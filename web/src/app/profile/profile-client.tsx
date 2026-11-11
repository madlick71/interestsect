"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import LocationInput from "@/app/components/LocationInput";
import SiteNav from "@/app/components/SiteNav";

type ProfileData = {
  display_name: string;
  region: string;
  lat: number | null;
  lng: number | null;
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
  const [regionLat, setRegionLat] = useState<number | null>(initial.lat);
  const [regionLng, setRegionLng] = useState<number | null>(initial.lng);
  const [bio, setBio] = useState(initial.bio);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function save() {
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const { error: updateError } = await supabase
      .from("profiles")
      .update({
        display_name: displayName,
        region: region || null,
        lat: regionLat,
        lng: regionLng,
        bio,
      })
      .eq("id", userId);
    if (updateError) {
      setError(updateError.message);
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
    regionLat !== initial.lat ||
    regionLng !== initial.lng ||
    bio !== initial.bio;

  return (
    <main className="mx-auto w-full px-4 py-12 md:w-[70%]">
      <SiteNav />
      <h1 className="text-2xl font-bold">Mein Profil</h1>

      {/* Einheitlicher Seitenrahmen (volle Breite, max. 1600px); Formulare in lesbarer Breite */}
      <div className="mx-auto max-w-xl">
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
              (für Treffer in der Nähe — bitte aus den Vorschlägen wählen)
            </span>
          </label>
          <LocationInput
            id="region"
            value={region}
            onChange={(v) => {
              setRegion(v);
              // Manuelle Eingabe nach einer Auswahl macht die Koordinaten
              // ungültig — erst ein neuer Pick liefert sie wieder.
              setRegionLat(null);
              setRegionLng(null);
            }}
            onPick={(choice) => {
              setRegion(choice.label);
              setRegionLat(choice.lat);
              setRegionLng(choice.lon);
            }}
            placeholder="z. B. München"
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 outline-none focus:border-black"
          />
          <p className="mt-1 text-xs text-gray-400">
            {regionLat != null && regionLng != null
              ? "Ort mit Koordinaten gespeichert — du erscheinst auf der Treffer-Karte."
              : "Nur per Vorschlagsauswahl wird der Ort auf der Karte verortet."}
          </p>
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
      </div>
    </main>
  );
}
