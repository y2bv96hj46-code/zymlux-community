# Enlève-sous-titres 🎬

Petit outil pour **effacer les sous-titres incrustés** d'une vidéo, en ligne de commande.
Idéal pour récupérer des clips propres avant de remettre **ta** voix off + tes sous-titres.

## 1. Prérequis (à installer une fois)

- **Python 3** : https://www.python.org/downloads/
- **FFmpeg** :
  - Mac : `brew install ffmpeg`
  - Windows : `winget install Gyan.FFmpeg` (ou `choco install ffmpeg`)
  - Linux : `sudo apt install ffmpeg`

Vérifie que ça marche : ouvre un terminal et tape `ffmpeg -version`.

## 2. Utilisation

Mets ta vidéo dans le même dossier que `remove_subs.py`, puis :

```bash
# Le plus simple : efface la zone en bas (par défaut)
python remove_subs.py ma_video.mp4
```

Ça crée `ma_video_clean.mp4`. **Vérifie le rendu.**

### Si la zone est mal placée

```bash
# Bande plus haute (sous-titres sur 2 lignes par ex.)
python remove_subs.py ma_video.mp4 --band 25

# Choisir le nom de sortie
python remove_subs.py ma_video.mp4 -o propre.mp4

# Zone exacte en pixels : --box X Y LARGEUR HAUTEUR
python remove_subs.py ma_video.mp4 --box 40 1500 1000 220
```

Astuce pour trouver les coordonnées exactes : ouvre la vidéo dans un lecteur,
repère où est le texte. X = depuis la gauche, Y = depuis le haut.

## 3. Limites de cette méthode

Le filtre `delogo` **reconstruit** la zone à partir des pixels autour.
- ✅ Très bon quand le fond derrière le texte est **simple ou flou** (ciel, mur, dégradé).
- ⚠️ Sur un fond **très détaillé qui bouge**, ça peut laisser une légère trace floue.

## 4. Qualité maximale (inpainting IA)

Pour un résultat parfait sur fonds complexes, utilise un vrai outil d'inpainting :

- **En ligne (0 install)** : Vmake AI, Media.io, Pollo AI, CreatOK.ai
- **Gratuit / local / sans perte** :
  [video-subtitle-remover](https://github.com/YaoFANGUK/video-subtitle-remover)
  (plus lourd, idéalement un PC avec GPU)
