-- 🐟 AutoFishing Completo con GUI Moderna, Teletrasporto e Gestione Bait

local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local camera = workspace.CurrentCamera

-- Elementi di gioco
local fishingFolder = replicatedStorage:WaitForChild("Events"):WaitForChild("Minigames"):WaitForChild("Fishing")
local boostFolder = replicatedStorage:WaitForChild("Events"):WaitForChild("Boosts")
local gui = player.PlayerGui:WaitForChild("FishingMinigame")
local barFrame = gui:WaitForChild("BarFrame")
local bobber = barFrame:WaitForChild("Bobber")
local greenBar = barFrame:WaitForChild("GreenBar")

-- Valute
local currency = player:WaitForChild("currency")
local fishingCash = currency:WaitForChild("FishingCash")

-- Stati
local isHolding = false
local autoFishingEnabled = false
local autoBuyEnabled = false
local autoUseEnabled = false

-- 🧭 Teletrasporto tramite portale + attivazione zona Fishing
local function teleportToFishingMinigame()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- 2. Attiva teleport (simula cliccare portale)
    local args = {
        workspace:WaitForChild("BlockRegions"):WaitForChild("Pirate Cove Digsite")
            :WaitForChild("Interactive"):WaitForChild("Teleport")
    }

    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Teleport")
        :WaitForChild("TeleportClient"):FireServer(unpack(args))
    -- 1. Vai davanti al portale (rende il trigger attivabile)
    hrp.CFrame = CFrame.new(-216, 4, -852)
    wait(1.5)

    -- 3. Attendi che il personaggio sia nella zona (opzionale delay aggiuntivo)
    wait(3)
end


-- Mouse Hold
local function getMidY(frame)
    return frame.AbsolutePosition.Y + (frame.AbsoluteSize.Y / 2)
end

local function startMouseHold()
    if isHolding then return end
    isHolding = true
    virtualInput:SendMouseButtonEvent(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 0, true, game, 1)
end

local function stopMouseHold()
    if not isHolding then return end
    isHolding = false
    virtualInput:SendMouseButtonEvent(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 0, false, game, 1)
end

-- Pesca
local function autoFish()
    if not autoFishingEnabled then return end
    fishingFolder.CastRod:InvokeServer()
    wait(2.5)
    fishingFolder.ReelRod:InvokeServer()
end

-- Sicuro stock check
local function getBasicBaitStock()
    local success, result = pcall(function()
        local merchantFrame = player.PlayerGui:WaitForChild("MainUi", 2):FindFirstChild("FishingMerchanFrame", true)
        local basicBait = merchantFrame and merchantFrame:FindFirstChild("Basic Bait", true)
        local stockLabel = basicBait and basicBait:FindFirstChild("Stock", true)
        if stockLabel and stockLabel.Text then
            local value = tonumber(stockLabel.Text:match("x(%d+)"))
            return value or 0
        end
        return 0
    end)
    return success and result or 0
end

-- Compra esche
local function checkAndBuyBait()
    if not autoBuyEnabled then return end
    local value = fishingCash.Value
    if value >= 8000 then
        fishingFolder.BuyBait:InvokeServer("Divine Bait")
        print("🛒 Comprata Divine Bait")
    elseif value >= 1000 then
        fishingFolder.BuyBait:InvokeServer("Basic Bait")
        print("🛒 Comprata Basic Bait")
    end
end

-- Usa Basic Bait
local function checkAndUseBasicBait()
    if not autoUseEnabled then return end
    local stock = getBasicBaitStock()
    if stock > 0 then
        boostFolder.Consume:FireServer("Basic Bait", 1)
        print("🎯 Usata Basic Bait")
    end
end

-- Mouse Hold Loop
runService.Heartbeat:Connect(function()
    if autoFishingEnabled and gui.Enabled then
        local delta = getMidY(greenBar) - getMidY(bobber)
        if delta > 20 then
            startMouseHold()
        elseif delta < 0 then
            stopMouseHold()
        end
    else
        stopMouseHold()
    end
end)

-- Pesca Loop
task.spawn(function()
    while true do
        if autoFishingEnabled then
            autoFish()
        end
        wait(4)
    end
end)

-- Acquisto e uso Loop
task.spawn(function()
    while true do
        if autoFishingEnabled then
            checkAndBuyBait()
            checkAndUseBasicBait()
        end
        wait(10)
    end
end)

-- 🎨 GUI Moderna
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "AutoFishingGUI"
screenGui.ResetOnSpawn = false

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 250)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.1
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(100, 255, 100)

-- Funzione per creare pulsanti toggle
local function createToggle(text, posY, colorOn, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = text .. ": OFF"
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and colorOn or Color3.fromRGB(100, 100, 100)
        if state then teleportToFishingMinigame() end
        callback(state)
    end)
end

createToggle("AutoFishing", 10, Color3.fromRGB(200, 50, 50), function(v) autoFishingEnabled = v end)
createToggle("AutoCompra Bait", 60, Color3.fromRGB(50, 200, 255), function(v) autoBuyEnabled = v end)
createToggle("AutoUsa Bait", 110, Color3.fromRGB(255, 150, 50), function(v) autoUseEnabled = v end)
