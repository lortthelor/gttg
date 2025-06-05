-- ✅ SCRIPT AUTO SYSTEM - VERSIONE FUNZIONANTE
-- Risolve: AutoBait, Supercharged Egg Detection, Teleport automatico

local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local virtualInput = game:GetService("VirtualInputManager")
local userInput = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Remotes
local fishingFolder = replicated.Events.Minigames.Fishing
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
local lastEggName = ""
local lastEggCheck = 0

-- Teleport zones
local zones = {
    "Jungle Digsite", "Kingdom Digsite", "Choco Digsite",
    "Neon Digsite", "Galaxy Digsite", "Arcade Digsite"
}

-- Debug function
local function debugPrint(msg)
    print("[AUTO SYSTEM] " .. msg)
end

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
    pcall(function()
        fishingFolder.CastRod:InvokeServer()
        wait(2.5)
        fishingFolder.ReelRod:InvokeServer()
    end)
end

-- Bait handling - VERSIONE CORRETTA
local function getBasicBaitStock()
    local boosts = player:FindFirstChild("Boosts")
    if boosts and boosts:FindFirstChild("Basic Bait") then
        return boosts["Basic Bait"].Value
    end
    return 0
end

local function useBait()
    if not autoUse then return end
    
    local stock = getBasicBaitStock()
    debugPrint("Stock Basic Bait: " .. stock)
    
    if stock > 0 then
        -- Prova tutti i possibili percorsi per il consume
        local success = false
        
        -- Metodo 1: Percorso diretto
        pcall(function()
            local args = {"Basic Bait", 1}
            replicated.Events.Boosts.Consume:FireServer(unpack(args))
            debugPrint("Bait usata (metodo 1)")
            success = true
        end)
        
        -- Metodo 2: Se il primo fallisce
        if not success then
            pcall(function()
                replicated.Events.Boosts.Consume:FireServer("Basic Bait", 1)
                debugPrint("Bait usata (metodo 2)")
                success = true
            end)
        end
        
        -- Metodo 3: Alternativo
        if not success then
            pcall(function()
                game:GetService("ReplicatedStorage").Events.Boosts.Consume:FireServer("Basic Bait", 1)
                debugPrint("Bait usata (metodo 3)")
            end)
        end
    else
        debugPrint("Nessuna bait disponibile")
    end
end

local function buyBait()
    if not autoBuy then return end
    
    if fishingCash.Value >= 1000 then
        pcall(function()
            fishingFolder.BuyBait:InvokeServer("Basic Bait")
            debugPrint("Basic Bait comprata")
        end)
    end
    
    if fishingCash.Value >= 8000 then
        pcall(function()
            fishingFolder.BuyBait:InvokeServer("Divine Bait")
            debugPrint("Divine Bait comprata")
        end)
    end
end

-- Supercharged detection - VERSIONE CORRETTA
local function findSuperchargedEgg()
    for _, egg in pairs(workspace.Eggs:GetChildren()) do
        if egg:IsA("Model") and egg:GetAttribute("Supercharged") then
            return egg
        end
    end
    return nil
end

local function teleportToZone(zoneName)
    local region = workspace.BlockRegions:FindFirstChild(zoneName)
    if region and region:FindFirstChild("Interactive") then
        local portal = region.Interactive:FindFirstChild("Teleport")
        if portal then
            debugPrint("Teletrasporto a: " .. zoneName)
            teleportEvent:FireServer(portal)
            return true
        end
    end
    return false
end

local function checkForSuperchargeText()
    return workspace:FindFirstChild("SuperchargeText") ~= nil
end

local function findSuperchargedZone()
    debugPrint("Cerco zona supercharged...")
    
    for _, zone in ipairs(zones) do
        if teleportToZone(zone) then
            wait(3) -- Aspetta il caricamento
            
            if checkForSuperchargeText() then
                debugPrint("TROVATA zona supercharged: " .. zone)
                return zone
            else
                debugPrint("Zona " .. zone .. " non è supercharged")
            end
        end
        wait(1)
    end
    
    debugPrint("Nessuna zona supercharged trovata")
    return nil
end

local function teleportToEgg(egg)
    if not egg then return end
    
    local char = player.Character
    if not char then return end
    
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local eggPos = egg:GetPivot().Position
    humanoidRootPart.CFrame = CFrame.new(eggPos + Vector3.new(0, 5, 0))
    debugPrint("Teletrasportato all'uovo: " .. egg.Name)
end

local function activateAutoFarm()
    pcall(function()
        autoFarmEvent:FireServer()
        debugPrint("AutoFarm/AutoMine attivato")
    end)
end

