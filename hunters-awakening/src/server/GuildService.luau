--!strict
-- Guildes : création, liste, rejoindre/quitter, QG achetable en Or (jeu) ou Robux.
-- Les guildes sont persistées dans un DataStore dédié, partagé entre serveurs.

local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local GuildService = {}

local Services: any = nil
local notification = Remotes.Event("Notification")

local storeGuildes = nil
do
	local ok, resultat = pcall(function()
		return DataStoreService:GetDataStore("Guildes_v1")
	end)
	if ok then
		storeGuildes = resultat
	else
		warn("[GuildService] DataStore indisponible : " .. tostring(resultat))
	end
end

local CLE_INDEX = "__Index" -- liste des IDs de guildes existantes
local cacheGuildes: { [string]: any } = {}

----------------------------------------------------------------
-- ACCÈS DATASTORE
----------------------------------------------------------------

local function chargerGuilde(guildeId: string): any?
	if cacheGuildes[guildeId] then
		return cacheGuildes[guildeId]
	end
	if not storeGuildes then
		return nil
	end
	local ok, guilde = pcall(function()
		return storeGuildes:GetAsync("Guilde_" .. guildeId)
	end)
	if ok and guilde then
		cacheGuildes[guildeId] = guilde
		return guilde
	end
	return nil
end

local function sauvegarderGuilde(guilde: any)
	if not storeGuildes then
		return
	end
	cacheGuildes[guilde.Id] = guilde
	pcall(function()
		storeGuildes:SetAsync("Guilde_" .. guilde.Id, guilde)
	end)
end

local function mettreAJourIndex(fn: (index: { string }) -> { string })
	if not storeGuildes then
		return
	end
	pcall(function()
		storeGuildes:UpdateAsync(CLE_INDEX, function(ancien)
			return fn(ancien or {})
		end)
	end)
end

local function listeIds(): { string }
	if not storeGuildes then
		return {}
	end
	local ok, index = pcall(function()
		return storeGuildes:GetAsync(CLE_INDEX)
	end)
	if ok and index then
		return index
	end
	return {}
end

----------------------------------------------------------------
-- FILTRAGE DU NOM (obligatoire sur Roblox)
----------------------------------------------------------------

local function filtrerNom(nom: string, player: Player): string?
	local ok, resultat = pcall(function()
		local objetFiltre = TextService:FilterStringAsync(nom, player.UserId)
		return objetFiltre:GetNonChatStringForBroadcastAsync()
	end)
	if ok then
		return resultat
	end
	return nil
end

----------------------------------------------------------------
-- ACTIONS
----------------------------------------------------------------

function GuildService.Creer(player: Player, nom: string): boolean
	local profil = Services.DataService.Get(player)
	if not profil or profil.GuildeId then
		return false
	end
	if typeof(nom) ~= "string" or #nom < 3 or #nom > GameConfig.Guildes.LongueurNomMax then
		notification:FireClient(player, { Titre = "Nom invalide", Message = "3 à " .. GameConfig.Guildes.LongueurNomMax .. " caractères.", Couleur = Color3.fromRGB(255, 100, 100) })
		return false
	end
	if profil.Or < GameConfig.Guildes.CoutCreation then
		notification:FireClient(player, { Titre = "Or insuffisant", Message = "Créer une guilde coûte " .. Util.FormatNombre(GameConfig.Guildes.CoutCreation) .. " Or.", Couleur = Color3.fromRGB(255, 100, 100) })
		return false
	end

	local nomFiltre = filtrerNom(nom, player)
	if not nomFiltre or nomFiltre:find("#") then
		notification:FireClient(player, { Titre = "Nom refusé", Message = "Ce nom n'est pas autorisé par le filtre Roblox.", Couleur = Color3.fromRGB(255, 100, 100) })
		return false
	end

	profil.Or -= GameConfig.Guildes.CoutCreation

	local guilde = {
		Id = Util.UUID(),
		Nom = nomFiltre,
		ChefId = player.UserId,
		ChefNom = player.Name,
		Membres = { [tostring(player.UserId)] = player.Name },
		NbMembres = 1,
		QG = false,
		CreeLe = os.time(),
	}
	sauvegarderGuilde(guilde)
	mettreAJourIndex(function(index)
		table.insert(index, guilde.Id)
		return index
	end)

	profil.GuildeId = guilde.Id
	Services.DataService.Push(player)
	notification:FireClient(player, { Titre = "Guilde créée !", Message = "Bienvenue dans « " .. guilde.Nom .. " » !", Couleur = Color3.fromRGB(140, 100, 255) })
	return true
end

