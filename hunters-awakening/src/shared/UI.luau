--!strict
-- Mini-bibliothèque pour construire l'interface en code, de façon concise.
-- UI.new("Frame", { Size = ..., Parent = ... }, { enfants... })

local UI = {}

function UI.new(className: string, props: { [string]: any }?, enfants: { Instance }?): any
	local instance = Instance.new(className)
	local parent: Instance? = nil
	if props then
		for cle, valeur in props do
			if cle == "Parent" then
				parent = valeur
			else
				(instance :: any)[cle] = valeur
			end
		end
	end
	if enfants then
		for _, enfant in enfants do
			enfant.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function UI.coin(rayon: number): UICorner
	return UI.new("UICorner", { CornerRadius = UDim.new(0, rayon) })
end

function UI.contour(couleur: Color3, epaisseur: number?, transparence: number?): UIStroke
	return UI.new("UIStroke", {
		Color = couleur,
		Thickness = epaisseur or 1,
		Transparency = transparence or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.marge(pixels: number): UIPadding
	local p = UDim.new(0, pixels)
	return UI.new("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

function UI.listeVerticale(espace: number): UIListLayout
	return UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, espace),
	})
end

function UI.listeHorizontale(espace: number): UIListLayout
	return UI.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, espace),
	})
end

-- Style par défaut du jeu
UI.Couleurs = {
	Fond = Color3.fromRGB(18, 16, 28),
	FondClair = Color3.fromRGB(30, 27, 45),
	Accent = Color3.fromRGB(120, 90, 255),
	Texte = Color3.fromRGB(235, 232, 245),
	TexteSecondaire = Color3.fromRGB(160, 155, 180),
	Vie = Color3.fromRGB(90, 220, 120),
	Mana = Color3.fromRGB(90, 140, 255),
	XP = Color3.fromRGB(255, 200, 80),
	Danger = Color3.fromRGB(255, 80, 80),
}

function UI.texte(props: { [string]: any }): TextLabel
	local defauts = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextColor3 = UI.Couleurs.Texte,
		TextSize = 14,
	}
	for cle, valeur in defauts do
		if props[cle] == nil then
			props[cle] = valeur
		end
	end
	return UI.new("TextLabel", props)
end

function UI.bouton(props: { [string]: any }): TextButton
	local defauts = {
		BackgroundColor3 = UI.Couleurs.Accent,
		Font = Enum.Font.GothamBold,
		TextColor3 = UI.Couleurs.Texte,
		TextSize = 14,
		AutoButtonColor = true,
		BorderSizePixel = 0,
	}
	for cle, valeur in defauts do
		if props[cle] == nil then
			props[cle] = valeur
		end
	end
	local bouton = UI.new("TextButton", props)
	UI.coin(8).Parent = bouton
	return bouton
end

return UI
