-- === ANTI-AFK ===
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    task.wait(1)
    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(0.1)
    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
-- =================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local player = Players.LocalPlayer
local CharactersFolder = workspace:WaitForChild("Characters")

local root = nil
local enabled = false
local guiClosed = false
local gui, toggle, closeBtn = nil, nil, nil
local Noclipping = nil

-- Weapons
local hitEvents = {
    ReplicatedStorage.Modules.Net["RE/ToiletWeaponActivated"],
    ReplicatedStorage.Modules.Net["RE/TrashbagHit"],
    ReplicatedStorage.Modules.Net["RE/PipeActivated"],
    ReplicatedStorage.Modules.Net["RE/stopsignalHit"],
    ReplicatedStorage.Modules.Net["RE/trashbinDisguiseHit"],
    ReplicatedStorage.Modules.Net["RE/mopHit"],
    ReplicatedStorage.Modules.Net["RE/PoolNoodleActivated"],
    ReplicatedStorage:WaitForChild("PUNCHEVENT"),
    ReplicatedStorage.Modules.Net["RE/sprayRemote"],
    ReplicatedStorage.Modules.Net["RE/BeachShovelHit"],
    ReplicatedStorage.Modules.Net["RE/panHit"],
    ReplicatedStorage.Modules.Net["RE/taserRemote"],
    ReplicatedStorage.Modules.Net["RE/flamethrowerFire"],
    ReplicatedStorage.Modules.Net["RE/BatonHit"],
    ReplicatedStorage.Modules.Net["RE/pinkStopSignalHit"],
    ReplicatedStorage.Modules.Net["RE/baseballBatHit"],
    ReplicatedStorage.Modules.Net["RE/StickActivated"],
    ReplicatedStorage.Modules.Net["RE/CrowbarHit"],
    ReplicatedStorage.Modules.Net["RE/GoldenFlameThrowerFire"],
    ReplicatedStorage.Modules.Net["RE/GoldenTaserRemote"],
    ReplicatedStorage.Modules.Net["RE/goldStopSignalHit"],
    ReplicatedStorage.Modules.Net["RE/sledgehammer"],
    ReplicatedStorage.Modules.Net["RE/PurseActivated"],
    ReplicatedStorage.Modules.Net["RE/PinkPanHit"],
    ReplicatedStorage.Modules.Net["RE/ShieldHit"],
    ReplicatedStorage.Modules.Net["RE/SpatulaHit"],
    ReplicatedStorage.Modules.Net["RE/chefKnifeHit"],
    ReplicatedStorage.Modules.Net["RE/slasherClawsHit"]
}

-- GUI creation
local function createGUI()
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "NPC_Teleport_GUI"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 120)
    frame.Position = UDim2.new(0, 20, 0, 200)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.Parent = gui

    toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(1, -10, 0, 50)
    toggle.Position = UDim2.new(0, 5, 0, 5)
    toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    toggle.Text = "Teleport: OFF"
    toggle.Parent = frame

    closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, -10, 0, 40)
    closeBtn.Position = UDim2.new(0, 5, 0, 60)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeBtn.Text = "Close"
    closeBtn.Parent = frame

    gui.Parent = player:WaitForChild("PlayerGui")

    toggle.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            toggle.Text = "Teleport: ON"
            toggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        else
            toggle.Text = "Teleport: OFF"
            toggle.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
            --if Noclipping then Noclipping:Disconnect() end


			waypoints = {}
			clearPathVisuals()


        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        enabled = false
        guiClosed = true
        if gui then gui:Destroy() end
        if Noclipping then Noclipping:Disconnect() end
    end)
end
createGUI()

-- Character tracking
local function onCharacter(char)
    root = char:WaitForChild("HumanoidRootPart")
    if not guiClosed and (not gui or not gui.Parent) then
        createGUI()
    end
end

if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)

-- NPC targeting
local targetNames = {
    ["Gym Bro 1"] = true,
    ["Gym Bro 2"] = true,
    ["Gym Bro 3"] = true
}

local function getClosestNPC()
    if not root then return nil end
    local closest, smallest = nil, math.huge
    for _, npc in ipairs(CharactersFolder:GetChildren()) do
        if targetNames[npc.Name] then
            local rootPart = npc:FindFirstChild("HumanoidRootPart")
            if rootPart and npc ~= player.Character and not Players:GetPlayerFromCharacter(npc) then
                local dist = (rootPart.Position - root.Position).Magnitude
                if dist < smallest then
                    smallest = dist
                    closest = npc
                end
            end
        end
    end
    return closest
end


-- Highlight for the current target NPC
local npcHighlight = Instance.new("Highlight")
npcHighlight.FillColor = Color3.fromRGB(255, 0, 0)
npcHighlight.FillTransparency = 0.5
npcHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
npcHighlight.OutlineTransparency = 0
npcHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local currentHighlightedNPC = nil

local function updateNPCHighlight(npc)
    if currentHighlightedNPC == npc then
        return
    end

    currentHighlightedNPC = npc

    if npc then
        npcHighlight.Parent = npc
        npcHighlight.Adornee = npc
    else
        npcHighlight.Parent = nil
        npcHighlight.Adornee = nil
    end
end


