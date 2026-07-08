--!strict
-- Portails & donjons :
--  - des portails apparaissent aléatoirement dans la ville (rang pondéré E → S)
--  - un joueur entre via ProximityPrompt → téléporté dans un donjon instancié
--  - vagues de monstres puis boss ; victoire = récompenses + progression de rang
--  - échec (mort / temps écoulé) = retour en ville sans récompense de fin

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MonsterConfig = require(Shared:WaitForChild("MonsterConfig"))
local Util = require(Shared:WaitForChild("Util"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DungeonService = {}

local Services: any = nil
local DungeonBuilder = require(script.Parent:WaitForChild("DungeonBuilder"))

local notification = Remotes.Event("Notification")
local etatDonjonEvent = Remotes.Event("EtatDonjon") -- HUD du donjon côté client

type Donjon = {
	Id: number,
	RangId: string,
	Slot: number,
	Construction: any,
	Joueurs: { Player },
	Actif: boolean,
	MonstresRestants: number,
}

local portailsActifs: { [Model]: { RangId: string, Expiration: number } } = {}
local donjons: { [number]: Donjon } = {}
local slotsOccupes: { [number]: boolean } = {}
local compteurDonjons = 0
local pointsApparitionPortails: { Vector3 } = {}
local spawnVille = Vector3.new(0, 5, 0)

----------------------------------------------------------------
-- PORTAILS DANS LA VILLE
----------------------------------------------------------------

local function construirePortail(position: Vector3, rangId: string): Model
	local rang = GameConfig.Rangs[GameConfig.IndexRang[rangId]]
	local model = Instance.new("Model")
	model.Name = "Portail_" .. rangId

	local anneau = Instance.new("Part")
	anneau.Name = "Anneau"
	anneau.Shape = Enum.PartType.Cylinder
	anneau.Size = Vector3.new(1.5, 14, 14)
	anneau.CFrame = CFrame.new(position + Vector3.new(0, 7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	anneau.Anchored = true
	anneau.CanCollide = false
	anneau.Material = Enum.Material.Neon
	anneau.Color = rang.Couleur
	anneau.Parent = model

	local coeur = Instance.new("Part")
	coeur.Name = "Coeur"
	coeur.Shape = Enum.PartType.Cylinder
	coeur.Size = Vector3.new(0.5, 11, 11)
	coeur.CFrame = anneau.CFrame
	coeur.Anchored = true
	coeur.CanCollide = false
	coeur.Material = Enum.Material.ForceField
	coeur.Color = rang.Couleur
	coeur.Transparency = 0.2
	coeur.Parent = model

	local particules = Instance.new("ParticleEmitter")
	particules.Color = ColorSequence.new(rang.Couleur)
	particules.Size = NumberSequence.new(0.6, 0)
	particules.Lifetime = NumberRange.new(0.8, 1.6)
	particules.Rate = 25
	particules.Speed = NumberRange.new(3, 8)
	particules.LightEmission = 1
	particules.Parent = anneau

	local lumiere = Instance.new("PointLight")
	lumiere.Color = rang.Couleur
	lumiere.Range = 30
	lumiere.Brightness = 3
	lumiere.Parent = anneau

	-- Panneau du rang au-dessus du portail
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 60)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 10, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = anneau
	billboard.Parent = model

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 26
	label.TextColor3 = rang.Couleur
	label.TextStrokeTransparency = 0.3
	label.Text = "PORTAIL RANG " .. rangId
	label.Parent = billboard

	-- Interaction
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Entrer dans le portail"
	prompt.ObjectText = "Donjon de rang " .. rangId
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = anneau

	prompt.Triggered:Connect(function(player)
		DungeonService.EntrerDonjon(player, model)
	end)

	model.Parent = workspace
	return model
end

local function fairePoperPortail()
	-- Compte les portails encore valides
	local actifs = 0
	for model, info in portailsActifs do
		if os.clock() > info.Expiration then
			portailsActifs[model] = nil
			model:Destroy()
		else
			actifs += 1
		end
	end
	if actifs >= GameConfig.Portails.MaxActifs or #pointsApparitionPortails == 0 then
		return
	end

	local rang = Util.ChoixPondere(GameConfig.Rangs, "PoidsPortail")
	local position = pointsApparitionPortails[math.random(#pointsApparitionPortails)]

	-- Évite deux portails au même endroit
	for model in portailsActifs do
		local primaire = model:FindFirstChild("Anneau") :: BasePart?
		if primaire and (Vector3.new(primaire.Position.X, 0, primaire.Position.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude < 10 then
			return
		end
	end

	local portail = construirePortail(position, rang.Id)
	portailsActifs[portail] = { RangId = rang.Id, Expiration = os.clock() + GameConfig.Portails.DureeVie }

	notification:FireAllClients({
		Titre = "⚠️ Un portail de rang " .. rang.Id .. " est apparu !",
		Message = "Trouvez-le dans la ville avant qu'il ne se referme.",
		Couleur = rang.Couleur,
	})
end

----------------------------------------------------------------
-- DONJONS INSTANCIÉS
----------------------------------------------------------------

local function slotLibre(): number?
	for i = 1, GameConfig.Monde.MaxDonjonsSimultanes do
		if not slotsOccupes[i] then
			return i
		end
	end
	return nil
end

local function teleporter(player: Player, position: Vector3)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(position)
	end
end

local function terminerDonjon(donjon: Donjon, victoire: boolean)
	if not donjon.Actif then
		return
	end
	donjon.Actif = false

	local rang = GameConfig.Rangs[GameConfig.IndexRang[donjon.RangId]]
	for _, player in donjon.Joueurs do
		if player.Parent then
			if victoire then
				local orGagne = math.random(rang.OrMin, rang.OrMax)
				Services.ProgressionService.AjouterOr(player, orGagne)
				Services.ProgressionService.AjouterXP(player, rang.XPDonjon)
				Services.ProgressionService.EnregistrerDonjonReussi(player, donjon.RangId)
				Services.BattlePassService.AjouterXPPasse(player, rang.XPPasse)
				notification:FireClient(player, {
					Titre = "🏆 DONJON TERMINÉ !",
					Message = "+" .. orGagne .. " Or • +" .. rang.XPDonjon .. " XP • +" .. rang.XPPasse .. " XP de passe",
					Couleur = rang.Couleur,
				})
			else
				notification:FireClient(player, {
					Titre = "Donjon échoué",
					Message = "Vous avez été renvoyé en ville.",
					Couleur = Color3.fromRGB(255, 100, 100),
				})
			end
			etatDonjonEvent:FireClient(player, nil) -- ferme le HUD donjon
			teleporter(player, spawnVille + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8)))
		end
	end

	Services.MonsterService.NettoyerDonjon(donjon.Id)
	donjon.Construction.Model:Destroy()
	slotsOccupes[donjon.Slot] = nil
	donjons[donjon.Id] = nil
end

local function joueursVivantsDansDonjon(donjon: Donjon): number
	local vivants = 0
	for _, player in donjon.Joueurs do
		local character = player.Parent and player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			-- Le joueur doit toujours être physiquement dans le donjon
			if hrp then
				local origine = GameConfig.Monde.OrigineDonjons + Vector3.new(donjon.Slot * GameConfig.Monde.EcartSlots, 0, 0)
				if (hrp.Position - origine).Magnitude < 600 then
					vivants += 1
				end
			end
		end
	end
	return vivants
end

local function lancerDonjon(donjon: Donjon)
	task.spawn(function()
		local rang = GameConfig.Rangs[GameConfig.IndexRang[donjon.RangId]]
		local monstresDuRang = MonsterConfig.ParRang[donjon.RangId]
		local finLimite = os.clock() + GameConfig.Portails.TempsLimiteDonjon

		local function pousserEtat(texte: string)
			for _, player in donjon.Joueurs do
				if player.Parent then
					etatDonjonEvent:FireClient(player, {
						Rang = donjon.RangId,
						Texte = texte,
						TempsRestant = math.max(finLimite - os.clock(), 0),
					})
				end
			end
		end

		-- VAGUES
		for vague = 1, rang.Vagues do
			if not donjon.Actif then
				return
			end
			pousserEtat("Vague " .. vague .. " / " .. rang.Vagues)

			local vivantsVague = rang.MonstresParVague
			for i = 1, rang.MonstresParVague do
				local def = monstresDuRang[math.random(#monstresDuRang)]
				local point = donjon.Construction.PointsSpawnMonstres[math.random(#donjon.Construction.PointsSpawnMonstres)]
				Services.MonsterService.Spawn(def, point, donjon.Id, function()
					vivantsVague -= 1
				end)
			end

			-- Attend la fin de la vague (ou l'échec)
			while vivantsVague > 0 do
				task.wait(1)
				if not donjon.Actif then
					return
				end
				if os.clock() > finLimite or joueursVivantsDansDonjon(donjon) == 0 then
					terminerDonjon(donjon, false)
					return
				end
				pousserEtat("Vague " .. vague .. " / " .. rang.Vagues .. " — " .. vivantsVague .. " monstre(s) restant(s)")
			end
		end

		-- BOSS
		if not donjon.Actif then
			return
		end
		local defBoss = MonsterConfig.Boss[donjon.RangId]
		pousserEtat("☠️ BOSS : " .. defBoss.Nom)
		local bossVivant = true
		Services.MonsterService.Spawn(defBoss, donjon.Construction.PositionBoss, donjon.Id, function()
			bossVivant = false
		end)

		while bossVivant do
			task.wait(1)
			if not donjon.Actif then
				return
			end
			if os.clock() > finLimite or joueursVivantsDansDonjon(donjon) == 0 then
				terminerDonjon(donjon, false)
				return
			end
			pousserEtat("☠️ BOSS : " .. defBoss.Nom)
		end

		terminerDonjon(donjon, true)
	end)
end

function DungeonService.EntrerDonjon(player: Player, portail: Model)
	local info = portailsActifs[portail]
	if not info then
		return
	end
	local profil = Services.DataService.Get(player)
	if not profil then
		return
	end
	if not profil.Classe then
		notification:FireClient(player, {
			Titre = "Choisissez d'abord une classe !",
			Message = "Vous ne pouvez pas entrer dans un portail sans classe.",
			Couleur = Color3.fromRGB(255, 100, 100),
		})
		return
	end

	local slot = slotLibre()
	if not slot then
		notification:FireClient(player, {
			Titre = "Trop de donjons actifs",
			Message = "Réessayez dans quelques instants.",
			Couleur = Color3.fromRGB(255, 100, 100),
		})
		return
	end

	-- Le portail se consume : les joueurs proches (groupe) entrent ensemble
	portailsActifs[portail] = nil
	local anneau = portail:FindFirstChild("Anneau") :: BasePart?
	local joueurs: { Player } = { player }
	if anneau then
		for _, autre in Players:GetPlayers() do
			if autre ~= player then
				local hrp = autre.Character and autre.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local profilAutre = hrp and Services.DataService.Get(autre)
				if hrp and profilAutre and profilAutre.Classe and (hrp.Position - anneau.Position).Magnitude < 25 then
					table.insert(joueurs, autre)
				end
			end
		end
	end
	portail:Destroy()

	compteurDonjons += 1
	slotsOccupes[slot] = true
	local origine = GameConfig.Monde.OrigineDonjons + Vector3.new(slot * GameConfig.Monde.EcartSlots, 0, 0)
	local construction = DungeonBuilder.Construire(origine, info.RangId)

	local donjon: Donjon = {
		Id = compteurDonjons,
		RangId = info.RangId,
		Slot = slot,
		Construction = construction,
		Joueurs = joueurs,
		Actif = true,
		MonstresRestants = 0,
	}
	donjons[donjon.Id] = donjon

	for _, membre in joueurs do
		teleporter(membre, construction.SpawnJoueur)
		notification:FireClient(membre, {
			Titre = "Donjon de rang " .. info.RangId,
			Message = "Survivez aux vagues et vainquez le boss !",
			Couleur = GameConfig.Rangs[GameConfig.IndexRang[info.RangId]].Couleur,
		})
	end

	lancerDonjon(donjon)
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

function DungeonService.DefinirPointsApparition(points: { Vector3 }, spawn: Vector3)
	pointsApparitionPortails = points
	spawnVille = spawn
end

function DungeonService.Init(services: any)
	Services = services

	task.spawn(function()
		task.wait(10) -- laisse la ville se construire
		while true do
			fairePoperPortail()
			task.wait(GameConfig.Portails.IntervalleApparition)
		end
	end)
end

return DungeonService
