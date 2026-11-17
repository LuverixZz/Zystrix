if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local env = (getgenv and getgenv()) or _G
if env.__MystrixUI then
	pcall(function() env.__MystrixUI:Unload() end)
end
if env.__ZystrixUI then
	pcall(function() env.__ZystrixUI:Unload() end)
end

local BASE_W, BASE_H = 640, 400
local HEADER_H, SIDEBAR_W, SEC_H = 46, 150, 40
local CTRL_BTN, CTRL_SLOT = 36, 42
local CTRL_W = CTRL_SLOT * 3
local TITLE_X = 54
local TOG_SIZE = 40
local FONT, FONT_BOLD = Enum.Font.GothamMedium, Enum.Font.GothamBold
local ROOT = "ZystrixUI"

local HasFS = (writefile and readfile and isfile and isfolder and makefolder) and true or false

local AutoY, AutoX, AutoNone = Enum.AutomaticSize.Y, Enum.AutomaticSize.X, Enum.AutomaticSize.None

local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local USE_CANVAS_HIT = false
local HIT_W = 120
local TAP_SLOP = 18
local onClick
local DRAG_SLOP = IS_TOUCH and 16 or 6

local Themes = {
	Monochrome = {
		Background = Color3.fromRGB(10, 10, 10), Sidebar = Color3.fromRGB(15, 15, 15),
		Card = Color3.fromRGB(21, 21, 21), Element = Color3.fromRGB(28, 28, 28),
		Hover = Color3.fromRGB(38, 38, 38), Stroke = Color3.fromRGB(46, 46, 46),
		Text = Color3.fromRGB(245, 245, 245), SubText = Color3.fromRGB(140, 140, 140),
		Accent = Color3.fromRGB(236, 236, 236), AccentText = Color3.fromRGB(10, 10, 10),
	},
	Crimson = {
		Background = Color3.fromRGB(14, 9, 9), Sidebar = Color3.fromRGB(19, 12, 12),
		Card = Color3.fromRGB(26, 17, 17), Element = Color3.fromRGB(34, 23, 23),
		Hover = Color3.fromRGB(46, 32, 32), Stroke = Color3.fromRGB(60, 41, 41),
		Text = Color3.fromRGB(246, 240, 240), SubText = Color3.fromRGB(155, 132, 132),
		Accent = Color3.fromRGB(214, 40, 57), AccentText = Color3.fromRGB(255, 255, 255),
	},
	Ocean = {
		Background = Color3.fromRGB(8, 12, 18), Sidebar = Color3.fromRGB(11, 16, 24),
		Card = Color3.fromRGB(16, 23, 34), Element = Color3.fromRGB(22, 31, 45),
		Hover = Color3.fromRGB(30, 42, 60), Stroke = Color3.fromRGB(38, 52, 74),
		Text = Color3.fromRGB(238, 244, 252), SubText = Color3.fromRGB(128, 146, 170),
		Accent = Color3.fromRGB(59, 130, 246), AccentText = Color3.fromRGB(255, 255, 255),
	},
	Emerald = {
		Background = Color3.fromRGB(8, 13, 11), Sidebar = Color3.fromRGB(11, 18, 15),
		Card = Color3.fromRGB(16, 25, 21), Element = Color3.fromRGB(22, 34, 29),
		Hover = Color3.fromRGB(30, 46, 39), Stroke = Color3.fromRGB(39, 60, 51),
		Text = Color3.fromRGB(238, 248, 243), SubText = Color3.fromRGB(128, 160, 145),
		Accent = Color3.fromRGB(16, 185, 129), AccentText = Color3.fromRGB(4, 20, 14),
	},
	Violet = {
		Background = Color3.fromRGB(12, 9, 18), Sidebar = Color3.fromRGB(16, 12, 25),
		Card = Color3.fromRGB(23, 18, 36), Element = Color3.fromRGB(31, 25, 48),
		Hover = Color3.fromRGB(42, 34, 64), Stroke = Color3.fromRGB(55, 45, 82),
		Text = Color3.fromRGB(243, 240, 252), SubText = Color3.fromRGB(145, 135, 170),
		Accent = Color3.fromRGB(139, 92, 246), AccentText = Color3.fromRGB(255, 255, 255),
	},
	Amber = {
		Background = Color3.fromRGB(15, 12, 8), Sidebar = Color3.fromRGB(20, 16, 10),
		Card = Color3.fromRGB(28, 22, 14), Element = Color3.fromRGB(37, 30, 19),
		Hover = Color3.fromRGB(50, 40, 25), Stroke = Color3.fromRGB(66, 53, 33),
		Text = Color3.fromRGB(250, 245, 236), SubText = Color3.fromRGB(165, 148, 120),
		Accent = Color3.fromRGB(245, 158, 11), AccentText = Color3.fromRGB(24, 14, 0),
	},
}

local Theme = {}
for k, v in pairs(Themes.Monochrome) do Theme[k] = v end

local Library = {
	Flags = {}, Options = {}, Connections = {}, Windows = {},
	Version = "2.0.0", ThemeName = "Monochrome",
	ThemeList = { "Monochrome", "Crimson", "Ocean", "Emerald", "Violet", "Amber" },
	Transparency = 0, ConfigFolder = ROOT, Listening = false,
	Effects = true,
}

local SliderLock = { Active = nil }

local Bound, Hooks, TransFrames = {}, {}, {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	local sink = Library._sink
	if sink then
		sink[#sink + 1] = c
	else
		Library.Connections[#Library.Connections + 1] = c
	end
	return c
end

local function tween(obj, props, time, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function bind(obj, prop, key)
	obj[prop] = Theme[key]
	Bound[#Bound + 1] = { obj, prop, key }
end

local function prune()
	for i = #Bound, 1, -1 do
		if not Bound[i][1].Parent then table.remove(Bound, i) end
	end
end

local function new(class, props)
	props = props or {}
	local o = Instance.new(class)
	local isGui = o:IsA("GuiObject")
	if isGui then o.BorderSizePixel = 0 end
	if o:IsA("TextButton") or o:IsA("ImageButton") then o.AutoButtonColor = false end
	if o:IsA("TextButton") then o.Text = "" end
	if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
		o.Font = FONT
		o.TextSize = 13
		o.TextXAlignment = Enum.TextXAlignment.Left
	end
	if o:IsA("TextBox") then
		o.ClearTextOnFocus = false
		pcall(function() o.ShowNativeInput = false end)
	end
	if isGui and props.Bg == nil and props.BackgroundColor3 == nil and props.BackgroundTransparency == nil then
		o.BackgroundTransparency = 1
	end
	local parent
	for k, v in pairs(props) do
		if k == "Parent" then parent = v
		elseif k == "Bg" then bind(o, "BackgroundColor3", v)
		elseif k == "Fg" then bind(o, "TextColor3", v)
		elseif k == "Img" then bind(o, "ImageColor3", v)
		elseif k == "Sb" then bind(o, "ScrollBarImageColor3", v)
		elseif k == "Ph" then bind(o, "PlaceholderColor3", v)
		elseif k == "Stk" then bind(o, "Color", v)
		else o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end

local function corner(p, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = p })
end

local function round(p)
	return new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = p })
end

local function hitZone(parent, props)
	props = props or {}
	local zone = new(USE_CANVAS_HIT and "CanvasGroup" or "Frame", {
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0), Position = props.Position or UDim2.new(),
		Size = props.Size or UDim2.fromScale(1, 1), LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1, Parent = parent,
	})
	local btn = new("TextButton", { Size = UDim2.fromScale(1, 1), Parent = zone })
	return btn, zone
end

local function stroke(p, key, thick)
	return new("UIStroke", { Stk = key or "Stroke", Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end

local function padding(p, l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or 0), Parent = p,
	})
end

local function listLayout(p, pad, dir)
	return new("UIListLayout", {
		Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = dir or Enum.FillDirection.Vertical, Parent = p,
	})
end

local function gradient(p, dark, rot)
	local d = dark or 190
	return new("UIGradient", {
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(d, d, d)),
		Rotation = rot or 90, Parent = p,
	})
end

local function applyTheme(name, instant)
	local t = Themes[name]
	if not t then return end
	prune()
	for k, v in pairs(t) do Theme[k] = v end
	Library.ThemeName = name
	for _, b in ipairs(Bound) do
		local o, prop, key = b[1], b[2], b[3]
		if instant then
			pcall(function() o[prop] = Theme[key] end)
		else
			pcall(tween, o, { [prop] = Theme[key] }, 0.35)
		end
	end
	for _, h in ipairs(Hooks) do pcall(h, instant) end
end

local function ensureFolder(path)
	if HasFS and not isfolder(path) then pcall(makefolder, path) end
end

local function httpGet(url)
	local req = (syn and syn.request) or (http and http.request) or http_request or request
	if req then
		local ok, res = pcall(req, { Url = url, Method = "GET" })
		if ok and res and (res.StatusCode == 200 or res.Success) and res.Body then return res.Body end
	end
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok then return body end
	return nil
end

local Icons = {
	crown = { "rbxassetid://127843403295538", "*" },
	home = { "rbxassetid://98755624629571", "H" },
	main = { "rbxassetid://72664649203050", "M" },
	farm = { "rbxassetid://138133190015277", "~" },
	settings = { "rbxassetid://80758916183665", "S" },
	search = { "rbxassetid://121018724060431", "?" },
	close = { "rbxassetid://110786993356448", "x" },
	minimize = { "rbxassetid://118026365011536", "-" },
	maximize = { "rbxassetid://76045941763188", "+" },
	chevron = { "rbxassetid://134243273101015", "v" },
	palette = { "rbxassetid://86350350950064", "P" },
	keyboard = { "rbxassetid://121474456068237", "K" },
	save = { "rbxassetid://126116963775616", "S" },
	refresh = { "rbxassetid://138133190015277", "R" },
	folder = { "rbxassetid://76018996254888", "F" },
	trash = { "rbxassetid://109843431391323", "X" },
	user = { "rbxassetid://81589895647169", "U" },
	key = { "rbxassetid://83619031955390", "K" },
	info = { "rbxassetid://124560466474914", "i" },
	link = { "rbxassetid://131607023382430", "@" },
	bike = { "rbxassetid://102930322246035", "B" },
	eye = { "rbxassetid://100033680381365", "o" },
	globe = { "rbxassetid://114238209622913", "O" },
	toggle = { "rbxassetid://90411952142550", "T" },
	slider = { "rbxassetid://85538382643347", "=" },
	list = { "rbxassetid://113179976918783", "-" },
	input = { "rbxassetid://107551944047171", "I" },
	click = { "rbxassetid://107150227368485", "o" },
	grid = { "rbxassetid://81344910161871", "#" },
	columns = { "rbxassetid://113004100221850", "|" },
	pulse = { "rbxassetid://94212016861936", "~" },
	signal = { "rbxassetid://78424889355261", "l" },
	contrast = { "rbxassetid://112796643981497", "o" },
	edit = { "rbxassetid://137986121120732", "/" },
	hash = { "rbxassetid://82890331678520", "#" },
	up = { "rbxassetid://89282378235317", "^" },
	down = { "rbxassetid://98764963621439", "v" },
	sun = { "rbxassetid://110150589884127", "*" },
	percent = { "rbxassetid://130155041032013", "%" },
	bolt = { "rbxassetid://130551565616516", "!" },
	check = { "rbxassetid://93898873302694", "+" },
	clock = { "rbxassetid://121808839832144", "o" },
	plus = { "rbxassetid://111774323017047", "+" },
	server = { "rbxassetid://92188766517878", "=" },
	users = { "rbxassetid://115398113982385", "U" },
	chat = { "rbxassetid://83881670383280", "C" },
	cpu = { "rbxassetid://77549309870247", "#" },
	copy = { "rbxassetid://78979572434545", "c" },
	shield = { "rbxassetid://87354736164608", "S" },
	hop = { "rbxassetid://132382786975101", ">" },
}
Library.Icons = Icons

local IconCache, Pending = {}, {}

local function fetchAsset(source)
	if source:find("^rbxassetid://") or source:find("^rbxasset://") then return source end
	if tonumber(source) then return "rbxassetid://" .. source end
	return nil
end

local function loadIcon(spec, cb)
	if not spec or spec == "" then return end
	local entry = Icons[spec]
	local source = entry and entry[1] or spec
	if IconCache[source] then cb(IconCache[source]) return end
	if IconCache[source] == false then return end
	if Pending[source] then table.insert(Pending[source], cb) return end
	Pending[source] = { cb }
	task.spawn(function()
		local asset = fetchAsset(source)
		IconCache[source] = asset or false
		local list = Pending[source]
		Pending[source] = nil
		if asset then
			for _, f in ipairs(list) do pcall(f, asset) end
		end
	end)
end

function Library:RegisterIcon(name, source, glyph)
	Icons[name] = { source, glyph or "*" }
end

local function makeIcon(parent, spec, size, key, props)
	local p = { Size = UDim2.fromOffset(size, size), ImageTransparency = 1, ScaleType = Enum.ScaleType.Fit, Parent = parent }
	if props then for k, v in pairs(props) do p[k] = v end end
	local img = new("ImageLabel", p)
	local entry = Icons[spec or ""]
	local glyph = new("TextLabel", {
		Name = "Glyph", Size = UDim2.fromScale(1, 1), Text = entry and entry[2] or "*", Font = FONT_BOLD,
		TextSize = math.max(8, size - 4), TextXAlignment = Enum.TextXAlignment.Center, Parent = img,
	})
	if key then
		bind(img, "ImageColor3", key)
		bind(glyph, "TextColor3", key)
	else
		img.ImageColor3 = Theme.SubText
		glyph.TextColor3 = Theme.SubText
	end
	loadIcon(spec, function(asset)
		if img.Parent then
			img.Image = asset
			glyph.Visible = false
			tween(img, { ImageTransparency = 0 }, 0.3)
		end
	end)
	return img
end

local function tintIcon(img, color, t)
	tween(img, { ImageColor3 = color }, t or 0.2)
	local g = img:FindFirstChild("Glyph")
	if g then tween(g, { TextColor3 = color }, t or 0.2) end
end

local SHADOW_STEPS, SHADOW_STEP, SHADOW_ALPHA = 6, 4, 0.045

local function makeShadow(parent, radius, o)
	o = o or {}
	local steps = o.Steps or SHADOW_STEPS
	local step = o.Step or SHADOW_STEP
	local alpha = o.Alpha or SHADOW_ALPHA
	local dy = o.Offset or 0

	local holder = Instance.new("Frame")
	holder.Name = "Shadow"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Active = false
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.5, dy)
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 0
	holder.Parent = parent

	local layers = {}
	for i = steps, 1, -1 do
		local grow = i * step
		local layer = Instance.new("Frame")
		layer.Name = "Layer" .. i
		layer.BackgroundColor3 = Color3.new(0, 0, 0)
		layer.BackgroundTransparency = 1 - alpha
		layer.BorderSizePixel = 0
		layer.Active = false
		layer.AnchorPoint = Vector2.new(0.5, 0.5)
		layer.Position = UDim2.fromScale(0.5, 0.5)
		layer.Size = UDim2.new(1, grow * 2, 1, grow * 2)
		layer.ZIndex = 0
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius + grow)
		c.Parent = layer
		layer.Parent = holder
		layers[#layers + 1] = layer
	end

	local obj = { Holder = holder }
	function obj:Set(visible)
		for _, l in ipairs(layers) do
			l.BackgroundTransparency = visible and (1 - alpha) or 1
		end
	end
	function obj:Fade(visible, time, style)
		for _, l in ipairs(layers) do
			tween(l, { BackgroundTransparency = visible and (1 - alpha) or 1 }, time or 0.3, style or Enum.EasingStyle.Quad)
		end
	end
	return obj
end
local function iconTile(parent, spec, tile, size, props, static)
	local p = { Size = UDim2.fromOffset(tile, tile), Parent = parent }
	if static then p.BackgroundColor3 = Theme.Hover else p.Bg = "Hover" end
	if props then for k, v in pairs(props) do p[k] = v end end
	local box = new("Frame", p)
	corner(box, math.max(6, math.floor(tile * 0.3)))
	local st = stroke(box)
	gradient(box, 185)
	local img = makeIcon(box, spec, size, (not static) and "Accent" or nil, {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	})
	return box, img, st
end

local Gui = new("ScreenGui", {
	Name = "ZystrixUI_" .. HttpService:GenerateGUID(false):sub(1, 6), ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 1000,
})
if syn and syn.protect_gui then pcall(syn.protect_gui, Gui) end
local okParent = pcall(function() Gui.Parent = (gethui and gethui()) or CoreGui end)
if not okParent or not Gui.Parent then Gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
Library.Gui = Gui

local ScaleObj, MainFrame

local function getScale()
	if MainFrame and MainFrame.AbsoluteSize.X > 0 then
		return MainFrame.AbsoluteSize.X / BASE_W
	end
	return ScaleObj and ScaleObj.Scale or 1
end

local function closePopup()
	local c = Library.OpenPopup
	if c then Library.OpenPopup = nil c() end
end

local FX = {
	Assets = {
		glow = "rbxassetid://88172507927269",
		ring = "rbxassetid://130359823580534",
		spark = "rbxassetid://111044800239623",
		tick = "rbxassetid://93898873302694",
	},
	Ready = true, Active = 0, MAX = 40,
}
Library.FX = FX

function FX.whenReady(fn)
	pcall(fn)
end

local FxLayer = new("Frame", { Name = "Fx", Size = UDim2.fromScale(1, 1), ZIndex = 200, Parent = Gui })

local function uiScale(obj)
	local s, o = 1, obj
	while o and o ~= Gui do
		for _, c in ipairs(o:GetChildren()) do
			if c:IsA("UIScale") then s *= c.Scale end
		end
		o = o.Parent
	end
	return s
end

local function fxOn()
	return Library.Effects ~= false and FX.Active < FX.MAX
end

local function fxShape(name, parent)
	local asset = FX.Assets[name]
	local inst
	if asset then
		inst = Instance.new("ImageLabel")
		inst.Image = asset
		inst.ScaleType = Enum.ScaleType.Stretch
		inst.BackgroundTransparency = 1
	elseif name == "ring" then
		inst = Instance.new("Frame")
		inst.BackgroundTransparency = 1
		local st = Instance.new("UIStroke")
		st.Thickness = 2
		st.Parent = inst
		Instance.new("UICorner", inst).CornerRadius = UDim.new(1, 0)
	else
		inst = Instance.new("Frame")
		inst.BackgroundTransparency = 0
		Instance.new("UICorner", inst).CornerRadius = UDim.new(1, 0)
	end
	inst.BorderSizePixel = 0
	inst.AnchorPoint = Vector2.new(0.5, 0.5)
	inst.Active = false
	inst.Parent = parent
	return inst
end

local function fxSet(inst, v)
	if inst:IsA("ImageLabel") then
		inst.ImageTransparency = v
	else
		local st = inst:FindFirstChildOfClass("UIStroke")
		if st then st.Transparency = v else inst.BackgroundTransparency = v end
	end
end

local function fxFade(inst, v, time, style, dir)
	if inst:IsA("ImageLabel") then
		return tween(inst, { ImageTransparency = v }, time, style, dir)
	end
	local st = inst:FindFirstChildOfClass("UIStroke")
	if st then return tween(st, { Transparency = v }, time, style, dir) end
	return tween(inst, { BackgroundTransparency = v }, time, style, dir)
end

local function fxTint(inst, c)
	if inst:IsA("ImageLabel") then
		inst.ImageColor3 = c
	else
		local st = inst:FindFirstChildOfClass("UIStroke")
		if st then st.Color = c else inst.BackgroundColor3 = c end
	end
end

local function life(inst, t, layer)
	FX.Active += 1
	task.delay(t, function()
		FX.Active -= 1
		pcall(function() inst:Destroy() end)
		if layer and layer.Parent and layer.Name == "FxLayer" and #layer:GetChildren() <= 1 then
			layer.Visible = false
		end
	end)
end

local function layerOf(host, radius)
	local l = host:FindFirstChild("FxLayer")
	if not l then
		l = Instance.new("CanvasGroup")
		l.Name = "FxLayer"
		l.BackgroundTransparency = 1
		l.BorderSizePixel = 0
		l.Size = UDim2.fromScale(1, 1)
		l.ZIndex = 0
		l.Active = false
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius or 8)
		c.Parent = l
		l.Parent = host
	end
	l.Visible = true
	return l
end

function FX.ripple(host, pos, color, opts)
	if not fxOn() or not host or not host.Parent then return end
	opts = opts or {}
	local layer = host:IsA("CanvasGroup") and host or layerOf(host, opts.Radius or 8)
	local s = uiScale(layer)
	local ap, as = layer.AbsolutePosition, layer.AbsoluteSize
	if as.X <= 0 or as.Y <= 0 or s <= 0 then return end
	local w, h = as.X / s, as.Y / s
	local lx = pos and (pos.X - ap.X) / s or w / 2
	local ly = pos and (pos.Y - ap.Y) / s or h / 2
	lx, ly = math.clamp(lx, 0, w), math.clamp(ly, 0, h)
	local far = math.sqrt(math.max(lx, w - lx) ^ 2 + math.max(ly, h - ly) ^ 2)
	local d = math.max(far * 2.3, 24)
	local inst = fxShape("glow", layer)
	inst.ZIndex = 0
	inst.Position = UDim2.fromOffset(lx, ly)
	inst.Size = UDim2.fromOffset(d * 0.12, d * 0.12)
	fxTint(inst, color or Theme.Accent)
	fxSet(inst, opts.Alpha or 0.7)
	local t = opts.Time or 0.6
	life(inst, t + 0.05, layer)
	tween(inst, { Size = UDim2.fromOffset(d, d) }, t, Enum.EasingStyle.Quart)
	fxFade(inst, 1, t, Enum.EasingStyle.Quad)
end

function FX.shine(host, color, radius)
	if not fxOn() or not host or not host.Parent then return end
	local layer = host:IsA("CanvasGroup") and host or layerOf(host, radius or 8)
	local s = uiScale(layer)
	if s <= 0 or layer.AbsoluteSize.X <= 0 then return end
	local w, h = layer.AbsoluteSize.X / s, layer.AbsoluteSize.Y / s
	local bar = Instance.new("Frame")
	bar.BorderSizePixel = 0
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.BackgroundColor3 = color or Color3.new(1, 1, 1)
	bar.Size = UDim2.fromOffset(h * 0.9, h * 3)
	bar.Rotation = 18
	bar.Position = UDim2.fromOffset(-h, h / 2)
	bar.ZIndex = 0
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1),
	})
	g.Parent = bar
	bar.Parent = layer
	life(bar, 0.65, layer)
	tween(bar, { Position = UDim2.fromOffset(w + h, h / 2) }, 0.55, Enum.EasingStyle.Quint)
end

function FX.ring(center, color, from, to, time, a0)
	if not fxOn() then return end
	local inst = fxShape("ring", FxLayer)
	local ox, oy = FxLayer.AbsolutePosition.X, FxLayer.AbsolutePosition.Y
	inst.Position = UDim2.fromOffset(center.X - ox, center.Y - oy)
	inst.Size = UDim2.fromOffset(from, from)
	fxTint(inst, color)
	fxSet(inst, a0 or 0.3)
	time = time or 0.5
	life(inst, time + 0.05)
	tween(inst, { Size = UDim2.fromOffset(to, to) }, time, Enum.EasingStyle.Quint)
	fxFade(inst, 1, time, Enum.EasingStyle.Quad)
end

function FX.burst(center, color, count, dist, opts)
	if not fxOn() then return end
	opts = opts or {}
	count = math.min(count, FX.MAX - FX.Active)
	if count <= 0 then return end
	local base = opts.Base or (math.random() * math.pi * 2)
	local ox, oy = FxLayer.AbsolutePosition.X, FxLayer.AbsolutePosition.Y
	for k = 1, count do
		local ang = base + (k - 1) / count * math.pi * 2 + (math.random() - 0.5) * 0.7
		local d = dist * (0.6 + math.random() * 0.7)
		local sz = (opts.Size or 9) * (0.7 + math.random() * 0.6)
		local inst = fxShape(opts.Shape or "spark", FxLayer)
		inst.Position = UDim2.fromOffset(center.X - ox, center.Y - oy)
		inst.Size = UDim2.fromOffset(sz, sz)
		inst.Rotation = math.random(0, 90)
		fxTint(inst, (k % 3 == 0) and Theme.Text or color)
		fxSet(inst, 0)
		local t = 0.45 + math.random() * 0.25
		life(inst, t + 0.05)
		tween(inst, {
			Position = UDim2.fromOffset(center.X - ox + math.cos(ang) * d, center.Y - oy + math.sin(ang) * d * (opts.Squash or 1)),
			Size = UDim2.fromOffset(sz * 0.3, sz * 0.3),
			Rotation = inst.Rotation + (math.random() - 0.5) * 220,
		}, t, Enum.EasingStyle.Quint)
		task.delay(t * 0.3, function()
			if inst.Parent then fxFade(inst, 1, t * 0.7, Enum.EasingStyle.Quad) end
		end)
	end
end

local function fxScale(obj)
	local u = obj:FindFirstChild("FxScale")
	if not u then
		u = Instance.new("UIScale")
		u.Name = "FxScale"
		u.Parent = obj
	end
	return u
end

function FX.scaleTo(obj, v, time, style, dir)
	return tween(fxScale(obj), { Scale = v }, time or 0.2, style or Enum.EasingStyle.Quint, dir)
end

function FX.pop(obj, from, time)
	local u = fxScale(obj)
	u.Scale = from
	tween(u, { Scale = 1 }, time or 0.45, Enum.EasingStyle.Back)
end

local function flashObj(obj, prop, hot, rest, up, down)
	if Library.Effects == false then return end
	up = up or 0.08
	tween(obj, { [prop] = hot }, up, Enum.EasingStyle.Quad)
	task.delay(up, function()
		if obj.Parent then tween(obj, { [prop] = rest() }, down or 0.5, Enum.EasingStyle.Quad) end
	end)
end

local function pressTrack(hit, onDown, onUp)
	local st = { Pos = nil, Down = false }
	connect(hit.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		st.Pos = Vector2.new(i.Position.X, i.Position.Y)
		st.Down = true
		if onDown then onDown(st.Pos) end
		local con
		con = i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel then
				con:Disconnect()
				st.Down = false
				if onUp then onUp() end
			end
		end)
	end)
	return st
end

function Library:SetEffects(v)
	Library.Effects = v and true or false
end

local function clampCenter(target, nx, ny, startPos)
	local vp = Gui.AbsoluteSize
	local w, h = target.AbsoluteSize.X, target.AbsoluteSize.Y
	local visX, visY = math.min(80, w), math.min(40, h)
	local bx, by = startPos.X.Scale * vp.X, startPos.Y.Scale * vp.Y
	local loX, hiX = visX - w / 2 - bx, vp.X + w / 2 - visX - bx
	local loY, hiY = h / 2 - by, vp.Y - visY + h / 2 - by
	if loX > hiX then loX = (loX + hiX) / 2 hiX = loX end
	if loY > hiY then loY = (loY + hiY) / 2 hiY = loY end
	return math.clamp(nx, loX, hiX), math.clamp(ny, loY, hiY)
end

local function draggable(handle, target, onTap, opt)
	opt = opt or {}
	local dragging, moved, startIn, startPos = false, false, nil, nil
	connect(handle.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if opt.canDrag and not opt.canDrag() then return end
		if opt.deadRight then
			local right = handle.AbsolutePosition.X + handle.AbsoluteSize.X
			if i.Position.X > right - opt.deadRight * getScale() then return end
		end
		dragging, moved = true, false
		startIn, startPos = i.Position, target.Position
		local con
		con = i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				dragging = false
				con:Disconnect()
				if onTap and not moved then onTap() end
			end
		end)
	end)
	connect(UserInputService.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startIn
			if not moved and d.Magnitude > DRAG_SLOP then
				moved = true
				closePopup()
			end
			if moved or not onTap then
				local nx, ny = clampCenter(target, startPos.X.Offset + d.X, startPos.Y.Offset + d.Y, startPos)
				target.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
			end
		end
	end)
end

function Library:SetTheme(name) applyTheme(name, false) end

function Library:SetTransparency(v)
	Library.Transparency = v
	for _, f in ipairs(TransFrames) do tween(f, { BackgroundTransparency = v }, 0.25) end
end

local NOTIFY_W, NOTIFY_MAX, NOTIFY_OFF = 260, 4, 300
local NotifHolder = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(NOTIFY_W, 440), Parent = Gui })
new("UIListLayout", {
	Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = NotifHolder,
})
local NotifToasts, NotifSerial = {}, 0

