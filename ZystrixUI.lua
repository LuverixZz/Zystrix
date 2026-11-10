local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__MystrixUI then
	pcall(function() env.__MystrixUI:Unload() end)
end
if env.__ZystrixUI then
	pcall(function() env.__ZystrixUI:Unload() end)
end

local BASE_W, BASE_H = 640, 400
local HEADER_H, SIDEBAR_W, SEC_H = 40, 150, 36
local CTRL_BTN, CTRL_GAP = 28, 4
local CTRL_W = CTRL_BTN * 3 + CTRL_GAP * 2
local FONT, FONT_BOLD = Enum.Font.GothamMedium, Enum.Font.GothamBold
local ROOT = "ZystrixUI"
local ICON_DIR = ROOT .. "/icons"

local HasFS = (writefile and readfile and isfile and isfolder and makefolder) and true or false
local getAsset = getcustomasset or getsynasset

local AutoY, AutoX, AutoNone = Enum.AutomaticSize.Y, Enum.AutomaticSize.X, Enum.AutomaticSize.None

local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local USE_CANVAS_HIT = true

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
	Version = "1.4.0", ThemeName = "Monochrome",
	ThemeList = { "Monochrome", "Crimson", "Ocean", "Emerald", "Violet", "Amber" },
	Transparency = 0.1, ConfigFolder = ROOT, Listening = false,
}

local SliderLock = { Active = nil }

local Bound, Hooks, TransFrames = {}, {}, {}

local function connect(signal, fn)
	local c = signal:Connect(fn)
	Library.Connections[#Library.Connections + 1] = c
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
	if o:IsA("TextBox") then o.ClearTextOnFocus = false end
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
		ClipsDescendants = true, Parent = parent,
	})
	if props.Radius then corner(zone, props.Radius) end
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

local function i8(name) return "https://img.icons8.com/ios-glyphs/60/ffffff/" .. name .. ".png" end
local Icons = {
	crown = { i8("crown"), "*" }, home = { i8("home"), "H" }, main = { i8("monitor"), "M" },
	farm = { i8("synchronize"), "~" }, settings = { i8("settings"), "S" }, search = { i8("search"), "?" },
	close = { i8("multiply"), "x" }, minimize = { i8("minus"), "-" }, maximize = { i8("expand"), "+" },
	chevron = { i8("chevron-down"), "v" }, palette = { i8("paint-palette"), "P" },
	keyboard = { i8("keyboard"), "K" }, save = { i8("save"), "S" }, refresh = { i8("refresh"), "R" },
	folder = { i8("open-folder"), "F" }, trash = { i8("trash"), "X" }, user = { i8("user"), "U" },
	key = { i8("key"), "K" }, info = { i8("info"), "i" }, link = { i8("link"), "@" },
	bike = { i8("bicycle"), "B" }, eye = { i8("visible"), "o" }, globe = { i8("globe"), "O" },
}
Library.Icons = Icons

local IconCache, Pending = {}, {}

local function fetchAsset(source)
	if source:find("^rbxassetid://") or source:find("^rbxasset://") then return source end
	if tonumber(source) then return "rbxassetid://" .. source end
	if not getAsset or not HasFS then return nil end
	local path
	if source:find("^https?://") then
		ensureFolder(ROOT)
		ensureFolder(ICON_DIR)
		path = ICON_DIR .. "/" .. source:gsub("[^%w]", "_"):sub(-70) .. ".png"
		if not isfile(path) then
			local body = httpGet(source)
			if not (body and #body > 8 and body:sub(2, 4) == "PNG") then return nil end
			local ok = pcall(writefile, path, body)
			if not ok then return nil end
		end
	elseif isfile(source) then
		path = source
	end
	if not path then return nil end
	local ok, asset = pcall(getAsset, path)
	if ok and asset and asset ~= "" then return asset end
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
			if not moved and d.Magnitude > 6 then
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

local NotifHolder = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(260, 400), Parent = Gui })
new("UIListLayout", {
	Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = NotifHolder,
})

function Library:Notify(o)
	o = o or {}
	local dur = o.Duration or 4
	local slot = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Parent = NotifHolder })
	local toast = new("Frame", { Position = UDim2.new(1, 60, 0, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Card", Parent = slot })
	corner(toast, 10)
	stroke(toast)
	padding(toast, 12, 9, 12, 10)
	listLayout(toast, 4)

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = toast })
	makeIcon(head, o.Icon or "info", 16, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
	new("TextLabel", {
		Text = o.Title or "Notification", Font = FONT_BOLD, Fg = "Text", Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -24, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	if o.Content and o.Content ~= "" then
		new("TextLabel", {
			Text = o.Content, Fg = "SubText", TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
			TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Parent = toast,
		})
	end
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 2), Bg = "Stroke", LayoutOrder = 3, Parent = toast })
	corner(bar, 1)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), Bg = "Accent", Parent = bar })
	corner(fill, 1)

	tween(toast, { Position = UDim2.fromScale(0, 0) }, 0.45, Enum.EasingStyle.Back)
	tween(fill, { Size = UDim2.fromScale(0, 1) }, dur, Enum.EasingStyle.Linear)
	task.delay(dur, function()
		if not slot.Parent then return end
		tween(toast, { Position = UDim2.new(1, 60, 0, 0) }, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.wait(0.3)
		if not slot.Parent then return end
		local h = slot.AbsoluteSize.Y
		slot.AutomaticSize = AutoNone
		slot.Size = UDim2.new(1, 0, 0, h)
		tween(slot, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
		task.wait(0.2)
		slot:Destroy()
		prune()
	end)
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
			if typeof(v) == "EnumItem" then v = { __key = v.Name } end
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
				if type(v) == "table" and v.__key then v = Enum.KeyCode[v.__key] end
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
end

local function quiet(obj)
	if obj.Flag then Library.Flags[obj.Flag] = obj.Value end
end

local function makeRow(sec, height, bgKey)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, height or 36), Bg = bgKey or "Element", LayoutOrder = sec:_next(), Parent = sec.Content })
	corner(row, 8)
	return row
end

