local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()
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

local Window = Rayfield:CreateWindow({
   Name = "Valhalla Hub",
   LoadingTitle = "Valhalla Loading",
   LoadingSubtitle = "by App",
   Theme = "Default",
   ToggleUIKeybind = "F8",

   ConfigurationSaving = {
      Enabled = true,
      FileName = "Valhalla Hub"
   },

   KeySystem = true,
   KeySettings = {
      Title = "App Keys",
      Subtitle = "Key System",
      Note = "Pegue a key com o App",
      FileName = "Key",
      SaveKey = true,
      Key = keysValidas,

      Callback = function(keyDigitada)
         pcall(function()
            local keyLimpa = keyDigitada:gsub("%s+", ""):gsub("[%c]", "")
            game:HttpGet(API .. "/validate?key=" .. keyLimpa .. "&hwid=" .. hwid)
         end)
      end
   }
})

local Tab = Window:CreateTab("Valhalla Hub", 4483362458)

--------------------------------------------------
-- AUTO REWARD
--------------------------------------------------

local isRunning = false
local currentId = 1

Tab:CreateToggle({
   Name = "Auto Rewards",
   CurrentValue = false,
   Callback = function(Value)
      isRunning = Value
      if isRunning then
         task.spawn(function()
            local ok, base = pcall(function()
               return ReplicatedStorage
                  :WaitForChild("Packages", 10)
                  :WaitForChild("_Index", 10)
                  :WaitForChild("sleitnick_knit@1.7.0", 10)
                  :WaitForChild("knit", 10)
                  :WaitForChild("Services", 10)
            end)

            if not ok or not base then
               warn("Base não encontrada!")
               return
            end

            -- Pega cada remote com proteção individual
            local function getRemote(serviceName, remoteName)
               local ok, remote = pcall(function()
                  return base
                     :WaitForChild(serviceName, 5)
                     :WaitForChild("RF", 5)
                     :WaitForChild(remoteName, 5)
               end)
               if ok and remote then
                  return remote
               else
                  warn("Não encontrado: " .. serviceName .. "/" .. remoteName)
                  return nil
               end
            end

            local remotes = {
               getRemote("GameService", "AwardDailyReward"),
               getRemote("QuestService", "Claim"),
               getRemote("QuestService", "ClaimAll"),
               getRemote("LevelService", "ClaimLevelRewards"),
               getRemote("RewardService", "RequestReward"),
               getRemote("MasteryService", "RequestClaim"),
               getRemote("SeasonService", "ClaimDailyPresent"),
               getRemote("SeasonService", "RequestRewardClaim"),
               getRemote("ChallengeService", "ClaimReward"),
            }

            while isRunning do
               for _, remote in pairs(remotes) do
                  if remote then
                     pcall(function()
                        remote:InvokeServer()
                     end)
                     task.wait(0.3)
                  end
               end
               task.wait(1)
            end
         end)
      end
   end
})
--------------------------------------------------
-- FPS BOOST
--------------------------------------------------

Tab:CreateToggle({
   Name = "FPS Boost + Anti Texture",
   CurrentValue = false,
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

Tab:CreateButton({
   Name = "Remove Textures",
   Callback = function()
      for _,obj in pairs(game:GetDescendants()) do
         if obj:IsA("Texture") or obj:IsA("Decal") then
            obj:Destroy()
         end
      end
   end
})

--------------------------------------------------
-- ANTI AFK
--------------------------------------------------

Tab:CreateToggle({
   Name = "Anti AFK",
   CurrentValue = false,
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

Tab:CreateButton({
   Name = "Auto Reconnect",
   Callback = function()
      player.OnTeleport:Connect(function(State)
         if State == Enum.TeleportState.Failed then
            TeleportService:Teleport(game.PlaceId, player)
         end
      end)
   end
})
