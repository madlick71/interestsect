"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import SiteNav from "@/app/components/SiteNav";
import { Background } from "@/app/components/background";
import { Button } from "@/app/components/ui/button";

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

const SEARCH_LIMIT = 150;
const PAGE = 200;

export default function InterestsClient() {
  const router = useRouter();
  const [categories, setCategories] = useState<Category[]>([]);
  // Lazy Loading: Interessen werden nie komplett geladen, sondern pro
  // Kategorie beim Aufklappen (200er-Seiten) bzw. per serverseitiger
  // Suche (search_interests-RPC) nachgeladen
  const [catCounts, setCatCounts] = useState<Record<string, number>>({});
  const [catPages, setCatPages] = useState<Record<string, Interest[]>>({});
  const [loadingCats, setLoadingCats] = useState<Set<string>>(new Set());
  const [searchResults, setSearchResults] = useState<Interest[]>([]);
  const [searching, setSearching] = useState(false);
  const [searchCapped, setSearchCapped] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [selectedByCat, setSelectedByCat] = useState<Record<string, number>>({});
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
    const [cats, mine, pending, counts] = await Promise.all([
      supabase
        .from("interest_categories")
        .select("id, slug, name_de, sort_order")
        .order("sort_order"),
      // Auswahlen mit Kategorie-Join (für „X ausgewählt" je Kategorie)
      supabase.from("user_interests").select("interest_id, interests(category_id)"),
      // Eigene offene Vorschläge (Admins sehen alle) — für Hinweise
      supabase
        .from("interest_suggestions")
        .select("id, name_de")
        .eq("status", "pending")
        .limit(100),
      supabase.rpc("interest_category_counts"),
    ]);
    if (cats.error || mine.error || pending.error || counts.error) {
      setError("Konnte Daten nicht laden. Bist du angemeldet?");
      return;
    }
    setCategories(cats.data ?? []);
    const cnt: Record<string, number> = {};
    for (const r of (counts.data ?? []) as { category_id: string; n: number }[]) {
      cnt[r.category_id] = Number(r.n);
    }
    setCatCounts(cnt);
    const sel = (mine.data ?? []).map(
      (r: { interest_id: string }) => r.interest_id,
    );
    const byCat: Record<string, number> = {};
    for (const r of (mine.data ?? []) as {
      interest_id: string;
      interests: { category_id: string } | null;
    }[]) {
      const c = r.interests?.category_id;
      if (c) byCat[c] = (byCat[c] ?? 0) + 1;
    }
    setSelected(new Set(sel));
    setInitialSelected(new Set(sel));
    setSelectedByCat(byCat);
    setOpenSuggestions(
      new Set((pending.data ?? []).map((r) => normalize(r.name_de))),
    );
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  // Suche: entprellt serverseitig (search_interests-RPC), max. SEARCH_LIMIT
  useEffect(() => {
    const t = setTimeout(async () => {
      const q = query.trim();
      if (q === "") {
        setSearchResults([]);
        setSearchCapped(false);
        setSearching(false);
        return;
      }
      setSearching(true);
      const supabase = createClient();
      const { data, error: rpcError } = await supabase.rpc("search_interests", {
        q,
        lmt: SEARCH_LIMIT,
        offs: 0,
      });
      setSearching(false);
      if (rpcError) {
        setError("Suche fehlgeschlagen: " + rpcError.message);
        return;
      }
      setSearchResults((data ?? []) as Interest[]);
      setSearchCapped((data?.length ?? 0) >= SEARCH_LIMIT);
    }, 250);
    return () => clearTimeout(t);
  }, [query]);

  async function fetchCatPage(catId: string, from: number) {
    setLoadingCats((prev) => new Set(prev).add(catId));
    const supabase = createClient();
    const { data, error: pageError } = await supabase
      .from("interests")
      .select("id, category_id, slug, name_de, keywords")
      .eq("category_id", catId)
      .order("name_de")
      .range(from, from + PAGE - 1);
    setLoadingCats((prev) => {
      const next = new Set(prev);
      next.delete(catId);
      return next;
    });
    if (pageError) {
      setError("Interessen konnten nicht geladen werden.");
      return;
    }
    setCatPages((prev) => {
      const page = (data ?? []) as Interest[];
      return { ...prev, [catId]: from === 0 ? page : [...(prev[catId] ?? []), ...page] };
    });
  }

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
    // (serverseitig suchen — der Katalog liegt nicht mehr komplett im Client)
    const n = normalize(name);
    const supabase = createClient();
    const { data: found } = await supabase.rpc("search_interests", {
      q: name,
      lmt: 50,
      offs: 0,
    });
    const existing = ((found ?? []) as Interest[]).find(
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
    const willOpen = !openCats.has(id);
    setOpenCats((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
    // Lazy Loading: erste Seite erst beim Aufklappen nachladen
    if (willOpen && !catPages[id]) void fetchCatPage(id, 0);
  }

  function renderChip(interest: Interest) {
    const active = selected.has(interest.id);
    return (
      <button
        key={interest.id}
        onClick={() => toggle(interest.id)}
        className={`rounded-full border px-3 py-1 text-sm transition ${
          active
            ? "border-primary bg-primary text-primary-foreground"
            : "border-input hover:border-muted-foreground"
        }`}
      >
        {interest.name_de}
      </button>
    );
  }

  const q = query.trim();
  const totalCount = Object.values(catCounts).reduce((a, b) => a + b, 0);

  return (
    <Background>
      <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
        <SiteNav />
        <h1 className="text-2xl font-bold tracking-tight">Deine Interessen</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Wähle so spezifisch wie möglich — die Grundlage für Treffer sind
          gemeinsame Interessen. Aktuell ausgewählt: {selected.size} von{" "}
          {totalCount.toLocaleString("de-DE")} Interessen
        </p>

        {error && <p className="mt-4 rounded bg-red-50 p-3 text-red-700">{error}</p>}

        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Interessen suchen (z. B. schach, kräuter, funk)…"
          className="mt-6 w-full rounded-md border border-input bg-background px-4 py-2.5 outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/30"
          aria-label="Interessen durchsuchen"
        />
        {q !== "" && (
          <p className="mt-2 text-sm text-muted-foreground">
            {searching
              ? "Suche…"
              : `${searchResults.length}${searchCapped ? "+" : ""} ${
                  searchResults.length === 1 ? "Treffer" : "Treffer"
                } für „${q}“`}
          </p>
        )}

        <div className="mt-8 space-y-8">
          {q === "" &&
            categories.map((cat) => {
              const total = catCounts[cat.id] ?? 0;
              if (total === 0) return null;
              const items = catPages[cat.id] ?? [];
              const open = openCats.has(cat.id);
              const selectedInCat = selectedByCat[cat.id] ?? 0;
              return (
                <section key={cat.id}>
                  <button
                    type="button"
                    onClick={() => toggleCat(cat.id)}
                    aria-expanded={open}
                    className="flex w-full items-baseline justify-between gap-4 border-b pb-2 text-left"
                  >
                    <h2 className="font-semibold">{cat.name_de}</h2>
                    <span className="text-sm text-muted-foreground">
                      {selectedInCat > 0 && (
                        <span className="mr-2">
                          {selectedInCat} ausgewählt
                        </span>
                      )}
                      {total.toLocaleString("de-DE")} Interessen{" "}
                      <span aria-hidden>{open ? "▲" : "▼"}</span>
                    </span>
                  </button>
                  {open && (
                    <>
                      {loadingCats.has(cat.id) && items.length === 0 ? (
                        <p className="mt-3 text-sm text-muted-foreground">
                          Lade Interessen…
                        </p>
                      ) : (
                        <div className="mt-3 flex flex-wrap gap-2">
                          {items.map((interest) => renderChip(interest))}
                        </div>
                      )}
                      {items.length < total && (
                        <button
                          type="button"
                          onClick={() => void fetchCatPage(cat.id, items.length)}
                          disabled={loadingCats.has(cat.id)}
                          className="mt-3 rounded-md border border-input px-3 py-1.5 text-sm text-muted-foreground transition hover:border-muted-foreground disabled:opacity-50"
                        >
                          {loadingCats.has(cat.id)
                            ? "Lade…"
                            : `Weitere laden (${
                                total - items.length
                              } offen)`}
                        </button>
                      )}
                    </>
                  )}
                </section>
              );
            })}

          {q !== "" && !searching && searchResults.length === 0 && (
            <p className="rounded-lg border p-6 text-muted-foreground">
              Keine Treffer für „{q}“ — tippe es anders oder reiche den
              Begriff unten als Vorschlag ein.
            </p>
          )}

          {q !== "" &&
            categories.map((cat) => {
              const items = searchResults.filter(
                (i) => i.category_id === cat.id,
              );
              if (items.length === 0) return null;
              return (
                <section key={cat.id}>
                  <h2 className="border-b pb-2 font-semibold">
                    {cat.name_de}
                    <span className="ml-2 text-sm font-normal text-muted-foreground">
                      {items.length} Treffer
                    </span>
                  </h2>
                  <div className="mt-3 flex flex-wrap gap-2">
                    {items.map((interest) => renderChip(interest))}
                  </div>
                </section>
              );
            })}

          {q !== "" && searchCapped && (
            <p className="text-sm text-muted-foreground">
              Zeige die ersten {SEARCH_LIMIT} Treffer — tippe weiter, um die
              Suche zu verfeinern.
            </p>
          )}
        </div>

        <div className="sticky bottom-4 mt-10 rounded-xl border bg-background/95 p-4 shadow-md backdrop-blur">
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
                  className="rounded-md border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/30 sm:w-56"
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
                  className="min-w-0 flex-1 rounded-md border border-input bg-background px-3 py-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/30"
                />
                <Button
                  type="submit"
                  variant="outline"
                  disabled={suggesting}
                  className="shrink-0"
                >
                  {suggesting ? "Reiche ein…" : "Interesse hinzufügen"}
                </Button>
              </div>
              {suggestMsg && (
                <p
                  className={`text-xs ${
                    suggestMsg.kind === "ok"
                      ? "text-green-700"
                      : suggestMsg.kind === "error"
                        ? "text-red-700"
                        : "text-muted-foreground"
                  }`}
                  role="status"
                >
                  {suggestMsg.text}
                </p>
              )}
              {openSuggestions.size > 0 && !suggestMsg && (
                <p className="text-xs text-muted-foreground">
                  {openSuggestions.size} Vorschlag{openSuggestions.size === 1 ? "" : "e"} in Prüfung
                </p>
              )}
            </form>

            <Button
              onClick={handlePrimaryAction}
              disabled={saving || redirecting || !dirty}
              className="shrink-0"
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
            </Button>
          </div>
        </div>
      </main>
    </Background>
  );
}
