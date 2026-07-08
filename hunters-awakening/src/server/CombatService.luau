--!strict
-- Combat côté serveur (autoritaire, anti-triche) :
-- validation des compétences (classe, cooldown, mana, portée), calcul des dégâts,
-- attaque de base, buffs temporaires, défense.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local CombatService = {}

local Services: any = nil
local vfx = Remotes.Event("VFX")
local cooldownEvent = Remotes.Event("CooldownDebute")

-- Cooldowns par joueur : { [Player] = { [skillId] = timestampFin } }
local cooldowns: { [Player]: { [string]: number } } = {}
-- Buffs actifs : { [Player] = { Degats = {Mult, Fin}, Defense = {Mult, Fin} } }
local buffs: { [Player]: { [string]: { Mult: number, Fin: number } } } = {}

local ATTAQUE_BASE_COOLDOWN = 0.6
local ATTAQUE_BASE_PORTEE = 12

----------------------------------------------------------------
-- CALCULS
----------------------------------------------------------------

local function multiplicateurBuff(player: Player, type_: string): number
	local buffsJoueur = buffs[player]
	if buffsJoueur and buffsJoueur[type_] and os.clock() < buffsJoueur[type_].Fin then
		return buffsJoueur[type_].Mult
	end
	return 1
end

-- Fraction de dégâts réduite par la défense (0 à 0,75).
function CombatService.DefenseDe(player: Player): number
	local profil = Services.DataService.Get(player)
	if not profil then
		return 0
	end
	local stats = Services.ProgressionService.StatsTotales(profil)
	local _, defenseEquipement = Services.ProgressionService.BonusEquipement(profil)
	local defense = (stats.Endurance * 0.5 + defenseEquipement) * multiplicateurBuff(player, "Defense")
	return math.min(defense / (defense + 100), 0.75)
end

local function calculerDegats(player: Player, profil: any, competence: any): (number, boolean)
	local stats = Services.ProgressionService.StatsTotales(profil)
	local degatsArme = Services.ProgressionService.BonusEquipement(profil)

	local base = (competence.Degats or 0) + degatsArme * 0.5
	if competence.StatScaling and competence.Ratio then
		base += (stats[competence.StatScaling] or 0) * competence.Ratio
	end
	base *= multiplicateurBuff(player, "Degats")

	-- Critique
	local chanceCrit = GameConfig.ChanceCritique(stats.Agilite, stats.Chance)
	local critique = math.random() < chanceCrit
	if critique then
		base *= 1.75
	end

	return math.max(math.floor(base), 1), critique
end

