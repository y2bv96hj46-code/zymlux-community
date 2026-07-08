--!strict
-- Bestiaire : monstres par rang de portail (E → S) + boss.
-- Type visuel : "Humanoide" (bipède), "Bete" (quadrupède), "Golem" (massif), "Volant".

export type Monstre = {
	Id: string,
	Nom: string,
	Type: string,
	Vie: number,
	Degats: number,
	Vitesse: number,
	Taille: number, -- multiplicateur de taille du modèle
	Couleur: Color3,
	CouleurYeux: Color3,
	XP: number,
	Or: number,
	Boss: boolean?,
}

local MonsterConfig: { ParRang: { [string]: { Monstre } }, Boss: { [string]: Monstre } } = {
	ParRang = {},
	Boss = {},
}

MonsterConfig.ParRang = {
	E = {
		{ Id = "Gobelin", Nom = "Gobelin", Type = "Humanoide", Vie = 60, Degats = 6, Vitesse = 12, Taille = 0.8, Couleur = Color3.fromRGB(110, 160, 80), CouleurYeux = Color3.fromRGB(255, 220, 60), XP = 12, Or = 4 },
		{ Id = "LoupDesPlaines", Nom = "Loup des Plaines", Type = "Bete", Vie = 50, Degats = 8, Vitesse = 17, Taille = 1, Couleur = Color3.fromRGB(120, 110, 100), CouleurYeux = Color3.fromRGB(255, 200, 80), XP = 14, Or = 5 },
		{ Id = "SlimeVenimeux", Nom = "Slime Venimeux", Type = "Golem", Vie = 80, Degats = 5, Vitesse = 8, Taille = 0.7, Couleur = Color3.fromRGB(120, 220, 120), CouleurYeux = Color3.fromRGB(40, 80, 40), XP = 10, Or = 3 },
	},
	D = {
		{ Id = "Orc", Nom = "Orc", Type = "Humanoide", Vie = 220, Degats = 16, Vitesse = 13, Taille = 1.15, Couleur = Color3.fromRGB(90, 130, 70), CouleurYeux = Color3.fromRGB(255, 90, 60), XP = 35, Or = 12 },
		{ Id = "AraigneeGeante", Nom = "Araignée Géante", Type = "Bete", Vie = 170, Degats = 20, Vitesse = 18, Taille = 1.1, Couleur = Color3.fromRGB(50, 40, 60), CouleurYeux = Color3.fromRGB(255, 60, 60), XP = 38, Or = 13 },
		{ Id = "SqueletteGuerrier", Nom = "Squelette Guerrier", Type = "Humanoide", Vie = 190, Degats = 18, Vitesse = 14, Taille = 1, Couleur = Color3.fromRGB(220, 215, 190), CouleurYeux = Color3.fromRGB(120, 220, 255), XP = 36, Or = 12 },
	},
	C = {
		{ Id = "GolemDePierre", Nom = "Golem de Pierre", Type = "Golem", Vie = 700, Degats = 35, Vitesse = 10, Taille = 1.6, Couleur = Color3.fromRGB(130, 130, 140), CouleurYeux = Color3.fromRGB(120, 200, 255), XP = 90, Or = 30 },
		{ Id = "Harpie", Nom = "Harpie", Type = "Volant", Vie = 450, Degats = 40, Vitesse = 20, Taille = 1, Couleur = Color3.fromRGB(160, 120, 180), CouleurYeux = Color3.fromRGB(255, 240, 120), XP = 85, Or = 28 },
		{ Id = "ChevalierDechu", Nom = "Chevalier Déchu", Type = "Humanoide", Vie = 600, Degats = 45, Vitesse = 14, Taille = 1.1, Couleur = Color3.fromRGB(70, 70, 90), CouleurYeux = Color3.fromRGB(200, 60, 255), XP = 95, Or = 32 },
	},
	B = {
		{ Id = "ElementaireDeFeu", Nom = "Élémentaire de Feu", Type = "Golem", Vie = 1800, Degats = 80, Vitesse = 13, Taille = 1.5, Couleur = Color3.fromRGB(255, 120, 40), CouleurYeux = Color3.fromRGB(255, 240, 120), XP = 220, Or = 75 },
		{ Id = "Naga", Nom = "Naga", Type = "Humanoide", Vie = 1500, Degats = 90, Vitesse = 16, Taille = 1.25, Couleur = Color3.fromRGB(50, 140, 130), CouleurYeux = Color3.fromRGB(255, 220, 80), XP = 210, Or = 70 },
		{ Id = "OgreADeuxTetes", Nom = "Ogre à Deux Têtes", Type = "Golem", Vie = 2400, Degats = 100, Vitesse = 11, Taille = 1.8, Couleur = Color3.fromRGB(150, 120, 90), CouleurYeux = Color3.fromRGB(255, 100, 60), XP = 240, Or = 85 },
	},
	A = {
		{ Id = "ChevalierDuNeant", Nom = "Chevalier du Néant", Type = "Humanoide", Vie = 5500, Degats = 180, Vitesse = 16, Taille = 1.3, Couleur = Color3.fromRGB(40, 30, 60), CouleurYeux = Color3.fromRGB(160, 60, 255), XP = 520, Or = 170 },
		{ Id = "DemonMineur", Nom = "Démon Mineur", Type = "Humanoide", Vie = 4800, Degats = 200, Vitesse = 18, Taille = 1.2, Couleur = Color3.fromRGB(140, 40, 40), CouleurYeux = Color3.fromRGB(255, 200, 60), XP = 500, Or = 160 },
		{ Id = "Wyverne", Nom = "Wyverne", Type = "Volant", Vie = 6500, Degats = 210, Vitesse = 22, Taille = 1.7, Couleur = Color3.fromRGB(60, 90, 60), CouleurYeux = Color3.fromRGB(255, 120, 60), XP = 560, Or = 190 },
	},
	S = {
		{ Id = "TitanDObsidienne", Nom = "Titan d'Obsidienne", Type = "Golem", Vie = 16000, Degats = 380, Vitesse = 12, Taille = 2.4, Couleur = Color3.fromRGB(25, 25, 35), CouleurYeux = Color3.fromRGB(255, 60, 60), XP = 1400, Or = 480 },
		{ Id = "DragonDOmbre", Nom = "Dragon d'Ombre", Type = "Volant", Vie = 14000, Degats = 420, Vitesse = 24, Taille = 2.2, Couleur = Color3.fromRGB(35, 25, 50), CouleurYeux = Color3.fromRGB(200, 60, 255), XP = 1350, Or = 460 },
		{ Id = "FaucheurAbyssal", Nom = "Faucheur Abyssal", Type = "Humanoide", Vie = 12000, Degats = 450, Vitesse = 19, Taille = 1.6, Couleur = Color3.fromRGB(20, 20, 25), CouleurYeux = Color3.fromRGB(120, 255, 200), XP = 1300, Or = 440 },
	},
}

