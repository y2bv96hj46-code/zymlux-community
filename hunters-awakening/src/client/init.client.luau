--!strict
-- Point d'entrée client : démarre tous les contrôleurs.

local Controllers: { [string]: any } = {}

Controllers.ClientState = require(script:WaitForChild("ClientState"))

local ordre = {
	"UIController",
	"MenusController",
	"CombatController",
	"EffectsController",
}

for _, nom in ordre do
	Controllers[nom] = require(script:WaitForChild(nom) :: ModuleScript)
end

for _, nom in ordre do
	local ok, err = pcall(function()
		Controllers[nom].Init(Controllers)
	end)
	if not ok then
		warn("[Client] ❌ " .. nom .. " a échoué : " .. tostring(err))
	end
end

print("[Client] ✅ L'Éveil des Chasseurs — interface chargée")
