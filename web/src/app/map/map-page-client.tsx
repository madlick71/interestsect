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
}

export default function MapPageClient({
  matches,
  initialView,
}: MapPageClientProps) {
  return (
    <MatchesMap matches={matches} initialView={initialView} />
  );
}