local function rowLabel(row, text, width)
	return new("TextLabel", {
		Text = text or "", Fg = "Text", Position = UDim2.fromOffset(12, 0), Size = width or UDim2.new(1, -24, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
end

local function onHover(gui, enter, leave)
	if IS_TOUCH then return end
	connect(gui.MouseEnter, enter)
	connect(gui.MouseLeave, leave)
end

local function hoverRow(row, hit, key)
	onHover(hit,
		function() tween(row, { BackgroundColor3 = Theme.Hover }, 0.15) end,
		function() tween(row, { BackgroundColor3 = Theme[key or "Element"] }, 0.2) end)
end

local function sideControl(box)
	new("UISizeConstraint", { MinSize = Vector2.new(96, 24), MaxSize = Vector2.new(160, 24), Parent = box })
end
local SIDE_LABEL = UDim2.new(0.5, -12, 1, 0)
local SIDE_BOX = UDim2.new(0.5, -10, 0, 24)

function Section:AddToggle(o)
	local row = makeRow(self, 36)
	rowLabel(row, o.Name, UDim2.new(1, -78, 1, 0))

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(40, 20),
		BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0, Parent = row,
	})
	round(pill)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.SubText, BackgroundTransparency = 0, Parent = pill,
	})
	round(knob)

	local hit = hitZone(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(52, 30), Radius = 8,
	})

	local obj = { Type = "Toggle", Value = o.Default and true or false }
	local function render(instant)
		local on = obj.Value
		local t = instant and 0 or 0.16
		tween(pill, { BackgroundColor3 = on and Theme.Accent or Theme.Stroke }, t, Enum.EasingStyle.Quad)
		tween(knob, {
			Position = UDim2.new(0, on and 23 or 3, 0.5, 0),
			BackgroundColor3 = on and Theme.AccentText or Theme.SubText,
		}, t, Enum.EasingStyle.Quad)
	end
	render(true)
	Hooks[#Hooks + 1] = function() render(false) end
	function obj:Set(v, silent)
		self.Value = v and true or false
		render(false)
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end
	connect(hit.Activated, function() obj:Set(not obj.Value) end)
	register(obj, o)
	return obj
end

function Section:AddSlider(o)
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local decimals = 0
	local frac = tostring(inc):match("%.(%d+)")
	if frac then decimals = #frac end

	local row = makeRow(self, 48)
	rowLabel(row, o.Name, UDim2.new(1, -86, 0, 26)).Position = UDim2.fromOffset(12, 4)
	local valueLbl = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.fromOffset(66, 26),
		TextXAlignment = Enum.TextXAlignment.Right, Fg = "SubText", TextSize = 12, Parent = row,
	})
	local track = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 1, -13), Size = UDim2.new(1, -24, 0, 6), Bg = "Stroke", Parent = row })
	round(track)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), Bg = "Accent", Parent = track })
	round(fill)
	local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromOffset(14, 14), Bg = "Text", Parent = fill })
	round(knob)
	local hit = hitZone(row, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 1, -13), Size = UDim2.new(1, -12, 0, 26), Radius = 6 })

	local obj = { Type = "Slider", Value = min }
	local function render()
		local pct = (obj.Value - min) / math.max(max - min, 1e-9)
		tween(fill, { Size = UDim2.fromScale(pct, 1) }, 0.08, Enum.EasingStyle.Quad)
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
		tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.2, Enum.EasingStyle.Back)
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
		tween(knob, { Size = UDim2.fromOffset(18, 18) }, 0.15, Enum.EasingStyle.Back)
		fromX(i.Position.X)
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

	obj:Set(o.Default or min, true)
	register(obj, o)
	return obj
end

