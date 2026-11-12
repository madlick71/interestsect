import { Suspense } from "react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import MyInterests from "./my-interests";
import SiteNav from "@/app/components/SiteNav";
import Avatar from "@/app/components/Avatar";
import { Background } from "@/app/components/background";
import { resolveAvatarUrl, signAvatarUrls } from "@/lib/avatars";

type Match = {
  user_id: string;
  display_name: string;
  region: string | null;
  bio: string | null;
  avatar_url: string | null;
  common_interests: number;
  shared_interests: string[];
};

async function HomeList() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/");

  // Eigene Interessen für Zähler + aufklappbare Liste
  const { data: myInterestRows } = await supabase
    .from("user_interests")
    .select("interests(name_de)");
  const myInterests = (myInterestRows ?? [])
    .map((r) => r.interests?.name_de ?? "")
    .filter(Boolean)
    .sort((a, b) => a.localeCompare(b, "de"));

  const { data: matches, error } = await supabase.rpc("find_matches", {
    min_common: 2,
    max_results: 20,
  });
  // Privater Bucket: Avatar-Pfade einmal im Batch zu Signed URLs signieren.
  const avatarUrls = await signAvatarUrls(
    supabase,
    (matches ?? []).map((m: Match) => m.avatar_url),
  );

  if (error) {
    return (
      <div>
        <MyInterests interests={myInterests} />
        <p className="mt-4 rounded bg-red-50 p-3 text-red-700">
          {error.message}
        </p>
      </div>
    );
  }

  if (!matches || matches.length === 0) {
    return (
      <div>
        <MyInterests interests={myInterests} />
        <div className="mt-8 rounded-lg border p-6 text-muted-foreground">
          Noch keine Treffer. Wähle mehr Interessen — je spezifischer, desto
          besser.{" "}
          <Link href="/interests" className="underline">
            Interessen bearbeiten
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div>
      <MyInterests interests={myInterests} />
      <div className="mt-6 space-y-4">
      {(matches as Match[]).map((m) => (
        <article key={m.user_id} className="rounded-lg border p-5">
          <div className="flex items-start justify-between gap-4">
            <div className="flex items-center gap-3">
              <Avatar
                url={resolveAvatarUrl(avatarUrls, m.avatar_url)}
                name={m.display_name}
                size={44}
              />
              <div>
                <h2 className="font-semibold">{m.display_name}</h2>
                {m.region && (
                  <p className="mt-0.5 text-sm text-muted-foreground">{m.region}</p>
                )}
              </div>
            </div>
            <span className="shrink-0 pt-1 text-sm text-muted-foreground">
              {m.common_interests} gemeinsame Interessen
            </span>
          </div>
          {m.bio && <p className="mt-2 text-sm">{m.bio}</p>}
          <div className="mt-3 flex flex-wrap gap-2">
            {m.shared_interests.slice(0, 6).map((name) => (
              <span
                key={name}
                className="rounded-full bg-muted px-3 py-1 text-xs"
              >
                {name}
              </span>
            ))}
          </div>
        </article>
      ))}
      </div>
    </div>
  );
}

export default function HomePage() {
  return (
    <Background>
      <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
        <SiteNav />
        <div className="flex items-baseline justify-between">
          <h1 className="text-2xl font-bold tracking-tight">Deine Treffer</h1>
        </div>
        <p className="mt-2 text-sm text-muted-foreground">
          Menschen mit mindestens 2 gemeinsamen Interessen.{" "}
          <Link href="/map" className="underline hover:text-foreground">
            Treffer auf der Karte ansehen
          </Link>
        </p>
        <Suspense fallback={<p className="mt-8 text-muted-foreground">Lade Treffer…</p>}>
          <HomeList />
        </Suspense>
      </main>
    </Background>
  );
}
