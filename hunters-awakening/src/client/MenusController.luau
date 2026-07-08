--!strict
-- Menus du jeu : Stats (C), Inventaire (I), Guilde (G), Passe de combat (P).
-- Un seul menu ouvert à la fois ; ouverture par touche ou par les boutons du HUD.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ItemConfig = require(Shared:WaitForChild("ItemConfig"))
local BattlePassConfig = require(Shared:WaitForChild("BattlePassConfig"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local UI = require(Shared:WaitForChild("UI"))

local MenusController = {}

local joueur = Players.LocalPlayer
local ClientState: any = nil

local ecran: ScreenGui
local menus: { [string]: Frame } = {}
local rafraichisseurs: { [string]: () -> () } = {}

----------------------------------------------------------------
-- CADRE DE BASE D'UN MENU
----------------------------------------------------------------

local function creerMenu(nom: string, titre: string, largeur: number, hauteur: number): Frame
	local menu = UI.new("Frame", {
		Name = "Menu" .. nom,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(largeur, hauteur),
		BackgroundColor3 = UI.Couleurs.Fond,
		Visible = false,
		Parent = ecran,
	}, { UI.coin(16), UI.marge(14), UI.contour(UI.Couleurs.Accent, 2, 0.4) })

	UI.texte({
		Size = UDim2.new(1, 0, 0, 30),
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titre,
		Parent = menu,
	})

	local fermer = UI.bouton({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = UI.Couleurs.Danger,
		Text = "✕",
		Parent = menu,
	})
	fermer.Activated:Connect(function()
		menu.Visible = false
	end)

	menus[nom] = menu
	return menu
end

local function basculerMenu(nom: string)
	for autreNom, menu in menus do
		if autreNom ~= nom then
			menu.Visible = false
		end
	end
	local menu = menus[nom]
	if menu then
		menu.Visible = not menu.Visible
		if menu.Visible and rafraichisseurs[nom] then
			rafraichisseurs[nom]()
		end
	end
end

----------------------------------------------------------------
-- MENU STATS
----------------------------------------------------------------

local function construireMenuStats()
	local menu = creerMenu("Stats", "📊 Statistiques", 420, 430)

	local labelPoints = UI.texte({
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 22),
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = UI.Couleurs.XP,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Points disponibles : 0",
		Parent = menu,
	})

	local liste = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 64),
		Size = UDim2.new(1, 0, 1, -100),
		BackgroundTransparency = 1,
		Parent = menu,
	}, { UI.listeVerticale(6) })

	local lignes: { [string]: TextLabel } = {}
	for i, stat in GameConfig.Stats do
		local ligne = UI.new("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = UI.Couleurs.FondClair,
			LayoutOrder = i,
			Parent = liste,
		}, { UI.coin(10), UI.marge(8) })

		UI.texte({
			Size = UDim2.new(0.55, 0, 0, 16),
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = stat.Icone .. " " .. stat.Nom,
			Parent = ligne,
		})
		UI.texte({
			Position = UDim2.fromOffset(0, 16),
			Size = UDim2.new(0.9, 0, 0, 12),
			TextSize = 9,
			TextColor3 = UI.Couleurs.TexteSecondaire,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = stat.Description,
			Parent = ligne,
		})

		local valeur = UI.texte({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -40, 0.5, 0),
			Size = UDim2.fromOffset(50, 20),
			Font = Enum.Font.GothamBlack,
			TextSize = 16,
			Text = "5",
			Parent = ligne,
		})
		lignes[stat.Id] = valeur

		local plus = UI.bouton({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			Text = "+",
			TextSize = 18,
			Parent = ligne,
		})
		local statId = stat.Id
		plus.Activated:Connect(function()
			Remotes.Event("RepartirPoint"):FireServer(statId)
		end)
	end

	local labelDerives = UI.texte({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = 12,
		TextColor3 = UI.Couleurs.TexteSecondaire,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = menu,
	})

	rafraichisseurs.Stats = function()
		local profil = ClientState.Profil
		if not profil then
			return
		end
		labelPoints.Text = "Points disponibles : " .. profil.PointsDeStats
		for statId, label in lignes do
			label.Text = tostring(profil.Stats[statId] or 0)
		end
		labelDerives.Text = string.format(
			"❤️ Vie max : %d    🔷 Mana max : %d    👟 Vitesse : %.1f",
			GameConfig.VieMax(profil.Niveau, profil.Stats.Endurance),
			GameConfig.ManaMax(profil.Niveau, profil.Stats.Intelligence),
			GameConfig.VitesseMarche(profil.Stats.Vitesse)
		)
	end
