"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { Background } from "@/app/components/background";
import { Button } from "@/app/components/ui/button";

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
      options: {
        emailRedirectTo: `${location.origin}/auth/callback`,
      },
    });
    if (error) {
      setError(error.message);
      return;
    }
    setSent(true);
  }

  if (sent) {
    return (
      <Background>
        <main className="mx-auto max-w-md px-4 py-16">
          <h1 className="text-2xl font-bold tracking-tight">
            Prüfe dein Postfach
          </h1>
          <p className="mt-4 text-muted-foreground">
            Wir haben dir einen Anmeldelink geschickt. Bitte
            überprüfe dein E-Mail-Postfach und klicke auf den Link,
            um dich anzumelden.
          </p>
        </main>
      </Background>
    );
  }

  return (
    <Background>
      <main className="mx-auto max-w-md px-4 py-16">
        <h1 className="text-2xl font-bold tracking-tight">Anmelden</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Ohne Passwort: Wir schicken dir einen Link per E-Mail.
        </p>
        <form
          onSubmit={handleMagicLink}
          className="mt-6 space-y-4"
        >
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="du@example.org"
            className="w-full rounded-md border border-input bg-background px-3 py-2 outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/30"
          />
          {error && (
            <p className="text-sm text-red-600">{error}</p>
          )}
          <Button type="submit" className="w-full">
            Login-Link senden
          </Button>
        </form>
      </main>
    </Background>
  );
}
