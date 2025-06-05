-- ✅ SCRIPT AUTO SYSTEM COMPLETO - VERSIONE CORRETTA
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
local consumeBoostEvent = replicated.Events.Boosts.Consume

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
local currentSuperchargedZone = nil
local autoMineActive = false

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
    -- Auto Buy Bait
    if autoBuy and fishingCash.Value >= 1000 then
        fishingFolder.BuyBait:InvokeServer("Basic Bait")
    end
    if autoBuy and fishingCash.Value >= 8000 then
        fishingFolder.BuyBait:InvokeServer("Divine Bait")
    end
    
    -- Auto Use Bait - CORRETTO
    if autoUse and getBasicBaitStock() > 0 then
        local args = {"Basic Bait", 1}
        consumeBoostEvent:FireServer(unpack(args))
    end
end

-- Supercharged Zone Detection - MIGLIORATO
local function findSuperchargedZone()
    print("🔍 Cercando zona supercharged...")
    
    for _, zone in ipairs(zones) do
        print("📍 Controllando zona:", zone)
        local region = workspace.BlockRegions:FindFirstChild(zone)
        if region and region:FindFirstChild("Interactive") then
            local portal = region.Interactive:FindFirstChild("Teleport")
            if portal then
                teleportEvent:FireServer(portal)
                wait(3) -- Aspetta un po' di più per il caricamento
                
                -- Controlla se esiste SuperchargeText
                if workspace:FindFirstChild("SuperchargeText") then
                    print("✅ Trovata zona supercharged:", zone)
                    currentSuperchargedZone = zone
                    
                    -- Attiva AutoFarm (AutoMine)
                    if not autoMineActive then
                        autoFarmEvent:FireServer()
                        autoMineActive = true
                        print("⛏️ AutoMine attivato")
                    end
                    
                    -- Piazza Magnet Flags se attivo nella GUI
                    if autoMagnet and not flagsPlaced then
                        print("🧲 Piazzando magnet flags...")
                        for i = 1, 6 do
                            magnetEvent:FireServer()
                            wait(0.2)
                        end
                        flagsPlaced = true
                        print("✅ Magnet flags piazzate")
                    end
                    
                    return true
                end
            end
        end
        wait(1)
    end
    
    print("❌ Nessuna zona supercharged trovata")
    currentSuperchargedZone = nil
    return false
end

local function teleportToEgg(egg)
    local pos = egg:GetPivot().Position
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
    print("🥚 Teletrasportato all'uovo:", egg.Name)
end

-- Supercharged Egg Logic - COMPLETAMENTE RISCRITTO
local function checkSuperchargedEgg()
    -- Controllo ogni 60 secondi
    if tick() - lastEggCheck < 60 then return end
    lastEggCheck = tick()
    
    print("🔄 Controllo supercharged egg...")
    
    -- Trova l'uovo supercharged attuale
    local currentSuperchargedEgg = nil
    for _, egg in ipairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:GetAttribute("Supercharged") then
            currentSuperchargedEgg = egg
            break
        end
    end
    
    if not currentSuperchargedEgg then
        print("❌ Nessun uovo supercharged trovato")
        return
    end
    
    -- Se è un nuovo uovo o se non abbiamo ancora una zona
    if currentSuperchargedEgg.Name ~= lastEggName or not currentSuperchargedZone then
        print("🆕 Nuovo uovo supercharged rilevato:", currentSuperchargedEgg.Name)
        lastEggName = currentSuperchargedEgg.Name
        
        -- Reset flags per la nuova ricerca
        flagsPlaced = false
        autoMineActive = false
        currentSuperchargedZone = nil
        
        -- Cerca la zona supercharged
        if findSuperchargedZone() then
            -- Teletrasportati all'uovo
            teleportToEgg(currentSuperchargedEgg)
            wait(1.5)
            
            -- Attiva AutoHatch
            autoHatchEvent:FireServer()
            print("🐣 AutoHatch attivato")
            
            -- Hatcha l'uovo
            hatchEvent:FireServer(currentSuperchargedEgg, 14)
            print("🎉 Uovo hatchato!")
        else
            print("⚠️ Impossibile trovare zona supercharged per l'uovo")
        end
    else
        print("ℹ️ Stesso uovo supercharged, nessuna azione necessaria")
    end
end

-- Background Loops
task.spawn(function()
    while true do
        if autoFishing then 
            pcall(autoFish) -- Usa pcall per evitare crash
        end
        if autoBuy or autoUse then 
            pcall(handleBait)
        end
        if autoEgg then 
            pcall(checkSuperchargedEgg)
        end
        wait(5)
    end
end)

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "AutoSystemGUI"
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 230, 0, 300)
frame.Position = UDim2.new(0, 30, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Titolo
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.Position = UDim2.new(0, 0, 0, -30)
title.BackgroundTransparency = 1
title.Text = "🔧 AUTO SYSTEM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16

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
        button.BackgroundColor3 = state and Color3.fromRGB(46, 125, 50) or Color3.fromRGB(60, 60, 60)
        callback(state)
    end)
end

-- Create all toggles
makeToggle("🎣 Auto Fishing", 10, function(v) autoFishing = v end)
makeToggle("💰 Compra Bait", 50, function(v) autoBuy = v end)
makeToggle("🪝 Usa Bait", 90, function(v) autoUse = v end)
makeToggle("🥚 Supercharged Egg", 130, function(v) 
    autoEgg = v 
    if not v then
        -- Reset quando disattivato
        flagsPlaced = false
        autoMineActive = false
        currentSuperchargedZone = nil
    end
end)
makeToggle("🧲 Magnet Flags", 170, function(v) 
    autoMagnet = v 
    if not v then
        flagsPlaced = false
    end
end)

-- Status Label
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, -20, 0, 60)
statusLabel.Position = UDim2.new(0, 10, 0, 210)
statusLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = "Status: Pronto"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextWrapped = true
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

-- Aggiorna status in tempo reale
task.spawn(function()
    while true do
        local status = "Status: "
        if autoEgg and currentSuperchargedZone then
            status = status .. "🟢 Zona: " .. currentSuperchargedZone
        elseif autoEgg then
            status = status .. "🔍 Cercando zona..."
        else
            status = status .. "⚪ In attesa"
        end
        
        if autoFishing then status = status .. " | 🎣 Fishing" end
        if autoUse then status = status .. " | 🪝 Using Bait" end
        
        statusLabel.Text = status
        wait(2)
    end
end)

print("✅ Auto System caricato con successo!")
