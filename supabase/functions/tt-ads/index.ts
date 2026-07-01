// ============================================================
//  ZYMLUX TREND — Robot collecteur "publicités"
//  Edge Function Supabase (Deno).
//  Interroge l'API officielle Meta Ad Library pour chaque mot-clé
//  surveillé, enregistre les pubs actives (Facebook / Instagram).
//
//  Prérequis : un token Meta dans les secrets de la fonction :
//    supabase secrets set META_TOKEN=EAAB...
//  Obtention du token : https://www.facebook.com/ads/library/api/
//  (compte développeur + identité vérifiée pour certains pays).
//
//  Déploiement : supabase functions deploy tt-ads --no-verify-jwt
// ============================================================
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const META_TOKEN   = Deno.env.get("META_TOKEN") ?? "";
const API_VERSION  = "v21.0";
const PER_KEYWORD  = 25;

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  if (!META_TOKEN) {
    return json({ skipped: true, reason: "META_TOKEN absent — configure le secret pour activer l'espion pubs." });
  }

  const db = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: keywords, error } = await db
    .from("tt_keywords").select("*").eq("active", true);
  if (error) return json({ error: error.message }, 500);

  const report: Record<string, unknown>[] = [];

  for (const kw of keywords ?? []) {
    let saved = 0, kwErr: string | null = null;
    try {
      const params = new URLSearchParams({
        access_token: META_TOKEN,
        search_terms: kw.keyword,
        ad_reached_countries: JSON.stringify([kw.country]),
        ad_active_status: "ACTIVE",
        ad_type: "ALL",
        fields: "id,page_name,ad_snapshot_url,ad_delivery_start_time,publisher_platforms",
        limit: String(PER_KEYWORD),
      });
      const url = `https://graph.facebook.com/${API_VERSION}/ads_archive?${params}`;
      const res = await fetch(url, { signal: AbortSignal.timeout(20000) });
      const body = await res.json().catch(() => null);

      if (body?.error) { kwErr = body.error.message; }
      else {
        for (const ad of body?.data ?? []) {
          const { error: upErr } = await db.from("tt_ads").upsert({
            archive_id:   ad.id,
            keyword:      kw.keyword,
            country:      kw.country,
            page_name:    ad.page_name ?? null,
            snapshot_url: ad.ad_snapshot_url ?? null,
            platforms:    (ad.publisher_platforms ?? []).join(", "),
            started:      ad.ad_delivery_start_time ?? null,
            seen_at:      new Date().toISOString(),
          }, { onConflict: "archive_id" });
          if (!upErr) saved++;
        }
      }
    } catch (e) {
      kwErr = String((e as Error).message ?? e);
    }
    report.push({ keyword: kw.keyword, country: kw.country, saved, error: kwErr });
  }

  return json({ ok: true, keywords: report.length, detail: report });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body, null, 2), {
    status, headers: { ...cors, "Content-Type": "application/json" },
  });
}
