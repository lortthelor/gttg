-- ✅ SCRIPT COMPLETO "AUTO SYSTEM" OTTIMIZZATO
-- Gestisce: AutoFishing + AutoBait + Supercharged Eggs + Hatch + Magnet + GUI

local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local camera = workspace.CurrentCamera

-- 🔁 Remotes
local fishingFolder = replicated:WaitForChild("Events"):WaitForChild("Minigames"):WaitForChild("Fishing")
local boostFolder = replicated:WaitForChild("Events"):WaitForChild("Boosts")
local teleportEvent = replicated.Events.Teleport.TeleportClient
local autoFarmEvent = replicated.Events.Pets.ToggleAutoFarm
local autoHatchEvent = replicated.Events.Eggs.ToggleAutoHatch
local hatchEvent = replicated.Events.Eggs.Hatch
local magnetEvent = replicated.Events.Tools.MagnetServer

-- ⚙️ Valori
local gui = player:WaitForChild("PlayerGui"):WaitForChild("FishingMinigame")
local barFrame = gui:WaitForChild("BarFrame")
local bobber = barFrame:WaitForChild("Bobber")
local greenBar = barFrame:WaitForChild("GreenBar")
local currency = player:WaitForChild("currency")
local fishingCash = currency:WaitForChild("FishingCash")

-- 🌍 Teleport zone fallback
local teleportZones = {
    "Jungle Digsite", "Kingdom Digsite", "Choco Digsite",
    "Neon Digsite", "Galaxy Digsite", "Arcade Digsite"
}

-- 🔘 Stati
local isHolding = false
local autoFishingEnabled = false
local autoBuyEnabled = false
local autoUseEnabled = false
local autoEggEnabled = false
local autoMagnetEnabled = false
local currentSuperEgg = nil
local currentSuperZone = nil
local flagsPlaced = false
local lastCheckedEgg = nil
local lastCheckTime = 0

-- 🧭 Funzioni base
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

-- 🐟 AutoFishing + AutoBuy/Use
local function autoFish()
    if not autoFishingEnabled then return end
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
        if delta > 20 then startMouseHold() elseif delta < 0 then stopMouseHold() end
    else
        stopMouseHold()
    end
end)

local function getBasicBaitStock()
    local boosts = player:FindFirstChild("Boosts")
    local basic = boosts and boosts:FindFirstChild("Basic Bait")
    return basic and basic.Value or 0
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
        local args = {"Basic Bait", 1}
        boostFolder:WaitForChild("Consume"):FireServer(unpack(args))
    end
end

task.spawn(function()
    while true do
        checkAndBuyBait()
        checkAndUseBasicBait()
        wait(10)
    end
end)

-- 🧠 Supercharged Egg Manager
local function teleportTo(pos)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
end

local function teleportToZone(zoneName)
    local zone = workspace.BlockRegions:FindFirstChild(zoneName)
    if zone then
        local tp = zone.Interactive:FindFirstChild("Teleport")
        if tp then
            teleportEvent:FireServer(tp)
            wait(2.5)
        end
    end
end

local function getSuperchargeZonePosition()
    for _, zone in ipairs(teleportZones) do
        teleportToZone(zone)
        wait(1.5)
        local sc = workspace:FindFirstChild("SuperchargeText")
        if sc then
            currentSuperZone = zone
            return sc.CFrame.Position
        end
    end
    return nil
end

local function checkForSuperchargedEgg()
    if not autoEggEnabled then return end
    local now = tick()
    if now - lastCheckTime < 60 then return end
    lastCheckTime = now
    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:FindFirstChild("Egg") then
            local sc = egg.Egg:FindFirstChild("Supercharge")
            if sc and egg:GetAttribute("Supercharged") and egg.Name ~= currentSuperEgg then
                print("🚨 Trovato nuovo Supercharged Egg:", egg.Name)
                local zonePos = getSuperchargeZonePosition()
                if zonePos then
                    teleportTo(zonePos)
                    wait(1.5)
                    if autoMagnetEnabled and not flagsPlaced then
                        for _ = 1, 6 do
                            magnetEvent:FireServer()
                            wait(0.2)
                        end
                        flagsPlaced = true
                    end
                end
                teleportTo(egg:GetPivot().Position)
                wait(1.5)
                local autoHatch = player:FindFirstChild("AutoHatch")
                if autoHatch and not autoHatch.Value then
                    autoHatchEvent:FireServer()
                    wait(0.5)
                end
                autoFarmEvent:FireServer()
                local model = workspace.Eggs:FindFirstChild(egg.Name)
                if model then
                    hatchEvent:FireServer(unpack({model, 14}))
                    print("✅ Hatch avviato su:", model.Name)
                    currentSuperEgg = egg.Name
                end
                return
            end
        end
    end
end

runService.Heartbeat:Connect(function()
    if autoEggEnabled then
        checkForSuperchargedEgg()
    end
end)

-- 🎨 GUI
local guiMain = Instance.new("ScreenGui")
guiMain.Name = "AutoSystemGUI"
guiMain.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", guiMain)
frame.Size = UDim2.new(0, 200, 0, 360)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local function makeToggle(name, y, default, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = name .. ": OFF"
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local active = default
    btn.MouseButton1Click:Connect(function()
        active = not active
        btn.Text = name .. ": " .. (active and "ON" or "OFF")
        callback(active)
    end)
end

makeToggle("AutoFishing", 10, false, function(v) autoFishingEnabled = v end)
makeToggle("AutoCompra Bait", 60, false, function(v) autoBuyEnabled = v end)
makeToggle("AutoUsa Bait", 110, false, function(v) autoUseEnabled = v end)
makeToggle("AutoSuperEgg", 160, false, function(v) autoEggEnabled = v end)
makeToggle("AutoMagnet", 210, false, function(v)
    autoMagnetEnabled = v
    flagsPlaced = false
end)
