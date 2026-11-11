"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";

type ProfileData = {
  display_name: string;
  region: string;
  bio: string;
};

type SubscriptionInfo = {
  status: string;
  trialEnd: string | null;
  periodEnd: string | null;
};

function formatDate(iso: string | null) {
  if (!iso) return null;
  return new Date(iso).toLocaleDateString("de-DE", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

export default function ProfileClient({
  userId,
  email,
  initial,
  subscription,
}: {
  userId: string;
  email: string;
  initial: ProfileData;
  subscription: SubscriptionInfo;
}) {
  const router = useRouter();
  const [displayName, setDisplayName] = useState(initial.display_name);
  const [region, setRegion] = useState(initial.region);
  const [bio, setBio] = useState(initial.bio);
  const [saving, setSaving] = useState(false);
  const [savedAt, setSavedAt] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function save() {
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const { error: updateError } = await supabase
      .from("profiles")
      .update({ display_name: displayName, region, bio })
      .eq("id", userId);
    if (updateError) {
      setError(updateError.message);
    } else {
      setSavedAt(new Date().toLocaleTimeString("de-DE"));
    }
    setSaving(false);
  }

  async function logout() {
    if (!window.confirm("Möchtest du dich wirklich abmelden?")) return;
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/");
    router.refresh();
  }

  const trialEndDate = formatDate(subscription.trialEnd);
  const periodEndDate = formatDate(subscription.periodEnd);
  const dirty =
    displayName !== initial.display_name ||
    region !== initial.region ||
    bio !== initial.bio;

  return (
    <main className="mx-auto max-w-2xl px-4 py-12">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Mein Profil</h1>
        <Link
          href="/home"
          className="text-sm text-gray-500 underline hover:text-gray-800"
        >
          zurück
        </Link>
      </div>

      <div className="mt-6 space-y-5">
        <div>
          <label htmlFor="email" className="block text-sm text-gray-500">
            E-Mail
          </label>
          <input
            id="email"
            type="email"
            value={email}
            disabled
            className="mt-1 w-full rounded border border-gray-200 bg-gray-50 px-3 py-2 text-gray-500"
          />
        </div>

        <div>
          <label htmlFor="displayName" className="block text-sm text-gray-500">
            Anzeigename
          </label>
          <input
            id="displayName"
            type="text"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 outline-none focus:border-black"
          />
        </div>

        <div>
          <label htmlFor="region" className="block text-sm text-gray-500">
            Region{" "}
            <span className="text-gray-400">
              (für Treffer in der Nähe)
            </span>
          </label>
          <input
            id="region"
            type="text"
            value={region}
            onChange={(e) => setRegion(e.target.value)}
            placeholder="z. B. München"
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 outline-none focus:border-black"
          />
        </div>

        <div>
          <label htmlFor="bio" className="block text-sm text-gray-500">
            Über mich
          </label>
          <textarea
            id="bio"
            value={bio}
            onChange={(e) => setBio(e.target.value)}
            rows={4}
            maxLength={500}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 outline-none focus:border-black"
          />
        </div>

        {error && (
          <p className="rounded bg-red-50 p-3 text-sm text-red-700">{error}</p>
        )}

        <div className="flex items-center gap-4">
          <button
            onClick={save}
            disabled={saving || !dirty}
            className="rounded bg-black px-5 py-2 font-medium text-white hover:bg-gray-800 disabled:opacity-50"
          >
            {saving ? "Speichern…" : "Speichern"}
          </button>
          {savedAt && (
            <span className="text-sm text-green-700">
              Gespeichert um {savedAt}
            </span>
          )}
        </div>
      </div>

      <section className="mt-10 rounded-lg border p-5">
        <h2 className="font-semibold">Mitgliedschaft</h2>
        {subscription.status === "trialing" && trialEndDate && (
          <p className="mt-2 text-sm text-gray-700">
            Testphase: noch aktiv bis{" "}
            <strong>{trialEndDate}</strong> — danach 1 €/Monat.
          </p>
        )}
        {subscription.status === "active" && periodEndDate && (
          <p className="mt-2 text-sm text-gray-700">
            Abo aktiv, nächster Abrechnungstag:{" "}
            <strong>{periodEndDate}</strong>.
          </p>
        )}
        {(subscription.status === "none" ||
          subscription.status === "canceled" ||
          subscription.status === "past_due") && (
          <p className="mt-2 text-sm text-gray-700">
            Kein aktives Abo. Die Zahlungsfunktion folgt in Kürze.
          </p>
        )}
      </section>

      <button
        onClick={logout}
        className="mt-10 text-sm text-gray-500 underline hover:text-gray-800"
      >
        Abmelden
      </button>
    </main>
  );
}
