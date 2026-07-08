--!strict
-- Monstres : construction procédurale des modèles, IA (poursuite + attaque),
-- gestion des dégâts et de la mort (XP, or, loot).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local MonsterService = {}

local Services: any = nil
local vfx = Remotes.Event("VFX")
local degatsEvent = Remotes.Event("DegatsInfliges")

export type MonstreActif = {
	Model: Model,
	Def: any,
	Vie: number,
	VieMax: number,
	DonjonId: number?,
	Mort: boolean,
	DernierAttaquant: Player?,
	ProchaineAttaque: number,
	Cible: Player?,
	SurMort: ((MonstreActif) -> ())?,
	BarreVie: Frame?,
}

local monstres: { [Model]: MonstreActif } = {}

----------------------------------------------------------------
-- CONSTRUCTION DU MODÈLE (procédural, en blocs stylisés)
----------------------------------------------------------------

local function creerPartie(nom: string, taille: Vector3, couleur: Color3, materiau: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = nom
	part.Size = taille
	part.Color = couleur
	part.Material = materiau or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function ajouterYeux(tete: Part, couleur: Color3, taille: number)
	for _, cote in { -1, 1 } do
		local oeil = creerPartie("Oeil", Vector3.new(taille, taille, 0.1), couleur, Enum.Material.Neon)
		oeil.CanCollide = false
		local soudure = Instance.new("WeldConstraint")
		oeil.CFrame = tete.CFrame * CFrame.new(cote * tete.Size.X * 0.22, tete.Size.Y * 0.1, -tete.Size.Z / 2 - 0.05)
		soudure.Part0 = tete
		soudure.Part1 = oeil
		soudure.Parent = oeil
		oeil.Parent = tete.Parent
	end
end

local function construireModele(def: any, position: Vector3): (Model, Humanoid)
	local t = def.Taille
	local model = Instance.new("Model")
	model.Name = def.Nom

	local torse: Part
	if def.Type == "Bete" then
		torse = creerPartie("Torso", Vector3.new(2 * t, 1.6 * t, 3.4 * t), def.Couleur)
	elseif def.Type == "Golem" then
		torse = creerPartie("Torso", Vector3.new(3 * t, 3 * t, 2 * t), def.Couleur, Enum.Material.Slate)
	elseif def.Type == "Volant" then
		torse = creerPartie("Torso", Vector3.new(1.8 * t, 2 * t, 1.2 * t), def.Couleur)
	else -- Humanoide
		torse = creerPartie("Torso", Vector3.new(2 * t, 2.4 * t, 1.2 * t), def.Couleur)
	end
	torse.CFrame = CFrame.new(position + Vector3.new(0, 4 * t, 0))
	torse.Parent = model

	-- HumanoidRootPart obligatoire pour que le Humanoid puisse se déplacer
	local racine = creerPartie("HumanoidRootPart", torse.Size, def.Couleur)
	racine.Transparency = 1
	racine.CanCollide = false
	racine.CFrame = torse.CFrame
	local soudureRacine = Instance.new("WeldConstraint")
	soudureRacine.Part0 = racine
	soudureRacine.Part1 = torse
	soudureRacine.Parent = racine
	racine.Parent = model

	local tete = creerPartie("Head", Vector3.new(1.3 * t, 1.3 * t, 1.3 * t), def.Couleur)
	tete.CFrame = torse.CFrame * CFrame.new(0, torse.Size.Y / 2 + tete.Size.Y / 2, def.Type == "Bete" and -torse.Size.Z / 2 * 0.7 or 0)
	local soudureTete = Instance.new("WeldConstraint")
	soudureTete.Part0 = torse
	soudureTete.Part1 = tete
	soudureTete.Parent = tete
	tete.Parent = model
	ajouterYeux(tete, def.CouleurYeux, 0.32 * t)

	-- Membres décoratifs (soudés, sans collision, le Humanoid gère le déplacement)
	local membres = if def.Type == "Bete" then 4 elseif def.Type == "Golem" then 2 else 2
	for i = 1, membres do
		local jambe = creerPartie("Jambe", Vector3.new(0.7 * t, 2 * t, 0.7 * t), def.Couleur:Lerp(Color3.new(0, 0, 0), 0.25))
		jambe.CanCollide = false
		local offsetX = (i % 2 == 0 and 1 or -1) * torse.Size.X * 0.3
		local offsetZ = def.Type == "Bete" and ((i <= 2 and -1 or 1) * torse.Size.Z * 0.3) or 0
		jambe.CFrame = torse.CFrame * CFrame.new(offsetX, -torse.Size.Y / 2 - jambe.Size.Y / 2 + 0.2, offsetZ)
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0 = torse
		soudure.Part1 = jambe
		soudure.Parent = jambe
		jambe.Parent = model
	end

	-- Ailes pour les volants
	if def.Type == "Volant" then
		for _, cote in { -1, 1 } do
			local aile = creerPartie("Aile", Vector3.new(2.6 * t, 0.15 * t, 1.4 * t), def.Couleur:Lerp(Color3.new(1, 1, 1), 0.15))
			aile.CanCollide = false
			aile.CFrame = torse.CFrame * CFrame.new(cote * (torse.Size.X / 2 + aile.Size.X / 2), torse.Size.Y * 0.25, 0) * CFrame.Angles(0, 0, cote * 0.35)
			local soudure = Instance.new("WeldConstraint")
			soudure.Part0 = torse
			soudure.Part1 = aile
			soudure.Parent = aile
			aile.Parent = model
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = def.Vie
	humanoid.Health = def.Vie
	humanoid.WalkSpeed = def.Vitesse
	humanoid.AutoRotate = true
	humanoid.RequiresNeck = false -- rig custom : sans ça, le Humanoid meurt instantanément
	humanoid.BreakJointsOnDeath = false
	humanoid.HipHeight = 2 * t
	humanoid.Parent = model

	model.PrimaryPart = racine

	-- Barre de vie + nom au-dessus de la tête
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BarreVie"
	billboard.Size = UDim2.fromOffset(120, 34)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, tete.Size.Y + 1.5, 0)
	billboard.AlwaysOnTop = false
	billboard.Adornee = tete
	billboard.Parent = model

	local nomLabel = Instance.new("TextLabel")
	nomLabel.Size = UDim2.new(1, 0, 0, 16)
	nomLabel.BackgroundTransparency = 1
	nomLabel.Font = Enum.Font.GothamBold
	nomLabel.TextSize = 12
	nomLabel.TextColor3 = def.Boss and Color3.fromRGB(255, 90, 90) or Color3.new(1, 1, 1)
	nomLabel.TextStrokeTransparency = 0.4
	nomLabel.Text = (def.Boss and "☠️ " or "") .. def.Nom
	nomLabel.Parent = billboard

	local fondBarre = Instance.new("Frame")
	fondBarre.Position = UDim2.new(0, 0, 0, 18)
	fondBarre.Size = UDim2.new(1, 0, 0, 8)
	fondBarre.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	fondBarre.BorderSizePixel = 0
	fondBarre.Parent = billboard

	local barre = Instance.new("Frame")
	barre.Name = "Remplissage"
	barre.Size = UDim2.fromScale(1, 1)
	barre.BackgroundColor3 = Color3.fromRGB(230, 60, 60)
	barre.BorderSizePixel = 0
	barre.Parent = fondBarre

	return model, humanoid
