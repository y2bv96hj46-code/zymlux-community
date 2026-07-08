--!strict
-- État partagé côté client : le profil du joueur (répliqué par le serveur)
-- et quelques signaux internes entre contrôleurs.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local ClientState = {
	Profil = nil :: any,
	ProfilChange = Instance.new("BindableEvent"),
	-- Fired quand un bouton de compétence du HUD est cliqué (mobile/souris)
	CompetenceDemandee = Instance.new("BindableEvent"),
	-- Fired pour ouvrir/fermer un menu depuis le HUD : "Stats" | "Inventaire" | "Guilde" | "Passe"
	BasculerMenu = Instance.new("BindableEvent"),
}

Remotes.Event("ProfilMisAJour").OnClientEvent:Connect(function(profil)
	ClientState.Profil = profil
	ClientState.ProfilChange:Fire(profil)
end)

return ClientState