function Section:AddDropdown(o)
	local row = makeRow(self, 36)
	rowLabel(row, o.Name, SIDE_LABEL)
	local box = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = SIDE_BOX, Bg = "Hover", Parent = row })
	corner(box, 6)
	sideControl(box)
	local bstroke = stroke(box)
	local txt = new("TextLabel", { Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -28, 1, 0), Fg = "Text", TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = box })
	local arrow = makeIcon(box, "chevron", 12, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0) })
	local hit = hitZone(box, { Size = UDim2.fromScale(1, 1), Radius = 6 })
	hoverRow(row, hit)

	local allowNone = o.AllowNone ~= false
	local NONE_ITEM = {}
	local obj = { Type = "Dropdown", Options = o.Options or {}, Value = nil }
	local function render()
		if obj.Value ~= nil then
			txt.Text = tostring(obj.Value)
		elseif #obj.Options == 0 then
			txt.Text = o.Placeholder or "None"
		else
			txt.Text = "None"
		end
		tween(txt, { TextTransparency = obj.Value ~= nil and 0 or 0.45 }, 0.15)
	end
	function obj:Set(v, silent)
		if v == nil then
			if not allowNone then return end
		elseif not table.find(self.Options, v) then
			return
		end
		self.Value = v
		render()
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
			padding(item, 8, 0, 8, 0)
			onHover(item,
				function() tween(item, { BackgroundTransparency = 0 }, 0.12) end,
				function() tween(item, { BackgroundTransparency = 1 }, 0.15) end)
			connect(item.MouseButton1Click, function()
				if isNone then obj:Set(nil) else obj:Set(opt) end
				closePopup()
			end)
		end
		tween(popup, { Size = UDim2.fromOffset(w, h) }, 0.22)
		tween(arrow, { Rotation = 180 }, 0.22)
		tween(bstroke, { Color = Theme.Accent }, 0.2)

		local scrollCon
		if self.Scroll then
			scrollCon = self.Scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(closePopup)
		end
		local function close()
			isOpen = false
			if scrollCon then scrollCon:Disconnect() end
			tween(arrow, { Rotation = 0 }, 0.2)
			tween(bstroke, { Color = Theme.Stroke }, 0.2)
			tween(popup, { Size = UDim2.fromOffset(w, 0) }, 0.15)
			blocker:Destroy()
			task.delay(0.18, function() popup:Destroy() end)
		end
		Library.OpenPopup = close
		connect(blocker.MouseButton1Click, closePopup)
	end
	connect(hit.MouseButton1Click, function()
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
	local row = makeRow(self, primary and 34 or 36, primary and "Text" or "Element")
	local hit, target, lbl

	if primary then
		hit = hitZone(row, { Size = UDim2.fromScale(1, 1), Radius = 8 })
		target = row
		lbl = new("TextLabel", {
			Text = o.Name or "Button", Fg = "Background", Font = FONT_BOLD, Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
		})
		if o.Icon then
			makeIcon(row, o.Icon, 14, "Background", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) })
		end
	else
		local hasIcon = o.Icon ~= nil
		local hasText = o.ButtonText ~= nil or not hasIcon
		local pw = (hasIcon and hasText) and 76 or (hasIcon and 34 or 52)
		lbl = rowLabel(row, o.Name, UDim2.new(1, -(pw + 24), 1, 0))
		hit, target = hitZone(row, {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(pw, 24), Radius = 6,
		})
		bind(target, "BackgroundColor3", "Hover")
		target.BackgroundTransparency = 0
		stroke(target)
		if hasIcon then
			if hasText then
				makeIcon(target, o.Icon, 13, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
			else
				makeIcon(target, o.Icon, 14, "Accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
			end
		end
		if hasText then
			new("TextLabel", {
				Text = o.ButtonText or "Run", Fg = "Text", TextSize = 12, Font = FONT_BOLD, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(hasIcon and 14 or 0, 0), Size = UDim2.new(1, hasIcon and -14 or 0, 1, 0),
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = target,
			})
		end
	end

	local sc = new("UIScale", { Parent = target })
	local function base() return primary and Theme.Text or Theme.Hover end
	local function over() return primary and Theme.Text:Lerp(Theme.Background, 0.15) or Theme.Stroke end
	onHover(hit,
		function() tween(target, { BackgroundColor3 = over() }, 0.15) end,
		function()
			tween(target, { BackgroundColor3 = base() }, 0.2)
			tween(sc, { Scale = 1 }, 0.2, Enum.EasingStyle.Quad)
		end)
	connect(hit.MouseButton1Down, function() tween(sc, { Scale = 0.96 }, 0.08) end)
	connect(hit.MouseButton1Up, function() tween(sc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back) end)
	connect(hit.MouseButton1Click, function()
		if o.Callback then task.spawn(o.Callback) end
	end)
	local obj = { Type = "Button" }
	function obj:SetText(t) lbl.Text = t end
	return obj
end

function Section:AddTextbox(o)
	local row = makeRow(self, 36)
	rowLabel(row, o.Name, SIDE_LABEL)
	local tb = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = SIDE_BOX,
		Bg = "Hover", Fg = "Text", Ph = "SubText", PlaceholderText = o.Placeholder or "", Text = o.Default or "",
		TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, Parent = row,
	})
	corner(tb, 6)
	sideControl(tb)
	padding(tb, 8, 0, 8, 0)
	local st = stroke(tb)
	local obj = { Type = "Textbox", Value = o.Default or "", Input = tb }
	connect(tb.Focused, function() tween(st, { Color = Theme.Accent }, 0.2) end)
	connect(tb.FocusLost, function()
		tween(st, { Color = Theme.Stroke }, 0.2)
		obj.Value = tb.Text
		fire(obj, o)
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
	rowLabel(row, o.Name, UDim2.new(1, -118, 1, 0))
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 24),
		AutomaticSize = AutoX, Bg = "Hover", Fg = "Text", TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
	corner(btn, 6)
	padding(btn, 10, 0, 10, 0)
	new("UISizeConstraint", { MinSize = Vector2.new(34, 24), MaxSize = Vector2.new(108, 24), Parent = btn })
	local st = stroke(btn)

	local obj = { Type = "Keybind", Value = nil }
	local listening = false
	local function render()
		btn.Text = listening and "..." or (obj.Value and obj.Value.Name or "None")
		tween(st, { Color = listening and Theme.Accent or Theme.Stroke }, 0.15)
	end
	local function setListening(v)
		listening = v
		Library.Listening = v
		render()
	end
	function obj:Set(v, silent)
		if type(v) == "string" then
			local ok, kc = pcall(function() return Enum.KeyCode[v] end)
			v = ok and kc or nil
		end
		self.Value = v
		setListening(false)
		if self.Flag then Library.Flags[self.Flag] = self.Value end
		if not silent and o.Changed then task.spawn(o.Changed, self.Value) end
	end
	function obj:Get() return self.Value end
	connect(btn.MouseButton1Click, function() setListening(true) end)
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
		if t ~= nil then title.Text = t end
		if s ~= nil then sub.Text = s sub.Visible = s ~= "" end
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
	corner(card, 10)
	stroke(card)
	listLayout(card, 0)

	local header = new("Frame", { Size = UDim2.new(1, 0, 0, SEC_H), LayoutOrder = 1, Parent = card })
	local hasIcon = o.Icon ~= nil
	local lx = hasIcon and 36 or 12
	if hasIcon then
		makeIcon(header, o.Icon, 16, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0) })
	end
	new("TextLabel", {
		Text = o.Name or "Section", Font = FONT_BOLD, Fg = "Text", Position = UDim2.fromOffset(lx, 0),
		Size = UDim2.new(1, -(lx + 34), 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})
	local chev = makeIcon(header, "chevron", 14, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Rotation = o.Collapsed and 0 or 180 })
	local hz = hitZone(header, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(38, 28), Radius = 6 })

	local content = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, ClipsDescendants = true, LayoutOrder = 2, Parent = card })
	padding(content, 8, 0, 8, 8)
	local layout = listLayout(content, 5)

	local sec = setmetatable({
		Tab = self, Content = content, Scroll = self.Scroll, Order = 0,
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
			local t = tween(content, { Size = UDim2.new(1, 0, 0, target) }, 0.22)
			t.Completed:Connect(function()
				if sec._tok == tok and not sec.Collapsed then
					content.AutomaticSize = AutoY
				end
			end)
		end
	end
	connect(hz.MouseButton1Click, function()
		sec.Collapsed = not sec.Collapsed
		tween(chev, { Rotation = sec.Collapsed and 0 or 180 }, 0.25)
		closePopup()
		apply()
	end)
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

local function relayoutSub(tab)
	if not tab.SubFrame then return end
	local n = 0
	for _, c in ipairs(tab.Children) do
		if c.Button.Visible then n += 1 end
	end
	local open = tab.Expanded or tab.Window.Searching
	local h = (n > 0 and open) and (n * 28 + (n - 1) * 3 + 6) or 0
	tween(tab.SubFrame, { Size = UDim2.new(1, 0, 0, h) }, 0.25)
end

function Library._toggleSub(tab)
	if #tab.Children == 0 then return end
	tab.Expanded = not tab.Expanded
	if tab.Chevron then tween(tab.Chevron, { Rotation = tab.Expanded and 180 or 0 }, 0.25) end
	relayoutSub(tab)
end

local function paintTab(tab, instant)
	local t = instant and 0 or 0.2
	local on = tab.Active
	tween(tab.Button, { BackgroundTransparency = on and 0 or 1 }, t)
	tween(tab.Bar, { Size = UDim2.fromOffset(3, on and 16 or 0) }, t, Enum.EasingStyle.Back)
	tween(tab.Label, { TextColor3 = on and Theme.Text or Theme.SubText }, t)
	if tab.Icon then tintIcon(tab.Icon, on and Theme.Accent or Theme.SubText, t) end
end

function Window:_sub(parentTab)
	if parentTab.SubFrame then return parentTab.SubFrame end
	local sf = new(USE_CANVAS_HIT and "CanvasGroup" or "Frame", { Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, LayoutOrder = 2, Parent = parentTab.Holder })
	listLayout(sf, 3)
	padding(sf, 14, 3, 0, 0)
	parentTab.SubFrame = sf
	parentTab.Chevron = makeIcon(parentTab.Button, "chevron", 12, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) })
	local zh = hitZone(parentTab.Button, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(28, 26), Radius = 6 })
	connect(zh.MouseButton1Click, function() Library._toggleSub(parentTab) end)
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

	local tab = setmetatable({ Window = self, Name = opts.Name or "Tab", Children = {}, ParentTab = parentTab, Active = false, Order = 0, Expanded = false }, Tab)
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

	local h = isSub and 28 or 32
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, h), Bg = "Element", BackgroundTransparency = 1, LayoutOrder = layoutOrder, Parent = container })
	corner(btn, 8)
	local bar = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(3, 0), Bg = "Accent", Parent = btn })
	corner(bar, 2)
	local hasIcon = opts.Icon ~= nil
	if hasIcon then
		tab.Icon = makeIcon(btn, opts.Icon, 16, nil, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0) })
	end
	local hasChevSpace = 26
	tab.Label = new("TextLabel", {
		Text = tab.Name, TextColor3 = Theme.SubText, TextSize = isSub and 12 or 13,
		Position = UDim2.fromOffset(hasIcon and 36 or 12, 0), Size = UDim2.new(1, -((hasIcon and 36 or 12) + hasChevSpace), 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
	})
	tab.Button, tab.Bar = btn, bar
	Hooks[#Hooks + 1] = function() paintTab(tab, false) end

	onHover(btn,
		function() if not tab.Active then tween(btn, { BackgroundTransparency = 0.55 }, 0.15) end end,
		function() if not tab.Active then tween(btn, { BackgroundTransparency = 1 }, 0.2) end end)

	if opts.NoPage ~= true then
		local holder = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), Visible = false, GroupTransparency = 1, Parent = self.Content })
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

	connect(btn.MouseButton1Click, function()
		if tab.Page then
			self:SelectTab(tab)
		else
			Library._toggleSub(tab)
		end
	end)

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
	if self.Current == tab or not tab.Page then return end
	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	local old = self.Current
	self.Current = tab
	if old then
		old.Active = false
		paintTab(old, false)
		local pg = old.Page
		tween(pg, { GroupTransparency = 1 }, 0.14)
		task.delay(0.15, function()
			if not old.Active then pg.Visible = false end
		end)
	end
	tab.Active = true
	paintTab(tab, instant)
	local pg = tab.Page
	pg.Visible = true
	if instant then
		pg.GroupTransparency = 0
		pg.Position = UDim2.new()
	else
		pg.GroupTransparency = 1
		pg.Position = UDim2.fromOffset(0, 14)
		tween(pg, { GroupTransparency = 0, Position = UDim2.new() }, 0.3)
	end