function Library:Notify(o)
	o = o or {}
	local dur = tonumber(o.Duration) or 4
	while #NotifToasts >= NOTIFY_MAX do NotifToasts[1]() end
	NotifSerial += 1

	local slot = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = NotifSerial, Parent = NotifHolder })
	local mover = new("Frame", {
		Position = UDim2.fromOffset(NOTIFY_OFF, 0), Size = UDim2.new(1, 0, 0, 64), Parent = slot,
	})
	makeShadow(mover, 12, { Steps = 4, Step = 4, Alpha = 0.05 })
	local toast = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Card", Parent = mover })
	corner(toast, 12)
	local tstroke = stroke(toast)
	gradient(toast, 215)
	toast:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local h = toast.AbsoluteSize.Y
		if h > 0 then mover.Size = UDim2.new(1, 0, 0, h) end
	end)
	padding(toast, 14, 11, 14, 12)
	listLayout(toast, 7)

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = toast })
	local nbox = iconTile(head, o.Icon or "info", 26, 15, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
	new("TextLabel", {
		Text = o.Title or "Notification", Font = FONT_BOLD, TextSize = 14, Fg = "Text", Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -36, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	if o.Content and o.Content ~= "" then
		new("TextLabel", {
			Text = o.Content, Fg = "SubText", TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
			TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Parent = toast,
		})
	end
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 4), Bg = "Stroke", LayoutOrder = 3, Parent = toast })
	corner(bar, 2)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), Bg = "Accent", Parent = bar })
	corner(fill, 2)
	gradient(fill, 0)

	local dismissed, hit = false, nil
	local function dismiss()
		if dismissed then return end
		dismissed = true
		if hit then hit.Active = false hit.Visible = false end
		for i = #NotifToasts, 1, -1 do
			if NotifToasts[i] == dismiss then table.remove(NotifToasts, i) end
		end
		tween(mover, { Position = UDim2.fromOffset(NOTIFY_OFF, 0) }, 0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.26, function()
			if not slot.Parent then return end
			local h = slot.AbsoluteSize.Y
			slot.AutomaticSize = AutoNone
			slot.Size = UDim2.new(1, 0, 0, h)
			tween(slot, { Size = UDim2.new(1, 0, 0, 0) }, 0.18)
			task.delay(0.18, function()
				if slot.Parent then slot:Destroy() end
				prune()
			end)
		end)
	end
	NotifToasts[#NotifToasts + 1] = dismiss

	hit = new("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = slot })
	onClick(hit, dismiss)
	if not IS_TOUCH then
		connect(hit.MouseEnter, function()
			if dismissed then return end
			tween(toast, { BackgroundColor3 = Theme.Hover }, 0.15)
			tween(mover, { Position = UDim2.fromOffset(-4, 0) }, 0.18, Enum.EasingStyle.Quad)
		end)
		connect(hit.MouseLeave, function()
			if dismissed then return end
			tween(toast, { BackgroundColor3 = Theme.Card }, 0.2)
			tween(mover, { Position = UDim2.fromOffset(0, 0) }, 0.2, Enum.EasingStyle.Quad)
		end)
	end

	tween(mover, { Position = UDim2.fromOffset(0, 0) }, 0.45, Enum.EasingStyle.Back)
	tstroke.Color = Theme.Accent
	tween(tstroke, { Color = Theme.Stroke }, 1.0, Enum.EasingStyle.Quad)
	task.delay(0.16, function()
		if nbox.Parent then FX.pop(nbox, 0.3, 0.55) end
	end)
	if dur > 0 then
		tween(fill, { Size = UDim2.fromScale(0, 1) }, dur, Enum.EasingStyle.Linear)
		task.delay(dur, dismiss)
	end
	return { Dismiss = dismiss }
end

function Library:ListConfigs()
	local list = {}
	if not (HasFS and listfiles) then return list end
	local dir = Library.ConfigFolder .. "/configs"
	if not isfolder(dir) then return list end
	for _, p in ipairs(listfiles(dir)) do
		local n = tostring(p):match("([^/\\]+)%.json$")
		if n then list[#list + 1] = n end
	end
	table.sort(list)
	return list
end

function Library:SaveConfig(name)
	if not HasFS then return false end
	name = tostring(name or ""):gsub("[^%w_%- ]", "")
	if name:gsub("%s", "") == "" then return false end
	ensureFolder(ROOT)
	ensureFolder(Library.ConfigFolder)
	ensureFolder(Library.ConfigFolder .. "/configs")
	local data = {}
	for flag, obj in pairs(Library.Options) do
		local v = obj.Value
		if v ~= nil then
			if typeof(v) == "EnumItem" then
				v = { __key = v.Name }
			elseif typeof(v) == "Color3" then
				v = { __c3 = v:ToHex() }
			end
			data[flag] = v
		end
	end
	local ok = pcall(function()
		writefile(Library.ConfigFolder .. "/configs/" .. name .. ".json", HttpService:JSONEncode(data))
		writefile(Library.ConfigFolder .. "/last.txt", name)
	end)
	return ok, name
end

function Library:LoadConfig(name)
	if not HasFS or not name then return false end
	local path = Library.ConfigFolder .. "/configs/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or type(data) ~= "table" then return false end
	for flag, v in pairs(data) do
		local obj = Library.Options[flag]
		if obj then
			pcall(function()
				if type(v) == "table" and v.__key then
					v = Enum.KeyCode[v.__key]
				elseif type(v) == "table" and v.__c3 then
					v = Color3.fromHex(v.__c3)
				end
				obj:Set(v)
			end)
		end
	end
	pcall(writefile, Library.ConfigFolder .. "/last.txt", name)
	return true
end

function Library:Unload()
	if SliderLock.Active then pcall(SliderLock.Active) end
	for _, c in ipairs(Library.Connections) do pcall(function() c:Disconnect() end) end
	Library.Connections = {}
	pcall(function() Gui:Destroy() end)
	env.__ZystrixUI = nil
end

local Section = {}
Section.__index = Section

function Section:_next()
	self.Order += 1
	return self.Order
end

local function register(obj, o)
	obj.Flag = o.Flag
	if o.Flag then
		Library.Options[o.Flag] = obj
		Library.Flags[o.Flag] = obj.Value
	end
end

local function fire(obj, o)
	if obj.Flag then Library.Flags[obj.Flag] = obj.Value end
	if o.Callback then task.spawn(o.Callback, obj.Value) end
	if obj.Flag and Library.OnFlagChanged then task.spawn(Library.OnFlagChanged, obj.Flag, obj.Value) end
end

local function quiet(obj)
	if obj.Flag then Library.Flags[obj.Flag] = obj.Value end
end

local function makeRow(sec, height, bgKey)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, height or 36), Bg = bgKey or "Element", LayoutOrder = sec:_next(), Parent = sec.Content })
	corner(row, 8)
	return row
end

local function indexItem(sec, name, kind, row, icon)
	local tab = sec.Tab
	local win = tab and tab.Window
	if win and win._register then
		win:_register({ Name = name, Kind = kind, Tab = tab, Section = sec, Row = row, Icon = icon })
	end
end

local function fitLabel(lbl, maxSize, minSize)
	local lastW, lastText = -1, nil
	local function run()
		local sc = math.max(getScale(), 0.05)
		local w, h = lbl.AbsoluteSize.X / sc, lbl.AbsoluteSize.Y / sc
		if w <= 4 then return end
		local text = lbl.Text
		if lastText == text and math.abs(w - lastW) < 2.5 then return end
		lastW, lastText = w, text
		pcall(function()
			for s = maxSize, minSize, -1 do
				local b = TextService:GetTextSize(text, s, lbl.Font, Vector2.new(10000, 10000))
				if b.X <= w then
					lbl.TextWrapped = false
					lbl.TextSize = s
					return
				end
			end
			if h >= 30 then
				lbl.TextWrapped = true
				local s = minSize + 1
				local b = TextService:GetTextSize(text, s, lbl.Font, Vector2.new(w, 10000))
				if b.Y > h then s = minSize end
				lbl.TextSize = s
			else
				lbl.TextWrapped = false
				lbl.TextSize = minSize
			end
		end)
	end
	local queued = false
	connect(lbl:GetPropertyChangedSignal("AbsoluteSize"), function()
		if queued then return end
		queued = true
		task.delay(0.1, function()
			queued = false
			if lbl.Parent then run() end
		end)
	end)
	connect(lbl:GetPropertyChangedSignal("Text"), run)
	task.defer(run)
end

local function rowLabel(row, text, width, shift)
	shift = shift or 0
	width = width or UDim2.new(1, -24, 1, 0)
	local lbl = new("TextLabel", {
		Text = text or "", Fg = "Text", Position = UDim2.fromOffset(12 + shift, 0),
		Size = UDim2.new(width.X.Scale, width.X.Offset - shift - 12, width.Y.Scale, width.Y.Offset),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	fitLabel(lbl, 13, 10)
	return lbl
end

local function rowIcon(row, spec, cy)
	if not spec then return 0 end
	local pos = cy and UDim2.new(0, 12, 0, cy) or UDim2.new(0, 12, 0.5, 0)
	makeIcon(row, spec, 16, "SubText", { AnchorPoint = Vector2.new(0, 0.5), Position = pos })
	return 26
end

local function onHover(gui, enter, leave)
	if IS_TOUCH then return end
	connect(gui.MouseEnter, enter)
	connect(gui.MouseLeave, leave)
end

function onClick(btn, fn, eager)
	local last = 0
	local function fire(pos)
		local now = os.clock()
		if now - last < 0.06 then return end
		last = now
		fn(pos)
	end
	connect(btn.InputBegan, function(i)
		local t = i.UserInputType
		local p0 = Vector2.new(i.Position.X, i.Position.Y)
		if t == Enum.UserInputType.MouseButton1 then
			fire(p0)
		elseif t == Enum.UserInputType.Touch then
			if eager then
				fire(p0)
				return
			end
			local start = i.Position
			local con
			con = i.Changed:Connect(function()
				local st = i.UserInputState
				if st == Enum.UserInputState.End then
					con:Disconnect()
					if (i.Position - start).Magnitude <= TAP_SLOP then fire(p0) end
				elseif st == Enum.UserInputState.Cancel then
					con:Disconnect()
				end
			end)
		end
	end)
end
local function hoverRow(row, hit, key)
	onHover(hit,
		function() tween(row, { BackgroundColor3 = Theme.Hover }, 0.15) end,
		function() tween(row, { BackgroundColor3 = Theme[key or "Element"] }, 0.2) end)
end

local function sideControl(box)
	new("UISizeConstraint", { MinSize = Vector2.new(96, 24), MaxSize = Vector2.new(160, 24), Parent = box })
end
local SIDE_LABEL = UDim2.new(0.5, -18, 1, 0)
local SIDE_BOX = UDim2.new(0.5, -10, 0, 24)

local function restElement() return Theme.Element end
local function restHover() return Theme.Hover end

function Section:AddToggle(o)
	local row = makeRow(self, 40)
	indexItem(self, o.Name, "Toggle", row, o.Icon)
	rowLabel(row, o.Name, UDim2.new(1, -68, 1, 0), rowIcon(row, o.Icon))

	local PW, PH, KS, PAD = 46, 24, 18, 3
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(PW, PH),
		BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0, Parent = row,
	})
	round(pill)
	local pst = new("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = pill })
	gradient(pill, 200)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, PAD, 0.5, 0), Size = UDim2.fromOffset(KS, KS),
		BackgroundColor3 = Theme.SubText, BackgroundTransparency = 0, Parent = pill,
	})
	round(knob)
	gradient(knob, 190)
	new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.7, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = knob })
	local tick = new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
		ImageTransparency = 1, Img = "Accent", Parent = knob,
	})

	local hit = hitZone(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(HIT_W, 40),
	})

	local obj = { Type = "Toggle", Value = o.Default and true or false }
	local tok, halo = 0, nil
	local function kx(on) return on and (PW - PAD - KS) or PAD end
	local function render(instant)
		local on = obj.Value
		local bg = on and Theme.Accent or Theme.Hover
		local bd = on and Theme.Accent or Theme.Stroke
		local kc = on and Theme.AccentText or Theme.SubText
		local kp = UDim2.new(0, kx(on), 0.5, 0)
		tok += 1
		local my = tok
		if instant then
			pill.BackgroundColor3 = bg
			pst.Color = bd
			knob.BackgroundColor3 = kc
			knob.Position = kp
			knob.Size = UDim2.fromOffset(KS, KS)
			tick.Size = on and UDim2.fromOffset(11, 11) or UDim2.fromOffset(0, 0)
			tick.ImageTransparency = on and 0 or 1
			return
		end
		tween(pill, { BackgroundColor3 = bg }, 0.14, Enum.EasingStyle.Quad)
		tween(pst, { Color = bd }, 0.14, Enum.EasingStyle.Quad)
		tween(knob, { BackgroundColor3 = kc }, 0.14, Enum.EasingStyle.Quad)
		tween(knob, { Position = kp }, 0.32, Enum.EasingStyle.Back)
		tween(knob, { Size = UDim2.fromOffset(KS + 4, KS - 2) }, 0.08, Enum.EasingStyle.Quad)
		task.delay(0.08, function()
			if my == tok then tween(knob, { Size = UDim2.fromOffset(KS, KS) }, 0.3, Enum.EasingStyle.Back) end
		end)
		if on then
			tick.Rotation = -60
			tween(tick, { Size = UDim2.fromOffset(11, 11), ImageTransparency = 0, Rotation = 0 }, 0.4, Enum.EasingStyle.Back)
		else
			tween(tick, { Size = UDim2.fromOffset(0, 0), ImageTransparency = 1, Rotation = 40 }, 0.16, Enum.EasingStyle.Quad)
		end
	end
	render(true)
	FX.whenReady(function()
		if FX.Assets.tick then tick.Image = FX.Assets.tick end
	end)
	Hooks[#Hooks + 1] = function(instant)
		local on = obj.Value
		local t = instant and 0 or 0.3
		tween(pill, { BackgroundColor3 = on and Theme.Accent or Theme.Hover }, t)
		tween(pst, { Color = on and Theme.Accent or Theme.Stroke }, t)
		tween(knob, { BackgroundColor3 = on and Theme.AccentText or Theme.SubText }, t)
	end

	local function flashHalo(col, a0, time)
		if Library.Effects == false or not FX.Assets.glow then return end
		if not halo then
			halo = new("ImageLabel", {
				Image = FX.Assets.glow, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0),
				Size = UDim2.fromOffset(86, 44), ImageTransparency = 1, ZIndex = 0, Parent = row,
			})
		end
		halo.ImageColor3 = col
		halo.ImageTransparency = a0
		tween(halo, { ImageTransparency = 1 }, time, Enum.EasingStyle.Quad)
	end

	local function play(on, click)
		local s = pill.AbsoluteSize.X / PW
		if s <= 0 then return end
		local cx = pill.AbsolutePosition.X + pill.AbsoluteSize.X * (kx(on) + KS / 2) / PW
		local cy = pill.AbsolutePosition.Y + pill.AbsoluteSize.Y / 2
		local c = Vector2.new(cx, cy)
		flashHalo(on and Theme.Accent or Theme.SubText, on and 0.5 or 0.82, on and 0.65 or 0.4)
		flashObj(row, "BackgroundColor3", on and Theme.Element:Lerp(Theme.Accent, 0.12) or Theme.Element:Lerp(Theme.Text, 0.05), restElement, 0.08, 0.5)
		if not click then return end
		FX.ripple(row, typeof(click) == "Vector2" and click or nil, on and Theme.Accent or Theme.SubText, { Radius = 8, Alpha = on and 0.8 or 0.88 })
		if on then
			FX.ring(c, Theme.Accent, 14 * s, 58 * s, 0.55, 0.15)
			FX.burst(c, Theme.Accent, 5, 24 * s, { Size = 9 * s, Squash = 0.55 })
		else
			FX.ring(c, Theme.SubText, 44 * s, 15 * s, 0.4, 0.5)
		end
	end

	onHover(hit,
		function() FX.scaleTo(pill, 1.06, 0.18, Enum.EasingStyle.Back) end,
		function() FX.scaleTo(pill, 1, 0.2) end)
	connect(hit.MouseButton1Down, function() FX.scaleTo(pill, 0.92, 0.07) end)
	connect(hit.MouseButton1Up, function() FX.scaleTo(pill, IS_TOUCH and 1 or 1.06, 0.4, Enum.EasingStyle.Back) end)

	function obj:Set(v, silent, click)
		v = v and true or false
		local changed = v ~= self.Value
		self.Value = v
		if changed then
			render(false)
			play(v, click)
		end
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end
	onClick(hit, function(pos) obj:Set(not obj.Value, false, pos or true) end)
	register(obj, o)
	return obj
end

function Section:AddSlider(o)
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local decimals = 0
	local frac = tostring(inc):match("%.(%d+)")
	if frac then decimals = #frac end

	local row = makeRow(self, 48)
	indexItem(self, o.Name, "Slider", row, o.Icon)
	local sh = rowIcon(row, o.Icon, 17)
	rowLabel(row, o.Name, UDim2.new(1, -80, 0, 26), sh).Position = UDim2.fromOffset(12 + sh, 4)
	local valueLbl
	local vst
	if o.Input == false then
		valueLbl = new("TextLabel", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.fromOffset(66, 26),
			TextXAlignment = Enum.TextXAlignment.Right, Fg = "SubText", TextSize = 12, Parent = row,
		})
	else
		valueLbl = new("TextBox", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 2), Size = UDim2.fromOffset(62, 22),
			Bg = "Hover", Fg = "Text", Ph = "SubText", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
			ClipsDescendants = true, Parent = row,
		})
		corner(valueLbl, 6)
		vst = stroke(valueLbl)
	end
	local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 1, -13), Size = UDim2.new(1, -24, 0, 6), Bg = "Stroke", Parent = row })
	round(track)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), Bg = "Accent", Parent = track })
	round(fill)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(14, 14), Bg = "Text", Parent = fill })
	round(knob)
	gradient(knob, 190)
	local hit = hitZone(row, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 24) })

	local obj = { Type = "Slider", Value = min, Min = min, Max = max, Step = inc }
	local fillTime, fillStyle = 0.08, Enum.EasingStyle.Quad
	local halo
	local function render()
		local pct = (obj.Value - min) / math.max(max - min, 1e-9)
		tween(fill, { Size = UDim2.fromScale(pct, 1) }, fillTime, fillStyle)
		valueLbl.Text = string.format("%." .. decimals .. "f", obj.Value) .. (o.Suffix or "")
	end
	function obj:Set(v, silent)
		v = math.clamp(tonumber(v) or min, min, max)
		v = math.floor((v - min) / inc + 0.5) * inc + min
		v = math.clamp(tonumber(string.format("%." .. decimals .. "f", v)), min, max)
		self.Value = v
		render()
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end

	local dragging, dragInput, stateCon = false, nil, nil
	local scroll = self.Scroll
	local scrollCon, lockPos = nil, nil

	local function fromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local before = obj.Value
		obj:Set(min + (max - min) * rel)
		return before ~= obj.Value
	end

	local function knobCenter()
		return Vector2.new(knob.AbsolutePosition.X + knob.AbsoluteSize.X / 2, knob.AbsolutePosition.Y + knob.AbsoluteSize.Y / 2)
	end

	local function ensureHalo()
		if halo or not FX.Assets.glow then return halo end
		halo = new("ImageLabel", {
			Image = FX.Assets.glow, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(44, 44), ImageTransparency = 1, ZIndex = 0, Parent = fill,
		})
		return halo
	end

	local function stop()
		if not dragging then return end
		dragging = false
		dragInput = nil
		if stateCon then
			stateCon:Disconnect()
			stateCon = nil
		end
		if SliderLock.Active == stop then SliderLock.Active = nil end
		if scrollCon then
			scrollCon:Disconnect()
			scrollCon = nil
		end
		lockPos = nil
		if scroll then scroll.ScrollingEnabled = true end
		tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.3, Enum.EasingStyle.Back)
		tween(track, { Size = UDim2.new(1, -24, 0, 6) }, 0.3, Enum.EasingStyle.Back)
		if vst then tween(vst, { Color = Theme.Stroke }, 0.25) end
		FX.pop(valueLbl, 1.14, 0.45)
		if halo then tween(halo, { ImageTransparency = 1 }, 0.3) end
		local s = uiScale(knob)
		FX.ring(knobCenter(), Theme.Accent, 14 * s, 34 * s, 0.4, 0.4)
	end

	connect(hit.InputBegan, function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if SliderLock.Active and SliderLock.Active ~= stop then SliderLock.Active() end
		if dragging then stop() end
		dragging = true
		dragInput = i
		SliderLock.Active = stop
		stateCon = i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel then stop() end
		end)
		if scroll then
			lockPos = scroll.CanvasPosition
			scroll.ScrollingEnabled = false
			scrollCon = scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
				if dragging and lockPos and scroll.CanvasPosition ~= lockPos then
					scroll.CanvasPosition = lockPos
				end
			end)
		end
		tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.2, Enum.EasingStyle.Back)
		tween(track, { Size = UDim2.new(1, -24, 0, 8) }, 0.25, Enum.EasingStyle.Back)
		if vst then tween(vst, { Color = Theme.Accent }, 0.15) end
		local h = ensureHalo()
		if h then
			h.ImageColor3 = Theme.Accent:Lerp(Theme.Text, 0.4)
			tween(h, { ImageTransparency = 0.55 }, 0.2)
		end
		FX.ripple(row, Vector2.new(i.Position.X, i.Position.Y), Theme.Accent, { Radius = 8, Alpha = 0.9 })
		fillTime, fillStyle = 0.28, Enum.EasingStyle.Quint
		fromX(i.Position.X)
		fillTime, fillStyle = 0.07, Enum.EasingStyle.Quad
		local s = uiScale(knob)
		FX.ring(knobCenter(), Theme.Accent, 12 * s, 38 * s, 0.45, 0.3)
	end)

	connect(UserInputService.InputChanged, function(i)
		if not dragging or SliderLock.Active ~= stop or not dragInput then return end
		if dragInput.UserInputType == Enum.UserInputType.Touch then
			if i ~= dragInput then return end
		else
			if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				stop()
				return
			end
		end
		fromX(i.Position.X)
	end)

	connect(UserInputService.InputEnded, function(i)
		if not dragging or not dragInput then return end
		if i == dragInput then
			stop()
		elseif dragInput.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1 then
			stop()
		end
	end)

	if o.Input ~= false then
		connect(valueLbl.Focused, function()
			tween(vst, { Color = Theme.Accent }, 0.15)
			valueLbl.Text = string.format("%." .. decimals .. "f", obj.Value)
		end)
		connect(valueLbl.FocusLost, function()
			tween(vst, { Color = Theme.Stroke }, 0.2)
			local n = tonumber((valueLbl.Text:gsub("[^%d%.%-]", "")))
			if n then
				local before = obj.Value
				obj:Set(n, true)
				if obj.Value ~= before then fire(obj, o) end
			end
			render()
		end)
	end
	obj:Set(o.Default or min, true)
	fillTime, fillStyle = 0.08, Enum.EasingStyle.Quad
	register(obj, o)
	return obj
end

function Section:AddDropdown(o)
	local row = makeRow(self, 36)
	indexItem(self, o.Name, "Dropdown", row, o.Icon)
	rowLabel(row, o.Name, SIDE_LABEL, rowIcon(row, o.Icon))
	local box = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = SIDE_BOX, Bg = "Hover", Parent = row })
	corner(box, 6)
	sideControl(box)
	local bstroke = stroke(box)
	local txt = new("TextLabel", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0), Fg = "Text", TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box })
	local arrow = makeIcon(box, "chevron", 12, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0) })
	local hit = hitZone(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0) })
	hoverRow(row, hit)

	local allowNone = o.AllowNone ~= false
	local NONE_ITEM = {}
	local obj = { Type = "Dropdown", Options = o.Options or {}, Value = nil }
	local function render(animate)
		if obj.Value ~= nil then
			txt.Text = tostring(obj.Value)
		elseif #obj.Options == 0 then
			txt.Text = o.Placeholder or "None"
		else
			txt.Text = "None"
		end
		local tr = obj.Value ~= nil and 0 or 0.45
		if animate then
			txt.TextTransparency = 1
			txt.Position = UDim2.fromOffset(8, 8)
			tween(txt, { TextTransparency = tr, Position = UDim2.fromOffset(8, 0) }, 0.3, Enum.EasingStyle.Quint)
		else
			tween(txt, { TextTransparency = tr }, 0.15)
		end
	end
	function obj:Set(v, silent)
		if v == nil then
			if not allowNone then return end
		elseif not table.find(self.Options, v) then
			return
		end
		local changed = v ~= self.Value
		self.Value = v
		render(changed)
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end
	function obj:Refresh(list)
		self.Options = list or {}
		if self.Value ~= nil and not table.find(self.Options, self.Value) then
			self.Value = allowNone and nil or self.Options[1]
		end
		quiet(self)
		render()
	end

	local isOpen = false
	local function open()
		closePopup()
		if #obj.Options == 0 then return end
		local entries = {}
		if allowNone then entries[1] = NONE_ITEM end
		for _, opt in ipairs(obj.Options) do entries[#entries + 1] = opt end
		local n = #entries
		prune()
		isOpen = true
		local scale = getScale()
		local abs, size = box.AbsolutePosition, box.AbsoluteSize
		local w = size.X / scale
		local h = math.min(n, 6) * 28 + 8
		local up = (abs.Y + size.Y + 4 + h * scale) > Gui.AbsoluteSize.Y

		local blocker = new("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = Gui })
		local popup = new("Frame", {
			AnchorPoint = Vector2.new(0, up and 1 or 0),
			Position = UDim2.fromOffset(abs.X, up and abs.Y - 4 or abs.Y + size.Y + 4),
			Size = UDim2.fromOffset(w, 0), Bg = "Card", ClipsDescendants = true, ZIndex = 51, Parent = Gui,
		})
		corner(popup, 8)
		stroke(popup)
		new("UIScale", { Scale = scale, Parent = popup })
		local sc = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
			ScrollBarThickness = 2, Sb = "Stroke", Parent = popup,
		})
		padding(sc, 4, 4, 4, 4)
		listLayout(sc, 2)
		for idx, opt in ipairs(entries) do
			local isNone = opt == NONE_ITEM
			local selected = (isNone and obj.Value == nil) or (not isNone and opt == obj.Value)
			local item = new("TextButton", {
				Size = UDim2.new(1, 0, 0, 26), Bg = "Hover", BackgroundTransparency = 1, LayoutOrder = idx,
				Text = isNone and "None" or tostring(opt), TextSize = 12, Fg = selected and "Accent" or "Text", Font = selected and FONT_BOLD or FONT,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = sc,
			})
			corner(item, 6)
			local pad = padding(item, 8, 0, 8, 0)
			if idx <= 6 then
				item.TextTransparency = 1
				pad.PaddingLeft = UDim.new(0, 20)
				task.delay(0.03 + idx * 0.025, function()
					if item.Parent then
						tween(item, { TextTransparency = 0 }, 0.2)
						tween(pad, { PaddingLeft = UDim.new(0, 8) }, 0.3, Enum.EasingStyle.Back)
					end
				end)
			end
			onHover(item,
				function()
					tween(item, { BackgroundTransparency = 0 }, 0.12)
					tween(pad, { PaddingLeft = UDim.new(0, 12) }, 0.16)
				end,
				function()
					tween(item, { BackgroundTransparency = 1 }, 0.15)
					tween(pad, { PaddingLeft = UDim.new(0, 8) }, 0.18)
				end)
			onClick(item, function()
				item.BackgroundColor3 = Theme.Accent
				item.BackgroundTransparency = 0.6
				tween(item, { BackgroundTransparency = 1 }, 0.2)
				if isNone then obj:Set(nil) else obj:Set(opt) end
				closePopup()
			end)
		end
		tween(popup, { Size = UDim2.fromOffset(w, h) }, 0.26, Enum.EasingStyle.Quint)
		tween(arrow, { Rotation = 180 }, 0.4, Enum.EasingStyle.Back)
		tween(bstroke, { Color = Theme.Accent }, 0.2)

		local scrollCon
		if self.Scroll then
			scrollCon = self.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup)
		end
		local function close()
			isOpen = false
			if scrollCon then scrollCon:Disconnect() end
			tween(arrow, { Rotation = 0 }, 0.3, Enum.EasingStyle.Back)
			tween(bstroke, { Color = Theme.Stroke }, 0.2)
			tween(popup, { Size = UDim2.fromOffset(w, 0) }, 0.15)
			blocker:Destroy()
			task.delay(0.18, function() popup:Destroy() end)
		end
		Library.OpenPopup = close
		onClick(blocker, closePopup)
	end
	onClick(hit, function(pos)
		FX.ripple(row, pos, Theme.Accent, { Radius = 8, Alpha = 0.85 })
		flashObj(row, "BackgroundColor3", Theme.Element:Lerp(Theme.Accent, 0.12), restElement, 0.08, 0.4)
		if isOpen then closePopup() else open() end
	end)

	local startValue = o.Default
	if startValue == nil and not allowNone then startValue = obj.Options[1] end
	obj:Set(startValue, true)
	render()
	register(obj, o)
	return obj
