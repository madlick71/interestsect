"use client";

import { useEffect, useRef } from "react";
import * as maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

export type MapMatch = {
  user_id: string;
  display_name: string;
  region: string | null;
  bio: string | null;
  lat: number | null;
  lng: number | null;
  common_interests: number;
  shared_interests: string[];
};

// MapLibre GL v6: Turbopack bundles the worker but drops its sibling
// maplibre-gl-shared.mjs, so the worker fails on its first import and the
// map never requests a tile (blank map). The official fix is to copy the
// worker files to public/ (scripts/copy-maplibre-worker.mjs) and set the
// worker URL explicitly. See MapLibre ESM/Turbopack installation docs.
maplibregl.setWorkerUrl("/maplibre/maplibre-gl-worker.mjs");

// Maptoolkit Community License – kostenlose Vektorkarte (maxzoom 15), kein API-Key.
// Pflicht-Attribution: Logo ≥24px + "© Maptoolkit © OpenStreetMap" klickbar.
const VECTOR_STYLE_URL = "https://styles.maptoolkit.org/street.json";
const MAPTOOLKIT_LOGO_SRC = "/images/maptoolkit-attribution.png";

interface MatchesMapProps {
  matches: MapMatch[];
  initialView?: { lat?: number; lng?: number; zoom?: number };
  // Eigener Standort aus dem Profil (falls gesetzt): eigener Pin + Fallback-Zentrum.
  ownLocation?: { lat: number; lng: number } | null;
  // Hinweistext im Overlay, wenn kein Treffer verortet ist (null = Overlay aus).
  emptyHint?: string | null;
}