end

function Window:_filter(q)
	q = q:lower()
	self.Searching = q ~= ""
	for _, gl in ipairs(self.GroupLabels) do gl.Visible = not self.Searching end
	for _, t in ipairs(self.Tabs) do
		if not t.ParentTab then
			local selfMatch = (q == "") or (t.Name:lower():find(q, 1, true) ~= nil)
			local any = false
			for _, c in ipairs(t.Children) do
				local m = (q == "") or selfMatch or (c.Name:lower():find(q, 1, true) ~= nil)
				c.Button.Visible = m
				if m then any = true end
			end
			t.Holder.Visible = selfMatch or any
			relayoutSub(t)
		end
	end
end

function Window:SetMinimized(state)
	state = state and true or false
	if state == self.Minimized then return end
	if self._minLock then return end
	self._minLock = true
	task.delay(0.38, function() self._minLock = false end)

	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	self.Minimized = state
	self._minTok = (self._minTok or 0) + 1
	local tok = self._minTok

	local delta = (BASE_H - (HEADER_H + 1)) * getScale() / 2
	local p = self.Main.Position
	local ny = state and (p.Y.Offset - delta) or (p.Y.Offset + delta)
	if not state then self.Body.Visible = true end
	tween(self.Main, {
		Size = UDim2.fromOffset(BASE_W, state and (HEADER_H + 1) or BASE_H),
		Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, ny),
	}, 0.35, Enum.EasingStyle.Quint)
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
	if self.Minimized then
		self.Minimized = false
		self._minTok = (self._minTok or 0) + 1
		self.Body.Visible = true
		tween(self.Main, { Size = UDim2.fromOffset(BASE_W, BASE_H) }, 0.35)
	end
	tween(ScaleObj, { Scale = state and maxScale() or fitScale() }, 0.4)
	tween(self.Main, { Position = UDim2.fromScale(0.5, 0.5) }, 0.4)
