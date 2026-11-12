import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import AdminClient from "./admin-client";

// Nur für Admins (public.app_admins): nicht-Admins landen auf /home.
// Der Admin-Check läuft über RLS — jede Zeile sieht nur ihren eigenen
// Eintrag, nicht-Admins bekommen also nichts zurück.
export default async function AdminPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/");

  const { data: isAdmin } = await supabase
    .from("app_admins")
    .select("user_id")
    .eq("user_id", user.id)
    .maybeSingle();

  if (!isAdmin) redirect("/home");

  return <AdminClient />;
}
