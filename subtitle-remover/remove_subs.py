#!/usr/bin/env python3
"""
remove_subs.py — Enlève les sous-titres incrustés d'une vidéo.

Methode : filtre "delogo" de FFmpeg. Il efface une zone rectangulaire
(là où sont les sous-titres) en reconstruisant les pixels à partir du
contour. Léger, rapide, sans IA lourde ni GPU.

Marche bien quand le fond derrière le sous-titre est simple/flou.
Pour un fond très détaillé qui bouge, vise plutôt un outil d'inpainting
(voir le README, section "Qualité maximale").

Exemples :
    # Zone par défaut (bas de l'écran, auto-calculée)
    python remove_subs.py video.mp4

    # Choisir le fichier de sortie
    python remove_subs.py video.mp4 -o propre.mp4

    # Régler la hauteur de la bande à effacer (en % de la hauteur)
    python remove_subs.py video.mp4 --band 22

    # Zone manuelle exacte (x y largeur hauteur, en pixels)
    python remove_subs.py video.mp4 --box 40 1500 1000 220
"""

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def check_ffmpeg():
    """Vérifie que ffmpeg et ffprobe sont installés."""
    for tool in ("ffmpeg", "ffprobe"):
        if shutil.which(tool) is None:
            sys.exit(
                f"❌ '{tool}' introuvable.\n"
                "   Installe FFmpeg :\n"
                "   - Mac      : brew install ffmpeg\n"
                "   - Windows  : winget install Gyan.FFmpeg  (ou choco install ffmpeg)\n"
                "   - Linux    : sudo apt install ffmpeg"
            )


def get_dimensions(video: Path):
    """Retourne (largeur, hauteur) de la vidéo via ffprobe."""
    out = subprocess.run(
        [
            "ffprobe", "-v", "error",
            "-select_streams", "v:0",
            "-show_entries", "stream=width,height",
            "-of", "json", str(video),
        ],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        sys.exit(f"❌ Impossible de lire la vidéo :\n{out.stderr.strip()}")
    stream = json.loads(out.stdout)["streams"][0]
    return int(stream["width"]), int(stream["height"])


def default_box(width: int, height: int, band_pct: float):
    """
    Calcule la zone des sous-titres : une bande en bas de l'écran.
    band_pct = hauteur de la bande en % de la hauteur totale.
    On laisse une petite marge sur les côtés et tout en bas.
    """
    band_h = int(height * band_pct / 100)
    margin_x = int(width * 0.04)          # 4% de marge gauche/droite
    bottom_margin = int(height * 0.03)    # 3% de marge sous le texte

    x = margin_x
    w = width - 2 * margin_x
    h = band_h
    y = height - band_h - bottom_margin

    # delogo refuse une zone qui touche le bord : on garde >= 1px partout
    x = max(1, x)
    y = max(1, y)
    w = min(w, width - x - 1)
    h = min(h, height - y - 1)
    return x, y, w, h


def main():
    p = argparse.ArgumentParser(
        description="Enlève les sous-titres incrustés d'une vidéo (FFmpeg delogo)."
    )
    p.add_argument("input", help="Vidéo source (mp4, mov, ...)")
    p.add_argument("-o", "--output", help="Fichier de sortie (défaut: <nom>_clean.mp4)")
    p.add_argument(
        "--band", type=float, default=18.0,
        help="Hauteur de la bande à effacer, en %% de la hauteur (défaut: 18)",
    )
    p.add_argument(
        "--box", nargs=4, type=int, metavar=("X", "Y", "W", "H"),
        help="Zone manuelle exacte en pixels (prioritaire sur --band)",
    )
    args = p.parse_args()

    check_ffmpeg()

    src = Path(args.input)
    if not src.exists():
        sys.exit(f"❌ Fichier introuvable : {src}")

    out = Path(args.output) if args.output else src.with_name(src.stem + "_clean.mp4")

    width, height = get_dimensions(src)
    if args.box:
        x, y, w, h = args.box
    else:
        x, y, w, h = default_box(width, height, args.band)

    print(f"📐 Vidéo : {width}x{height}")
    print(f"🎯 Zone effacée : x={x} y={y} w={w} h={h}")
    print(f"💾 Sortie : {out}")
    print("⏳ Traitement en cours...")

    cmd = [
        "ffmpeg", "-y", "-i", str(src),
        "-vf", f"delogo=x={x}:y={y}:w={w}:h={h}",
        "-c:a", "copy",          # on garde l'audio tel quel
        str(out),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(f"❌ Échec FFmpeg :\n{res.stderr.strip()[-1500:]}")

    print(f"✅ Terminé : {out}")
    print("   Vérifie le rendu. Si la zone est mal placée, ajuste --band ou --box.")


if __name__ == "__main__":
    main()
