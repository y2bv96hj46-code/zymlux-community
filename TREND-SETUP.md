# Zymlux Trend — Mise en route (≈ 15 min)

Outil de veille e-commerce **réel** : il va chercher les vrais produits des
boutiques Shopify (endpoint public `/products.json`) et les pubs actives via
l'**API officielle Meta Ad Library**, stocke tout dans **ton** Supabase et
affiche un dashboard. Plus il tourne, plus ta base grossit.

> **À comprendre** : le jour 1 ta base est vide. Elle se remplit au fur et à
> mesure des scans. Les CA/ventes exacts ne sont pas fournis (personne ne les a
> sauf Shopify) — l'outil te donne des **signaux réels** : nouveaux produits,
> prix, promos, rang catalogue, pubs actives.

---

## 1. Installer la base de données
1. Supabase → **SQL Editor** → **New query**.
2. Copie tout le contenu de **`supabase-trend.sql`**, colle, **Run**.
   → crée les tables, la sécurité (RLS), une liste de boutiques d'amorce et
   quelques mots-clés.

*(La config Supabase dans `assets/config.js` est déjà partagée avec le reste du
site — rien à changer si l'app Zymlux fonctionne déjà.)*

## 2. Déployer le robot collecteur (Edge Functions)
Il te faut le **CLI Supabase** (une fois) : https://supabase.com/docs/guides/cli

```bash
# à la racine du dépôt
supabase login
supabase link --project-ref TON_PROJECT_REF        # visible dans l'URL du dashboard

# déploie les 2 robots
supabase functions deploy tt-scan --no-verify-jwt   # boutiques Shopify
supabase functions deploy tt-ads  --no-verify-jwt   # pubs Meta (optionnel)
```

> `--no-verify-jwt` autorise le déclenchement depuis le bouton « Scanner » de
> l'interface (clé anon). Les fonctions écrivent avec la `service_role`
> (fournie automatiquement par Supabase), jamais exposée au navigateur.

## 3. (Optionnel) Activer l'espion de pubs Meta
Sans token, l'onglet **Pubs** reste vide (le reste marche).
1. Crée un token : https://www.facebook.com/ads/library/api/
   (compte développeur Meta + identité vérifiée pour certains pays).
2. Enregistre-le comme secret :
   ```bash
   supabase secrets set META_TOKEN=EAAB...ton_token
   ```

## 4. Premier scan
Ouvre **`/trend/`** sur ton site, puis :
- clique **⚡ Scanner** (barre du haut) → collecte les boutiques d'amorce, ou
- onglet **Boutiques** → **+ Ajouter & scanner** avec le domaine d'un concurrent
  (ex : `ma-boutique-concurrente.com`).

Le premier scan prend 1–2 min. Reviens : les produits apparaissent dans l'onglet
**Produits** (filtres, tri, favoris, fiche détaillée avec historique de prix).

## 5. (Recommandé) Automatiser
Pour que ça tourne tout seul (sans cliquer), décommente le bloc **pg_cron** en
bas de `supabase-trend.sql`, remplace `<PROJECT_REF>` et `<SERVICE_ROLE_KEY>`
(Project Settings → API), et relance la requête.
→ scan des boutiques toutes les 6 h, des pubs toutes les 12 h.

---

## Comment ça marche (schéma)
```
tt-scan (Edge Function, cron)                tt-ads (Edge Function, cron)
  fetch boutique.com/products.json             API Meta Ad Library
        ↓                                             ↓
        └──────────►  Supabase (tt_products, tt_snapshots, tt_ads)  ◄──────┘
                                   ↓
                    trend/index.html  (dashboard, lit avec la clé anon)
```

## Aller plus loin
- **Plus de boutiques** = plus de couverture. Ajoute tes concurrents et les
  boutiques de tes niches en continu (onglet Boutiques).
- **Détection de gagnants** : trie par *Best-sellers* (rang catalogue) et
  *Nouveautés*, croise avec les pubs actives sur le même mot-clé.
- **Estimations de ventes** : possibles en v2 en ajoutant la collecte du nombre
  d'avis et de sa vitesse (comme le font les outils du marché).

## Légal
`products.json` et la Meta Ad Library sont des sources **publiques et
officielles**. Reste dans un usage de veille concurrentielle raisonnable
(fréquence de scan modérée, pas de revente de données).
