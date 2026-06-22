#!/usr/bin/env python3
"""Genere les slides du carrousel TikTok Top 5 combats UFC (1080x1350)."""
from PIL import Image, ImageDraw, ImageFont
import os

W, H = 1080, 1350
OUT = "carrousel_images"
os.makedirs(OUT, exist_ok=True)

# Couleurs
BLACK = (10, 10, 12)
DARK = (20, 20, 24)
RED = (214, 32, 38)
RED_DARK = (140, 18, 22)
WHITE = (245, 245, 245)
GREY = (170, 170, 175)
GOLD = (230, 190, 90)

FONT_DIR = "/usr/share/fonts/truetype/dejavu"
def font(size, bold=True):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    return ImageFont.truetype(os.path.join(FONT_DIR, name), size)

def bg(draw, img):
    # degrade vertical noir -> rouge tres sombre en bas
    for y in range(H):
        t = y / H
        r = int(BLACK[0] + (RED_DARK[0] - BLACK[0]) * (t ** 2))
        g = int(BLACK[1] + (RED_DARK[1] - BLACK[1]) * (t ** 2))
        b = int(BLACK[2] + (RED_DARK[2] - BLACK[2]) * (t ** 2))
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    # bande rouge en haut
    draw.rectangle([0, 0, W, 14], fill=RED)
    draw.rectangle([0, H - 14, W, H], fill=RED)

def wrap(draw, text, fnt, max_w):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if draw.textlength(test, font=fnt) <= max_w:
            cur = test
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines

def draw_center(draw, text, fnt, y, color, max_w=W - 120, line_gap=14):
    lines = wrap(draw, text, fnt, max_w)
    for ln in lines:
        w = draw.textlength(ln, font=fnt)
        draw.text(((W - w) / 2, y), ln, font=fnt, fill=color)
        asc, desc = fnt.getmetrics()
        y += asc + desc + line_gap
    return y

def badge(draw, text, cx, cy, fnt, pad=28):
    w = draw.textlength(text, font=fnt)
    asc, desc = fnt.getmetrics()
    h = asc + desc
    x0, y0 = cx - w / 2 - pad, cy - h / 2 - pad // 2
    x1, y1 = cx + w / 2 + pad, cy + h / 2 + pad // 2
    draw.rounded_rectangle([x0, y0, x1, y1], radius=20, fill=RED)
    draw.text((cx - w / 2, cy - h / 2), text, font=fnt, fill=WHITE)

def slide(idx, builder):
    img = Image.new("RGB", (W, H), BLACK)
    d = ImageDraw.Draw(img)
    bg(d, img)
    builder(d)
    path = os.path.join(OUT, f"slide_{idx}.png")
    img.save(path, "PNG")
    print("ok", path)

# ---- SLIDE 1 : COUVERTURE ----
def s1(d):
    draw_center(d, "TOP 5", font(170), 240, RED)
    draw_center(d, "DES PLUS GROS COMBATS", font(64), 470, WHITE)
    draw_center(d, "DE L'HISTOIRE DE L'UFC", font(64), 560, WHITE)
    # ligne deco
    d.line([(180, 700), (W - 180, 700)], fill=GOLD, width=4)
    draw_center(d, "Le n°1 a litteralement", font(50), 770, GREY)
    draw_center(d, "SAUVE l'UFC", font(72), 850, GOLD)
    badge(d, "SWIPE  >>", W / 2, 1130, font(56))
slide(1, s1)

# ---- SLIDES CLASSEMENT ----
def rank_slide(num, titre, combat, lignes):
    def builder(d):
        # numero geant en filigrane
        big = font(420)
        nstr = f"{num}"
        w = d.textlength(nstr, font=big)
        d.text(((W - w) / 2, 60), nstr, font=big, fill=(45, 16, 18))
        badge(d, f"N°{num}", W / 2, 150, font(60))
        draw_center(d, titre, font(46), 270, GOLD)
        y = draw_center(d, combat, font(70), 400, WHITE)
        d.line([(150, y + 20), (W - 150, y + 20)], fill=RED, width=4)
        yy = y + 70
        for emo, txt in lignes:
            yy = draw_center(d, f"{emo}  {txt}", font(42), yy, GREY, max_w=W - 130, line_gap=10)
            yy += 18
    return builder

slide(2, rank_slide(5, "LE PLUS GROS CHOC DE L'HISTOIRE",
    "Holly Holm  vs  Ronda Rousey",
    [("DATE", "UFC 193 - 14 nov. 2015, Melbourne"),
     ("FIN", "Holm gagne par KO (head kick), round 2"),
     ("HYPE", "Rousey etait INVAINCUE et la plus grosse star du sport. Mise KO par une outsider. La plus grande surprise de l'UFC.")]))

slide(3, rank_slide(4, "LA GUERRE DE 25 MINUTES",
    "Dan Henderson  vs  Shogun Rua",
    [("DATE", "UFC 139 - 19 nov. 2011, San Jose"),
     ("FIN", "Henderson gagne par decision unanime, 5 rounds"),
     ("HYPE", "Classe n°1 par ESPN. 5 rounds de violence non-stop entre 2 legendes. Rua a failli tout renverser au dernier round.")]))

slide(4, rank_slide(3, "LE COMBAT LE PLUS BRUTAL",
    "Robbie Lawler  vs  Rory MacDonald II",
    [("DATE", "UFC 189 - 11 juil. 2015, Las Vegas"),
     ("FIN", "Lawler garde son titre par TKO, round 5"),
     ("HYPE", "Le face-a-face sanglant de fin de round 4 est culte. Combat de l'annee 2015. Cite comme LE plus grand combat de l'UFC.")]))

slide(5, rank_slide(2, "LE COMBAT LE PLUS VENDU",
    "Khabib  vs  Conor McGregor",
    [("DATE", "UFC 229 - 6 oct. 2018, Las Vegas"),
     ("FIN", "Khabib gagne par soumission, round 4"),
     ("HYPE", "~2,4 MILLIONS d'achats PPV : record absolu jamais battu. + la bagarre generale apres le combat. Khabib reste invaincu.")]))

slide(6, rank_slide(1, "LE COMBAT QUI A SAUVE L'UFC",
    "Forrest Griffin  vs  Stephan Bonnar",
    [("DATE", "TUF 1 Finale - 9 avril 2005, Las Vegas"),
     ("FIN", "Griffin gagne par decision unanime, 3 rounds"),
     ("HYPE", "Diffuse en direct gratuit alors que l'UFC etait au bord de la faillite. 15 min de guerre qui ont fait exploser le MMA.")]))

# ---- SLIDE 7 : CTA ----
def s7(d):
    draw_center(d, "T'ES D'ACCORD ?", font(96), 280, RED)
    d.line([(180, 470), (W - 180, 470)], fill=GOLD, width=4)
    draw_center(d, "Quel combat tu mettrais N°1 ?", font(54), 560, WHITE)
    draw_center(d, "Dis-le en commentaire", font(54), 650, WHITE)
    badge(d, "COMMENTE  v", W / 2, 850, font(56))
    draw_center(d, "Abonne-toi pour la PARTIE 2", font(48), 1020, GOLD)
slide(7, s7)

print("\nTermine -> dossier:", OUT)
