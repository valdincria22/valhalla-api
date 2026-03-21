local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not ok or not Rayfield then
    Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
end

local API = "https://valhalla-api-production-cc2a.up.railway.app"
local FILE = "valhalla_hwid.txt"
local hwid = ""
local ok2, content = pcall(readfile, FILE)
if ok2 and content and content ~= "" then
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

local Window = Rayfield:CreateWindow({
    Name = "Valhalla Hub",
    LoadingTitle = "Valhalla Loading",
    LoadingSubtitle = "by App",
    Theme = "Default",
    ToggleUIKeybind = "F8",
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = true,
    KeySettings = {
        Title = "App Keys",
        Subtitle = "Key System",
        Note = "Pegue a key com o App",
        FileName = "Key",
        SaveKey = true,
        Key = keys,
        Callback = function(k)
            pcall(function()
                local clean = k:match("^%s*(.-)%s*$"):gsub("[%c%s]", "")
                game:HttpGet(API .. "/validate?key=" .. clean .. "&hwid=" .. hwid)
            end)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/valdincria22/valhalla-api/refs/heads/main/.lua"))()
        end
    }
})