local function positionJoueur(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return hrp, humanoid
end

----------------------------------------------------------------
-- APPLICATION DES COMPÉTENCES
----------------------------------------------------------------

local function appliquerCompetence(player: Player, profil: any, competence: any, pointVise: Vector3)
	local hrp, humanoid = positionJoueur(player)
	if not hrp or not humanoid then
		return
	end

	local origine = hrp.Position
	local direction = (pointVise - origine)
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.1 then
		direction = hrp.CFrame.LookVector
	else
		direction = direction.Unit
	end

	if competence.Type == "Melee" then
		local degats, critique = calculerDegats(player, profil, competence)
		for _, monstre in Services.MonsterService.DansRayon(origine, competence.Portee) do
			local posMonstre = (monstre.Model.PrimaryPart :: BasePart).Position
			local versMonstre = (posMonstre - origine)
			versMonstre = Vector3.new(versMonstre.X, 0, versMonstre.Z)
			-- Arc de ~120° devant le joueur
			if versMonstre.Magnitude < 2 or direction:Dot(versMonstre.Unit) > 0.5 then
				Services.MonsterService.Infliger(monstre, degats, player, critique)
			end
		end
		vfx:FireAllClients("Slash", { Origine = origine, Direction = direction, Couleur = competence.Couleur, Portee = competence.Portee })

	elseif competence.Type == "Projectile" then
		local degats, critique = calculerDegats(player, profil, competence)
		local cible = origine + direction * competence.Portee
		vfx:FireAllClients("Projectile", { Origine = origine + Vector3.new(0, 1, 0), Cible = cible, Couleur = competence.Couleur })
		-- Simulation serveur : le projectile avance et touche le premier monstre sur la trajectoire
		task.spawn(function()
			local vitesse = 90
			local pas = 3
			local distance = 0
			local position = origine
			while distance < competence.Portee do
				position += direction * pas
				distance += pas
				local touches = Services.MonsterService.DansRayon(position, 4)
				if #touches > 0 then
					Services.MonsterService.Infliger(touches[1], degats, player, critique)
					return
				end
				task.wait(pas / vitesse)
			end
		end)

	elseif competence.Type == "Zone" then
		local degats, critique = calculerDegats(player, profil, competence)
		local centre
		if (competence.Portee or 0) <= 0 then
			centre = origine -- zone centrée sur le joueur
		else
			local distance = math.min((pointVise - origine).Magnitude, competence.Portee)
			centre = origine + direction * distance
		end
		vfx:FireAllClients("Zone", { Centre = centre, Rayon = competence.Rayon, Couleur = competence.Couleur })
		task.delay(0.25, function()
			for _, monstre in Services.MonsterService.DansRayon(centre, competence.Rayon) do
				Services.MonsterService.Infliger(monstre, degats, player, critique)
			end
		end)

	elseif competence.Type == "Buff" then
		buffs[player] = buffs[player] or {}
		buffs[player][competence.BuffStat] = { Mult = competence.BuffMult, Fin = os.clock() + competence.Duree }
		vfx:FireAllClients("Buff", { Joueur = player, Couleur = competence.Couleur, Duree = competence.Duree })

	elseif competence.Type == "Soin" then
		local stats = Services.ProgressionService.StatsTotales(profil)
		local soin = (competence.Soin or 0) + (stats[competence.StatScaling or "Intelligence"] or 0) * (competence.Ratio or 1)
		humanoid.Health = math.min(humanoid.Health + soin, humanoid.MaxHealth)
		vfx:FireAllClients("Soin", { Joueur = player, Couleur = competence.Couleur })

	elseif competence.Type == "Dash" then
		-- Propulsion vers l'avant (le serveur applique la vélocité)
		hrp.AssemblyLinearVelocity = direction * 120 + Vector3.new(0, 20, 0)
		vfx:FireAllClients("Dash", { Joueur = player, Couleur = competence.Couleur })
	end
end

----------------------------------------------------------------
-- INIT / REMOTES
----------------------------------------------------------------

function CombatService.Init(services: any)
	Services = services

	-- Compétence de classe (index 1 à 4)
	Remotes.Event("LancerCompetence").OnServerEvent:Connect(function(player, index, pointVise)
		if typeof(index) ~= "number" or typeof(pointVise) ~= "Vector3" then
			return
		end
		local profil = Services.DataService.Get(player)
		if not profil or not profil.Classe then
			return
		end
		local classe = ClassConfig.ParId[profil.Classe]
		local competence = classe and classe.Competences[index]
		if not competence then
			return
		end

		-- Anti-triche : cooldown et mana vérifiés côté serveur
		cooldowns[player] = cooldowns[player] or {}
		if os.clock() < (cooldowns[player][competence.Id] or 0) then
			return
		end
		local mana = player:GetAttribute("Mana") or 0
		if mana < competence.Mana then
			return
		end

		local stats = Services.ProgressionService.StatsTotales(profil)
		local reduction = GameConfig.ReductionRecharge(stats.Agilite)
		local cooldownReel = competence.Cooldown * (1 - reduction)

		cooldowns[player][competence.Id] = os.clock() + cooldownReel
		player:SetAttribute("Mana", mana - competence.Mana)
		cooldownEvent:FireClient(player, index, cooldownReel)

		appliquerCompetence(player, profil, competence, pointVise)
	end)

	-- Attaque de base (clic gauche)
	Remotes.Event("AttaqueBase").OnServerEvent:Connect(function(player, pointVise)
		if typeof(pointVise) ~= "Vector3" then
			return
		end
		local profil = Services.DataService.Get(player)
		if not profil then
			return
		end
		cooldowns[player] = cooldowns[player] or {}
		if os.clock() < (cooldowns[player]["__base"] or 0) then
			return
		end
		cooldowns[player]["__base"] = os.clock() + ATTAQUE_BASE_COOLDOWN

		local hrp = positionJoueur(player)
		if not hrp then
			return
		end
		local stats = Services.ProgressionService.StatsTotales(profil)
		local degatsArme = Services.ProgressionService.BonusEquipement(profil)
		local degats = math.max(math.floor((5 + degatsArme + stats.Force * 0.8) * multiplicateurBuff(player, "Degats")), 1)
		local critique = math.random() < GameConfig.ChanceCritique(stats.Agilite, stats.Chance)
		if critique then
			degats = math.floor(degats * 1.75)
		end

		local origine = hrp.Position
		local direction = (pointVise - origine)
		direction = Vector3.new(direction.X, 0, direction.Z)
		direction = direction.Magnitude > 0.1 and direction.Unit or hrp.CFrame.LookVector

		local plusProche = nil
		local distanceMin = ATTAQUE_BASE_PORTEE
		for _, monstre in Services.MonsterService.DansRayon(origine, ATTAQUE_BASE_PORTEE) do
			local posMonstre = (monstre.Model.PrimaryPart :: BasePart).Position
			local distance = (posMonstre - origine).Magnitude
			if distance < distanceMin then
				distanceMin = distance
				plusProche = monstre
			end
		end
		if plusProche then
			Services.MonsterService.Infliger(plusProche, degats, player, critique)
		end
		vfx:FireAllClients("Slash", { Origine = origine, Direction = direction, Couleur = Color3.fromRGB(220, 220, 220), Portee = ATTAQUE_BASE_PORTEE * 0.8 })
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
		buffs[player] = nil
	end)
end

return CombatService
