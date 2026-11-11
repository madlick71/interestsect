import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import MapPageClient from "./map-page-client";
import SiteNav from "@/app/components/SiteNav";
import type { MapMatch } from "./matches-map";

// Treffer-Karte: dieselben Treffer wie auf der Home-Seite (find_matches),
// verortet über die im Profil per Geocoding gewählte Region.
export default async function MapPage({
  searchParams,
}: {
  searchParams: Promise<{
    lat?: string;
    lng?: string;
    zoom?: string;
  }>;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/");

  const [{ data: matches, error }, { data: ownProfile }] = await Promise.all([
    supabase.rpc("find_matches", {
      min_common: 2,
      max_results: 20,
    }),
    supabase
      .from("profiles")
      .select("lat, lng")
      .eq("id", user.id)
      .single(),
  ]);

  if (error) {
    return (
      <main className="mx-auto max-w-6xl px-4 py-12">
        <SiteNav />
        <h1 className="text-2xl font-bold">Treffer-Karte</h1>
        <p className="mt-4 rounded bg-red-50 p-3 text-sm text-red-700">
          {error.message}
        </p>
      </main>
    );
  }

  const params = await searchParams;
  const latNum = params.lat ? Number(params.lat) : NaN;
  const lngNum = params.lng ? Number(params.lng) : NaN;
  const zoomNum = params.zoom ? Number(params.zoom) : NaN;
  const initialView =
    Number.isFinite(latNum) && Number.isFinite(lngNum)
      ? {
          lat: latNum,
          lng: lngNum,
          zoom: Number.isFinite(zoomNum) ? zoomNum : undefined,
        }
      : undefined;

  const allMatches = (matches ?? []) as MapMatch[];
  const locatedCount = allMatches.filter(
    (m) => m.lat != null && m.lng != null,
  ).length;
  const ownLocation =
    ownProfile?.lat != null && ownProfile?.lng != null
      ? { lat: ownProfile.lat, lng: ownProfile.lng }
      : null;

  // Overlay nur, wenn kein Treffer verortet ist — die Karte selbst rendert immer.
  let emptyHint: string | null = null;
  if (locatedCount === 0) {
    if (allMatches.length === 0) {
      emptyHint =
        "Noch keine Treffer: Sobald jemand mindestens 2 Interessen mit dir teilt, erscheint die Person hier auf der Karte." +
        (ownLocation
          ? ""
          : " Setze deine Region im Profil, damit andere dich finden.");
    } else {
      emptyHint =
        "Deine Treffer haben noch keine Region mit Koordinaten im Profil hinterlegt.";
    }
  }

  return (
    <main className="mx-auto max-w-6xl px-4 py-12">
      <SiteNav />
      <div className="mb-4 flex items-baseline justify-between gap-4">
        <h1 className="text-2xl font-bold">Treffer-Karte</h1>
        <span className="text-sm text-gray-500">
          {locatedCount} von {allMatches.length} Treffern mit Ort
        </span>
      </div>
      <MapPageClient
        matches={allMatches}
        initialView={initialView}
        ownLocation={ownLocation}
        emptyHint={emptyHint}
      />
    </main>
  );
}
