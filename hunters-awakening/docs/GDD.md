# 📜 Game Design Document — L'Éveil des Chasseurs

## Vision

Un MMORPG Roblox où chaque joueur est un **chasseur** qui grimpe les rangs (E → S) en
fermant des portails apparus dans une grande ville fantasy. Boucle de jeu :

**Explorer la ville → repérer un portail → nettoyer le donjon → looter/XP → améliorer
son build (stats + équipement) → viser un rang plus élevé → recommencer, en guilde.**

## Boucle de progression

| Élément | Mécanique |
|---|---|
| Niveau (1 → 100) | XP des monstres + bonus de fin de donjon. Courbe : `100 × niveau^1.6` |
| Points de stats | +5 par niveau, répartition libre (builds personnalisés) |
| Rang de chasseur | E→D : 5 donjons E réussis, D→C : 8, C→B : 12, B→A : 16, A→S : 20 |
| Équipement | Drop en donjon, le rang du donjon = le rang de l'objet |

### Les 6 stats

- **Force** : +2 % dégâts physiques / point
- **Agilité** : réduction de cooldown (max 35 %) + critique
- **Intelligence** : dégâts magiques + mana max
- **Endurance** : +12 PV / point + défense
- **Vitesse** : vitesse de déplacement (plafonnée)
- **Chance** : +0,4 % chance de drop / point (max +20 %) + critique

### Défense (anti « one-shot »)

`réduction = défense / (défense + 100)`, plafonnée à 75 %. Courbe à rendements
décroissants : impossible de devenir invincible.

## Donjons

- Un portail apparaît toutes les ~40 s (max 6 actifs), rang tiré au sort :
  E 38 %, D 26 %, C 16 %, B 10 %, A 7 %, S 3 %.
- Les joueurs à moins de 25 studs du portail entrent **en groupe**.
- 2 à 4 vagues selon le rang, puis un **boss** (drop garanti, minimum Rare).
- Limite de 10 minutes ; si tous les joueurs meurent, le donjon échoue.
- Les donjons sont **instanciés** à 6000+ studs de la ville (12 slots simultanés).

## Économie (double monnaie)

| | Or 🪙 | Cristaux 💎 |
|---|---|---|
| Source | Monstres, donjons, vente d'objets | Robux, passe de combat, abonnement |
| Usage | Guilde (création 10k, QG 250k) | Réservé au premium / cosmétique (à étendre) |

**Règle d'or** : jamais de « pay-to-win » direct — les Robux achètent du confort
(XP boost, passe premium, QG) mais pas de puissance brute inaccessible autrement.

## Monétisation

1. **Abonnement « Chasseur d'Élite »** (Game Pass) : ×2 XP, +50 % Or, 50 cristaux/jour
2. **Passe de combat premium** (Game Pass) : 2e piste de récompenses, 30 paliers/saison
3. **Packs de cristaux** (produits développeur)
4. **QG de guilde** : 250 000 Or **ou** achat direct en Robux (produit développeur)

## Anti-triche

Le client n'envoie que des **intentions** (« je lance la compétence 2 vers ce point »).
Le serveur valide : classe possédée, cooldown, mana, portée — puis calcule les dégâts.
Les monnaies, l'XP, le loot et les achats ne transitent jamais par le client.

## Extensions prévues (v0.2+)

- Ruptures de portail : un portail ignoré trop longtemps déverse ses monstres dans la ville
- Rôles de groupe et matchmaking de donjon
- Éveil (2e classe) au niveau 50, arbres de talents
- Hôtel des ventes entre joueurs (économie dirigée par les joueurs)
- Événements de guilde : raids hebdomadaires avec classement
