import type { Metadata } from "next";
import { Mulish } from "next/font/google";
import "./globals.css";

// Variable Font: alle Schnitte (200–1000) in einer Datei,
// Basis-Gewicht wird per CSS gesteuert (globals.css: font-weight 300 = Light)
const mulish = Mulish({
  variable: "--font-mulish",
  subsets: ["latin", "latin-ext"],
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL("https://interestsect.com"),
  title: "InterestSect",
  description:
    "Das soziale Netzwerk für echte Treffen — gemeinsame Interessen statt Newsfeed.",
  openGraph: {
    title: "InterestSect",
    description:
      "Das soziale Netzwerk für echte Treffen — gemeinsame Interessen statt Newsfeed.",
    url: "https://interestsect.com",
    siteName: "InterestSect",
    locale: "de_DE",
    type: "website",
  },
  verification: {
    // Google Search Console (Domain-Property via DNS-TXT;
    // Meta-Tag als Fallback für eine URL-Präfix-Property)
    google: "6KZdDQfuXbTxZNh8h7VyJ-S0DOq9irhobJZLIVyAjwQ",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="de" className={`${mulish.variable} h-full antialiased`}>
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