end

function Window:Toggle(state)
	if state == nil then state = not self.Visible end
	if state == self.Visible then return end
	self.Visible = state
	closePopup()
	if SliderLock.Active then pcall(SliderLock.Active) end
	local target = self.Maximized and maxScale() or fitScale()
	if state then
		self.Main.Visible = true
		ScaleObj.Scale = target * 0.86
		tween(ScaleObj, { Scale = target }, 0.4, Enum.EasingStyle.Back)
	else
		tween(ScaleObj, { Scale = target * 0.86 }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.2, function()
			if not self.Visible then self.Main.Visible = false end
		end)
	end
end

function Window:SetUserVisible(v)
	self.UserCard.Visible = v
	tween(self.TabList, { Size = UDim2.new(1, 0, 1, -(46 + (v and 60 or 8))) }, 0.25)
end

function Window:_statsRefresh()
	local parts = {}
	if self.ShowFPS then parts[#parts + 1] = string.format("%d FPS", math.floor(self.Fps + 0.5)) end
	if self.ShowPing then parts[#parts + 1] = string.format("%d ms", math.floor(self.Ping + 0.5)) end
	local show = #parts > 0
	self.StatsLabel.Visible = show
	self.StatsLabel.Text = table.concat(parts, "  |  ")
	self.TitleBlock.Size = UDim2.new(1, -(44 + CTRL_W + 20 + (show and 124 or 0)), 1, 0)
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
	ap:AddDropdown({ Name = "Theme", Options = Library.ThemeList, Default = Library.ThemeName, AllowNone = false, Flag = "UI_Theme", Callback = function(v) Library:SetTheme(v) end })
	ap:AddSlider({ Name = "Transparency", Min = 0, Max = 0.8, Increment = 0.01, Default = Library.Transparency, Flag = "UI_Transparency", Callback = function(v) Library:SetTransparency(v) end })
	ap:AddToggle({ Name = "Show User", Default = true, Flag = "UI_ShowUser", Callback = function(v) self:SetUserVisible(v) end })
	ap:AddToggle({ Name = "Show FPS", Default = false, Flag = "UI_ShowFPS", Callback = function(v) self.ShowFPS = v self:_statsRefresh() end })
	ap:AddToggle({ Name = "Show Ping", Default = false, Flag = "UI_ShowPing", Callback = function(v) self.ShowPing = v self:_statsRefresh() end })

	local kb = tab:AddSection({ Name = "Keybinds", Icon = "keyboard", Side = "Left" })
	kb:AddKeybind({ Name = "Toggle UI", Default = self.ToggleKey, Flag = "UI_ToggleKey", Changed = function(k) if k then self.ToggleKey = k end end })
	kb:AddButton({ Name = "Unload UI", Icon = "close", Callback = function() self:RequestClose() end })

	local cf = tab:AddSection({ Name = "Config", Icon = "save", Side = "Right" })
	local nameBox = cf:AddTextbox({ Name = "Config Name", Placeholder = "MyConfig" })
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
	sel = cf:AddDropdown({ Name = "Select Config", Options = Library:ListConfigs(), Placeholder = "No configs..." })
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
	cf:AddToggle({ Name = "Enable Auto Load", Default = autoOn, Callback = function(v)
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
	corner(card, 12)
	stroke(card)
	padding(card, 18, 16, 18, 16)
	listLayout(card, 10)
	local scale = new("UIScale", { Scale = s * 0.92, Parent = card })

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = card })
	makeIcon(head, o.Icon or "info", 18, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
	new("TextLabel", {
		Text = o.Title or "Konfirmasi", Font = FONT_BOLD, TextSize = 15, Fg = "Text",
		Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -26, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = head,
	})
	new("TextLabel", {
		Text = o.Content or "", TextSize = 12, Fg = "SubText", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY,
		TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2, Parent = card,
	})

	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 3, Parent = card })
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
	})
	local cancel = new("TextButton", {
		Size = UDim2.new(0.5, -4, 1, 0), Bg = "Element", Text = o.CancelText or "Cancel", Font = FONT_BOLD, Fg = "Text",
		TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = row,
	})
	corner(cancel, 8)
	stroke(cancel)
	local RED = Color3.fromRGB(220, 50, 60)
	local ok = new("TextButton", {
		Size = UDim2.new(0.5, -4, 1, 0), BackgroundColor3 = RED, Text = o.ConfirmText or "Yes", Font = FONT_BOLD,
		TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = row,
	})
	corner(ok, 8)
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
		tween(blocker, { BackgroundTransparency = 1 }, 0.15)
		tween(card, { GroupTransparency = 1 }, 0.15)
		tween(scale, { Scale = s * 0.92 }, 0.15)
		task.delay(0.18, function()
			pcall(function() blocker:Destroy() end)
			pcall(function() card:Destroy() end)
			prune()
		end)
		if cb then task.spawn(cb) end
	end
	escCon = UserInputService.InputBegan:Connect(function(i)
		if i.KeyCode == Enum.KeyCode.Escape then close(o.OnCancel) end
	end)
	connect(blocker.Activated, function() close(o.OnCancel) end)
	connect(cancel.Activated, function() close(o.OnCancel) end)
	connect(ok.Activated, function() close(o.Callback) end)

	tween(blocker, { BackgroundTransparency = 0.45 }, 0.2)
	tween(card, { GroupTransparency = 0 }, 0.2)
	tween(scale, { Scale = s }, 0.28, Enum.EasingStyle.Back)
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

	local Canvas = new("CanvasGroup", {
		Name = "Canvas", Size = UDim2.fromScale(1, 1), Bg = "Background", BackgroundTransparency = Library.Transparency, Parent = Main,
	})
	corner(Canvas, 12)
	TransFrames[#TransFrames + 1] = Canvas
	self.Canvas = Canvas

	local Outline = new("Frame", { Name = "Outline", Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = Main })
	corner(Outline, 12)
	stroke(Outline)

	local BODY_H = BASE_H - HEADER_H - 1
	local Body = new("Frame", { Name = "Body", Position = UDim2.fromOffset(0, HEADER_H + 1), Size = UDim2.fromOffset(BASE_W, BODY_H), Parent = Canvas })
	self.Body = Body

	local Header = new("Frame", { Size = UDim2.new(1, 0, 0, HEADER_H), Bg = "Sidebar", BackgroundTransparency = Library.Transparency, Parent = Canvas })
	TransFrames[#TransFrames + 1] = Header
	local headerCrown = makeIcon(Header, "crown", 20, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) })

	local TitleBlock = new("Frame", {
		Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -(44 + CTRL_W + 20), 1, 0), ClipsDescendants = true, Parent = Header,
	})
	self.TitleBlock = TitleBlock
	local titleRow = new("Frame", { Position = UDim2.fromOffset(0, 5), Size = UDim2.fromOffset(0, 17), AutomaticSize = AutoX, Parent = TitleBlock })
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
		TweenService:Create(pst, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 3, Transparency = 1 }):Play()
	end
	new("TextLabel", {
		Text = opts.Subtitle or "", TextSize = 11, Fg = "SubText", Position = UDim2.fromOffset(0, 23),
		Size = UDim2.new(1, 0, 0, 13), TextTruncate = Enum.TextTruncate.AtEnd, Parent = TitleBlock,
	})

	local ctrls = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(CTRL_W, CTRL_BTN), Parent = Header,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, CTRL_GAP), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = ctrls,
	})

	self.StatsLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(CTRL_W + 20), 0.5, 0), Size = UDim2.fromOffset(118, 14),
		TextXAlignment = Enum.TextXAlignment.Right, TextSize = 11, Fg = "SubText", Visible = false, Parent = Header,
	})

	local function ctrl(order, iconName, hoverColor, fn)
		local b = new("Frame", { Size = UDim2.fromOffset(CTRL_BTN, CTRL_BTN), Bg = "Hover", BackgroundTransparency = 1, LayoutOrder = order, Parent = ctrls })
		corner(b, 7)
		local ic
		if iconName then
			ic = makeIcon(b, iconName, 14, "SubText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
		else
			ic = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 2), Bg = "SubText", Parent = b })
			round(ic)
		end
		local function tint(color, t)
			if ic:IsA("ImageLabel") then tintIcon(ic, color, t) else tween(ic, { BackgroundColor3 = color }, t) end
		end
		local hit = hitZone(b, { Size = UDim2.fromScale(1, 1), Radius = 7 })
		onHover(hit,
			function()
				tween(b, { BackgroundTransparency = 0, BackgroundColor3 = hoverColor or Theme.Hover }, 0.15)
				if hoverColor then tint(Color3.new(1, 1, 1), 0.15) end
			end,
			function()
				tween(b, { BackgroundTransparency = 1, BackgroundColor3 = Theme.Hover }, 0.2)
				tint(Theme.SubText, 0.2)
			end)
		connect(hit.MouseButton1Click, fn)
		return b
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
	TweenService:Create(grad, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(1, 0) }):Play()

	local Sidebar = new("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, SIDEBAR_W, 1, 0), Bg = "Sidebar", BackgroundTransparency = Library.Transparency, ClipsDescendants = true, Parent = Body })
	TransFrames[#TransFrames + 1] = Sidebar
	new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), Bg = "Stroke", Parent = Sidebar })

	local search = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 30), Bg = "Element", Parent = Sidebar })
	corner(search, 8)
	local sst = stroke(search)
	makeIcon(search, "search", 14, "SubText", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
	local sbox = new("TextBox", { Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -(30 + (UserInputService.TouchEnabled and 8 or 46)), 1, 0), PlaceholderText = "Search...", Text = "", Fg = "Text", Ph = "SubText", TextSize = 12, ClipsDescendants = true, Parent = search })
	if not UserInputService.TouchEnabled then
		local badge = new("TextLabel", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(0, 16), AutomaticSize = AutoX, Bg = "Hover", Text = "Ctrl K", TextSize = 9, Fg = "SubText", TextXAlignment = Enum.TextXAlignment.Center, Parent = search })
		corner(badge, 4)
		padding(badge, 5, 0, 5, 0)
	end
	connect(sbox.Focused, function() tween(sst, { Color = Theme.Accent }, 0.2) end)
	connect(sbox.FocusLost, function() tween(sst, { Color = Theme.Stroke }, 0.2) end)
	connect(sbox:GetPropertyChangedSignal("Text"), function() self:_filter(sbox.Text) end)

	self.TabList = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -(46 + 60)), CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AutoY, ScrollBarThickness = 2, Sb = "Stroke", Parent = Sidebar,
	})
	padding(self.TabList, 8, 0, 8, 6)
	listLayout(self.TabList, 3)

	self.UserCard = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 44), Bg = "Element", Parent = Sidebar })
	corner(self.UserCard, 10)
	stroke(self.UserCard)
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

	if opts.ToggleButton ~= false then
		local fb = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -46, 0, 58), Size = UDim2.fromOffset(44, 44), Bg = "Sidebar", Parent = Gui })
		corner(fb, 22)
		local fst = stroke(fb, "Accent", 1.5)
		local toggleCrown = makeIcon(fb, "crown", 20, "Accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
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
		TweenService:Create(fst, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 3.5, Transparency = 0.7 }):Play()
		local fsc = new("UIScale", { Parent = fb })
		local fhit = hitZone(fb, { Size = UDim2.fromScale(1, 1), Radius = 22 })
		connect(fhit.MouseButton1Down, function() tween(fsc, { Scale = 0.9 }, 0.08) end)
		connect(fhit.MouseButton1Up, function() tween(fsc, { Scale = 1 }, 0.25, Enum.EasingStyle.Back) end)
		draggable(fhit, fb, function() self:Toggle() end)
	end

	connect(UserInputService.InputBegan, function(i, gp)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if Library.Listening then return end
		if i.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
			if not self.Visible then self:Toggle(true) end
			if self.Minimized then self.Minimized = false self._minTok = (self._minTok or 0) + 1 self.Body.Visible = true
				tween(self.Main, { Size = UDim2.fromOffset(BASE_W, BASE_H) }, 0.35) end
			task.defer(function()
				sbox:CaptureFocus()
				task.wait()
				sbox.Text = ""
			end)
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

	tween(ScaleObj, { Scale = fitScale() }, 0.5, Enum.EasingStyle.Back)

	table.insert(Library.Windows, self)
	return self
end

env.__ZystrixUI = Library

if env.ZystrixUI_NoDemo or env.MystrixUI_NoDemo then return Library end

local Window = Library:CreateWindow({
	Title = "ZystrixUI Tester",
	Subtitle = "Component playground",
	Version = "v1.4",
	ConfigFolder = "ZystrixTester",
	ToggleKey = Enum.KeyCode.J,
})

local function stamp() return os.date("%H:%M:%S") end

local Overview = Window:AddTab({
	Name = "Overview", Icon = "home", Group = "TESTER",
	Description = "Playground for testing every ZystrixUI component.",
})
local about = Overview:AddSection({ Name = "About", Icon = "info", Side = "Left" })
about:AddLabel({ Title = "ZystrixUI Tester", Text = "Pick a tab in the sidebar to test switches, sliders, inputs, dropdowns, keybinds, buttons and layout." })
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
	Name = "Switch", Icon = "settings", Group = "TESTER",
	Description = "Switch test: only the switch area is clickable, smooth animation, no flicker.",
})
local sb = Switches:AddSection({ Name = "Basic Switch", Icon = "settings", Side = "Left" })
sb:AddToggle({ Name = "Switch Off (default)", Default = false, Flag = "T_Off" })
sb:AddToggle({ Name = "Switch On (default)", Default = true, Flag = "T_On" })
sb:AddToggle({ Name = "Switch + Notification", Flag = "T_Notify", Callback = function(v)
	Library:Notify({ Title = "Switch", Content = v and "Enabled" or "Disabled", Duration = 2 })
end })
sb:AddDivider("Spam Test")
local spamLabel = sb:AddLabel({ Title = "Changes: 0", Text = "Click the switch below rapidly. It must not flicker or get stuck." })
local spamCount = 0
sb:AddToggle({ Name = "Spam Click", Flag = "T_Spam", Callback = function()
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
sm:AddToggle({ Name = "Master Switch", Flag = "T_Master", Callback = function(v)
	for _, f in ipairs(childFlags) do
		local o = Library.Options[f]
		if o then o:Set(v, true) end
	end
	recount()
end })
for i, f in ipairs(childFlags) do
	sm:AddToggle({ Name = "Child " .. i, Flag = f, Callback = recount })
end

local Sliders = Window:AddTab({
	Name = "Slider", Icon = "main", Group = "TESTER",
	Description = "Slider test: drag, click on the track, decimal values, negative range, suffix.",
})
local si = Sliders:AddSection({ Name = "Integer", Icon = "main", Side = "Left" })
local lastInt = si:AddLabel({ Title = "Last value", Text = "-" })
si:AddSlider({ Name = "Walk Speed", Min = 16, Max = 200, Default = 16, Increment = 1, Flag = "S_Walk", Callback = function(v)
	lastInt:Set(nil, "Walk Speed = " .. v)
end })
si:AddSlider({ Name = "Jump Power", Min = 0, Max = 300, Default = 50, Increment = 5, Flag = "S_Jump", Suffix = " st", Callback = function(v)
	lastInt:Set(nil, "Jump Power = " .. v)
end })
si:AddSlider({ Name = "Percent", Min = 0, Max = 100, Default = 50, Increment = 1, Flag = "S_Percent", Suffix = "%" })

local sd = Sliders:AddSection({ Name = "Decimal & Range", Icon = "main", Side = "Right" })
local lastDec = sd:AddLabel({ Title = "Last value", Text = "-" })
sd:AddSlider({ Name = "Gravity Scale", Min = 0, Max = 2, Default = 1, Increment = 0.05, Flag = "S_Gravity", Suffix = "x", Callback = function(v)
	lastDec:Set(nil, "Gravity Scale = " .. v)
end })
sd:AddSlider({ Name = "Brightness", Min = 0, Max = 1, Default = 0.5, Increment = 0.01, Flag = "S_Bright", Callback = function(v)
	lastDec:Set(nil, "Brightness = " .. v)
end })
sd:AddSlider({ Name = "Negative", Min = -100, Max = 100, Default = 0, Increment = 5, Flag = "S_Neg" })
sd:AddSlider({ Name = "Large Range", Min = 0, Max = 10000, Default = 2500, Increment = 50, Flag = "S_Big" })
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
	Name = "Input", Icon = "keyboard", Group = "TESTER",
	Description = "Input box and keybind test.",
})
local it = Inputs:AddSection({ Name = "Input Box", Icon = "keyboard", Side = "Left" })
local echo = it:AddLabel({ Title = "Echo", Text = "Type something, then press Enter or click outside the box." })
local nameBox = it:AddTextbox({ Name = "Username", Placeholder = "Type a name...", Flag = "I_Name", Callback = function(v)
	echo:Set("Echo", v == "" and "(empty)" or ("Username = " .. v))
end })
it:AddTextbox({ Name = "Numbers Only", Placeholder = "0 - 100", Flag = "I_Number", Callback = function(v)
	local n = tonumber(v)
	if n then
		echo:Set("Echo", "Valid number: " .. math.clamp(n, 0, 100))
	else
		echo:Set("Echo", "\"" .. v .. "\" is not a number")
		Library:Notify({ Title = "Input", Content = "Enter a valid number.", Duration = 2 })
	end
end })
it:AddTextbox({ Name = "Long Text", Placeholder = "Truncation test...", Default = "A very long piece of text to test clipping inside the input box", Flag = "I_Long" })
it:AddButton({ Name = "Clear Username", Icon = "trash", Callback = function()
	nameBox:Set("")
end })

