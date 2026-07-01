// ============================================================
//  ZYMLUX TREND — Robot collecteur "boutiques Shopify"
//  Edge Function Supabase (Deno).
//  Va chercher /products.json (endpoint PUBLIC) de chaque boutique
//  active, enregistre les produits + un snapshot d'historique.
//  Déploiement :  supabase functions deploy tt-scan --no-verify-jwt
//  Déclenchement : manuel (bouton "Scanner"), ou cron (voir SQL).
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const STORES_PER_RUN = 25;   // boutiques traitées par exécution
const MAX_PAGES      = 5;    // pages products.json par boutique (250 produits/page)

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function num(v: unknown): number | null {
  const n = parseFloat(String(v ?? ""));
  return Number.isFinite(n) ? n : null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const db = createClient(SUPABASE_URL, SERVICE_KEY);

  // (optionnel) scanner une seule boutique : { store_id: "..." }
  let onlyStore: string | null = null;
  try { onlyStore = (await req.json())?.store_id ?? null; } catch { /* body vide */ }

  let q = db.from("tt_stores").select("*").eq("active", true)
            .order("last_scanned_at", { ascending: true, nullsFirst: true })
            .limit(STORES_PER_RUN);
  if (onlyStore) q = db.from("tt_stores").select("*").eq("id", onlyStore);

  const { data: stores, error } = await q;
  if (error) return json({ error: error.message }, 500);

  const report: Record<string, unknown>[] = [];

  for (const store of stores ?? []) {
    const domain = String(store.domain).replace(/^https?:\/\//, "").replace(/\/.*$/, "");
    let scanned = 0, added = 0, storeErr: string | null = null;

    try {
      for (let page = 1; page <= MAX_PAGES; page++) {
        const url = `https://${domain}/products.json?limit=250&page=${page}`;
        const res = await fetch(url, {
          headers: { "User-Agent": "Mozilla/5.0 ZymluxTrend/1.0" },
          signal: AbortSignal.timeout(15000),
        });
        if (!res.ok) { if (page === 1) storeErr = `HTTP ${res.status}`; break; }

        const body = await res.json().catch(() => null);
        const products = body?.products ?? [];
        if (!products.length) break;

        for (const [i, p] of products.entries()) {
          const variants = p.variants ?? [];
          const prices = variants.map((v: any) => num(v.price)).filter((x: any) => x != null) as number[];
          const comps  = variants.map((v: any) => num(v.compare_at_price)).filter((x: any) => x != null) as number[];
          const availVariants = variants.filter((v: any) => v.available).length;

          const row = {
            store_id:       store.id,
            shopify_id:     p.id,
            handle:         p.handle ?? null,
            title:          p.title ?? "(sans titre)",
            product_type:   p.product_type || null,
            vendor:         p.vendor || null,
            image:          p.images?.[0]?.src ?? null,
            price:          prices.length ? Math.min(...prices) : null,
            compare_at:     comps.length ? Math.max(...comps) : null,
            variants_count: variants.length,
            available:      availVariants > 0,
            published_at:   p.published_at ?? p.created_at ?? null,
            position:       (page - 1) * 250 + i,
            last_seen:      new Date().toISOString(),
          };

          // upsert SANS first_seen → conservé à l'insertion, jamais écrasé
          const { data: up, error: upErr } = await db
            .from("tt_products")
            .upsert(row, { onConflict: "store_id,shopify_id" })
            .select("id, first_seen")
            .single();
          if (upErr || !up) continue;

          scanned++;
          // produit "nouveau" si vu pour la première fois il y a < 2 min
          if (Date.now() - new Date(up.first_seen).getTime() < 120000) added++;

          await db.from("tt_snapshots").insert({
            product_id: up.id,
            price: row.price,
            available_variants: availVariants,
            position: row.position,
          });
        }

        if (products.length < 250) break; // dernière page
      }
    } catch (e) {
      storeErr = String((e as Error).message ?? e);
    }

    await db.from("tt_stores").update({
      product_count: scanned,
      last_scanned_at: new Date().toISOString(),
      last_error: storeErr,
    }).eq("id", store.id);

    report.push({ domain, scanned, added, error: storeErr });
  }

  return json({ ok: true, stores: report.length, detail: report });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body, null, 2), {
    status, headers: { ...cors, "Content-Type": "application/json" },
  });
}
