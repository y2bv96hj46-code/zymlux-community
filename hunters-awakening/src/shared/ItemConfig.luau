--!strict
-- Objets & butin : raretés, bases d'équipement par rang, tables de loot.
-- Les objets sont générés procéduralement : base (par rang) + rareté + bonus de stats.

local ItemConfig = {}

----------------------------------------------------------------
-- RARETÉS (poids = probabilité relative au drop)
----------------------------------------------------------------
ItemConfig.Raretes = {
	{ Id = "Commun", Nom = "Commun", Couleur = Color3.fromRGB(180, 180, 180), Poids = 58, Mult = 1.0, NbBonus = 0 },
	{ Id = "Rare", Nom = "Rare", Couleur = Color3.fromRGB(90, 160, 255), Poids = 27, Mult = 1.3, NbBonus = 1 },
	{ Id = "Epique", Nom = "Épique", Couleur = Color3.fromRGB(180, 100, 255), Poids = 10, Mult = 1.7, NbBonus = 2 },
	{ Id = "Legendaire", Nom = "Légendaire", Couleur = Color3.fromRGB(255, 170, 50), Poids = 4, Mult = 2.3, NbBonus = 3 },
	{ Id = "Mythique", Nom = "Mythique", Couleur = Color3.fromRGB(255, 70, 90), Poids = 1, Mult = 3.2, NbBonus = 4 },
}

ItemConfig.RareteParId = {} :: { [string]: any }
for _, r in ItemConfig.Raretes do
	ItemConfig.RareteParId[r.Id] = r
end

----------------------------------------------------------------
-- BASES D'ÉQUIPEMENT PAR RANG
-- Slots : "Arme" (Degats), "Armure" (Defense), "Accessoire" (bonus purs)
----------------------------------------------------------------
ItemConfig.Bases = {
	E = {
		Arme = { Nom = "Lame Rouillée", Degats = 8 },
		Armure = { Nom = "Tunique de Cuir", Defense = 4 },
		Accessoire = { Nom = "Anneau de Fer", BonusBase = 2 },
	},
	D = {
		Arme = { Nom = "Épée du Soldat", Degats = 18 },
		Armure = { Nom = "Cotte de Mailles", Defense = 10 },
		Accessoire = { Nom = "Pendentif d'Argent", BonusBase = 4 },
	},
	C = {
		Arme = { Nom = "Lame du Chevalier", Degats = 38 },
		Armure = { Nom = "Plastron d'Acier", Defense = 22 },
		Accessoire = { Nom = "Talisman Gravé", BonusBase = 8 },
	},
	B = {
		Arme = { Nom = "Croc de Naga", Degats = 75 },
		Armure = { Nom = "Écailles de Naga", Defense = 45 },
		Accessoire = { Nom = "Orbe Élémentaire", BonusBase = 14 },
	},
	A = {
		Arme = { Nom = "Faux du Néant", Degats = 150 },
		Armure = { Nom = "Armure du Néant", Defense = 90 },
		Accessoire = { Nom = "Sceau Démoniaque", BonusBase = 24 },
	},
	S = {
		Arme = { Nom = "Lame de l'Abîme", Degats = 320 },
		Armure = { Nom = "Égide d'Obsidienne", Defense = 190 },
		Accessoire = { Nom = "Cœur de Dragon", BonusBase = 40 },
	},
}

-- Préfixes de nom selon la rareté (pure cosmétique)
ItemConfig.Prefixes = {
	Commun = "",
	Rare = "Raffiné(e)",
	Epique = "Supérieur(e)",
	Legendaire = "Légendaire",
	Mythique = "Mythique",
}

----------------------------------------------------------------
-- DROPS
----------------------------------------------------------------
-- Chance de base qu'un monstre lâche un objet (le boss lâche toujours).
ItemConfig.ChanceDropObjet = 0.18
-- Chaque point de Chance ajoute +0,4% de chance de drop (plafonné +20%).
ItemConfig.BonusChanceParPoint = 0.004
ItemConfig.BonusChanceMax = 0.20

-- Stats pouvant apparaître en bonus sur un objet
ItemConfig.StatsBonus = { "Force", "Agilite", "Intelligence", "Endurance", "Vitesse", "Chance" }

return ItemConfig
