-- ================================================
-- Valhalla Key System
-- ================================================

local KeySystem = {}

-- Configurações
KeySystem.Config = {
    API  = "https://valhalla-api-production-cc2a.up.railway.app",
    FILE = "valhalla_hwid.txt",
}

-- Gera ou carrega HWID salvo
function KeySystem.getHWID()
    local ok, content = pcall(readfile, KeySystem.Config.FILE)
    if ok and content and content ~= "" then
        return content
    end

    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local id = ""
    for i = 1, 32 do
        local r = math.random(1, #chars)
        id = id .. chars:sub(r, r)
    end
    pcall(writefile, KeySystem.Config.FILE, id)
    return id
end

-- Busca keys válidas da API
function KeySystem.fetchKeys()
    local keys = {}
    pcall(function()
        local raw = game:HttpGet(KeySystem.Config.API .. "/keys")
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
    return keys
end

-- Valida key contra a lista + registra no servidor
function KeySystem.validate(key, keys, hwid)
    local clean = key:match("^%s*(.-)%s*$"):gsub("[%c%s]", "")
    for _, k in pairs(keys) do
        if clean == k then
            pcall(function()
                game:HttpGet(KeySystem.Config.API .. "/validate?key=" .. clean .. "&hwid=" .. hwid)
            end)
            return true
        end
    end
    return false
end

-- Cria a GUI de inserção de key
-- onSuccess: callback chamado após key válida confirmada
function KeySystem.createGUI(onSuccess)
    local hwid = KeySystem.getHWID()
    local keys = KeySystem.fetchKeys()

    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "ValhallaKey"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 400, 0, 180)
    frame.Position = UDim2.new(0.5, -200, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Valhalla Hub - Key System"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold

    local note = Instance.new("TextLabel", frame)
    note.Size = UDim2.new(1, 0, 0, 25)
    note.Position = UDim2.new(0, 0, 0, 40)
    note.BackgroundTransparency = 1
    note.Text = "Pegue a key com o App"
    note.TextColor3 = Color3.fromRGB(180, 180, 180)
    note.TextSize = 14
    note.Font = Enum.Font.Gotham

    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(0.85, 0, 0, 35)
    input.Position = UDim2.new(0.075, 0, 0, 75)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderText = "VLH-XXXX-XXXX"
    input.Text = ""
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.BorderSizePixel = 0
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.Position = UDim2.new(0.075, 0, 0, 120)
    btn.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = "Confirmar Key"
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 1, 5)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 80, 80)
    status.TextSize = 13
    status.Font = Enum.Font.Gotham

    btn.MouseButton1Click:Connect(function()
        if KeySystem.validate(input.Text, keys, hwid) then
            status.TextColor3 = Color3.fromRGB(80, 255, 80)
            status.Text = "Key válida! Carregando..."
            task.wait(1)
            gui:Destroy()
            if onSuccess then onSuccess() end
        else
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            status.Text = "Key inválida!"
        end
    end)
end

-- ================================================
-- USO
-- ================================================

KeySystem.createGUI(function()
    -- Coloque aqui o que roda após a key ser aceita
    loadstring(game:HttpGet("https://raw.githubusercontent.com/valdincria22/valhalla-api/refs/heads/main/.lua"))()
end)
