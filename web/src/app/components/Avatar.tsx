// Rundes Profilbild mit Initialen-Fallback — links neben dem Namen
// (Trefferliste, Karten-Popup, Profilseite).
type AvatarProps = {
  url: string | null | undefined;
  name: string;
  size?: number;
  className?: string;
};

export default function Avatar({
  url,
  name,
  size = 44,
  className = "",
}: AvatarProps) {
  const initial = (name ?? "").trim().charAt(0).toUpperCase() || "?";
  return (
    <span
      className={`inline-flex shrink-0 select-none items-center justify-center overflow-hidden rounded-full bg-gray-200 font-semibold text-gray-600 ${className}`}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.42) }}
    >
      {url ? (
        // Externe Supabase-Storage-URL (mit Cache-Buster) — kein next/image.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={url}
          alt={`Profilbild von ${name}`}
          width={size}
          height={size}
          className="h-full w-full object-cover"
          referrerPolicy="no-referrer"
        />
      ) : (
        initial
      )}
    </span>
  );
}
