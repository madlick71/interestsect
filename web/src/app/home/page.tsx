import { Suspense } from "react";
import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import MyInterests from "./my-interests";
import SiteNav from "@/app/components/SiteNav";

type Match = {
  user_id: string;
  display_name: string;
  region: string | null;
  bio: string | null;
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
        <div className="mt-8 rounded border p-6 text-gray-600">
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
          <div className="flex items-baseline justify-between">
            <h2 className="font-semibold">{m.display_name}</h2>
            <span className="text-sm text-gray-500">
              {m.common_interests} gemeinsame Interessen
            </span>
          </div>
          {m.region && <p className="mt-1 text-sm text-gray-500">{m.region}</p>}
          {m.bio && <p className="mt-2 text-sm">{m.bio}</p>}
          <div className="mt-3 flex flex-wrap gap-2">
            {m.shared_interests.slice(0, 6).map((name) => (
              <span
                key={name}
                className="rounded-full bg-gray-100 px-3 py-1 text-xs"
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
    <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
      <SiteNav />
      <div className="flex items-baseline justify-between">
        <h1 className="text-2xl font-bold">Deine Treffer</h1>
      </div>
      <p className="mt-2 text-sm text-gray-600">
        Menschen mit mindestens 2 gemeinsamen Interessen.{" "}
        <Link href="/map" className="underline hover:text-gray-800">
          Treffer auf der Karte ansehen
        </Link>
      </p>
      <Suspense fallback={<p className="mt-8 text-gray-500">Lade Treffer…</p>}>
        <HomeList />
      </Suspense>
    </main>
  );
}
