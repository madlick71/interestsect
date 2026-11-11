import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import MapPageClient from "./map-page-client";
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

  const { data: matches, error } = await supabase.rpc("find_matches", {
    min_common: 2,
    max_results: 20,
  });

  if (error) {
    return (
      <main className="mx-auto max-w-3xl px-4 py-12">
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

  return (
    <main className="mx-auto max-w-5xl px-4 py-12">
      <div className="mb-4 flex items-baseline justify-between gap-4">
        <h1 className="text-2xl font-bold">Treffer-Karte</h1>
        <span className="text-sm text-gray-500">
          {(matches as MapMatch[]).filter((m) => m.lat != null && m.lng != null)
            .length}{" "}
          von {(matches ?? []).length} Treffern mit Ort
        </span>
      </div>
      <MapPageClient
        matches={(matches ?? []) as MapMatch[]}
        initialView={initialView}
      />
    </main>
  );
}
