import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import InterestsClient from "./interests-client";

// Serverseitiger Auth-Schutz (die Seite ist sonst statisch und
// würde ohne Worker-Aufruf aus den Assets ausgeliefert)
export default async function InterestsPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/");

  return <InterestsClient />;
}
