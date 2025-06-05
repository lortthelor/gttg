-- ✅ SCRIPT AUTO SYSTEM COMPLETO
-- Include: AutoFishing, AutoBuy/Use Bait, Supercharged Egg Detection, AutoFarm, AutoHatch, Magnet Flags, GUI draggabile

local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local userInput = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Remotes
local fishingFolder = replicated.Events.Minigames.Fishing
local boostFolder = replicated.Events.Boosts
local teleportEvent = replicated.Events.Teleport.TeleportClient
local autoFarmEvent = replicated.Events.Pets.ToggleAutoFarm
local autoHatchEvent = replicated.Events.Eggs.ToggleAutoHatch
local hatchEvent = replicated.Events.Eggs.Hatch
local magnetEvent = replicated.Events.Tools.MagnetServer

-- GUI Elements
local fishingGui = player.PlayerGui:WaitForChild("FishingMinigame")
local barFrame = fishingGui:WaitForChild("BarFrame")
local bobber = barFrame:WaitForChild("Bobber")
local greenBar = barFrame:WaitForChild("GreenBar")
local fishingCash = player:WaitForChild("currency"):WaitForChild("FishingCash")

-- Flags
local autoFishing, autoBuy, autoUse, autoEgg, autoMagnet = false, false, false, false, false
local isHolding = false
local flagsPlaced = false
local lastEggName = ""
local lastEggCheck = 0

-- Teleport zones
local zones = {
    "Jungle Digsite", "Kingdom Digsite", "Choco Digsite",
    "Neon Digsite", "Galaxy Digsite", "Arcade Digsite"
}

-- Utility
local function getMidY(frame)
    return frame.AbsolutePosition.Y + frame.AbsoluteSize.Y / 2
end

local function startHold()
    if isHolding then return end
    isHolding = true
    virtualInput:SendMouseButtonEvent(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 0, true, game, 1)
end

local function stopHold()
    if not isHolding then return end
    isHolding = false
    virtualInput:SendMouseButtonEvent(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2, 0, false, game, 1)
end

-- AutoFishing hold bar
runService.Heartbeat:Connect(function()
    if autoFishing and fishingGui.Enabled then
        local delta = getMidY(greenBar) - getMidY(bobber)
        if delta > 20 then startHold() elseif delta < 0 then stopHold() end
    else
        stopHold()
    end
end)

-- AutoFishing logic
local function autoFish()
    fishingFolder.CastRod:InvokeServer()
    wait(2.5)
    fishingFolder.ReelRod:InvokeServer()
end

-- Bait handling
local function getBasicBaitStock()
    local b = player:FindFirstChild("Boosts")
    return b and b:FindFirstChild("Basic Bait") and b["Basic Bait"].Value or 0
end

local function handleBait()
    if autoBuy and fishingCash.Value >= 1000 then
        fishingFolder.BuyBait:InvokeServer("Basic Bait")
    end
    if autoBuy and fishingCash.Value >= 8000 then
        fishingFolder.BuyBait:InvokeServer("Divine Bait")
    end
    if autoUse and getBasicBaitStock() > 0 then
        local args = { "Basic Bait", 1 }
        replicated.Events.Boosts.Consume:FireServer(unpack(args))
    end
end

-- Supercharged Egg Logic
local function teleportToSuperchargeZone()
    for _, zone in ipairs(zones) do
        local region = workspace.BlockRegions:FindFirstChild(zone)
        if region and region:FindFirstChild("Interactive") then
            local portal = region.Interactive:FindFirstChild("Teleport")
            if portal then
                teleportEvent:FireServer(portal)
                wait(2.5)
                if workspace:FindFirstChild("SuperchargeText") then
                    return true
                end
            end
        end
        wait(1)
    end
    return false
end

local function teleportToEgg(egg)
    local pos = egg:GetPivot().Position
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
end

local function checkSuperchargedEgg()
    if tick() - lastEggCheck < 60 then return end
    lastEggCheck = tick()

    for _, egg in ipairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:GetAttribute("Supercharged") and egg.Name ~= lastEggName then
            lastEggName = egg.Name

            -- Teleport to zone
            if teleportToSuperchargeZone() then
                if autoMagnet and not flagsPlaced then
                    for _ = 1, 6 do
                        magnetEvent:FireServer()
                        wait(0.2)
                    end
                    flagsPlaced = true
                end
            end

            -- Teleport to egg
            teleportToEgg(egg)
            wait(1.5)

            -- Enable AutoFarm & AutoHatch
            replicated.Events.Pets.ToggleAutoFarm:FireServer()
            replicated.Events.Eggs.ToggleAutoHatch:FireServer()

            -- Hatch the egg
            hatchEvent:FireServer(egg, 14)
        end
    end
end

-- Background Loops
task.spawn(function()
    while true do
        if autoFishing then autoFish() end
        if autoBuy or autoUse then handleBait() end
        if autoEgg then checkSuperchargedEgg() end
        wait(5)
    end
end)

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 230, 0, 300)
frame.Position = UDim2.new(0, 30, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Drag system
local dragging = false
local dragStart, startPos

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

-- Toggle Generator
local function makeToggle(text, yPos, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

    local state = false
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
end

-- Create all toggles
makeToggle("Auto Fishing", 10, function(v) autoFishing = v end)
makeToggle("Compra Bait", 50, function(v) autoBuy = v end)
makeToggle("Usa Bait", 90, function(v) autoUse = v end)
makeToggle("Supercharged Egg", 130, function(v) autoEgg = v flagsPlaced = false end)
makeToggle("Magnet Flags", 170, function(v) autoMagnet = v flagsPlaced = false end)
