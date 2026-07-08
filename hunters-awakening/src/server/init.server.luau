--!strict
-- Point d'entrée serveur : démarre tous les services dans le bon ordre
-- puis construit la ville.

print("========================================")
print("  L'ÉVEIL DES CHASSEURS — Serveur")
print("========================================")

local Services: { [string]: any } = {}

-- Ordre de chargement : les données d'abord, le monde à la fin.
local ordre = {
	"DataService",
	"MonetizationService",
	"ProgressionService",
	"LootService",
	"MonsterService",
	"CombatService",
	"BattlePassService",
	"GuildService",
	"DungeonService",
}

for _, nom in ordre do
	Services[nom] = require(script:WaitForChild(nom) :: ModuleScript)
end

for _, nom in ordre do
	local ok, err = pcall(function()
		Services[nom].Init(Services)
	end)
	if ok then
		print("[Serveur] ✅ " .. nom .. " démarré")
	else
		warn("[Serveur] ❌ " .. nom .. " a échoué : " .. tostring(err))
	end
end

-- Construction de la ville, puis transmission des points de portails au DungeonService
local CityBuilder = require(script:WaitForChild("CityBuilder"))
local infosVille = CityBuilder.Construire()
Services.DungeonService.DefinirPointsApparition(infosVille.PointsPortails, infosVille.SpawnVille)

print("[Serveur] 🏰 Ville construite, " .. #infosVille.PointsPortails .. " points de portails actifs")
