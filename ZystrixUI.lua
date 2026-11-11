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
local HEADER_H, SIDEBAR_W, SEC_H = 46, 150, 40
local CTRL_BTN, CTRL_SLOT = 36, 42
local CTRL_W = CTRL_SLOT * 3
local TITLE_X = 54
local TOG_SIZE = 40
local FONT, FONT_BOLD = Enum.Font.GothamMedium, Enum.Font.GothamBold
local ROOT = "ZystrixUI"
local ICON_DIR = ROOT .. "/icons"

local HasFS = (writefile and readfile and isfile and isfolder and makefolder) and true or false
local getAsset = getcustomasset or getsynasset

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
	Version = "1.6.0", ThemeName = "Monochrome",
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

local Gen = (function()
	local G = {}

	local crcTable
	local function crc32(s)
		if not crcTable then
			crcTable = {}
			for i = 0, 255 do
				local c = i
				for _ = 1, 8 do
					if bit32.band(c, 1) == 1 then
						c = bit32.bxor(bit32.rshift(c, 1), 0xEDB88320)
					else
						c = bit32.rshift(c, 1)
					end
				end
				crcTable[i] = c
			end
		end
		local c = 0xFFFFFFFF
		for i = 1, #s do
			c = bit32.bxor(crcTable[bit32.band(bit32.bxor(c, string.byte(s, i)), 0xFF)], bit32.rshift(c, 8))
		end
		return bit32.bxor(c, 0xFFFFFFFF)
	end

	local function be32(n)
		return string.char(
			bit32.band(bit32.rshift(n, 24), 255), bit32.band(bit32.rshift(n, 16), 255),
			bit32.band(bit32.rshift(n, 8), 255), bit32.band(n, 255)
		)
	end

	local function chunk(kind, data)
		return be32(#data) .. kind .. data .. be32(crc32(kind .. data))
	end

	local function adler32(s)
		local a, b = 1, 0
		for i = 1, #s do
			a = (a + string.byte(s, i)) % 65521
			b = (b + a) % 65521
		end
		return b * 65536 + a
	end

	local function zlibStored(raw)
		local out = { "\120\1" }
		local n, pos = #raw, 1
		while pos <= n do
			local len = math.min(65535, n - pos + 1)
			local final = (pos + len > n) and 1 or 0
			local nlen = 65535 - len
			out[#out + 1] = string.char(final, len % 256, math.floor(len / 256), nlen % 256, math.floor(nlen / 256))
			out[#out + 1] = string.sub(raw, pos, pos + len - 1)
			pos = pos + len
		end
		out[#out + 1] = be32(adler32(raw))
		return table.concat(out)
	end

	local function encodePNG(w, h, pix, canYield)
		local rows = {}
		for y = 0, h - 1 do
			if canYield and G.yield and y % 8 == 7 then G.yield() end
			local row = { "\0" }
			for x = 0, w - 1 do
				local r, g, b, a = pix(x, y)
				row[#row + 1] = string.char(r, g, b, a)
			end
			rows[#rows + 1] = table.concat(row)
		end
		local raw = table.concat(rows)
		local ihdr = be32(w) .. be32(h) .. "\8\6\0\0\0"
		return "\137PNG\r\n\26\n" .. chunk("IHDR", ihdr) .. chunk("IDAT", zlibStored(raw)) .. chunk("IEND", "")
	end

	local function smooth(t)
		return t * t * (3 - 2 * t)
	end

	local function sdRoundBox(px, py, cx, cy, hx, hy, r)
		local qx = math.abs(px - cx) - (hx - r)
		local qy = math.abs(py - cy) - (hy - r)
		local ox, oy = math.max(qx, 0), math.max(qy, 0)
		return math.sqrt(ox * ox + oy * oy) + math.min(math.max(qx, qy), 0) - r
	end

	G.shadowSize = 96
	G.shadowMargin = 24
	G.shadowCenter = 47

	function G.shadowPNG()
		local N, M, R, BLUR, INNER = 96, 24, 12, 22, 12
		local c = N / 2
		local h = N / 2 - M
		return encodePNG(N, N, function(x, y)
			local d = sdRoundBox(x + 0.5, y + 0.5, c, c, h, h, R)
			local a
			if d >= 0 then
				local t = math.min(d / BLUR, 1)
				a = (1 - smooth(t)) ^ 1.6
			else
				local t = math.min(-d / INNER, 1)
				a = smooth(1 - t)
			end
			return 0, 0, 0, math.floor(a * 255 + 0.5)
		end)
	end

	local function primSd(p, gx, gy)
		local k = p[1]
		if k == "l" then
			local ax, ay, bx, by = p[2], p[3], p[4], p[5]
			local pax, pay, bax, bay = gx - ax, gy - ay, bx - ax, by - ay
			local den = bax * bax + bay * bay
			local t = 0
			if den > 0 then t = (pax * bax + pay * bay) / den end
			t = math.max(0, math.min(1, t))
			local dx, dy = pax - bax * t, pay - bay * t
			return math.sqrt(dx * dx + dy * dy) - p[6] / 2
		elseif k == "c" then
			local dx, dy = gx - p[2], gy - p[3]
			return math.sqrt(dx * dx + dy * dy) - p[4]
		elseif k == "o" then
			local dx, dy = gx - p[2], gy - p[3]
			return math.abs(math.sqrt(dx * dx + dy * dy) - p[4]) - p[5] / 2
		elseif k == "r" then
			return sdRoundBox(gx, gy, p[2], p[3], p[4], p[5], p[6])
		elseif k == "R" then
			return math.abs(sdRoundBox(gx, gy, p[2], p[3], p[4], p[5], p[6])) - p[7] / 2
		elseif k == "h" then
			local dx, dy = gx - p[2], gy - p[3]
			local dc = math.sqrt(dx * dx + dy * dy) - p[4]
			return math.max(dc, p[2] - gx)
		elseif k == "e" then
			local dx, dy = (gx - p[2]) / p[4], (gy - p[3]) / p[5]
			local d = (math.sqrt(dx * dx + dy * dy) - 1) * math.min(p[4], p[5])
			return math.abs(d) - p[6] / 2
		end
		return 1
	end

	local ICON_PX, ICON_GRID = 64, 24

	function G.iconPNG(prims)
		local k = ICON_PX / ICON_GRID
		return encodePNG(ICON_PX, ICON_PX, function(x, y)
			local gx, gy = (x + 0.5) / k, (y + 0.5) / k
			local best = 0
			for i = 1, #prims do
				local cov = 0.5 - primSd(prims[i], gx, gy) * k
				if cov > best then best = cov end
			end
			if best > 1 then best = 1 end
			return 255, 255, 255, math.floor(best * 255 + 0.5)
		end, true)
	end

	local function sunPrims()
		local p = { { "c", 12, 12, 4 } }
		for i = 0, 7 do
			local a = i * math.pi / 4
			local ca, sa = math.cos(a), math.sin(a)
			p[#p + 1] = { "l", 12 + ca * 7.2, 12 + sa * 7.2, 12 + ca * 9.6, 12 + sa * 9.6, 1.8 }
		end
		return p
	end

	G.icons = {
		toggle = { { "R", 12, 12, 9, 5.4, 5.4, 2 }, { "c", 15.8, 12, 2.7 } },
		slider = { { "l", 3.5, 8, 20.5, 8, 2 }, { "l", 3.5, 16, 20.5, 16, 2 }, { "c", 9, 8, 3 }, { "c", 15.5, 16, 3 } },
		list = {
			{ "c", 5, 7, 1.6 }, { "l", 9.5, 7, 20, 7, 2 },
			{ "c", 5, 12, 1.6 }, { "l", 9.5, 12, 20, 12, 2 },
			{ "c", 5, 17, 1.6 }, { "l", 9.5, 17, 20, 17, 2 },
		},
		input = { { "R", 12, 12, 9.5, 6.2, 2.6, 2 }, { "l", 8.5, 9, 8.5, 15, 1.8 }, { "l", 12, 12, 16, 12, 1.8 } },
		click = { { "o", 12, 12, 8, 2 }, { "c", 12, 12, 3 } },
		grid = {
			{ "r", 7.6, 7.6, 3.6, 3.6, 1.2 }, { "r", 16.4, 7.6, 3.6, 3.6, 1.2 },
			{ "r", 7.6, 16.4, 3.6, 3.6, 1.2 }, { "r", 16.4, 16.4, 3.6, 3.6, 1.2 },
		},
		columns = { { "R", 12, 12, 9, 7, 2.2, 2 }, { "l", 12, 5.6, 12, 18.4, 1.8 } },
		pulse = {
			{ "l", 2.5, 12.5, 7, 12.5, 2 }, { "l", 7, 12.5, 9.8, 5.5, 2 }, { "l", 9.8, 5.5, 14, 18.5, 2 },
			{ "l", 14, 18.5, 16.8, 12.5, 2 }, { "l", 16.8, 12.5, 21.5, 12.5, 2 },
		},
		signal = {
			{ "r", 5, 18.5, 1.5, 1.5, 0.8 }, { "r", 9.5, 17, 1.5, 3, 0.8 },
			{ "r", 14, 15.5, 1.5, 4.5, 0.8 }, { "r", 18.5, 14, 1.5, 6, 0.8 },
		},
		user = { { "c", 12, 8, 4 }, { "r", 12, 18.6, 7, 3.6, 3.6 } },
		contrast = { { "o", 12, 12, 8.2, 2 }, { "h", 12, 12, 5.2 } },
		edit = { { "l", 16.4, 7.6, 7.2, 16.8, 3.8 }, { "l", 5.2, 18.8, 7.2, 16.8, 1.6 }, { "l", 10, 20.8, 20.5, 20.8, 1.8 } },
		folder = { { "R", 12, 13.6, 9.2, 5.6, 2, 2 }, { "r", 7.4, 7.6, 3.4, 1.6, 0.8 } },
		hash = { { "l", 9, 4.5, 7.5, 19.5, 1.8 }, { "l", 16.5, 4.5, 15, 19.5, 1.8 }, { "l", 4.5, 9, 20, 9, 1.8 }, { "l", 4, 15, 19.5, 15, 1.8 } },
		up = { { "l", 12, 19.5, 12, 5.2, 2 }, { "l", 6.2, 11, 12, 5.2, 2 }, { "l", 17.8, 11, 12, 5.2, 2 } },
		down = { { "l", 12, 4.5, 12, 18.8, 2 }, { "l", 6.2, 13, 12, 18.8, 2 }, { "l", 17.8, 13, 12, 18.8, 2 } },
		sun = sunPrims(),
		percent = { { "o", 7.5, 7.5, 2.8, 1.8 }, { "o", 16.5, 16.5, 2.8, 1.8 }, { "l", 18, 5.5, 6, 18.5, 1.9 } },
		bolt = {
			{ "l", 13.5, 2.8, 6, 13.2, 1.8 }, { "l", 6, 13.2, 11.8, 13.2, 1.8 }, { "l", 11.8, 13.2, 10, 21.2, 1.8 },
			{ "l", 10, 21.2, 18, 10.2, 1.8 }, { "l", 18, 10.2, 12, 10.2, 1.8 }, { "l", 12, 10.2, 13.5, 2.8, 1.8 },
		},
		check = { { "l", 5, 12.8, 10, 17.8, 2.4 }, { "l", 10, 17.8, 19, 7, 2.4 } },
		clock = { { "o", 12, 12, 8.5, 2 }, { "l", 12, 7, 12, 12, 1.9 }, { "l", 12, 12, 15.5, 14, 1.9 } },
		plus = { { "l", 12, 5, 12, 19, 2.2 }, { "l", 5, 12, 19, 12, 2.2 } },
		info = { { "o", 12, 12, 8.6, 2 }, { "c", 12, 8, 1.3 }, { "l", 12, 11.2, 12, 16.4, 2 } },
		link = { { "R", 7.8, 12, 5, 3.4, 3.4, 1.9 }, { "R", 16.2, 12, 5, 3.4, 3.4, 1.9 }, { "l", 9.5, 12, 14.5, 12, 1.9 } },
		eye = { { "e", 12, 12, 9.2, 5.6, 2 }, { "c", 12, 12, 2.7 } },
		key = { { "o", 7.5, 12, 4, 2 }, { "l", 11.5, 12, 21, 12, 2 }, { "l", 17.5, 12, 17.5, 16, 1.9 }, { "l", 20.8, 12, 20.8, 15, 1.9 } },
	}

	return G
end)()

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
for name, glyph in pairs({
	toggle = "T", slider = "=", list = "-", input = "I", click = "o", grid = "#", columns = "|", pulse = "~",
	signal = "l", user = "U", contrast = "o", edit = "/", folder = "F", hash = "#", up = "^", down = "v",
	sun = "*", percent = "%", bolt = "!", check = "+", clock = "o", plus = "+", info = "i", link = "@",
	eye = "o", key = "K",
}) do
	Icons[name] = { "proc:" .. name, glyph }
end

local IconCache, Pending = {}, {}

local function fetchAsset(source)
	if source:find("^rbxassetid://") or source:find("^rbxasset://") then return source end
	if tonumber(source) then return "rbxassetid://" .. source end
	if source:sub(1, 5) == "proc:" then
		if not getAsset or not HasFS then return nil end
		local name = source:sub(6)
		local prims = Gen.icons[name]
		if not prims then return nil end
		ensureFolder(ROOT)
		ensureFolder(ICON_DIR)
		local path = ICON_DIR .. "/p_" .. name .. "_v1.png"
		if not isfile(path) then
			local okGen, png = pcall(Gen.iconPNG, prims)
			if not okGen or not pcall(writefile, path, png) then return nil end
		end
		local ok, asset = pcall(getAsset, path)
		if ok and asset and asset ~= "" then return asset end
		return nil
	end
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

local SHADOW_DY, SHADOW_TRANS = 6, 0.55
local function shadowAsset()
	if not getAsset or not HasFS then return nil end
	ensureFolder(ROOT)
	local path = ROOT .. "/shadow_v1.png"
	if not isfile(path) then
		local okGen, png = pcall(Gen.shadowPNG)
		if not okGen or not pcall(writefile, path, png) then return nil end
	end
	local ok, asset = pcall(getAsset, path)
	if ok and asset and asset ~= "" then return asset end
	return nil
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

Gen.yield = function() task.wait() end
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
local NotifToasts, NotifSerial, NotifShadow = {}, 0, nil

function Library:Notify(o)
	o = o or {}
	local dur = tonumber(o.Duration) or 4
	while #NotifToasts >= NOTIFY_MAX do NotifToasts[1]() end
	NotifSerial += 1

	local slot = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, LayoutOrder = NotifSerial, Parent = NotifHolder })
	local mover = new("Frame", {
		Position = UDim2.fromOffset(NOTIFY_OFF, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Parent = slot,
	})
	NotifShadow = NotifShadow == nil and (shadowAsset() or false) or NotifShadow
	if NotifShadow then
		new("ImageLabel", {
			Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 5),
			Size = UDim2.fromScale(1.1, 1.5), Image = NotifShadow, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(Gen.shadowCenter, Gen.shadowCenter, Gen.shadowCenter + 2, Gen.shadowCenter + 2),
			SliceScale = 0.55, ZIndex = 0, Parent = mover,
		})
	end
	local toast = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AutoY, Bg = "Card", Parent = mover })
	corner(toast, 12)
	stroke(toast)
	gradient(toast, 215)
	padding(toast, 14, 11, 14, 12)
	listLayout(toast, 7)

	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = toast })
	iconTile(head, o.Icon or "info", 26, 15, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
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

local function rowLabel(row, text, width, shift)
	shift = shift or 0
	width = width or UDim2.new(1, -24, 1, 0)
	return new("TextLabel", {
		Text = text or "", Fg = "Text", Position = UDim2.fromOffset(12 + shift, 0),
		Size = UDim2.new(width.X.Scale, width.X.Offset - shift, width.Y.Scale, width.Y.Offset),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
	})
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
	local function fire()
		local now = os.clock()
		if now - last < 0.06 then return end
		last = now
		fn()
	end
	connect(btn.InputBegan, function(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.MouseButton1 then
			fire()
		elseif t == Enum.UserInputType.Touch then
			if eager then
				fire()
				return
			end
			local start = i.Position
			local con
			con = i.Changed:Connect(function()
				local st = i.UserInputState
				if st == Enum.UserInputState.End then
					con:Disconnect()
					if (i.Position - start).Magnitude <= TAP_SLOP then fire() end
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
local SIDE_LABEL = UDim2.new(0.5, -12, 1, 0)
local SIDE_BOX = UDim2.new(0.5, -10, 0, 24)

function Section:AddToggle(o)
	local row = makeRow(self, 40)
	rowLabel(row, o.Name, UDim2.new(1, -90, 1, 0), rowIcon(row, o.Icon))

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

	local hit = hitZone(row, {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(HIT_W, 40),
	})

	local obj = { Type = "Toggle", Value = o.Default and true or false }
	local function kx(on) return on and (PW - PAD - KS) or PAD end
	local function render(instant)
		local on = obj.Value
		local bg = on and Theme.Accent or Theme.Hover
		local bd = on and Theme.Accent or Theme.Stroke
		local kc = on and Theme.AccentText or Theme.SubText
		local kp = UDim2.new(0, kx(on), 0.5, 0)
		if instant then
			pill.BackgroundColor3 = bg
			pst.Color = bd
			knob.BackgroundColor3 = kc
			knob.Position = kp
			return
		end
		tween(pill, { BackgroundColor3 = bg }, 0.12, Enum.EasingStyle.Quad)
		tween(pst, { Color = bd }, 0.12, Enum.EasingStyle.Quad)
		tween(knob, { Position = kp, BackgroundColor3 = kc }, 0.12, Enum.EasingStyle.Quad)
	end
	render(true)
	Hooks[#Hooks + 1] = function() render(false) end
	function obj:Set(v, silent)
		self.Value = v and true or false
		render(false)
		if silent then quiet(self) else fire(self, o) end
	end
	function obj:Get() return self.Value end
	onClick(hit, function() obj:Set(not obj.Value) end)
	register(obj, o)
	return obj
end

function Section:AddSlider(o)
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local decimals = 0
	local frac = tostring(inc):match("%.(%d+)")
	if frac then decimals = #frac end

	local row = makeRow(self, 48)
	local sh = rowIcon(row, o.Icon, 17)
	rowLabel(row, o.Name, UDim2.new(1, -86, 0, 26), sh).Position = UDim2.fromOffset(12 + sh, 4)
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
	register(obj, o)
	return obj
end

function Section:AddDropdown(o)
	local row = makeRow(self, 36)
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
			onClick(item, function()
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
		onClick(blocker, closePopup)
	end
	onClick(hit, function()
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
	local hit, target, lbl

	if primary then
		gradient(row, 200)
		target = row
		lbl = new("TextLabel", {
			Text = o.Name or "Button", Fg = "Background", Font = FONT_BOLD, Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
		})
		if o.Icon then
			makeIcon(row, o.Icon, 16, "Background", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0) })
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
				makeIcon(target, o.Icon, 14, "Accent", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0) })
			else
				makeIcon(target, o.Icon, 16, "Accent", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
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
	connect(hit.MouseButton1Up, function() tween(sc, { Scale = 1 }, 0.12, Enum.EasingStyle.Quad) end)
	onClick(hit, function()
		if o.Callback then task.spawn(o.Callback) end
	end)
	local obj = { Type = "Button" }
	function obj:SetText(t) lbl.Text = t end
	return obj
end

function Section:AddTextbox(o)
	local row = makeRow(self, 36)
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
	local obj = { Type = "Textbox", Value = o.Default or "", Input = tb }
	onClick(zone, function() tb:CaptureFocus() end)
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
	rowLabel(row, o.Name, UDim2.new(1, -118, 1, 0), rowIcon(row, o.Icon))
	local zone = hitZone(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(HIT_W, 36) })
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
	onClick(btn, function() setListening(true) end)
	onClick(zone, function() setListening(true) end)
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
	corner(card, 12)
	stroke(card)
	gradient(card, 225)
	listLayout(card, 0)

	local header = new("Frame", { Size = UDim2.new(1, 0, 0, SEC_H), LayoutOrder = 1, Parent = card })
	local hasIcon = o.Icon ~= nil
	local lx = hasIcon and 44 or 12
	if hasIcon then
		iconTile(header, o.Icon, 24, 14, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0) })
	end
	new("TextLabel", {
		Text = o.Name or "Section", Font = FONT_BOLD, Fg = "Text", Position = UDim2.fromOffset(lx, 0),
		Size = UDim2.new(1, -(lx + 34), 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})
	local chev = makeIcon(header, "chevron", 14, "SubText", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Rotation = o.Collapsed and 0 or 180 })
	local hz = hitZone(header, { Size = UDim2.fromScale(1, 1) })

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
	onClick(hz, function()
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
	if tab.Icon then
		tween(tab.IconTile, { BackgroundColor3 = on and Theme.Accent or Theme.Hover }, t)
		tintIcon(tab.Icon, on and Theme.AccentText or Theme.SubText, t)
	end
end

function Window:_sub(parentTab)
	if parentTab.SubFrame then return parentTab.SubFrame end
	local sf = new(USE_CANVAS_HIT and "CanvasGroup" or "Frame", { Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, LayoutOrder = 2, Parent = parentTab.Holder })
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

	onClick(btn, function()
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
	if self.OnToggle then pcall(self.OnToggle, state) end
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
	ap:AddToggle({ Name = "Show User", Icon = "user", Default = true, Flag = "UI_ShowUser", Callback = function(v) self:SetUserVisible(v) end })
	ap:AddToggle({ Name = "Show FPS", Icon = "pulse", Default = false, Flag = "UI_ShowFPS", Callback = function(v) self.ShowFPS = v self:_statsRefresh() end })
	ap:AddToggle({ Name = "Show Ping", Icon = "signal", Default = false, Flag = "UI_ShowPing", Callback = function(v) self.ShowPing = v self:_statsRefresh() end })

	local kb = tab:AddSection({ Name = "Keybinds", Icon = "keyboard", Side = "Left" })
	kb:AddKeybind({ Name = "Toggle UI", Icon = "keyboard", Default = self.ToggleKey, Flag = "UI_ToggleKey", Changed = function(k) if k then self.ToggleKey = k end end })
	kb:AddButton({ Name = "Unload UI", Icon = "close", Callback = function() self:RequestClose() end })

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
	iconTile(head, o.Icon or "info", 26, 15, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0) })
	new("TextLabel", {
		Text = o.Title or "Konfirmasi", Font = FONT_BOLD, TextSize = 15, Fg = "Text",
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
	onClick(cancel, function() close(o.OnCancel) end, true)
	onClick(ok, function() close(o.Callback) end, true)

	tween(blocker, { BackgroundTransparency = 0.45 }, 0.2)
	tween(card, { GroupTransparency = 0 }, 0.2)
	tween(cardStroke, { Transparency = 0 }, 0.2)
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

	local shadowImg = shadowAsset()
	if shadowImg then
		new("ImageLabel", {
			Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, SHADOW_DY),
			Size = UDim2.new(1, Gen.shadowMargin * 2, 1, Gen.shadowMargin * 2), Image = shadowImg,
			ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = SHADOW_TRANS, ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(Gen.shadowCenter, Gen.shadowCenter, Gen.shadowCenter + 2, Gen.shadowCenter + 2),
			SliceScale = 1, ZIndex = 0, Parent = Main,
		})
	end

	local Canvas = new("CanvasGroup", {
		Name = "Canvas", Size = UDim2.fromScale(1, 1), Bg = "Background", BackgroundTransparency = Library.Transparency, Parent = Main,
	})
	corner(Canvas, 12)
	TransFrames[#TransFrames + 1] = Canvas
	self.Canvas = Canvas

	local Outline = new("Frame", { Name = "Outline", Size = UDim2.fromScale(1, 1), ZIndex = 20, Active = false, Parent = Main })
	corner(Outline, 12)
	stroke(Outline)

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
		TweenService:Create(pst, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Thickness = 3, Transparency = 1 }):Play()
	end
	new("TextLabel", {
		Text = opts.Subtitle or "", TextSize = 11, Fg = "SubText", Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, 0, 0, 13), TextTruncate = Enum.TextTruncate.AtEnd, Parent = TitleBlock,
	})

	local ctrls = new("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 0), Size = UDim2.fromOffset(CTRL_W, HEADER_H), ZIndex = 30, Parent = Main,
	})
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
			end,
			function()
				tween(b, { BackgroundColor3 = Theme.Element }, 0.2)
				tween(bst, { Color = Theme.Stroke }, 0.2)
				tween(bsc, { Scale = 1 }, 0.2)
				tint(Theme.SubText, 0.2)
			end)
		connect(hit.MouseButton1Down, function() tween(bsc, { Scale = 0.9 }, 0.06) end)
		connect(hit.MouseButton1Up, function() tween(bsc, { Scale = 1 }, 0.12, Enum.EasingStyle.Quad) end)
		onClick(hit, fn, true)
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
	TweenService:Create(grad, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Offset = Vector2.new(1, 0) }):Play()

	local Sidebar = new("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, SIDEBAR_W, 1, 0), Bg = "Sidebar", BackgroundTransparency = Library.Transparency, ClipsDescendants = true, Parent = Body })
	TransFrames[#TransFrames + 1] = Sidebar
	new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), Bg = "Stroke", Parent = Sidebar })

	local search = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 30), Bg = "Element", Parent = Sidebar })
	corner(search, 9)
	local sst = stroke(search)
	gradient(search, 200)
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

		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.84, 0, 0.84, 0), Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = Theme.Accent, ZIndex = 3, Parent = holder,
		})
		round(dot)
		stroke(dot, "Sidebar", 1.5)
		local function paintDot(instant)
			tween(dot, { BackgroundColor3 = self.Visible and Theme.Accent or Theme.SubText }, instant and 0 or 0.25)
		end
		paintDot(true)
		Hooks[#Hooks + 1] = paintDot
		self.OnToggle = function() paintDot(false) end

		local fsc = new("UIScale", { Parent = fb })
		local fhit = hitZone(holder, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(TOG_SIZE + 20, TOG_SIZE + 20), ZIndex = 5 })
		onHover(fhit,
			function() tween(fsc, { Scale = 1.08 }, 0.15, Enum.EasingStyle.Quad) end,
			function() tween(fsc, { Scale = 1 }, 0.2) end)
		connect(fhit.MouseButton1Down, function() tween(fsc, { Scale = 0.9 }, 0.08) end)
		connect(fhit.MouseButton1Up, function() tween(fsc, { Scale = IS_TOUCH and 1 or 1.08 }, 0.12, Enum.EasingStyle.Quad) end)
		draggable(fhit, holder, function()
			self:Toggle()
			pulse()
			toggleCrown.Rotation = 0
			tween(toggleCrown, { Rotation = 360 }, 0.4, Enum.EasingStyle.Quint)
			task.delay(0.45, function()
				if toggleCrown.Parent then toggleCrown.Rotation = 0 end
			end)
		end)
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
	Version = "v1.6",
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
local echo = it:AddLabel({ Title = "Echo", Text = "Type something, then press Enter or click outside the box." })
local nameBox = it:AddTextbox({ Name = "Username", Icon = "user", Placeholder = "Type a name...", Flag = "I_Name", Callback = function(v)
	echo:Set("Echo", v == "" and "(empty)" or ("Username = " .. v))
end })
it:AddTextbox({ Name = "Numbers Only", Icon = "hash", Placeholder = "0 - 100", Flag = "I_Number", Callback = function(v)
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

Window:CreateSettingsTab({ Group = "ACCOUNT" })

Window:LoadAutoConfig()
Library:Notify({ Title = "ZystrixUI Tester", Content = "Ready. Press J or the round button to open/close.", Duration = 5, Icon = "crown" })

return Library