end

----------------------------------------------------------------
-- MENU INVENTAIRE
----------------------------------------------------------------

local function construireMenuInventaire()
	local menu = creerMenu("Inventaire", "🎒 Inventaire", 520, 460)

	local defilement = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = menu,
	}, { UI.listeVerticale(6) })

	rafraichisseurs.Inventaire = function()
		local profil = ClientState.Profil
		if not profil then
			return
		end
		for _, enfant in defilement:GetChildren() do
			if enfant:IsA("Frame") then
				enfant:Destroy()
			end
		end

		if #profil.Inventaire == 0 then
			UI.texte({
				Size = UDim2.new(1, 0, 0, 40),
				TextColor3 = UI.Couleurs.TexteSecondaire,
				Text = "Inventaire vide — terminez des donjons pour trouver du butin !",
				Parent = defilement,
			})
			return
		end

		for i, objet in profil.Inventaire do
			local rarete = ItemConfig.RareteParId[objet.Rarete]
			local equipe = profil.Equipement[objet.Slot] == objet.UUID

			local ligne = UI.new("Frame", {
				Size = UDim2.new(1, -8, 0, 56),
				BackgroundColor3 = UI.Couleurs.FondClair,
				LayoutOrder = i,
				Parent = defilement,
			}, { UI.coin(10), UI.marge(8), UI.contour(rarete.Couleur, 2, equipe and 0 or 0.6) })

			UI.texte({
				Size = UDim2.new(0.6, 0, 0, 18),
				Font = Enum.Font.GothamBold,
				TextSize = 13,
				TextColor3 = rarete.Couleur,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = (equipe and "✅ " or "") .. objet.Nom,
				Parent = ligne,
			})

			local detailsTexte = rarete.Nom .. " • Rang " .. objet.Rang
			if objet.Degats then
				detailsTexte ..= " • ⚔️ " .. objet.Degats
			end
			if objet.Defense then
				detailsTexte ..= " • 🛡️ " .. objet.Defense
			end
			for statId, bonus in objet.Bonus or {} do
				detailsTexte ..= " • +" .. bonus .. " " .. statId
			end
			UI.texte({
				Position = UDim2.fromOffset(0, 20),
				Size = UDim2.new(0.65, 0, 0, 14),
				TextSize = 10,
				TextColor3 = UI.Couleurs.TexteSecondaire,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = detailsTexte,
				Parent = ligne,
			})

			local boutonEquiper = UI.bouton({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -72, 0.5, 0),
				Size = UDim2.fromOffset(84, 28),
				TextSize = 11,
				Text = equipe and "Retirer" or "Équiper",
				Parent = ligne,
			})
			local boutonVendre = UI.bouton({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(64, 28),
				BackgroundColor3 = UI.Couleurs.Danger,
				TextSize = 11,
				Text = "Vendre",
				Parent = ligne,
			})

			local uuid = objet.UUID
			boutonEquiper.Activated:Connect(function()
				Remotes.Event("EquiperObjet"):FireServer(uuid)
			end)
			boutonVendre.Activated:Connect(function()
				Remotes.Event("VendreObjet"):FireServer(uuid)
			end)
		end
	end
end

----------------------------------------------------------------
-- MENU GUILDE
----------------------------------------------------------------

