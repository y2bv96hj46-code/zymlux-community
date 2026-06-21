# Zymlux Community — Mise en route (≈ 10 min)

L'application (comptes, salons de chat en temps réel, espace perso) a besoin
d'un **backend Supabase** — gratuit. Voici les étapes, dans l'ordre.

---

## 1. Créer un projet Supabase
1. Va sur **https://supabase.com** → **Start your project** → connecte-toi (GitHub possible).
2. **New project** :
   - Nom : `zymlux`
   - Mot de passe base de données : choisis-en un (note-le, pas besoin ensuite).
   - Région : `West EU (Paris)` ou la plus proche.
3. Attends ~2 min que le projet se crée.

## 2. Installer la base de données
1. Dans le menu de gauche : **SQL Editor** → **New query**.
2. Ouvre le fichier **`supabase-schema.sql`** de ce dépôt, **copie tout**, colle-le.
3. Clique **Run** (en bas à droite). Tu dois voir « Success ».
   → Ça crée les tables, la sécurité, les salons de départ et un premier défi.

## 3. Récupérer tes 2 clés
1. Menu de gauche : **Project Settings** (la roue dentée) → **API**
   *(ou « Data API » selon la version)*.
2. Repère :
   - **Project URL** → ex. `https://abcd1234.supabase.co`
   - **Project API keys → `anon` `public`** → une longue chaîne `eyJ...`
3. Ouvre **`assets/config.js`** dans ce dépôt et remplace les 2 valeurs :
   ```js
   window.ZYMLUX_CONFIG = {
     SUPABASE_URL: "https://abcd1234.supabase.co",
     SUPABASE_ANON_KEY: "eyJhbGciOi....(ta clé anon)"
   };
   ```
   > La clé `anon` est **publique** par nature : aucun risque à la mettre ici.
   > Ne mets **jamais** la clé `service_role`.

## 4. (Recommandé) Connexion immédiate sans confirmation d'e-mail
Pour que les comptes fonctionnent tout de suite (sans cliquer un lien reçu par mail) :
- **Authentication** → **Sign In / Providers** (ou **Settings**) → **Email** →
  désactive **« Confirm email »** → **Save**.

Tu pourras le réactiver plus tard quand tu configureras l'envoi d'e-mails.

## 5. Autoriser ton site (URL)
- **Authentication** → **URL Configuration** → **Site URL** :
  `https://y2bv96hj46-code.github.io/zymlux-community/`
- Ajoute aussi en **Redirect URLs** la même adresse.

## 6. C'est prêt 🎉
- Page d'accueil : `https://y2bv96hj46-code.github.io/zymlux-community/`
- Application : `…/zymlux-community/app.html`

Crée un compte, ouvre un 2ᵉ navigateur (ou ton téléphone) avec un autre compte,
et regarde le **chat en temps réel** fonctionner. ✦

---

## Notes
- **Sécurité** : chaque membre ne peut lire/écrire que ses propres données
  (fiche de route, humeur) grâce aux règles RLS. Les messages des salons sont
  visibles par les membres connectés.
- **Modération** : à prévoir avant une vraie ouverture publique (signalement,
  bannissement, filtres). On l'ajoutera dans une prochaine étape.
- **Coût** : le plan gratuit Supabase suffit largement pour démarrer.
