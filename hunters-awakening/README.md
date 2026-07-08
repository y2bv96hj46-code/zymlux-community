# ⚔️ L'Éveil des Chasseurs — MMORPG Roblox

Un MMORPG complet pour Roblox, inspiré de l'univers *chasseurs & portails* (à la Solo Leveling) :
une grande ville fantasy où des **portails classés E → S** apparaissent, menant vers des **donjons
instanciés** remplis de monstres et de boss. **Tout le jeu est généré par le code** — la ville,
les donjons, les monstres, l'interface : aucun asset à installer.

> ⚠️ **Important** : le jeu est *inspiré* du genre, avec un nom et des personnages **originaux**.
> N'utilise jamais les noms/personnages de Solo Leveling (Sung Jin-Woo, etc.) : Roblox supprime
> les jeux qui violent les droits d'auteur.

---

## ✨ Fonctionnalités

| Système | Détails |
|---|---|
| 🎭 **6 classes** | Guerrier, Assassin, Mage, Archer, Gardien, Prêtre — 4 compétences uniques chacune (touches 1-4) |
| 📊 **Stats RPG** | Force, Agilité, Intelligence, Endurance, Vitesse, Chance — 5 points à répartir par niveau (touche C) |
| 🌀 **Portails E → S** | Apparition aléatoire dans la ville, pondérée par rang (E fréquent, S rarissime) |
| 🏰 **Donjons instanciés** | Vagues de monstres + boss, limite de temps, entrée en groupe (les joueurs proches du portail entrent ensemble) |
| 👹 **Bestiaire complet** | 18 monstres + 6 boss (Gobelin → Seigneur de l'Abîme), générés procéduralement |
| 🎖️ **Rang de chasseur** | E → S : réussis des donjons de ton rang pour monter |
| 💰 **Double monnaie** | Or (jeu) + Cristaux (premium, achetables en Robux) |
| ⭐ **Abonnement** | « Chasseur d'Élite » (Game Pass) : ×2 XP, +50 % Or, cristaux quotidiens |
| 🗡️ **Loot** | Objets générés (arme/armure/accessoire), 5 raretés (Commun → Mythique), bonus de stats aléatoires |
| 🎒 **Inventaire & équipement** | Équipe, vends, compare (touche I) |
| 🛡️ **Guildes** | Création (10k Or), 20 membres, **QG payable en Or OU en Robux** (touche G) |
| 🏆 **Passe de combat** | 30 paliers, piste gratuite + premium, saisonnier (touche P) |
| 💾 **Sauvegarde** | Profils DataStore avec autosave + sauvegarde à la déconnexion |
| 🔒 **Anti-triche** | Combat 100 % côté serveur : cooldowns, mana, portée et dégâts validés serveur |

---

## 🚀 Installation

### Option A — Rojo (recommandé, pro)

1. Installe [Rojo](https://rojo.space/) : `cargo install rojo` ou via [Aftman](https://github.com/LPGhatguy/aftman)
2. Installe le plugin Rojo dans Roblox Studio
3. Dans ce dossier :
   ```bash
   rojo serve
   ```
4. Dans Studio : ouvre un nouveau lieu (Baseplate → supprime la baseplate), plugin Rojo → **Connect**
5. Appuie sur **Play** ▶️

### Option B — Copier-coller (simple)

1. Dans Studio, crée cette structure :
   - `ReplicatedStorage/Shared` → colle chaque fichier de `src/shared/` dans un **ModuleScript** du même nom (sans `.luau`)
   - `ServerScriptService/Server` → un **Script** nommé `Server` contenant `init.server.luau`, avec chaque fichier de `src/server/` en **ModuleScript enfant**
   - `StarterPlayer/StarterPlayerScripts/Client` → un **LocalScript** contenant `init.client.luau`, avec chaque fichier de `src/client/` en **ModuleScript enfant**

### Configuration obligatoire avant publication

1. **Game Settings → Security → Enable Studio Access to API Services** ✅ (sinon pas de sauvegarde en Studio)
2. Crée dans le **Creator Dashboard** :
   - 1 Game Pass « Chasseur d'Élite » (abonnement)
   - 1 Game Pass « Passe Premium »
   - 1 Produit développeur « QG de Guilde »
   - 3 Produits développeur « Packs de cristaux » (ex. 100 / 550 / 1200)
3. Reporte les IDs dans `src/shared/GameConfig.luau` → section `Monetisation`

---

## 🎮 Contrôles

| Touche | Action |
|---|---|
| Clic gauche | Attaque de base |
| 1 / 2 / 3 / 4 | Compétences de classe |
| C | Statistiques (répartition de points) |
| I | Inventaire |
| G | Guilde |
| P | Passe de combat |
| E (près d'un portail) | Entrer dans le donjon |

---

## 📁 Structure du code

```
src/
├── shared/            # Configs & utilitaires (répliqués client + serveur)
│   ├── GameConfig     # Rangs, stats, monnaies, monétisation, formules
│   ├── ClassConfig    # 6 classes × 4 compétences
│   ├── MonsterConfig  # Bestiaire complet (18 monstres + 6 boss)
│   ├── ItemConfig     # Raretés, bases d'équipement, règles de drop
│   ├── BattlePassConfig # 30 paliers de la saison
│   └── Remotes / Util / UI
├── server/
│   ├── init.server    # Démarrage des services
│   ├── DataService    # Sauvegarde DataStore
│   ├── ProgressionService # XP, niveaux, stats, rang de chasseur
│   ├── CombatService  # Compétences (anti-triche serveur)
│   ├── MonsterService # Modèles procéduraux + IA
│   ├── DungeonService # Portails + donjons instanciés
│   ├── LootService    # Génération d'objets
│   ├── GuildService   # Guildes + QG
│   ├── MonetizationService # Robux, abonnement, cristaux
│   ├── BattlePassService
│   ├── CityBuilder    # La ville hub (procédurale)
│   └── DungeonBuilder # Les arènes de donjon (procédurales)
└── client/
    ├── init.client
    ├── UIController   # HUD, notifications, choix de classe
    ├── MenusController # Stats / Inventaire / Guilde / Passe
    ├── CombatController # Entrées clavier/souris/mobile
    └── EffectsController # VFX + dégâts flottants
```

## 🗺️ Roadmap (idées pour la suite)

- [ ] Système de quêtes journalières
- [ ] Boss mondiaux (« ruptures de portail » qui envahissent la ville)
- [ ] Échange d'objets entre joueurs
- [ ] Donjons en équipe avec rôles (tank/heal/dps) et matchmaking
- [ ] Classements globaux (OrderedDataStore)
- [ ] Remplacement des modèles procéduraux par des meshes (Blender)
- [ ] Musiques et sons d'ambiance
- [ ] Système d'éveil / seconde classe au niveau 50