function GuildService.Rejoindre(player: Player, guildeId: string): boolean
	local profil = Services.DataService.Get(player)
	if not profil or profil.GuildeId or typeof(guildeId) ~= "string" then
		return false
	end
	local guilde = chargerGuilde(guildeId)
	if not guilde then
		return false
	end
	if guilde.NbMembres >= GameConfig.Guildes.MembresMax then
		notification:FireClient(player, { Titre = "Guilde pleine", Message = "Cette guilde a atteint " .. GameConfig.Guildes.MembresMax .. " membres.", Couleur = Color3.fromRGB(255, 100, 100) })
		return false
	end

	guilde.Membres[tostring(player.UserId)] = player.Name
	guilde.NbMembres += 1
	sauvegarderGuilde(guilde)

	profil.GuildeId = guildeId
	Services.DataService.Push(player)
	notification:FireClient(player, { Titre = "Guilde rejointe", Message = "Vous avez rejoint « " .. guilde.Nom .. " » !", Couleur = Color3.fromRGB(140, 100, 255) })
	return true
end

function GuildService.Quitter(player: Player)
	local profil = Services.DataService.Get(player)
	if not profil or not profil.GuildeId then
		return
	end
	local guilde = chargerGuilde(profil.GuildeId)
	if guilde then
		guilde.Membres[tostring(player.UserId)] = nil
		guilde.NbMembres = math.max(guilde.NbMembres - 1, 0)
		-- Si le chef part, transmet la guilde à un autre membre (ou la dissout)
		if guilde.ChefId == player.UserId then
			local nouveauChefId, nouveauChefNom = next(guilde.Membres)
			if nouveauChefId then
				guilde.ChefId = tonumber(nouveauChefId)
				guilde.ChefNom = nouveauChefNom
			end
		end
		if guilde.NbMembres <= 0 then
			mettreAJourIndex(function(index)
				local position = table.find(index, guilde.Id)
				if position then
					table.remove(index, position)
				end
				return index
			end)
			cacheGuildes[guilde.Id] = nil
			if storeGuildes then
				pcall(function()
					storeGuildes:RemoveAsync("Guilde_" .. guilde.Id)
				end)
			end
		else
			sauvegarderGuilde(guilde)
		end
	end
	profil.GuildeId = nil
	Services.DataService.Push(player)
end

-- Achat du QG en Or (l'achat en Robux passe par MonetizationService)
function GuildService.AcheterQGOr(player: Player)
	local profil = Services.DataService.Get(player)
	if not profil or not profil.GuildeId then
		return
	end
	local guilde = chargerGuilde(profil.GuildeId)
	if not guilde or guilde.QG then
		return
	end
	if guilde.ChefId ~= player.UserId then
		notification:FireClient(player, { Titre = "Réservé au chef", Message = "Seul le chef de guilde peut acheter le QG.", Couleur = Color3.fromRGB(255, 100, 100) })
		return
	end
	if profil.Or < GameConfig.Guildes.CoutQGOr then
		notification:FireClient(player, { Titre = "Or insuffisant", Message = "Le QG coûte " .. Util.FormatNombre(GameConfig.Guildes.CoutQGOr) .. " Or.", Couleur = Color3.fromRGB(255, 100, 100) })
		return
	end
	profil.Or -= GameConfig.Guildes.CoutQGOr
	GuildService.DebloquerQG(player)
	Services.DataService.Push(player)
end

-- Déblocage effectif du QG (appelé après paiement Or OU Robux)
function GuildService.DebloquerQG(player: Player)
	local profil = Services.DataService.Get(player)
	if not profil or not profil.GuildeId then
		return
	end
	local guilde = chargerGuilde(profil.GuildeId)
	if not guilde or guilde.QG then
		return
	end
	guilde.QG = true
	sauvegarderGuilde(guilde)
	notification:FireClient(player, {
		Titre = "🏰 QG débloqué !",
		Message = "Votre guilde « " .. guilde.Nom .. " » possède maintenant un QG dans la ville !",
		Couleur = Color3.fromRGB(255, 200, 80),
	})
end

----------------------------------------------------------------
-- INIT / REMOTES
----------------------------------------------------------------

function GuildService.Init(services: any)
	Services = services

	Remotes.Event("CreerGuilde").OnServerEvent:Connect(function(player, nom)
		GuildService.Creer(player, nom)
	end)

	Remotes.Event("RejoindreGuilde").OnServerEvent:Connect(function(player, guildeId)
		GuildService.Rejoindre(player, guildeId)
	end)

	Remotes.Event("QuitterGuilde").OnServerEvent:Connect(function(player)
		GuildService.Quitter(player)
	end)

	Remotes.Event("AcheterQGOr").OnServerEvent:Connect(function(player)
		GuildService.AcheterQGOr(player)
	end)

	-- Liste des guildes (pour le panneau Guilde du client)
	Remotes.Function("ListeGuildes").OnServerInvoke = function(_player)
		local resultat = {}
		for _, guildeId in listeIds() do
			local guilde = chargerGuilde(guildeId)
			if guilde then
				table.insert(resultat, {
					Id = guilde.Id,
					Nom = guilde.Nom,
					ChefNom = guilde.ChefNom,
					NbMembres = guilde.NbMembres,
					QG = guilde.QG,
				})
			end
		end
		return resultat
	end

	-- Détails de la guilde du joueur
	Remotes.Function("MaGuilde").OnServerInvoke = function(player)
		local profil = Services.DataService.Get(player)
		if not profil or not profil.GuildeId then
			return nil
		end
		return chargerGuilde(profil.GuildeId)
	end
end

return GuildService
