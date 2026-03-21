local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local VirtualUser = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

--------------------------------------------------
-- HWID
--------------------------------------------------

local HWID_FILE = "valhalla_hwid.txt"
local hwid = ""

local ok, conteudo = pcall(readfile, HWID_FILE)
if ok and conteudo and conteudo ~= "" then
    hwid = conteudo
else
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 32 do
        local rand = math.random(1, #chars)
        id = id .. chars:sub(rand, rand)
    end
    hwid = id
    pcall(writefile, HWID_FILE, hwid)
end

--------------------------------------------------
-- BUSCA KEYS DA API
--------------------------------------------------

local API = "https://valhalla-api-production-cc2a.up.railway.app"
local keysValidas = {}

local ok2 = pcall(function()
    local raw = game:HttpGet(API .. "/keys")
    for linha in raw:gmatch("[^\r\n]+") do
        local key = linha:gsub("%s+", ""):gsub("[%c]", "")
        if key ~= "" then
            table.insert(keysValidas, key)
        end
    end
end)

if not ok2 or #keysValidas == 0 then
    keysValidas = {"ERRO-API-OFFLINE"}
end

--------------------------------------------------
-- WINDOW
--------------------------------------------------

local Window = Fluent:CreateWindow({
    Title = "Valhalla Hub",
    SubTitle = "by App",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.F8
})

--------------------------------------------------
-- KEY SYSTEM
--------------------------------------------------

local validado = false
local KeyTab = Window:AddTab({ Title = "Key System", Icon = "lock" })

KeyTab:AddInput("KeyInput", {
    Title = "Digite sua Key",
    Default = "",
    Placeholder = "Pegue a key com o App",
    Numeric = false,
    Finished = false,
    Callback = function(keyDigitada)
        local keyLimpa = keyDigitada:gsub("%s+", ""):gsub("[%c]", "")
        for _, k in pairs(keysValidas) do
            if keyLimpa == k then
                validado = true
                pcall(function()
                    game:HttpGet(API .. "/validate?key=" .. keyLimpa .. "&hwid=" .. hwid)
                end)
                Fluent:Notify({
                    Title = "Valhalla Hub",
                    Content = "Key válida! Bem-vindo.",
                    Duration = 5
                })
                return
            end
        end
        Fluent:Notify({
            Title = "Valhalla Hub",
            Content = "Key inválida!",
            Duration = 5
        })
    end
})

--------------------------------------------------
-- MAIN TAB
--------------------------------------------------

local Tab = Window:AddTab({ Title = "Valhalla Hub", Icon = "star" })

--------------------------------------------------
-- AUTO REWARD
--------------------------------------------------

local isRunning = false

Tab:AddToggle("AutoRewards", {
    Title = "Auto Rewards",
    Default = false,
    Callback = function(Value)
        isRunning = Value
        if isRunning then
            task.spawn(function()
                local base = ReplicatedStorage
                    :WaitForChild("Packages")
                    :WaitForChild("_Index")
                    :WaitForChild("sleitnick_knit@1.7.0")
                    :WaitForChild("knit")
                    :WaitForChild("Services")

                local function getRemote(serviceName, rfOrRe, remoteName)
                    local ok, remote = pcall(function()
                        return base
                            :WaitForChild(serviceName)
                            :WaitForChild(rfOrRe)
                            :WaitForChild(remoteName)
                    end)
                    if ok and remote then
                        return remote
                    else
                        warn("Não encontrado: " .. serviceName .. "/" .. remoteName)
                        return nil
                    end
                end

                local remotes = {
                    getRemote("GameService",              "RF", "AwardDailyReward"),
                    getRemote("QuestService",             "RF", "Claim"),
                    getRemote("QuestService",             "RF", "ClaimAll"),
                    getRemote("LevelService",             "RF", "ClaimLevelRewards"),
                    getRemote("RewardService",            "RF", "RequestReward"),
                    getRemote("MasteryService",           "RF", "RequestClaim"),
                    getRemote("SeasonService",            "RF", "RequestRewardClaim"),
                    getRemote("SeasonService",            "RF", "ClaimDailyPresent"),
                    getRemote("SeasonService",            "RF", "RefreshDailyPresents"),
                    getRemote("ChallengeService",         "RF", "ClaimReward"),
                    getRemote("LeaderboardRewardService", "RF", "RequestReward"),
                }

                while isRunning do
                    for _, remote in pairs(remotes) do
                        if remote then
                            pcall(function()
                                remote:InvokeServer()
                            end)
                            task.wait(1.5)
                        end
                    end
                    task.wait(10)
                end
            end)
        end
    end
})

--------------------------------------------------
-- FPS BOOST
--------------------------------------------------

Tab:AddToggle("FpsBoost", {
    Title = "FPS Boost + Anti Texture",
    Default = false,
    Callback = function(Value)
        if Value then
            for _,v in pairs(game:GetDescendants()) do
                if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy() end
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                end
            end
            game.Lighting.GlobalShadows = false
            game.Lighting.FogEnd = 100000
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
    end
})

--------------------------------------------------
-- REMOVE TEXTURES
--------------------------------------------------

Tab:AddButton({
    Title = "Remove Textures",
    Callback = function()
        for _,obj in pairs(game:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj:Destroy()
            end
        end
        Fluent:Notify({
            Title = "Valhalla Hub",
            Content = "Texturas removidas!",
            Duration = 3
        })
    end
})

--------------------------------------------------
-- ANTI AFK
--------------------------------------------------

Tab:AddToggle("AntiAfk", {
    Title = "Anti AFK",
    Default = false,
    Callback = function(Value)
        if Value then
            player.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
    end
})

--------------------------------------------------
-- AUTO RECONNECT
--------------------------------------------------

Tab:AddButton({
    Title = "Auto Reconnect",
    Callback = function()
        player.OnTeleport:Connect(function(State)
            if State == Enum.TeleportState.Failed then
                TeleportService:Teleport(game.PlaceId, player)
            end
        end)
        Fluent:Notify({
            Title = "Valhalla Hub",
            Content = "Auto Reconnect ativado!",
            Duration = 3
        })
    end
})

--------------------------------------------------
-- SELECT TAB INICIAL
--------------------------------------------------

Window:SelectTab(1)
