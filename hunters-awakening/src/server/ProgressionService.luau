--!strict
-- Progression : XP, niveaux, rang de chasseur, répartition des points de stats,
-- application des stats dérivées (vie, mana, vitesse) sur le personnage.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ProgressionService = {}

local Services: any = nil
local notification = Remotes.Event("Notification")

----------------------------------------------------------------
-- STATS DÉRIVÉES (stats de base + bonus d'équipement)
----------------------------------------------------------------

-- Renvoie les stats totales (points répartis + bonus des objets équipés).
function ProgressionService.StatsTotales(profil: any): { [string]: number }
	local total = {}
	for _, stat in GameConfig.Stats do
		total[stat.Id] = profil.Stats[stat.Id] or 0
	end
	for _, uuid in profil.Equipement do
		for _, objet in profil.Inventaire do
			if objet.UUID == uuid and objet.Bonus then
				for statId, valeur in objet.Bonus do
					total[statId] = (total[statId] or 0) + valeur
				end
			end
		end
	end
	return total
end

-- Dégâts de l'arme équipée + défense de l'armure équipée.
function ProgressionService.BonusEquipement(profil: any): (number, number)
	local degats, defense = 0, 0
	for _, objet in profil.Inventaire do
		if objet.UUID == profil.Equipement.Arme and objet.Degats then
			degats += objet.Degats
		elseif objet.UUID == profil.Equipement.Armure and objet.Defense then
			defense += objet.Defense
		end
	end
	return degats, defense
end

-- Applique vie max, mana max et vitesse sur le personnage.
function ProgressionService.AppliquerStats(player: Player)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	local stats = ProgressionService.StatsTotales(profil)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local vieMax = GameConfig.VieMax(profil.Niveau, stats.Endurance)
		local ratio = humanoid.Health / math.max(humanoid.MaxHealth, 1)
		humanoid.MaxHealth = vieMax
		humanoid.Health = math.max(vieMax * ratio, 1)
		humanoid.WalkSpeed = GameConfig.VitesseMarche(stats.Vitesse)
	end
	local manaMax = GameConfig.ManaMax(profil.Niveau, stats.Intelligence)
	player:SetAttribute("ManaMax", manaMax)
	if (player:GetAttribute("Mana") or 0) > manaMax then
		player:SetAttribute("Mana", manaMax)
	end
end

----------------------------------------------------------------
-- XP / NIVEAUX
----------------------------------------------------------------

function ProgressionService.AjouterXP(player: Player, montant: number)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	if Services.MonetizationService.EstAbonne(player) then
		montant = math.floor(montant * GameConfig.Abonnement.MultXP)
	end
	profil.XP += montant

	local aMonte = false
	while profil.Niveau < GameConfig.NiveauMax and profil.XP >= GameConfig.XPPourNiveau(profil.Niveau) do
		profil.XP -= GameConfig.XPPourNiveau(profil.Niveau)
		profil.Niveau += 1
		profil.PointsDeStats += GameConfig.PointsParNiveau
		aMonte = true
	end

	if aMonte then
		notification:FireClient(player, {
			Titre = "NIVEAU " .. profil.Niveau .. " !",
			Message = "+" .. GameConfig.PointsParNiveau .. " points de stats à répartir (touche C)",
			Couleur = Color3.fromRGB(255, 200, 80),
		})
		Remotes.Event("VFX"):FireAllClients("LevelUp", { Joueur = player })
		ProgressionService.AppliquerStats(player)
		ProgressionService.MettreAJourLeaderstats(player)
	end
	Services.DataService.Push(player)
end

function ProgressionService.AjouterOr(player: Player, montant: number)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	if montant > 0 and Services.MonetizationService.EstAbonne(player) then
		montant = math.floor(montant * GameConfig.Abonnement.MultOr)
	end
	profil.Or = math.max(profil.Or + montant, 0)
	Services.DataService.Push(player)
end

----------------------------------------------------------------
-- RANG DE CHASSEUR
----------------------------------------------------------------

-- Appelé quand un donjon est réussi : progression vers le rang suivant.
function ProgressionService.EnregistrerDonjonReussi(player: Player, rangId: string)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	profil.DonjonsReussis[rangId] = (profil.DonjonsReussis[rangId] or 0) + 1

	local indexActuel = GameConfig.IndexRang[profil.RangChasseur]
	local rangActuel = GameConfig.Rangs[indexActuel]
	if rangId == profil.RangChasseur and indexActuel < #GameConfig.Rangs then
		if profil.DonjonsReussis[rangId] >= rangActuel.DonjonsPourMonter then
			local nouveauRang = GameConfig.Rangs[indexActuel + 1]
			profil.RangChasseur = nouveauRang.Id
			notification:FireClient(player, {
				Titre = "RANG " .. nouveauRang.Id .. " !",
				Message = "Vous êtes maintenant un chasseur de rang " .. nouveauRang.Id .. " !",
				Couleur = nouveauRang.Couleur,
			})
			ProgressionService.MettreAJourLeaderstats(player)
		end
	end
	Services.DataService.Push(player)
end

----------------------------------------------------------------
-- LEADERSTATS (classement Roblox natif)
----------------------------------------------------------------

function ProgressionService.MettreAJourLeaderstats(player: Player)
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local niveau = Instance.new("IntValue")
		niveau.Name = "Niveau"
		niveau.Parent = leaderstats

		local rang = Instance.new("StringValue")
		rang.Name = "Rang"
		rang.Parent = leaderstats
	end
	local valeurNiveau = leaderstats:FindFirstChild("Niveau") :: IntValue
	local valeurRang = leaderstats:FindFirstChild("Rang") :: StringValue
	valeurNiveau.Value = profil.Niveau
	valeurRang.Value = profil.RangChasseur
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

function ProgressionService.Init(services: any)
	Services = services

	-- Répartition d'un point de stat
	Remotes.Event("RepartirPoint").OnServerEvent:Connect(function(player, statId)
		local profil = Services.DataService.Get(player)
		if not profil or profil.PointsDeStats <= 0 then
			return
		end
		local statValide = false
		for _, stat in GameConfig.Stats do
			if stat.Id == statId then
				statValide = true
				break
			end
		end
		if not statValide then
			return
		end
		profil.PointsDeStats -= 1
		profil.Stats[statId] += 1
		ProgressionService.AppliquerStats(player)
		Services.DataService.Push(player)
	end)

	-- Choix de classe (une seule fois)
	Remotes.Event("ChoisirClasse").OnServerEvent:Connect(function(player, classeId)
		local profil = Services.DataService.Get(player)
		if not profil or profil.Classe ~= nil then
			return
		end
		if typeof(classeId) ~= "string" or not ClassConfig.ParId[classeId] then
			return
		end
		profil.Classe = classeId
		notification:FireClient(player, {
			Titre = "Classe choisie",
			Message = "Vous êtes maintenant " .. ClassConfig.ParId[classeId].Nom .. " !",
			Couleur = ClassConfig.ParId[classeId].Couleur,
		})
		Services.DataService.Push(player)
	end)

	-- Équiper / déséquiper un objet
	Remotes.Event("EquiperObjet").OnServerEvent:Connect(function(player, uuid)
		local profil = Services.DataService.Get(player)
		if not profil or typeof(uuid) ~= "string" then
			return
		end
		for _, objet in profil.Inventaire do
			if objet.UUID == uuid then
				if profil.Equipement[objet.Slot] == uuid then
					profil.Equipement[objet.Slot] = nil -- déséquipe
				else
					profil.Equipement[objet.Slot] = uuid
				end
				ProgressionService.AppliquerStats(player)
				Services.DataService.Push(player)
				return
			end
		end
	end)

	-- Vendre un objet (50% de sa "valeur" selon rang et rareté)
	Remotes.Event("VendreObjet").OnServerEvent:Connect(function(player, uuid)
		local profil = Services.DataService.Get(player)
		if not profil or typeof(uuid) ~= "string" then
			return
		end
		for index, objet in profil.Inventaire do
			if objet.UUID == uuid then
				-- On ne vend pas un objet équipé
				for slot, equipe in profil.Equipement do
					if equipe == uuid then
						return
					end
				end
				local rang = GameConfig.Rangs[GameConfig.IndexRang[objet.Rang] or 1]
				local rarete = ItemConfig.RareteParId[objet.Rarete]
				local prix = math.floor((rang.OrMax * 2) * (rarete and rarete.Mult or 1) * 0.5)
				table.remove(profil.Inventaire, index)
				ProgressionService.AjouterOr(player, prix)
				notification:FireClient(player, {
					Titre = "Objet vendu",
					Message = objet.Nom .. " vendu pour " .. prix .. " Or",
					Couleur = Color3.fromRGB(255, 200, 80),
				})
				return
			end
		end
	end)

	-- Mise en place du personnage à chaque (re)spawn
	local function surPersonnage(player: Player)
		player.CharacterAdded:Connect(function(character)
			local profil = Services.DataService.Get(player)
			if not profil then
				return
			end
			task.wait(0.1)
			ProgressionService.AppliquerStats(player)
			-- Mana plein au spawn
			player:SetAttribute("Mana", player:GetAttribute("ManaMax") or 50)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		surPersonnage(player)
		task.spawn(function()
			Services.DataService.Get(player) -- attend le chargement
			ProgressionService.MettreAJourLeaderstats(player)
			ProgressionService.AppliquerStats(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		surPersonnage(player)
	end

	-- Régénération de mana (et de vie hors combat, légère)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local manaMax = player:GetAttribute("ManaMax")
				if manaMax then
					local mana = player:GetAttribute("Mana") or 0
					player:SetAttribute("Mana", math.min(mana + manaMax * 0.03, manaMax))
				end
			end
		end
	end)
end

return ProgressionService