end

----------------------------------------------------------------
-- SPAWN / DÉGÂTS / MORT
----------------------------------------------------------------

function MonsterService.Spawn(def: any, position: Vector3, donjonId: number?, surMort: ((MonstreActif) -> ())?): MonstreActif
	local model, _humanoid = construireModele(def, position)
	model.Parent = workspace

	local monstre: MonstreActif = {
		Model = model,
		Def = def,
		Vie = def.Vie,
		VieMax = def.Vie,
		DonjonId = donjonId,
		Mort = false,
		DernierAttaquant = nil,
		ProchaineAttaque = 0,
		Cible = nil,
		SurMort = surMort,
		BarreVie = nil,
	}
	monstres[model] = monstre
	return monstre
end

function MonsterService.Infliger(monstre: MonstreActif, degats: number, attaquant: Player?, critique: boolean?)
	if monstre.Mort then
		return
	end
	monstre.Vie = math.max(monstre.Vie - degats, 0)
	monstre.DernierAttaquant = attaquant or monstre.DernierAttaquant

	-- Mise à jour de la barre de vie
	local billboard = monstre.Model:FindFirstChild("BarreVie")
	if billboard then
		local fond = billboard:FindFirstChildWhichIsA("Frame")
		local remplissage = fond and fond:FindFirstChild("Remplissage")
		if remplissage then
			(remplissage :: Frame).Size = UDim2.fromScale(monstre.Vie / monstre.VieMax, 1)
		end
	end

	-- Nombre de dégâts flottant côté clients
	local primaire = monstre.Model.PrimaryPart
	if primaire then
		degatsEvent:FireAllClients(primaire.Position + Vector3.new(0, 3, 0), math.floor(degats), critique or false)
	end

	if monstre.Vie <= 0 then
		MonsterService.Tuer(monstre)
	end
