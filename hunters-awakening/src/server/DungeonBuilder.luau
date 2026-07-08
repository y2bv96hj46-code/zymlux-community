--!strict
-- Construit l'arène d'un donjon (procédural) : sol, murs, piliers, torches,
-- thème coloré selon le rang du portail.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local DungeonBuilder = {}

local TAILLE_ARENE = 220

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for cle, valeur in props do
		(p :: any)[cle] = valeur
	end
	return p
end

-- Renvoie { Model, SpawnJoueur (Vector3), PointsSpawnMonstres ({Vector3}), PositionBoss (Vector3) }
function DungeonBuilder.Construire(origine: Vector3, rangId: string): any
	local rang = GameConfig.Rangs[GameConfig.IndexRang[rangId]]
	local couleurTheme = rang.Couleur

	local model = Instance.new("Model")
	model.Name = "Donjon_" .. rangId

	-- Sol
	local sol = part({
		Name = "Sol",
		Size = Vector3.new(TAILLE_ARENE, 4, TAILLE_ARENE),
		Position = origine + Vector3.new(0, -2, 0),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(45, 42, 55),
	})
	sol.Parent = model

	-- Lignes lumineuses au sol (ambiance "portail magique")
	for i = -2, 2 do
		local ligne = part({
			Name = "Ligne",
			Size = Vector3.new(1, 0.2, TAILLE_ARENE * 0.9),
			Position = origine + Vector3.new(i * 30, 0.1, 0),
			Material = Enum.Material.Neon,
			Color = couleurTheme,
			Transparency = 0.5,
			CanCollide = false,
		})
		ligne.Parent = model
	end

	-- Murs d'enceinte
	local hauteurMur = 40
	for _, info in {
		{ Vector3.new(TAILLE_ARENE, hauteurMur, 6), Vector3.new(0, hauteurMur / 2, TAILLE_ARENE / 2) },
		{ Vector3.new(TAILLE_ARENE, hauteurMur, 6), Vector3.new(0, hauteurMur / 2, -TAILLE_ARENE / 2) },
		{ Vector3.new(6, hauteurMur, TAILLE_ARENE), Vector3.new(TAILLE_ARENE / 2, hauteurMur / 2, 0) },
		{ Vector3.new(6, hauteurMur, TAILLE_ARENE), Vector3.new(-TAILLE_ARENE / 2, hauteurMur / 2, 0) },
	} do
		local mur = part({
			Name = "Mur",
			Size = info[1],
			Position = origine + info[2],
			Material = Enum.Material.Rock,
			Color = Color3.fromRGB(60, 55, 70),
		})
		mur.Parent = model
	end

	-- Piliers + torches
	for x = -1, 1, 2 do
		for z = -1, 1, 2 do
			local pilier = part({
				Name = "Pilier",
				Size = Vector3.new(8, 34, 8),
				Position = origine + Vector3.new(x * TAILLE_ARENE * 0.3, 17, z * TAILLE_ARENE * 0.3),
				Material = Enum.Material.Slate,
				Color = Color3.fromRGB(70, 65, 85),
			})
			pilier.Parent = model

			local torche = part({
				Name = "Torche",
				Size = Vector3.new(2, 2, 2),
				Position = pilier.Position + Vector3.new(0, 19, 0),
				Material = Enum.Material.Neon,
				Color = couleurTheme,
				CanCollide = false,
			})
			local lumiere = Instance.new("PointLight")
			lumiere.Color = couleurTheme
			lumiere.Range = 40
			lumiere.Brightness = 2
			lumiere.Parent = torche

			local particules = Instance.new("ParticleEmitter")
			particules.Color = ColorSequence.new(couleurTheme)
			particules.Size = NumberSequence.new(0.8, 0)
			particules.Lifetime = NumberRange.new(0.5, 1.2)
			particules.Rate = 12
			particules.Speed = NumberRange.new(2, 4)
			particules.LightEmission = 1
			particules.Parent = torche

			torche.Parent = model
		end
	end

	-- Estrade du boss (au fond)
	local estrade = part({
		Name = "EstradeBoss",
		Size = Vector3.new(40, 3, 40),
		Position = origine + Vector3.new(0, 1.5, -TAILLE_ARENE * 0.32),
		Material = Enum.Material.Basalt,
		Color = couleurTheme:Lerp(Color3.new(0, 0, 0), 0.6),
	})
	estrade.Parent = model

	-- Points d'apparition des monstres (répartis dans l'arène)
	local pointsSpawn = {}
	for i = 1, 10 do
		local angle = (i / 10) * math.pi * 2
		local rayon = TAILLE_ARENE * 0.28
		table.insert(pointsSpawn, origine + Vector3.new(math.cos(angle) * rayon, 3, math.sin(angle) * rayon * 0.7 - 10))
	end

	model.Parent = workspace

	return {
		Model = model,
		SpawnJoueur = origine + Vector3.new(0, 5, TAILLE_ARENE * 0.4),
		PointsSpawnMonstres = pointsSpawn,
		PositionBoss = estrade.Position + Vector3.new(0, 5, 0),
	}
end

return DungeonBuilder
