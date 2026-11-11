// Erzeugt eine Stripe-Checkout-Session für das 1-€-Abo.
// Wird vom angemeldeten Nutzer aufgerufen (JWT-Pflicht, Standard).
// Der 30-Tage-Trial läuft app-seitig (subscriptions.trial_end);
// das bezahlte Abo startet daher ohne erneuten Stripe-Trial.

import Stripe from "npm:stripe@^18";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Nicht angemeldet", { status: 401 });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Nicht angemeldet", { status: 401 });

  const { priceId, successUrl, cancelUrl } = await req.json();
  if (!priceId || !successUrl || !cancelUrl) {
    return new Response("priceId, successUrl und cancelUrl erforderlich", {
      status: 400,
    });
  }

  const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);

  // Bestehenden Customer wiederverwenden, falls schon einmal bezahlt
  const { data: existing } = await supabase
    .from("subscriptions")
    .select("stripe_customer_id")
    .eq("user_id", user.id)
    .maybeSingle();

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    line_items: [{ price: priceId, quantity: 1 }],
    client_reference_id: user.id,
    metadata: { user_id: user.id },
    customer: existing?.stripe_customer_id ?? undefined,
    success_url: successUrl,
    cancel_url: cancelUrl,
  });

  return new Response(JSON.stringify({ url: session.url }), {
    headers: { "Content-Type": "application/json" },
  });
});
