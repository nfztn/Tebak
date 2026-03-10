--// Nfztn Test (Roblox LocalScript)
--// Fungsi: GUI pencarian awalan (prefix) dari daftar kata yang diambil lewat HttpGet,
--// tampilkan hasil, ada pagination, tombol next page, tombol minimize, dan efek warna pelangi.

--[[
  CARA PAKAI:
  1) Taruh ini sebagai LocalScript di:
     StarterPlayerScripts  (paling aman), atau StarterGui
  2) Pastikan game kamu mengizinkan HttpGet:
     - Game Settings > Security > Allow HTTP Requests (ON)
  3) Pastikan URL word list bisa diakses.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- URL word list (1 kata per baris).
-- Kamu bisa ganti kalau punya list sendiri.
local WORDLIST_URL = "https://raw.githubusercontent.com/eenvyexe/KBBI/refs/heads/main/words.txt"

-- Konfigurasi
local RESULTS_PER_PAGE = 20

-- State
local words = {}
local page = 1
local minimized = false
local hue = 0

-- Helpers
local function trimSpaces(s: string): string
	-- hapus spasi/tab berlebih
	return (s:gsub("%s+", ""))
end

local function safeLower(s: string): string
	return string.lower(s or "")
end

local function startsWith(s: string, prefix: string): boolean
	return s:sub(1, #prefix) == prefix
end

local function fetchWordList()
	local ok, body = pcall(function()
		-- HttpGet hanya tersedia kalau HttpService/Allow HTTP Requests aktif
		return game:HttpGet(WORDLIST_URL)
	end)

	if not ok or type(body) ~= "string" or #body == 0 then
		return false, "Gagal mengambil word list (HTTP). Pastikan Allow HTTP Requests ON dan URL valid."
	end

	local seen = {}
	local out = {}

	for line in body:gmatch("[^\r\n]+") do
		-- Ambil kata alfabet dan tanda minus seperti versi obfuscated
		-- (contoh: kata-kata, anti-virus)
		local w = line:match("([%a%-]+)")
		if w and #w > 1 then
			w = safeLower(w)
			if not seen[w] then
				seen[w] = true
				table.insert(out, w)
			end
		end
	end

	words = out
	return true
end

-- UI build
local gui = Instance.new("ScreenGui")
gui.Name = "Nfztn Test"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Background"
frame.Parent = gui
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Position = UDim2.new(0.5, -80, 0.4, -40)
frame.Size = UDim2.new(0, 160, 0, 180)
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 6)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Parent = frame
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 8, 0, 6)
title.Size = UDim2.new(1, -40, 0, 18)
title.Font = Enum.Font.GothamBold
title.Text = "Nfztn Test"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Parent = frame
minimizeBtn.BackgroundTransparency = 1
minimizeBtn.Position = UDim2.new(1, -28, 0, 2)
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.Text = "[-]"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 10

local divider = Instance.new("Frame")
divider.Parent = frame
divider.BorderSizePixel = 0
divider.Position = UDim2.new(0, 0, 0, 24)
divider.Size = UDim2.new(1, 0, 0, 1)
divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

local body = Instance.new("Frame")
body.Parent = frame
body.BackgroundTransparency = 1
body.Position = UDim2.new(0, 0, 0, 28)
body.Size = UDim2.new(1, 0, 1, -28)

local input = Instance.new("TextBox")
input.Parent = body
input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
input.Position = UDim2.new(0.5, -72, 0, 4)
input.Size = UDim2.new(0, 144, 0, 24)
input.PlaceholderText = "Cari awalan..."
input.Text = ""
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.TextSize = 10
input.ClearTextOnFocus = false

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = input

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = body
scroll.BackgroundTransparency = 1
scroll.Position = UDim2.new(0, 8, 0, 34)
scroll.Size = UDim2.new(1, -16, 1, -65)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 2

local resultsLabel = Instance.new("TextLabel")
resultsLabel.Parent = scroll
resultsLabel.BackgroundTransparency = 1
resultsLabel.Size = UDim2.new(1, 0, 0, 0)
resultsLabel.AutomaticSize = Enum.AutomaticSize.Y
resultsLabel.Font = Enum.Font.GothamSemibold
resultsLabel.Text = "Input huruf..."
resultsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
resultsLabel.TextSize = 10
resultsLabel.TextWrapped = true
resultsLabel.TextXAlignment = Enum.TextXAlignment.Left
resultsLabel.TextYAlignment = Enum.TextYAlignment.Top

local nextBtn = Instance.new("TextButton")
nextBtn.Parent = body
nextBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
nextBtn.Position = UDim2.new(0.5, -72, 1, -28)
nextBtn.Size = UDim2.new(0, 144, 0, 18)
nextBtn.Font = Enum.Font.GothamBold
nextBtn.Text = "LAINNYA"
nextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
nextBtn.TextSize = 9

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 4)
nextCorner.Parent = nextBtn

local pageLabel = Instance.new("TextLabel")
pageLabel.Parent = body
pageLabel.BackgroundTransparency = 1
pageLabel.Position = UDim2.new(0, 8, 1, -28)
pageLabel.Size = UDim2.new(0, 120, 0, 18)
pageLabel.Font = Enum.Font.Code
pageLabel.Text = "Halaman: 1"
pageLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
pageLabel.TextSize = 11
pageLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Core logic: filter + pagination
local function renderResults(resetPage: boolean)
	if resetPage then
		page = 1
	end

	local query = safeLower(trimSpaces(input.Text))
	if query == "" then
		resultsLabel.Text = "Input huruf..."
		pageLabel.Text = "Halaman: 1"
		return
	end

	local startIndex = (page - 1) * RESULTS_PER_PAGE + 1
	local endIndex = startIndex + RESULTS_PER_PAGE - 1

	local matches = {}
	local count = 0

	for _, w in ipairs(words) do
		if startsWith(w, query) then
			count += 1
			if count >= startIndex and count <= endIndex then
				table.insert(matches, string.upper(w))
			end
			if count > endIndex then
				break
			end
		end
	end

	if #matches > 0 then
		resultsLabel.Text = table.concat(matches, "\n")
	else
		resultsLabel.Text = "Tidak ditemukan."
	end

	pageLabel.Text = "Halaman: " .. tostring(page)
end

-- Fetch list once
task.spawn(function()
	local ok, err = fetchWordList()
	if not ok then
		resultsLabel.Text = err
	else
		-- kalau user sudah ngetik cepat sebelum download selesai
		renderResults(true)
	end
end)

-- Events
input:GetPropertyChangedSignal("Text"):Connect(function()
	renderResults(true) -- reset halaman saat query berubah
end)

nextBtn.MouseButton1Click:Connect(function()
	page += 1
	renderResults(false)
end)

minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	body.Visible = not minimized
	divider.Visible = not minimized

	if minimized then
		frame.Size = UDim2.new(0, 160, 0, 24)
		minimizeBtn.Text = "[+]"
	else
		frame.Size = UDim2.new(0, 160, 0, 180)
		minimizeBtn.Text = "[-]"
	end
end)

-- Rainbow effect (mirip obfuscated)
RunService.RenderStepped:Connect(function(dt)
	hue = (hue + (0.5 / 360)) % 1
	local c = Color3.fromHSV(hue, 0.8, 1)
	title.TextColor3 = c
	divider.BackgroundColor3 = c
end)