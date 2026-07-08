--!strict
-- Passe de combat saisonnier : gain d'XP de passe (donjons), réclamation des paliers,
-- piste gratuite + piste premium.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BattlePassConfig = require(Shared:WaitForChild("BattlePassConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local BattlePassService = {}

local Services: any = nil
local notification = Remotes.Event("Notification")

local function palierActuel(xp: number): number
	return math.min(math.floor(xp / BattlePassConfig.XPParPalier), BattlePassConfig.NbPaliers)
end

function BattlePassService.AjouterXPPasse(player: Player, montant: number)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	-- Nouvelle saison → remise à zéro
	if profil.PasseDeCombat.Saison ~= BattlePassConfig.Saison then
		profil.PasseDeCombat = { Saison = BattlePassConfig.Saison, XP = 0, Premium = false, Reclames = {} }
	end

	local avant = palierActuel(profil.PasseDeCombat.XP)
	profil.PasseDeCombat.XP += montant
	local apres = palierActuel(profil.PasseDeCombat.XP)

	if apres > avant then
		notification:FireClient(player, {
			Titre = "🎖️ Palier " .. apres .. " du passe !",
			Message = "Ouvrez le passe de combat (touche P) pour réclamer vos récompenses.",
			Couleur = Color3.fromRGB(255, 200, 80),
		})
	end
	Services.DataService.Push(player)
end

local function donnerRecompense(player: Player, recompense: any)
	if recompense.Type == "Or" then
		Services.ProgressionService.AjouterOr(player, recompense.Montant)
	elseif recompense.Type == "Cristaux" then
		local profil = Services.DataService.Get(player)
		if profil then
			profil.Cristaux += recompense.Montant
		end
	elseif recompense.Type == "Objet" then
		local objet = Services.LootService.GenererObjet(recompense.Rang, recompense.Slot, recompense.Rarete)
		Services.LootService.DonnerObjet(player, objet)
	elseif recompense.Type == "Titre" then
		local profil = Services.DataService.Get(player)
		if profil then
			profil.Titre = recompense.Titre
		end
	end
end

function BattlePassService.Init(services: any)
	Services = services

	-- Réclamer un palier ("Gratuit" ou "Premium")
	Remotes.Event("ReclamerPalier").OnServerEvent:Connect(function(player, numeroPalier, piste)
		if typeof(numeroPalier) ~= "number" or (piste ~= "Gratuit" and piste ~= "Premium") then
			return
		end
		local profil = Services.DataService.Get(player)
		if not profil then
			return
		end
		local palier = BattlePassConfig.Paliers[numeroPalier]
		if not palier then
			return
		end
		-- Palier atteint ?
		if palierActuel(profil.PasseDeCombat.XP) < numeroPalier then
			return
		end
		-- Premium possédé ?
		if piste == "Premium" and not Services.MonetizationService.APassePremium(player) then
			notification:FireClient(player, {
				Titre = "Piste premium verrouillée",
				Message = "Achetez le passe premium pour débloquer ces récompenses !",
				Couleur = Color3.fromRGB(255, 100, 100),
			})
			return
		end
		-- Déjà réclamé ?
		local cle = piste .. "_" .. numeroPalier
		if profil.PasseDeCombat.Reclames[cle] then
			return
		end
		profil.PasseDeCombat.Reclames[cle] = true

		donnerRecompense(player, palier[piste])
		Services.DataService.Push(player)
	end)
end

return BattlePassService
