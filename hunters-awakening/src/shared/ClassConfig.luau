--!strict
-- Les 6 classes jouables et leurs compétences.
-- Types de compétences gérés par CombatService :
--   "Melee"      : arc de cercle devant le joueur
--   "Projectile" : projectile en ligne droite
--   "Zone"       : dégâts de zone au point visé
--   "Buff"       : bonus temporaire (BuffStat + BuffMult + Duree)
--   "Soin"       : rend de la vie
--   "Dash"       : propulsion vers l'avant

export type Competence = {
	Id: string,
	Nom: string,
	Type: string,
	Degats: number?, -- dégâts de base
	StatScaling: string?, -- stat qui augmente les dégâts
	Ratio: number?, -- dégâts ajoutés par point de stat
	Cooldown: number,
	Mana: number,
	Portee: number?,
	Rayon: number?,
	Duree: number?,
	BuffStat: string?,
	BuffMult: number?,
	Soin: number?,
	Couleur: Color3,
	Description: string,
}

export type Classe = {
	Id: string,
	Nom: string,
	Icone: string,
	Description: string,
	StatPrincipale: string,
	Couleur: Color3,
	Competences: { Competence },
}

local ClassConfig: { Classes: { Classe }, ParId: { [string]: Classe } } = {
	Classes = {},
	ParId = {},
}

