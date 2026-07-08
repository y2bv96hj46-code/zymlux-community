--!strict
-- Effets visuels côté client : slashs, projectiles, zones, buffs, soins,
-- morts de monstres, level up, et nombres de dégâts flottants.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local EffectsController = {}

local function partieEffet(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.CastShadow = false
	for cle, valeur in props do
		(p :: any)[cle] = valeur
	end
	p.Parent = workspace
	return p
end

local function positionDe(player: Player): Vector3?
	local character = player and player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return hrp and hrp.Position or nil
end

----------------------------------------------------------------
-- EFFETS
----------------------------------------------------------------

local effets: { [string]: (donnees: any) -> () } = {}

effets.Slash = function(donnees)
	local arc = partieEffet({
		Size = Vector3.new(donnees.Portee * 1.4, 0.4, 2),
		Color = donnees.Couleur,
		Transparency = 0.2,
		CFrame = CFrame.lookAt(donnees.Origine + Vector3.new(0, 1.5, 0), donnees.Origine + donnees.Direction * 10)
			* CFrame.new(0, 0, -donnees.Portee / 2),
	})
	TweenService:Create(arc, TweenInfo.new(0.25), {
		Transparency = 1,
		Size = arc.Size + Vector3.new(2, 0, 4),
	}):Play()
	Debris:AddItem(arc, 0.3)
end

effets.Projectile = function(donnees)
	local distance = (donnees.Cible - donnees.Origine).Magnitude
	local projectile = partieEffet({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Color = donnees.Couleur,
		CFrame = CFrame.new(donnees.Origine),
	})
	local trainee = Instance.new("Trail")
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0.5, 0)
	a0.Parent = projectile
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -0.5, 0)
	a1.Parent = projectile
	trainee.Attachment0 = a0
	trainee.Attachment1 = a1
	trainee.Color = ColorSequence.new(donnees.Couleur)
	trainee.LightEmission = 1
	trainee.Lifetime = 0.25
	trainee.Parent = projectile

	local duree = distance / 90
	TweenService:Create(projectile, TweenInfo.new(duree, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(donnees.Cible),
	}):Play()
	Debris:AddItem(projectile, duree + 0.3)
end

effets.Zone = function(donnees)
	local anneau = partieEffet({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 1, 1),
		Color = donnees.Couleur,
		Transparency = 0.15,
		CFrame = CFrame.new(donnees.Centre) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(anneau, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.4, donnees.Rayon * 2, donnees.Rayon * 2),
		Transparency = 1,
	}):Play()
	Debris:AddItem(anneau, 0.6)
end

effets.Buff = function(donnees)
	local position = positionDe(donnees.Joueur)
	if not position then
		return
	end
	local aura = partieEffet({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 8, 8),
		Color = donnees.Couleur,
		Transparency = 0.5,
		CFrame = CFrame.new(position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(aura, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	Debris:AddItem(aura, 1)
end

effets.Soin = function(donnees)
	local position = positionDe(donnees.Joueur)
	if not position then
		return
	end
	for _ = 1, 6 do
		local etincelle = partieEffet({
			Size = Vector3.new(0.5, 0.5, 0.5),
			Color = donnees.Couleur,
			CFrame = CFrame.new(position + Vector3.new(math.random(-2, 2), math.random(-1, 1), math.random(-2, 2))),
		})
		TweenService:Create(etincelle, TweenInfo.new(0.7), {
			CFrame = etincelle.CFrame + Vector3.new(0, 5, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(etincelle, 0.8)
	end
end

effets.Dash = function(donnees)
	local position = positionDe(donnees.Joueur)
	if not position then
		return
	end
	local trainee = partieEffet({
		Size = Vector3.new(1, 1, 6),
		Color = donnees.Couleur,
		Transparency = 0.4,
		CFrame = CFrame.new(position),
	})
	TweenService:Create(trainee, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	Debris:AddItem(trainee, 0.5)
end

effets.LevelUp = function(donnees)
	local position = positionDe(donnees.Joueur)
	if not position then
		return
	end
	local colonne = partieEffet({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(14, 3, 3),
		Color = Color3.fromRGB(255, 210, 90),
		Transparency = 0.3,
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(colonne, TweenInfo.new(1), {
		Size = Vector3.new(20, 10, 10),
		Transparency = 1,
	}):Play()
	Debris:AddItem(colonne, 1.2)
end

effets.MortMonstre = function(donnees)
	for _ = 1, 8 do
		local fragment = partieEffet({
			Size = Vector3.new(0.7, 0.7, 0.7),
			Color = donnees.Couleur,
			CFrame = CFrame.new(donnees.Position),
		})
		local direction = Vector3.new(math.random(-10, 10), math.random(5, 14), math.random(-10, 10)) / 4
		TweenService:Create(fragment, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(donnees.Position + direction),
			Transparency = 1,
			Size = Vector3.new(0.1, 0.1, 0.1),
		}):Play()
		Debris:AddItem(fragment, 0.8)
	end
end

effets.AttaqueMonstre = function(donnees)
	local flash = partieEffet({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		Color = Color3.fromRGB(255, 80, 60),
		Transparency = 0.5,
		CFrame = CFrame.new(donnees.Position),
	})
	TweenService:Create(flash, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(4, 4, 4) }):Play()
	Debris:AddItem(flash, 0.3)
end

effets.PortalEnter = function(_donnees) end

----------------------------------------------------------------
-- NOMBRES DE DÉGÂTS FLOTTANTS
----------------------------------------------------------------

local function afficherDegats(position: Vector3, montant: number, critique: boolean)
	local ancre = partieEffet({
		Size = Vector3.new(0.1, 0.1, 0.1),
		Transparency = 1,
		CFrame = CFrame.new(position + Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)),
	})

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(100, 40)
	billboard.AlwaysOnTop = true
	billboard.Adornee = ancre
	billboard.Parent = ancre

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = critique and 26 or 18
	label.TextColor3 = critique and Color3.fromRGB(255, 90, 60) or Color3.fromRGB(255, 230, 120)
	label.TextStrokeTransparency = 0.4
	label.Text = (critique and "💥 " or "") .. tostring(montant)
	label.Parent = billboard

	TweenService:Create(ancre, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = ancre.CFrame + Vector3.new(0, 4, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(ancre, 0.9)
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

function EffectsController.Init(_controllers: any)
	Remotes.Event("VFX").OnClientEvent:Connect(function(nom: string, donnees: any)
		local effet = effets[nom]
		if effet then
			task.spawn(effet, donnees)
		end
	end)

	Remotes.Event("DegatsInfliges").OnClientEvent:Connect(function(position: Vector3, montant: number, critique: boolean)
		-- Limite la distance d'affichage pour ne pas polluer l'écran
		local camera = workspace.CurrentCamera
		if camera and (camera.CFrame.Position - position).Magnitude < 250 then
			afficherDegats(position, montant, critique)
		end
	end)
end

return EffectsController
