"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

const LINKS = [
  { href: "/home", label: "Treffer" },
  { href: "/map", label: "Karte" },
  { href: "/interests", label: "Interessen" },
  { href: "/profile", label: "Profil" },
];

// Schlanke Hauptnavigation für die geschützten Seiten. Sticky, damit sie
// auch beim Scrollen (Interessenliste, Karte) erreichbar bleibt.
// Der Admin-Link erscheint nur, wenn die eigene Zeile in app_admins
// sichtbar ist (RLS: Admins sehen genau ihre eigene Zeile).
export default function SiteNav() {
  const pathname = usePathname();
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    createClient()
      .from("app_admins")
      .select("user_id")
      .limit(1)
      .then(({ data }) => setIsAdmin((data?.length ?? 0) > 0));
  }, []);

  const links = isAdmin
    ? [...LINKS, { href: "/admin", label: "Admin" }]
    : LINKS;

  return (
    <nav
      aria-label="Hauptnavigation"
      className="sticky top-0 z-20 -mx-4 mb-6 flex items-center gap-1 overflow-x-auto border-b border-gray-200 bg-white/95 px-4 py-2 backdrop-blur"
    >
      {links.map(({ href, label }) => {
        const active =
          pathname === href || pathname.startsWith(href + "/");
        return (
          <Link
            key={href}
            href={href}
            aria-current={active ? "page" : undefined}
            className={`whitespace-nowrap rounded-full px-3 py-1.5 text-sm transition ${
              active
                ? "bg-black text-white"
                : "text-gray-600 hover:bg-gray-100 hover:text-gray-900"
            }`}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
