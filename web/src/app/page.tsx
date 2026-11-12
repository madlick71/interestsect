import { Suspense } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { Background } from "@/app/components/background";
import { DashedLine } from "@/app/components/dashed-line";
import { Button } from "@/app/components/ui/button";

async function CtaButtons() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    return (
      <div className="mt-8 flex flex-wrap gap-4">
        <Button asChild size="lg">
          <Link href="/interests">Meine Interessen</Link>
        </Button>
        <Button variant="outline" size="lg" asChild>
          <Link href="/home">Treffer anzeigen</Link>
        </Button>
      </div>
    );
  }

  return (
    <Button asChild size="lg" className="mt-8">
      <Link href="/login">Jetzt starten — 30 Tage kostenlos</Link>
    </Button>
  );
}

export default function Home() {
  return (
    <Background>
      <main className="py-32 lg:py-44">
        <div className="container flex flex-col justify-between gap-10 md:gap-14 lg:flex-row lg:gap-20">
          <div className="flex-1">
            <h1 className="text-4xl font-bold tracking-tight text-balance md:text-5xl lg:text-6xl">
              InterestSect
            </h1>
            <p className="text-muted-foreground mt-5 max-w-xl text-lg leading-snug">
              Das soziale Netzwerk für echte Treffen. Kein Newsfeed, keine
              Likes, keine Werbung — nur gemeinsame Interessen und Menschen,
              die sie teilen.
            </p>

            <Suspense fallback={<div className="mt-8 h-10" />}>
              <CtaButtons />
            </Suspense>
          </div>

          <div className="relative flex flex-1 flex-col justify-center max-lg:pt-8 lg:pl-10">
            <DashedLine
              orientation="vertical"
              className="absolute top-0 left-0 max-lg:hidden"
            />
            <DashedLine
              orientation="horizontal"
              className="absolute top-0 lg:hidden"
            />
            <ul className="space-y-6">
              <li className="flex gap-3 lg:gap-4">
                <span aria-hidden="true">🤝</span>
                <span>Kontaktaufnahme über gemeinsame Interessen</span>
              </li>
              <li className="flex gap-3 lg:gap-4">
                <span aria-hidden="true">🌳</span>
                <span>Fokus auf reale Treffen statt Bildschirmzeit</span>
              </li>
              <li className="flex gap-3 lg:gap-4">
                <span aria-hidden="true">📖</span>
                <span>Riesiges, sehr spezifisches Interessen-Verzeichnis</span>
              </li>
              <li className="flex gap-3 lg:gap-4">
                <span aria-hidden="true">🚫</span>
                <span>
                  Keine Werbung. 30 Tage testen, danach 1 €/Monat.
                </span>
              </li>
            </ul>
          </div>
        </div>
      </main>
    </Background>
  );
}
