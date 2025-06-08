-- ✅ SCRIPT COMPLETO "AUTO SYSTEM"
-- Gestisce: AutoFishing + AutoBait + Supercharged Eggs + Hatch + Magnet + GUI + One-Shot Event Hatch

local player        = game.Players.LocalPlayer
local replicated    = game:GetService("ReplicatedStorage")
local runService    = game:GetService("RunService")
local virtualInput  = game:GetService("VirtualInputManager")
local camera        = workspace.CurrentCamera

-- 🔁 Remotes
local fishingFolder   = replicated:WaitForChild("Events"):WaitForChild("Minigames"):WaitForChild("Fishing")
local boostFolder     = replicated:WaitForChild("Events"):WaitForChild("Boosts")
local teleportEvent   = replicated.Events.Teleport.TeleportClient
local autoFarmEvent   = replicated.Events.Pets.ToggleAutoFarm
local autoHatchEvent  = replicated.Events.Eggs.ToggleAutoHatch
local hatchEvent      = replicated.Events.Eggs.Hatch
local magnetEvent     = replicated.Events.Tools.MagnetServer

-- ⚙️ Valori GUI Fishing
local gui            = player:WaitForChild("PlayerGui"):WaitForChild("FishingMinigame")
local barFrame       = gui:WaitForChild("BarFrame")
local bobber         = barFrame:WaitForChild("Bobber")
local greenBar       = barFrame:WaitForChild("GreenBar")
local currency       = player:WaitForChild("currency")
local fishingCash    = currency:WaitForChild("FishingCash")

-- 🔘 Stati
local isHolding           = false
local autoFishingEnabled  = false
local autoBuyEnabled      = false
local autoUseEnabled      = false
local autoEggEnabled      = false

-- 🧭 Funzioni base
local function getMidY(frame)
    return frame.AbsolutePosition.Y + (frame.AbsoluteSize.Y / 2)
end

local function startMouseHold()
    if isHolding then return end
    isHolding = true
    virtualInput:SendMouseButtonEvent(
        camera.ViewportSize.X/2,
        camera.ViewportSize.Y/2,
        0, true, game, 1
    )
end

local function stopMouseHold()
    if not isHolding then return end
    isHolding = false
    virtualInput:SendMouseButtonEvent(
        camera.ViewportSize.X/2,
        camera.ViewportSize.Y/2,
        0, false, game, 1
    )
end

-- 🐟 AutoFishing + AutoBuy/Use
local function autoFish()
    fishingFolder.CastRod:InvokeServer()
    wait(2.5)
    fishingFolder.ReelRod:InvokeServer()
end

task.spawn(function()
    while true do
        if autoFishingEnabled then autoFish() end
        wait(4)
    end
end)

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

local function getBasicBaitStock()
    local success, result = pcall(function()
        local merchant = player.PlayerGui:FindFirstChild("MainUi", true)
                             :FindFirstChild("FishingMerchanFrame", true)
        local bait  = merchant and merchant:FindFirstChild("Basic Bait", true)
        local stock = bait and bait:FindFirstChild("Stock", true)
        return tonumber(stock.Text:match("x(%d+)") or 0)
    end)
    return success and result or 0
end

local function checkAndBuyBait()
    if not autoBuyEnabled then return end
    local value = fishingCash.Value
    if value >= 8000 then
        fishingFolder.BuyBait:InvokeServer("Divine Bait")
    elseif value >= 1000 then
        fishingFolder.BuyBait:InvokeServer("Basic Bait")
    end
end

local function checkAndUseBasicBait()
    if not autoUseEnabled then return end
    if getBasicBaitStock() > 0 then
        boostFolder.Consume:FireServer("Basic Bait", 1)
    end
end

task.spawn(function()
    while true do
        if autoFishingEnabled then
            checkAndBuyBait()
            checkAndUseBasicBait()
        end
        wait(10)
    end
end)

-- 🧠 Supercharged Egg Manager (loop normale)
local function teleportTo(pos)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
end

