import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import ProfileClient from "./profile-client";
import { resolveAvatarUrl, signAvatarUrls } from "@/lib/avatars";

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/");

  const [{ data: profile }, { data: sub }] = await Promise.all([
    supabase
      .from("profiles")
      .select("display_name, region, lat, lng, bio, avatar_url")
      .eq("id", user.id)
      .single(),
    supabase
      .from("subscriptions")
      .select("status, trial_end, current_period_end")
      .eq("user_id", user.id)
      .single(),
  ]);

  // Privater Bucket: eigenen Avatar-Pfad zu einer Signed URL signieren.
  const avatarUrls = await signAvatarUrls(supabase, [profile?.avatar_url]);

  return (
    <ProfileClient
      userId={user.id}
      email={user.email ?? ""}
      initial={{
        display_name: profile?.display_name ?? "",
        region: profile?.region ?? "",
        lat: profile?.lat ?? null,
        lng: profile?.lng ?? null,
        bio: profile?.bio ?? "",
        avatarUrl: resolveAvatarUrl(avatarUrls, profile?.avatar_url),
      }}
      subscription={{
        status: sub?.status ?? "none",
        trialEnd: sub?.trial_end ?? null,
        periodEnd: sub?.current_period_end ?? null,
      }}
    />
  );
}