export default function MatchesMap({
  matches,
  initialView,
  ownLocation,
  emptyHint,
}: MatchesMapProps) {
  const mapContainer = useRef<HTMLDivElement>(null);
  const map = useRef<maplibregl.Map | null>(null);
  const markers = useRef<maplibregl.Marker[]>([]);

  const validMatches = matches.filter(
    (m) => m.lat != null && m.lng != null,
  );
  const hasData = validMatches.length > 0;

  // Exakte Ansicht aus der URL (/map?lat=..&lng=..&zoom=..) wiederherstellen?
  const hasInitialView =
    initialView?.lat != null && initialView?.lng != null;

  useEffect(() => {
    if (map.current || !mapContainer.current) return;

    map.current = new maplibregl.Map({
      container: mapContainer.current,
      style: VECTOR_STYLE_URL,
      center:
        initialView?.lat != null && initialView?.lng != null
          ? [initialView.lng, initialView.lat]
          : ownLocation
            ? [ownLocation.lng, ownLocation.lat]
            : [10.45, 51.16],
      zoom:
        initialView?.zoom ?? (ownLocation && !hasData ? 11 : 5),
    });

    // URL immer auf die aktuelle Kartenansicht synchronisieren, damit
    // /map?lat=..&lng=..&zoom=.. eine eindeutige, teilbare Adresse ist.
    map.current.on("moveend", () => {
      const m = map.current;
      if (!m) return;
      const c = m.getCenter();
      const params = new URLSearchParams(window.location.search);
      params.set("lat", c.lat.toFixed(5));
      params.set("lng", c.lng.toFixed(5));
      params.set("zoom", m.getZoom().toFixed(2));
      window.history.replaceState(null, "", `/map?${params.toString()}`);
    });

    map.current.addControl(
      new maplibregl.NavigationControl(),
      "top-right",
    );

    const el = mapContainer.current;
    const ro = new ResizeObserver(() => {
      map.current?.resize();
    });
    ro.observe(el);

    requestAnimationFrame(() => {
      map.current?.resize();
      map.current?.triggerRepaint();
    });

    return () => {
      ro.disconnect();
      markers.current.forEach((m) => m.remove());
      markers.current = [];
      map.current?.remove();
      map.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Stabiler Key, damit der Effect nur bei echten Datenänderungen neu läuft
  const coordsKey = validMatches
    .map((m) => `${m.user_id}:${m.lat},${m.lng}`)
    .join("|");

  useEffect(() => {
    if (!map.current) return;

    markers.current.forEach((m) => m.remove());
    markers.current = [];

    // Eigener Standort: eigener Pin (weiß mit schwarzem Rand), unabhängig
    // davon, ob schon Treffer existieren.
    if (ownLocation) {
      const ownEl = document.createElement("div");
      ownEl.style.width = "26px";
      ownEl.style.height = "26px";
      ownEl.style.borderRadius = "50%";
      ownEl.style.backgroundColor = "#ffffff";
      ownEl.style.border = "3px solid #171717";
      ownEl.style.boxShadow = "0 2px 6px rgba(0,0,0,0.3)";
      ownEl.style.display = "flex";
      ownEl.style.alignItems = "center";
      ownEl.style.justifyContent = "center";
      ownEl.style.fontSize = "9px";
      ownEl.style.fontWeight = "700";
      ownEl.style.color = "#171717";
      ownEl.textContent = "Du";
      const ownMarker = new maplibregl.Marker({ element: ownEl })
        .setLngLat([ownLocation.lng, ownLocation.lat])
        .setPopup(
          new maplibregl.Popup({ offset: 25 }).setHTML(
            '<div style="font-size: 13px; font-weight: 600; color: #111827;">Dein Standort</div>',
          ),
        )
        .addTo(map.current);
      markers.current.push(ownMarker);
    }

    if (!hasData) return;

    const bounds = new maplibregl.LngLatBounds();

    // Cluster matches by exact coordinates: everyone who picked the same
    // place (e.g. "München") from Google Places shares one marker with a
    // pager through the grouped people.
    const ROUNDOFF = 5; // ~1 m precision; identical input -> identical key
    const clusters = new Map<
      string,
      { lat: number; lng: number; matches: MapMatch[] }
    >();
    for (const m of validMatches) {
      if (m.lat == null || m.lng == null) continue;
      const key = `${m.lat.toFixed(ROUNDOFF)},${m.lng.toFixed(ROUNDOFF)}`;
      const c = clusters.get(key);
      if (c) {
        c.matches.push(m);
      } else {
        clusters.set(key, {
          lat: m.lat,
          lng: m.lng,
          matches: [m],
        });
      }
    }

    const escapeHtml = (s: string) =>
      s
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;");

    clusters.forEach((cluster) => {
      const { lat, lng, matches: group } = cluster;
      const multi = group.length > 1;

      const el = document.createElement("div");
      el.style.width = "24px";
      el.style.height = "24px";
      el.style.borderRadius = "50%";
      el.style.backgroundColor = "#171717";
      el.style.border = "3px solid white";
      el.style.boxShadow = "0 2px 6px rgba(0,0,0,0.3)";
      el.style.cursor = "pointer";
      if (multi) {
        // Cluster badge: show the number of people at this spot.
        el.style.display = "flex";
        el.style.alignItems = "center";
        el.style.justifyContent = "center";
        el.style.fontSize = "10px";
        el.style.fontWeight = "700";
        el.style.color = "white";
        el.style.width = "28px";
        el.style.height = "28px";
        el.textContent = String(group.length);
      }

      // Renders the popup content for one person of the cluster. The outer
      // div carries data-match-body so the pager can swap it in place.
      const renderMatch = (m: MapMatch) => {
        const chips = (m.shared_interests ?? [])
          .slice(0, 6)
          .map(
            (name) =>
              `<span style="display:inline-block; margin:2px 4px 2px 0; padding:2px 8px; border-radius:9999px; background:#f3f4f6; color:#374151; font-size:11px;">${escapeHtml(name)}</span>`,
          )
          .join("");
        return `
          <div data-match-body style="min-width: 200px; max-width: 260px;">
            <h3 style="margin: 0 26px 2px 0; font-size: 14px; font-weight: 600; color: #111827;">${escapeHtml(m.display_name)}</h3>
            ${m.region ? `<p style="margin: 0; font-size: 12px; color: #6b7280;">${escapeHtml(m.region)}</p>` : ""}
            <p style="margin: 6px 0 4px 0; font-size: 12px; font-weight: 600; color: #111827;">
              ${m.common_interests} gemeinsame Interesse${m.common_interests === 1 ? "" : "n"}
            </p>
            <div style="margin: 2px 0 4px 0;">${chips}</div>
          </div>
        `;
      };

      const popup = new maplibregl.Popup({ offset: 25 }).setHTML(
        renderMatch(group[0]),
      );

      if (multi) {
        // Pager row above the match body: ‹ 2/3 ›. The initial HTML from
        // setHTML already contains data-match-body; the open handler only
        // prepends the pager and wires the buttons.
        popup.on("open", () => {
          const content = popup
            .getElement()
            ?.querySelector<HTMLElement>(".maplibregl-popup-content");
          if (!content) return;
          // Guard against double-init (popup "open" can fire again).
          if (content.querySelector("[data-pager]")) return;
          let idx = 0;

          const pager = document.createElement("div");
          pager.setAttribute("data-pager", "");
          pager.style.cssText =
            "display:flex; align-items:center; justify-content:flex-start; gap:8px; margin:0 0 6px 0; padding-right:24px;";
          pager.innerHTML = `
            <button type="button" data-pager="prev" aria-label="Vorherige Person" style="width:22px;height:22px;border:none;border-radius:6px;background:#e5e7eb;color:#111827;cursor:pointer;font-size:14px;line-height:1;">‹</button>
            <span data-pager-count style="font-size:11px;color:#6b7280;"></span>
            <button type="button" data-pager="next" aria-label="Nächste Person" style="width:22px;height:22px;border:none;border-radius:6px;background:#e5e7eb;color:#111827;cursor:pointer;font-size:14px;line-height:1;">›</button>
          `;
          content.prepend(pager);

          const label = pager.querySelector("[data-pager-count]")!;
          const body = () =>
            content.querySelector<HTMLElement>("[data-match-body]")!;

          const swapBody = (m: MapMatch) => {
            const wrapper = document.createElement("div");
            wrapper.innerHTML = renderMatch(m);
            const fresh = wrapper.firstElementChild as HTMLElement;
            body().replaceWith(fresh);
          };

          const render = () => {
            const m = group[idx];
            label.textContent = `${idx + 1}/${group.length}`;
            swapBody(m);
          };

          pager
            .querySelector('[data-pager="prev"]')
            ?.addEventListener("click", (e) => {
              e.preventDefault();
              e.stopPropagation();
              idx = (idx - 1 + group.length) % group.length;
              render();
            });
          pager
            .querySelector('[data-pager="next"]')
            ?.addEventListener("click", (e) => {
              e.preventDefault();
              e.stopPropagation();
              idx = (idx + 1) % group.length;
              render();
            });

          render();
        });
      }

      const marker = new maplibregl.Marker({ element: el })
        .setLngLat([lng, lat])
        .setPopup(popup)
        .addTo(map.current!);

      markers.current.push(marker);
      bounds.extend([lng, lat]);
    });

    try {
      // Nur automatisch einpassen, wenn keine Ansicht per URL vorgegeben ist.
      if (!bounds.isEmpty() && !hasInitialView) {
        map.current.fitBounds(bounds, {
          padding: 50,
          maxZoom: 13,
        });
      }
    } catch {
      // leere bounds
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [coordsKey, hasData, ownLocation?.lat, ownLocation?.lng]);

  // Karte rendert immer — auch ohne Treffer: eigener Pin (falls gesetzt)
  // und Hinweis-Overlay statt einer leeren Box.
  return (
    <div className="relative h-[70vh] w-full overflow-hidden rounded-lg border border-gray-300">
      <div ref={mapContainer} className="h-full w-full" />

      {emptyHint && (
        <div className="pointer-events-none absolute left-1/2 top-4 z-10 w-[min(92%,32rem)] -translate-x-1/2 rounded-lg border border-gray-300 bg-white/95 px-4 py-3 text-center text-sm text-gray-600 shadow">
          {emptyHint}
        </div>
      )}

      {/* Maptoolkit Community License: Logo (min 24px high) + clickable copyright line */}
      <a
        href="https://www.maptoolkit.org"
        target="_blank"
        rel="noopener noreferrer"
        aria-label="Maptoolkit"
        className="absolute bottom-2 left-2 z-10"
      >
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={MAPTOOLKIT_LOGO_SRC}
          alt="Maptoolkit"
          className="h-6 w-auto opacity-90"
        />
      </a>
    </div>
  );
}
