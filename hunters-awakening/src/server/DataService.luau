--!strict
-- Sauvegarde des profils joueurs (DataStore) : chargement, autosave, sauvegarde à la déconnexion.
-- Réplique le profil au client via le RemoteEvent "ProfilMisAJour".

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DataService = {}

local STORE_NOM = "ProfilsChasseurs_v1"
local INTERVALLE_AUTOSAVE = 120

-- En Studio, activer "Enable Studio Access to API Services" pour que la sauvegarde fonctionne.
local store = nil
do
	local ok, resultat = pcall(function()
		return DataStoreService:GetDataStore(STORE_NOM)
	end)
	if ok then
		store = resultat
	else
		warn("[DataService] DataStore indisponible (mode sans sauvegarde) : " .. tostring(resultat))
	end
end

local profils: { [Player]: any } = {}
local evenementProfil = Remotes.Event("ProfilMisAJour")

local function profilParDefaut()
	local stats = {}
	for _, stat in GameConfig.Stats do
		stats[stat.Id] = GameConfig.StatDepart
	end
	local donjonsReussis = {}
	for _, rang in GameConfig.Rangs do
		donjonsReussis[rang.Id] = 0
	end
	return {
		Niveau = 1,
		XP = 0,
		PointsDeStats = 0,
		Stats = stats,
		Classe = nil, -- choisie au début de la partie
		Or = GameConfig.Monnaies.Or.Depart,
		Cristaux = GameConfig.Monnaies.Cristaux.Depart,
		RangChasseur = "E",
		DonjonsReussis = donjonsReussis,
		Inventaire = {}, -- liste d'objets { UUID, Nom, Slot, Rarete, Rang, Degats?, Defense?, Bonus }
		Equipement = { Arme = nil, Armure = nil, Accessoire = nil }, -- UUID des objets équipés
		GuildeId = nil,
		Titre = nil,
		PasseDeCombat = { Saison = 1, XP = 0, Premium = false, Reclames = {} },
		DerniersCristauxQuotidiens = 0, -- os.time() du dernier bonus d'abonné
		TempsDeJeu = 0,
	}
end

local function cleJoueur(userId: number): string
	return "Joueur_" .. userId
end

local function charger(player: Player)
	local profil = nil
	if store then
		for essai = 1, 3 do
			local ok, resultat = pcall(function()
				return store:GetAsync(cleJoueur(player.UserId))
			end)
			if ok then
				profil = resultat
				break
			end
			task.wait(2 ^ essai)
		end
	end
	if profil == nil then
		profil = profilParDefaut()
	else
		Util.Reconcilier(profil, profilParDefaut())
	end
	profils[player] = profil
	DataService.Push(player)
end

local function sauvegarder(player: Player)
	local profil = profils[player]
	if not profil or not store then
		return
	end
	for essai = 1, 3 do
		local ok, err = pcall(function()
			store:SetAsync(cleJoueur(player.UserId), profil)
		end)
		if ok then
			return
		end
		warn("[DataService] Échec de sauvegarde pour " .. player.Name .. " : " .. tostring(err))
		task.wait(2 ^ essai)
	end
end

-- Renvoie le profil du joueur (attend le chargement si nécessaire).
function DataService.Get(player: Player): any
	while profils[player] == nil and player.Parent do
		task.wait(0.1)
	end
	return profils[player]
end

-- Réplique le profil au client (à appeler après toute modification).
function DataService.Push(player: Player)
	local profil = profils[player]
	if profil then
		evenementProfil:FireClient(player, profil)
	end
end

function DataService.Init(_services: any)
	Players.PlayerAdded:Connect(charger)
	for _, player in Players:GetPlayers() do
		task.spawn(charger, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		sauvegarder(player)
		profils[player] = nil
	end)

	-- Autosave périodique
	task.spawn(function()
		while true do
			task.wait(INTERVALLE_AUTOSAVE)
			for player in profils do
				task.spawn(sauvegarder, player)
				local profil = profils[player]
				if profil then
					profil.TempsDeJeu += INTERVALLE_AUTOSAVE
				end
			end
		end
	end)

	-- Sauvegarde de tout le monde à la fermeture du serveur
	game:BindToClose(function()
		for player in profils do
			sauvegarder(player)
		end
	end)
end

return DataService
