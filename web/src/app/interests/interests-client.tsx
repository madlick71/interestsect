"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import SiteNav from "@/app/components/SiteNav";

type Category = {
  id: string;
  slug: string;
  name_de: string;
  sort_order: number;
};

type Interest = {
  id: string;
  category_id: string;
  slug: string;
  name_de: string;
  keywords: string[];
};

// Suchbare Normalform: kleingeschrieben, Umlaute ausgeschrieben —
// so findet "kräuter" auch "kraeuter" und "schach" auch "vereinschach"
function normalize(s: string) {
  return s
    .toLowerCase()
    .replaceAll("ä", "ae")
    .replaceAll("ö", "oe")
    .replaceAll("ü", "ue")
    .replaceAll("ß", "ss");
}

function setsEqual(a: Set<string>, b: Set<string>) {
  if (a.size !== b.size) return false;
  for (const v of a) if (!b.has(v)) return false;
  return true;
}

export default function InterestsClient() {
  const router = useRouter();
  const [categories, setCategories] = useState<Category[]>([]);
  const [interests, setInterests] = useState<Interest[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [initialSelected, setInitialSelected] = useState<Set<string>>(new Set());
  const [query, setQuery] = useState("");
  // Default: alle Kategorien zugeklappt
  const [openCats, setOpenCats] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);
  const [redirecting, setRedirecting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Vorschlags-Formular (neue Interessen zur Prüfung einreichen)
  const [suggestCat, setSuggestCat] = useState("");
  const [suggestName, setSuggestName] = useState("");
  const [suggesting, setSuggesting] = useState(false);
  const [suggestMsg, setSuggestMsg] = useState<
    { kind: "ok" | "hint" | "error"; text: string } | null
  >(null);
  const [openSuggestions, setOpenSuggestions] = useState<Set<string>>(new Set());

  const load = useCallback(async () => {
    const supabase = createClient();
    const [cats, mine, pending] = await Promise.all([
      supabase
        .from("interest_categories")
        .select("id, slug, name_de, sort_order")
        .order("sort_order"),
      supabase.from("user_interests").select("interest_id"),
      // Eigene offene Vorschläge (Admins sehen alle) — für Hinweise
      supabase
        .from("interest_suggestions")
        .select("id, name_de")
        .eq("status", "pending")
        .limit(100),
    ]);
    // Interessen seitenweise laden — die API liefert max. 1000 Zeilen
    // pro Anfrage, der Katalog ist inzwischen größer
    const ints: Interest[] = [];
    for (let from = 0; ; from += 1000) {
      const page = await supabase
        .from("interests")
        .select("id, category_id, slug, name_de, keywords")
        .order("name_de")
        .range(from, from + 999);
      if (page.error || cats.error || mine.error) {
        setError("Konnte Daten nicht laden. Bist du angemeldet?");
        return;
      }
      ints.push(...(page.data ?? []));
      if (!page.data || page.data.length < 1000) break;
    }
    setCategories(cats.data ?? []);
    setInterests(ints);
    setSelected(new Set((mine.data ?? []).map((r) => r.interest_id)));
    setInitialSelected(new Set((mine.data ?? []).map((r) => r.interest_id)));
    setOpenSuggestions(
      new Set((pending.data ?? []).map((r) => normalize(r.name_de))),
    );
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  function toggle(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  async function save() {
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const userId = (await supabase.auth.getUser()).data.user?.id;
    if (!userId) {
      setError("Nicht angemeldet.");
      setSaving(false);
      return;
    }

    const { error: delError } = await supabase.from("user_interests").delete().neq("interest_id", "00000000-0000-0000-0000-000000000000");
    if (delError) {
      setError(delError.message);
      setSaving(false);
      return;
    }
    if (selected.size > 0) {
      const rows = [...selected].map((interest_id) => ({
        user_id: userId,
        interest_id,
      }));
      const { error: insError } = await supabase.from("user_interests").insert(rows);
      if (insError) {
        setError(insError.message);
        setSaving(false);
        return;
      }
    }
    setInitialSelected(new Set(selected));
    setRedirecting(true);
    // Spinner zeigen, dann zur Startseite weiterleiten (saving bleibt
    // aktiviert, bis die Seite wechselt)
    setTimeout(() => router.push("/home"), 700);
  }

  const dirty = !setsEqual(selected, initialSelected);

  async function handleSuggest(e: React.FormEvent) {
    e.preventDefault();
    setSuggestMsg(null);
    const name = suggestName.trim();
    if (!suggestCat) {
      setSuggestMsg({ kind: "hint", text: "Bitte zuerst eine Kategorie wählen." });
      return;
    }
    if (!name) {
      setSuggestMsg({ kind: "hint", text: "Bitte einen Namen eingeben." });
      return;
    }

    // Gibt es das Interesse schon? Dann direkt auswählen statt vorschlagen
    const n = normalize(name);
    const existing = interests.find(
      (i) => normalize(i.name_de) === n || normalize(i.slug) === n,
    );
    if (existing) {
      toggle(existing.id);
      setSuggestName("");
      setSuggestMsg({
        kind: "hint",
        text: `„${existing.name_de}" gibt es schon — direkt ausgewählt.`,
      });
      return;
    }

    if (openSuggestions.has(n)) {
      setSuggestMsg({
        kind: "hint",
        text: `„${name}" wurde bereits vorgeschlagen und wartet auf Prüfung.`,
      });
      return;
    }

    setSuggesting(true);
    const supabase = createClient();
    const userId = (await supabase.auth.getUser()).data.user?.id;
    if (!userId) {
      setSuggestMsg({ kind: "error", text: "Nicht angemeldet." });
      setSuggesting(false);
      return;
    }
    const { error: insError } = await supabase
      .from("interest_suggestions")
      .insert({ category_id: suggestCat, name_de: name, suggested_by: userId });
    setSuggesting(false);
    if (insError) {
      setSuggestMsg({ kind: "error", text: insError.message });
      return;
    }
    setOpenSuggestions((prev) => new Set(prev).add(n));
    setSuggestName("");
    setSuggestMsg({
      kind: "ok",
      text: `„${name}" vorgeschlagen — erscheint nach Prüfung im Katalog.`,
    });
  }

  async function handlePrimaryAction() {
    if (!dirty) return;
    await save();
  }

  function toggleCat(id: string) {
    setOpenCats((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  const q = normalize(query.trim());
  const matches = (i: Interest) =>
    !q ||
    normalize(i.name_de).includes(q) ||
    normalize(i.slug).includes(q) ||
    (i.keywords ?? []).some((k) => normalize(k).includes(q));

  const totalHits =
    q === ""
      ? interests.length
      : interests.filter((i) => matches(i)).length;

  const visible = (catId: string) =>
    interests.filter((i) => i.category_id === catId && matches(i));

  return (
    <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
      <SiteNav />
      <h1 className="text-2xl font-bold">Deine Interessen</h1>
      <p className="mt-2 text-sm text-gray-600">
        Wähle so spezifisch wie möglich — die Grundlage für Treffer sind
        gemeinsame Interessen. Aktuell ausgewählt: {selected.size} von{" "}
        {interests.length.toLocaleString("de-DE")} Interessen
      </p>

      {error && <p className="mt-4 rounded bg-red-50 p-3 text-red-700">{error}</p>}

      <input
        type="search"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Interessen suchen (z. B. schach, kräuter, funk)…"
        className="mt-6 w-full rounded border border-gray-300 px-4 py-2.5 outline-none focus:border-black"
        aria-label="Interessen durchsuchen"
      />
      {q !== "" && (
        <p className="mt-2 text-sm text-gray-500">
          {totalHits} {totalHits === 1 ? "Treffer" : "Treffer"} für „{query.trim()}
          “
        </p>
      )}

      <div className="mt-8 space-y-8">
        {categories.map((cat) => {
          const items = visible(cat.id);
          if (items.length === 0) return null;
          const open = openCats.has(cat.id);
          const selectedInCat = items.filter((i) =>
            selected.has(i.id),
          ).length;
          return (
            <section key={cat.id}>
              <button
                type="button"
                onClick={() => toggleCat(cat.id)}
                aria-expanded={open}
                className="flex w-full items-baseline justify-between gap-4 border-b pb-2 text-left"
              >
                <h2 className="font-semibold">{cat.name_de}</h2>
                <span className="text-sm text-gray-500">
                  {selectedInCat > 0 && (
                    <span className="mr-2">
                      {selectedInCat} ausgewählt
                    </span>
                  )}
                  {items.length} Interessen <span aria-hidden>{open ? "▲" : "▼"}</span>
                </span>
              </button>
              {open && (
                <div className="mt-3 flex flex-wrap gap-2">
                  {items.map((interest) => {
                    const active = selected.has(interest.id);
                    return (
                      <button
                        key={interest.id}
                        onClick={() => toggle(interest.id)}
                        className={`rounded-full border px-3 py-1 text-sm transition ${
                          active
                            ? "border-black bg-black text-white"
                            : "border-gray-300 hover:border-gray-500"
                        }`}
                      >
                        {interest.name_de}
                      </button>
                    );
                  })}
                </div>
              )}
            </section>
          );
        })}
        {q !== "" && totalHits === 0 && (
          <p className="rounded border p-6 text-gray-600">
            Keine Treffer für „{query.trim()}“ — tippe es anders oder wähle
            direkt aus den Kategorien.
          </p>
        )}
      </div>

      <div className="sticky bottom-4 mt-10 rounded-lg border bg-white p-4 shadow">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <form
            onSubmit={handleSuggest}
            className="flex min-w-0 flex-1 flex-col gap-2"
            aria-label="Neues Interesse vorschlagen"
          >
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
              <select
                value={suggestCat}
                onChange={(e) => setSuggestCat(e.target.value)}
                aria-label="Kategorie für den Vorschlag"
                className="rounded border border-gray-300 bg-white px-3 py-2 text-sm outline-none focus:border-black sm:w-56"
              >
                <option value="">Kategorie wählen…</option>
                {categories.map((cat) => (
                  <option key={cat.id} value={cat.id}>
                    {cat.name_de}
                  </option>
                ))}
              </select>
              <input
                type="text"
                value={suggestName}
                onChange={(e) => setSuggestName(e.target.value)}
                maxLength={80}
                placeholder="Fehlt ein Interesse? Hier eintragen…"
                aria-label="Name des Interesses"
                className="min-w-0 flex-1 rounded border border-gray-300 px-3 py-2 text-sm outline-none focus:border-black"
              />
              <button
                type="submit"
                disabled={suggesting}
                className="whitespace-nowrap rounded border border-black px-4 py-2 text-sm font-medium transition hover:bg-black hover:text-white disabled:opacity-50"
              >
                {suggesting ? "Reiche ein…" : "Interesse hinzufügen"}
              </button>
            </div>
            {suggestMsg && (
              <p
                className={`text-xs ${
                  suggestMsg.kind === "ok"
                    ? "text-green-700"
                    : suggestMsg.kind === "error"
                      ? "text-red-700"
                      : "text-gray-600"
                }`}
                role="status"
              >
                {suggestMsg.text}
              </p>
            )}
            {openSuggestions.size > 0 && !suggestMsg && (
              <p className="text-xs text-gray-500">
                {openSuggestions.size} Vorschlag{openSuggestions.size === 1 ? "" : "e"} in Prüfung
              </p>
            )}
          </form>

          <button
            onClick={handlePrimaryAction}
            disabled={saving || redirecting || !dirty}
            className="flex shrink-0 items-center justify-center gap-2 rounded bg-black px-5 py-2 font-medium text-white hover:bg-gray-800 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {(saving || redirecting) && (
              <svg
                className="h-4 w-4 animate-spin"
                viewBox="0 0 24 24"
                fill="none"
                aria-hidden
              >
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 0 1 8-8v4a4 4 0 0 0-4 4H4z"
                />
              </svg>
            )}
            {saving
              ? "Speichern…"
              : redirecting
                ? "Weiterleiten…"
                : "Speichern"}
          </button>
        </div>
      </div>
    </main>
  );
}