end

function Section:AddButton(o)
	local primary = o.Style == "Primary"
	local row = makeRow(self, primary and 38 or 40, primary and "Text" or "Element")
	indexItem(self, o.Name, "Button", row, o.Icon)
	local hit, target, lbl, iconImg

	if primary then
		gradient(row, 200)
		target = row
		lbl = new("TextLabel", {
			Text = o.Name or "Button", Fg = "Background", Font = FONT_BOLD, Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
		})
		if o.Icon then
			iconImg = makeIcon(row, o.Icon, 16, "Background", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) })
		end
		hit = hitZone(row, { Size = UDim2.fromScale(1, 1) })
	else
		local hasIcon = o.Icon ~= nil
		local hasText = o.ButtonText ~= nil or not hasIcon
		local pw = (hasIcon and hasText) and 80 or (hasIcon and 36 or 54)
		lbl = rowLabel(row, o.Name, UDim2.new(1, -(pw + 24), 1, 0))
		target = new("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(pw, 28),
			Bg = "Hover", Parent = row,
		})
		corner(target, 8)
		stroke(target)
		gradient(target, 185)
		if hasIcon then
			if hasText then
				iconImg = makeIcon(target, o.Icon, 14, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
			else
				iconImg = makeIcon(target, o.Icon, 16, "Accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
			end
		end
		if hasText then
			new("TextLabel", {
				Text = o.ButtonText or "Run", Fg = "Text", TextSize = 12, Font = FONT_BOLD, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(hasIcon and 14 or 0, 0), Size = UDim2.new(1, hasIcon and -14 or 0, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = target,
			})
		end
		hit = hitZone(row, {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(math.max(pw + 24, HIT_W), 40),
		})
	end

	local sc = new("UIScale", { Parent = target })
	local function base() return primary and Theme.Text or Theme.Hover end
	local function over() return primary and Theme.Text:Lerp(Theme.Background, 0.15) or Theme.Stroke end
	onHover(hit,
		function()
			tween(target, { BackgroundColor3 = over() }, 0.15)
			tween(sc, { Scale = primary and 1.01 or 1.05 }, 0.18, Enum.EasingStyle.Back)
		end,
		function()
			tween(target, { BackgroundColor3 = base() }, 0.2)
			tween(sc, { Scale = 1 }, 0.2, Enum.EasingStyle.Quad)
		end)
	connect(hit.MouseButton1Down, function() tween(sc, { Scale = 0.95 }, 0.06) end)
	connect(hit.MouseButton1Up, function() tween(sc, { Scale = 1 }, 0.3, Enum.EasingStyle.Back) end)
	onClick(hit, function(pos)
		FX.ripple(target, pos, primary and Theme.Background or Theme.Accent, { Radius = primary and 8 or 8, Alpha = primary and 0.78 or 0.8, Time = 0.55 })
		if iconImg then FX.pop(iconImg, 1.45, 0.5) end
		if primary then
			FX.shine(target, Color3.new(1, 1, 1), 8)
		else
			flashObj(target, "BackgroundColor3", Theme.Hover:Lerp(Theme.Accent, 0.25), base, 0.06, 0.45)
		end
		if o.Callback then task.spawn(o.Callback) end
	end)
	local obj = { Type = "Button" }
	function obj:SetText(t)
		if lbl.Text == t then return end
		lbl.Text = t
		lbl.TextTransparency = 0.7
		tween(lbl, { TextTransparency = 0 }, 0.3)
	end
	return obj
end

function Section:AddTextbox(o)
	local row = makeRow(self, 36)
	indexItem(self, o.Name, "Textbox", row, o.Icon)
	rowLabel(row, o.Name, SIDE_LABEL, rowIcon(row, o.Icon))
	local zone = hitZone(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0) })
	local tb = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = SIDE_BOX,
		Bg = "Hover", Fg = "Text", Ph = "SubText", PlaceholderText = o.Placeholder or "", Text = o.Default or "",
		TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = row,
	})
	corner(tb, 6)
	sideControl(tb)
	padding(tb, 8, 0, 8, 0)
	local st = stroke(tb)
	local line = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 0, 0, 2), Bg = "Accent", Parent = tb,
	})
	local obj = { Type = "Textbox", Value = o.Default or "", Input = tb }
	onClick(zone, function(pos)
		FX.ripple(row, pos, Theme.Accent, { Radius = 8, Alpha = 0.9 })
		tb:CaptureFocus()
	end)
	connect(tb:GetPropertyChangedSignal("Text"), function()
		obj.Value = tb.Text
		if Library.Flags and obj.Flag then Library.Flags[obj.Flag] = tb.Text end
		if o.OnChanged then task.spawn(o.OnChanged, tb.Text) end
	end)
	connect(tb.Focused, function()
		tb.TextTruncate = Enum.TextTruncate.None
		tween(st, { Color = Theme.Accent }, 0.2)
		tween(line, { Size = UDim2.new(1, -12, 0, 2) }, 0.35, Enum.EasingStyle.Back)
		flashObj(row, "BackgroundColor3", Theme.Element:Lerp(Theme.Accent, 0.08), restElement, 0.1, 0.5)
	end)
	connect(tb.FocusLost, function()
		tb.TextTruncate = Enum.TextTruncate.AtEnd
		tween(st, { Color = Theme.Stroke }, 0.2)
		tween(line, { Size = UDim2.new(0, 0, 0, 2) }, 0.25, Enum.EasingStyle.Quint)
		obj.Value = tb.Text
		fire(obj, o)
		FX.pop(tb, 0.96, 0.4)
		FX.ring(Vector2.new(tb.AbsolutePosition.X + tb.AbsoluteSize.X / 2, tb.AbsolutePosition.Y + tb.AbsoluteSize.Y / 2), Theme.Accent, tb.AbsoluteSize.Y * 0.8, tb.AbsoluteSize.X * 1.05, 0.4, 0.75)
	end)
	function obj:Set(v, silent)
		self.Value = tostring(v or "")
		tb.Text = self.Value
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return tb.Text end
	register(obj, o)
	return obj
end

function Section:AddKeybind(o)
	local row = makeRow(self, 36)
	indexItem(self, o.Name, "Keybind", row, o.Icon)
	local kshift = rowIcon(row, o.Icon)
	local klbl = rowLabel(row, o.Name, UDim2.new(1, -126, 1, 0), kshift)
	local zone = hitZone(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(HIT_W, 36) })
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 24),
		AutomaticSize = AutoX, Bg = "Hover", Fg = "Text", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	corner(btn, 6)
	padding(btn, 10, 0, 10, 0)
	new("UISizeConstraint", { MinSize = Vector2.new(34, 24), MaxSize = Vector2.new(108, 24), Parent = btn })
	local lastKW = -1
	local function fitKeyLabel()
		local sc = math.max(getScale(), 0.05)
		local w = btn.AbsoluteSize.X / sc
		if math.abs(w - lastKW) < 1 then return end
		lastKW = w
		klbl.Size = UDim2.new(1, -(12 + kshift + w + 20), 1, 0)
	end
	connect(btn:GetPropertyChangedSignal("AbsoluteSize"), fitKeyLabel)
	task.defer(fitKeyLabel)
	local st = stroke(btn)

	local obj = { Type = "Keybind", Value = nil }
	local listening = false
	local pulse
	local function render(animate)
		btn.Text = listening and "..." or (obj.Value and obj.Value.Name or "None")
		tween(st, { Color = listening and Theme.Accent or Theme.Stroke }, 0.15)
		if animate then
			btn.TextTransparency = 1
			tween(btn, { TextTransparency = 0 }, 0.3)
		end
	end
	local function setListening(v)
		listening = v
		Library.Listening = v
		if pulse then
			pulse:Cancel()
			pulse = nil
		end
		st.Transparency = 0
		if v then
			pulse = TweenService:Create(st, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.75 })
			pulse:Play()
			FX.pop(btn, 0.92, 0.4)
		end
		render()
	end
	function obj:Set(v, silent)
		if type(v) == "string" then
			local ok, kc = pcall(function() return Enum.KeyCode[v] end)
			v = ok and kc or nil
		end
		local was = listening
		self.Value = v
		setListening(false)
		if self.Flag then Library.Flags[self.Flag] = self.Value end
		if not silent then
			render(true)
			if was then
				FX.pop(btn, 1.2, 0.5)
				local s = uiScale(btn)
				local c = Vector2.new(btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2, btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2)
				FX.ring(c, Theme.Accent, 16 * s, 52 * s, 0.45, 0.3)
				FX.burst(c, Theme.Accent, 5, 20 * s, { Size = 8 * s, Squash = 0.55 })
				flashObj(row, "BackgroundColor3", Theme.Element:Lerp(Theme.Accent, 0.12), restElement, 0.08, 0.5)
			end
		end
		if not silent and o.Changed then task.spawn(o.Changed, self.Value) end
	end
	function obj:Get() return self.Value end
	onClick(btn, function() setListening(true) end)
	onClick(zone, function(pos)
		FX.ripple(row, pos, Theme.Accent, { Radius = 8, Alpha = 0.85 })
		setListening(true)
	end)
	connect(UserInputService.InputBegan, function(i, gp)
		if listening then
			if i.UserInputType == Enum.UserInputType.Keyboard then
				if i.KeyCode == Enum.KeyCode.Escape then
					setListening(false)
				elseif i.KeyCode == Enum.KeyCode.Backspace then
					obj:Set(nil)
				else
					obj:Set(i.KeyCode)
				end
			end
			return
		end
		if not gp and obj.Value and i.KeyCode == obj.Value and o.Callback then
			task.spawn(o.Callback, obj.Value)
		end
	end)
	obj:Set(o.Default, true)
	register(obj, o)
	return obj
end

function Section:AddLabel(o)
	if type(o) == "string" then o = { Title = o } end
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Element", LayoutOrder = self:_next(), Parent = self.Content })
	corner(row, 8)
	padding(row, 12, 9, 12, 9)
	listLayout(row, 3)
	local title = new("TextLabel", { Text = o.Title or "", Font = FONT_BOLD, Fg = "Text", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, LayoutOrder = 1, Parent = row })
	local sub = new("TextLabel", { Text = o.Text or "", Fg = "SubText", TextSize = 11, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, LayoutOrder = 2, Visible = (o.Text ~= nil and o.Text ~= ""), Parent = row })
	local obj = { Type = "Label" }
	function obj:Set(t, s)
		if t ~= nil and title.Text ~= t then
			title.Text = t
			title.TextTransparency = 0.65
			tween(title, { TextTransparency = 0 }, 0.35)
		end
		if s ~= nil then
			if sub.Text ~= s then
				sub.Text = s
				sub.TextTransparency = 0.65
				tween(sub, { TextTransparency = 0 }, 0.35)
			end
			sub.Visible = s ~= ""
		end
	end
	function obj:SetLive(t, s)
		if t ~= nil and title.Text ~= t then title.Text = t end
		if s ~= nil then
			if sub.Text ~= s then sub.Text = s end
			sub.Visible = s ~= ""
		end
	end
	return obj
end
Section.AddParagraph = Section.AddLabel

function Section:AddDivider(text)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = self:_next(), Parent = self.Content })
	new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1), Bg = "Stroke", Parent = row })
	if text and text ~= "" then
		local l = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 14),
			AutomaticSize = AutoX, Bg = "Card", Text = text, Fg = "SubText", TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center, Parent = row,
		})
		padding(l, 8, 0, 8, 0)
	end
end

local LOG_COLORS = {
	info = Color3.fromRGB(96, 165, 250),
	ok = Color3.fromRGB(74, 190, 120),
	warn = Color3.fromRGB(235, 170, 60),
	err = Color3.fromRGB(226, 72, 80),
}

local function logEscape(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function Section:AddCheckbox(o)
	local row = makeRow(self, 40)
	indexItem(self, o.Name, "Checkbox", row, o.Icon)
	rowLabel(row, o.Name, UDim2.new(1, -56, 1, 0), rowIcon(row, o.Icon))

	local BS = 22
	local box = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(BS, BS),
		BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0, Parent = row,
	})
	corner(box, 7)
	local bst = new("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = box })
	gradient(box, 200)
	local tick = new("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0),
		Image = FX.Assets.tick, ImageTransparency = 1, Img = "AccentText", Parent = box,
	})
	local hit = hitZone(row)
	hoverRow(row, hit)

	local obj = { Type = "Checkbox", Value = o.Default and true or false }

	local function paint(instant)
		local on = obj.Value
		local t = instant and 0 or 0.16
		tween(box, { BackgroundColor3 = on and Theme.Accent or Theme.Hover }, t, Enum.EasingStyle.Quad)
		tween(bst, { Color = on and Theme.Accent or Theme.Stroke }, t, Enum.EasingStyle.Quad)
	end

	local function render(instant)
		local on = obj.Value
		paint(instant)
		if instant then
			tick.Rotation = 0
			tick.Size = on and UDim2.fromOffset(14, 14) or UDim2.fromOffset(0, 0)
			tick.ImageTransparency = on and 0 or 1
			return
		end
		if on then
			tick.Rotation = -70
			tween(tick, { Size = UDim2.fromOffset(14, 14), ImageTransparency = 0, Rotation = 0 }, 0.42, Enum.EasingStyle.Back)
			FX.pop(box, 0.8, 0.5)
		else
			tween(tick, { Size = UDim2.fromOffset(0, 0), ImageTransparency = 1, Rotation = 50 }, 0.18, Enum.EasingStyle.Quad)
			FX.pop(box, 0.9, 0.35)
		end
	end

	Hooks[#Hooks + 1] = function(instant) paint(instant) end

	local function play(on, click)
		if not click then return end
		FX.ripple(row, typeof(click) == "Vector2" and click or nil, Theme.Accent, { Radius = 8, Alpha = on and 0.8 or 0.9 })
		if on then
			local s = box.AbsoluteSize.X / BS
			if s <= 0 then return end
			local c = Vector2.new(box.AbsolutePosition.X + box.AbsoluteSize.X / 2, box.AbsolutePosition.Y + box.AbsoluteSize.Y / 2)
			FX.ring(c, Theme.Accent, 12 * s, 46 * s, 0.5, 0.25)
			FX.burst(c, Theme.Accent, 4, 22 * s, { Size = 8 * s, Squash = 0.6 })
		end
	end

	onHover(hit,
		function() FX.scaleTo(box, 1.1, 0.18, Enum.EasingStyle.Back) end,
		function() FX.scaleTo(box, 1, 0.2) end)
	connect(hit.MouseButton1Down, function() FX.scaleTo(box, 0.86, 0.07) end)
	connect(hit.MouseButton1Up, function() FX.scaleTo(box, IS_TOUCH and 1 or 1.1, 0.35, Enum.EasingStyle.Back) end)

	function obj:Set(v, silent, click)
		v = v and true or false
		local changed = v ~= self.Value
		self.Value = v
		if changed then
			render(false)
			play(v, click)
		end
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end
	onClick(hit, function(pos) obj:Set(not obj.Value, false, pos or true) end)
	render(true)
	register(obj, o)
	return obj
end

function Section:AddRadio(o)
	local opts = o.Options or {}
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Element", LayoutOrder = self:_next(), Parent = self.Content })
	corner(row, 8)
	padding(row, 0, 4, 0, 6)
	local rl = listLayout(row, 2)
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	indexItem(self, o.Name, "Radio", row, o.Icon)

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0, Parent = row })
	rowLabel(head, o.Name, UDim2.new(1, -24, 1, 0), rowIcon(head, o.Icon))

	local items = {}
	local obj = { Type = "Radio", Options = opts, Value = nil }

	local function paintColors(t)
		for i, it in ipairs(items) do
			local on = opts[i] == obj.Value
			tween(it.Stroke, { Color = on and Theme.Accent or Theme.Stroke }, t)
			tween(it.Label, { TextColor3 = on and Theme.Text or Theme.SubText }, t)
		end
	end

	local function paint(instant)
		for i, it in ipairs(items) do
			local on = opts[i] == obj.Value
			tween(it.Dot, { Size = on and UDim2.fromOffset(8, 8) or UDim2.fromOffset(0, 0) }, instant and 0 or (on and 0.38 or 0.16), on and Enum.EasingStyle.Back or Enum.EasingStyle.Quad)
		end
		paintColors(instant and 0 or 0.2)
	end

	Hooks[#Hooks + 1] = function(instant) paintColors(instant and 0 or 0.3) end

	for i, name in ipairs(opts) do
		local it = new("Frame", { Size = UDim2.new(1, -12, 0, 28), Bg = "Hover", BackgroundTransparency = 1, LayoutOrder = i, Parent = row })
		corner(it, 7)
		local ring = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(16, 16), Bg = "Element", Parent = it,
		})
		round(ring)
		local rst = new("UIStroke", { Color = Theme.Stroke, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = ring })
		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(0, 0), Bg = "Accent", Parent = ring,
		})
		round(dot)
		local lbl = new("TextLabel", {
			Text = tostring(name), TextColor3 = Theme.SubText, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -44, 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = it,
		})
		local hit = hitZone(it, { ZIndex = 3 })
		items[i] = { Frame = it, Ring = ring, Stroke = rst, Dot = dot, Label = lbl }
		onHover(hit,
			function()
				tween(it, { BackgroundTransparency = 0.5 }, 0.14)
				FX.scaleTo(ring, 1.14, 0.18, Enum.EasingStyle.Back)
			end,
			function()
				tween(it, { BackgroundTransparency = 1 }, 0.2)
				FX.scaleTo(ring, 1, 0.2)
			end)
		onClick(hit, function(pos) obj:Set(name, false, pos or true) end)
	end

	function obj:Set(v, silent, click)
		local idx = v ~= nil and table.find(opts, v) or nil
		if v ~= nil and not idx then return end
		local changed = v ~= self.Value
		self.Value = v
		if changed then
			paint(false)
			if idx and click then
				local it = items[idx]
				FX.ripple(it.Frame, typeof(click) == "Vector2" and click or nil, Theme.Accent, { Radius = 7, Alpha = 0.8 })
				local s = it.Ring.AbsoluteSize.X / 16
				if s > 0 then
					local c = Vector2.new(it.Ring.AbsolutePosition.X + it.Ring.AbsoluteSize.X / 2, it.Ring.AbsolutePosition.Y + it.Ring.AbsoluteSize.Y / 2)
					FX.ring(c, Theme.Accent, 10 * s, 40 * s, 0.45, 0.25)
				end
			end
		end
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end

	if o.Default ~= nil and table.find(opts, o.Default) then obj.Value = o.Default end
	paint(true)
	register(obj, o)
	return obj
end

function Section:AddSegmented(o)
	local opts = o.Options or {}
	local n = math.max(#opts, 1)
	local row = makeRow(self, 66)
	indexItem(self, o.Name, "Segmented", row, o.Icon)
	local sh = rowIcon(row, o.Icon, 17)
	rowLabel(row, o.Name, UDim2.new(1, -24, 0, 26), sh).Position = UDim2.fromOffset(12 + sh, 4)

	local track = new("Frame", { Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -20, 0, 26), Bg = "Hover", Parent = row })
	corner(track, 8)
	stroke(track)
	local ind = new("Frame", { Position = UDim2.new(0, 2, 0, 2), Size = UDim2.new(1 / n, -4, 1, -4), Bg = "Accent", Parent = track })
	corner(ind, 6)
	gradient(ind, 200)

	local obj = { Type = "Segmented", Options = opts, Value = nil }
	local labels = {}

	local function paintLabels(instant)
		local t = instant and 0 or 0.22
		for i, l in ipairs(labels) do
			local on = opts[i] == obj.Value
			tween(l, { TextColor3 = on and Theme.AccentText or Theme.SubText }, t)
		end
	end

	local function place(i, instant)
		local pos = UDim2.new((i - 1) / n, 2, 0, 2)
		if instant then
			ind.Position = pos
			return
		end
		tween(ind, { Position = pos }, 0.4, Enum.EasingStyle.Back)
		tween(ind, { Size = UDim2.new(1 / n, 4, 1, -4) }, 0.1, Enum.EasingStyle.Quad)
		task.delay(0.1, function()
			if ind.Parent then tween(ind, { Size = UDim2.new(1 / n, -4, 1, -4) }, 0.3, Enum.EasingStyle.Back) end
		end)
	end

	Hooks[#Hooks + 1] = function(instant) paintLabels(instant) end

	for i, name in ipairs(opts) do
		local lbl = new("TextLabel", {
			Text = tostring(name), Font = FONT_BOLD, TextSize = 11, TextColor3 = Theme.SubText, Position = UDim2.fromScale((i - 1) / n, 0),
			Size = UDim2.fromScale(1 / n, 1), TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2, Parent = track,
		})
		labels[i] = lbl
		local hit = hitZone(track, { Position = UDim2.fromScale((i - 1) / n, 0), Size = UDim2.fromScale(1 / n, 1), ZIndex = 4 })
		onHover(hit,
			function() if opts[i] ~= obj.Value then tween(lbl, { TextColor3 = Theme.Text }, 0.12) end end,
			function() paintLabels(false) end)
		onClick(hit, function(pos) obj:Set(name, false, pos or true) end)
	end

	function obj:Set(v, silent, click)
		local idx = v ~= nil and table.find(opts, v) or nil
		if not idx then return end
		local changed = v ~= self.Value
		self.Value = v
		if changed then
			place(idx, false)
			paintLabels(false)
			FX.pop(labels[idx], 1.3, 0.45)
			if click then
				FX.ripple(row, typeof(click) == "Vector2" and click or nil, Theme.Accent, { Radius = 8, Alpha = 0.85 })
			end
		end
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end

	local d = o.Default
	if d == nil or not table.find(opts, d) then d = opts[1] end
	obj.Value = d
	place(d ~= nil and table.find(opts, d) or 1, true)
	paintLabels(true)
	register(obj, o)
	return obj
end

function Section:AddChips(o)
	local opts = o.Options or {}
	local textService = game:GetService("TextService")
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Element", LayoutOrder = self:_next(), Parent = self.Content })
	corner(row, 8)
	padding(row, 12, 9, 12, 11)
	listLayout(row, 8)
	indexItem(self, o.Name, "Chips", row, o.Icon)

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = row })
	local sh = 0
	if o.Icon then
		makeIcon(head, o.Icon, 16, "SubText", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
		sh = 24
	end
	new("TextLabel", {
		Text = o.Name or "Chips", Fg = "Text", Position = UDim2.fromOffset(sh, 0), Size = UDim2.new(1, -(sh + 50), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	local counter = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(46, 18), Fg = "SubText", TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = head,
	})

	local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 2, Parent = row })
	local wl = listLayout(wrap, 6, Enum.FillDirection.Horizontal)
	wl.Wraps = true

	local sel, chips = {}, {}
	local obj = { Type = "Chips", Options = opts, Value = {} }

	local function collect()
		local out = {}
		for _, name in ipairs(opts) do
			if sel[name] then out[#out + 1] = name end
		end
		return out
	end

	local function paintChip(c, on, instant)
		local t = instant and 0 or 0.2
		tween(c.Frame, { BackgroundColor3 = on and Theme.Accent or Theme.Hover, TextColor3 = on and Theme.AccentText or Theme.SubText }, t)
		tween(c.Stroke, { Color = on and Theme.Accent or Theme.Stroke }, t)
	end

	local function refreshCount()
		counter.Text = tostring(#obj.Value) .. "/" .. tostring(#opts)
	end

	Hooks[#Hooks + 1] = function(instant)
		for _, name in ipairs(opts) do
			paintChip(chips[name], sel[name] and true or false, instant)
		end
	end

	local function flip(name, pos)
		sel[name] = (not sel[name]) or nil
		local on = sel[name] and true or false
		obj.Value = collect()
		paintChip(chips[name], on, false)
		refreshCount()
		local f = chips[name].Frame
		FX.pop(f, on and 0.82 or 0.92, 0.45)
		FX.ripple(f, pos, Theme.Accent, { Radius = 13, Alpha = 0.8, Time = 0.5 })
		fire(obj, o)
	end

	for i, name in ipairs(opts) do
		local text = tostring(name)
		local w = textService:GetTextSize(text, 11, FONT_BOLD, Vector2.new(1000, 26)).X + 26
		local f = new("TextLabel", {
			Text = text, Font = FONT_BOLD, TextSize = 11, TextColor3 = Theme.SubText, BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0,
			Size = UDim2.fromOffset(w, 26), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = i, Parent = wrap,
		})
		round(f)
		local st = new("UIStroke", { Color = Theme.Stroke, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f })
		local hit = hitZone(f, { ZIndex = 3 })
		chips[name] = { Frame = f, Stroke = st }
		onHover(hit,
			function() FX.scaleTo(f, 1.06, 0.16, Enum.EasingStyle.Back) end,
			function() FX.scaleTo(f, 1, 0.2) end)
		onClick(hit, function(pos) flip(name, pos) end)
	end

	function obj:Set(v, silent)
		sel = {}
		if type(v) == "table" then
			for _, name in ipairs(v) do
				if chips[name] then sel[name] = true end
			end
		end
		self.Value = collect()
		for _, name in ipairs(opts) do
			paintChip(chips[name], sel[name] and true or false, false)
		end
		refreshCount()
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end

	obj:Set(o.Default or {}, true)
	register(obj, o)
	return obj
end

function Section:AddStepper(o)
	local min, max, step = o.Min or 0, o.Max or 100, o.Step or o.Increment or 1
	local decimals = 0
	local frac = tostring(step):match("%.(%d+)")
	if frac then decimals = #frac end

	local row = makeRow(self, 40)
	indexItem(self, o.Name, "Stepper", row, o.Icon)
	rowLabel(row, o.Name, UDim2.new(1, -114, 1, 0), rowIcon(row, o.Icon))

	local grp = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(96, 28), Bg = "Hover", Parent = row })
	corner(grp, 8)
	stroke(grp)
	local valBox = new("Frame", { Position = UDim2.fromOffset(26, 0), Size = UDim2.fromOffset(44, 28), ClipsDescendants = true, Parent = grp })
	local valLbl = new("TextLabel", { Font = FONT_BOLD, Fg = "Text", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = valBox })

	local function mini(x, glyph)
		local b = new("Frame", { Position = UDim2.fromOffset(x, 2), Size = UDim2.fromOffset(24, 24), Bg = "Element", Parent = grp })
		corner(b, 6)
		local l = new("TextLabel", {
			Text = glyph, Font = FONT_BOLD, TextSize = 16, Fg = "Text", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = b,
		})
		local sc = new("UIScale", { Parent = b })
		local hit = hitZone(b, { ZIndex = 3 })
		return b, l, sc, hit
	end
	local minus, minusLbl, minusSc, minusHit = mini(2, "-")
	local plus, plusLbl, plusSc, plusHit = mini(70, "+")

	local obj = { Type = "Stepper", Value = min, Min = min, Max = max, Step = step }
	local ready = false

	local function limits()
		tween(minusLbl, { TextTransparency = obj.Value <= min and 0.65 or 0 }, 0.15)
		tween(plusLbl, { TextTransparency = obj.Value >= max and 0.65 or 0 }, 0.15)
	end

	function obj:Set(v, silent)
		v = math.clamp(tonumber(v) or min, min, max)
		v = math.floor((v - min) / step + 0.5) * step + min
		v = math.clamp(tonumber(string.format("%." .. decimals .. "f", v)), min, max)
		local old = self.Value
		self.Value = v
		valLbl.Text = string.format("%." .. decimals .. "f", v) .. (o.Suffix or "")
		if ready and v ~= old then
			local dir = v > old and 1 or -1
			valLbl.Position = UDim2.fromOffset(0, dir * 10)
			valLbl.TextTransparency = 0.7
			tween(valLbl, { Position = UDim2.fromOffset(0, 0), TextTransparency = 0 }, 0.3, Enum.EasingStyle.Back)
		end
		limits()
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end

	local function hold(hit, dir, btn, sc)
		local token = 0
		local st
		st = pressTrack(hit, function(pos)
			token += 1
			local my = token
			tween(sc, { Scale = 0.86 }, 0.06)
			FX.ripple(btn, pos, Theme.Accent, { Radius = 6, Alpha = 0.75, Time = 0.4 })
			obj:Set(obj.Value + dir * step)
			task.spawn(function()
				task.wait(0.42)
				local d = 0.14
				while token == my and st.Down do
					obj:Set(obj.Value + dir * step)
					d = math.max(0.035, d * 0.88)
					task.wait(d)
				end
			end)
		end, function()
			token += 1
			tween(sc, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		end)
		onHover(hit,
			function() tween(btn, { BackgroundColor3 = Theme.Stroke }, 0.12) end,
			function() tween(btn, { BackgroundColor3 = Theme.Element }, 0.18) end)
	end
	hold(minusHit, -1, minus, minusSc)
	hold(plusHit, 1, plus, plusSc)

	obj:Set(o.Default or min, true)
	ready = true
	register(obj, o)
	return obj
end

function Section:AddProgress(o)
	local min, max = o.Min or 0, o.Max or 100
	local row = makeRow(self, 52)
	indexItem(self, o.Name, "Progress", row, o.Icon)
	local sh = rowIcon(row, o.Icon, 17)
	rowLabel(row, o.Name, UDim2.new(1, -84, 0, 26), sh).Position = UDim2.fromOffset(12 + sh, 4)
	local pct = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.fromOffset(60, 26),
		TextXAlignment = Enum.TextXAlignment.Right, Fg = "SubText", TextSize = 12, Parent = row,
	})
	local track = new("Frame", { Position = UDim2.new(0, 12, 1, -20), Size = UDim2.new(1, -24, 0, 8), Bg = "Stroke", Parent = row })
	round(track)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), Bg = "Accent", ClipsDescendants = true, Parent = track })
	round(fill)
	gradient(fill, 175)
	local shine = new("Frame", { Position = UDim2.fromScale(-0.6, 0), Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = fill })
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = shine,
	})
	TweenService:Create(shine, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, 0.3), { Position = UDim2.fromScale(1.1, 0) }):Play()

	local obj = { Type = "Progress", Value = min }
	local nv = Instance.new("NumberValue")
	local tw
	connect(nv.Changed, function(x)
		pct.Text = string.format("%d%%", math.floor(x * 100 + 0.5))
	end)

	function obj:Set(v, instant)
		v = math.clamp(tonumber(v) or min, min, max)
		local old = self.Value
		self.Value = v
		local f = (v - min) / math.max(max - min, 1e-9)
		if tw then tw:Cancel() end
		if instant then
			fill.Size = UDim2.fromScale(f, 1)
			nv.Value = f
			return
		end
		tw = TweenService:Create(nv, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Value = f })
		tw:Play()
		tween(fill, { Size = UDim2.fromScale(f, 1) }, 0.5, Enum.EasingStyle.Quint)
		if v >= max and old < max then
			flashObj(row, "BackgroundColor3", Theme.Element:Lerp(Theme.Accent, 0.18), restElement, 0.1, 0.7)
			FX.shine(row, Theme.Accent, 8)
			local s = math.max(getScale(), 0.05)
			local c = Vector2.new(track.AbsolutePosition.X + track.AbsoluteSize.X, track.AbsolutePosition.Y + track.AbsoluteSize.Y / 2)
			FX.ring(c, Theme.Accent, 10 * s, 46 * s, 0.5, 0.2)
			FX.burst(c, Theme.Accent, 6, 28 * s, { Size = 8 * s, Squash = 0.6 })
			if o.OnComplete then task.spawn(o.OnComplete) end
		end
	end
	function obj:Get() return self.Value end

	obj:Set(o.Default or min, true)
	return obj
