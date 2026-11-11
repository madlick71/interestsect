// Stripe Webhook: hält die subscriptions-Tabelle synchron.
// Deploy mit verify_jwt = false (siehe supabase/config.toml) — Stripe
// authentifiziert sich über die Signatur, nicht über App-JWTs.

import Stripe from "npm:stripe@^18";
import { createClient } from "npm:@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY")!);
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

async function upsertSubscription(
  userId: string,
  customerId: string,
  sub: Stripe.Subscription,
) {
  const { error } = await supabase.from("subscriptions").upsert({
    user_id: userId,
    stripe_customer_id: customerId,
    stripe_subscription_id: sub.id,
    status: sub.status, // active, past_due, canceled, ...
    current_period_end: new Date(sub.current_period_end * 1000).toISOString(),
    updated_at: new Date().toISOString(),
  });
  if (error) console.error("upsert fehlgeschlagen:", error.message);
}

Deno.serve(async (req) => {
  const signature = req.headers.get("stripe-signature");
  const payload = await req.text();

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      payload,
      signature!,
      Deno.env.get("STRIPE_WEBHOOK_SECRET")!,
    );
  } catch (err) {
    return new Response(`Ungültige Signatur: ${err.message}`, { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.client_reference_id ??
          session.metadata?.user_id;
        if (userId && typeof session.subscription === "string") {
          const sub = await stripe.subscriptions.retrieve(
            session.subscription,
          );
          await upsertSubscription(
            userId,
            session.customer as string,
            sub,
          );
        }
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const { data: row } = await supabase
          .from("subscriptions")
          .select("user_id")
          .eq("stripe_subscription_id", sub.id)
          .maybeSingle();
        if (row) {
          await upsertSubscription(row.user_id, sub.customer as string, sub);
        }
        break;
      }
      default:
        // Andere Event-Typen interessieren uns (noch) nicht.
        break;
    }
  } catch (err) {
    console.error(`Fehler bei ${event.type}:`, err);
    return new Response("Verarbeitungsfehler", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});
