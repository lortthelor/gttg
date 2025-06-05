-- ✅ SCRIPT COMPLETO "AUTO SYSTEM" REVISIONATO
-- Gestisce: AutoFishing + AutoBait (con consumo corretto) + Supercharged Eggs + Hatch + Magnet + GUI Migliorata e Draggabile

local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local camera = workspace.CurrentCamera
local userInput = game:GetService("UserInputService")

-- 🔁 Remotes
local fishingFolder = replicated.Events.Minigames.Fishing
local boostFolder = replicated.Events.Boosts
local teleportEvent = replicated.Events.Teleport.TeleportClient
local autoFarmEvent = replicated.Events.Pets.ToggleAutoFarm
local autoHatchEvent = replicated.Events.Eggs.ToggleAutoHatch
local hatchEvent = replicated.Events.Eggs.Hatch
local magnetEvent = replicated.Events.Tools.MagnetServer

-- 🧱 Interfacce e Valori
local fishingGui = player:WaitForChild("PlayerGui"):WaitForChild("FishingMinigame")
local barFrame = fishingGui:WaitForChild("BarFrame")
local bobber = barFrame:WaitForChild("Bobber")
local greenBar = barFrame:WaitForChild("GreenBar")
local fishingCash = player:WaitForChild("currency"):WaitForChild("FishingCash")

-- 🧭 Variabili
local teleportZones = {"Jungle Digsite", "Kingdom Digsite", "Choco Digsite", "Neon Digsite", "Galaxy Digsite", "Arcade Digsite"}
local autoFishingEnabled, autoBuyEnabled, autoUseEnabled, autoEggEnabled, autoMagnetEnabled = false, false, false, false, false
local isHolding, flagsPlaced = false, false
local currentSuperEgg, lastEggCheckTime = nil, 0

-- 🖱️ Fishing Hold
local function getMidY(frame)
    return frame.AbsolutePosition.Y + frame.AbsoluteSize.Y / 2
end

local function startMouseHold()
    if not isHolding then
        isHolding = true
        virtualInput:SendMouseButtonEvent(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 0, true, game, 1)
    end
end

local function stopMouseHold()
    if isHolding then
        isHolding = false
        virtualInput:SendMouseButtonEvent(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 0, false, game, 1)
    end
end

runService.Heartbeat:Connect(function()
    if autoFishingEnabled and fishingGui.Enabled then
        local delta = getMidY(greenBar) - getMidY(bobber)
        if delta > 20 then startMouseHold() elseif delta < 0 then stopMouseHold() end
    else
        stopMouseHold()
    end
end)

-- 🎣 AutoFishing Core
local function autoFish()
    fishingFolder.CastRod:InvokeServer()
    task.wait(2.5)
    fishingFolder.ReelRod:InvokeServer()
end

-- 🪱 Bait
local function getBasicBaitStock()
    local boosts = player:FindFirstChild("Boosts")
    local bait = boosts and boosts:FindFirstChild("Basic Bait")
    return bait and bait.Value or 0
end

local function checkBait()
    if autoBuyEnabled then
        local val = fishingCash.Value
        if val >= 8000 then
            fishingFolder.BuyBait:InvokeServer("Divine Bait")
        elseif val >= 1000 then
            fishingFolder.BuyBait:InvokeServer("Basic Bait")
        end
    end
    if autoUseEnabled and getBasicBaitStock() > 0 then
        boostFolder.Consume:FireServer("Basic Bait", 1)
    end
end

-- 🥚 Supercharged Eggs
local function teleportTo(cframe)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(cframe + Vector3.new(0, 4, 0))
end

local function findSuperchargedZone()
    for _, zoneName in ipairs(teleportZones) do
        local region = workspace.BlockRegions:FindFirstChild(zoneName)
        if region then
            local portal = region.Interactive and region.Interactive:FindFirstChild("Teleport")
            if portal then
                teleportEvent:FireServer(portal)
                task.wait(2.5)
                local sc = workspace:FindFirstChild("SuperchargeText")
                if sc then return sc.Position end
            end
        end
        task.wait(1)
    end
    return nil
end

local function checkSuperchargedEgg()
    if tick() - lastEggCheckTime < 60 then return end
    lastEggCheckTime = tick()

    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        local isCharged = egg:GetAttribute("Supercharged")
        if isCharged and egg.Name ~= currentSuperEgg then
            currentSuperEgg = egg.Name
            local zonePos = findSuperchargedZone()
            if zonePos then
                teleportTo(zonePos)
                task.wait(2)
                if autoMagnetEnabled and not flagsPlaced then
                    for _ = 1, 6 do
                        magnetEvent:FireServer()
                        task.wait(0.2)
                    end
                    flagsPlaced = true
                end
            end

            teleportTo(egg:GetPivot().Position)
            task.wait(2)

            local autoFarm = player:FindFirstChild("AutoFarm")
            if autoFarm and not autoFarm.Value then autoFarmEvent:FireServer() end

            local autoHatch = player:FindFirstChild("AutoHatch")
            if autoHatch and not autoHatch.Value then autoHatchEvent:FireServer() end

            hatchEvent:FireServer(egg, 14)
            warn("✅ Hatch attivo su:", egg.Name)
        end
    end
end

-- 🔁 Loop
task.spawn(function()
    while true do
        if autoFishingEnabled then autoFish() end
        if autoBuyEnabled or autoUseEnabled then checkBait() end
        if autoEggEnabled then checkSuperchargedEgg() end
        task.wait(5)
    end
end)

-- 🧩 GUI Bella & Draggabile
local gui = Instance.new("ScreenGui", player.PlayerGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 230, 0, 300)
frame.Position = UDim2.new(0, 25, 0, 80)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
local corner = Instance.new("UICorner", frame) corner.CornerRadius = UDim.new(0, 12)

-- 🖱️ Drag Manuale
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
userInput.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- 🔘 Toggle Buttons
local function makeToggle(label, yPos, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = label .. ": OFF"
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 14
    button.AutoButtonColor = false
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local active = false
    button.MouseButton1Click:Connect(function()
        active = not active
        button.Text = label .. ": " .. (active and "ON" or "OFF")
        callback(active)
    end)
end

makeToggle("Auto Fishing", 10, function(b) autoFishingEnabled = b end)
makeToggle("Compra Bait", 50, function(b) autoBuyEnabled = b end)
makeToggle("Usa Bait", 90, function(b) autoUseEnabled = b end)
makeToggle("Supercharged Egg", 130, function(b) autoEggEnabled = b end)
makeToggle("Magnet Flags", 170, function(b) autoMagnetEnabled = b flagsPlaced = false end)