end

function Section:AddColorPicker(o)
	local row = makeRow(self, 40)
	indexItem(self, o.Name, "Color", row, o.Icon)
	rowLabel(row, o.Name, UDim2.new(1, -120, 1, 0), rowIcon(row, o.Icon))

	local sw = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(90, 26),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, Parent = row,
	})
	corner(sw, 8)
	local sst = stroke(sw)
	local hexLbl = new("TextLabel", {
		Font = FONT_BOLD, TextSize = 11, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(0, 0, 0), Parent = sw,
	})
	local hit = hitZone(row)
	hoverRow(row, hit)

	local obj = { Type = "Color", Value = Color3.new(1, 1, 1) }
	local h, s, v = 0, 0, 1
	local refreshPopup

	local function paint()
		local c = obj.Value
		tween(sw, { BackgroundColor3 = c }, 0.08, Enum.EasingStyle.Quad)
		hexLbl.Text = "#" .. c:ToHex():upper()
		hexLbl.TextColor3 = (c.R * 0.299 + c.G * 0.587 + c.B * 0.114) > 0.55 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	end

	local function apply(nh, ns, nv)
		h, s, v = nh, ns, nv
		obj.Value = Color3.fromHSV(h, s, v)
		paint()
		if refreshPopup then refreshPopup() end
		fire(obj, o)
	end

	function obj:Set(c, silent)
		if type(c) == "string" then
			local hx = c:gsub("#", "")
			if #hx ~= 6 or not hx:match("^%x+$") then return end
			c = Color3.fromHex(hx)
		end
		if typeof(c) ~= "Color3" then return end
		self.Value = c
		h, s, v = c:ToHSV()
		paint()
		if refreshPopup then refreshPopup() end
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end

	local isOpen = false
	local function open()
		closePopup()
		prune()
		isOpen = true
		local scale = getScale()
		local PW, PH = 208, 178
		local abs, size = sw.AbsolutePosition, sw.AbsoluteSize
		local up = (abs.Y + size.Y + 6 + PH * scale) > Gui.AbsoluteSize.Y
		local px = math.max(abs.X + size.X, PW * scale + 8)

		local blocker = new("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 50, Parent = Gui })
		local popup = new("Frame", {
			AnchorPoint = Vector2.new(1, up and 1 or 0), Position = UDim2.fromOffset(px, up and abs.Y - 6 or abs.Y + size.Y + 6),
			Size = UDim2.fromOffset(PW, 0), Bg = "Card", ClipsDescendants = true, ZIndex = 51, Parent = Gui,
		})
		corner(popup, 10)
		stroke(popup)
		new("UIScale", { Scale = scale, Parent = popup })

		local svBox = new("Frame", { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(PW - 20, 100), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Parent = popup })
		corner(svBox, 6)
		local white = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = svBox })
		corner(white, 6)
		new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = white })
		local black = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = svBox })
		corner(black, 6)
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = black })
		local cur = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s, 1 - v), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = obj.Value, BackgroundTransparency = 0, ZIndex = 3, Parent = svBox,
		})
		round(cur)
		new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = cur })

		local hueBar = new("Frame", { Position = UDim2.fromOffset(10, 118), Size = UDim2.fromOffset(PW - 20, 12), BackgroundColor3 = Color3.new(1, 1, 1), Parent = popup })
		round(hueBar)
		local kps = {}
		for k = 0, 6 do
			kps[#kps + 1] = ColorSequenceKeypoint.new(k / 6, Color3.fromHSV((k % 6) / 6, 1, 1))
		end
		new("UIGradient", { Color = ColorSequence.new(kps), Parent = hueBar })
		local hueKnob = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(h, 0.5), Size = UDim2.fromOffset(8, 18),
			BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 3, Parent = hueBar,
		})
		corner(hueKnob, 4)
		new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.4, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = hueKnob })

		local prev = new("Frame", { Position = UDim2.fromOffset(10, 142), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = obj.Value, Parent = popup })
		corner(prev, 7)
		stroke(prev)
		local hexBox = new("TextBox", {
			Position = UDim2.fromOffset(44, 142), Size = UDim2.fromOffset(PW - 54, 26), Bg = "Hover", Fg = "Text", Ph = "SubText",
			PlaceholderText = "#FFFFFF", Text = "#" .. obj.Value:ToHex():upper(), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
			ClipsDescendants = true, Parent = popup,
		})
		corner(hexBox, 7)
		local hst = stroke(hexBox)

		local conns = {}
		local function drag(area, fn)
			local active = false
			conns[#conns + 1] = area.InputBegan:Connect(function(i)
				if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
				active = true
				fn(i.Position.X, i.Position.Y)
				local c
				c = i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End or i.UserInputState == Enum.UserInputState.Cancel then
						active = false
						c:Disconnect()
					end
				end)
			end)
			conns[#conns + 1] = UserInputService.InputChanged:Connect(function(i)
				if active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
					fn(i.Position.X, i.Position.Y)
				end
			end)
		end

		drag(hitZone(svBox, { ZIndex = 4 }), function(x, y)
			local rx = math.clamp((x - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
			local ry = math.clamp((y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
			apply(h, rx, 1 - ry)
		end)
		drag(hitZone(hueBar, { ZIndex = 4 }), function(x)
			local rx = math.clamp((x - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 0.999)
			apply(rx, s, v)
		end)

		conns[#conns + 1] = hexBox.Focused:Connect(function() tween(hst, { Color = Theme.Accent }, 0.2) end)
		conns[#conns + 1] = hexBox.FocusLost:Connect(function()
			tween(hst, { Color = Theme.Stroke }, 0.2)
			local hx = hexBox.Text:gsub("#", "")
			if #hx == 6 and hx:match("^%x+$") then
				local nh, ns, nv = Color3.fromHex(hx):ToHSV()
				apply(nh, ns, nv)
			else
				hexBox.Text = "#" .. obj.Value:ToHex():upper()
			end
		end)

		refreshPopup = function()
			svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			cur.Position = UDim2.fromScale(s, 1 - v)
			cur.BackgroundColor3 = obj.Value
			hueKnob.Position = UDim2.fromScale(h, 0.5)
			prev.BackgroundColor3 = obj.Value
			if not hexBox:IsFocused() then hexBox.Text = "#" .. obj.Value:ToHex():upper() end
		end

		tween(popup, { Size = UDim2.fromOffset(PW, PH) }, 0.28, Enum.EasingStyle.Quint)
		tween(sst, { Color = Theme.Accent }, 0.2)
		FX.pop(cur, 0.3, 0.5)

		local scrollCon
		if self.Scroll then
			scrollCon = self.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup)
		end
		local function close()
			isOpen = false
			refreshPopup = nil
			if scrollCon then scrollCon:Disconnect() end
			for _, c in ipairs(conns) do c:Disconnect() end
			tween(sst, { Color = Theme.Stroke }, 0.2)
			tween(popup, { Size = UDim2.fromOffset(PW, 0) }, 0.15)
			blocker:Destroy()
			task.delay(0.18, function() popup:Destroy() end)
		end
		Library.OpenPopup = close
		onClick(blocker, closePopup)
	end

	onClick(hit, function(pos)
		FX.ripple(row, pos, Theme.Accent, { Radius = 8, Alpha = 0.85 })
		FX.pop(sw, 0.9, 0.35)
		if isOpen then closePopup() else open() end
	end)

	obj:Set(o.Default or Color3.fromRGB(255, 255, 255), true)
	register(obj, o)
	return obj
end

function Section:AddLog(o)
	o = o or {}
	local H = o.Height or 140
	local maxLines = o.MaxLines or 80
	local title = o.Name or "Console"
	local row = makeRow(self, H + 36)
	indexItem(self, title, "Log", row, o.Icon or "chat")
	local sh = rowIcon(row, o.Icon or "chat", 17)
	rowLabel(row, title, UDim2.new(1, -52, 0, 26), sh).Position = UDim2.fromOffset(12 + sh, 4)

	local clr = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 6), Size = UDim2.fromOffset(28, 22), Bg = "Hover", Parent = row })
	corner(clr, 6)
	stroke(clr)
	makeIcon(clr, "trash", 12, "SubText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	local clrHit = hitZone(clr, { ZIndex = 4 })

	local box = new("Frame", { Position = UDim2.fromOffset(8, 32), Size = UDim2.new(1, -16, 0, H), Bg = "Card", Parent = row })
	corner(box, 7)
	stroke(box)
	local sc = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY, ScrollBarThickness = 2, Sb = "Stroke", Parent = box,
	})
	padding(sc, 8, 6, 8, 6)
	listLayout(sc, 3)

	local lines, serial = {}, 0
	local obj = { Type = "Log" }

	function obj:Log(text, kind)
		kind = LOG_COLORS[kind or "info"] and (kind or "info") or "info"
		serial += 1
		local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = serial, Parent = sc })
		local lbl = new("TextLabel", {
			RichText = true, Fg = "Text", TextSize = 11, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
			Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextTransparency = 1, Parent = wrap,
			Text = string.format(
				'<font color="#%s">%s</font>  <font color="#%s"><b>%s</b></font>  %s',
				Theme.SubText:ToHex(), os.date("%H:%M:%S"), LOG_COLORS[kind]:ToHex(), string.upper(kind), logEscape(text)
			),
		})
		tween(lbl, { Position = UDim2.fromOffset(0, 0), TextTransparency = 0 }, 0.35, Enum.EasingStyle.Quint)
		lines[#lines + 1] = wrap
		while #lines > maxLines do
			local old = table.remove(lines, 1)
			pcall(function() old:Destroy() end)
		end
		task.delay(0.06, function()
			if not sc.Parent then return end
			local s = math.max(getScale(), 0.05)
			local maxY = math.max(0, (sc.AbsoluteCanvasSize.Y - sc.AbsoluteWindowSize.Y) / s)
			tween(sc, { CanvasPosition = Vector2.new(0, maxY) }, 0.25, Enum.EasingStyle.Quad)
		end)
	end

	function obj:Clear()
		for _, l in ipairs(lines) do pcall(function() l:Destroy() end) end
		lines = {}
	end

	onHover(clrHit,
		function() tween(clr, { BackgroundColor3 = Theme.Stroke }, 0.12) end,
		function() tween(clr, { BackgroundColor3 = Theme.Hover }, 0.18) end)
	onClick(clrHit, function(pos)
		FX.pop(clr, 0.7, 0.4)
		FX.ripple(clr, pos, Theme.Accent, { Radius = 6, Alpha = 0.8, Time = 0.4 })
		obj:Clear()
	end, true)

	return obj
end

local Tab = {}
Tab.__index = Tab

function Tab:_next()
	self.Order += 1
	return self.Order
end

function Tab:AddSection(o)
	o = o or {}
	local right = o.Side == "Right"
	if right and not self.RightUsed then
		self.RightUsed = true
		self.Right.Size = UDim2.new(0.5, -4, 0, 0)
		self.Right.Visible = true
		tween(self.Left, { Size = UDim2.new(0.5, -4, 0, 0) }, 0.3)
	end
	local col = right and self.Right or self.Left

	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Card", LayoutOrder = self:_next(),
		ClipsDescendants = true, Parent = col,
	})
	corner(card, 12)
	stroke(card)
	gradient(card, 225)
	listLayout(card, 0)

	local header = new("Frame", { Size = UDim2.new(1, 0, 0, SEC_H), LayoutOrder = 1, Parent = card })
	local hasIcon = o.Icon ~= nil
	local lx = hasIcon and 44 or 12
	local secBox
	if hasIcon then
		secBox = iconTile(header, o.Icon, 24, 14, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
	end
	new("TextLabel", {
		Text = o.Name or "Section", Font = FONT_BOLD, Fg = "Text", Position = UDim2.fromOffset(lx, 0),
		Size = UDim2.new(1, -(lx + 34), 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})
	local chev = makeIcon(header, "chevron", 14, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Rotation = o.Collapsed and 0 or 180 })
	local hz, hzone = hitZone(header, { Size = UDim2.fromScale(1, 1), ZIndex = 0 })
	bind(hzone, "BackgroundColor3", "Hover")
	hzone.BackgroundTransparency = 1
	onHover(hz,
		function() tween(hzone, { BackgroundTransparency = 0.6 }, 0.15) end,
		function() tween(hzone, { BackgroundTransparency = 1 }, 0.2) end)

	local content = new("CanvasGroup", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 2, Parent = card })
	padding(content, 8, 0, 8, 8)
	local layout = listLayout(content, 5)

	local sec = setmetatable({
		Tab = self, Name = o.Name or "Section", Content = content, Scroll = self.Scroll, Order = 0,
		Collapsed = o.Collapsed and true or false, _tok = 0,
	}, Section)

	if sec.Collapsed then
		content.AutomaticSize = AutoNone
		content.Size = UDim2.new(1, 0, 0, 0)
	end

	local function apply()
		sec._tok += 1
		local tok = sec._tok
		local s = math.max(getScale(), 0.05)
		if sec.Collapsed then
			local cur = content.AbsoluteSize.Y / s
			content.AutomaticSize = AutoNone
			content.Size = UDim2.new(1, 0, 0, cur)
			tween(content, { Size = UDim2.new(1, 0, 0, 0) }, 0.22)
		else
			local target = layout.AbsoluteContentSize.Y / s + 8
			content.AutomaticSize = AutoNone
			local t = tween(content, { Size = UDim2.new(1, 0, 0, target) }, 0.3, Enum.EasingStyle.Back)
			t.Completed:Connect(function()
				if sec._tok == tok and not sec.Collapsed then
					content.AutomaticSize = AutoY
				end
			end)
		end
	end
	function sec:SetCollapsed(v)
		v = v and true or false
		if self.Collapsed == v then return end
		self.Collapsed = v
		tween(chev, { Rotation = v and 0 or 180 }, 0.4, Enum.EasingStyle.Back)
		apply()
	end
	onClick(hz, function(pos)
		FX.ripple(header, pos, Theme.Accent, { Radius = 10, Alpha = 0.85, Time = 0.55 })
		if secBox then FX.pop(secBox, 1.3, 0.45) end
		closePopup()
		sec:SetCollapsed(not sec.Collapsed)
	end)
	if self.Window and self.Window._register then
		self.Window:_register({ Name = sec.Name, Kind = "Section", Tab = self, Section = sec, Row = card, Icon = o.Icon })
	end
	return sec
end

local Window = {}
Window.__index = Window

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function fitScale()
	local vp = viewport()
	return math.min(1, vp.X * 0.85 / BASE_W, vp.Y * 0.88 / BASE_H)
end

local function maxScale()
	local vp = viewport()
	return math.min(2, vp.X * 0.97 / BASE_W, vp.Y * 0.95 / BASE_H)
end

local PAGE_REST = UDim2.fromScale(0.5, 0.5)
local TABCLIP_Y = 54

local function relayoutSub(tab)
	if not tab.SubFrame then return end
	local n = 0
	for _, c in ipairs(tab.Children) do
		if c.Button.Visible then n += 1 end
	end
	local open = tab.Expanded or tab.Window.Searching
	local h = (n > 0 and open) and (n * 28 + (n - 1) * 3 + 6) or 0
	local sf = tab.SubFrame
	tab.SubTok = (tab.SubTok or 0) + 1
	local tok = tab.SubTok
	if h > 0 then sf.Visible = true end
	tween(sf, { Size = UDim2.new(1, 0, 0, h) }, 0.28, Enum.EasingStyle.Quint)
	if h == 0 then
		task.delay(0.3, function()
			if tab.SubTok == tok and sf.Parent then sf.Visible = false end
		end)
	end
end

function Library._toggleSub(tab)
	if #tab.Children == 0 then return end
	tab.Expanded = not tab.Expanded
	if tab.Chevron then tween(tab.Chevron, { Rotation = tab.Expanded and 180 or 0 }, 0.4, Enum.EasingStyle.Back) end
	relayoutSub(tab)
end

local function paintTab(tab, instant)
	local t = instant and 0 or 0.2
	local on = tab.Active
	tween(tab.Button, { BackgroundTransparency = on and 0 or 1 }, t)
	tween(tab.Bar, { Size = UDim2.fromOffset(3, on and 16 or 0) }, t, Enum.EasingStyle.Back)
	tween(tab.Label, { TextColor3 = on and Theme.Text or Theme.SubText }, t)
	if tab.Icon then
		tween(tab.IconTile, { BackgroundColor3 = on and Theme.Accent or Theme.Hover }, t)
		tintIcon(tab.Icon, on and Theme.AccentText or Theme.SubText, t)
	end
end

function Window:_sub(parentTab)
	if parentTab.SubFrame then return parentTab.SubFrame end
	local sf = new("CanvasGroup", { Size = UDim2.new(1, 0, 0, 0), Visible = false, LayoutOrder = 2, Parent = parentTab.Holder })
	listLayout(sf, 3)
	padding(sf, 14, 3, 0, 0)
	parentTab.SubFrame = sf
	parentTab.Chevron = makeIcon(parentTab.Button, "chevron", 12, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) })
	local zh = hitZone(parentTab.Button, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(40, 34) })
	onClick(zh, function() Library._toggleSub(parentTab) end)
	return sf
end