local ik = Inputs:AddSection({ Name = "Keybind", Icon = "keyboard", Side = "Right" })
ik:AddLabel({ Title = "How to use", Text = "Click the button, then press a keyboard key. Esc = cancel, Backspace = clear." })
ik:AddKeybind({ Name = "Action Key", Default = Enum.KeyCode.F, Flag = "K_Action", Callback = function(k)
	Library:Notify({ Title = "Keybind", Content = "Pressed: " .. k.Name, Duration = 2 })
end })
ik:AddKeybind({ Name = "No Default", Flag = "K_None", Callback = function(k)
	Library:Notify({ Title = "Keybind", Content = "Pressed: " .. k.Name, Duration = 2 })
end, Changed = function(k)
	Library:Notify({ Title = "Keybind", Content = "Changed to: " .. (k and k.Name or "None"), Duration = 2 })
end })

local Drops = Window:AddTab({
	Name = "Dropdown", Icon = "chevron", Group = "TESTER",
	Description = "Dropdown test: short list, long list (scroll) and dynamic list.",
})
local dr = Drops:AddSection({ Name = "Basic", Icon = "chevron", Side = "Left" })
local dropEcho = dr:AddLabel({ Title = "Last selection", Text = "-" })
dr:AddDropdown({ Name = "Mode", Options = { "Teleport", "Drive", "Safe" }, Default = "Teleport", Flag = "D_Mode", Callback = function(v)
	dropEcho:Set(nil, "Mode = " .. tostring(v))
end })
local longList = {}
for i = 1, 14 do longList[i] = "Item " .. i end
dr:AddDropdown({ Name = "Long List", Options = longList, Placeholder = "Select an item...", Flag = "D_Long", Callback = function(v)
	dropEcho:Set(nil, "Long List = " .. tostring(v))
end })

