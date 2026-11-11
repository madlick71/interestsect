import { NextRequest, NextResponse } from "next/server";

// Google Places API (New) – Place Details proxy. Resolves the placeId of a
// picked autocomplete suggestion into human-readable address parts plus
// coordinates. Runs server-side so the API key never reaches the browser.
//
// Billing: this call CLOSES the Autocomplete session that started with the
// /api/places?q=… request using the same session token. Send the token from
// the last autocomplete request, otherwise the whole session is re-billed.

export async function GET(request: NextRequest) {
  const placeId = request.nextUrl.searchParams.get("place_id")?.trim();
  const sessionToken = request.nextUrl.searchParams.get("st");

  if (!placeId) {
    return NextResponse.json({ error: "place_id required" }, { status: 400 });
  }

  const apiKey = process.env.GOOGLE_PLACES_API_KEY;
  if (!apiKey) {
    console.error("GOOGLE_PLACES_API_KEY is not configured");
    return NextResponse.json({ error: "not configured" }, { status: 500 });
  }

  try {
    const res = await fetch(
      `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`,
      {
        headers: {
          "X-Goog-Api-Key": apiKey,
          "X-Goog-FieldMask":
            "id,location,formattedAddress,addressComponents",
          ...(sessionToken ? { "X-Goog-Session-Token": sessionToken } : {}),
        },
      },
    );

    if (!res.ok) {
      console.error("Google Places details error:", res.status);
      return NextResponse.json({ error: "upstream error" }, { status: 200 });
    }

    const place = (await res.json()) as GooglePlaceDetails;
    const location = place.location;
    if (!location?.latitude || !location?.longitude) {
      return NextResponse.json({ error: "no location" }, { status: 200 });
    }

    // Derive a human label from the address components. For districts
    // (sublocality, e.g. "Endenich" in Bonn) the district itself comes
    // FIRST — locality alone would collapse the pick back to the parent
    // city ("Bonn"), which is exactly what the user did NOT choose.
    const comps = place.addressComponents ?? [];
    const get = (type: string) =>
      comps.find((c) => c.types?.includes(type))?.longText;
    const district = get("sublocality_level_2") ?? get("sublocality");
    const city =
      get("locality") ?? get("postal_town") ?? get("administrative_area_level_3");
    const state = get("administrative_area_level_1");
    const country = get("country");

    // District pick: "Endenich, Bonn, Germany". City pick: "Bonn, NRW, Germany".
    const parts = district
      ? [district, city ?? state, country]
      : [city, state, country];
    const label = [...new Set(parts.filter(Boolean))].join(", ");
    const finalLabel =
      label ||
      (place.formattedAddress?.split(",").slice(0, 3).join(",").trim() ?? "");

    return NextResponse.json({
      label: finalLabel,
      lat: location.latitude,
      lon: location.longitude,
    });
  } catch (err) {
    console.error("Places details proxy error:", err);
    return NextResponse.json({ error: "proxy error" }, { status: 200 });
  }
}

type GooglePlaceDetails = {
  id?: string;
  formattedAddress?: string;
  location?: { latitude?: number; longitude?: number };
  addressComponents?: { longText?: string; types?: string[] }[];
};
