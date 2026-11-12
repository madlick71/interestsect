import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import SiteNav from "@/app/components/SiteNav";
import Avatar from "@/app/components/Avatar";
import { resolveAvatarUrl, signAvatarUrls } from "@/lib/avatars";

// UUID-Format der auth.users-IDs — alles andere ist keine Profil-ID.
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Schreibgeschütztes Profil eines anderen Nutzers — Ziel der klickbaren
// Namenslabels auf der Treffer-Karte (/map). Die eigene ID leitet auf den
// Profil-Editor weiter. Fremde Interessen sind per RLS nur über die
// Match-RPC lesbar, deshalb zeigt die Seite die gemeinsamen Interessen.
export default async function UserProfilePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  if (!UUID_RE.test(id)) notFound();

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/");
  if (id === user.id) redirect("/profile");

  const [{ data: profile }, { data: matches }] = await Promise.all([
    supabase
      .from("profiles")
      .select("display_name, region, bio, avatar_url")
      .eq("id", id)
      .maybeSingle(),
    supabase.rpc("find_matches", { min_common: 2, max_results: 20 }),
  ]);

  if (!profile) notFound();

  // Privater Bucket: Avatar-Pfad des Profils zu einer Signed URL signieren.
  const avatarUrls = await signAvatarUrls(supabase, [profile.avatar_url]);

  const match = (matches ?? []).find((m) => m.user_id === id);
  const sharedInterests = match?.shared_interests ?? [];

  return (
    <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
      <SiteNav />
      <div className="mb-4 flex items-baseline justify-between gap-4">
        <h1 className="text-2xl font-bold">Profil</h1>
        <Link
          href="/map"
          className="text-sm text-gray-500 underline hover:text-gray-800"
        >
          Zurück zur Karte
        </Link>
      </div>

      <article className="rounded-lg border p-5">
        <div className="flex items-center gap-4">
          <Avatar
            url={resolveAvatarUrl(avatarUrls, profile.avatar_url)}
            name={profile.display_name}
            size={64}
          />
          <div>
            <h2 className="text-lg font-semibold">{profile.display_name}</h2>
            {profile.region && (
              <p className="mt-0.5 text-sm text-gray-500">{profile.region}</p>
            )}
          </div>
        </div>

        {profile.bio && <p className="mt-3 text-sm">{profile.bio}</p>}

        {match ? (
          <>
            <p className="mt-4 text-sm font-semibold">
              {match.common_interests} gemeinsame{" "}
              Interesse{match.common_interests === 1 ? "" : "n"} mit dir
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              {sharedInterests.map((name) => (
                <span
                  key={name}
                  className="rounded-full bg-gray-100 px-3 py-1 text-xs"
                >
                  {name}
                </span>
              ))}
            </div>
          </>
        ) : (
          <p className="mt-4 text-sm text-gray-500">
            Aktuell keine gemeinsamen Interessen (mindestens 2) mit dir.
          </p>
        )}
      </article>
    </main>
  );
}