end

function MonsterService.Tuer(monstre: MonstreActif)
	if monstre.Mort then
		return
	end
	monstre.Mort = true
	monstres[monstre.Model] = nil

	local primaire = monstre.Model.PrimaryPart
	if primaire then
		vfx:FireAllClients("MortMonstre", { Position = primaire.Position, Couleur = monstre.Def.Couleur })
	end

	-- Récompenses au dernier attaquant
	local tueur = monstre.DernierAttaquant
	if tueur and tueur.Parent then
		Services.ProgressionService.AjouterXP(tueur, monstre.Def.XP)
		Services.ProgressionService.AjouterOr(tueur, monstre.Def.Or)
		Services.LootService.RollDrop(tueur, monstre.Def)
	end

	if monstre.SurMort then
		task.spawn(monstre.SurMort, monstre)
	end
	monstre.Model:Destroy()
end

-- Détruit tous les monstres d'un donjon (nettoyage)
function MonsterService.NettoyerDonjon(donjonId: number)
	for model, monstre in monstres do
		if monstre.DonjonId == donjonId then
			monstres[model] = nil
			model:Destroy()
		end
	end
end

-- Renvoie les monstres vivants dans un rayon autour d'une position.
function MonsterService.DansRayon(position: Vector3, rayon: number): { MonstreActif }
	local resultat = {}
	for _, monstre in monstres do
		local primaire = monstre.Model.PrimaryPart
		if primaire and not monstre.Mort and (primaire.Position - position).Magnitude <= rayon then
			table.insert(resultat, monstre)
		end
	end
	return resultat
end

----------------------------------------------------------------
-- IA : poursuite du joueur le plus proche + attaque au contact
----------------------------------------------------------------

local RAYON_AGGRO = 80
local RAYON_ATTAQUE = 6

local function tourIA(dt: number)
	local maintenant = os.clock()
	for model, monstre in monstres do
		local primaire = model.PrimaryPart
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not primaire or not humanoid or monstre.Mort then
			continue
		end

		-- Cherche le joueur vivant le plus proche
		local cible: Player? = nil
		local distanceMin = RAYON_AGGRO
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			local humJoueur = character and character:FindFirstChildOfClass("Humanoid")
			if hrp and humJoueur and humJoueur.Health > 0 then
				local distance = ((hrp :: BasePart).Position - primaire.Position).Magnitude
				if distance < distanceMin then
					distanceMin = distance
					cible = player
				end
			end
		end
		monstre.Cible = cible

		if cible then
			local hrp = (cible.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
			if distanceMin > RAYON_ATTAQUE * monstre.Def.Taille then
				humanoid:MoveTo(hrp.Position)
			else
				humanoid:MoveTo(primaire.Position)
				-- Attaque toutes les 1,5 s
				if maintenant >= monstre.ProchaineAttaque then
					monstre.ProchaineAttaque = maintenant + 1.5
					local humJoueur = (cible.Character :: Model):FindFirstChildOfClass("Humanoid")
					if humJoueur then
						local defense = Services.CombatService.DefenseDe(cible)
						local degats = math.max(monstre.Def.Degats * (1 - defense), 1)
						humJoueur:TakeDamage(degats)
						vfx:FireAllClients("AttaqueMonstre", { Position = hrp.Position })
					end
				end
			end
		end
	end
end

function MonsterService.Init(services: any)
	Services = services

	-- Boucle d'IA à ~10 Hz (suffisant et léger)
	local accumulateur = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulateur += dt
		if accumulateur >= 0.1 then
			tourIA(accumulateur)
			accumulateur = 0
		end
	end)
end

return MonsterService