-- Boss de fin de donjon (un par rang)
MonsterConfig.Boss = {
	E = { Id = "RoiGobelin", Nom = "Roi Gobelin", Type = "Humanoide", Vie = 350, Degats = 14, Vitesse = 13, Taille = 1.5, Couleur = Color3.fromRGB(90, 140, 60), CouleurYeux = Color3.fromRGB(255, 60, 60), XP = 80, Or = 40, Boss = true },
	D = { Id = "BroyeurOrc", Nom = "Broyeur, Chef de Guerre Orc", Type = "Humanoide", Vie = 1200, Degats = 35, Vitesse = 14, Taille = 1.7, Couleur = Color3.fromRGB(70, 110, 50), CouleurYeux = Color3.fromRGB(255, 80, 40), XP = 220, Or = 100, Boss = true },
	C = { Id = "GolemAncien", Nom = "Golem Ancien", Type = "Golem", Vie = 4000, Degats = 70, Vitesse = 10, Taille = 2.4, Couleur = Color3.fromRGB(100, 105, 120), CouleurYeux = Color3.fromRGB(80, 180, 255), XP = 550, Or = 240, Boss = true },
	B = { Id = "SeigneurNaga", Nom = "Seigneur Naga", Type = "Humanoide", Vie = 11000, Degats = 150, Vitesse = 16, Taille = 1.9, Couleur = Color3.fromRGB(30, 110, 100), CouleurYeux = Color3.fromRGB(255, 230, 100), XP = 1300, Or = 550, Boss = true },
	A = { Id = "GeneralDuNeant", Nom = "Général du Néant", Type = "Humanoide", Vie = 30000, Degats = 320, Vitesse = 17, Taille = 2.1, Couleur = Color3.fromRGB(30, 20, 50), CouleurYeux = Color3.fromRGB(180, 80, 255), XP = 3200, Or = 1300, Boss = true },
	S = { Id = "SeigneurDeLAbime", Nom = "Seigneur de l'Abîme", Type = "Humanoide", Vie = 90000, Degats = 650, Vitesse = 18, Taille = 2.8, Couleur = Color3.fromRGB(15, 12, 22), CouleurYeux = Color3.fromRGB(255, 40, 90), XP = 9000, Or = 4000, Boss = true },
}

return MonsterConfig
