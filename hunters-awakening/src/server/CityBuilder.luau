--!strict
-- Construit la grande ville hub (procédural) : place centrale, hall des guildes,
-- quartiers de bâtiments, remparts, lampadaires, points d'apparition des portails,
-- et règle l'éclairage / l'ambiance.

local Lighting = game:GetService("Lighting")

local CityBuilder = {}

local TAILLE_VILLE = 900

local function part(props: { [string]: any }, parent: Instance?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for cle, valeur in props do
		(p :: any)[cle] = valeur
	end
	if parent then
		p.Parent = parent
	end
	return p
end

----------------------------------------------------------------
-- AMBIANCE / ÉCLAIRAGE
----------------------------------------------------------------

local function configurerEclairage()
	Lighting.ClockTime = 15
	Lighting.Brightness = 2.2
	Lighting.Ambient = Color3.fromRGB(90, 85, 110)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 115, 140)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.35
	atmosphere.Offset = 0.4
	atmosphere.Color = Color3.fromRGB(199, 185, 230)
	atmosphere.Decay = Color3.fromRGB(110, 90, 150)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 32
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Contrast = 0.08
	correction.Saturation = 0.12
	correction.TintColor = Color3.fromRGB(255, 248, 255)
	correction.Parent = Lighting
end

----------------------------------------------------------------
-- ÉLÉMENTS DE LA VILLE
----------------------------------------------------------------

