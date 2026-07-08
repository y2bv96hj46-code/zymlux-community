--!strict
-- HUD principal : barres de vie/mana/XP, rang, monnaies, barre de compétences,
-- notifications, HUD de donjon et écran de choix de classe.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ClassConfig = require(Shared:WaitForChild("ClassConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local UI = require(Shared:WaitForChild("UI"))

local UIController = {}

local joueur = Players.LocalPlayer
local ClientState: any = nil

local ecran: ScreenGui
local barreVie: Frame
local barreMana: Frame
local barreXP: Frame
local labelVie: TextLabel
local labelMana: TextLabel
local labelNiveau: TextLabel
local labelXP: TextLabel
local badgeRang: TextLabel
local labelOr: TextLabel
local labelCristaux: TextLabel
local casesCompetences: { Frame } = {}
local hudDonjon: Frame
local panneauClasse: Frame? = nil

----------------------------------------------------------------
-- CONSTRUCTION DU HUD
----------------------------------------------------------------

local function construireBarreStatut(parent: Instance)
	local conteneur = UI.new("Frame", {
		Name = "Statut",
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(280, 108),
		BackgroundColor3 = UI.Couleurs.Fond,
		BackgroundTransparency = 0.25,
		Parent = parent,
	}, { UI.coin(12), UI.marge(10) })

	badgeRang = UI.texte({
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 0,
		BackgroundColor3 = UI.Couleurs.FondClair,
		Font = Enum.Font.GothamBlack,
		TextSize = 24,
		Text = "E",
		Parent = conteneur,
	})
	UI.coin(10).Parent = badgeRang

	labelNiveau = UI.texte({
		Position = UDim2.fromOffset(54, 0),
		Size = UDim2.fromOffset(200, 20),
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Niveau 1",
		Parent = conteneur,
	})

	local function creerBarre(y: number, couleur: Color3): (Frame, TextLabel)
		local fond = UI.new("Frame", {
			Position = UDim2.fromOffset(54, y),
			Size = UDim2.new(1, -60, 0, 14),
			BackgroundColor3 = Color3.fromRGB(15, 13, 22),
			Parent = conteneur,
		}, { UI.coin(7) })
		local remplissage = UI.new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = couleur,
			Parent = fond,
		}, { UI.coin(7) })
		local label = UI.texte({
			Size = UDim2.fromScale(1, 1),
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			Text = "",
			Parent = fond,
		})
		return remplissage, label
	end

	barreVie, labelVie = creerBarre(24, UI.Couleurs.Vie)
	barreMana, labelMana = creerBarre(42, UI.Couleurs.Mana)
	barreXP, labelXP = creerBarre(60, UI.Couleurs.XP)

	labelXP.TextSize = 9
end

local function construireMonnaies(parent: Instance)
	local conteneur = UI.new("Frame", {
		Name = "Monnaies",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(170, 64),
		BackgroundColor3 = UI.Couleurs.Fond,
		BackgroundTransparency = 0.25,
		Parent = parent,
	}, { UI.coin(12), UI.marge(8), UI.listeVerticale(4) })

	labelOr = UI.texte({
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(255, 210, 90),
		Text = "🪙 0",
		Parent = conteneur,
	})
	labelCristaux = UI.texte({
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(130, 220, 255),
		Text = "💎 0",
		Parent = conteneur,
	})
end

local function construireBarreCompetences(parent: Instance)
	local conteneur = UI.new("Frame", {
		Name = "Competences",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(4 * 68 + 3 * 8, 68),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { UI.listeHorizontale(8) })

	for i = 1, 4 do
		local case = UI.new("Frame", {
			Name = "Competence" .. i,
			Size = UDim2.fromOffset(68, 68),
			BackgroundColor3 = UI.Couleurs.Fond,
			BackgroundTransparency = 0.2,
			LayoutOrder = i,
			Parent = conteneur,
		}, { UI.coin(10), UI.contour(UI.Couleurs.Accent, 1, 0.5) })

		UI.texte({
			Name = "Touche",
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(20, 14),
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = UI.Couleurs.TexteSecondaire,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = tostring(i),
			Parent = case,
		})

		UI.texte({
			Name = "Nom",
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.new(1, -4, 0, 30),
			TextSize = 10,
			TextWrapped = true,
			Text = "—",
			Parent = case,
		})

		-- Overlay de cooldown
		local overlay = UI.new("Frame", {
			Name = "Cooldown",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.4,
			Parent = case,
		}, { UI.coin(10) })
		overlay.ZIndex = 3

		-- Clique = utiliser la compétence (mobile)
		local bouton = UI.new("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = case,
		})
		bouton.ZIndex = 4
		local index = i
		bouton.Activated:Connect(function()
			ClientState.CompetenceDemandee:Fire(index)
		end)

		casesCompetences[i] = case
	end
end

