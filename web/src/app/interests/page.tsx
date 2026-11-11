"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

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
};

export default function InterestsPage() {
  const router = useRouter();
  const [categories, setCategories] = useState<Category[]>([]);
  const [interests, setInterests] = useState<Interest[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);
  const [savedAt, setSavedAt] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const supabase = createClient();
    const [cats, ints, mine] = await Promise.all([
      supabase
        .from("interest_categories")
        .select("id, slug, name_de, sort_order")
        .order("sort_order"),
      supabase
        .from("interests")
        .select("id, category_id, slug, name_de")
        .order("name_de"),
      supabase.from("user_interests").select("interest_id"),
    ]);
    if (cats.error || ints.error || mine.error) {
      setError("Konnte Daten nicht laden. Bist du angemeldet?");
      return;
    }
    setCategories(cats.data ?? []);
    setInterests(ints.data ?? []);
    setSelected(new Set((mine.data ?? []).map((r) => r.interest_id)));
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
    setSavedAt(new Date().toLocaleTimeString("de-DE"));
    setSaving(false);
    // Kurze Bestätigung zeigen, dann zu den Treffern weiterleiten
    setTimeout(() => router.push("/matches"), 700);
  }

  const byCategory = (catId: string) =>
    interests.filter((i) => i.category_id === catId);

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-2xl font-bold">Deine Interessen</h1>
      <p className="mt-2 text-sm text-gray-600">
        Wähle so spezifisch wie möglich — die Grundlage für Treffer sind
        gemeinsame Interessen. Aktuell ausgewählt: {selected.size}
      </p>

      {error && <p className="mt-4 rounded bg-red-50 p-3 text-red-700">{error}</p>}

      <div className="mt-8 space-y-8">
        {categories.map((cat) => (
          <section key={cat.id}>
            <h2 className="font-semibold">{cat.name_de}</h2>
            <div className="mt-3 flex flex-wrap gap-2">
              {byCategory(cat.id).map((interest) => {
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
          </section>
        ))}
      </div>

      <div className="sticky bottom-4 mt-10 flex items-center gap-4 rounded-lg border bg-white p-4 shadow">
        <button
          onClick={save}
          disabled={saving}
          className="rounded bg-black px-5 py-2 font-medium text-white hover:bg-gray-800 disabled:opacity-50"
        >
          {saving ? "Speichern…" : "Speichern"}
        </button>
        {savedAt && (
          <span className="text-sm text-green-700">Gespeichert um {savedAt}</span>
        )}
      </div>
    </main>
  );
}
