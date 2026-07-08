--!strict
-- Butin : génération procédurale d'objets (base par rang + rareté + bonus)
-- et tirage des drops à la mort des monstres.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local LootService = {}

local Services: any = nil
local notification = Remotes.Event("Notification")

local TAILLE_INVENTAIRE_MAX = 60

-- Retrouve le rang d'un monstre à partir de sa définition.
local function rangDuMonstre(defMonstre: any): string
	local MonsterConfig = require(Shared:WaitForChild("MonsterConfig"))
	for rangId, liste in MonsterConfig.ParRang do
		for _, def in liste do
			if def.Id == defMonstre.Id then
				return rangId
			end
		end
	end
	for rangId, boss in MonsterConfig.Boss do
		if boss.Id == defMonstre.Id then
			return rangId
		end
	end
	return "E"
end

-- Génère un objet aléatoire d'un rang donné.
function LootService.GenererObjet(rangId: string, slotForce: string?, rareteForcee: string?): any
	local slots = { "Arme", "Armure", "Accessoire" }
	local slot = slotForce or slots[math.random(#slots)]
	local base = ItemConfig.Bases[rangId][slot]

	local rarete
	if rareteForcee then
		rarete = ItemConfig.RareteParId[rareteForcee]
	else
		rarete = Util.ChoixPondere(ItemConfig.Raretes, "Poids")
	end

	local prefixe = ItemConfig.Prefixes[rarete.Id]
	local nom = (prefixe ~= "" and (prefixe .. " ") or "") .. base.Nom

	local objet: any = {
		UUID = Util.UUID(),
		Nom = nom,
		Slot = slot,
		Rarete = rarete.Id,
		Rang = rangId,
		Bonus = {},
	}

	if slot == "Arme" then
		objet.Degats = math.floor(base.Degats * rarete.Mult)
	elseif slot == "Armure" then
		objet.Defense = math.floor(base.Defense * rarete.Mult)
	end

	-- Bonus de stats aléatoires selon la rareté
	local bonusBase = base.BonusBase or math.max(math.floor((base.Degats or base.Defense or 4) * 0.3), 1)
	for _ = 1, rarete.NbBonus + (slot == "Accessoire" and 1 or 0) do
		local stat = ItemConfig.StatsBonus[math.random(#ItemConfig.StatsBonus)]
		objet.Bonus[stat] = (objet.Bonus[stat] or 0) + math.random(math.max(math.floor(bonusBase * 0.5), 1), bonusBase)
	end

	return objet
end

-- Donne un objet à un joueur (avec notification colorée selon la rareté).
function LootService.DonnerObjet(player: Player, objet: any)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	if #profil.Inventaire >= TAILLE_INVENTAIRE_MAX then
		notification:FireClient(player, {
			Titre = "Inventaire plein !",
			Message = "Vendez des objets pour faire de la place (touche I).",
			Couleur = Color3.fromRGB(255, 100, 100),
		})
		return
	end
	table.insert(profil.Inventaire, objet)
	local rarete = ItemConfig.RareteParId[objet.Rarete]
	notification:FireClient(player, {
		Titre = "Butin : " .. objet.Nom,
		Message = rarete.Nom .. " • Rang " .. objet.Rang .. " • " .. objet.Slot,
		Couleur = rarete.Couleur,
	})
	Services.DataService.Push(player)
end

-- Tirage de drop à la mort d'un monstre.
function LootService.RollDrop(player: Player, defMonstre: any)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	local stats = Services.ProgressionService.StatsTotales(profil)
	local bonusChance = math.min(stats.Chance * ItemConfig.BonusChanceParPoint, ItemConfig.BonusChanceMax)
	local chance = ItemConfig.ChanceDropObjet + bonusChance

	if defMonstre.Boss or math.random() < chance then
		local rangId = rangDuMonstre(defMonstre)
		-- Les boss garantissent au minimum du Rare
		local objet
		if defMonstre.Boss then
			objet = LootService.GenererObjet(rangId)
			if objet.Rarete == "Commun" then
				objet = LootService.GenererObjet(rangId, objet.Slot, "Rare")
			end
		else
			objet = LootService.GenererObjet(rangId)
		end
		LootService.DonnerObjet(player, objet)
	end
end

function LootService.Init(services: any)
	Services = services
end

return LootService