local function construireBoutonsMenus(parent: Instance)
	local conteneur = UI.new("Frame", {
		Name = "BoutonsMenus",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -14),
		Size = UDim2.fromOffset(76, 4 * 40 + 3 * 6),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { UI.listeVerticale(6) })

	for i, info in {
		{ "Stats", "📊 C" },
		{ "Inventaire", "🎒 I" },
		{ "Guilde", "🏰 G" },
		{ "Passe", "🎖️ P" },
	} do
		local bouton = UI.bouton({
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = UI.Couleurs.FondClair,
			TextSize = 13,
			Text = info[2],
			LayoutOrder = i,
			Parent = conteneur,
		})
		local nomMenu = info[1]
		bouton.Activated:Connect(function()
			ClientState.BasculerMenu:Fire(nomMenu)
		end)
	end
end

local function construireHudDonjon(parent: Instance)
	hudDonjon = UI.new("Frame", {
		Name = "HudDonjon",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 16),
		Size = UDim2.fromOffset(340, 64),
		BackgroundColor3 = UI.Couleurs.Fond,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = parent,
	}, { UI.coin(12), UI.marge(8) })

	UI.texte({
		Name = "Titre",
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		Text = "DONJON RANG E",
		Parent = hudDonjon,
	})
	UI.texte({
		Name = "Detail",
		Position = UDim2.fromOffset(0, 24),
		Size = UDim2.new(1, 0, 0, 20),
		TextSize = 13,
		TextColor3 = UI.Couleurs.TexteSecondaire,
		Text = "",
		Parent = hudDonjon,
	})
end

----------------------------------------------------------------
-- NOTIFICATIONS (toasts)
----------------------------------------------------------------

local pileNotifications: Frame

local function construireNotifications(parent: Instance)
	pileNotifications = UI.new("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.fromOffset(380, 300),
		BackgroundTransparency = 1,
		Parent = parent,
	}, { UI.listeVerticale(6) })
end

local function afficherNotification(donnees: any)
	local toast = UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 54),
		BackgroundColor3 = UI.Couleurs.Fond,
		BackgroundTransparency = 0.1,
		Parent = pileNotifications,
	}, { UI.coin(10), UI.marge(8), UI.contour(donnees.Couleur or UI.Couleurs.Accent, 2, 0.2) })

	UI.texte({
		Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextColor3 = donnees.Couleur or UI.Couleurs.Texte,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = donnees.Titre or "",
		Parent = toast,
	})
	UI.texte({
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 12,
		TextColor3 = UI.Couleurs.TexteSecondaire,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = donnees.Message or "",
		Parent = toast,
	})

	task.delay(4, function()
		local tween = TweenService:Create(toast, TweenInfo.new(0.4), { BackgroundTransparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		toast:Destroy()
	end)
end

----------------------------------------------------------------
-- CHOIX DE CLASSE
----------------------------------------------------------------

local function afficherChoixClasse()
	if panneauClasse then
		return
	end
	panneauClasse = UI.new("Frame", {
		Name = "ChoixClasse",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(8, 6, 14),
		BackgroundTransparency = 0.15,
		Parent = ecran,
	})
	local panneau = panneauClasse :: Frame

	UI.texte({
		Position = UDim2.new(0.5, 0, 0, 60),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(600, 40),
		Font = Enum.Font.GothamBlack,
		TextSize = 30,
		Text = "⚔️ CHOISISSEZ VOTRE CLASSE ⚔️",
		Parent = panneau,
	})
	UI.texte({
		Position = UDim2.new(0.5, 0, 0, 102),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(600, 20),
		TextSize = 14,
		TextColor3 = UI.Couleurs.TexteSecondaire,
		Text = "Ce choix est définitif. Chaque classe a 4 compétences uniques.",
		Parent = panneau,
	})

	local grille = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.55, 0),
		Size = UDim2.fromOffset(3 * 220 + 2 * 16, 2 * 200 + 16),
		BackgroundTransparency = 1,
		Parent = panneau,
	})
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(220, 200),
		CellPadding = UDim2.fromOffset(16, 16),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grille,
	})

	for i, classe in ClassConfig.Classes do
		local carte = UI.new("Frame", {
			BackgroundColor3 = UI.Couleurs.Fond,
			LayoutOrder = i,
			Parent = grille,
		}, { UI.coin(14), UI.marge(12), UI.contour(classe.Couleur, 2, 0.2) })

		UI.texte({
			Size = UDim2.new(1, 0, 0, 40),
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = classe.Couleur,
			Text = classe.Icone .. " " .. classe.Nom,
			Parent = carte,
		})
		UI.texte({
			Position = UDim2.fromOffset(0, 42),
			Size = UDim2.new(1, 0, 0, 60),
			TextSize = 12,
			TextWrapped = true,
			TextColor3 = UI.Couleurs.TexteSecondaire,
			Text = classe.Description,
			Parent = carte,
		})
		UI.texte({
			Position = UDim2.fromOffset(0, 104),
			Size = UDim2.new(1, 0, 0, 16),
			TextSize = 11,
			TextColor3 = UI.Couleurs.TexteSecondaire,
			Text = "Stat principale : " .. classe.StatPrincipale,
			Parent = carte,
		})

		local bouton = UI.bouton({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = classe.Couleur,
			Text = "CHOISIR",
			Parent = carte,
		})
		local classeId = classe.Id
		bouton.Activated:Connect(function()
			Remotes.Event("ChoisirClasse"):FireServer(classeId)
			if panneauClasse then
				panneauClasse:Destroy()
				panneauClasse = nil
			end
		end)
	end
