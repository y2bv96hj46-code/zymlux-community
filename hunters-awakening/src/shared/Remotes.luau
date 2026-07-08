--!strict
-- Petit utilitaire pour créer / récupérer les RemoteEvents et RemoteFunctions.
-- Côté serveur : crée l'instance si elle n'existe pas.
-- Côté client : attend qu'elle existe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local DOSSIER_NOM = "Remotes"

local function getDossier(): Folder
	if RunService:IsServer() then
		local dossier = ReplicatedStorage:FindFirstChild(DOSSIER_NOM)
		if not dossier then
			dossier = Instance.new("Folder")
			dossier.Name = DOSSIER_NOM
			dossier.Parent = ReplicatedStorage
		end
		return dossier :: Folder
	else
		return ReplicatedStorage:WaitForChild(DOSSIER_NOM) :: Folder
	end
end

function Remotes.Event(nom: string): RemoteEvent
	local dossier = getDossier()
	if RunService:IsServer() then
		local remote = dossier:FindFirstChild(nom)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = nom
			remote.Parent = dossier
		end
		return remote :: RemoteEvent
	else
		return dossier:WaitForChild(nom) :: RemoteEvent
	end
end

function Remotes.Function(nom: string): RemoteFunction
	local dossier = getDossier()
	if RunService:IsServer() then
		local remote = dossier:FindFirstChild(nom)
		if not remote then
			remote = Instance.new("RemoteFunction")
			remote.Name = nom
			remote.Parent = dossier
		end
		return remote :: RemoteFunction
	else
		return dossier:WaitForChild(nom) :: RemoteFunction
	end
end

return Remotes
