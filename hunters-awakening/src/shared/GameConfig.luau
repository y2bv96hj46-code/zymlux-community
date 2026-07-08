--!strict
-- Configuration générale du jeu "L'Éveil des Chasseurs"
-- MMORPG inspiré du genre "chasseurs & portails" : donjons classés E → S,
-- classes, stats, guildes, double monnaie, passe de combat.

local GameConfig = {}

GameConfig.NomDuJeu = "L'Éveil des Chasseurs"
GameConfig.Version = "0.1.0"

----------------------------------------------------------------
-- MONNAIES (double monnaie : Or = jeu, Cristaux = premium)
----------------------------------------------------------------
GameConfig.Monnaies = {
	Or = { Nom = "Or", Icone = "🪙", Depart = 250 },
	Cristaux = { Nom = "Cristaux", Icone = "💎", Depart = 0 },
}

----------------------------------------------------------------
-- PROGRESSION / NIVEAUX
----------------------------------------------------------------
GameConfig.NiveauMax = 100
GameConfig.PointsParNiveau = 5 -- points de stats gagnés par niveau
GameConfig.NiveauChoixClasse = 1 -- niveau auquel on choisit sa classe

function GameConfig.XPPourNiveau(niveau: number): number
	return math.floor(100 * niveau ^ 1.6)
end

----------------------------------------------------------------
-- STATS (répartition de points façon RPG)
----------------------------------------------------------------
GameConfig.StatDepart = 5
GameConfig.Stats = {
	{ Id = "Force", Nom = "Force", Icone = "⚔️", Description = "Augmente les dégâts physiques (+2% / point)." },
	{ Id = "Agilite", Nom = "Agilité", Icone = "🌀", Description = "Réduit les temps de recharge et augmente les critiques." },
	{ Id = "Intelligence", Nom = "Intelligence", Icone = "🔮", Description = "Augmente les dégâts magiques et le mana max." },
	{ Id = "Endurance", Nom = "Endurance", Icone = "🛡️", Description = "Augmente la vie max et la défense." },
	{ Id = "Vitesse", Nom = "Vitesse", Icone = "👟", Description = "Augmente la vitesse de déplacement." },
	{ Id = "Chance", Nom = "Chance", Icone = "🍀", Description = "Améliore la qualité du butin et les coups critiques." },
}

-- Formules de stats dérivées (utilisées serveur ET client pour l'affichage)
function GameConfig.VieMax(niveau: number, endurance: number): number
	return 100 + niveau * 10 + endurance * 12
end

function GameConfig.ManaMax(niveau: number, intelligence: number): number
	return 50 + niveau * 4 + intelligence * 8
end

function GameConfig.VitesseMarche(vitesse: number): number
	return math.min(16 + vitesse * 0.12, 28)
end

function GameConfig.ReductionRecharge(agilite: number): number
	return math.min(agilite * 0.004, 0.35) -- max 35% de réduction
end

function GameConfig.ChanceCritique(agilite: number, chance: number): number
	return math.min(0.05 + agilite * 0.001 + chance * 0.002, 0.6)
end

----------------------------------------------------------------
-- RANGS DE CHASSEUR / PORTAILS (E → S)
----------------------------------------------------------------
-- PoidsPortail : probabilité relative d'apparition d'un portail de ce rang.
-- DonjonsPourMonter : donjons de son rang à réussir pour passer au rang suivant.
GameConfig.Rangs = {
	{ Id = "E", Couleur = Color3.fromRGB(150, 150, 150), NiveauRecommande = 1,  Vagues = 2, MonstresParVague = 4, PoidsPortail = 38, DonjonsPourMonter = 5,  OrMin = 40,   OrMax = 80,    XPDonjon = 120,   XPPasse = 100 },
	{ Id = "D", Couleur = Color3.fromRGB(120, 200, 120), NiveauRecommande = 8,  Vagues = 2, MonstresParVague = 5, PoidsPortail = 26, DonjonsPourMonter = 8,  OrMin = 120,  OrMax = 220,   XPDonjon = 350,   XPPasse = 180 },
	{ Id = "C", Couleur = Color3.fromRGB(90, 160, 255),  NiveauRecommande = 18, Vagues = 3, MonstresParVague = 5, PoidsPortail = 16, DonjonsPourMonter = 12, OrMin = 300,  OrMax = 550,   XPDonjon = 900,   XPPasse = 300 },
	{ Id = "B", Couleur = Color3.fromRGB(180, 110, 255), NiveauRecommande = 32, Vagues = 3, MonstresParVague = 6, PoidsPortail = 10, DonjonsPourMonter = 16, OrMin = 700,  OrMax = 1200,  XPDonjon = 2200,  XPPasse = 450 },
	{ Id = "A", Couleur = Color3.fromRGB(255, 150, 60),  NiveauRecommande = 50, Vagues = 4, MonstresParVague = 6, PoidsPortail = 7,  DonjonsPourMonter = 20, OrMin = 1500, OrMax = 2600,  XPDonjon = 5200,  XPPasse = 650 },
	{ Id = "S", Couleur = Color3.fromRGB(255, 70, 70),   NiveauRecommande = 70, Vagues = 4, MonstresParVague = 7, PoidsPortail = 3,  DonjonsPourMonter = 0,  OrMin = 4000, OrMax = 7000,  XPDonjon = 14000, XPPasse = 1000 },
}

GameConfig.IndexRang = {} :: { [string]: number }
for i, rang in GameConfig.Rangs do
	GameConfig.IndexRang[rang.Id] = i
end

----------------------------------------------------------------
-- PORTAILS (apparition dans la ville)
----------------------------------------------------------------
GameConfig.Portails = {
	IntervalleApparition = 40, -- secondes entre deux tentatives d'apparition
	MaxActifs = 6,
	DureeVie = 300, -- un portail non utilisé disparaît après 5 min
	TempsLimiteDonjon = 600, -- 10 min pour finir un donjon
}

----------------------------------------------------------------
-- GUILDES
----------------------------------------------------------------
GameConfig.Guildes = {
	CoutCreation = 10_000, -- en Or
	MembresMax = 20,
	LongueurNomMax = 24,
	-- QG payable en Or (argent du jeu) OU en Robux (produit développeur)
	CoutQGOr = 250_000,
}

----------------------------------------------------------------
-- MONÉTISATION — ⚠️ remplacer les 0 par tes vrais IDs
-- (créés dans Roblox Creator Dashboard : passes + produits développeur)
----------------------------------------------------------------
GameConfig.Monetisation = {
	-- Game Pass : abonnement "Chasseur d'Élite" (x2 XP, +50% Or, cristaux quotidiens)
	PasseAbonnementId = 0,
	-- Game Pass : piste premium du passe de combat
	PassePremiumId = 0,
	-- Produit développeur : achat du QG de guilde en Robux
	ProduitQGGuildeId = 0,
	-- Produits développeur : packs de cristaux { [idProduit] = montant }
	PacksCristaux = {
		-- [1234567] = 100,
		-- [1234568] = 550,
		-- [1234569] = 1200,
	} :: { [number]: number },
}

GameConfig.Abonnement = {
	Nom = "Chasseur d'Élite",
	MultXP = 2,
	MultOr = 1.5,
	CristauxQuotidiens = 50,
}

----------------------------------------------------------------
-- MONDE
----------------------------------------------------------------
GameConfig.Monde = {
	-- Les donjons sont instanciés loin de la ville, un "slot" par donjon actif
	OrigineDonjons = Vector3.new(6000, 0, 6000),
	EcartSlots = 1500,
	MaxDonjonsSimultanes = 12,
}

return GameConfig