ClassConfig.Classes = {
	{
		Id = "Guerrier",
		Nom = "Guerrier",
		Icone = "⚔️",
		Description = "Combattant au corps à corps qui écrase ses ennemis à la force brute.",
		StatPrincipale = "Force",
		Couleur = Color3.fromRGB(220, 90, 60),
		Competences = {
			{ Id = "FrappeLourde", Nom = "Frappe Lourde", Type = "Melee", Degats = 25, StatScaling = "Force", Ratio = 1.4, Cooldown = 3, Mana = 8, Portee = 12, Couleur = Color3.fromRGB(255, 120, 80), Description = "Un coup dévastateur devant vous." },
			{ Id = "Tourbillon", Nom = "Tourbillon", Type = "Zone", Degats = 18, StatScaling = "Force", Ratio = 1.1, Cooldown = 7, Mana = 15, Portee = 0, Rayon = 14, Couleur = Color3.fromRGB(255, 160, 90), Description = "Tourne sur vous-même et frappe tout autour." },
			{ Id = "CriDeGuerre", Nom = "Cri de Guerre", Type = "Buff", Cooldown = 20, Mana = 20, Duree = 8, BuffStat = "Degats", BuffMult = 1.3, Couleur = Color3.fromRGB(255, 200, 100), Description = "+30% de dégâts pendant 8 s." },
			{ Id = "Jugement", Nom = "Jugement", Type = "Melee", Degats = 90, StatScaling = "Force", Ratio = 3.0, Cooldown = 35, Mana = 40, Portee = 16, Couleur = Color3.fromRGB(255, 60, 40), Description = "ULTIME — Un coup colossal qui fend la terre." },
		},
	},
	{
		Id = "Assassin",
		Nom = "Assassin",
		Icone = "🗡️",
		Description = "Rapide et mortel. Frappe dans l'ombre avant qu'on ne le voie.",
		StatPrincipale = "Agilite",
		Couleur = Color3.fromRGB(120, 80, 200),
		Competences = {
			{ Id = "LameRapide", Nom = "Lame Rapide", Type = "Melee", Degats = 16, StatScaling = "Agilite", Ratio = 1.2, Cooldown = 1.5, Mana = 5, Portee = 10, Couleur = Color3.fromRGB(180, 120, 255), Description = "Une entaille éclair." },
			{ Id = "PasDeLOmbre", Nom = "Pas de l'Ombre", Type = "Dash", Cooldown = 6, Mana = 12, Portee = 40, Couleur = Color3.fromRGB(90, 60, 160), Description = "Se propulse instantanément vers l'avant." },
			{ Id = "EventailDeDagues", Nom = "Éventail de Dagues", Type = "Projectile", Degats = 22, StatScaling = "Agilite", Ratio = 1.5, Cooldown = 8, Mana = 18, Portee = 60, Couleur = Color3.fromRGB(200, 160, 255), Description = "Lance une volée de dagues." },
			{ Id = "DanseMortelle", Nom = "Danse Mortelle", Type = "Zone", Degats = 70, StatScaling = "Agilite", Ratio = 2.6, Cooldown = 30, Mana = 40, Portee = 0, Rayon = 16, Couleur = Color3.fromRGB(140, 40, 220), Description = "ULTIME — Une tempête de lames autour de vous." },
		},
	},
	{
		Id = "Mage",
		Nom = "Mage",
		Icone = "🔮",
		Description = "Maître des arcanes. Fragile mais dévastateur à distance.",
		StatPrincipale = "Intelligence",
		Couleur = Color3.fromRGB(80, 140, 255),
		Competences = {
			{ Id = "EclairArcanique", Nom = "Éclair Arcanique", Type = "Projectile", Degats = 24, StatScaling = "Intelligence", Ratio = 1.6, Cooldown = 2.5, Mana = 10, Portee = 80, Couleur = Color3.fromRGB(100, 180, 255), Description = "Un trait de pure énergie." },
			{ Id = "NovaDeGivre", Nom = "Nova de Givre", Type = "Zone", Degats = 20, StatScaling = "Intelligence", Ratio = 1.2, Cooldown = 9, Mana = 22, Portee = 50, Rayon = 12, Couleur = Color3.fromRGB(160, 220, 255), Description = "Une explosion glaciale au point visé." },
			{ Id = "BouclierDeMana", Nom = "Bouclier de Mana", Type = "Buff", Cooldown = 22, Mana = 25, Duree = 10, BuffStat = "Defense", BuffMult = 1.5, Couleur = Color3.fromRGB(120, 200, 255), Description = "+50% de défense pendant 10 s." },
			{ Id = "Meteore", Nom = "Météore", Type = "Zone", Degats = 95, StatScaling = "Intelligence", Ratio = 3.2, Cooldown = 40, Mana = 55, Portee = 70, Rayon = 20, Couleur = Color3.fromRGB(255, 120, 60), Description = "ULTIME — Fait s'écraser un météore." },
		},
	},
	{
		Id = "Archer",
		Nom = "Archer",
		Icone = "🏹",
		Description = "Précision chirurgicale à longue distance.",
		StatPrincipale = "Agilite",
		Couleur = Color3.fromRGB(90, 190, 110),
		Competences = {
			{ Id = "TirPrecis", Nom = "Tir Précis", Type = "Projectile", Degats = 20, StatScaling = "Agilite", Ratio = 1.3, Cooldown = 2, Mana = 6, Portee = 100, Couleur = Color3.fromRGB(140, 230, 150), Description = "Une flèche rapide et précise." },
			{ Id = "PluieDeFleches", Nom = "Pluie de Flèches", Type = "Zone", Degats = 26, StatScaling = "Agilite", Ratio = 1.4, Cooldown = 10, Mana = 20, Portee = 70, Rayon = 14, Couleur = Color3.fromRGB(110, 200, 130), Description = "Bombarde la zone visée." },
			{ Id = "FlechePerçante", Nom = "Flèche Perçante", Type = "Projectile", Degats = 40, StatScaling = "Force", Ratio = 1.8, Cooldown = 12, Mana = 22, Portee = 120, Couleur = Color3.fromRGB(230, 250, 160), Description = "Transperce tout sur son passage." },
			{ Id = "SalveUltime", Nom = "Salve Ultime", Type = "Zone", Degats = 80, StatScaling = "Agilite", Ratio = 2.8, Cooldown = 35, Mana = 45, Portee = 90, Rayon = 22, Couleur = Color3.fromRGB(60, 255, 120), Description = "ULTIME — Un déluge de flèches sur une large zone." },
		},
	},
	{
		Id = "Gardien",
		Nom = "Gardien",
		Icone = "🛡️",
		Description = "Un mur vivant. Protège l'équipe et encaisse les coups.",
		StatPrincipale = "Endurance",
		Couleur = Color3.fromRGB(200, 170, 90),
		Competences = {
			{ Id = "CoupDeBouclier", Nom = "Coup de Bouclier", Type = "Melee", Degats = 18, StatScaling = "Endurance", Ratio = 1.0, Cooldown = 3, Mana = 8, Portee = 10, Couleur = Color3.fromRGB(230, 200, 120), Description = "Frappe avec le bouclier." },
			{ Id = "Rempart", Nom = "Rempart", Type = "Buff", Cooldown = 18, Mana = 20, Duree = 10, BuffStat = "Defense", BuffMult = 2.0, Couleur = Color3.fromRGB(250, 220, 140), Description = "Défense doublée pendant 10 s." },
			{ Id = "Provocation", Nom = "Provocation", Type = "Zone", Degats = 8, StatScaling = "Endurance", Ratio = 0.5, Cooldown = 12, Mana = 15, Portee = 0, Rayon = 20, Couleur = Color3.fromRGB(255, 180, 80), Description = "Attire l'attention des monstres proches." },
			{ Id = "Seisme", Nom = "Séisme", Type = "Zone", Degats = 75, StatScaling = "Endurance", Ratio = 2.4, Cooldown = 32, Mana = 45, Portee = 0, Rayon = 18, Couleur = Color3.fromRGB(200, 140, 60), Description = "ULTIME — Fait trembler la terre autour de vous." },
		},
	},
	{
		Id = "Pretre",
		Nom = "Prêtre",
		Icone = "✨",
		Description = "Canalise la lumière pour soigner ses alliés et punir les ténèbres.",
		StatPrincipale = "Intelligence",
		Couleur = Color3.fromRGB(255, 230, 140),
		Competences = {
			{ Id = "Chatiment", Nom = "Châtiment", Type = "Projectile", Degats = 18, StatScaling = "Intelligence", Ratio = 1.3, Cooldown = 2.5, Mana = 8, Portee = 70, Couleur = Color3.fromRGB(255, 240, 170), Description = "Un trait de lumière sacrée." },
			{ Id = "SoinSacre", Nom = "Soin Sacré", Type = "Soin", Soin = 40, StatScaling = "Intelligence", Ratio = 1.5, Cooldown = 8, Mana = 25, Couleur = Color3.fromRGB(170, 255, 170), Description = "Restaure votre vie." },
			{ Id = "Benediction", Nom = "Bénédiction", Type = "Buff", Cooldown = 25, Mana = 25, Duree = 12, BuffStat = "Degats", BuffMult = 1.25, Couleur = Color3.fromRGB(255, 250, 200), Description = "+25% de dégâts pendant 12 s." },
			{ Id = "ColereDivine", Nom = "Colère Divine", Type = "Zone", Degats = 85, StatScaling = "Intelligence", Ratio = 2.9, Cooldown = 38, Mana = 50, Portee = 60, Rayon = 18, Couleur = Color3.fromRGB(255, 255, 150), Description = "ULTIME — La lumière s'abat sur la zone visée." },
		},
	},
}

for _, classe in ClassConfig.Classes do
	ClassConfig.ParId[classe.Id] = classe
end

return ClassConfig
