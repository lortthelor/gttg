-- ✅ AUTO SYSTEM COMPLETO - Rework + GUI Migliorata
-- Funzioni: AutoFishing, AutoBait, Supercharged Egg Hatch, Event AutoMine, GUI Draggabile

local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local camera = workspace.CurrentCamera

-- 🔁 Remotes
local fishing = replicated.Events.Minigames.Fishing
local boosts = replicated.Events.Boosts
local teleportEvent = replicated.Events.Teleport.TeleportClient
local autoFarm = replicated.Events.Pets.ToggleAutoFarm
local autoHatch = replicated.Events.Eggs.ToggleAutoHatch
local hatch = replicated.Events.Eggs.Hatch
local magnet = replicated.Events.Tools.MagnetServer

-- ⚙️ Variabili di stato
local isHolding = false
local autoFishing = false
local autoBuyBait = false
local autoUseBait = false
local superEggHatch = false
local eventAutoMine = false

-- 🧭 Utility
local function teleportTo(position)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
end

-- 🐟 AutoFishing
local function fishLoop()
    while true do
        if autoFishing then
            fishing.CastRod:InvokeServer()
            task.wait(2.5)
            fishing.ReelRod:InvokeServer()
        end
        task.wait(4)
    end
end

task.spawn(fishLoop)

-- 🧠 AutoHold per minigioco
local gui = player:WaitForChild("PlayerGui"):WaitForChild("FishingMinigame")
local function getMidY(frame)
    return frame.AbsolutePosition.Y + (frame.AbsoluteSize.Y / 2)
end

runService.Heartbeat:Connect(function()
    if autoFishing and gui.Enabled then
        local bobber = gui.BarFrame.Bobber
        local green = gui.BarFrame.GreenBar
        if (getMidY(green) - getMidY(bobber)) > 20 then
            if not isHolding then
                isHolding = true
                virtualInput:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, true, game, 1)
            end
        else
            if isHolding then
                isHolding = false
                virtualInput:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, false, game, 1)
            end
        end
    elseif isHolding then
        isHolding = false
        virtualInput:SendMouseButtonEvent(camera.ViewportSize.X/2, camera.ViewportSize.Y/2, 0, false, game, 1)
    end
end)

-- 🎯 Bait Management
local fishingCash = player.currency.FishingCash
local function manageBait()
    while true do
        if autoBuyBait and fishingCash.Value >= 1000 then
            local baitType = fishingCash.Value >= 8000 and "Divine Bait" or "Basic Bait"
            fishing.BuyBait:InvokeServer(baitType)
        end
        if autoUseBait then
            boosts.Consume:FireServer("Basic Bait", 1)
        end
        task.wait(10)
    end
end

task.spawn(manageBait)

-- 🥚 Supercharged Egg Hunter
local function hatchSuperEgg()
    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        if egg:GetAttribute("Supercharged") and egg:FindFirstChild("Egg") then
            teleportTo(egg:GetPivot().Position)
            task.wait(1)
            autoFarm:FireServer()
            task.wait(0.5)
            if player:FindFirstChild("AutoHatch") and not player.AutoHatch.Value then
                autoHatch:FireServer()
            end
            hatch:FireServer(egg, 14)
            break
        end
    end
end

task.spawn(function()
    while true do
        if superEggHatch then hatchSuperEgg() end
        task.wait(60)
    end
end)

-- 🗺️ Event AutoMine
local eventPosition = Vector3.new(1231, 94, 2247)
local function runEventMine()
    teleportTo(eventPosition)
    task.wait(2)
    autoFarm:FireServer()
    task.wait(1)
    magnet:FireServer()
end

task.spawn(function()
    while true do
        if eventAutoMine then runEventMine() end
        task.wait(180)
    end
end)

-- 🎨 GUI Migliorata
local guiMain = Instance.new("ScreenGui", player.PlayerGui)
local frame = Instance.new("Frame", guiMain)
frame.Size = UDim2.new(0, 240, 0, 300)
frame.Position = UDim2.new(0, 30, 0, 30)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local uiLayout = Instance.new("UIListLayout", frame)
uiLayout.Padding = UDim.new(0, 6)
uiLayout.FillDirection = Enum.FillDirection.Vertical
uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uiLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local function createToggle(name, stateVar, callback)
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Text = name .. ": OFF"
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseButton1Click:Connect(function()
        _G[stateVar] = not _G[stateVar]
        btn.Text = name .. ": " .. (_G[stateVar] and "ON" or "OFF")
        callback(_G[stateVar])
    end)
end

createToggle("AutoFishing", "autoFishing", function(v) autoFishing = v end)
createToggle("AutoCompra Bait", "autoBuyBait", function(v) autoBuyBait = v end)
createToggle("AutoUsa Bait", "autoUseBait", function(v) autoUseBait = v end)
createToggle("AutoSuperEgg", "superEggHatch", function(v) superEggHatch = v end)
createToggle("EventAutoMine", "eventAutoMine", function(v) eventAutoMine = v end)
