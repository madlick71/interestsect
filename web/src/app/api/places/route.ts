import { NextRequest, NextResponse } from "next/server";

// Google Places API (New) – Autocomplete proxy. Runs server-side so the
// API key never reaches the browser.
//
// Billing: every request must carry the same session token as the later
// Place Details call that resolves its coordinates. One Autocomplete
// session (typed query -> picked place -> Details) is billed as a single
// Autocomplete session, which is much cheaper than per-request billing.

const MIN_QUERY_LENGTH = 2;

// Restrict suggestions to places a profile region can plausibly be:
// cities, districts/suburbs (sublocality, e.g. "Endenich, Bonn") and
// regions. Streets and POIs are excluded by these primary types.
const INCLUDED_TYPES = [
  "locality",
  "sublocality",
  "neighborhood",
  "administrative_area_level_1",
];

export async function GET(request: NextRequest) {
  const q = request.nextUrl.searchParams.get("q")?.trim();
  const sessionToken = request.nextUrl.searchParams.get("st");

  if (!q || q.length < MIN_QUERY_LENGTH) {
    return NextResponse.json([]);
  }

  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    console.error("GOOGLE_PLACES_API_KEY is not configured");
    return NextResponse.json([], { status: 200 });
  }

  try {
    const res = await fetch(
      "https://places.googleapis.com/v1/places:autocomplete",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask":
            "suggestions.placePrediction.placeId,suggestions.placePrediction.text.text",
        },
        body: JSON.stringify({
          input: q,
          ...(sessionToken ? { sessionToken } : {}),
          includedPrimaryTypes: INCLUDED_TYPES,
        }),
      },
    );

    if (!res.ok) {
      console.error("Google Places autocomplete error:", res.status);
      return NextResponse.json([], { status: 200 });
    }

    const data = (await res.json()) as GoogleAutocompleteResponse;
    const suggestions = data.suggestions ?? [];

    // Shape for the client: label + placeId. Coordinates come later from
    // /api/places/details once the user actually picks a suggestion.
    const places: { label: string; placeId: string }[] = [];
    for (const p of suggestions.map((s) => s.placePrediction)) {
      const placeId = p?.placeId;
      const label = p?.text?.text;
      if (!placeId || !label) continue;
      places.push({ label, placeId });
    }

    // Deduplicate by label
    const seen = new Set<string>();
    const unique = places.filter((p) => {
      if (seen.has(p.label)) return false;
      seen.add(p.label);
      return true;
    });

    return NextResponse.json(unique);
  } catch (err) {
    console.error("Places proxy error:", err);
    return NextResponse.json([], { status: 200 });
  }
}

type GoogleAutocompleteResponse = {
  suggestions?: {
    placePrediction?: {
      placeId?: string;
      text?: { text?: string };
    };
  }[];
};
