"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleMagicLink(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${location.origin}/auth/callback` },
    });
    if (error) {
      setError(error.message);
      return;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <main className="mx-auto max-w-md px-4 py-16">
        <h1 className="text-2xl font-bold">Prüfe dein Postfach</h1>
        <p className="mt-4 text-gray-600">
          Wir haben dir einen Anmeldelink geschickt. Deine ersten 30 Tage
          sind kostenlos.
        </p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-md px-4 py-16">
      <h1 className="text-2xl font-bold">Anmelden</h1>
      <p className="mt-2 text-sm text-gray-600">
        Ohne Passwort: Wir schicken dir einen Link per E-Mail.
      </p>
      <form onSubmit={handleMagicLink} className="mt-6 space-y-4">
        <input
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="du@example.org"
          className="w-full rounded border px-3 py-2"
        />
        {error && <p className="text-sm text-red-600">{error}</p>}
        <button
          type="submit"
          className="w-full rounded bg-black px-4 py-2 font-medium text-white hover:bg-gray-800"
        >
          Login-Link senden
        </button>
      </form>
    </main>
  );
}
