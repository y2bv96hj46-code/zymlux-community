#!/bin/sh
# remove_subs.sh — Enlève les sous-titres incrustes d'une video.
# Version shell pensee pour tourner sur iPhone via l'app iSH (gratuite).
#
# Methode : filtre "delogo" de FFmpeg. Il efface une zone rectangulaire
# (la ou sont les sous-titres) en reconstruisant les pixels autour.
#
# Usage :
#   sh remove_subs.sh entree.mp4                 # bande du bas (defaut)
#   sh remove_subs.sh entree.mp4 18 bottom       # bande du bas, 18% de hauteur
#   sh remove_subs.sh entree.mp4 22 center       # sous-titres au milieu (style TikTok)
#   sh remove_subs.sh entree.mp4 18 bottom out.mp4
#
# Sortie par defaut : <nom>_clean.mp4

set -e

IN="$1"
BAND="${2:-18}"          # hauteur de la bande en % (defaut 18)
POS="${3:-bottom}"       # bottom | center
OUT="$4"

if [ -z "$IN" ]; then
  echo "Usage: sh remove_subs.sh entree.mp4 [pourcent] [bottom|center] [sortie.mp4]"
  exit 1
fi

if [ ! -f "$IN" ]; then
  echo "Fichier introuvable : $IN"
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "FFmpeg n'est pas installe. Dans iSH, tape :  apk add ffmpeg"
  exit 1
fi

# Sortie par defaut
if [ -z "$OUT" ]; then
  base="${IN%.*}"
  OUT="${base}_clean.mp4"
fi

# Dimensions de la video
DIM=$(ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height -of csv=p=0:s=x "$IN")
W=$(echo "$DIM" | cut -d x -f1)
H=$(echo "$DIM" | cut -d x -f2)

if [ -z "$W" ] || [ -z "$H" ]; then
  echo "Impossible de lire les dimensions de la video."
  exit 1
fi

# Calcul de la zone a effacer (awk gere les pourcentages)
# Marge laterale 4%, marge bas 3%.
read BX BY BW BH <<EOF
$(awk -v w="$W" -v h="$H" -v band="$BAND" -v pos="$POS" 'BEGIN{
  bandh = int(h*band/100);
  mx = int(w*0.04);
  x = mx;
  bw = w - 2*mx;
  if (pos == "center") {
    y = int(h/2 - bandh/2);
  } else {
    y = h - bandh - int(h*0.03);
  }
  bh = bandh;
  if (x < 1) x = 1;
  if (y < 1) y = 1;
  if (x + bw > w-1) bw = w - x - 1;
  if (y + bh > h-1) bh = h - y - 1;
  print x, y, bw, bh;
}')
EOF

echo "Video : ${W}x${H}"
echo "Zone effacee : x=$BX y=$BY w=$BW h=$BH ($POS)"
echo "Sortie : $OUT"
echo "Traitement en cours... (peut etre lent sur iPhone, patiente)"

ffmpeg -y -i "$IN" \
  -vf "delogo=x=$BX:y=$BY:w=$BW:h=$BH" \
  -c:a copy "$OUT"

echo "Termine : $OUT"
echo "Verifie le rendu. Si mal place : change le pourcentage ou bottom/center."
