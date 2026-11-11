"use client";

import dynamic from "next/dynamic";
import type { MapMatch } from "./matches-map";

// MapLibre needs window — load client-only, no SSR.
const MatchesMap = dynamic(() => import("./matches-map"), {
  ssr: false,
});

interface MapPageClientProps {
  matches: MapMatch[];
  initialView?: {
    lat?: number;
    lng?: number;
    zoom?: number;
  };
  ownLocation?: { lat: number; lng: number } | null;
  emptyHint?: string | null;
}

export default function MapPageClient({
  matches,
  initialView,
  ownLocation,
  emptyHint,
}: MapPageClientProps) {
  return (
    <MatchesMap
      matches={matches}
      initialView={initialView}
      ownLocation={ownLocation}
      emptyHint={emptyHint}
    />
  );
}
