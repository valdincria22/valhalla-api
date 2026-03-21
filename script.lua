local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local API = "https://valhalla-api-production-cc2a.up.railway.app"
local FILE = "valhalla_hwid.txt"
local hwid = ""

local ok, content = pcall(readfile, FILE)
if ok and content and content ~= "" then
    hwid = content
else
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
    end
    hwid = id
    pcall(writefile, FILE, hwid)
end

local keys = {}
pcall(function()
    local raw = game:HttpGet(API .. "/keys")
    for line in raw:gmatch("[^\r\n]+") do
        local k = line:match("^%s*(.-)%s*$"):gsub("[%c%s]", "")
        if k ~= "" then
            table.insert(keys, k)
        end
    end
end)

if #keys == 0 then
    keys = {"ERRO-API-OFFLINE"}
end

local keyValida = false
local keyPrompt = Library:CreateWindow('Valhalla Hub - Key System')
local keyBox = keyPrompt:AddTextbox('Digite sua Key:', '', function(v)
    local clean = v:match("^%s*(.-)%s*$"):gsub("[%c%s]", "")
    for _, k in pairs(keys) do
        if clean == k then
            keyValida = true
            pcall(function()
                game:HttpGet(API .. "/validate?key=" .. clean .. "&hwid=" .. hwid)
            end)
            Library:Notify("Key válida! Carregando...", 3)
            task.wait(1)
            keyPrompt:Destroy()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/valdincria22/valhalla-api/refs/heads/main/.lua"))()
            return
        end
    end
    Library:Notify("Key inválida!", 3)
end)
