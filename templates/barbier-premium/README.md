# Barbier Premium — Template HTML une page

Template de site vitrine haut de gamme pour barbier / salon de coiffure homme.
**Un seul fichier** (`index.html`), aucune dépendance, aucun framework :
s'ouvre dans le navigateur, s'héberge n'importe où (Netlify, GitHub Pages, OVH…).

## Personnalisation en 10 minutes

Tout se modifie dans `index.html` avec un simple éditeur de texte.

### 1. Les couleurs (lignes 12–16)

```css
:root{
  --bg:#0e0e10;      /* fond principal */
  --bg2:#15151a;     /* fond alterné */
  --card:#1a1a20;    /* cartes */
  --line:#26262f;    /* bordures */
  --or:#c9a24b;      /* couleur d'accent (boutons, titres) */
  --or2:#e7c878;     /* accent clair (survol) */
  --txt:#f3f1ea;     /* texte */
  --mut:#9a99a3;     /* texte secondaire */
}
```
Changez `--or` et `--or2` pour adapter le template à n'importe quelle identité
(cuivre, acier, bordeaux…). Tout le site suit automatiquement.

### 2. Le nom et les textes

- Titre de l'onglet + description Google : lignes 6–7 (`<title>` et `<meta name="description">`)
- Nom du salon : cherchez « ATELIER BLADE » et remplacez partout
- Prestations et prix, horaires, adresse, téléphone : directement dans les sections
  correspondantes (repérées par des commentaires `<!-- ... -->`)

### 3. Les polices (ligne 10)

Le template utilise **Bebas Neue** (titres) et **Inter** (texte) via Google Fonts.
Pour changer : remplacez le lien Google Fonts et le nom de la police ligne 22.

### 4. Mise en ligne

Glissez le dossier sur [Netlify Drop](https://app.netlify.com/drop) (gratuit) —
en ligne en 30 secondes. Ou déposez `index.html` chez n'importe quel hébergeur.

## Contenu du template

- Hero plein écran avec appel à l'action « Réserver »
- Grille de prestations avec prix
- Section « L'atelier » (présentation + valeurs)
- Avis clients
- FAQ dépliante (HTML natif, accessible)
- Bloc contact : horaires, adresse, téléphone cliquable
- Design responsive (mobile, tablette, desktop)
- Animations d'apparition au défilement (JavaScript vanilla, ~30 lignes)

## Support

Une question ? contact : cyril.chabane@outlook.fr