local function placeMagnetFlags()
    if not autoMagnet then return end
    
    debugPrint("Piazzo magnet flags...")
    for i = 1, 6 do
        pcall(function()
            magnetEvent:FireServer()
        end)
        wait(0.2)
    end
    debugPrint("Magnet flags piazzate")
end

local function hatchSuperchargedEgg(egg)
    if not egg then return end
    
    -- Attiva AutoHatch
    pcall(function()
        autoHatchEvent:FireServer()
        debugPrint("AutoHatch attivato")
    end)
    
    wait(1)
    
    -- Hatcha l'uovo
    pcall(function()
        hatchEvent:FireServer(egg, 14)
        debugPrint("Uovo hatchato: " .. egg.Name)
    end)
end

-- Main supercharged logic
local function handleSuperchargedEgg()
    if not autoEgg then return end
    
    -- Controllo ogni 60 secondi
    if tick() - lastEggCheck < 60 then return end
    lastEggCheck = tick()
    
    debugPrint("=== CONTROLLO SUPERCHARGED EGG ===")
    
    local currentEgg = findSuperchargedEgg()
    if not currentEgg then
        debugPrint("Nessun uovo supercharged trovato")
        return
    end
    
    debugPrint("Uovo supercharged trovato: " .. currentEgg.Name)
    
    -- Se è un nuovo uovo
    if currentEgg.Name ~= lastEggName then
        lastEggName = currentEgg.Name
        debugPrint("NUOVO uovo supercharged: " .. currentEgg.Name)
        
        -- Trova la zona supercharged
        local superZone = findSuperchargedZone()
        if superZone then
            debugPrint("Zona trovata: " .. superZone)
            
            -- Attiva AutoFarm
            activateAutoFarm()
            
            -- Piazza magnet flags
            placeMagnetFlags()
            
            wait(2)
            
            -- Teletrasportati all'uovo
            teleportToEgg(currentEgg)
            
            wait(2)
            
            -- Hatcha l'uovo
            hatchSuperchargedEgg(currentEgg)
        else
            debugPrint("ERRORE: Impossibile trovare zona supercharged")
        end
    else
        debugPrint("Stesso uovo, nessuna azione")
    end
end

-- Main loop
task.spawn(function()
    debugPrint("Sistema avviato!")
    
    while true do
        -- AutoFishing
        if autoFishing then
            autoFish()
        end
        
        -- Bait management
        buyBait()
        useBait()
        
        -- Supercharged egg
        handleSuperchargedEgg()
        
        wait(5)
    end
end)

-- GUI Creation
local gui = Instance.new("ScreenGui")
gui.Name = "AutoSystemGUI"
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 350)
frame.Position = UDim2.new(0, 30, 0, 60)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- Drag functionality
local dragging = false
local dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

userInput.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 5)
title.BackgroundTransparency = 1
title.Text = "🔧 AUTO SYSTEM v2.0"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

-- Toggle creation function
local function createToggle(text, yPos, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text .. ": OFF"
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button
    
    local state = false
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = text .. ": " .. (state and "ON" or "OFF")
        button.BackgroundColor3 = state and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(60, 60, 60)
        callback(state)
        debugPrint(text .. " " .. (state and "attivato" or "disattivato"))
    end)
end

-- Create toggles
createToggle("🎣 Auto Fishing", 50, function(state) autoFishing = state end)
createToggle("💰 Compra Bait", 95, function(state) autoBuy = state end)
createToggle("🪝 Usa Bait", 140, function(state) autoUse = state end)
createToggle("🥚 Supercharged Egg", 185, function(state) 
    autoEgg = state 
    if state then
        lastEggCheck = 0 -- Force immediate check
    end
end)
createToggle("🧲 Magnet Flags", 230, function(state) autoMagnet = state end)

-- Status display
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 70)
statusLabel.Position = UDim2.new(0, 10, 0, 275)
statusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = "✅ Sistema pronto!\nAttiva le funzioni desiderate"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.Parent = frame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel

-- Status updater
task.spawn(function()
    while true do
        local status = "Status: "
        local details = {}
        
        if autoFishing then table.insert(details, "🎣 Fishing") end
        if autoUse then table.insert(details, "🪝 Using Bait") end
        if autoEgg then table.insert(details, "🥚 Egg Hunt") end
        
        if #details > 0 then
            status = status .. table.concat(details, " | ")
        else
            status = status .. "⏸️ In pausa"
        end
        
        status = status .. "\n\nBait Stock: " .. getBasicBaitStock()
        status = status .. "\nCash: " .. math.floor(fishingCash.Value)
        
        statusLabel.Text = status
        wait(3)
    end
end)

debugPrint("GUI creata con successo!")