local function checkForSuperchargedEgg()
    if not autoEggEnabled then return end
    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:FindFirstChild("Egg")
        and egg:GetAttribute("Supercharged") then

            -- auto-farm + magnet nella zona attuale
            autoFarmEvent:FireServer()
            wait(1)
            teleportTo(egg:GetPivot().Position)
            wait(1.5)

            -- auto-hatch
            local autoHatch = player:FindFirstChild("AutoHatch")
            if autoHatch and not autoHatch.Value then
                autoHatchEvent:FireServer()
                wait(0.5)
            end
            hatchEvent:FireServer(unpack({egg,14}))
            return
        end
    end
end

task.spawn(function()
    while true do
        checkForSuperchargedEgg()
        wait(300)
    end
end)

-- 🌈 One-Shot Event Hatch (solo su pulsante)
local eventCoords = Vector3.new(1231, 94, 2247)

local function getEventSuperchargedEgg()
    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:FindFirstChild("Egg")
        and egg:GetAttribute("Supercharged") then
            return egg
        end
    end
    return nil
end

local function runEventHatch()
    -- 1) teleport evento
    teleportTo(eventCoords)
    wait(2)
    -- 2) auto-farm
    autoFarmEvent:FireServer()
    wait(2)
    -- 3) trova il supercharged egg nella zona evento
    local egg = getEventSuperchargedEgg()
    if egg then
        teleportTo(egg:GetPivot().Position)
        wait(1)
        -- 4) auto-hatch
        local autoHatch = player:FindFirstChild("AutoHatch")
        if autoHatch and not autoHatch.Value then
            autoHatchEvent:FireServer()
            wait(0.5)
        end
        hatchEvent:FireServer(unpack({egg,14}))
        print("🌈 Event Supercharged Hatch eseguito su:", egg.Name)
    else
        warn("❌ Nessun Supercharged Egg trovato nell'Event Zone")
    end
end

-- 🎨 GUI
local guiMain = Instance.new("ScreenGui")
guiMain.Name   = "AutoSystemGUI"
guiMain.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", guiMain)
frame.Size             = UDim2.new(0, 220, 0, 340)
frame.Position         = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active           = true
frame.Draggable        = true

-- bordo bianco
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 2
stroke.Color     = Color3.fromRGB(255,255,255)

-- titolo
local title = Instance.new("TextLabel", frame)
title.Size             = UDim2.new(1, 0, 0, 30)
title.Position         = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50,50,50)
title.Text             = "Auto System"
title.TextColor3       = Color3.fromRGB(255,255,255)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 18
title.TextYAlignment   = Enum.TextYAlignment.Center

-- helper per i toggle
local function makeToggle(name, y, default, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size             = UDim2.new(1, -20, 0, 40)
    btn.Position         = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    btn.TextColor3       = Color3.fromRGB(255,255,255)
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 16
    btn.Text             = name .. ": OFF"
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local active = default
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = name .. ": " .. (active and "ON" or "OFF")
        callback(active)
    end)
end

-- toggles
makeToggle("AutoFishing",     40,  false, function(v) autoFishingEnabled = v end)
makeToggle("AutoCompra Bait", 90,  false, function(v) autoBuyEnabled     = v end)
makeToggle("AutoUsa Bait",    140, false, function(v) autoUseEnabled    = v end)
makeToggle("AutoSuperEgg",    190, false, function(v) autoEggEnabled    = v end)

-- pulsante one-shot Event Hatch
local eventBtn = Instance.new("TextButton", frame)
eventBtn.Size             = UDim2.new(1, -20, 0, 40)
eventBtn.Position         = UDim2.new(0, 10, 0, 240)
eventBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 200)
eventBtn.TextColor3       = Color3.fromRGB(255,255,255)
eventBtn.Font             = Enum.Font.GothamBold
eventBtn.TextSize         = 16
eventBtn.Text             = "Run Event Hatch"
Instance.new("UICorner", eventBtn).CornerRadius = UDim.new(0, 8)

eventBtn.MouseButton1Click:Connect(function()
    eventBtn.Active = false
    eventBtn.Text   = "Running..."
    runEventHatch()
    eventBtn.Text = "Done"
end)