local dd = Drops:AddSection({ Name = "Dynamic", Icon = "refresh", Side = "Right" })
local dynItems = { "Alpha", "Beta" }
local dyn = dd:AddDropdown({ Name = "Dynamic List", Options = dynItems, Placeholder = "Empty", Flag = "D_Dyn" })
dd:AddButton({ Name = "Add Option", Icon = "save", Callback = function()
	dynItems[#dynItems + 1] = "Option " .. (#dynItems + 1)
	dyn:Refresh(dynItems)
end })
dd:AddButton({ Name = "Reset List", Icon = "refresh", Callback = function()
	dynItems = { "Alpha", "Beta" }
	dyn:Refresh(dynItems)
end })

local Buttons = Window:AddTab({
	Name = "Button", Icon = "crown", Group = "TESTER",
	Description = "Button and notification test.",
})
local bt = Buttons:AddSection({ Name = "Buttons", Icon = "crown", Side = "Left" })
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
counterBtn = bt:AddButton({ Name = "Clicked: 0", Icon = "refresh", Callback = function()
	clicks += 1
	counterBtn:SetText("Clicked: " .. clicks)
end })

local nt = Buttons:AddSection({ Name = "Notifications", Icon = "info", Side = "Right" })
nt:AddButton({ Name = "Short Notification", Icon = "info", Callback = function()
	Library:Notify({ Title = "Short", Content = "Hello!", Duration = 3 })
end })
nt:AddButton({ Name = "Long Notification", Icon = "info", Callback = function()
	Library:Notify({
		Title = "Long Notification",
		Content = "This is a fairly long piece of text used to check that the notification height adapts to its content and nothing gets cut off at the bottom.",
		Duration = 6,
	})
end })
nt:AddButton({ Name = "Spam 3 Notifications", Icon = "info", Callback = function()
	for i = 1, 3 do
		task.delay((i - 1) * 0.25, function()
			Library:Notify({ Title = "Notification " .. i, Content = "Sent at " .. stamp(), Duration = 3 })
		end)
	end
end })

local Layout = Window:AddTab({ Name = "Layout", Icon = "eye", Group = "TESTER", NoPage = true })

local colTab = Layout:AddSubTab({ Name = "Columns", Description = "Two columns side by side." })
local cl = colTab:AddSection({ Name = "Left Column", Icon = "info", Side = "Left" })
cl:AddLabel({ Title = "Left", Text = "This section is in the left column." })
cl:AddToggle({ Name = "Left Toggle", Flag = "L_Left" })
local cr = colTab:AddSection({ Name = "Right Column", Icon = "info", Side = "Right" })
cr:AddLabel({ Title = "Right", Text = "This section is in the right column." })
cr:AddToggle({ Name = "Right Toggle", Flag = "L_Right" })

local scrollTab = Layout:AddSubTab({ Name = "Scroll", Description = "Test a long page with many elements." })
local ls = scrollTab:AddSection({ Name = "Many Elements", Icon = "main" })
for i = 1, 14 do
	ls:AddToggle({ Name = "Toggle #" .. i, Flag = "L_Many" .. i })
end
ls:AddSlider({ Name = "Bottom Slider", Min = 0, Max = 100, Default = 40, Flag = "L_Bottom" })

local colpTab = Layout:AddSubTab({ Name = "Collapse", Description = "Collapsible sections." })
local c1 = colpTab:AddSection({ Name = "Open (click the arrow)", Icon = "chevron" })
c1:AddToggle({ Name = "Content A", Flag = "L_A" })
c1:AddToggle({ Name = "Content B", Flag = "L_B" })
local c2 = colpTab:AddSection({ Name = "Collapsed at start", Icon = "chevron", Collapsed = true })
c2:AddToggle({ Name = "Content C", Flag = "L_C" })
c2:AddSlider({ Name = "Content D", Min = 0, Max = 10, Default = 5, Flag = "L_D" })

Window:CreateSettingsTab({ Group = "ACCOUNT" })

Window:LoadAutoConfig()
Library:Notify({ Title = "ZystrixUI Tester", Content = "Ready. Press J or the round button to open/close.", Duration = 5, Icon = "crown" })

return Library