local function construireMenuGuilde()
	local menu = creerMenu("Guilde", "🏰 Guilde", 520, 480)

	local contenu = UI.new("Frame", {
		Position = UDim2.fromOffset(0, 40),
		Size = UDim2.new(1, 0, 1, -44),
		BackgroundTransparency = 1,
		Parent = menu,
	})

	rafraichisseurs.Guilde = function()
		local profil = ClientState.Profil
		if not profil then
			return
		end
		for _, enfant in contenu:GetChildren() do
			enfant:Destroy()
		end

		if not profil.GuildeId then
			-- ===== PAS DE GUILDE : créer ou rejoindre =====
			UI.texte({
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "Créer une guilde (" .. Util.FormatNombre(GameConfig.Guildes.CoutCreation) .. " 🪙)",
				Parent = contenu,
			})

			local champNom = UI.new("TextBox", {
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, -110, 0, 34),
				BackgroundColor3 = UI.Couleurs.FondClair,
				Font = Enum.Font.Gotham,
				TextColor3 = UI.Couleurs.Texte,
				PlaceholderText = "Nom de la guilde…",
				Text = "",
				TextSize = 14,
				ClearTextOnFocus = false,
				Parent = contenu,
			}, { UI.coin(8), UI.marge(6) })

			local boutonCreer = UI.bouton({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 26),
				Size = UDim2.fromOffset(100, 34),
				Text = "Créer",
				Parent = contenu,
			})
			boutonCreer.Activated:Connect(function()
				if #champNom.Text >= 3 then
					Remotes.Event("CreerGuilde"):FireServer(champNom.Text)
				end
			end)

			UI.texte({
				Position = UDim2.fromOffset(0, 72),
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = "Guildes existantes",
				Parent = contenu,
			})

			local listeGuildes = UI.new("ScrollingFrame", {
				Position = UDim2.fromOffset(0, 96),
				Size = UDim2.new(1, 0, 1, -96),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				Parent = contenu,
			}, { UI.listeVerticale(6) })

			task.spawn(function()
				local guildes = Remotes.Function("ListeGuildes"):InvokeServer()
				if typeof(guildes) ~= "table" then
					return
				end
				if #guildes == 0 then
					UI.texte({
						Size = UDim2.new(1, 0, 0, 30),
						TextColor3 = UI.Couleurs.TexteSecondaire,
						Text = "Aucune guilde pour l'instant. Créez la première !",
						Parent = listeGuildes,
					})
				end
				for i, guilde in guildes do
					local ligne = UI.new("Frame", {
						Size = UDim2.new(1, -8, 0, 44),
						BackgroundColor3 = UI.Couleurs.FondClair,
						LayoutOrder = i,
						Parent = listeGuildes,
					}, { UI.coin(10), UI.marge(8) })

					UI.texte({
						Size = UDim2.new(0.7, 0, 0, 16),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = (guilde.QG and "🏰 " or "") .. guilde.Nom,
						Parent = ligne,
					})
					UI.texte({
						Position = UDim2.fromOffset(0, 16),
						Size = UDim2.new(0.7, 0, 0, 12),
						TextSize = 10,
						TextColor3 = UI.Couleurs.TexteSecondaire,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "Chef : " .. guilde.ChefNom .. " • " .. guilde.NbMembres .. "/" .. GameConfig.Guildes.MembresMax .. " membres",
						Parent = ligne,
					})
					local rejoindre = UI.bouton({
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.fromOffset(90, 26),
						TextSize = 11,
						Text = "Rejoindre",
						Parent = ligne,
					})
					local guildeId = guilde.Id
					rejoindre.Activated:Connect(function()
						Remotes.Event("RejoindreGuilde"):FireServer(guildeId)
					end)
				end
			end)
		else
			-- ===== MEMBRE D'UNE GUILDE =====
			task.spawn(function()
				local guilde = Remotes.Function("MaGuilde"):InvokeServer()
				if not guilde then
					return
				end

				UI.texte({
					Size = UDim2.new(1, 0, 0, 26),
					Font = Enum.Font.GothamBlack,
					TextSize = 20,
					TextColor3 = UI.Couleurs.Accent,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = (guilde.QG and "🏰 " or "") .. guilde.Nom,
					Parent = contenu,
				})
				UI.texte({
					Position = UDim2.fromOffset(0, 28),
					Size = UDim2.new(1, 0, 0, 16),
					TextSize = 12,
					TextColor3 = UI.Couleurs.TexteSecondaire,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = "Chef : " .. guilde.ChefNom .. " • " .. guilde.NbMembres .. "/" .. GameConfig.Guildes.MembresMax .. " membres",
					Parent = contenu,
				})

				-- QG
				if not guilde.QG then
					UI.texte({
						Position = UDim2.fromOffset(0, 56),
						Size = UDim2.new(1, 0, 0, 18),
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "Débloquer le QG de guilde (réservé au chef) :",
						Parent = contenu,
					})
					local boutonOr = UI.bouton({
						Position = UDim2.fromOffset(0, 80),
						Size = UDim2.fromOffset(210, 34),
						Text = "🪙 " .. Util.FormatNombre(GameConfig.Guildes.CoutQGOr) .. " Or",
						Parent = contenu,
					})
					boutonOr.Activated:Connect(function()
						Remotes.Event("AcheterQGOr"):FireServer()
					end)
					local boutonRobux = UI.bouton({
						Position = UDim2.fromOffset(220, 80),
						Size = UDim2.fromOffset(210, 34),
						BackgroundColor3 = Color3.fromRGB(70, 180, 120),
						Text = "💵 Acheter en Robux",
						Parent = contenu,
					})
					boutonRobux.Activated:Connect(function()
						Remotes.Event("DemanderAchat"):FireServer("Produit", GameConfig.Monetisation.ProduitQGGuildeId)
					end)
				else
					UI.texte({
						Position = UDim2.fromOffset(0, 56),
						Size = UDim2.new(1, 0, 0, 18),
						TextColor3 = Color3.fromRGB(120, 255, 160),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "✅ Cette guilde possède un QG dans la ville !",
						Parent = contenu,
					})
				end

				-- Membres
				UI.texte({
					Position = UDim2.fromOffset(0, 126),
					Size = UDim2.new(1, 0, 0, 18),
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = "Membres",
					Parent = contenu,
				})
				local listeMembres = UI.new("ScrollingFrame", {
					Position = UDim2.fromOffset(0, 148),
					Size = UDim2.new(1, 0, 1, -196),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 6,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					Parent = contenu,
				}, { UI.listeVerticale(4) })
				for _, nomMembre in guilde.Membres do
					UI.texte({
						Size = UDim2.new(1, 0, 0, 20),
						TextXAlignment = Enum.TextXAlignment.Left,
						Text = "• " .. nomMembre,
						Parent = listeMembres,
					})
				end

				-- Quitter
				local quitter = UI.bouton({
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.fromOffset(160, 32),
					BackgroundColor3 = UI.Couleurs.Danger,
					Text = "Quitter la guilde",
					Parent = contenu,
				})
				quitter.Activated:Connect(function()
					Remotes.Event("QuitterGuilde"):FireServer()
					menu.Visible = false
				end)
			end)
		end
	end
