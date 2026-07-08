--!strict
-- Passe de combat saisonnier : 30 paliers, piste gratuite + piste premium.
-- L'XP de passe se gagne en terminant des donjons (XPPasse dans GameConfig.Rangs).

local BattlePassConfig = {}

BattlePassConfig.Saison = 1
BattlePassConfig.NomSaison = "Saison 1 — L'Éveil"
BattlePassConfig.XPParPalier = 1000
BattlePassConfig.NbPaliers = 30

export type Recompense = {
	Type: string, -- "Or" | "Cristaux" | "Objet" | "Titre"
	Montant: number?,
	Rang: string?, -- pour Type == "Objet" : rang de l'objet généré
	Slot: string?, -- "Arme" | "Armure" | "Accessoire"
	Rarete: string?,
	Titre: string?,
}

-- Génère les paliers : chaque palier a une récompense gratuite et une premium.
local paliers: { { Gratuit: Recompense, Premium: Recompense } } = {}
for i = 1, BattlePassConfig.NbPaliers do
	local gratuit: Recompense
	local premium: Recompense

	if i % 10 == 0 then
		-- Paliers majeurs (10/20/30)
		local rangs = { "C", "B", "A" }
		local rang = rangs[i / 10]
		gratuit = { Type = "Cristaux", Montant = 25 * (i / 10) }
		premium = { Type = "Objet", Rang = rang, Slot = "Arme", Rarete = "Legendaire" }
	elseif i % 5 == 0 then
		gratuit = { Type = "Or", Montant = 500 * i }
		premium = { Type = "Objet", Rang = i < 15 and "D" or "C", Slot = "Armure", Rarete = "Epique" }
	elseif i % 3 == 0 then
		gratuit = { Type = "Or", Montant = 200 * i }
		premium = { Type = "Cristaux", Montant = 15 + i }
	else
		gratuit = { Type = "Or", Montant = 100 * i }
		premium = { Type = "Or", Montant = 300 * i }
	end

	paliers[i] = { Gratuit = gratuit, Premium = premium }
end

-- Palier final : titre exclusif premium
paliers[BattlePassConfig.NbPaliers].Premium = { Type = "Titre", Titre = "⚔️ Éveillé(e)" }

BattlePassConfig.Paliers = paliers

return BattlePassConfig
