import type { SupabaseClient } from "@supabase/supabase-js";

// Der Avatar-Bucket ist privat: profiles.avatar_url enthält den
// Storage-Pfad (<user-id>/avatar.jpg), gerendert wird eine kurzlebige
// Signed URL. Die Seiten (dynamisch, pro Request gerendert) signieren
// serverseitig; nach Ablauf läuft einfach der nächste Seitenaufruf.
const AVATAR_SIGNED_URL_EXPIRY = 60 * 60; // 1 Stunde

export type AvatarUrlMap = Map<string, string>;

function isStoragePath(value: string): boolean {
  return !/^https?:\/\//i.test(value);
}

/**
 * Signiert alle übergebenen Avatar-Pfade in einem Batch-Aufruf.
 * Bereits vollständige HTTP-URLs (Legacy-Einträge) werden unverändert
 * übernommen. Bei Fehlern bleibt der jeweilige Eintrag unsigniert →
 * die Avatar-Komponente zeigt die Initialen-Fallback.
 */
export async function signAvatarUrls(
  supabase: SupabaseClient,
  paths: (string | null | undefined)[],
): Promise<AvatarUrlMap> {
  const map: AvatarUrlMap = new Map();
  const unique = [
    ...new Set(
      paths.filter(
        (p): p is string => !!p && isStoragePath(p),
      ),
    ),
  ];
  for (const p of paths) {
    if (p && !isStoragePath(p)) map.set(p, p);
  }
  if (unique.length === 0) return map;

  const { data, error } = await supabase.storage
    .from("avatars")
    .createSignedUrls(unique, AVATAR_SIGNED_URL_EXPIRY);
  if (error || !data) return map;

  for (const entry of data) {
    if (!entry.error && entry.signedUrl && entry.path) {
      map.set(entry.path, entry.signedUrl);
    }
  }
  return map;
}

/** Pfad → signierte URL (oder null → Initialen-Fallback). */
export function resolveAvatarUrl(
  map: AvatarUrlMap,
  path: string | null | undefined,
): string | null {
  if (!path) return null;
  return map.get(path) ?? null;
}
