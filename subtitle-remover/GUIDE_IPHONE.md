# 📱 Enlever les sous-titres sur iPhone — 100% gratuit

Pas besoin d'ordi ni de site payant. On installe un mini-Linux gratuit sur ton
iPhone (l'app **iSH**) et on y fait tourner **FFmpeg**, le moteur vidéo des pros.

⚠️ C'est un peu technique au début, mais tu ne le fais qu'**une seule fois**.
Ensuite chaque vidéo = 2 lignes à taper.

---

## Étape 1 — Installer iSH (une fois)

1. Va sur l'**App Store**
2. Cherche **« iSH Shell »** (icône terminal noir) → **Installe** (gratuit)
3. Ouvre l'app. Tu vois un écran noir avec du texte : c'est ton terminal.

## Étape 2 — Installer FFmpeg dans iSH (une fois)

Dans iSH, tape ces 2 lignes (Entrée après chacune) :

```sh
apk update
apk add ffmpeg
```

⏳ Ça télécharge FFmpeg (1-2 min). Quand c'est fini, tape `ffmpeg -version`
pour vérifier : si ça affiche du texte, c'est bon. ✅

## Étape 3 — Mettre ta vidéo dans iSH

1. Enregistre la vidéo virale dans ton app **Fichiers** (ou Photos → Enregistrer dans Fichiers)
2. Ouvre l'app **Fichiers** → **Parcourir** → tu vois un dossier **« iSH »**
3. **Copie ta vidéo** dans ce dossier iSH, renomme-la simplement : `video.mp4`

> Astuce : appuie longuement sur la vidéo → Copier → va dans le dossier iSH → Coller.

## Étape 4 — Récupérer mon script (une fois)

Dans iSH, tape (en une ligne) :

```sh
curl -O https://raw.githubusercontent.com/y2bv96hj46-code/zymlux-community/claude/slt-p5woju/subtitle-remover/remove_subs.sh
```

(Si `curl` ne marche pas : `apk add curl` puis recommence.)

## Étape 5 — Lancer ! (à chaque vidéo)

```sh
sh remove_subs.sh video.mp4
```

Ça crée **`video_clean.mp4`** sans les sous-titres, dans le même dossier
(donc visible dans l'app Fichiers → iSH). Tu n'as plus qu'à le récupérer
dans Photos et l'envoyer dans Cortia. 🎉

---

## Si les sous-titres sont mal effacés

Selon la vidéo, le texte est en bas ou au milieu :

```sh
# Sous-titres au MILIEU de l'écran (style TikTok)
sh remove_subs.sh video.mp4 22 center

# Bande du bas plus haute (texte sur 2 lignes)
sh remove_subs.sh video.mp4 25 bottom
```

Tu joues sur le **chiffre** (hauteur de la zone en %) et **bottom / center**
jusqu'à ce que le texte disparaisse bien.

---

## ⚠️ À savoir

- **Vitesse** : iSH émule Linux, donc c'est **plus lent** qu'un ordi. Pour un
  clip TikTok court (< 1 min) ça passe. Évite les longues vidéos.
- **Qualité** : marche très bien sur fond simple/flou (anime, ciel). Sur un fond
  très détaillé qui bouge, ça peut laisser une légère trace.
- C'est **gratuit et illimité** : aucune limite de nombre de vidéos.

## Routine quotidienne (une fois tout installé)

```sh
# 1. (mets video.mp4 dans le dossier iSH via l'app Fichiers)
# 2. lance :
sh remove_subs.sh video.mp4
# 3. récupère video_clean.mp4 dans Fichiers → envoie dans Cortia
```