function Window:AddTab(opts)
	opts = opts or {}
	local parentTab = opts.Parent
	local isSub = parentTab ~= nil

	if not isSub and opts.Group and opts.Group ~= self.LastGroup then
		self.LastGroup = opts.Group
		self.TabOrder += 1
		local gl = new("TextLabel", { Text = string.upper(opts.Group), Font = FONT_BOLD, TextSize = 10, Fg = "SubText", Size = UDim2.new(1, 0, 0, 24), LayoutOrder = self.TabOrder, Parent = self.TabList })
		padding(gl, 6, 8, 0, 0)
		table.insert(self.GroupLabels, gl)
	end

	local tab = setmetatable({
		Window = self, Name = opts.Name or "Tab", Children = {}, ParentTab = parentTab, Active = false, Order = 0,
		Expanded = false, Index = #self.Tabs + 1,
	}, Tab)
	local container, layoutOrder
	if isSub then
		container = self:_sub(parentTab)
		table.insert(parentTab.Children, tab)
		layoutOrder = #parentTab.Children
	else
		self.TabOrder += 1
		tab.Holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = self.TabOrder, Parent = self.TabList })
		listLayout(tab.Holder, 3)
		container, layoutOrder = tab.Holder, 1
	end

	local h = isSub and 28 or 34
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, h), Bg = "Element", BackgroundTransparency = 1, LayoutOrder = layoutOrder, Parent = container })
	corner(btn, 9)
	local bar = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(3, 0), Bg = "Accent", Parent = btn })
	corner(bar, 2)
	local hasIcon = opts.Icon ~= nil
	if hasIcon then
		local ts = isSub and 20 or 24
		local is = isSub and 12 or 14
		tab.IconTile, tab.Icon = iconTile(btn, opts.Icon, ts, is, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) }, true)
	end
	local lblX = hasIcon and (isSub and 36 or 42) or 12
	tab.LabelX = lblX
	local hasChevSpace = 26
	tab.Label = new("TextLabel", {
		Text = tab.Name, TextColor3 = Theme.SubText, TextSize = isSub and 12 or 13,
		Position = UDim2.fromOffset(lblX, 0), Size = UDim2.new(1, -(lblX + hasChevSpace), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	tab.Button, tab.Bar = btn, bar
	Hooks[#Hooks + 1] = function() paintTab(tab, false) end

	onHover(btn,
		function()
			if not tab.Active then tween(btn, { BackgroundTransparency = 0.55 }, 0.15) end
			tween(tab.Label, { Position = UDim2.fromOffset(lblX + 3, 0) }, 0.18)
		end,
		function()
			if not tab.Active then tween(btn, { BackgroundTransparency = 1 }, 0.2) end
			tween(tab.Label, { Position = UDim2.fromOffset(lblX, 0) }, 0.2)
		end)

	if opts.NoPage ~= true then
		local holder = new("CanvasGroup", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = PAGE_REST, Size = UDim2.fromScale(1, 1),
			Visible = false, GroupTransparency = 1, Parent = self.Content,
		})
		tab.PageScale = new("UIScale", { Parent = holder })
		local scroll = new("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
			ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, Sb = "Stroke", Parent = holder,
		})
		padding(scroll, 10, 10, 12, 10)
		listLayout(scroll, 10)
		if opts.Description then
			local hdr = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 0, Parent = scroll })
			listLayout(hdr, 2)
			new("TextLabel", { Text = tab.Name, Font = FONT_BOLD, TextSize = 20, Fg = "Text", Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = hdr })
			new("TextLabel", { Text = opts.Description, TextSize = 12, Fg = "SubText", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, TextWrapped = true, LayoutOrder = 2, Parent = hdr })
		end
		local cols = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 1, Parent = scroll })
		listLayout(cols, 8, Enum.FillDirection.Horizontal)
		local left = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 1, Parent = cols })
		listLayout(left, 8)
		local right = new("Frame", { Size = UDim2.new(0, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 2, Visible = false, Parent = cols })
		listLayout(right, 8)
		tab.Page, tab.Scroll, tab.Left, tab.Right = holder, scroll, left, right
	end

	onClick(btn, function(pos)
		FX.ripple(btn, pos, Theme.Accent, { Radius = 9, Alpha = 0.8, Time = 0.55 })
		if tab.Page then
			self:SelectTab(tab)
		else
			Library._toggleSub(tab)
		end
	end)

	self:_register({ Name = tab.Name, Kind = "Tab", Tab = tab, Icon = opts.Icon })
	if isSub then relayoutSub(parentTab) end
	table.insert(self.Tabs, tab)
	if not self.Current and tab.Page then self:SelectTab(tab, true) end
	return tab
end

function Tab:AddSubTab(opts)
	opts = opts or {}
	opts.Parent = self
	return self.Window:AddTab(opts)
end

function Window:SelectTab(tab, instant)
	if not tab.Page then return end
	if self.SearchOpen then
		self:ClearSearch(true)
		if self.Current == tab then self:_restorePage() end
	end
	if self.Current == tab then return end
	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	local old = self.Current
	self.Current = tab
	local dir = (old and old.Index and tab.Index < old.Index) and -1 or 1
	if old then
		old.Active = false
		paintTab(old, false)
		local pg = old.Page
		tween(pg, { GroupTransparency = 1 }, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(old.PageScale, { Scale = 0.985 }, 0.16)
		task.delay(0.17, function()
			if not old.Active then
				pg.Visible = false
				pg.Position = PAGE_REST
				old.PageScale.Scale = 1
			end
		end)
	end
	tab.Active = true
	paintTab(tab, instant)
	local pg = tab.Page
	pg.Visible = true
	if instant then
		pg.GroupTransparency = 0
		pg.Position = PAGE_REST
		tab.PageScale.Scale = 1
	else
		pg.GroupTransparency = 1
		pg.Position = PAGE_REST
		tab.PageScale.Scale = 0.985
		tween(pg, { GroupTransparency = 0, Position = PAGE_REST }, 0.32, Enum.EasingStyle.Quint)
		tween(tab.PageScale, { Scale = 1 }, 0.4, Enum.EasingStyle.Back)
		if tab.IconTile then FX.pop(tab.IconTile, 1.3, 0.5) end
		tab.Label.Position = UDim2.fromOffset(tab.LabelX + 6, 0)
		tween(tab.Label, { Position = UDim2.fromOffset(tab.LabelX, 0) }, 0.45, Enum.EasingStyle.Back)
	end
end

local KIND_LABEL = {
	Toggle = "Switch", Slider = "Slider", Dropdown = "Dropdown", Button = "Button", Textbox = "Input",
	Keybind = "Keybind", Tab = "Tab", Section = "Section", Action = "Action", Card = "Card",
	Checkbox = "Checkbox", Radio = "Radio", Segmented = "Segmented", Chips = "Chips", Stepper = "Stepper",
	Progress = "Progress", Color = "Color", Log = "Console",
}
local KIND_ICON = {
	Toggle = "toggle", Slider = "slider", Dropdown = "list", Button = "click", Textbox = "input",
	Keybind = "keyboard", Tab = "grid", Section = "columns", Action = "bolt", Card = "grid",
	Checkbox = "check", Radio = "list", Segmented = "columns", Chips = "hash", Stepper = "plus",
	Progress = "pulse", Color = "palette", Log = "chat",
}
local KIND_RANK = { Tab = 1, Section = 2, Card = 2, Action = 3 }
local MAX_RESULTS = 40

local function esc(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function markMatch(name, token)
	if not token or token == "" then return esc(name) end
	local s, e = name:lower():find(token, 1, true)
	if not s then return esc(name) end
	return esc(name:sub(1, s - 1))
		.. '<font color="#' .. Theme.Accent:ToHex() .. '"><b>' .. esc(name:sub(s, e)) .. "</b></font>"
		.. esc(name:sub(e + 1))
end

local function pathOf(it)
	local parts = {}
	local t = it.Tab
	if t and t.ParentTab then parts[#parts + 1] = t.ParentTab.Name end
	if t and it.Kind ~= "Tab" then parts[#parts + 1] = t.Name end
	if it.Extra then
		parts[#parts + 1] = it.Extra
	elseif it.Section and it.Kind ~= "Section" and it.Section.Name then
		parts[#parts + 1] = it.Section.Name
	end
	if #parts == 0 then return "Page" end
	return table.concat(parts, "  /  ")
end

local function flashRow(obj)
	if not obj or not obj.Parent then return end
	local rest = obj.BackgroundColor3
	local hot = rest:Lerp(Theme.Accent, 0.3)
	for k = 0, 1 do
		task.delay(k * 0.45, function()
			if not obj.Parent then return end
			tween(obj, { BackgroundColor3 = hot }, 0.12, Enum.EasingStyle.Quad)
			task.delay(0.14, function()
				if obj.Parent then tween(obj, { BackgroundColor3 = rest }, 0.3, Enum.EasingStyle.Quad) end
			end)
		end)
	end
	if not obj:FindFirstChildOfClass("UIListLayout") then
		FX.ripple(obj, nil, Theme.Accent, { Radius = 10, Alpha = 0.78, Time = 0.7 })
	end
end

function Window:_register(it)
	if not it or not it.Name or tostring(it.Name) == "" then return end
	it.Name = tostring(it.Name)
	it.Lower = it.Name:lower()
	self.Index[#self.Index + 1] = it
end

function Window:_search(q)
	local tokens = {}
	for w in q:gmatch("%S+") do tokens[#tokens + 1] = w end
	local out = {}
	if #tokens == 0 then return out end
	for _, it in ipairs(self.Index) do
		if not it.Row or it.Row.Parent then
			local name = it.Lower
			local kind = (KIND_LABEL[it.Kind] or it.Kind):lower()
			local score, ok = 0, true
			for _, tk in ipairs(tokens) do
				local p = name:find(tk, 1, true)
				if p then
					local s = 40
					if name == tk then
						s = 100
					elseif p == 1 then
						s = 80
					elseif name:sub(p - 1, p - 1):match("[%s%p]") then
						s = 60
					end
					score += s
				elseif kind:find(tk, 1, true) == 1 then
					score += 10
				else
					ok = false
					break
				end
			end
			if ok then
				out[#out + 1] = {
					Name = it.Name, Kind = it.Kind, Tab = it.Tab, Section = it.Section, Row = it.Row,
					Icon = it.Icon, Extra = it.Extra, Score = score, Mark = tokens[1],
				}
			end
		end
	end
	table.sort(out, function(a, b)
		if a.Score ~= b.Score then return a.Score > b.Score end
		local ra, rb = KIND_RANK[a.Kind] or 9, KIND_RANK[b.Kind] or 9
		if ra ~= rb then return ra < rb end
		return a.Name:lower() < b.Name:lower()
	end)
	while #out > MAX_RESULTS do table.remove(out) end
	return out
end

function Window:_paintSel(scrollTo)
	if not IS_TOUCH then
		for i, row in ipairs(self._srRows) do
			local on = i == self._sel
			tween(row.Frame, { BackgroundColor3 = on and Theme.Hover or Theme.Element }, 0.12)
			tween(row.Stroke, { Color = on and Theme.Accent or Theme.Stroke }, 0.12)
		end
	end
	local row, sc = self._srRows[self._sel], self.SearchScroll
	if scrollTo and row and sc then
		local s = math.max(getScale(), 0.05)
		local top = (row.Frame.AbsolutePosition.Y - sc.AbsolutePosition.Y) / s
		local h = row.Frame.AbsoluteSize.Y / s
		local view = sc.AbsoluteWindowSize.Y / s
		local cp = sc.CanvasPosition.Y
		if top < 12 then
			cp = cp + top - 12
		elseif top + h > view - 12 then
			cp = cp + top + h - view + 12
		end
		tween(sc, { CanvasPosition = Vector2.new(0, math.max(cp, 0)) }, 0.15, Enum.EasingStyle.Quad)
	end
end

function Window:_moveSel(d)
	local n = #self._srRows
	if n == 0 then return end
	self._sel = ((self._sel - 1 + d) % n) + 1
	self:_paintSel(true)
end

function Window:_renderResults(q, results)
	local scroll = self.SearchScroll
	if not scroll then return end
	self._rrTok = (self._rrTok or 0) + 1
	for _, c in ipairs(self._srConns) do pcall(function() c:Disconnect() end) end
	self._srConns = {}
	for _, r in ipairs(self._srRows) do pcall(function() r.Frame:Destroy() end) end
	if self._srEmpty then
		pcall(function() self._srEmpty:Destroy() end)
		self._srEmpty = nil
	end
	self._srRows = {}
	prune()
	self._sel = 1

	local n = #results
	self.SearchInfo.Text = n == 0 and ('Nothing found for "' .. q .. '"')
		or string.format('%d result%s for "%s"', n, n == 1 and "" or "s", q)

	Library._sink = self._srConns
	local ok, err = pcall(function()
		if n == 0 then
			local empty = new("Frame", { Size = UDim2.new(1, 0, 0, 150), LayoutOrder = 1, Parent = scroll })
			local box = iconTile(empty, "search", 44, 24, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 26) })
			new("TextLabel", {
				Text = "No matches", Font = FONT_BOLD, TextSize = 14, Fg = "Text", AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 82), Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Center, Parent = empty,
			})
			new("TextLabel", {
				Text = "Try another word: a tab, a section or a setting name.", Fg = "SubText", TextSize = 11, TextWrapped = true,
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 102), Size = UDim2.new(1, -40, 0, 30),
				TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, Parent = empty,
			})
			FX.pop(box, 0.6, 0.5)
			self._srEmpty = empty
			return
		end
		local function build(i, r)
			local f = new("Frame", { Size = UDim2.new(1, 0, 0, 46), Bg = "Element", LayoutOrder = i, Parent = scroll })
			corner(f, 10)
			local st = stroke(f)
			gradient(f, 205)
			iconTile(f, r.Icon or KIND_ICON[r.Kind] or "info", 28, 15, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
			new("TextLabel", {
				RichText = true, Text = markMatch(r.Name, r.Mark), Fg = "Text", TextSize = 13, Position = UDim2.fromOffset(46, 6),
				Size = UDim2.new(1, -(46 + 96), 0, 17), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
			})
			new("TextLabel", {
				Text = pathOf(r), Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(46, 24),
				Size = UDim2.new(1, -(46 + 96), 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
			})
			local badge = new("TextLabel", {
				Text = KIND_LABEL[r.Kind] or r.Kind, Font = FONT_BOLD, TextSize = 9, Fg = "SubText", Bg = "Hover",
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 18),
				AutomaticSize = AutoX, TextXAlignment = Enum.TextXAlignment.Center, Parent = f,
			})
			round(badge)
			padding(badge, 8, 0, 8, 0)
			local hit = hitZone(f, { ZIndex = 6 })
			onHover(hit,
				function()
					self._sel = i
					self:_paintSel(false)
				end,
				function() end)
			onClick(hit, function(pos)
				FX.ripple(f, pos, Theme.Accent, { Radius = 10, Alpha = 0.8, Time = 0.45 })
				self:_goto(r)
			end)
			self._srRows[i] = { Frame = f, Stroke = st }
		end
		local FIRST, CHUNK = 8, 6
		for i = 1, math.min(FIRST, n) do build(i, results[i]) end
		self:_paintSel(false)
		if n > FIRST then
			local myTok = self._rrTok
			task.spawn(function()
				local nextI = FIRST + 1
				while nextI <= n do
					task.wait()
					if self._rrTok ~= myTok or not self.SearchOpen or not scroll.Parent then return end
					Library._sink = self._srConns
					local ok2, err2 = pcall(function()
						for i = nextI, math.min(nextI + CHUNK - 1, n) do build(i, results[i]) end
					end)
					Library._sink = nil
					if not ok2 then
						warn("[ZystrixUI] search render: " .. tostring(err2))
						return
					end
					nextI += CHUNK
				end
				if self._rrTok == myTok then self:_paintSel(false) end
			end)
		end
	end)
	Library._sink = nil
	if not ok then warn("[ZystrixUI] search render: " .. tostring(err)) end
end

function Window:_restorePage()
	local cur = self.Current
	if cur and cur.Page then
		cur.Page.Visible = true
		tween(cur.Page, { GroupTransparency = 0 }, 0.24, Enum.EasingStyle.Quad)
	end
end

function Window:_openSearchPage()
	local sp = self.SearchPage
	if not sp or self.SearchOpen then return end
	self.SearchOpen = true
	self._srTok += 1
	local tok = self._srTok
	local cur = self.Current
	if cur and cur.Page then
		tween(cur.Page, { GroupTransparency = 1 }, 0.16, Enum.EasingStyle.Quad)
		task.delay(0.17, function()
			if self._srTok == tok and self.SearchOpen and self.Current == cur then cur.Page.Visible = false end
		end)
	end
	closePopup()
	sp.Visible = true
	sp.Position = UDim2.new(0.5, 0, 0.5, 12)
	tween(sp, { GroupTransparency = 0, Position = PAGE_REST }, 0.3, Enum.EasingStyle.Quint)
end

function Window:_closeSearchPage(restore)
	local sp = self.SearchPage
	if not sp or not self.SearchOpen then return end
	self.SearchOpen = false
	self._srTok += 1
	local tok = self._srTok
	tween(sp, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 8) }, 0.18, Enum.EasingStyle.Quad)
	task.delay(0.2, function()
		if self._srTok == tok and not self.SearchOpen then
			sp.Visible = false
			sp.Position = PAGE_REST
		end
	end)
	if restore then self:_restorePage() end
end

function Window:_queueFilter(q)
	self._qTok = (self._qTok or 0) + 1
	local tok = self._qTok
	if q == "" then
		self._pendingQ = nil
		self:_filter("")
		return
	end
	self._pendingQ = q
	task.delay(0.12, function()
		if self._qTok == tok and self._pendingQ ~= nil then
			local p = self._pendingQ
			self._pendingQ = nil
			self:_filter(p)
		end
	end)
end

function Window:_flushFilter()
	if self._pendingQ ~= nil then
		local p = self._pendingQ
		self._pendingQ = nil
		self._qTok = (self._qTok or 0) + 1
		self:_filter(p)
	end
end

function Window:ClearSearch(noRestore)
	self._pendingQ = nil
	self._qTok = (self._qTok or 0) + 1
	if self.SearchOpen then self:_closeSearchPage(not noRestore) end
	if self.SearchBox and self.SearchBox.Text ~= "" then self.SearchBox.Text = "" end
	self:_filter("")
end

function Window:_reveal(r)
	local tab, target, sec = r.Tab, r.Row, r.Section
	if not tab or not target or not target.Parent then return end
	local wait = 0.45
	if sec and sec.Collapsed and sec.SetCollapsed then
		sec:SetCollapsed(false)
		wait = 0.75
	end
	task.delay(wait, function()
		local scroll = tab.Scroll
		if not (scroll and target.Parent and tab.Active) then return end
		local s = math.max(getScale(), 0.05)
		local dy = (target.AbsolutePosition.Y - scroll.AbsolutePosition.Y) / s
		local ny = math.max(0, scroll.CanvasPosition.Y + dy - 14)
		tween(scroll, { CanvasPosition = Vector2.new(0, ny) }, 0.4, Enum.EasingStyle.Quint)
		task.delay(0.3, function() flashRow(target) end)
	end)
end

function Window:_goto(r)
	local tab = r.Tab
	if not tab then return end
	if self.SearchBox then pcall(function() self.SearchBox:ReleaseFocus() end) end
	self:ClearSearch(true)
	if self.Minimized then self:SetMinimized(false) end
	if not tab.Page then
		tab = tab.Children[1]
		if not tab then return end
	end
	if tab.ParentTab and not tab.ParentTab.Expanded then Library._toggleSub(tab.ParentTab) end
	if self.Current == tab then
		self:_restorePage()
	else
		self:SelectTab(tab)
	end
	if r.Row then
		self:_reveal({ Tab = tab, Row = r.Row, Section = r.Section })
	end
end

function Window:_filter(q)
	q = (tostring(q or ""):lower():gsub("^%s+", ""):gsub("%s+$", ""))
	if q == self._lastQ then return end
	self._lastQ = q
	local searching = q ~= ""
	self.Searching = searching
	for _, gl in ipairs(self.GroupLabels) do gl.Visible = not searching end

	if not searching then
		for _, t in ipairs(self.Tabs) do
			if not t.ParentTab then
				t.Holder.Visible = true
				for _, c in ipairs(t.Children) do c.Button.Visible = true end
				relayoutSub(t)
			end
		end
		self.SearchResults = {}
		self:_closeSearchPage(true)
		return
	end

	local results = self:_search(q)
	self.SearchResults = results
	local anyHit, nameHit = {}, {}
	for _, r in ipairs(results) do
		if r.Tab then
			anyHit[r.Tab] = true
			if r.Kind == "Tab" then nameHit[r.Tab] = true end
		end
	end
	for _, t in ipairs(self.Tabs) do
		if not t.ParentTab then
			local childAny = false
			for _, c in ipairs(t.Children) do
				local show = (anyHit[c] or nameHit[t]) and true or false
				c.Button.Visible = show
				if anyHit[c] then childAny = true end
			end
			t.Holder.Visible = (anyHit[t] or nameHit[t] or childAny) and true or false
		end
	end
	for _, t in ipairs(self.Tabs) do
		if not t.ParentTab then relayoutSub(t) end
	end
	self:_openSearchPage()
	self:_renderResults(q, results)
end

function Window:SetMinimized(state)
	state = state and true or false
	if state == self.Minimized then return end

	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	self.Minimized = state
	self:_setLoops(self.Visible and not state)
	self._minTok = (self._minTok or 0) + 1
	local tok = self._minTok

	local delta = (BASE_H - (HEADER_H + 1)) * ScaleObj.Scale / 2
	local p = (self._minBusy and self._posGoal) or self.Main.Position
	local goal = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, state and (p.Y.Offset - delta) or (p.Y.Offset + delta))
	self._posGoal, self._minBusy = goal, true
	task.delay(0.5, function()
		if self._minTok == tok then self._minBusy = false end
	end)
	if not state then self.Body.Visible = true end
	tween(self.Main, {
		Size = UDim2.fromOffset(BASE_W, state and (HEADER_H + 1) or BASE_H),
		Position = goal,
	}, 0.38, state and Enum.EasingStyle.Quint or Enum.EasingStyle.Back)
	if state then
		task.delay(0.36, function()
			if self._minTok == tok and self.Minimized then self.Body.Visible = false end
		end)
	end
end

function Window:SetMaximized(state)
	state = state and true or false
	if state == self.Maximized then return end
	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	self.Maximized = state
	self._minBusy = false
	if self.Minimized then
		self.Minimized = false
		self:_setLoops(self.Visible)
		self._minTok = (self._minTok or 0) + 1
		self.Body.Visible = true
		tween(self.Main, { Size = UDim2.fromOffset(BASE_W, BASE_H) }, 0.35)
	end
	tween(ScaleObj, { Scale = state and maxScale() or fitScale() }, 0.45, Enum.EasingStyle.Back)
	tween(self.Main, { Position = UDim2.fromScale(0.5, 0.5) }, 0.4)
end

function Window:_setLoops(on)
	for _, tw in ipairs(self._loops or {}) do
		pcall(function()
			if on then tw:Play() else tw:Pause() end
		end)
	end
end

function Window:Toggle(state)
	if state == nil then state = not self.Visible end
	if state == self.Visible then return end
	self.Visible = state
	self.FxShow = state
	self:_setLoops(state and not self.Minimized)
	if self.OnToggle then pcall(self.OnToggle, state) end
	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	self._tgTok = (self._tgTok or 0) + 1
	local tok = self._tgTok
	local target = self.Maximized and maxScale() or fitScale()
	local main, canvas, rim, shadow, ctrls = self.Main, self.Canvas, self.OutlineStroke, self.Shadow, self.Ctrls
	if not self._restPos then self._restPos = (self._minBusy and self._posGoal) or main.Position end
	local rest = self._restPos
	local lowered = UDim2.new(rest.X.Scale, rest.X.Offset, rest.Y.Scale, rest.Y.Offset + 22)
	if state then
		main.Visible = true
		main.Position = lowered
		ScaleObj.Scale = target * 0.86
		canvas.GroupTransparency = 1
		if rim then rim.Transparency = 1 end
		if shadow then shadow:Set(false) end
		if ctrls then ctrls.Visible = false end
		tween(main, { Position = rest }, 0.5, Enum.EasingStyle.Quint)
		tween(ScaleObj, { Scale = target }, 0.45, Enum.EasingStyle.Back)
		tween(canvas, { GroupTransparency = 0 }, 0.26, Enum.EasingStyle.Quad)
		if rim then tween(rim, { Transparency = 0 }, 0.35, Enum.EasingStyle.Quad) end
		if shadow then shadow:Fade(true, 0.4) end
		task.delay(0.12, function()
			if self._tgTok == tok and ctrls then ctrls.Visible = true end
		end)
		task.delay(0.55, function()
			if self._tgTok == tok then self._restPos = nil end
		end)
	else
		if ctrls then ctrls.Visible = false end
		tween(main, { Position = lowered }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(ScaleObj, { Scale = target * 0.86 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(canvas, { GroupTransparency = 1 }, 0.2, Enum.EasingStyle.Quad)
		if rim then tween(rim, { Transparency = 1 }, 0.2, Enum.EasingStyle.Quad) end
		if shadow then shadow:Fade(false, 0.2) end
		task.delay(0.23, function()
			if self._tgTok == tok and not self.Visible then
				main.Visible = false
				main.Position = rest
				self._restPos = nil
			end
		end)
	end
end

function Window:SetUserVisible(v)
	self.UserCard.Visible = v
	tween(self.TabClip, { Size = UDim2.new(1, 0, 1, -(TABCLIP_Y + (v and 60 or 8))) }, 0.25)
end

function Window:_statsRefresh()
	local parts = {}
	if self.ShowFPS then parts[#parts + 1] = string.format("%d FPS", math.floor(self.Fps + 0.5)) end
	if self.ShowPing then parts[#parts + 1] = string.format("%d ms", math.floor(self.Ping + 0.5)) end
	local show = #parts > 0
	self.StatsLabel.Visible = show
	self.StatsLabel.Text = table.concat(parts, "  |  ")
	self.TitleBlock.Size = UDim2.new(1, -(TITLE_X + CTRL_W + 20 + (show and 124 or 0)), 1, 0)
end

function Window:LoadAutoConfig()
	if not HasFS then return end
	local f = Library.ConfigFolder
	if isfile(f .. "/autoload.txt") and readfile(f .. "/autoload.txt") == "1" and isfile(f .. "/last.txt") then
		local name = readfile(f .. "/last.txt")
		if Library:LoadConfig(name) then
			Library:Notify({ Title = "Config", Content = "Auto load: " .. name, Icon = "folder" })
		end
	end
end

function Window:CreateSettingsTab(opts)
	opts = opts or {}
	local tab = self:AddTab({ Name = "Settings", Icon = "settings", Group = opts.Group, Description = opts.Description })
	local ap = tab:AddSection({ Name = "Appearance", Icon = "palette", Side = "Left" })
	ap:AddDropdown({ Name = "Theme", Icon = "palette", Options = Library.ThemeList, Default = Library.ThemeName, AllowNone = false, Flag = "UI_Theme", Callback = function(v) Library:SetTheme(v) end })
	ap:AddSlider({ Name = "Transparency", Icon = "contrast", Min = 0, Max = 0.8, Increment = 0.01, Default = Library.Transparency, Flag = "UI_Transparency", Callback = function(v) Library:SetTransparency(v) end })
	ap:AddToggle({ Name = "Click Effects", Icon = "bolt", Default = true, Flag = "UI_Effects", Callback = function(v) Library:SetEffects(v) end })
	ap:AddToggle({ Name = "Show User", Icon = "user", Default = true, Flag = "UI_ShowUser", Callback = function(v) self:SetUserVisible(v) end })
	ap:AddToggle({ Name = "Show FPS", Icon = "pulse", Default = false, Flag = "UI_ShowFPS", Callback = function(v) self.ShowFPS = v self:_statsRefresh() end })
	ap:AddToggle({ Name = "Show Ping", Icon = "signal", Default = false, Flag = "UI_ShowPing", Callback = function(v) self.ShowPing = v self:_statsRefresh() end })

	local kb = tab:AddSection({ Name = "Keybinds", Icon = "keyboard", Side = "Left" })
	kb:AddKeybind({ Name = "Toggle UI", Icon = "keyboard", Default = self.ToggleKey, Flag = "UI_ToggleKey", Changed = function(k) if k then self.ToggleKey = k end end })
	kb:AddButton({ Name = "Unload UI", Icon = "close", Callback = function() self:RequestClose() end })

	local mo = tab:AddSection({ Name = "Motion 3D", Icon = "pulse", Side = "Left" })
	mo:AddToggle({ Name = "3D Tilt", Icon = "grid", Default = true, Flag = "UI_Tilt", Callback = function(v) Library.Motion.Tilt = v end })
	mo:AddToggle({ Name = "Idle Wave", Icon = "pulse", Default = true, Flag = "UI_Wave", Callback = function(v) Library.Motion.Wave = v end })
	mo:AddToggle({ Name = "Depth Layers", Icon = "columns", Default = true, Flag = "UI_Depth", Callback = function(v) Library.Motion.Depth = v end })
	mo:AddSlider({ Name = "Motion Strength", Icon = "slider", Min = 0.2, Max = 2, Increment = 0.05, Default = 1, Suffix = "x", Flag = "UI_MotionStrength", Callback = function(v) Library.Motion.Strength = v end })
	if UserInputService.GyroscopeEnabled then
		mo:AddToggle({ Name = "Gyroscope", Icon = "signal", Default = true, Flag = "UI_Gyro", Callback = function(v) Library.Motion.Gyro = v end })
		mo:AddToggle({ Name = "Invert Gyroscope", Icon = "refresh", Default = false, Flag = "UI_GyroInvert", Callback = function(v) Library.Motion.InvertGyro = v end })
	end

	local cf = tab:AddSection({ Name = "Config", Icon = "save", Side = "Right" })
	local nameBox = cf:AddTextbox({ Name = "Config Name", Icon = "edit", Placeholder = "MyConfig" })
	local sel
	local function refreshList() sel:Refresh(Library:ListConfigs()) end
	cf:AddButton({ Name = "Save Config", Icon = "save", Callback = function()
		local ok, name = Library:SaveConfig(nameBox:Get())
		if ok then
			Library:Notify({ Title = "Config", Content = "Saved: " .. name, Icon = "save" })
			refreshList()
		else
			Library:Notify({ Title = "Config", Content = HasFS and "Config name is empty." or "Your executor does not support writefile.", Icon = "info" })
		end
	end })
	sel = cf:AddDropdown({ Name = "Select Config", Icon = "folder", Options = Library:ListConfigs(), Placeholder = "No configs..." })
	cf:AddButton({ Name = "Refresh Config List", Icon = "refresh", Callback = refreshList })
	cf:AddButton({ Name = "Load Selected Config", Icon = "folder", Callback = function()
		if sel.Value and Library:LoadConfig(sel.Value) then
			Library:Notify({ Title = "Config", Content = "Loaded: " .. sel.Value, Icon = "folder" })
		end
	end })
	cf:AddButton({ Name = "Delete Selected Config", Icon = "trash", Callback = function()
		if sel.Value and HasFS and delfile then
			pcall(delfile, Library.ConfigFolder .. "/configs/" .. sel.Value .. ".json")
			sel:Set(nil, true)
			refreshList()
		end
	end })
	cf:AddDivider()
	local autoOn = HasFS and isfile(Library.ConfigFolder .. "/autoload.txt") and readfile(Library.ConfigFolder .. "/autoload.txt") == "1"
	cf:AddToggle({ Name = "Enable Auto Load", Icon = "check", Default = autoOn, Callback = function(v)
		if HasFS then
			ensureFolder(ROOT)
			ensureFolder(Library.ConfigFolder)
			pcall(writefile, Library.ConfigFolder .. "/autoload.txt", v and "1" or "0")
		end
	end })
	cf:AddButton({ Name = "Load Last Config", Icon = "folder", Callback = function()
		if HasFS and isfile(Library.ConfigFolder .. "/last.txt") then
			Library:LoadConfig(readfile(Library.ConfigFolder .. "/last.txt"))
		end
	end })
	return tab
end

function Window:CreateDashboard(opts)
	opts = opts or {}
	local win = self
	local tab = self:AddTab({ Name = opts.Name or "Home", Icon = opts.Icon or "home", Group = opts.Group })
	tab.Left.Parent.Visible = false
	local scroll = tab.Scroll
	local D = { Tab = tab }
	tab.Dashboard = D

	local GOOD, WARN, BAD = Color3.fromRGB(74, 190, 120), Color3.fromRGB(235, 170, 60), Color3.fromRGB(226, 72, 80)
	local TILE_H, GAP, SAMPLES = 46, 6, 36
	local scales, glows = {}, {}
	local born = os.clock()
	local ts = game:GetService("TeleportService")

	local function copy(text)
		local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
		if not fn then return false end
		return (pcall(fn, text))
	end

	local function clock(sec)
		sec = math.max(0, math.floor(sec))
		return string.format("%02d:%02d:%02d", math.floor(sec / 3600), math.floor(sec / 60) % 60, sec % 60)
	end

	local function panel(parent, size, pos)
		local f = new("Frame", { Bg = "Card", Size = size, Position = pos or UDim2.new(), ClipsDescendants = true, Parent = parent })
		corner(f, 12)
		stroke(f)
		gradient(f, 225)
		scales[#scales + 1] = new("UIScale", { Parent = f })
		return f
	end

	local function head(card, icon, text, rightW)
		local h = new("Frame", { Size = UDim2.new(1, 0, 0, 36), Parent = card })
		iconTile(h, icon, 22, 13, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
		new("TextLabel", {
			Text = text, Font = FONT_BOLD, Fg = "Text", Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -(46 + (rightW or 24)), 1, 0),
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = h,
		})
		return h
	end

	local function glow(parent, fade, rot)
		local g = new("Frame", { Bg = "Accent", BackgroundTransparency = 0.84, Size = UDim2.fromScale(1, 1), Parent = parent })
		corner(g, 12)
		local gr = new("UIGradient", { Transparency = fade, Rotation = rot, Parent = g })
		glows[#glows + 1] = gr
		return g
	end

	local function press(gui)
		local sc = gui:FindFirstChild("PressScale")
		if not sc then sc = new("UIScale", { Name = "PressScale", Parent = gui }) end
		sc.Scale = 0.95
		tween(sc, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
	end

	local function clickable(gui, fn, key, popObj)
		local hit = hitZone(gui, { ZIndex = 6 })
		onHover(hit,
			function() tween(gui, { BackgroundColor3 = Theme.Hover }, 0.15) end,
			function() tween(gui, { BackgroundColor3 = Theme[key or "Element"] }, 0.2) end)
		onClick(hit, function(pos)
			press(gui)
			FX.ripple(gui, pos, Theme.Accent, { Radius = 10, Alpha = 0.8, Time = 0.55 })
			if popObj then FX.pop(popObj, 1.35, 0.5) end
			fn()
		end)
		return hit
	end

	local function tile(parent, title, value, order)
		local f = new("Frame", { Bg = "Element", LayoutOrder = order or 0, Parent = parent })
		corner(f, 9)
		stroke(f)
		gradient(f, 205)
		new("TextLabel", {
			Text = title, Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -26, 0, 12),
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
		})
		local val = new("TextLabel", {
			Text = value or "-", Font = FONT_BOLD, Fg = "Text", TextSize = 14, Position = UDim2.fromOffset(10, 17),
			Size = UDim2.new(1, -20, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f,
		})
		local dot = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -9, 0, 8), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = GOOD, Visible = false, Parent = f })
		round(dot)
		local track = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -5), Size = UDim2.new(1, -20, 0, 3), Bg = "Stroke", Visible = false, Parent = f })
		round(track)
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), Bg = "Accent", Parent = track })
		round(fill)
		local obj = { Frame = f }
		function obj:Set(text, color, calm)
			if val.Text ~= text then
				val.Text = text
				if not calm then
					val.TextTransparency = 0.6
					tween(val, { TextTransparency = 0 }, 0.3)
				end
			end
			if color then
				dot.Visible = true
				tween(dot, { BackgroundColor3 = color }, 0.3)
			end
		end
		function obj:Fill(frac)
			track.Visible = true
			tween(fill, { Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1) }, 0.4)
		end
		function obj:Click(fn) return clickable(f, fn) end
		return obj
	end

	local function grid(parent, cols, cellH, pos, size)
		local g = new("Frame", { Position = pos, Size = size, Parent = parent })
		new("UIGridLayout", {
			CellSize = UDim2.new(1 / cols, -(GAP * (cols - 1)) / cols, 0, cellH), CellPadding = UDim2.fromOffset(GAP, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = g,
		})
		return g
	end

	local function row(h, order)
		return new("Frame", { Size = UDim2.new(1, 0, 0, h), LayoutOrder = order, Parent = scroll })
	end

	local function pulse(obj, prop, to, t)
		TweenService:Create(obj, TweenInfo.new(t or 1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { [prop] = to }):Play()
	end

	local hour = tonumber(os.date("%H")) or 12
	local hello = opts.Greeting or (hour < 5 and "Good night" or hour < 11 and "Good morning" or hour < 15 and "Good afternoon" or hour < 19 and "Good evening" or "Good night")
	local gameName = opts.GameName or tostring(game.Name)
	local age = LocalPlayer.AccountAge or 0
	local ageText = age >= 365 and string.format("%.1f years", age / 365) or (age .. " days")

	local hero = panel(row(84, 1), UDim2.fromScale(1, 1))
	glow(hero, NumberSequence.new(0, 1), 20)
	local avBox = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(58, 58), Bg = "Hover", Parent = hero })
	round(avBox)
	local ring = stroke(avBox, "Accent", 2.5)
	local ringG = new("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 110, 110)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.88),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = ring,
	})
	local halo = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(43, 42), Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 1, Parent = hero })
	round(halo)
	local haloStroke = stroke(halo, "Accent", 1.5)
	haloStroke.Transparency = 0.85
	pulse(haloStroke, "Transparency", 0.45, 1.3)
	pulse(halo, "Size", UDim2.fromOffset(72, 72), 1.3)
	local av = new("ImageLabel", { Size = UDim2.fromScale(1, 1), Parent = avBox })
	round(av)
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and av.Parent then av.Image = img end
	end)
	new("TextLabel", { Text = hello, Fg = "SubText", TextSize = 11, Position = UDim2.fromOffset(84, 14), Size = UDim2.new(1, -250, 0, 14), Parent = hero })
	new("TextLabel", {
		Text = LocalPlayer.DisplayName, Font = FONT_BOLD, TextSize = 18, Fg = "Text", Position = UDim2.fromOffset(84, 28),
		Size = UDim2.new(1, -250, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd, Parent = hero,
	})
	local sub = new("TextLabel", {
		Text = "@" .. LocalPlayer.Name .. "  |  " .. gameName, Fg = "SubText", TextSize = 11, Position = UDim2.fromOffset(84, 54),
		Size = UDim2.new(1, -250, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = hero,
	})
	task.spawn(function()
		if opts.GameName then return end
		local ok, info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
		if ok and info and info.Name and sub.Parent then
			sub.Text = "@" .. LocalPlayer.Name .. "  |  " .. info.Name
		end
	end)

	local facts = new("Frame", { Bg = "Element", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(150, 62), Parent = hero })
	corner(facts, 9)
	stroke(facts)
	local function fact(y, label, value)
		new("TextLabel", { Text = label, Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(10, y), Size = UDim2.fromOffset(52, 16), Parent = facts })
		return new("TextLabel", {
			Text = value, Fg = "Text", TextSize = 11, Font = FONT_BOLD, Position = UDim2.fromOffset(60, y), Size = UDim2.new(1, -70, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = facts,
		})
	end
	fact(6, "Account", ageText)
	fact(23, "User ID", tostring(LocalPlayer.UserId))
	local sessionLbl = fact(40, "Session", "00:00:00")

	local rowB = row(202, 2)
	local serverCard = panel(rowB, UDim2.new(0.56, -4, 1, 0))
	win:_register({ Name = "Server", Kind = "Card", Tab = tab, Row = serverCard, Icon = "server", Extra = "Dashboard" })
	head(serverCard, "server", "Server")

	local sg = grid(serverCard, 2, TILE_H, UDim2.fromOffset(10, 40), UDim2.new(1, -20, 0, TILE_H * 3 + GAP * 2))
	local tPlayers = tile(sg, "Players", "-", 1)
	local tPing = tile(sg, "Latency", "-", 2)
	local tFps = tile(sg, "Frame Rate", "-", 3)
	local tRegion = tile(sg, "Region", "...", 4)
	local tUp = tile(sg, "Server Uptime", "00:00:00", 5)
	local tJoin = tile(sg, "Join Script", "Tap to copy", 6)

	local joinCode = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%s, "%s", game.Players.LocalPlayer)', tostring(game.PlaceId), tostring(game.JobId))
	tJoin:Click(function()
		local ok = copy(joinCode)
		tJoin:Set(ok and "Copied!" or "Not supported")
		task.delay(1.6, function() tJoin:Set("Tap to copy") end)
		Library:Notify({ Title = "Join Script", Content = ok and "Copied to clipboard." or "Your executor has no clipboard.", Icon = "copy" })
	end)

	task.spawn(function()
		local ok, code = pcall(function()
			return game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LocalPlayer)
		end)
		tRegion:Set(ok and code and tostring(code) or "N/A")
	end)

	local hasDisc = type(opts.Discord) == "string" and opts.Discord ~= ""
	local rc = new("Frame", { Position = UDim2.new(0.56, 4, 0, 0), Size = UDim2.new(0.44, -4, 1, 0), Parent = rowB })
	local exCard = panel(rc, UDim2.new(1, 0, 0, hasDisc and 97 or 202))
	win:_register({ Name = "Executor", Kind = "Card", Tab = tab, Row = exCard, Icon = "cpu", Extra = "Dashboard" })

	local exName, exVer = "Unknown", "Executor"
	if identifyexecutor then
		local ok, n, v = pcall(identifyexecutor)
		if ok and n then
			exName = tostring(n)
			exVer = v and tostring(v) or "Executor"
		end
	end
	local caps = {
		{ "FS", HasFS },
		{ "HTTP", ((syn and syn.request) or (http and http.request) or http_request or request) ~= nil },
		{ "Clip", (setclipboard or toclipboard or (syn and syn.write_clipboard)) ~= nil },
		{ "Draw", Drawing ~= nil }, { "Hooks", hookfunction ~= nil }, { "Env", getgenv ~= nil }, { "UI", gethui ~= nil },
	}
	local passed = 0
	for _, c in ipairs(caps) do
		if c[2] then passed += 1 end
	end
	iconTile(exCard, "cpu", 28, 15, { Position = UDim2.fromOffset(10, 9) })
	new("TextLabel", {
		Text = exName, Font = FONT_BOLD, Fg = "Text", Position = UDim2.fromOffset(46, 8), Size = UDim2.new(1, -104, 0, 16),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = exCard,
	})
	new("TextLabel", {
		Text = exVer, Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(46, 24), Size = UDim2.new(1, -104, 0, 12),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = exCard,
	})
	local badge = new("TextLabel", {
		Text = passed .. "/" .. #caps, Font = FONT_BOLD, TextSize = 11, Fg = "Text", Bg = "Element", AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 12), Size = UDim2.fromOffset(42, 22), TextXAlignment = Enum.TextXAlignment.Center, Parent = exCard,
	})
	round(badge)
	stroke(badge)
	local chips = new("Frame", { Position = UDim2.fromOffset(10, 47), Size = UDim2.new(1, -20, 0, 44), Parent = exCard })
	local chipList = listLayout(chips, 4, Enum.FillDirection.Horizontal)
	chipList.Wraps = true
	for i, c in ipairs(caps) do
		local chip = new("TextLabel", {
			Text = c[1], TextSize = 10, Font = FONT_BOLD, Fg = c[2] and "Text" or "SubText", Bg = "Element",
			BackgroundTransparency = c[2] and 0 or 0.5, Size = UDim2.fromOffset(0, 18), AutomaticSize = AutoX,
			TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = i, Parent = chips,
		})
		round(chip)
		padding(chip, 6, 0, 6, 0)
		local cs = stroke(chip, c[2] and "Accent" or "Stroke")
		if c[2] then cs.Transparency = 0.55 end
	end

	if hasDisc then
		local disc = panel(rc, UDim2.new(1, 0, 0, 97), UDim2.fromOffset(0, 105))
		glow(disc, NumberSequence.new(1, 0), 0).BackgroundTransparency = 0.76
		iconTile(disc, "chat", 34, 18, { Position = UDim2.fromOffset(12, 12) })
		new("TextLabel", { Text = opts.DiscordTitle or "Join the Discord", Font = FONT_BOLD, TextSize = 14, Fg = "Text", Position = UDim2.fromOffset(54, 13), Size = UDim2.new(1, -64, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd, Parent = disc })
		local discSub = new("TextLabel", { Text = "Tap to copy the invite", Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(54, 31), Size = UDim2.new(1, -64, 0, 14), Parent = disc })
		local invite = new("Frame", { Bg = "Element", Position = UDim2.fromOffset(12, 61), Size = UDim2.new(1, -24, 0, 26), Parent = disc })
		corner(invite, 8)
		stroke(invite)
		new("TextLabel", { Text = opts.Discord, Fg = "Text", TextSize = 11, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = invite })
		makeIcon(invite, "copy", 13, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0) })
		local hz = hitZone(disc, { ZIndex = 6 })
		onClick(hz, function(pos)
			FX.ripple(disc, pos, Theme.Accent, { Radius = 12, Alpha = 0.8, Time = 0.6 })
			local ok = copy(opts.Discord)
			discSub.Text = ok and "Invite copied!" or "Clipboard not supported"
			task.delay(1.8, function()
				if discSub.Parent then discSub.Text = "Tap to copy the invite" end
			end)
			Library:Notify({ Title = "Discord", Content = ok and "Invite copied to clipboard." or "Your executor has no clipboard.", Icon = "chat" })
			local req = (syn and syn.request) or (http and http.request) or http_request or request
			local code = opts.Discord:match("discord%.gg/([%w%-_]+)") or opts.Discord:match("discord%.com/invite/([%w%-_]+)")
			if req and code then
				task.spawn(function()
					pcall(req, {
						Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
						Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
						Body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = code }, nonce = HttpService:GenerateGUID(false) }),
					})
				end)
			end
		end)
	end

	local rowC = row(152, 3)
	local frCard = panel(rowC, UDim2.new(0.5, -4, 1, 0))
	win:_register({ Name = "Friends", Kind = "Card", Tab = tab, Row = frCard, Icon = "users", Extra = "Dashboard" })
	local fh = head(frCard, "users", "Friends", 40)
	local refreshBtn = hitZone(fh, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(34, 30) })
	local refreshIcon = makeIcon(fh, "refresh", 14, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0) })
	local fg = grid(frCard, 2, TILE_H, UDim2.fromOffset(10, 40), UDim2.new(1, -20, 0, TILE_H * 2 + GAP))
	local tIn = tile(fg, "In Server", "...", 1)
	local tOn = tile(fg, "Online", "...", 2)
	local tOff = tile(fg, "Offline", "...", 3)
	local tAll = tile(fg, "All Friends", "...", 4)

	local loading = false
	local function loadFriends()
		if loading then return end
		loading = true
		refreshIcon.Rotation = 0
		tween(refreshIcon, { Rotation = 360 }, 0.8)
		task.spawn(function()
			local inServer, online, all
			pcall(function()
				local n = 0
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer then
						local ok, f = pcall(LocalPlayer.IsFriendsWith, LocalPlayer, p.UserId)
						if ok and f then n += 1 end
					end
				end
				inServer = n
			end)
			pcall(function() online = #LocalPlayer:GetFriendsOnline(200) end)
			pcall(function()
				local n = 0
				local pages = Players:GetFriendsAsync(LocalPlayer.UserId)
				for _ = 1, 30 do
					n = n + #pages:GetCurrentPage()
					if pages.IsFinished then break end
					pages:AdvanceToNextPageAsync()
				end
				all = n
			end)
			local function show(t, v) t:Set(v ~= nil and tostring(v) or "N/A") end
			show(tIn, inServer)
			show(tOn, online)
			show(tAll, all)
			show(tOff, (all and online) and math.max(all - online, 0) or nil)
			loading = false
		end)
	end
	onClick(refreshBtn, function()
		FX.pop(refreshIcon, 1.4, 0.5)
		loadFriends()
	end)

	local perfCard = panel(rowC, UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0))
	win:_register({ Name = "Monitor", Kind = "Card", Tab = tab, Row = perfCard, Icon = "pulse", Extra = "Dashboard" })
	local ph = head(perfCard, "pulse", "Monitor", 100)
	local modes = {
		{ key = "fps", label = "FPS" }, { key = "ping", label = "PING" }, { key = "mem", label = "MEM" },
	}
	local mode = 1
	local pills = {}
	local function paintPills()
		for i, p in ipairs(pills) do
			local on = i == mode
			tween(p.box, { BackgroundColor3 = on and Theme.Accent or Theme.Element }, 0.2)
			tween(p.lbl, { TextColor3 = on and Theme.AccentText or Theme.SubText }, 0.2)
		end
	end
	for i, m in ipairs(modes) do
		local box = new("Frame", { Bg = "Element", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10 - (#modes - i) * 33, 0.5, 0), Size = UDim2.fromOffset(30, 20), Parent = ph })
		round(box)
		stroke(box)
		local lbl = new("TextLabel", { Text = m.label, Font = FONT_BOLD, TextSize = 9, Fg = "SubText", Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = box })
		pills[i] = { box = box, lbl = lbl }
		local hz = hitZone(box, { ZIndex = 6 })
		onClick(hz, function()
			mode = i
			FX.pop(box, 1.25, 0.4)
			paintPills()
			D.render()
		end, true)
	end
	Hooks[#Hooks + 1] = function() paintPills() end
	local big = new("TextLabel", { Text = "-", Font = FONT_BOLD, TextSize = 20, Fg = "Text", Position = UDim2.fromOffset(12, 38), Size = UDim2.new(0.5, -12, 0, 26), Parent = perfCard })
	local range = new("TextLabel", {
		Text = "", Fg = "SubText", TextSize = 10, Position = UDim2.new(0.4, 0, 0, 44), Size = UDim2.new(0.6, -12, 0, 14),
		TextXAlignment = Enum.TextXAlignment.Right, Parent = perfCard,
	})
	local spark = new("Frame", { Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 0, 54), Parent = perfCard })
	local bars = {}
	for i = 1, SAMPLES do
		local b = new("Frame", {
			Bg = "Accent", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / SAMPLES, 1, 1, 0),
			Size = UDim2.new(1 / SAMPLES, -2, 0, 2), BackgroundTransparency = 0.78 - 0.78 * (i / SAMPLES) + 0.06, Parent = spark,
		})
		corner(b, 2)
		bars[i] = b
	end
	local foot = new("TextLabel", { Text = "", Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(12, 130), Size = UDim2.new(1, -24, 0, 14), Parent = perfCard })

	local hist = { fps = {}, ping = {}, mem = {} }
	local function push(list, v)
		list[#list + 1] = v
		if #list > SAMPLES then table.remove(list, 1) end
	end
	local function sample()
		push(hist.fps, win.Fps or 0)
		push(hist.ping, win.Ping or 0)
		local ok, mem = pcall(function() return Stats:GetTotalMemoryUsageMb() end)
		push(hist.mem, ok and mem or 0)
	end

	function D.render()
		local m = modes[mode].key
		local list = hist[m]
		local n = #list
		local peak, low, sum = 0, math.huge, 0
		for _, v in ipairs(list) do
			peak = math.max(peak, v)
			low = math.min(low, v)
			sum += v
		end
		if n == 0 then low = 0 end
		local top = m == "fps" and math.max(60, peak) or m == "ping" and math.max(120, peak * 1.15) or math.max(peak * 1.1, 1)
		for i = 1, SAMPLES do
			local v = list[i - (SAMPLES - n)]
			local frac = v and math.clamp(v / top, 0.04, 1) or 0.03
			bars[i].Size = UDim2.new(1 / SAMPLES, -2, frac, 0)
		end
		local cur = list[n] or 0
		if m == "fps" then
			big.Text = string.format("%d FPS", math.floor(cur + 0.5))
		elseif m == "ping" then
			big.Text = string.format("%d ms", math.floor(cur + 0.5))
		else
			big.Text = string.format("%d MB", math.floor(cur + 0.5))
		end
		range.Text = n > 0 and string.format("%d avg  %d-%d", math.floor(sum / n + 0.5), math.floor(low + 0.5), math.floor(peak + 0.5)) or ""
		foot.Text = string.format("Ping %d ms  |  Memory %d MB  |  %d players", math.floor(win.Ping or 0), math.floor(hist.mem[#hist.mem] or 0), #Players:GetPlayers())
	end

	local label = new("TextLabel", {
		Text = "QUICK ACTIONS", Font = FONT_BOLD, TextSize = 10, Fg = "SubText", Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 4, Parent = scroll,
	})
	padding(label, 4, 0, 0, 0)

	local function confirmThen(title, text, fn)
		Library:Confirm({ Title = title, Content = text, ConfirmText = "Continue", CancelText = "Cancel", Icon = "info", Callback = fn })
	end

	local antiConn, savedGfx
	local actions = {
		{ Name = "Rejoin", Sub = "Same server", Icon = "refresh", Callback = function()
			confirmThen("Rejoin?", "You will be teleported back into this server.", function()
				if #Players:GetPlayers() <= 1 then
					pcall(function() ts:Teleport(game.PlaceId, LocalPlayer) end)
				else
					pcall(function() ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
				end
			end)
		end },
		{ Name = "Server Hop", Sub = "Random public", Icon = "hop", Callback = function()
			confirmThen("Server Hop?", "You will be moved to another public server of this game.", function()
				Library:Notify({ Title = "Server Hop", Content = "Searching for a server...", Icon = "hop" })
				task.spawn(function()
					local ok = pcall(function()
						local body = httpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
						local data = body and HttpService:JSONDecode(body)
						local list = {}
						for _, s in ipairs(data and data.data or {}) do
							if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 then list[#list + 1] = s.id end
						end
						if #list == 0 then
							Library:Notify({ Title = "Server Hop", Content = "No other server found.", Icon = "info" })
							return
						end
						ts:TeleportToPlaceInstance(game.PlaceId, list[math.random(#list)], LocalPlayer)
					end)
					if not ok then Library:Notify({ Title = "Server Hop", Content = "Failed to search for servers.", Icon = "info" }) end
				end)
			end)
		end },
		{ Name = "Copy Job ID", Sub = "To clipboard", Icon = "copy", Callback = function()
			local ok = copy(game.JobId)
			Library:Notify({ Title = "Job ID", Content = ok and "Copied to clipboard." or "Your executor has no clipboard.", Icon = "copy" })
		end },
		{ Name = "Reset", Sub = "Respawn", Icon = "user", Callback = function()
			local ch = LocalPlayer.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = 0 end
		end },
		{ Name = "Anti AFK", Icon = "shield", Toggle = true, Callback = function(on)
			if antiConn then
				antiConn:Disconnect()
				antiConn = nil
			end
			if on then
				antiConn = connect(LocalPlayer.Idled, function()
					pcall(function()
						local vu = game:GetService("VirtualUser")
						vu:CaptureController()
						vu:ClickButton2(Vector2.new())
					end)
				end)
			end
		end },
		{ Name = "Low GFX", Sub = "Boost FPS", Icon = "bolt", Toggle = true, Callback = function(on)
			pcall(function()
				local lighting = game:GetService("Lighting")
				if on then
					savedGfx = { shadows = lighting.GlobalShadows, quality = settings().Rendering.QualityLevel }
					lighting.GlobalShadows = false
					settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
				elseif savedGfx then
					lighting.GlobalShadows = savedGfx.shadows
					settings().Rendering.QualityLevel = savedGfx.quality
				end
			end)
		end },
	}
	for _, a in ipairs(opts.Actions or {}) do actions[#actions + 1] = a end

	local rows = math.ceil(#actions / 3)
	local ag = grid(scroll, 3, 52, UDim2.new(), UDim2.new(1, 0, 0, rows * 52 + (rows - 1) * GAP))
	ag.LayoutOrder = 5
	D.Actions = {}
	for i, a in ipairs(actions) do
		local f = new("Frame", { Bg = "Element", LayoutOrder = i, Parent = ag })
		win:_register({ Name = a.Name, Kind = "Action", Tab = tab, Row = f, Icon = a.Icon or "click", Extra = "Quick Actions" })
		corner(f, 10)
		stroke(f)
		gradient(f, 205)
		local ibox = iconTile(f, a.Icon or "click", 30, 16, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
		new("TextLabel", { Text = a.Name, Font = FONT_BOLD, TextSize = 12, Fg = "Text", Position = UDim2.fromOffset(48, 9), Size = UDim2.new(1, -66, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
		local subLbl = new("TextLabel", { Text = a.Toggle and "Off" or (a.Sub or ""), Fg = "SubText", TextSize = 10, Position = UDim2.fromOffset(48, 26), Size = UDim2.new(1, -66, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
		local state = { On = false }
		if a.Toggle then
			function state:Set(v, silent)
				state.On = v and true or false
				subLbl.Text = state.On and "On" or "Off"
				tween(subLbl, { TextColor3 = state.On and Theme.Text or Theme.SubText }, 0.2)
				if not silent and a.Callback then a.Callback(state.On) end
			end
			clickable(f, function() state:Set(not state.On) end, nil, ibox)
			if a.Default then state:Set(true) end
		else
			clickable(f, function() if a.Callback then a.Callback() end end, nil, ibox)
		end
		D.Actions[a.Name] = state
	end

	local function updateTiles()
		local players, maxP = #Players:GetPlayers(), Players.MaxPlayers or 0
		tPlayers:Set(maxP > 0 and (players .. " / " .. maxP) or tostring(players), nil, true)
		if maxP > 0 then tPlayers:Fill(players / maxP) end
		local ping = win.Ping or 0
		tPing:Set(string.format("%d ms", math.floor(ping + 0.5)), ping < 100 and GOOD or ping < 200 and WARN or BAD, true)
		local fps = win.Fps or 0
		tFps:Set(string.format("%d FPS", math.floor(fps + 0.5)), fps >= 55 and GOOD or fps >= 30 and WARN or BAD, true)
		tUp:Set(clock(workspace.DistributedGameTime), nil, true)
		sessionLbl.Text = clock(os.clock() - born)
	end

	local acc, accSec, accFr, accRot = 0, 0, 0, 0
	connect(RunService.Heartbeat, function(dt)
		acc += dt
		if acc >= 0.5 then
			acc = 0
			sample()
			if tab.Active and win.Visible then
				D.render()
				updateTiles()
			end
		end
		if tab.Active and win.Visible then
			accSec += dt
			accFr += dt
			ringG.Rotation = (ringG.Rotation + dt * 110) % 360
			accRot += dt
			if accRot >= 1 / 30 then
				for _, g in ipairs(glows) do g.Rotation = (g.Rotation + accRot * 14) % 360 end
				accRot = 0
			end
			if accSec >= 1 then
				accSec = 0
				sessionLbl.Text = clock(os.clock() - born)
				tUp:Set(clock(workspace.DistributedGameTime), nil, true)
			end
			if accFr >= 60 then
				accFr = 0
				loadFriends()
			end
		end
	end)

	function D.intro()
		for i, sc in ipairs(scales) do
			sc.Scale = 0.93
			task.delay((i - 1) * 0.04, function()
				if sc.Parent then tween(sc, { Scale = 1 }, 0.45, Enum.EasingStyle.Back) end
			end)
		end
	end
	connect(tab.Page:GetPropertyChangedSignal("Visible"), function()
		if tab.Page.Visible then D.intro() end
	end)

	function D.Refresh()
		loadFriends()
		D.render()
	end

	sample()
	sample()
	D.render()
	updateTiles()
	loadFriends()
	paintPills()
	D.intro()
	return tab
end

function Library:Confirm(o)
	o = o or {}
	if Library._confirm then return end
	Library._confirm = true
	closePopup()

	local vp = viewport()
	local s = math.min(1, vp.X * 0.92 / 300, vp.Y * 0.92 / 220)

	local blocker = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		ZIndex = 100, Parent = Gui,
	})
	local card = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 0),
		AutomaticSize = AutoY, Bg = "Card", GroupTransparency = 1, Active = true, ZIndex = 101, Parent = Gui,
	})
	corner(card, 14)
	local cardStroke = stroke(card)
	cardStroke.Transparency = 1
	gradient(card, 220)
	padding(card, 18, 16, 18, 16)
	listLayout(card, 10)
	local scale = new("UIScale", { Scale = s * 0.92, Parent = card })

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = card })
	local cbox = iconTile(head, o.Icon or "info", 26, 15, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
	new("TextLabel", {
		Text = o.Title or "Confirm", Font = FONT_BOLD, TextSize = 15, Fg = "Text",
		Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -34, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	new("TextLabel", {
		Text = o.Content or "", TextSize = 12, Fg = "SubText", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Parent = card,
	})

	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 36), LayoutOrder = 3, Parent = card })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
	})
	local cancel = new("TextButton", {
		Size = UDim2.new(0.5, -4, 1, 0), Bg = "Element", Text = o.CancelText or "Cancel", Font = FONT_BOLD, Fg = "Text",
		TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = row,
	})
	corner(cancel, 9)
	stroke(cancel)
	gradient(cancel, 185)
	local RED = Color3.fromRGB(220, 50, 60)
	local ok = new("TextButton", {
		Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = RED, Text = o.ConfirmText or "Yes", Font = FONT_BOLD,
		TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = row,
	})
	corner(ok, 9)
	gradient(ok, 190)
	onHover(cancel,
		function() tween(cancel, { BackgroundColor3 = Theme.Hover }, 0.15) end,
		function() tween(cancel, { BackgroundColor3 = Theme.Element }, 0.2) end)
	onHover(ok,
		function() tween(ok, { BackgroundColor3 = RED:Lerp(Color3.new(1, 1, 1), 0.15) }, 0.15) end,
		function() tween(ok, { BackgroundColor3 = RED }, 0.2) end)

	local closed, escCon = false, nil
	local function close(cb)
		if closed then return end
		closed = true
		Library._confirm = nil
		if escCon then escCon:Disconnect() end
		blocker.Active = false
		card.Active = false
		cardStroke.Enabled = false
		tween(blocker, { BackgroundTransparency = 1 }, 0.12)
		tween(card, { GroupTransparency = 1 }, 0.12)
		tween(scale, { Scale = s * 0.94 }, 0.12)
		task.delay(0.13, function()
			pcall(function() blocker:Destroy() end)
			pcall(function() card:Destroy() end)
			prune()
		end)
		if cb then task.spawn(cb) end
	end
	escCon = UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Escape then close(o.OnCancel) end
	end)
	onClick(blocker, function() close(o.OnCancel) end)
	onClick(cancel, function(pos)
		FX.ripple(cancel, pos, Theme.Accent, { Radius = 9, Alpha = 0.75, Time = 0.4 })
		close(o.OnCancel)
	end, true)
	onClick(ok, function(pos)
		FX.ripple(ok, pos, Color3.new(1, 1, 1), { Radius = 9, Alpha = 0.7, Time = 0.4 })
		close(o.Callback)
	end, true)

	tween(blocker, { BackgroundTransparency = 0.45 }, 0.2)
	tween(card, { GroupTransparency = 0 }, 0.2)
	tween(cardStroke, { Transparency = 0 }, 0.2)
	tween(scale, { Scale = s }, 0.28, Enum.EasingStyle.Back)
	task.delay(0.12, function()
		if cbox.Parent then FX.pop(cbox, 0.3, 0.55) end
	end)
end

function Window:RequestClose()
	Library:Confirm({
		Title = "Close UI?",
		Content = "The UI will be closed completely, not just hidden. Settings that were not saved to a config will be lost, and you will need to run the script again to reopen it.\n\nWant to hide it instead? Press Cancel, then press "
			.. self.ToggleKey.Name .. " or the round button.",
		ConfirmText = "Close UI",
		CancelText = "Cancel",
		Icon = "close",
		Callback = function() Library:Unload() end,
	})
end

function Window:Destroy() Library:Unload() end

function Library:CreateWindow(opts)
	opts = opts or {}
	local self = setmetatable({
		Tabs = {}, GroupLabels = {}, TabOrder = 0, Visible = true, Minimized = false, Maximized = false,
		Index = {}, SearchOpen = false, SearchResults = {}, _srRows = {}, _srConns = {}, _srTok = 0, _sel = 1, _lastQ = "", _loops = {},
		ToggleKey = opts.ToggleKey or Enum.KeyCode.J, Searching = false, Fps = 60, Ping = 0,
	}, Window)
	Library.ConfigFolder = ROOT .. "/" .. (opts.ConfigFolder or "Default")
	ensureFolder(ROOT)
	ensureFolder(Library.ConfigFolder)

	local Main = new("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(BASE_W, BASE_H), Parent = Gui,
	})
	ScaleObj = new("UIScale", { Scale = fitScale() * 0.85, Parent = Main })
	MainFrame = Main
	self.Main = Main

	self.Shadow = makeShadow(Main, 12)

	local Canvas = new("CanvasGroup", {
		Name = "Canvas", Size = UDim2.fromScale(1, 1), Bg = "Background", BackgroundTransparency = Library.Transparency, Parent = Main,
	})
	corner(Canvas, 12)
	TransFrames[#TransFrames + 1] = Canvas
	self.Canvas = Canvas

	local Outline = new("Frame", { Name = "Outline", Size = UDim2.fromScale(1, 1), ZIndex = 20, Active = false, Parent = Main })
	corner(Outline, 12)
	self.OutlineStroke = stroke(Outline)

	local BODY_H = BASE_H - HEADER_H - 1
	local Body = new("Frame", { Name = "Body", Position = UDim2.fromOffset(0, HEADER_H + 1), Size = UDim2.fromOffset(BASE_W, BODY_H), Parent = Canvas })
	self.Body = Body

	local Header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), Bg = "Sidebar", BackgroundTransparency = Library.Transparency, Parent = Canvas })
	TransFrames[#TransFrames + 1] = Header
	gradient(Header, 205)
	local _, headerCrown = iconTile(Header, "crown", 30, 18, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0) })

	local TitleBlock = new("Frame", {
		Position = UDim2.fromOffset(TITLE_X, 0), Size = UDim2.new(1, -(TITLE_X + CTRL_W + 20), 1, 0), ClipsDescendants = true, Parent = Header,
	})
	self.TitleBlock = TitleBlock
	local titleRow = new("Frame", { Position = UDim2.fromOffset(0, 7), Size = UDim2.fromOffset(0, 17), AutomaticSize = AutoX, Parent = TitleBlock })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = titleRow })
	new("TextLabel", { Text = opts.Title or "ZystrixUI", Font = FONT_BOLD, TextSize = 14, Fg = "Text", Size = UDim2.fromOffset(0, 17), AutomaticSize = AutoX, LayoutOrder = 1, Parent = titleRow })
	if opts.Version then
		local pill = new("TextLabel", {
			Text = opts.Version, Font = FONT_BOLD, TextSize = 10, Bg = "Accent", Fg = "AccentText", Size = UDim2.fromOffset(0, 15),
			AutomaticSize = AutoX, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = titleRow,
		})
		corner(pill, 8)
		padding(pill, 8, 0, 8, 0)
		local pst = new("UIStroke", { Stk = "Accent", Thickness = 0, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = pill })
		local pillLoop = TweenService:Create(pst, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 3, Transparency = 1 })
		pillLoop:Play()
		self._loops[#self._loops + 1] = pillLoop
	end
	new("TextLabel", {
		Text = opts.Subtitle or "", TextSize = 11, Fg = "SubText", Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 13), TextTruncate = Enum.TextTruncate.AtEnd, Parent = TitleBlock,
	})

	local ctrls = new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(CTRL_W, HEADER_H), ZIndex = 30, Parent = Main,
	})
	self.Ctrls = ctrls
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = ctrls,
	})

	self.StatsLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(CTRL_W + 20), 0.5, 0), Size = UDim2.fromOffset(118, 14),
		TextXAlignment = Enum.TextXAlignment.Right, TextSize = 11, Fg = "SubText", Visible = false, Parent = Header,
	})

	local function ctrl(order, iconName, hoverColor, fn)
		local slot = new("Frame", { Size = UDim2.fromOffset(CTRL_SLOT, HEADER_H), LayoutOrder = order, Parent = ctrls })
		local b = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CTRL_BTN, CTRL_BTN), Bg = "Element", Parent = slot,
		})
		corner(b, 11)
		local bst = stroke(b)
		gradient(b, 175)
		local bsc = new("UIScale", { Parent = b })
		local ic
		if iconName then
			ic = makeIcon(b, iconName, 18, "SubText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		else
			ic = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 2), Bg = "SubText", Parent = b })
			round(ic)
		end
		local function tint(color, t)
			if ic:IsA("ImageLabel") then tintIcon(ic, color, t) else tween(ic, { BackgroundColor3 = color }, t) end
		end
		local hit = hitZone(slot, { Size = UDim2.fromScale(1, 1) })
		onHover(hit,
			function()
				tween(b, { BackgroundColor3 = hoverColor or Theme.Hover }, 0.15)
				tween(bst, { Color = hoverColor or Theme.Accent }, 0.15)
				tween(bsc, { Scale = 1.08 }, 0.12, Enum.EasingStyle.Quad)
				tint(hoverColor and Color3.new(1, 1, 1) or Theme.Text, 0.15)
				if iconName == "close" then tween(ic, { Rotation = 90 }, 0.35, Enum.EasingStyle.Back) end
			end,
			function()
				tween(b, { BackgroundColor3 = Theme.Element }, 0.2)
				tween(bst, { Color = Theme.Stroke }, 0.2)
				tween(bsc, { Scale = 1 }, 0.2)
				tint(Theme.SubText, 0.2)
				if iconName == "close" then tween(ic, { Rotation = 0 }, 0.35, Enum.EasingStyle.Back) end
			end)
		connect(hit.MouseButton1Down, function() tween(bsc, { Scale = 0.9 }, 0.06) end)
		connect(hit.MouseButton1Up, function() tween(bsc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back) end)
		onClick(hit, function(pos)
			FX.ripple(b, pos, hoverColor or Theme.Accent, { Radius = 11, Alpha = 0.7, Time = 0.45 })
			FX.pop(ic, 1.45, 0.5)
			fn()
		end, true)
		return slot
	end
	ctrl(1, nil, nil, function() self:SetMinimized(not self.Minimized) end)
	ctrl(2, "maximize", nil, function() self:SetMaximized(not self.Maximized) end)
	ctrl(3, "close", Color3.fromRGB(220, 50, 60), function() self:RequestClose() end)
	draggable(Header, Main, nil, {
		deadRight = CTRL_W + 14,
		canDrag = function() return not self.Maximized end,
	})

	new("Frame", { Position = UDim2.fromOffset(0, -1), Size = UDim2.new(1, 0, 0, 1), Bg = "Stroke", ZIndex = 2, Parent = Body })
	local shim = new("Frame", { Position = UDim2.fromOffset(0, -1), Size = UDim2.new(1, 0, 0, 1), Bg = "Accent", ZIndex = 3, Parent = Body })
	local grad = new("UIGradient", {
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }),
		Offset = Vector2.new(-1, 0), Parent = shim,
	})
	local shimLoop = TweenService:Create(grad, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(1, 0) })
	shimLoop:Play()
	self._loops[#self._loops + 1] = shimLoop

	local Sidebar = new("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, SIDEBAR_W, 1, 0), Bg = "Sidebar", BackgroundTransparency = Library.Transparency, ClipsDescendants = true, Parent = Body })
	TransFrames[#TransFrames + 1] = Sidebar
	new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), Bg = "Stroke", Parent = Sidebar })

	local SEARCH_H = 38
	local searchHit, searchHitZone = hitZone(Sidebar, {
		Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, SEARCH_H + 12), ZIndex = 49,
	})
	local search = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, SEARCH_H), Bg = "Element", ZIndex = 50, Parent = Sidebar })
	corner(search, 11)
	local sst = stroke(search)
	gradient(search, 200)
	local searchIcon = makeIcon(search, "search", 16, "SubText", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), ZIndex = 51 })
	local sbox = new("TextBox", { Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -(34 + (UserInputService.TouchEnabled and 32 or 50)), 1, 0), PlaceholderText = "Search...", Text = "", Fg = "Text", Ph = "SubText", TextSize = 13, ClipsDescendants = true, ZIndex = 52, Parent = search })
	self.SearchBox = sbox
	local kbdBadge
	if not UserInputService.TouchEnabled then
		kbdBadge = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(0, 18), AutomaticSize = AutoX, Bg = "Hover", Text = "Ctrl K", TextSize = 9, Fg = "SubText", TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 51, Parent = search })
		corner(kbdBadge, 4)
		padding(kbdBadge, 5, 0, 5, 0)
	end
	onClick(searchHit, function() sbox:CaptureFocus() end, true)
	local clearBtn = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(24, 24), Bg = "Hover", Visible = false, ZIndex = 53, Parent = search })
	round(clearBtn)
	makeIcon(clearBtn, "close", 11, "SubText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 54 })
	local clearHit = hitZone(clearBtn, { ZIndex = 56 })
	onClick(clearHit, function()
		FX.pop(clearBtn, 0.7, 0.35)
		self:ClearSearch()
	end, true)
	connect(sbox.Focused, function()
		tween(sst, { Color = Theme.Accent }, 0.2)
		FX.pop(searchIcon, 1.4, 0.5)
	end)
	connect(sbox.FocusLost, function(enter)
		tween(sst, { Color = Theme.Stroke }, 0.2)
		if enter then
			self:_flushFilter()
			local r = self.SearchResults[self._sel] or self.SearchResults[1]
			if r then self:_goto(r) end
		end
	end)
	connect(sbox:GetPropertyChangedSignal("Text"), function()
		local has = sbox.Text ~= ""
		if clearBtn.Visible ~= has then
			clearBtn.Visible = has
			if has then FX.pop(clearBtn, 0.6, 0.35) end
		end
		if kbdBadge then kbdBadge.Visible = not has end
		self:_queueFilter(sbox.Text)
	end)

	self.TabClip = new("CanvasGroup", {
		Name = "TabClip", Position = UDim2.fromOffset(0, TABCLIP_Y), Size = UDim2.new(1, 0, 1, -(TABCLIP_Y + 60)), Parent = Sidebar,
	})
	self.TabList = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AutoY, ScrollBarThickness = 2, Sb = "Stroke", Parent = self.TabClip,
	})
	padding(self.TabList, 8, 2, 8, 6)
	listLayout(self.TabList, 3)

	self.UserCard = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 44), Bg = "Element", ZIndex = 5, Parent = Sidebar })
	corner(self.UserCard, 11)
	stroke(self.UserCard)
	gradient(self.UserCard, 200)
	local av = new("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(28, 28), Bg = "Hover", Parent = self.UserCard })
	corner(av, 14)
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and av.Parent then av.Image = img end
	end)
	new("TextLabel", { Text = LocalPlayer.DisplayName, Font = FONT_BOLD, TextSize = 12, Fg = "Text", Position = UDim2.fromOffset(44, 6), Size = UDim2.new(1, -50, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = self.UserCard })
	new("TextLabel", { Text = "@" .. LocalPlayer.Name, TextSize = 10, Fg = "SubText", Position = UDim2.fromOffset(44, 22), Size = UDim2.new(1, -50, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = self.UserCard })

	self.Content = new("Frame", { Position = UDim2.fromOffset(SIDEBAR_W + 1, 0), Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, 0), ClipsDescendants = true, Parent = Body })

	self.SearchPage = new("CanvasGroup", {
		Name = "SearchPage", AnchorPoint = Vector2.new(0.5, 0.5), Position = PAGE_REST, Size = UDim2.fromScale(1, 1),
		Visible = false, GroupTransparency = 1, ZIndex = 5, Parent = self.Content,
	})
	self.SearchScroll = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = AutoY,
		ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, Sb = "Stroke", Parent = self.SearchPage,
	})
	padding(self.SearchScroll, 10, 10, 12, 10)
	listLayout(self.SearchScroll, 6)
	local sHead = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = 0, Parent = self.SearchScroll })
	listLayout(sHead, 2)
	new("TextLabel", { Text = "Search", Font = FONT_BOLD, TextSize = 20, Fg = "Text", Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = sHead })
	self.SearchInfo = new("TextLabel", { Text = "", TextSize = 12, Fg = "SubText", Size = UDim2.new(1, 0, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2, Parent = sHead })

	if opts.ToggleButton ~= false then
		local holder = new("Frame", {
			Name = "ToggleButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -36, 0, 60),
			Size = UDim2.fromOffset(TOG_SIZE, TOG_SIZE), Parent = Gui,
		})
		local ripple = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1),
			Bg = "Accent", BackgroundTransparency = 1, ZIndex = 1, Parent = holder,
		})
		round(ripple)
		local function pulse()
			ripple.Size = UDim2.fromScale(1, 1)
			ripple.BackgroundTransparency = 0.55
			tween(ripple, { Size = UDim2.fromScale(1.7, 1.7), BackgroundTransparency = 1 }, 0.5, Enum.EasingStyle.Quad)
		end

		local fb = new("Frame", { Name = "Body", Size = UDim2.fromScale(1, 1), Bg = "Sidebar", ZIndex = 2, Parent = holder })
		round(fb)
		gradient(fb, 150)
		local fst = stroke(fb, "Accent", 1.5)
		local ringGrad = new("UIGradient", {
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 0) }),
			Parent = fst,
		})
		TweenService:Create(ringGrad, TweenInfo.new(3.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, false), { Rotation = 360 }):Play()

		local inner = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -10, 1, -10),
			Bg = "Element", Parent = fb,
		})
		round(inner)
		stroke(inner)
		gradient(inner, 170)
		local toggleCrown = makeIcon(inner, "crown", 18, "Accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0) })
		local function syncCrown()
			if headerCrown.Image ~= "" then
				toggleCrown.Image = headerCrown.Image
				toggleCrown.ImageTransparency = 0
				local g = toggleCrown:FindFirstChild("Glyph")
				if g then g.Visible = false end
			end
		end
		syncCrown()
		connect(headerCrown:GetPropertyChangedSignal("Image"), syncCrown)
		TweenService:Create(toggleCrown, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = UDim2.new(0.5, 0, 0.5, -2),
		}):Play()

		local fsc = new("UIScale", { Parent = fb })
		local fhit = hitZone(holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(TOG_SIZE + 20, TOG_SIZE + 20), ZIndex = 5 })
		onHover(fhit,
			function() tween(fsc, { Scale = 1.08 }, 0.15, Enum.EasingStyle.Quad) end,
			function() tween(fsc, { Scale = 1 }, 0.2) end)
		connect(fhit.MouseButton1Down, function() tween(fsc, { Scale = 0.9 }, 0.08) end)
		connect(fhit.MouseButton1Up, function() tween(fsc, { Scale = IS_TOUCH and 1 or 1.08 }, 0.25, Enum.EasingStyle.Back) end)
		draggable(fhit, holder, function()
			self:Toggle()
			pulse()
			local s = holder.AbsoluteSize.X / TOG_SIZE
			local c = Vector2.new(holder.AbsolutePosition.X + holder.AbsoluteSize.X / 2, holder.AbsolutePosition.Y + holder.AbsoluteSize.Y / 2)
			FX.ring(c, Theme.Accent, 28 * s, 84 * s, 0.55, 0.18)
			FX.burst(c, Theme.Accent, 5, 34 * s, { Size = 9 * s })
			toggleCrown.Rotation = 0
			tween(toggleCrown, { Rotation = 360 }, 0.5, Enum.EasingStyle.Quint)
			task.delay(0.55, function()
				if toggleCrown.Parent then toggleCrown.Rotation = 0 end
			end)
		end)
	end

	connect(UserInputService.InputBegan, function(i, gp)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if Library.Listening then return end
		if i.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
			if not self.Visible then self:Toggle(true) end
			if self.Minimized then self:SetMinimized(false) end
			task.defer(function()
				sbox:CaptureFocus()
				task.wait()
				sbox.Text = ""
			end)
			return
		end
		if sbox:IsFocused() then
			local kc = i.KeyCode
			if kc == Enum.KeyCode.Down then
				self:_moveSel(1)
			elseif kc == Enum.KeyCode.Up then
				self:_moveSel(-1)
			elseif kc == Enum.KeyCode.Escape then
				self:ClearSearch()
				sbox:ReleaseFocus()
			end
			return
		end
		if not gp and i.KeyCode == self.ToggleKey then self:Toggle() end
	end)

	local cam = workspace.CurrentCamera
	if cam then
		connect(cam:GetPropertyChangedSignal("ViewportSize"), function()
			if self.Visible then ScaleObj.Scale = self.Maximized and maxScale() or fitScale() end
		end)
	end

	local acc, frames = 0, 0
	connect(RunService.Heartbeat, function(dt)
		acc += dt
		frames += 1
		if acc >= 0.5 then
			self.Fps = frames / acc
			acc, frames = 0, 0
			local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			self.Ping = ok and ping or 0
			if self.ShowFPS or self.ShowPing then self:_statsRefresh() end
		end
	end)

	self:_init3D(headerCrown)

	tween(ScaleObj, { Scale = fitScale() }, 0.5, Enum.EasingStyle.Back)

	table.insert(Library.Windows, self)
	return self
