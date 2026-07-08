--!strict
-- Monétisation :
--  - double monnaie : Or (jeu) + Cristaux (achetables en Robux via produits développeur)
--  - abonnement "Chasseur d'Élite" (Game Pass) : x2 XP, +50% Or, cristaux quotidiens
--  - passe de combat premium (Game Pass)
--  - QG de guilde achetable en Robux (produit développeur)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MonetizationService = {}

local Services: any = nil
local notification = Remotes.Event("Notification")

-- Cache des Game Pass possédés : { [userId] = { [passId] = boolean } }
local cachePasses: { [number]: { [number]: boolean } } = {}

----------------------------------------------------------------
-- GAME PASS
----------------------------------------------------------------

local function possedePasse(player: Player, passeId: number): boolean
	if passeId == 0 then
		return false -- ID non configuré
	end
	cachePasses[player.UserId] = cachePasses[player.UserId] or {}
	local cache = cachePasses[player.UserId]
	if cache[passeId] ~= nil then
		return cache[passeId]
	end
	local ok, possede = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passeId)
	end)
	cache[passeId] = ok and possede or false
	return cache[passeId]
end

function MonetizationService.EstAbonne(player: Player): boolean
	return possedePasse(player, GameConfig.Monetisation.PasseAbonnementId)
end

function MonetizationService.APassePremium(player: Player): boolean
	local profil = Services.DataService.Get(player)
	if profil and profil.PasseDeCombat.Premium then
		return true
	end
	return possedePasse(player, GameConfig.Monetisation.PassePremiumId)
end

----------------------------------------------------------------
-- CRISTAUX QUOTIDIENS DES ABONNÉS
----------------------------------------------------------------

local function verifierBonusQuotidien(player: Player)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	if MonetizationService.EstAbonne(player) then
		local maintenant = os.time()
		if maintenant - profil.DerniersCristauxQuotidiens >= 20 * 3600 then -- ~1 fois/jour
			profil.DerniersCristauxQuotidiens = maintenant
			profil.Cristaux += GameConfig.Abonnement.CristauxQuotidiens
			notification:FireClient(player, {
				Titre = "💎 Bonus d'abonné",
				Message = "+" .. GameConfig.Abonnement.CristauxQuotidiens .. " cristaux quotidiens (" .. GameConfig.Abonnement.Nom .. ")",
				Couleur = Color3.fromRGB(120, 220, 255),
			})
			Services.DataService.Push(player)
		end
	end
end

----------------------------------------------------------------
-- PRODUITS DÉVELOPPEUR (achats Robux)
----------------------------------------------------------------

local function traiterRecu(infoRecu: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(infoRecu.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profil = Services.DataService.Get(player)
	if not profil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local produitId = infoRecu.ProductId

	-- Pack de cristaux ?
	local montantCristaux = GameConfig.Monetisation.PacksCristaux[produitId]
	if montantCristaux then
		profil.Cristaux += montantCristaux
		notification:FireClient(player, {
			Titre = "💎 Achat réussi",
			Message = "+" .. montantCristaux .. " cristaux ! Merci pour votre soutien !",
			Couleur = Color3.fromRGB(120, 220, 255),
		})
		Services.DataService.Push(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- QG de guilde en Robux ?
	if produitId == GameConfig.Monetisation.ProduitQGGuildeId then
		Services.GuildService.DebloquerQG(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	warn("[MonetizationService] Produit inconnu : " .. tostring(produitId))
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

function MonetizationService.Init(services: any)
	Services = services

	MarketplaceService.ProcessReceipt = traiterRecu

	-- Le client demande l'ouverture d'une fenêtre d'achat
	Remotes.Event("DemanderAchat").OnServerEvent:Connect(function(player, typeAchat, id)
		if typeAchat == "Produit" and typeof(id) == "number" then
			MarketplaceService:PromptProductPurchase(player, id)
		elseif typeAchat == "Passe" and typeof(id) == "number" then
			MarketplaceService:PromptGamePassPurchase(player, id)
		end
	end)

	-- Invalide le cache quand un passe vient d'être acheté en jeu
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passeId, achete)
		if achete and cachePasses[player.UserId] then
			cachePasses[player.UserId][passeId] = true
			verifierBonusQuotidien(player)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			Services.DataService.Get(player) -- attend le profil
			verifierBonusQuotidien(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		cachePasses[player.UserId] = nil
	end)
end

return MonetizationService