-- ===== Pathfinding state =====
local waypoints = {}
local waypointIndex = 1
local lastTargetPos = nil

local RECOMPUTE_INTERVAL = 0.5    -- seconds between forced path recomputes
local TARGET_MOVE_THRESHOLD = 4   -- studs the NPC must move before we force a recompute
local WAYPOINT_REACHED_DIST = 3   -- how close we need to be to a waypoint to advance
local STOP_DISTANCE = 2           -- stop pathing once this close to the NPC

local recomputeTimer = 0




local pathFolder = workspace:FindFirstChild("BotPathVisuals")
if not pathFolder then
    pathFolder = Instance.new("Folder")
    pathFolder.Name = "BotPathVisuals"
    pathFolder.Parent = workspace
end

local function clearPathVisuals()
    pathFolder:ClearAllChildren()
end

local function drawPath()
    clearPathVisuals()

    for i = waypointIndex, #waypoints do
        local wp = waypoints[i]

        local part = Instance.new("Part")
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Material = Enum.Material.Neon

        if wp.Action == Enum.PathWaypointAction.Jump then
            part.Color = Color3.fromRGB(0, 255, 255) -- Cyan = Jump
        else
            part.Color = Color3.fromRGB(255, 80, 0) -- Orange = Walk
        end

        part.Position = wp.Position
        part.Parent = pathFolder
    end
end


-- Computes a waypoint path from our current position to `destination`.
local function computePathTo(destination)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4,
    })

    local ok = pcall(function()
        path:ComputeAsync(root.Position, destination)
    end)

    if ok and path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end

    return nil
end

-- Moves the humanoid toward the NPC using the current waypoint list
local function moveToPosition(npc, humanoid, dt)
    if not root or not npc or not humanoid then return end

    local targetPart = npc:FindFirstChild("HumanoidRootPart")
        or npc:FindFirstChild("LowerTorso")
        or npc:FindFirstChild("Torso")
    if not targetPart then return end

    local targetPos = targetPart.Position
    local distance = (targetPos - root.Position).Magnitude

    if distance <= STOP_DISTANCE then
		waypoints = {}
		clearPathVisuals()
		humanoid:MoveTo(root.Position)

        return
    end

    -- [FIX] Proactive Raycast Jump: If we are moving and hit a wall, jump instantly
    if humanoid.MoveDirection.Magnitude > 0.1 then
        local rayParams = RaycastParams.new()
        rayParams.FilterDescendantsInstances = {player.Character, npc}
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        
        -- Shoot a ray out at knee/hip height in our walking direction
        local wallHit = workspace:Raycast(root.Position - Vector3.new(0, 1, 0), humanoid.MoveDirection * 3.5, rayParams)
        if wallHit and wallHit.Instance.CanCollide then
            humanoid.Jump = true
        end
    end

    recomputeTimer += dt
    local targetMoved = lastTargetPos
        and (targetPos - lastTargetPos).Magnitude > TARGET_MOVE_THRESHOLD

    if #waypoints == 0 or recomputeTimer >= RECOMPUTE_INTERVAL or targetMoved then
        recomputeTimer = 0
        lastTargetPos = targetPos

        local newWaypoints = computePathTo(targetPos)
		if newWaypoints then
		    waypoints = newWaypoints
		    waypointIndex = math.min(2, #waypoints)
		    drawPath()
		end



    end

    local currentWaypoint = waypoints[waypointIndex]
    if currentWaypoint then
        -- [FIX] Flatten the calculation vector to ignore vertical height differences
        local flatWaypointPos = Vector3.new(currentWaypoint.Position.X, root.Position.Y, currentWaypoint.Position.Z)
        local wpDist = (flatWaypointPos - root.Position).Magnitude

        if wpDist < WAYPOINT_REACHED_DIST then
            waypointIndex += 1
            currentWaypoint = waypoints[waypointIndex]
        end

        if currentWaypoint then
            if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid:MoveTo(currentWaypoint.Position)
        end
    end
end





local lastAttackTime = 0
local attackCooldown = 0.3
local attackRange = 6 -- How close you need to be before swinging

RunService.Heartbeat:Connect(function(dt)
    if not enabled or not root then
        updateNPCHighlight(nil)
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local npc = getClosestNPC()

    updateNPCHighlight(npc)

    if not npc or not humanoid then return end

    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return end

    local distance = (root.Position - npcRoot.Position).Magnitude

    -- ONLY path system controls movement
    moveToPosition(npc, humanoid, dt)

    -- ATTACK SYSTEM ONLY
    if distance <= attackRange then

        root.CFrame = CFrame.lookAt(
            root.Position,
            Vector3.new(npcRoot.Position.X, root.Position.Y, npcRoot.Position.Z)
        )

        local now = tick()
        if now - lastAttackTime >= attackCooldown then
            for _, ev in ipairs(hitEvents) do
                if ev then
                    ev:FireServer(1)
                end
            end
            lastAttackTime = now
        end
    end

    -- AUTO EQUIP ONLY
    local char = player.Character
    if char then
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            local purse = backpack:FindFirstChild("SpikedPurse")
            if purse and purse.Parent ~= char then
                purse.Parent = char
            end
        end
    end
end)