end

do
	local Motion = {
		Tilt = true, Wave = true, Depth = true,
		Gyro = true, InvertGyro = false, Strength = 1,
	}
	Library.Motion = Motion

	function Library:SetMotion(key, value)
		Motion[key] = value
	end

	local function newSpring() return { x = 0, v = 0 } end
	local function stepSpring(s, target, dt, k, d)
		s.v += ((target - s.x) * k - s.v * d) * dt
		s.x += s.v * dt
	end
	local function sat(x) return math.clamp(x, -1, 1) end

	local PLATES = 4
	local KP = NumberSequenceKeypoint.new

	function Window:_init3D(headerCrown)
		local main = self.Main
		local outline = main:FindFirstChild("Outline")
		local crownTile = headerCrown and headerCrown.Parent
		self.FxShow = self.Visible ~= false

		local tilt = new("Frame", {
			Name = "Tilt", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1), Parent = main,
		})
		local tiltScale = new("UIScale", { Name = "TiltScale", Parent = tilt })

		local shadowHolder = self.Shadow and self.Shadow.Holder
		if shadowHolder then shadowHolder.Parent = tilt end

		local plates = {}
		for k = 1, PLATES do
			local f = new("Frame", {
				Name = "Plate" .. k, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -k * 3.5, 1, -k * 3.5), Bg = "Sidebar", BackgroundTransparency = 1, ZIndex = 0, Parent = tilt,
			})
			corner(f, 12)
			local st = stroke(f, "Stroke", 1)
			st.Transparency = 1
			plates[k] = { Frame = f, Stroke = st, Base = 0.4 + k * 0.1 }
		end

		self.Canvas.Parent = tilt
		if outline then outline.Parent = tilt end
		self.Ctrls.Parent = tilt

		local glare, glareGrad, rimStroke, rimGrad
		if outline then
			glare = new("Frame", {
				Name = "Glare", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
				BackgroundTransparency = 1, Active = false, Parent = outline,
			})
			corner(glare, 12)
			glareGrad = new("UIGradient", {
				Rotation = 28,
				Transparency = NumberSequence.new({ KP(0, 1), KP(0.25, 0.985), KP(0.5, 0.93), KP(0.75, 0.985), KP(1, 1) }),
				Parent = glare,
			})
			local rim = new("Frame", { Name = "Rim", Size = UDim2.fromScale(1, 1), Active = false, Parent = outline })
			corner(rim, 12)
			rimStroke = stroke(rim, "Accent", 1)
			rimStroke.Transparency = 1
			rimGrad = new("UIGradient", {
				Transparency = NumberSequence.new({ KP(0, 1), KP(0.5, 1), KP(0.8, 0.45), KP(0.95, 0.1), KP(1, 0.1) }),
				Parent = rimStroke,
			})
		end

		local px, py, lift, press = newSpring(), newSpring(), newSpring(), newSpring()
		local show, calm = 1, 1
		local t0 = os.clock()
		local touch, mouseDown, lastC, baseline = nil, false, nil, nil

		local function inside(pos)
			local ap, as = main.AbsolutePosition, main.AbsoluteSize
			return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
		end

		connect(UserInputService.InputBegan, function(i)
			if not self.FxShow then return end
			local ty = i.UserInputType
			if ty == Enum.UserInputType.Touch then
				if inside(i.Position) then touch = i end
			elseif ty == Enum.UserInputType.MouseButton1 then
				if inside(i.Position) then mouseDown = true end
			end
		end)
		connect(UserInputService.InputEnded, function(i)
			if i == touch then touch = nil end
			if i.UserInputType == Enum.UserInputType.MouseButton1 then mouseDown = false end
		end)

		local function aim(x, y, cx, cy, as)
			local dx, dy = (x - cx) / (as.X * 0.6), (y - cy) / (as.Y * 0.6)
			local fade = 1 - math.clamp((math.max(math.abs(dx), math.abs(dy)) - 1.4) / 2, 0, 1)
			return sat(dx) * fade, sat(dy) * fade
		end

		local function gyro(dt)
			if not (Motion.Gyro and UserInputService.GyroscopeEnabled) then return 0, 0 end
			local ok, _, cf = pcall(UserInputService.GetDeviceRotation, UserInputService)
			if not ok or typeof(cf) ~= "CFrame" then return 0, 0 end
			baseline = baseline or cf
			baseline = baseline:Lerp(cf, math.min(1, dt * 0.6))
			local rx, ry = (baseline:Inverse() * cf):ToEulerAnglesXYZ()
			local sign = Motion.InvertGyro and -1 or 1
			return sat(ry / 0.3) * sign, sat(-rx / 0.3) * sign
		end

		local L = {}
		local function chg(k, v, eps)
			local o = L[k]
			if o == nil or math.abs(v - o) >= eps then
				L[k] = v
				return true
			end
			return false
		end
		local sdt = 1 / 60

		connect(RunService.RenderStepped, function(dt)
			dt = math.min(dt, 1 / 20)
			sdt += (dt - sdt) * 0.15
			dt = sdt
			show += ((self.FxShow and 1 or 0) - show) * math.min(1, dt * 12)
			if not main.Visible or (show < 0.01 and not self.FxShow) then
				lastC = nil
				return
			end
			if touch and (touch.UserInputState == Enum.UserInputState.End or touch.UserInputState == Enum.UserInputState.Cancel) then
				touch = nil
			end

			local S = Motion.Strength
			local t = os.clock() - t0
			local w = Motion.Wave and 1 or 0
			local amp = S * (IS_TOUCH and 1.3 or 1)

			local typing = UserInputService:GetFocusedTextBox() ~= nil
			local still = (SliderLock.Active or Library.OpenPopup or Library._confirm or typing) and 0 or 1
			calm += (still - calm) * math.min(1, dt * 9)

			local ap, as = main.AbsolutePosition, main.AbsoluteSize
			local cx, cy = ap.X + as.X / 2, ap.Y + as.Y / 2

			local tx, ty, near = 0, 0, 0
			if Motion.Tilt and as.X > 0 and as.Y > 0 then
				if touch then
					tx, ty = aim(touch.Position.X, touch.Position.Y, cx, cy, as)
					near = 1
				elseif not IS_TOUCH then
					local m = UserInputService:GetMouseLocation()
					tx, ty = aim(m.X, m.Y, cx, cy, as)
					near = inside(m) and 1 or 0
				else
					tx, ty = gyro(dt)
				end
			end

			local swx, swy = 0, 0
			if lastC and Motion.Tilt then
				local idt = 1 / math.max(dt, 1e-3)
				swx = sat(-(cx - lastC.X) * idt / 1800)
				swy = sat(-(cy - lastC.Y) * idt / 1800)
			end
			lastC = Vector2.new(cx, cy)

			stepSpring(px, sat(tx + swx * 0.9), dt, 140, 16)
			stepSpring(py, sat(ty + swy * 0.9), dt, 140, 16)
			stepSpring(lift, near, dt, 120, 14)
			stepSpring(press, (mouseDown or touch) and 1 or 0, dt, 220, 16)

			local wx = (math.sin(t * 0.9) + 0.45 * math.sin(t * 1.9 + 1.3)) * 0.7 * w
			local wy = (math.cos(t * 0.75 + 0.6) + 0.45 * math.sin(t * 1.5 + 2.1)) * 0.7 * w
			local bob = (math.sin(t * 1.15) + 0.35 * math.sin(t * 2.3 + 0.8)) * w

			local TX = (px.x * S + wx * 0.34 * amp) * calm
			local TY = (py.x * S + wy * 0.34 * amp) * calm
			local lf = lift.x * calm
			local pr = press.x * calm

			local tpx, tpy = TX * 3.2, TY * 2.6 + bob * 2.4 * amp * calm
			local c1, c2 = chg("tpx", tpx, 0.01), chg("tpy", tpy, 0.01)
			if c1 or c2 then tilt.Position = UDim2.new(0.5, tpx, 0.5, tpy) end
			if chg("trot", TX * 0.9, 0.002) then tilt.Rotation = TX * 0.9 end
			local tsc = 1 + (lf * 0.010 - pr * 0.010)
			if chg("tsc", tsc, 0.0003) then tiltScale.Scale = tsc end

			if shadowHolder then
				local sx, sy = -TX * 9 * S, 5 + lf * 4 - TY * 9 * S - bob * 1.6 * calm
				local s1, s2 = chg("shx", sx, 0.02), chg("shy", sy, 0.02)
				if s1 or s2 then shadowHolder.Position = UDim2.new(0.5, sx, 0.5, sy) end
			end

			local a = show * (Motion.Depth and 1 or 0) * (1 - math.clamp((Library.Transparency - 0.1) * 1.4, 0, 0.9))
			local qx, qy = TX + wx * 0.2 * w * calm, TY + wy * 0.2 * w * calm
			local aChanged = chg("plA", a, 0.004)
			for k, pl in ipairs(plates) do
				local lag = math.sin(t * 1.3 - k * 0.8) * 0.45 * k * w * S * calm
				local plx, ply = -qx * k * 1.5 * S + lag, -qy * k * 1.5 * S + k * 0.5
				local p1, p2 = chg("plx" .. k, plx, 0.02), chg("ply" .. k, ply, 0.02)
				if p1 or p2 then pl.Frame.Position = UDim2.new(0.5, plx, 0.5, ply) end
				if aChanged then
					pl.Frame.BackgroundTransparency = 1 - (1 - pl.Base) * a
					pl.Stroke.Transparency = 1 - 0.55 * a * (1 - (k - 1) * 0.18)
				end
			end

			local mag = math.min(1, math.sqrt(TX * TX + TY * TY))
			if glare then
				local go = math.clamp(TX * 0.55 + TY * 0.2, -0.85, 0.85)
				if chg("glo", go, 0.004) then glareGrad.Offset = Vector2.new(go, 0) end
				local gt = 1 - show * (0.55 + 0.45 * math.clamp(lf, 0, 1))
				if chg("glt", gt, 0.003) then glare.BackgroundTransparency = gt end
				local rr = math.deg(math.atan2(TY, TX))
				if chg("rimr", rr, 0.5) then rimGrad.Rotation = rr end
				local rt = 1 - math.clamp(0.12 + mag * 0.6, 0, 1) * show
				if chg("rimt", rt, 0.004) then rimStroke.Transparency = rt end
			end

			local IX, IY = px.x * S * calm, py.x * S * calm
			if crownTile then
				local cxp, cyp = 12 + IX * 2.4, IY * 2.4
				local k1, k2 = chg("crx", cxp, 0.05), chg("cry", cyp, 0.05)
				if k1 or k2 then crownTile.Position = UDim2.new(0, cxp, 0.5, cyp) end
			end
			if self.TitleBlock then
				local txp, typ = TITLE_X + IX * 1.2, IY * 1.2
				local k1, k2 = chg("ttx", txp, 0.05), chg("tty", typ, 0.05)
				if k1 or k2 then self.TitleBlock.Position = UDim2.fromOffset(txp, typ) end
			end
			if self.UserCard then
				local uxp, uyp = 8 + IX * 1.6, -8 + IY * 1.6
				local k1, k2 = chg("ucx", uxp, 0.05), chg("ucy", uyp, 0.05)
				if k1 or k2 then self.UserCard.Position = UDim2.new(0, uxp, 1, uyp) end
			end
		end)
	end
