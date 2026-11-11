import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import ProfileClient from "./profile-client";

export default async function ProfilePage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/");

  const [{ data: profile }, { data: sub }] = await Promise.all([
    supabase
      .from("profiles")
      .select("display_name, region, bio")
      .eq("id", user.id)
      .single(),
    supabase
      .from("subscriptions")
      .select("status, trial_end, current_period_end")
      .eq("user_id", user.id)
      .single(),
  ]);

  return (
    <ProfileClient
      userId={user.id}
      email={user.email ?? ""}
      initial={{
        display_name: profile?.display_name ?? "",
        region: profile?.region ?? "",
        bio: profile?.bio ?? "",
      }}
      subscription={{
        status: sub?.status ?? "none",
        trialEnd: sub?.trial_end ?? null,
        periodEnd: sub?.current_period_end ?? null,
      }}
    />
  );
}
