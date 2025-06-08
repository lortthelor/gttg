-- ✅ SCRIPT COMPLETO "AUTO SYSTEM" + EventAutoMine Mode
-- Gestisce: AutoFishing + AutoBait + Supercharged Eggs + Hatch + Magnet + GUI + EventAutoMine

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

-- 🔘 Stati
local isHolding = false
local autoFishingEnabled = false
local autoBuyEnabled = false
local autoUseEnabled = false
local autoEggEnabled = false
local eventAutoMineEnabled = false
local currentSuperEgg = nil

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
    local success, result = pcall(function()
        local merchantFrame = player.PlayerGui:FindFirstChild("MainUi", true):FindFirstChild("FishingMerchanFrame", true)
        local bait = merchantFrame and merchantFrame:FindFirstChild("Basic Bait", true)
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

-- 🧠 Supercharged Egg Manager
local function teleportTo(pos)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
end

local function checkForSuperchargedEgg()
    if not autoEggEnabled then return end
    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:FindFirstChild("Egg") then
            local isSuper = egg:GetAttribute("Supercharged")
            if isSuper then
                print("🚨 Trovato Supercharged Egg:", egg.Name)
                teleportTo(egg:GetPivot().Position)
                wait(1.5)
                autoFarmEvent:FireServer()
                wait(0.5)
                local autoHatch = player:FindFirstChild("AutoHatch")
                if autoHatch and not autoHatch.Value then
                    autoHatchEvent:FireServer()
                    wait(0.5)
                end
                hatchEvent:FireServer(unpack({egg, 14}))
                print("✅ Hatch su Supercharged Egg:", egg.Name)
                currentSuperEgg = egg.Name
                return
            end
        end
    end
end

task.spawn(function()
    while true do
        if autoEggEnabled then
            checkForSuperchargedEgg()
        end
        wait(60)
    end
end)

-- 🗺️ Event AutoMine
local function runEventAutoMine()
    if not eventAutoMineEnabled then return end

    local eventPosition = Vector3.new(1231, 94, 2247)
    teleportTo(eventPosition)
    wait(2)
    autoFarmEvent:FireServer()
    wait(1)
    magnetEvent:FireServer()
end

task.spawn(function()
    while true do
        if eventAutoMineEnabled then
            runEventAutoMine()
        end
        wait(180)
    end
end)

-- 🎨 GUI
local guiMain = Instance.new("ScreenGui")
guiMain.Name = "AutoSystemGUI"
guiMain.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame", guiMain)
frame.Size = UDim2.new(0, 200, 0, 330)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
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
makeToggle("EventAutoMine", 210, false, function(v) eventAutoMineEnabled = v end)
