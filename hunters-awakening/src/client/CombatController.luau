--!strict
-- Contrôles de combat : clic gauche = attaque de base, touches 1-4 = compétences.
-- Le serveur reste autoritaire ; ici on ne fait qu'envoyer les intentions.

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local CombatController = {}

local joueur = Players.LocalPlayer

function CombatController.Init(controllers: any)
	local ClientState = controllers.ClientState
	local souris = joueur:GetMouse()

	local lancerCompetence = Remotes.Event("LancerCompetence")
	local attaqueBase = Remotes.Event("AttaqueBase")

	local function pointVise(): Vector3
		local hit = souris.Hit
		if hit then
			return hit.Position
		end
		local character = joueur.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		return hrp and (hrp.Position + hrp.CFrame.LookVector * 20) or Vector3.zero
	end

	local function utiliserCompetence(index: number)
		lancerCompetence:FireServer(index, pointVise())
	end

	-- Clavier : 1-4 pour les compétences
	UserInputService.InputBegan:Connect(function(input, traite)
		if traite then
			return
		end
		if input.KeyCode == Enum.KeyCode.One then
			utiliserCompetence(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			utiliserCompetence(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			utiliserCompetence(3)
		elseif input.KeyCode == Enum.KeyCode.Four then
			utiliserCompetence(4)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			attaqueBase:FireServer(pointVise())
		end
	end)

	-- Boutons du HUD (utile sur mobile)
	ClientState.CompetenceDemandee.Event:Connect(function(index: number)
		utiliserCompetence(index)
	end)
end

return CombatController