end

----------------------------------------------------------------
-- MENU PASSE DE COMBAT
----------------------------------------------------------------

local function construireMenuPasse()
	local menu = creerMenu("Passe", "🎖️ " .. BattlePassConfig.NomSaison, 640, 480)

	local labelProgression = UI.texte({
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.GothamBold,
		TextColor3 = UI.Couleurs.XP,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
		Parent = menu,
	})

	local boutonPremium = UI.bouton({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -40, 0, 32),
		Size = UDim2.fromOffset(200, 28),
		BackgroundColor3 = Color3.fromRGB(255, 170, 50),
		TextSize = 12,
		Text = "⭐ Débloquer le passe premium",
		Parent = menu,
	})
	boutonPremium.Activated:Connect(function()
		Remotes.Event("DemanderAchat"):FireServer("Passe", GameConfig.Monetisation.PassePremiumId)
	end)

	local defilement = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = menu,
	}, { UI.listeVerticale(6) })

	local function texteRecompense(recompense: any): string
		if recompense.Type == "Or" then
			return "🪙 " .. Util.FormatNombre(recompense.Montant)
		elseif recompense.Type == "Cristaux" then
			return "💎 " .. recompense.Montant
		elseif recompense.Type == "Objet" then
			return "🗡️ " .. (ItemConfig.RareteParId[recompense.Rarete].Nom) .. " (Rang " .. recompense.Rang .. ")"
		elseif recompense.Type == "Titre" then
			return "🏅 Titre : " .. recompense.Titre
		end
		return "?"
	end

	rafraichisseurs.Passe = function()
		local profil = ClientState.Profil
		if not profil then
			return
		end
		local passe = profil.PasseDeCombat
		local palierAtteint = math.min(math.floor(passe.XP / BattlePassConfig.XPParPalier), BattlePassConfig.NbPaliers)
		labelProgression.Text = "Palier " .. palierAtteint .. " / " .. BattlePassConfig.NbPaliers
			.. "  •  " .. Util.FormatNombre(passe.XP) .. " XP de passe"

		for _, enfant in defilement:GetChildren() do
			if enfant:IsA("Frame") then
				enfant:Destroy()
			end
		end

		for i, palier in BattlePassConfig.Paliers do
			local atteint = palierAtteint >= i
			local ligne = UI.new("Frame", {
				Size = UDim2.new(1, -8, 0, 52),
				BackgroundColor3 = UI.Couleurs.FondClair,
				BackgroundTransparency = atteint and 0 or 0.5,
				LayoutOrder = i,
				Parent = defilement,
			}, { UI.coin(10), UI.marge(8) })

			UI.texte({
				Size = UDim2.fromOffset(60, 36),
				Font = Enum.Font.GothamBlack,
				TextSize = 18,
				TextColor3 = atteint and UI.Couleurs.XP or UI.Couleurs.TexteSecondaire,
				Text = tostring(i),
				Parent = ligne,
			})

			for colonne, piste in { "Gratuit", "Premium" } do
				local cle = piste .. "_" .. i
				local reclame = passe.Reclames[cle] == true
				local x = 70 + (colonne - 1) * 260

				UI.texte({
					Position = UDim2.fromOffset(x, 0),
					Size = UDim2.fromOffset(160, 16),
					TextSize = 10,
					TextColor3 = piste == "Premium" and Color3.fromRGB(255, 190, 90) or UI.Couleurs.TexteSecondaire,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = piste == "Premium" and "⭐ PREMIUM" or "GRATUIT",
					Parent = ligne,
				})
				UI.texte({
					Position = UDim2.fromOffset(x, 16),
					Size = UDim2.fromOffset(160, 18),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					Text = texteRecompense(palier[piste]),
					Parent = ligne,
				})

				local bouton = UI.bouton({
					Position = UDim2.fromOffset(x + 170, 8),
					Size = UDim2.fromOffset(74, 24),
					TextSize = 10,
					BackgroundColor3 = reclame and Color3.fromRGB(70, 70, 90) or (atteint and Color3.fromRGB(70, 180, 120) or UI.Couleurs.FondClair),
					Text = reclame and "✅ Pris" or "Réclamer",
					Parent = ligne,
				})
				if not reclame and atteint then
					local numeroPalier = i
					local pisteChoisie = piste
					bouton.Activated:Connect(function()
						Remotes.Event("ReclamerPalier"):FireServer(numeroPalier, pisteChoisie)
					end)
				end
			end
		end
	end