end

env.__ZystrixUI = Library

if env.ZystrixUI_NoDemo or env.MystrixUI_NoDemo then return Library end

local function RunDemo()

local Window = Library:CreateWindow({
	Title = "ZystrixUI Tester",
	Subtitle = "Component playground",
	Version = "v2.0",
	ConfigFolder = "ZystrixTester",
	ToggleKey = Enum.KeyCode.J,
})

local function stamp() return os.date("%H:%M:%S") end

Window:CreateDashboard({
	Name = "Home", Icon = "home", Group = "TESTER",
	Discord = "discord.gg/yourinvite",
})
local Overview = Window:AddTab({
	Name = "Overview", Icon = "info", Group = "TESTER",
	Description = "Playground for testing every ZystrixUI component.",
})
local about = Overview:AddSection({ Name = "About", Icon = "info", Side = "Left" })
about:AddLabel({ Title = "ZystrixUI Tester", Text = "Pick a tab in the sidebar to test switches, sliders, inputs, dropdowns, keybinds, buttons, layout, checkboxes, radios, chips, steppers, progress bars, color pickers and the live console." })
about:AddButton({ Name = "Test Notification", Icon = "info", Style = "Primary", Callback = function()
	Library:Notify({ Title = "Tester", Content = "Notification shown at " .. stamp(), Icon = "info" })
end })

