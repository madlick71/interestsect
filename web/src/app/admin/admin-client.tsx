"use client";

import { useCallback, useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import SiteNav from "@/app/components/SiteNav";

type Suggestion = {
  id: string;
  name_de: string;
  status: string;
  created_at: string;
  decided_at: string | null;
  category: { id: string; name_de: string } | null;
  suggester: { display_name: string } | null;
};

type Category = { id: string; name_de: string };

function formatDate(iso: string) {
  return new Date(iso).toLocaleDateString("de-DE", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}

// Genehmigen = in den Katalog übernehmen (RPC legt die Interest an bzw.
// verlinkt eine bestehende), Ablehnen = verwirfen. Beides nur für Admins.
export default function AdminClient() {
  const [suggestions, setSuggestions] = useState<Suggestion[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const supabase = createClient();
    const [sugRes, catRes] = await Promise.all([
      supabase
        .from("interest_suggestions")
        .select(
          `id, name_de, status, created_at, decided_at,
           category:interest_categories(id, name_de),
           suggester:profiles!interest_suggestions_suggested_by_fkey(display_name)`,
        )
        .order("created_at", { ascending: false })
        .limit(200),
      supabase
        .from("interest_categories")
        .select("id, name_de")
        .order("sort_order"),
    ]);
    if (sugRes.error || catRes.error) {
      setError(sugRes.error?.message ?? catRes.error!.message);
      return;
    }
    setSuggestions(sugRes.data ?? []);
    setCategories(catRes.data ?? []);
    setError(null);
  }, []);

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, [load]);

  async function decide(id: string, action: "approve" | "reject") {
    setBusyId(id);
    setError(null);
    const supabase = createClient();
    const fn =
      action === "approve" ? "approve_interest_suggestion" : "reject_interest_suggestion";
    const { error: rpcError } = await supabase.rpc(fn, { p_suggestion_id: id });
    if (rpcError) {
      setError(rpcError.message);
      setBusyId(null);
      return;
    }
    await load();
    setBusyId(null);
  }

  // Kategorie eines offenen Vorschlags korrigieren (vor dem Genehmigen);
  // entschiedene Vorschläge sperrt das Backend zusätzlich ab.
  async function changeCategory(id: string, categoryId: string) {
    setBusyId(id);
    setError(null);
    const supabase = createClient();
    const { error: rpcError } = await supabase.rpc("set_interest_suggestion_category", {
      p_suggestion_id: id,
      p_category_id: categoryId,
    });
    if (rpcError) {
      setError(rpcError.message);
      setBusyId(null);
      return;
    }
    setSuggestions((prev) =>
      prev.map((s) =>
        s.id === id
          ? {
              ...s,
              category: {
                id: categoryId,
                name_de: categories.find((c) => c.id === categoryId)?.name_de ?? "",
              },
            }
          : s,
      ),
    );
    setBusyId(null);
  }

  const pending = suggestions.filter((s) => s.status === "pending");
  const decided = suggestions.filter((s) => s.status !== "pending");

  return (
    <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
      <SiteNav />
      <h1 className="text-2xl font-bold">Vorschläge prüfen</h1>
      <p className="mt-2 text-sm text-gray-600">
        Genehmigte Interessen fließen in den Katalog und stehen danach allen
        Nutzern zur Auswahl. Die Kategorie lässt sich vor dem Genehmigen
        korrigieren. Offen: {pending.length}
      </p>

      {error && (
        <p className="mt-4 rounded bg-red-50 p-3 text-red-700">{error}</p>
      )}

      {loading ? (
        <p className="mt-8 text-gray-600">Lade…</p>
      ) : (
        <>
          <section className="mt-8" aria-label="Offene Vorschläge">
            <h2 className="border-b pb-2 font-semibold">Offene Vorschläge</h2>
            {pending.length === 0 && (
              <p className="mt-4 text-gray-600">
                Keine offenen Vorschläge — alles geprüft.
              </p>
            )}
            <ul className="mt-4 space-y-3">
              {pending.map((s) => (
                <li
                  key={s.id}
                  className="flex flex-col gap-3 rounded border p-4 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="min-w-0">
                    <p className="font-medium">{s.name_de}</p>
                    <p className="text-sm text-gray-500">
                      von {s.suggester?.display_name ?? "unbekannt"} ·{" "}
                      {formatDate(s.created_at)}
                    </p>
                    <select
                      value={s.category?.id ?? ""}
                      onChange={(e) => changeCategory(s.id, e.target.value)}
                      disabled={busyId === s.id}
                      aria-label={`Kategorie für „${s.name_de}"`}
                      className="mt-2 rounded border border-gray-300 bg-white px-2 py-1 text-sm outline-none focus:border-black"
                    >
                      {categories.map((cat) => (
                        <option key={cat.id} value={cat.id}>
                          {cat.name_de}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="flex shrink-0 gap-2">
                    <button
                      onClick={() => decide(s.id, "approve")}
                      disabled={busyId === s.id}
                      className="rounded bg-black px-4 py-2 text-sm font-medium text-white hover:bg-gray-800 disabled:opacity-50"
                    >
                      Genehmigen
                    </button>
                    <button
                      onClick={() => decide(s.id, "reject")}
                      disabled={busyId === s.id}
                      className="rounded border border-gray-300 px-4 py-2 text-sm hover:border-gray-500 disabled:opacity-50"
                    >
                      Ablehnen
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          </section>

          {decided.length > 0 && (
            <section className="mt-12" aria-label="Entschiedene Vorschläge">
              <h2 className="border-b pb-2 font-semibold">Bereits entschieden</h2>
              <ul className="mt-4 space-y-2">
                {decided.map((s) => (
                  <li
                    key={s.id}
                    className="flex flex-wrap items-center gap-2 text-sm text-gray-600"
                  >
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs ${
                        s.status === "approved"
                          ? "bg-green-50 text-green-700"
                          : "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {s.status === "approved" ? "genehmigt" : "abgelehnt"}
                    </span>
                    <span className="font-medium text-gray-900">{s.name_de}</span>
                    <span>
                      {s.category?.name_de ?? "—"} ·{" "}
                      {s.decided_at ? formatDate(s.decided_at) : ""}
                    </span>
                  </li>
                ))}
              </ul>
            </section>
          )}
        </>
      )}
    </main>
  );
}
