import { Suspense } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

async function CtaButtons() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    return (
      <div className="mt-10 flex gap-4">
        <Link
          href="/interests"
          className="rounded bg-black px-5 py-2.5 font-medium text-white hover:bg-gray-800"
        >
          Meine Interessen
        </Link>
        <Link
          href="/home"
          className="rounded border border-black px-5 py-2.5 font-medium hover:bg-gray-100"
        >
          Treffer anzeigen
        </Link>
      </div>
    );
  }

  return (
    <Link
      href="/login"
      className="mt-10 inline-block rounded bg-black px-5 py-2.5 font-medium text-white hover:bg-gray-800"
    >
      Jetzt starten — 30 Tage kostenlos
    </Link>
  );
}

export default function Home() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">
        InterestSect
      </h1>
      <p className="mt-4 text-lg text-gray-700">
        Das soziale Netzwerk für echte Treffen. Kein Newsfeed,
        keine Likes, keine Werbung — nur gemeinsame Interessen
        und Menschen, die sie teilen.
      </p>

      <ul className="mt-8 space-y-3 text-gray-800">
        <li>🤝 Kontaktaufnahme über gemeinsame Interessen</li>
        <li>🌳 Fokus auf reale Treffen statt Bildschirmzeit</li>
        <li>
          📖 Riesiges, sehr spezifisches Interessen-Verzeichnis
        </li>
        <li>
          🚫 Keine Werbung. 30 Tage testen, danach 1 €/Monat.
        </li>
      </ul>

      <Suspense fallback={<div className="mt-10 h-11" />}>
        <CtaButtons />
      </Suspense>
    </main>
  );
}