local function construireBatiment(dossier: Instance, position: Vector3, largeur: number, profondeur: number, etages: number)
	local hauteur = etages * 12
	local couleurs = {
		Color3.fromRGB(190, 175, 155),
		Color3.fromRGB(170, 160, 175),
		Color3.fromRGB(200, 185, 170),
		Color3.fromRGB(155, 150, 165),
	}
	local corps = part({
		Name = "Batiment",
		Size = Vector3.new(largeur, hauteur, profondeur),
		Position = position + Vector3.new(0, hauteur / 2, 0),
		Material = Enum.Material.Brick,
		Color = couleurs[math.random(#couleurs)],
	}, dossier)

	-- Toit en pente (style médiéval-fantasy)
	local toit = part({
		Name = "Toit",
		Size = Vector3.new(largeur + 2, 6, profondeur + 2),
		Position = position + Vector3.new(0, hauteur + 3, 0),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(90, 60, 80),
	}, dossier)
	toit.CFrame = toit.CFrame * CFrame.Angles(0, 0, math.rad(math.random(-3, 3)))

	-- Fenêtres lumineuses
	for etage = 1, etages do
		for f = 1, math.max(math.floor(largeur / 10), 1) do
			if math.random() < 0.7 then
				part({
					Name = "Fenetre",
					Size = Vector3.new(2.4, 3.2, 0.3),
					Position = position + Vector3.new(-largeur / 2 + f * (largeur / (math.floor(largeur / 10) + 1)), etage * 12 - 5, profondeur / 2 + 0.1),
					Material = Enum.Material.Neon,
					Color = Color3.fromRGB(255, 214, 140),
					CanCollide = false,
				}, dossier)
			end
		end
	end
	return corps
end

local function construireLampadaire(dossier: Instance, position: Vector3)
	part({
		Name = "Poteau",
		Size = Vector3.new(0.8, 12, 0.8),
		Position = position + Vector3.new(0, 6, 0),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(40, 40, 50),
	}, dossier)
	local lampe = part({
		Name = "Lampe",
		Size = Vector3.new(1.6, 1.6, 1.6),
		Position = position + Vector3.new(0, 12.5, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(170, 140, 255),
		CanCollide = false,
	}, dossier)
	local lumiere = Instance.new("PointLight")
	lumiere.Color = Color3.fromRGB(190, 160, 255)
	lumiere.Range = 26
	lumiere.Brightness = 1.5
	lumiere.Parent = lampe
end

local function construireHallDesGuildes(dossier: Instance, position: Vector3)
	local hall = Instance.new("Model")
	hall.Name = "HallDesGuildes"
	hall.Parent = dossier

	local base = part({
		Name = "Base",
		Size = Vector3.new(70, 30, 50),
		Position = position + Vector3.new(0, 15, 0),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(225, 218, 235),
	}, hall)

	part({
		Name = "Toit",
		Size = Vector3.new(76, 5, 56),
		Position = position + Vector3.new(0, 32.5, 0),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(80, 60, 120),
	}, hall)

	-- Colonnes à l'entrée
	for _, x in { -25, -12, 12, 25 } do
		part({
			Name = "Colonne",
			Size = Vector3.new(3, 30, 3),
			Position = position + Vector3.new(x, 15, 28),
			Material = Enum.Material.Marble,
			Color = Color3.fromRGB(240, 235, 245),
		}, hall)
	end

	-- Enseigne
	local enseigne = part({
		Name = "Enseigne",
		Size = Vector3.new(40, 6, 1),
		Position = position + Vector3.new(0, 26, 28.5),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(140, 100, 255),
		CanCollide = false,
	}, hall)
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.CanvasSize = Vector2.new(800, 120)
	surface.Parent = enseigne
	local texte = Instance.new("TextLabel")
	texte.Size = UDim2.fromScale(1, 1)
	texte.BackgroundTransparency = 1
	texte.Font = Enum.Font.GothamBlack
	texte.TextScaled = true
	texte.TextColor3 = Color3.new(1, 1, 1)
	texte.Text = "⚔️ HALL DES GUILDES ⚔️"
	texte.Parent = surface

	base:SetAttribute("HallDesGuildes", true)
	return hall
end

----------------------------------------------------------------
-- CONSTRUCTION PRINCIPALE
----------------------------------------------------------------

-- Renvoie { PointsPortails = {Vector3}, SpawnVille = Vector3 }
function CityBuilder.Construire(): any
	configurerEclairage()

	local ville = Instance.new("Model")
	ville.Name = "Ville"
	ville.Parent = workspace

	-- Sol principal (herbe) + place centrale (pavés)
	part({
		Name = "SolVille",
		Size = Vector3.new(TAILLE_VILLE, 4, TAILLE_VILLE),
		Position = Vector3.new(0, -2, 0),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(96, 140, 85),
	}, ville)

	part({
		Name = "PlaceCentrale",
		Size = Vector3.new(160, 0.5, 160),
		Position = Vector3.new(0, 0.25, 0),
		Material = Enum.Material.Cobblestone,
		Color = Color3.fromRGB(140, 135, 145),
	}, ville)

	-- Fontaine magique au centre
	local bassin = part({
		Name = "Fontaine",
		Size = Vector3.new(18, 3, 18),
		Position = Vector3.new(0, 1.5, 0),
		Material = Enum.Material.Marble,
		Color = Color3.fromRGB(210, 205, 220),
	}, ville)
	local cristal = part({
		Name = "CristalCentral",
		Size = Vector3.new(4, 10, 4),
		Position = Vector3.new(0, 9, 0),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(130, 100, 255),
		CanCollide = false,
	}, ville)
	cristal.CFrame = cristal.CFrame * CFrame.Angles(math.rad(15), math.rad(45), 0)
	local lumiereCristal = Instance.new("PointLight")
	lumiereCristal.Color = Color3.fromRGB(150, 110, 255)
	lumiereCristal.Range = 60
	lumiereCristal.Brightness = 2
	lumiereCristal.Parent = cristal
	local particulesCristal = Instance.new("ParticleEmitter")
	particulesCristal.Color = ColorSequence.new(Color3.fromRGB(170, 130, 255))
	particulesCristal.Size = NumberSequence.new(0.5, 0)
	particulesCristal.Lifetime = NumberRange.new(1, 2)
	particulesCristal.Rate = 15
	particulesCristal.Speed = NumberRange.new(2, 5)
	particulesCristal.LightEmission = 1
	particulesCristal.Parent = cristal

	-- Routes en croix
	for _, info in {
		{ Vector3.new(24, 0.4, TAILLE_VILLE), Vector3.new(0, 0.2, 0) },
		{ Vector3.new(TAILLE_VILLE, 0.4, 24), Vector3.new(0, 0.2, 0) },
	} do
		part({
			Name = "Route",
			Size = info[1],
			Position = info[2],
			Material = Enum.Material.Cobblestone,
			Color = Color3.fromRGB(120, 115, 125),
		}, ville)
	end

	-- Hall des guildes au nord de la place
	construireHallDesGuildes(ville, Vector3.new(0, 0, -140))

	-- Quartiers de bâtiments autour de la place
	math.randomseed(20260708) -- ville identique sur tous les serveurs
	local pointsPortails: { Vector3 } = {}
	for x = -1, 1 do
		for z = -1, 1 do
			if x == 0 and z == 0 then
				continue
			end
			local centreQuartier = Vector3.new(x * 280, 0, z * 280)
			-- 4 à 6 bâtiments par quartier
			for _ = 1, math.random(4, 6) do
				local offset = Vector3.new(math.random(-90, 90), 0, math.random(-90, 90))
				construireBatiment(
					ville,
					centreQuartier + offset,
					math.random(18, 34),
					math.random(18, 34),
					math.random(1, 4)
				)
			end
			-- Un point d'apparition de portail par quartier (dans une clairière)
			table.insert(pointsPortails, centreQuartier + Vector3.new(math.random(-40, 40), 0, math.random(-40, 40)))
		end
	end
	-- Points de portail supplémentaires près de la place
	table.insert(pointsPortails, Vector3.new(120, 0, 120))
	table.insert(pointsPortails, Vector3.new(-120, 0, -120))
	table.insert(pointsPortails, Vector3.new(120, 0, -120))
	table.insert(pointsPortails, Vector3.new(-120, 0, 120))

	-- Lampadaires le long des routes
	for i = -4, 4 do
		if i ~= 0 then
			construireLampadaire(ville, Vector3.new(i * 90, 0, 16))
			construireLampadaire(ville, Vector3.new(16, 0, i * 90))
		end
	end

	-- Remparts + tours d'angle
	local demiTaille = TAILLE_VILLE / 2
	for _, info in {
		{ Vector3.new(TAILLE_VILLE, 30, 8), Vector3.new(0, 15, demiTaille) },
		{ Vector3.new(TAILLE_VILLE, 30, 8), Vector3.new(0, 15, -demiTaille) },
		{ Vector3.new(8, 30, TAILLE_VILLE), Vector3.new(demiTaille, 15, 0) },
		{ Vector3.new(8, 30, TAILLE_VILLE), Vector3.new(-demiTaille, 15, 0) },
	} do
		part({
			Name = "Rempart",
			Size = info[1],
			Position = info[2],
			Material = Enum.Material.Rock,
			Color = Color3.fromRGB(105, 100, 115),
		}, ville)
	end
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			part({
				Name = "Tour",
				Size = Vector3.new(20, 55, 20),
				Position = Vector3.new(x * demiTaille, 27.5, z * demiTaille),
				Material = Enum.Material.Rock,
				Color = Color3.fromRGB(95, 90, 105),
			}, ville)
		end
	end

	math.randomseed(os.time()) -- on rend l'aléatoire au reste du jeu

	-- Point de spawn des joueurs (sur la place)
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.6, 40)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Material = Enum.Material.Marble
	spawn.Color = Color3.fromRGB(200, 190, 230)
	spawn.Parent = ville

	return {
		PointsPortails = pointsPortails,
		SpawnVille = Vector3.new(0, 5, 40),
	}
end

return CityBuilder
