"use client";

import { useEffect, useRef, useState } from "react";

// Portiert aus jamnb: Der Debounce-Effekt setzt Zustand synchron im
// Effect-Body (Dropdown schließen bzw. aus dem Cache servieren), direkt
// abhängig vom Eingabewert — hier bewusst so, keine cascading renders.
/* eslint-disable react-hooks/set-state-in-effect */

// A suggestion as delivered by /api/places (Google Places autocomplete):
// label for display, placeId for the later coordinate lookup.
type PlaceSuggestion = {
  label: string;
  placeId: string;
};

export type LocationChoice = {
  label: string;
  lat: number;
  lon: number;
};

// One Autocomplete session = all autocomplete requests while typing + the
// final Place Details call. Billed as ONE session instead of per request,
// which is what makes this integration the cheap variant.
function newSessionToken(): string {
  return crypto.randomUUID();
}

type Props = {
  value: string;
  onChange: (value: string) => void;
  onPick?: (choice: LocationChoice) => void;
  placeholder?: string;
  required?: boolean;
  className?: string;
  // Optional name/autocomplete for native browser form history. Defaults
  // to off so the custom suggestion list doesn't clash with the browser's.
  name?: string;
  autoComplete?: string;
  id?: string;
};

export default function LocationInput({
  value,
  onChange,
  onPick,
  placeholder,
  required,
  className,
  name,
  autoComplete = "off",
  id,
}: Props) {
  const [suggestions, setSuggestions] = useState<PlaceSuggestion[]>([]);
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const [resolving, setResolving] = useState(false);

  const wrapperRef = useRef<HTMLDivElement>(null);
  const latestQuery = useRef("");
  const abortRef = useRef<AbortController | null>(null);
  const cacheRef = useRef(new Map<string, PlaceSuggestion[]>());
  const retryRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pickedRef = useRef<LocationChoice | null>(null);
  // The session token from the LAST autocomplete request must be sent to
  // the Place Details call to close the billing session.
  const sessionTokenRef = useRef(newSessionToken());

  // Debounced fetch against /api/places
  useEffect(() => {
    const q = value.trim();
    latestQuery.current = q;

    // A programmatic value update from a successful pick must NOT reopen
    // the dropdown: skip entirely while the value equals the picked label.
    if (pickedRef.current && pickedRef.current.label === q) {
      setSuggestions([]);
      setOpen(false);
      return;
    }

    // Any manual edit invalidates the previous selection: the parent must
    // validate against the picked ref before allowing a save.
    pickedRef.current = null;

    if (retryRef.current) {
      clearTimeout(retryRef.current);
      retryRef.current = null;
    }
    if (q.length < 2) {
      setSuggestions([]);
      setOpen(false);
      abortRef.current?.abort();
      return;
    }

    // Serve from cache instantly; no new request needed. Never cache or
    // serve empty results: a transient Google error would otherwise blank
    // the dropdown for this query until the next reload.
    const cached = cacheRef.current.get(q);
    if (cached && cached.length > 0) {
      setSuggestions(cached);
      setOpen(true);
      setActiveIndex(-1);
      return;
    }

    async function run(query: string) {
      abortRef.current?.abort();
      const ac = new AbortController();
      abortRef.current = ac;
      try {
        const params = new URLSearchParams({
          q: query,
          st: sessionTokenRef.current,
        });
        const res = await fetch(`/api/places?${params.toString()}`, {
          signal: ac.signal,
        });
        if (!res.ok) return;
        const data = (await res.json()) as PlaceSuggestion[];
        if (!Array.isArray(data)) return;
        // Prevent stale responses
        if (latestQuery.current !== query) return;
        // Empty result = transient upstream failure (Google error, server
        // restart). Do NOT cache it, do NOT close the dropdown — keep the
        // last good suggestions visible so the user can still pick.
        if (data.length === 0) return;
        cacheRef.current.set(query, data);

        // Google Autocomplete already does prefix matching — show exactly
        // what came back. The dropdown only makes sense while the input is
        // focused; also keep it open if it already is (keyboard navigation).
        setSuggestions(data);
        setOpen(document.activeElement === wrapperRef.current?.querySelector("input"));
        setActiveIndex(-1);
      } catch {
        // Aborted or network error — fail silently
      }
    }

    const timer = setTimeout(() => void run(q), 350);

    return () => clearTimeout(timer);
  }, [value]);

  // Close on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  async function pick(place: PlaceSuggestion) {
    // Reserve the picked label BEFORE the first onChange: the debounce
    // effect skips while the input shows a picked label, so the programmatic
    // value updates below don't trigger a refetch that reopens the dropdown.
    // lat/lon are filled in once the details call resolves.
    pickedRef.current = { label: place.label, lat: 0, lon: 0 };
    onChange(place.label);
    setOpen(false);
    setSuggestions([]);
    setActiveIndex(-1);
    setResolving(true);
    try {
      // Close the autocomplete session: resolve the picked place's
      // coordinates with the SAME session token (cheaper billing).
      const params = new URLSearchParams({
        place_id: place.placeId,
        st: sessionTokenRef.current,
      });
      const res = await fetch(`/api/places/details?${params.toString()}`);
      if (!res.ok) return;
      const data = (await res.json()) as {
        label?: string;
        lat: number;
        lon: number;
      };
      if (typeof data.lat !== "number" || typeof data.lon !== "number") return;
      const choice: LocationChoice = {
        label: data.label || place.label,
        lat: data.lat,
        lon: data.lon,
      };
      pickedRef.current = choice;
      onChange(choice.label);
      onPick?.(choice);
      // Session complete: next input starts a fresh billing session.
      sessionTokenRef.current = newSessionToken();
    } catch {
      // Network error — user can retry by picking again
    } finally {
      setResolving(false);
    }
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (!open || suggestions.length === 0) return;

    if (e.key === "ArrowDown") {
      e.preventDefault();
      setActiveIndex((i) => Math.min(i + 1, suggestions.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActiveIndex((i) => Math.max(i - 1, -1));
    } else if (e.key === "Enter" && activeIndex >= 0) {
      e.preventDefault();
      void pick(suggestions[activeIndex]);
    } else if (e.key === "Escape") {
      setOpen(false);
      setActiveIndex(-1);
    }
  }

  return (
    <div ref={wrapperRef} className="relative">
      <input
        type="text"
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onFocus={() => suggestions.length > 0 && setOpen(true)}
        onKeyDown={handleKeyDown}
        placeholder={resolving ? "…" : placeholder}
        required={required}
        name={name}
        autoComplete={autoComplete}
        className={className}
        role="combobox"
        aria-expanded={open}
        aria-controls="location-suggestions"
        aria-activedescendant={
          activeIndex >= 0 ? `location-option-${activeIndex}` : undefined
        }
      />

      {open && suggestions.length > 0 && (
        <ul
          id="location-suggestions"
          role="listbox"
          className="absolute left-0 right-0 top-full z-50 mt-1 max-h-56 overflow-y-auto rounded border border-gray-300 bg-white shadow-lg"
        >
          {suggestions.map((s, i) => (
            <li
              key={s.label}
              id={`location-option-${i}`}
              role="option"
              aria-selected={i === activeIndex}
              className={`cursor-pointer px-4 py-2.5 text-sm transition-colors ${
                i === activeIndex
                  ? "bg-gray-100 text-gray-900"
                  : "text-gray-600 hover:bg-gray-100"
              }`}
              onMouseDown={(e) => {
                // onMouseDown instead of onClick so it fires before input blur
                e.preventDefault();
                void pick(s);
              }}
            >
              {s.label}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
