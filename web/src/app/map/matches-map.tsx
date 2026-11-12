"use client";

import { useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import * as maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

export type MapMatch = {
  user_id: string;
  display_name: string;
  region: string | null;
  bio: string | null;
  avatar_url: string | null;
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
  // SPA-Navigation für die klickbaren Namenslabels / Popup-Links.
  const router = useRouter();

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
    // Wichtig: window.history.state DURCHREICHEN — replaceState(null, …)
    // wischt Next.js' internen Router-State (Tree-Key) und lässt danach
    // usePathname() auf der Zielseite beim alten Pfad hängen (Navigation
    // bleibt optisch auf der Karte "kleben").
    map.current.on("moveend", () => {
      const m = map.current;
      if (!m) return;
      const c = m.getCenter();
      const params = new URLSearchParams(window.location.search);
      params.set("lat", c.lat.toFixed(5));
      params.set("lng", c.lng.toFixed(5));
      params.set("zoom", m.getZoom().toFixed(2));
      window.history.replaceState(
        window.history.state,
        "",
        `/map?${params.toString()}`,
      );
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

      // Wrapper keeps the pin centered on the coordinate. MapLibre styles
      // the marker element via its .maplibregl-marker class (position:
      // absolute) and centers it with translate(-50%,-50%) — therefore the
      // element gets explicit pin dimensions and the labels hang absolutely
      // below it. Position/display MUST NOT be overridden here: a block div
      // stretches to container width and the pin then lands half a map
      // width away from its coordinate.
      const el = document.createElement("div");
      el.style.width = multi ? "28px" : "24px";
      el.style.height = multi ? "28px" : "24px";
      el.style.cursor = "pointer";

      const pin = document.createElement("div");
      pin.style.width = "100%";
      pin.style.height = "100%";
      pin.style.borderRadius = "50%";
      pin.style.backgroundColor = "#171717";
      pin.style.border = "3px solid white";
      pin.style.boxShadow = "0 2px 6px rgba(0,0,0,0.3)";
      if (multi) {
        // Cluster badge: show the number of people at this spot.
        pin.style.display = "flex";
        pin.style.alignItems = "center";
        pin.style.justifyContent = "center";
        pin.style.fontSize = "10px";
        pin.style.fontWeight = "700";
        pin.style.color = "white";
        pin.textContent = String(group.length);
      }
      el.appendChild(pin);

      // Clickable name label per person, stacked under the pin. Capped so
      // big clusters stay readable; the rest is reachable via the popup.
      // stopPropagation keeps the marker's map-click popup toggle away;
      // without it (the "+N" chip) the click falls through to the popup.
      const LABEL_LIMIT = 3;
      const labelWrap = document.createElement("div");
      labelWrap.style.cssText =
        "position:absolute; top:calc(100% + 3px); left:50%; transform:translateX(-50%); display:flex; flex-direction:column; align-items:center; gap:2px; pointer-events:none;";
      const labelCss =
        "pointer-events:auto; display:inline-block; max-width:9rem; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; padding:1px 7px; border-radius:9999px; background:rgba(255,255,255,0.95); border:1px solid #d1d5db; box-shadow:0 1px 3px rgba(0,0,0,0.25); color:#111827; font-size:11px; font-weight:600; line-height:1.5; text-decoration:none; cursor:pointer;";
      for (const m of group.slice(0, LABEL_LIMIT)) {
        const label = document.createElement("a");
        label.href = `/profile/${m.user_id}`;
        label.textContent = m.display_name;
        label.title = m.display_name;
        label.style.cssText = labelCss;
        label.addEventListener("click", (e) => {
          e.stopPropagation();
          // Modifier-Klicks (neuer Tab etc.) dem Browser überlassen.
          if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
          e.preventDefault();
          router.push(`/profile/${m.user_id}`);
        });
        label.addEventListener("mouseenter", () => {
          label.style.backgroundColor = "#111827";
          label.style.borderColor = "#111827";
          label.style.color = "#ffffff";
        });
        label.addEventListener("mouseleave", () => {
          label.style.backgroundColor = "rgba(255,255,255,0.95)";
          label.style.borderColor = "#d1d5db";
          label.style.color = "#111827";
        });
        labelWrap.appendChild(label);
      }
      if (group.length > LABEL_LIMIT) {
        const more = document.createElement("span");
        more.textContent = `+${group.length - LABEL_LIMIT} weitere`;
        more.style.cssText =
          "pointer-events:auto; padding:1px 7px; border-radius:9999px; background:rgba(255,255,255,0.85); border:1px solid #e5e7eb; color:#6b7280; font-size:10px; font-weight:600; line-height:1.5; cursor:pointer;";
        labelWrap.appendChild(more);
      }
      el.appendChild(labelWrap);

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
        const avatar = m.avatar_url
          ? `<img src="${escapeHtml(m.avatar_url)}" alt="" style="width:34px; height:34px; border-radius:50%; object-fit:cover; flex-shrink:0;" referrerPolicy="no-referrer" />`
          : `<span style="width:34px; height:34px; border-radius:50%; object-fit:cover; flex-shrink:0; display:inline-flex; align-items:center; justify-content:center; background:#e5e7eb; color:#4b5563; font-size:15px; font-weight:600;">${escapeHtml((m.display_name ?? "").trim().charAt(0).toUpperCase() || "?")}</span>`;
        return `
          <div data-match-body style="min-width: 200px; max-width: 260px;">
            <div style="display:flex; align-items:center; gap:8px;">
              ${avatar}
              <h3 style="margin: 0 26px 0 0; font-size: 14px; font-weight: 600; color: #111827;">${escapeHtml(m.display_name)}</h3>
            </div>
            ${m.region ? `<p style="margin: 2px 0 0 42px; font-size: 12px; color: #6b7280;">${escapeHtml(m.region)}</p>` : ""}
            <p style="margin: 6px 0 4px 0; font-size: 12px; font-weight: 600; color: #111827;">
              ${m.common_interests} gemeinsame Interesse${m.common_interests === 1 ? "" : "n"}
            </p>
            <div style="margin: 2px 0 4px 0;">${chips}</div>
            <a href="/profile/${m.user_id}" data-profile-link style="display:inline-block; margin-top:4px; font-size:12px; font-weight:600; color:#111827; text-decoration:underline;">Profil ansehen →</a>
          </div>
        `;
      };

      const popup = new maplibregl.Popup({ offset: 25 }).setHTML(
        renderMatch(group[0]),
      );

      popup.on("open", () => {
        const content = popup
          .getElement()
          ?.querySelector<HTMLElement>(".maplibregl-popup-content");
        if (!content) return;

        // "Profil ansehen →" im Popup: SPA-Navigation statt Reload.
        // Einmalig binden — "open" feuert bei jedem Öffnen erneut.
        if (!content.dataset.profileNav) {
          content.dataset.profileNav = "1";
          content.addEventListener("click", (e) => {
            const link = (e.target as HTMLElement).closest(
              "a[data-profile-link]",
            );
            if (!link) return;
            e.preventDefault();
            e.stopPropagation();
            router.push(link.getAttribute("href") ?? "/map");
          });
        }

        if (!multi) return;
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

      const marker = new maplibregl.Marker({ element: el })
        .setLngLat([lng, lat])
        .setPopup(popup)
        .addTo(map.current!);

      markers.current.push(marker);
      bounds.extend([lng, lat]);
    });

    try {
      // Nur automatisch einpassen, wenn keine Ansicht per URL vorgegeben ist.
      // Padding groß genug für Pin + Namenslabels unterhalb des Pins.
      if (!bounds.isEmpty() && !hasInitialView) {
        map.current.fitBounds(bounds, {
          padding: 90,
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
