-- ⚙️ Setup
local player = game.Players.LocalPlayer
local replicated = game:GetService("ReplicatedStorage")
local workspaceEggs = workspace:WaitForChild("Eggs")

local autoFarmEvent = replicated.Events.Pets.ToggleAutoFarm
local autoHatchEvent = replicated.Events.Eggs.ToggleAutoHatch
local hatchEvent = replicated.Events.Eggs.Hatch
local teleportEvent = replicated.Events.Teleport.TeleportClient

local currentSuperEgg = nil

-- 🌍 Zone da ciclare se non si trova SuperchargeText
local teleportZones = {
    "Jungle Digsite",
    "Kingdom Digsite",
    "Choco Digsite",
    "Neon Digsite",
    "Galaxy Digsite",
    "Arcade Digsite"
}

-- 🚪 Teletrasporto a una zona specifica
local function teleportToZone(zoneName)
    local success, result = pcall(function()
        local zone = workspace:WaitForChild("BlockRegions"):WaitForChild(zoneName)
        local teleporter = zone:WaitForChild("Interactive"):WaitForChild("Teleport")
        teleportEvent:FireServer(teleporter)
    end)
    if success then
        print("🗺️ Teletrasportato a:", zoneName)
        wait(2.5)
    else
        warn("❌ Errore nel teletrasporto alla zona:", zoneName)
    end
end

-- 📍 Trova la posizione della zona Supercharge
local function getSuperchargeZonePosition()
    local superObj = workspace:FindFirstChild("SuperchargeText")

    if not superObj then
        for _, zone in ipairs(teleportZones) do
            teleportToZone(zone)
            wait(2)
            superObj = workspace:FindFirstChild("SuperchargeText")
            if superObj then break end
        end
    end

    if not superObj then
        warn("⚠️ SuperchargeText non trovato nemmeno dopo cambio zone.")
        return nil
    end

    return superObj.CFrame.Position
end

-- 🚶 Funzione di teletrasporto a posizione 3D
local function teleportTo(position)
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(position + Vector3.new(0, 5, 0))
end

-- 🔁 Funzione principale per gestire uovo Supercharged
local function checkForSuperchargedEgg()
    for _, egg in pairs(workspaceEggs:GetChildren()) do
        if egg:IsA("Model") and egg:FindFirstChild("Egg") then
            local supercharge = egg.Egg:FindFirstChild("Supercharge")
            local isSuper = egg:GetAttribute("Supercharged")

            if supercharge and isSuper and egg.Name ~= currentSuperEgg then
                print("📦 Trovato nuovo Supercharged Egg:", egg.Name)

                -- 🔴 Disattiva solo AutoFarm
                autoFarmEvent:FireServer()
                wait(1)

                -- 📍 Zona Supercharge
                local zonePosition = getSuperchargeZonePosition()
                if zonePosition then
                    teleportTo(zonePosition)
                    wait(2.5)
                    autoFarmEvent:FireServer()
                    wait(1)
                else
                    print("⚠️ Nessuna zona Supercharge trovata, procedo solo con Hatch.")
                end

                -- 🥚 Teletrasporto all’uovo
                teleportTo(egg:GetPivot().Position)
                wait(1.5)

                -- ✅ Verifica e attiva AutoHatch se non già attivo
                local autoHatchValue = player:FindFirstChild("AutoHatch")
                if autoHatchValue and not autoHatchValue.Value then
                    autoHatchEvent:FireServer()
                    wait(0.5)
                end

                -- 🐣 Hatch tramite args (corretta struttura richiesta dal gioco)
                local eggModel = workspace.Eggs:FindFirstChild(egg.Name)
                if eggModel then
                    local args = {eggModel, 14}
                    hatchEvent:FireServer(unpack(args))
                    print("✅ Hatch avviato correttamente su:", eggModel.Name)
                else
                    warn("❌ Egg non trovato per Hatch:", egg.Name)
                end

                currentSuperEgg = egg.Name
                return
            end
        end
    end
end

-- 🔄 Ciclo ogni 60 secondi
task.spawn(function()
    while true do
        checkForSuperchargedEgg()
        wait(60)
    end
end)
