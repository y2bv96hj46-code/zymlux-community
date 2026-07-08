--!strict
-- Fonctions utilitaires partagées.

local HttpService = game:GetService("HttpService")

local Util = {}

-- Formate un nombre : 1532 -> "1,5k", 2400000 -> "2,4M"
function Util.FormatNombre(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.1fMd", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.1fM", n / 1_000_000)
	elseif n >= 10_000 then
		return string.format("%.1fk", n / 1_000)
	end
	return tostring(math.floor(n))
end

-- Choix pondéré dans une liste d'éléments possédant un champ de poids.
function Util.ChoixPondere<T>(liste: { T }, champPoids: string): T
	local total = 0
	for _, element in liste do
		total += (element :: any)[champPoids]
	end
	local tirage = math.random() * total
	local cumul = 0
	for _, element in liste do
		cumul += (element :: any)[champPoids]
		if tirage <= cumul then
			return element
		end
	end
	return liste[#liste]
end

function Util.UUID(): string
	return HttpService:GenerateGUID(false)
end

-- Copie profonde d'une table (pour les profils par défaut)
function Util.CopieProfonde(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local copie = {}
	for cle, valeur in t do
		copie[cle] = Util.CopieProfonde(valeur)
	end
	return copie
end

-- Complète les champs manquants d'un profil avec les valeurs par défaut
-- (utile quand on ajoute de nouveaux champs après la sortie du jeu).
function Util.Reconcilier(profil: any, defaut: any)
	for cle, valeur in defaut do
		if profil[cle] == nil then
			profil[cle] = Util.CopieProfonde(valeur)
		elseif type(valeur) == "table" and type(profil[cle]) == "table" then
			Util.Reconcilier(profil[cle], valeur)
		end
	end
end

function Util.FormatTemps(secondes: number): string
	local minutes = math.floor(secondes / 60)
	local reste = math.floor(secondes % 60)
	return string.format("%d:%02d", minutes, reste)
end

return Util