local mon = Overview:AddSection({ Name = "Flag Monitor", Icon = "eye", Side = "Right" })
local monLabel = mon:AddLabel({ Title = "Flags", Text = "Press Refresh to see the value of every flag." })
mon:AddButton({ Name = "Refresh Flags", Icon = "refresh", Callback = function()
	local keys = {}
	for k in pairs(Library.Flags) do keys[#keys + 1] = k end
	table.sort(keys)
	local lines = {}
	for i, k in ipairs(keys) do
		if i > 14 then
			lines[#lines + 1] = "... +" .. (#keys - 14) .. " more"
			break
		end
		lines[#lines + 1] = k .. " = " .. tostring(Library.Flags[k])
	end
	monLabel:Set("Flags (" .. #keys .. ")", #lines > 0 and table.concat(lines, "\n") or "No flags yet.")
end })

local Switches = Window:AddTab({
	Name = "Switch", Icon = "toggle", Group = "TESTER",
	Description = "Switch test: large tap area, instant response, no flicker.",
})
local sb = Switches:AddSection({ Name = "Basic Switch", Icon = "toggle", Side = "Left" })
sb:AddToggle({ Name = "Switch Off (default)", Icon = "toggle", Default = false, Flag = "T_Off" })
sb:AddToggle({ Name = "Switch On (default)", Icon = "check", Default = true, Flag = "T_On" })
sb:AddToggle({ Name = "Switch + Notification", Icon = "info", Flag = "T_Notify", Callback = function(v)
	Library:Notify({ Title = "Switch", Content = v and "Enabled" or "Disabled", Duration = 2 })
end })
sb:AddDivider("Spam Test")
local spamLabel = sb:AddLabel({ Title = "Changes: 0", Text = "Click the switch below rapidly. It must not flicker or get stuck." })
local spamCount = 0
sb:AddToggle({ Name = "Spam Click", Icon = "click", Flag = "T_Spam", Callback = function()
	spamCount += 1
	spamLabel:Set("Changes: " .. spamCount)
end })

local sm = Switches:AddSection({ Name = "Master / Child", Icon = "link", Side = "Right" })
local childFlags = { "T_Child1", "T_Child2", "T_Child3" }
local countLabel = sm:AddLabel({ Title = "Enabled: 0 / 3", Text = "The master switch turns every child on / off." })
local function recount()
	local n = 0
	for _, f in ipairs(childFlags) do
		if Library.Flags[f] then n += 1 end
	end
	countLabel:Set("Enabled: " .. n .. " / " .. #childFlags)
end
sm:AddToggle({ Name = "Master Switch", Icon = "link", Flag = "T_Master", Callback = function(v)
	for _, f in ipairs(childFlags) do
		local o = Library.Options[f]
		if o then o:Set(v, true) end
	end
	recount()
end })
for i, f in ipairs(childFlags) do
	sm:AddToggle({ Name = "Child " .. i, Icon = "check", Flag = f, Callback = recount })
end

local Sliders = Window:AddTab({
	Name = "Slider", Icon = "slider", Group = "TESTER",
	Description = "Slider test: drag, tap on the track, or type a value in the small box.",
})
local si = Sliders:AddSection({ Name = "Integer", Icon = "hash", Side = "Left" })
local lastInt = si:AddLabel({ Title = "Last value", Text = "-" })
si:AddSlider({ Name = "Walk Speed", Icon = "bolt", Min = 16, Max = 200, Default = 16, Increment = 1, Flag = "S_Walk", Callback = function(v)
	lastInt:Set(nil, "Walk Speed = " .. v)
end })
si:AddSlider({ Name = "Jump Power", Icon = "up", Min = 0, Max = 300, Default = 50, Increment = 5, Flag = "S_Jump", Suffix = " st", Callback = function(v)
	lastInt:Set(nil, "Jump Power = " .. v)
end })
si:AddSlider({ Name = "Percent", Icon = "percent", Min = 0, Max = 100, Default = 50, Increment = 1, Flag = "S_Percent", Suffix = "%" })

local sd = Sliders:AddSection({ Name = "Decimal & Range", Icon = "percent", Side = "Right" })
local lastDec = sd:AddLabel({ Title = "Last value", Text = "-" })
sd:AddSlider({ Name = "Gravity Scale", Icon = "down", Min = 0, Max = 2, Default = 1, Increment = 0.05, Flag = "S_Gravity", Suffix = "x", Callback = function(v)
	lastDec:Set(nil, "Gravity Scale = " .. v)
end })
sd:AddSlider({ Name = "Brightness", Icon = "sun", Min = 0, Max = 1, Default = 0.5, Increment = 0.01, Flag = "S_Bright", Callback = function(v)
	lastDec:Set(nil, "Brightness = " .. v)
end })
sd:AddSlider({ Name = "Negative", Icon = "contrast", Min = -100, Max = 100, Default = 0, Increment = 5, Flag = "S_Neg" })
sd:AddSlider({ Name = "Large Range", Icon = "hash", Min = 0, Max = 10000, Default = 2500, Increment = 50, Flag = "S_Big" })
sd:AddButton({ Name = "Reset All Sliders", Icon = "refresh", Callback = function()
	local defaults = {
		S_Walk = 16, S_Jump = 50, S_Percent = 50, S_Gravity = 1, S_Bright = 0.5, S_Neg = 0, S_Big = 2500,
	}
	for flag, v in pairs(defaults) do
		local o = Library.Options[flag]
		if o then o:Set(v, true) end
	end
	lastInt:Set(nil, "Reset")
	lastDec:Set(nil, "Reset")
end })

local Inputs = Window:AddTab({
	Name = "Input", Icon = "input", Group = "TESTER",
	Description = "Input box and keybind test.",
})
local it = Inputs:AddSection({ Name = "Input Box", Icon = "input", Side = "Left" })
local echo = it:AddLabel({ Title = "Echo", Text = "Type something, the text shows up live as you type." })
local nameBox = it:AddTextbox({ Name = "Username", Icon = "user", Placeholder = "Type a name...", Flag = "I_Name",
	OnChanged = function(v)
		echo:SetLive("Echo", v == "" and "(empty)" or ("Typing: " .. v))
	end,
	Callback = function(v)
		echo:Set("Echo", v == "" and "(empty)" or ("Username = " .. v))
	end })
it:AddTextbox({ Name = "Numbers Only", Icon = "hash", Placeholder = "0 - 100", Flag = "I_Number",
	OnChanged = function(v)
		echo:SetLive("Echo", v == "" and "(empty)" or ("Typing: " .. v))
	end,
	Callback = function(v)
	local n = tonumber(v)
	if n then
		echo:Set("Echo", "Valid number: " .. math.clamp(n, 0, 100))
	else
		echo:Set("Echo", "\"" .. v .. "\" is not a number")
		Library:Notify({ Title = "Input", Content = "Enter a valid number.", Duration = 2 })
	end
end })
it:AddTextbox({ Name = "Long Text", Icon = "edit", Placeholder = "Truncation test...", Default = "A very long piece of text to test clipping inside the input box", Flag = "I_Long" })
it:AddButton({ Name = "Clear Username", Icon = "trash", Callback = function()
	nameBox:Set("")
end })

local ik = Inputs:AddSection({ Name = "Keybind", Icon = "keyboard", Side = "Right" })
ik:AddLabel({ Title = "How to use", Text = "Tap the button, then press a keyboard key. Esc = cancel, Backspace = clear." })
ik:AddKeybind({ Name = "Action Key", Icon = "keyboard", Default = Enum.KeyCode.F, Flag = "K_Action", Callback = function(k)
	Library:Notify({ Title = "Keybind", Content = "Pressed: " .. k.Name, Duration = 2 })
end })
ik:AddKeybind({ Name = "No Default", Icon = "key", Flag = "K_None", Callback = function(k)
	Library:Notify({ Title = "Keybind", Content = "Pressed: " .. k.Name, Duration = 2 })
end, Changed = function(k)
	Library:Notify({ Title = "Keybind", Content = "Changed to: " .. (k and k.Name or "None"), Duration = 2 })
end })

local Drops = Window:AddTab({
	Name = "Dropdown", Icon = "list", Group = "TESTER",
	Description = "Dropdown test: short list, long list (scroll) and dynamic list.",
})
local dr = Drops:AddSection({ Name = "Basic", Icon = "list", Side = "Left" })
local dropEcho = dr:AddLabel({ Title = "Last selection", Text = "-" })
dr:AddDropdown({ Name = "Mode", Icon = "list", Options = { "Teleport", "Drive", "Safe" }, Default = "Teleport", Flag = "D_Mode", Callback = function(v)
	dropEcho:Set(nil, "Mode = " .. tostring(v))
end })
local longList = {}
for i = 1, 14 do longList[i] = "Item " .. i end
dr:AddDropdown({ Name = "Long List", Icon = "grid", Options = longList, Placeholder = "Select an item...", Flag = "D_Long", Callback = function(v)
	dropEcho:Set(nil, "Long List = " .. tostring(v))
end })

local dd = Drops:AddSection({ Name = "Dynamic", Icon = "refresh", Side = "Right" })
local dynItems = { "Alpha", "Beta" }
local dyn = dd:AddDropdown({ Name = "Dynamic List", Icon = "refresh", Options = dynItems, Placeholder = "Empty", Flag = "D_Dyn" })
dd:AddButton({ Name = "Add Option", Icon = "plus", Callback = function()
	dynItems[#dynItems + 1] = "Option " .. (#dynItems + 1)
	dyn:Refresh(dynItems)
end })
dd:AddButton({ Name = "Reset List", Icon = "refresh", Callback = function()
	dynItems = { "Alpha", "Beta" }
	dyn:Refresh(dynItems)
end })

local Buttons = Window:AddTab({
	Name = "Button", Icon = "click", Group = "TESTER",
	Description = "Button and notification test.",
})
local bt = Buttons:AddSection({ Name = "Buttons", Icon = "click", Side = "Left" })
bt:AddButton({ Name = "Primary Button", Style = "Primary", Icon = "crown", Callback = function()
	Library:Notify({ Title = "Button", Content = "Primary clicked", Duration = 2 })
end })
bt:AddButton({ Name = "Normal Button", Icon = "link", Callback = function()
	Library:Notify({ Title = "Button", Content = "Normal clicked", Duration = 2 })
end })
bt:AddButton({ Name = "No Icon", Callback = function()
	Library:Notify({ Title = "Button", Content = "No-icon button clicked", Duration = 2 })
end })
local clicks = 0
local counterBtn
counterBtn = bt:AddButton({ Name = "Clicked: 0", Icon = "plus", Callback = function()
	clicks += 1
	counterBtn:SetText("Clicked: " .. clicks)
end })

local nt = Buttons:AddSection({ Name = "Notifications", Icon = "info", Side = "Right" })
nt:AddButton({ Name = "Short Notification", Icon = "info", Callback = function()
	Library:Notify({ Title = "Short", Content = "Hello!", Duration = 3 })
end })
nt:AddButton({ Name = "Long Notification", Icon = "clock", Callback = function()
	Library:Notify({
		Title = "Long Notification",
		Content = "This is a fairly long piece of text used to check that the notification height adapts to its content and nothing gets cut off at the bottom.",
		Duration = 6,
	})
end })
nt:AddButton({ Name = "Spam 3 Notifications", Icon = "plus", Callback = function()
	for i = 1, 3 do
		task.delay((i - 1) * 0.25, function()
			Library:Notify({ Title = "Notification " .. i, Content = "Sent at " .. stamp(), Duration = 3 })
		end)
	end
end })

local Layout = Window:AddTab({ Name = "Layout", Icon = "grid", Group = "TESTER", NoPage = true })

local colTab = Layout:AddSubTab({ Name = "Columns", Icon = "columns", Description = "Two columns side by side." })
local cl = colTab:AddSection({ Name = "Left Column", Icon = "columns", Side = "Left" })
cl:AddLabel({ Title = "Left", Text = "This section is in the left column." })
cl:AddToggle({ Name = "Left Toggle", Icon = "toggle", Flag = "L_Left" })
local cr = colTab:AddSection({ Name = "Right Column", Icon = "columns", Side = "Right" })
cr:AddLabel({ Title = "Right", Text = "This section is in the right column." })
cr:AddToggle({ Name = "Right Toggle", Icon = "toggle", Flag = "L_Right" })

local scrollTab = Layout:AddSubTab({ Name = "Scroll", Icon = "down", Description = "Test a long page with many elements." })
local ls = scrollTab:AddSection({ Name = "Many Elements", Icon = "list" })
for i = 1, 14 do
	ls:AddToggle({ Name = "Toggle #" .. i, Icon = "hash", Flag = "L_Many" .. i })
end
ls:AddSlider({ Name = "Bottom Slider", Icon = "slider", Min = 0, Max = 100, Default = 40, Flag = "L_Bottom" })

local colpTab = Layout:AddSubTab({ Name = "Collapse", Icon = "list", Description = "Collapsible sections." })
local c1 = colpTab:AddSection({ Name = "Open (tap the header)", Icon = "chevron" })
c1:AddToggle({ Name = "Content A", Icon = "check", Flag = "L_A" })
c1:AddToggle({ Name = "Content B", Icon = "check", Flag = "L_B" })
local c2 = colpTab:AddSection({ Name = "Collapsed at start", Icon = "chevron", Collapsed = true })
c2:AddToggle({ Name = "Content C", Icon = "check", Flag = "L_C" })
c2:AddSlider({ Name = "Content D", Icon = "slider", Min = 0, Max = 10, Default = 5, Flag = "L_D" })

do
	local function fmt(v)
		local t = typeof(v)
		if t == "Color3" then return "#" .. v:ToHex():upper() end
		if t == "EnumItem" then return v.Name end
		if t == "table" then
			local parts = {}
			for _, x in ipairs(v) do parts[#parts + 1] = tostring(x) end
			return "{" .. table.concat(parts, ", ") .. "}"
		end
		return tostring(v)
	end

	local Choice = Window:AddTab({
		Name = "Choice", Icon = "check", Group = "TESTER",
		Description = "Checkbox, radio, segmented control and multi select chips.",
	})

	local ck = Choice:AddSection({ Name = "Checkbox", Icon = "check", Side = "Left" })
	ck:AddCheckbox({ Name = "Option A", Icon = "check", Flag = "C_A" })
	ck:AddCheckbox({ Name = "Option B", Icon = "check", Default = true, Flag = "C_B" })
	ck:AddCheckbox({ Name = "With Notification", Icon = "info", Flag = "C_Notify", Callback = function(v)
		Library:Notify({ Title = "Checkbox", Content = v and "Checked" or "Unchecked", Duration = 2, Icon = "check" })
	end })
	ck:AddDivider("Select All")
	local groupFlags = { "C_G1", "C_G2", "C_G3" }
	local groupInfo = ck:AddLabel({ Title = "Checked: 0 / 3", Text = "The first checkbox controls the other three." })
	local function regroup()
		local n = 0
		for _, f in ipairs(groupFlags) do
			if Library.Flags[f] then n += 1 end
		end
		groupInfo:Set("Checked: " .. n .. " / " .. #groupFlags)
	end
	ck:AddCheckbox({ Name = "Select All", Icon = "list", Flag = "C_Master", Callback = function(v)
		for i, f in ipairs(groupFlags) do
			task.delay((i - 1) * 0.07, function()
				local ob = Library.Options[f]
				if ob then ob:Set(v, true) end
				if i == #groupFlags then regroup() end
			end)
		end
	end })
	for i, f in ipairs(groupFlags) do
		ck:AddCheckbox({ Name = "Item " .. i, Icon = "hash", Flag = f, Callback = regroup })
	end

	local ch = Choice:AddSection({ Name = "Chips", Icon = "hash", Side = "Left" })
	local chipInfo = ch:AddLabel({ Title = "Selected", Text = "Coins, Gems" })
	ch:AddChips({
		Name = "Collect Targets", Icon = "grid", Options = { "Coins", "Gems", "Chests", "Quests", "Pets", "Keys", "Eggs" },
		Default = { "Coins", "Gems" }, Flag = "CH_Targets", Callback = function(list)
			chipInfo:Set(nil, #list > 0 and table.concat(list, ", ") or "Nothing selected")
		end,
	})

	local rd = Choice:AddSection({ Name = "Radio and Segmented", Icon = "list", Side = "Right" })
	local choiceInfo = rd:AddLabel({ Title = "Last change", Text = "-" })
	rd:AddRadio({
		Name = "Target Part", Icon = "user", Options = { "Head", "Torso", "Legs", "Random" }, Default = "Head", Flag = "R_Part",
		Callback = function(v) choiceInfo:Set(nil, "Target Part = " .. tostring(v)) end,
	})
	rd:AddRadio({
		Name = "Sort By", Icon = "list", Options = { "Name", "Level", "Rarity" }, Flag = "R_Sort",
		Callback = function(v) choiceInfo:Set(nil, "Sort By = " .. tostring(v)) end,
	})
	rd:AddSegmented({
		Name = "Speed Mode", Icon = "bolt", Options = { "Slow", "Normal", "Fast" }, Default = "Normal", Flag = "G_Speed",
		Callback = function(v) choiceInfo:Set(nil, "Speed Mode = " .. tostring(v)) end,
	})
	rd:AddSegmented({
		Name = "Time Of Day", Icon = "sun", Options = { "Dawn", "Day", "Dusk", "Night" }, Default = "Day", Flag = "G_Time",
		Callback = function(v) choiceInfo:Set(nil, "Time Of Day = " .. tostring(v)) end,
	})

	local ValueTab = Window:AddTab({
		Name = "Value", Icon = "percent", Group = "TESTER",
		Description = "Stepper with press and hold, progress bar and color picker.",
	})

	local sp = ValueTab:AddSection({ Name = "Stepper", Icon = "plus", Side = "Left" })
	local stepInfo = sp:AddLabel({ Title = "Last change", Text = "Press and hold + or - to repeat faster." })
	sp:AddStepper({ Name = "Quantity", Icon = "hash", Min = 0, Max = 20, Step = 1, Default = 5, Flag = "V_Qty", Callback = function(v)
		stepInfo:Set(nil, "Quantity = " .. v)
	end })
	sp:AddStepper({ Name = "Delay", Icon = "clock", Min = 0, Max = 2, Step = 0.1, Default = 0.5, Suffix = "s", Flag = "V_Delay", Callback = function(v)
		stepInfo:Set(nil, "Delay = " .. v .. "s")
	end })
	sp:AddStepper({ Name = "Power", Icon = "bolt", Min = 0, Max = 500, Step = 25, Default = 100, Flag = "V_Power", Callback = function(v)
		stepInfo:Set(nil, "Power = " .. v)
	end })

	local pg = ValueTab:AddSection({ Name = "Progress", Icon = "pulse", Side = "Right" })
	local prog = pg:AddProgress({ Name = "Download", Icon = "down", Default = 0, OnComplete = function()
		Library:Notify({ Title = "Progress", Content = "Download complete.", Duration = 2.5, Icon = "check" })
	end })
	local runId = 0
	local function runProgress()
		runId += 1
		local my = runId
		prog:Set(0, true)
		task.spawn(function()
			local val = 0
			task.wait(0.25)
			while val < 100 and runId == my do
				val = math.min(100, val + math.random(3, 12))
				prog:Set(val)
				task.wait(0.22)
			end
		end)
	end
	pg:AddButton({ Name = "Run Progress", Icon = "bolt", Style = "Primary", Callback = runProgress })
	pg:AddButton({ Name = "Reset Progress", Icon = "refresh", ButtonText = "Reset", Callback = function()
		runId += 1
		prog:Set(0)
	end })
	pg:AddDivider("Static")
	local staticBar = pg:AddProgress({ Name = "Loaded", Icon = "server", Default = 65 })
	pg:AddButton({ Name = "Random Value", Icon = "refresh", ButtonText = "Roll", Callback = function()
		staticBar:Set(math.random(0, 100))
	end })

	local cp = ValueTab:AddSection({ Name = "Color Picker", Icon = "palette", Side = "Left" })
	local pvRow = makeRow(cp, 46)
	local pvBar = new("Frame", {
		Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, Parent = pvRow,
	})
	corner(pvBar, 8)
	local pvGrad = new("UIGradient", { Parent = pvBar })
	TweenService:Create(pvGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false), { Rotation = 360 }):Play()
	local colA, colB = Color3.fromRGB(59, 130, 246), Color3.fromRGB(236, 72, 153)
	local colInfo = cp:AddLabel({ Title = "Gradient", Text = "Pick two colors to update the preview above." })
	local function refreshPv()
		pvGrad.Color = ColorSequence.new(colA, colB)
		colInfo:Set(nil, fmt(colA) .. "  to  " .. fmt(colB))
	end
	cp:AddColorPicker({ Name = "Color A", Icon = "palette", Default = colA, Flag = "P_ColorA", Callback = function(c)
		colA = c
		refreshPv()
	end })
	cp:AddColorPicker({ Name = "Color B", Icon = "palette", Default = colB, Flag = "P_ColorB", Callback = function(c)
		colB = c
		refreshPv()
	end })
	refreshPv()

	local Console = Window:AddTab({
		Name = "Console", Icon = "chat", Group = "TESTER",
		Description = "Live event log and stress tests for every component.",
	})

	local lg = Console:AddSection({ Name = "Event Log", Icon = "chat", Side = "Left" })
	local log = lg:AddLog({ Name = "Events", Height = 160, MaxLines = 60 })
	log:Log("Console ready.", "ok")
	lg:AddToggle({ Name = "Log Flag Changes", Icon = "eye", Default = true, Flag = "X_LogFlags" })
	lg:AddButton({ Name = "Log Info", Icon = "info", ButtonText = "Add", Callback = function()
		log:Log("Information message at " .. stamp(), "info")
	end })
	lg:AddButton({ Name = "Log Success", Icon = "check", ButtonText = "Add", Callback = function()
		log:Log("Operation completed at " .. stamp(), "ok")
	end })
	lg:AddButton({ Name = "Log Warning", Icon = "bolt", ButtonText = "Add", Callback = function()
		log:Log("Something looks unusual at " .. stamp(), "warn")
	end })
	lg:AddButton({ Name = "Log Error", Icon = "close", ButtonText = "Add", Callback = function()
		log:Log("Something failed at " .. stamp(), "err")
	end })
	lg:AddButton({ Name = "Spam 10 Logs", Icon = "plus", ButtonText = "Spam", Callback = function()
		local kinds = { "info", "ok", "warn", "err" }
		for i = 1, 10 do
			task.delay((i - 1) * 0.08, function()
				log:Log("Spam line " .. i, kinds[(i - 1) % #kinds + 1])
			end)
		end
	end })
	lg:AddButton({ Name = "Clear Log", Icon = "trash", ButtonText = "Clear", Callback = function() log:Clear() end })

	local lastLog = {}
	Library.OnFlagChanged = function(flag, value)
		if not Library.Flags.X_LogFlags or flag == "X_LogFlags" then return end
		local now = os.clock()
		if lastLog[flag] and now - lastLog[flag] < 0.12 then return end
		lastLog[flag] = now
		log:Log(flag .. " = " .. fmt(value), "info")
	end

	local stt = Console:AddSection({ Name = "Stress Tests", Icon = "bolt", Side = "Left" })

	local function skip(flag)
		return flag:find("^UI_") ~= nil or flag:find("^X_") ~= nil
	end

	stt:AddButton({ Name = "Randomize All Flags", Icon = "refresh", ButtonText = "Run", Callback = function()
		local n = 0
		for flag, ob in pairs(Library.Options) do
			if not skip(flag) then
				local t = ob.Type
				if t == "Toggle" or t == "Checkbox" then
					ob:Set(math.random() < 0.5)
					n += 1
				elseif t == "Slider" or t == "Stepper" then
					ob:Set(ob.Min + math.random() * (ob.Max - ob.Min))
					n += 1
				elseif (t == "Dropdown" or t == "Radio" or t == "Segmented") and #ob.Options > 0 then
					ob:Set(ob.Options[math.random(#ob.Options)])
					n += 1
				elseif t == "Chips" then
					local pick = {}
					for _, name in ipairs(ob.Options) do
						if math.random() < 0.5 then pick[#pick + 1] = name end
					end
					ob:Set(pick)
					n += 1
				elseif t == "Color" then
					ob:Set(Color3.fromHSV(math.random(), 0.65 + math.random() * 0.35, 0.8 + math.random() * 0.2))
					n += 1
				end
			end
		end
		log:Log("Randomized " .. n .. " flags.", "ok")
	end })

	local allState = false
	stt:AddButton({ Name = "Toggle All Switches", Icon = "toggle", ButtonText = "Flip", Callback = function()
		allState = not allState
		local i = 0
		for flag, ob in pairs(Library.Options) do
			if not skip(flag) and (ob.Type == "Toggle" or ob.Type == "Checkbox") then
				i += 1
				task.delay(i * 0.03, function() ob:Set(allState, true) end)
			end
		end
		log:Log("All switches set to " .. tostring(allState) .. " (" .. i .. ").", "info")
	end })

	local cycling = false
	stt:AddButton({ Name = "Cycle Themes", Icon = "palette", ButtonText = "Play", Callback = function()
		if cycling then return end
		cycling = true
		local start = Library.ThemeName
		task.spawn(function()
			for _, name in ipairs(Library.ThemeList) do
				Library:SetTheme(name)
				local th = Library.Options.UI_Theme
				if th then th:Set(name, true) end
				log:Log("Theme: " .. name, "info")
				task.wait(0.9)
			end
			Library:SetTheme(start)
			local th = Library.Options.UI_Theme
			if th then th:Set(start, true) end
			cycling = false
		end)
	end })

	stt:AddButton({ Name = "Effects Burst", Icon = "bolt", ButtonText = "Fire", Callback = function()
		local m = Window.Main
		local c = Vector2.new(m.AbsolutePosition.X + m.AbsoluteSize.X / 2, m.AbsolutePosition.Y + m.AbsoluteSize.Y / 2)
		local s = m.AbsoluteSize.X / BASE_W
		for k = 0, 2 do
			task.delay(k * 0.18, function()
				FX.ring(c, Theme.Accent, 30 * s, (140 + k * 60) * s, 0.7, 0.2)
			end)
		end
		FX.burst(c, Theme.Accent, 14, 120 * s, { Size = 12 * s })
	end })

	stt:AddButton({ Name = "Notification Flood", Icon = "info", ButtonText = "Send", Callback = function()
		for i = 1, 6 do
			task.delay((i - 1) * 0.15, function()
				Library:Notify({ Title = "Flood " .. i, Content = "Queue test at " .. stamp(), Duration = 3, Icon = "info" })
			end)
		end
	end })

	stt:AddButton({ Name = "Confirm Dialog", Icon = "shield", ButtonText = "Open", Callback = function()
		Library:Confirm({
			Title = "Test Dialog", Content = "Pick an option to see the result in the log.", ConfirmText = "Confirm", CancelText = "Cancel", Icon = "shield",
			Callback = function() log:Log("Dialog confirmed.", "ok") end,
			OnCancel = function() log:Log("Dialog cancelled.", "warn") end,
		})
	end })

	local touring = false
	stt:AddButton({ Name = "Tour All Tabs", Icon = "grid", Style = "Primary", Callback = function()
		if touring then return end
		touring = true
		task.spawn(function()
			for _, t in ipairs(Window.Tabs) do
				if t.Page then
					if t.ParentTab and not t.ParentTab.Expanded then Library._toggleSub(t.ParentTab) end
					Window:SelectTab(t)
					task.wait(1.1)
				end
			end
			Window:SelectTab(Console)
			log:Log("Tour finished.", "ok")
			touring = false
		end)
	end })
end

Window:CreateSettingsTab({ Group = "ACCOUNT" })

Window:LoadAutoConfig()
Library:Notify({ Title = "ZystrixUI Tester", Content = "Ready. Press J or the round button to open/close.", Duration = 5, Icon = "crown" })
end

local okDemo, errDemo = pcall(RunDemo)
if not okDemo then warn("[ZystrixUI] demo error: " .. tostring(errDemo)) end

return Library
 