end

----------------------------------------------------------------
-- MISE À JOUR DU HUD
----------------------------------------------------------------

local function rafraichirProfil(profil: any)
	labelNiveau.Text = "Niveau " .. profil.Niveau .. (profil.Titre and ("  " .. profil.Titre) or "")
	labelOr.Text = "🪙 " .. Util.FormatNombre(profil.Or)
	labelCristaux.Text = "💎 " .. Util.FormatNombre(profil.Cristaux)

	local rang = GameConfig.Rangs[GameConfig.IndexRang[profil.RangChasseur]]
	badgeRang.Text = profil.RangChasseur
	badgeRang.TextColor3 = rang.Couleur

	local xpRequis = GameConfig.XPPourNiveau(profil.Niveau)
	barreXP.Size = UDim2.fromScale(math.clamp(profil.XP / xpRequis, 0, 1), 1)
	labelXP.Text = Util.FormatNombre(profil.XP) .. " / " .. Util.FormatNombre(xpRequis) .. " XP"

	-- Barre de compétences selon la classe
	if profil.Classe then
		local classe = ClassConfig.ParId[profil.Classe]
		for i, case in casesCompetences do
			local competence = classe.Competences[i]
			local nomLabel = case:FindFirstChild("Nom") :: TextLabel
			if competence then
				nomLabel.Text = competence.Nom
				local contour = case:FindFirstChildOfClass("UIStroke")
				if contour then
					contour.Color = competence.Couleur
				end
			end
		end
	elseif profil.Niveau >= GameConfig.NiveauChoixClasse then
		afficherChoixClasse()
	end
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

function UIController.Init(controllers: any)
	ClientState = controllers.ClientState

	ecran = UI.new("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		Parent = joueur:WaitForChild("PlayerGui"),
	})

	construireBarreStatut(ecran)
	construireMonnaies(ecran)
	construireBarreCompetences(ecran)
	construireBoutonsMenus(ecran)
	construireHudDonjon(ecran)
	construireNotifications(ecran)

	-- Vie / mana en continu
	RunService.RenderStepped:Connect(function()
		local character = joueur.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local fraction = humanoid.Health / math.max(humanoid.MaxHealth, 1)
			barreVie.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
			labelVie.Text = math.floor(humanoid.Health) .. " / " .. math.floor(humanoid.MaxHealth)
		end
		local mana = joueur:GetAttribute("Mana") or 0
		local manaMax = joueur:GetAttribute("ManaMax") or 50
		barreMana.Size = UDim2.fromScale(math.clamp(mana / math.max(manaMax, 1), 0, 1), 1)
		labelMana.Text = math.floor(mana) .. " / " .. math.floor(manaMax)
	end)

	-- Profil répliqué
	ClientState.ProfilChange.Event:Connect(rafraichirProfil)
	if ClientState.Profil then
		rafraichirProfil(ClientState.Profil)
	end

	-- Notifications serveur
	Remotes.Event("Notification").OnClientEvent:Connect(afficherNotification)

	-- Cooldowns des compétences
	Remotes.Event("CooldownDebute").OnClientEvent:Connect(function(index: number, duree: number)
		local case = casesCompetences[index]
		if not case then
			return
		end
		local overlay = case:FindFirstChild("Cooldown") :: Frame
		overlay.Size = UDim2.fromScale(1, 1)
		TweenService:Create(overlay, TweenInfo.new(duree, Enum.EasingStyle.Linear), {
			Size = UDim2.fromScale(1, 0),
		}):Play()
	end)

	-- HUD donjon
	Remotes.Event("EtatDonjon").OnClientEvent:Connect(function(etat: any?)
		if etat == nil then
			hudDonjon.Visible = false
			return
		end
		hudDonjon.Visible = true
		local rang = GameConfig.Rangs[GameConfig.IndexRang[etat.Rang]]
		local titre = hudDonjon:FindFirstChild("Titre") :: TextLabel
		local detail = hudDonjon:FindFirstChild("Detail") :: TextLabel
		titre.Text = "DONJON RANG " .. etat.Rang .. "  •  ⏱ " .. Util.FormatTemps(etat.TempsRestant)
		titre.TextColor3 = rang.Couleur
		detail.Text = etat.Texte
	end)
end

return UIController