end

----------------------------------------------------------------
-- INIT
----------------------------------------------------------------

function MenusController.Init(controllers: any)
	ClientState = controllers.ClientState

	ecran = UI.new("ScreenGui", {
		Name = "Menus",
		ResetOnSpawn = false,
		Parent = joueur:WaitForChild("PlayerGui"),
	})

	construireMenuStats()
	construireMenuInventaire()
	construireMenuGuilde()
	construireMenuPasse()

	-- Raccourcis clavier
	UserInputService.InputBegan:Connect(function(input, traite)
		if traite then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			basculerMenu("Stats")
		elseif input.KeyCode == Enum.KeyCode.I then
			basculerMenu("Inventaire")
		elseif input.KeyCode == Enum.KeyCode.G then
			basculerMenu("Guilde")
		elseif input.KeyCode == Enum.KeyCode.P then
			basculerMenu("Passe")
		end
	end)

	-- Boutons du HUD
	ClientState.BasculerMenu.Event:Connect(basculerMenu)

	-- Rafraîchit le menu ouvert quand le profil change
	ClientState.ProfilChange.Event:Connect(function()
		for nom, menu in menus do
			if menu.Visible and rafraichisseurs[nom] then
				rafraichisseurs[nom]()
			end
		end
	end)
end

return MenusController
