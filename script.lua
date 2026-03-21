local L = {
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))(),
    API = "https://valhalla-api-production-cc2a.up.railway.app/",
    FILE = "valhalla_hwid.txt",
    HttpGet = game.HttpGet,
    random = math.random,
    sub = string.sub,
    gsub = string.gsub
}

local hwid = ""
local ok, content = pcall(readfile, L.FILE)

if ok and content and content ~= "" then
    hwid = content
else
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 32 do
        local r = L.random(1, #chars)
        id = id .. L.sub(chars, r, r)
    end
    hwid = id
    pcall(writefile, L.FILE, hwid)
end

local keys = {}

pcall(function()
    local raw = L.HttpGet(game, L.API .. "/keys")
    for line in raw:gmatch("[^\r\n]+") do
        local k = L.gsub(L.gsub(line, "%s+", ""), "[%c]", "")
        if k ~= "" then
            table.insert(keys, k)
        end
    end
end)

if #keys == 0 then
    keys = {"ERRO-API-OFFLINE"}
end

L.Rayfield:CreateWindow({
    Name = "Valhalla Hub",
    LoadingTitle = "Valhalla Loading",
    LoadingSubtitle = "by App",
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
                local clean = L.gsub(L.gsub(k, "%s+", ""), "[%c]", "")
                L.HttpGet(game, L.API .. "/validate?key=" .. clean .. "&hwid=" .. hwid)
            end)

            loadstring(game:HttpGet("https://raw.githubusercontent.com/valdincria22/valhalla-api/refs/heads/main/.lua"))()
        end
    }
})
