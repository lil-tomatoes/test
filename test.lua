--!strict
-- Full persistent GUI with WalkSpeed slider, Jump, Fly, Noclip, Tabs, minimize/close
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

-- destroy any previous small GUI so we recreate the full one
local old = playerGui:FindFirstChild("CustomGUI")
if old then
	old:Destroy()
end

local GC = getconnections or get_signal_cons
if GC then
	for i,v in pairs(GC(Players.LocalPlayer.Idled)) do
		if v["Disable"] then
			v["Disable"](v)
		elseif v["Disconnect"] then
			v["Disconnect"](v)
		end
	end
else
	local VirtualUser = cloneref(game:GetService("VirtualUser"))
	Players.LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end


-- === persistent settings stored globally for re-exec persistence in-session ===
_G.PlayerSettings = _G.PlayerSettings or {
	walkEnabled = false,
	jumpEnabled = false,
	walkSpeed = 22,
	jumpPower = 50,
	flyEnabled = false,
	flySpeed = 16,
	noclipEnabled = false,
    hitActionsEnabled = false,
    spinActionsEnabled = true,
    autohealActionsEnabled = false
}

-- === cleanup for re-execution ===
if _G.PlayerLoops then
	if _G.PlayerLoops.RenderConn then _G.PlayerLoops.RenderConn:Disconnect() end
	if _G.PlayerLoops.NoclipConn then _G.PlayerLoops.NoclipConn:Disconnect() end
end
_G.PlayerLoops = {}

-- === GUI creation ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 300)
MainFrame.Position = UDim2.new(0.68, 0, 0.45, 0)
MainFrame.AnchorPoint = Vector2.new(0, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Add UICorner for rounded corners
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10) -- Adjust the second value (pixel offset) to change the roundness
Corner.Parent = MainFrame

-- Title bar (Keeping your custom size: 60px tall)
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(40,40,40)
TitleBar.Parent = MainFrame

local TitleText = Instance.new("TextLabel")
TitleText.Text = "Tomatoes"
TitleText.Size = UDim2.new(0, 0, -1, 0)
TitleText.BackgroundTransparency = 1
TitleText.TextColor3 = Color3.fromRGB(255,255,255)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 18
TitleText.Position = UDim2.new(0.5, 0, 0, 40)
TitleText.Parent = TitleBar
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = TitleBar

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0,25,0,25)
CloseBtn.Position = UDim2.new(1, -30, 0, 3)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 16
CloseBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
CloseBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
CloseBtn.Parent = TitleBar
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 100)
Corner.Parent = CloseBtn
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

---- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,25,0,25)
MinBtn.Position = UDim2.new(1, -60, 0, 3)
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 30
MinBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 0)
MinBtn.Parent = TitleBar
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 100)
Corner.Parent = MinBtn

-- Minimize logic
MinBtn.MouseButton1Click:Connect(function()
    -- FIX: Toggles the visibility of the entire MainFrame (Minimize/Restore).
    MainFrame.Visible = not MainFrame.Visible
end)
-- === Keybind Logic (Control Key to Toggle GUI) ===
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    -- Ignore input if it was processed by Roblox (like typing in a chat box)
    if gameProcessedEvent then return end

    -- Check if the pressed key is the Left Control or Right Control key
    if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
        -- Toggle the visibility of the MainFrame
        MainFrame.Visible = not MainFrame.Visible
    end
end)

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(0.75, 0, 0, 25)
TabFrame.Position = UDim2.new(0, 3, 0, 30)
TabFrame.BackgroundTransparency = 1
TabFrame.Parent = MainFrame

-- *** THE FIX ***
local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
TabListLayout.Parent = TabFrame
-- ***************

local ButtonWidth = 0.33 -- 1 / 3 = 0.3333...

local PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.new(ButtonWidth, 0, 1, 0)
PlayerTab.Text = "Player"
PlayerTab.BackgroundColor3 = Color3.fromRGB(70,70,70)
PlayerTab.AutoButtonColor = false
PlayerTab.TextColor3 = Color3.new(1,1,1)
PlayerTab.Parent = TabFrame
local Corner1 = Instance.new("UICorner")
Corner1.CornerRadius = UDim.new(0, 5) -- Reduced radius for better fit
Corner1.Parent = PlayerTab

local TargetTab = Instance.new("TextButton")
TargetTab.Size = UDim2.new(ButtonWidth, 0, 1, 0)
TargetTab.Text = "Target"
TargetTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
TargetTab.AutoButtonColor = false
TargetTab.BackgroundTransparency = 1
TargetTab.TextColor3 = Color3.new(1,1,1)
TargetTab.Parent = TabFrame
local Corner2 = Instance.new("UICorner")
Corner2.CornerRadius = UDim.new(0, 5)
Corner2.Parent = TargetTab

local CombatTab = Instance.new("TextButton")
CombatTab.Size = UDim2.new(ButtonWidth, 0, 1, 0)
CombatTab.Text = "Combat"
CombatTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
CombatTab.AutoButtonColor = false
CombatTab.BackgroundTransparency = 1
CombatTab.TextColor3 = Color3.new(1,1,1)
CombatTab.Parent = TabFrame
local Corner3 = Instance.new("UICorner")
Corner3.CornerRadius = UDim.new(0, 5)
Corner3.Parent = CombatTab

-- Frames (These positions look correct, assuming TitleBar is 60px)
local PlayerFrame = Instance.new("ScrollingFrame")
PlayerFrame.Size = UDim2.new(1, 0, 1, -85)
PlayerFrame.Position = UDim2.new(0, 0, 0, 60)
PlayerFrame.BackgroundTransparency = 1
PlayerFrame.Parent = MainFrame
PlayerFrame.CanvasSize = UDim2.new( 0, 0, 0, 310)

local TargetFrame = Instance.new("ScrollingFrame")
TargetFrame.Size = PlayerFrame.Size
TargetFrame.Position = PlayerFrame.Position
TargetFrame.BackgroundTransparency = 1
TargetFrame.Visible = false
TargetFrame.Parent = MainFrame
TargetFrame.CanvasSize = UDim2.new( 0, 0, 0, 10)

local CombatFrame = Instance.new("ScrollingFrame")
CombatFrame.Size = TargetFrame.Size
CombatFrame.Position = TargetFrame.Position
CombatFrame.BackgroundTransparency = 1
CombatFrame.Visible = false
CombatFrame.Parent = MainFrame
CombatFrame.CanvasSize = UDim2.new( 0, 0, 0, 50)

-- Tab logic
PlayerTab.MouseButton1Click:Connect(function()
    PlayerFrame.Visible = true
    TargetFrame.Visible = false
    CombatFrame.Visible = false
    PlayerTab.BackgroundColor3 = Color3.fromRGB(70,70,70)
    PlayerTab.BackgroundTransparency = 0
    TargetTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
    TargetTab.BackgroundTransparency = 1
    CombatTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
    CombatTab.BackgroundTransparency = 1
end)
TargetTab.MouseButton1Click:Connect(function()
    PlayerFrame.Visible = false
    TargetFrame.Visible = true
    CombatFrame.Visible = false
    PlayerTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
    PlayerTab.BackgroundTransparency = 1
    TargetTab.BackgroundColor3 = Color3.fromRGB(70,70,70)
    TargetTab.BackgroundTransparency = 0
    CombatTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
    CombatTab.BackgroundTransparency = 1
end)
CombatTab.MouseButton1Click:Connect(function()
    PlayerFrame.Visible = false
    TargetFrame.Visible = false
    CombatFrame.Visible = true
    PlayerTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
    PlayerTab.BackgroundTransparency = 1
    TargetTab.BackgroundColor3 = Color3.fromRGB(40,40,40)
    TargetTab.BackgroundTransparency = 1
    CombatTab.BackgroundColor3 = Color3.fromRGB(70,70,70)
    CombatTab.BackgroundTransparency = 0
end)

-- Drag
local dragging = false
local dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- === PLAYER MENU ===
local function makeLabel(text, y)
	local l = Instance.new("TextLabel")
	l.Text = text
	l.Size = UDim2.new(0,120,0,30)
	l.Position = UDim2.new(0,10,0,y)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.new(1,1,1)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = PlayerFrame
	return l
end

-- WalkSpeed
local walkBox = Instance.new("TextBox")
walkBox.Size = UDim2.new(0,60,0,30)
walkBox.Position = UDim2.new(0,230,0,10)
walkBox.Text = tostring(_G.PlayerSettings.walkSpeed)
walkBox.ClearTextOnFocus = false
walkBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
walkBox.TextColor3 = Color3.new(1,1,1)
walkBox.Parent = PlayerFrame

local walkToggle = Instance.new("TextButton")
walkToggle.Size = UDim2.new(0,100,0,30)
walkToggle.Position = UDim2.new(0,10,0,10)
walkToggle.Text = _G.PlayerSettings.walkEnabled and "WalkSpeed: ON" or "WalkSpeed: OFF"
walkToggle.BackgroundColor3 = _G.PlayerSettings.walkEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
walkToggle.TextColor3 = Color3.new(1,1,1)
walkToggle.Parent = PlayerFrame

-- JumpPower
local jumpBox = Instance.new("TextBox")
jumpBox.Size = UDim2.new(0,60,0,30)
jumpBox.Position = UDim2.new(0,230,0,48)
jumpBox.Text = tostring(_G.PlayerSettings.jumpPower)
jumpBox.ClearTextOnFocus = false
jumpBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
jumpBox.TextColor3 = Color3.new(1,1,1)
jumpBox.Parent = PlayerFrame

local jumpToggle = Instance.new("TextButton")
jumpToggle.Size = UDim2.new(0,100,0,30)
jumpToggle.Position = UDim2.new(0,10,0,48)
jumpToggle.Text = _G.PlayerSettings.jumpEnabled and "JumpPower: ON" or "JumpPower: OFF"
jumpToggle.BackgroundColor3 = _G.PlayerSettings.jumpEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
jumpToggle.TextColor3 = Color3.new(1,1,1)
jumpToggle.Parent = PlayerFrame

-- Fly
local flyBox = Instance.new("TextBox")
flyBox.Size = UDim2.new(0,60,0,30)
flyBox.Position = UDim2.new(0,230,0,86)
flyBox.Text = tostring(_G.PlayerSettings.flySpeed)
flyBox.ClearTextOnFocus = false
flyBox.BackgroundColor3 = Color3.fromRGB(60,60,60)
flyBox.TextColor3 = Color3.new(1,1,1)
flyBox.Parent = PlayerFrame

local flyToggle = Instance.new("TextButton")
flyToggle.Size = UDim2.new(0,100,0,30)
flyToggle.Position = UDim2.new(0,10,0,86)
flyToggle.Text = _G.PlayerSettings.flyEnabled and "Fly: ON" or "Fly: OFF"
flyToggle.BackgroundColor3 = _G.PlayerSettings.flyEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
flyToggle.TextColor3 = Color3.new(1,1,1)
flyToggle.Parent = PlayerFrame

-- Noclip
local noclipToggle = Instance.new("TextButton")
noclipToggle.Size = UDim2.new(0,100,0,30)
noclipToggle.Position = UDim2.new(0,10,0,124)
noclipToggle.Text = _G.PlayerSettings.noclipEnabled and "Noclip: ON" or "Noclip: OFF"
noclipToggle.BackgroundColor3 = _G.PlayerSettings.noclipEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
noclipToggle.TextColor3 = Color3.new(1,1,1)
noclipToggle.Parent = PlayerFrame


-- Dependencies (Define these at the very top of your full script)

-- --- CORE VARIABLES ---
local grabLoopConnection = nil 
local SelectedTargets = {} -- Store multiple selected players

local BUTTONS_Y = 40 + 180 + 10 

-- --- TARGET MENU GUI ---
local TargetNameLabel = makeLabel("Targets: None", 10, TargetFrame)
TargetNameLabel.Parent = TargetFrame

-- Player List Scrolling Frame
local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Name = "PlayerListFrame"
PlayerListFrame.Size = UDim2.new(1, -20, 0, 180)
PlayerListFrame.Position = UDim2.new(0, 10, 0, 40)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PlayerListFrame.Parent = TargetFrame

-- List Layout for automatic positioning
local ListLayout = Instance.new("UIListLayout")
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
ListLayout.Padding = UDim.new(0, 2)
ListLayout.Parent = PlayerListFrame


-- ⭐ NEW SELECT ALL BUTTON UI ⭐
local SelectAllBtn = Instance.new("TextButton")
SelectAllBtn.Size = UDim2.new(1, -20, 0, 30)
SelectAllBtn.Position = UDim2.new(0, 10, 0, BUTTONS_Y + 30) 
SelectAllBtn.Text = "SELECT ALL"
SelectAllBtn.Font = Enum.Font.SourceSansBold
SelectAllBtn.TextSize = 16
SelectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
SelectAllBtn.TextColor3 = Color3.new(1, 1, 1)
SelectAllBtn.Parent = TargetFrame

-- ⭐ NEW kill BUTTON UI ⭐
local KillTargetBtn = Instance.new("TextButton")
KillTargetBtn.Size = UDim2.new(1, -20, 0, 30)
KillTargetBtn.Position = UDim2.new(0, 10, 0, BUTTONS_Y + 60) 
KillTargetBtn.Text = "KILL (First) TARGET: OFF"
KillTargetBtn.Font = Enum.Font.SourceSansBold
KillTargetBtn.TextSize = 16
KillTargetBtn.BackgroundColor3 = Color3.fromRGB(200,0,0)
KillTargetBtn.TextColor3 = Color3.new(1, 1, 1)
KillTargetBtn.Parent = TargetFrame


-- ⭐ NEW TELEPORT LOGIC ⭐
local function KillTarget()
    if #SelectedTargets == 0 then
        warn("No target selected to teleport to.")
        return
    end

    local targetPlayer = SelectedTargets[1] -- Teleport to the first player in the list
    local targetChar = targetPlayer.Character
    
    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
        local myChar = player.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if myHRP then
            local targetHRP = targetChar.HumanoidRootPart
            local targetPosition = targetHRP.CFrame.Position
            myHRP.CFrame = CFrame.new(targetPosition) * CFrame.new(0, -12, 0)
        end
    end
end

KillTargetBtn.MouseButton1Click:Connect(function()
	killtargetEnabled = not killtargetEnabled
	KillTargetBtn.Text = killtargetEnabled and "KILL (First) TARGET: ON" or "KILL (First) TARGET: OFF"
	KillTargetBtn.BackgroundColor3 = killtargetEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

    if killtargetEnabled then
        workspace.Gravity = 0
    else
        workspace.Gravity = 196.2
    end
	while killtargetEnabled do
        KillTarget()
        wait(0.01)
    end
end)


-- ⭐ CONNECT THE BUTTON ⭐
KillTargetBtn.MouseButton1Click:Connect(KillTarget)



-- ⭐ NEW TELEPORT BUTTON UI ⭐
local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Size = UDim2.new(1, -20, 0, 30)
TeleportBtn.Position = UDim2.new(0, 10, 0, BUTTONS_Y) 
TeleportBtn.Text = "Teleport to (First) TARGET"
TeleportBtn.Font = Enum.Font.SourceSansBold
TeleportBtn.TextSize = 16
TeleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
TeleportBtn.TextColor3 = Color3.new(1, 1, 1)
TeleportBtn.Parent = TargetFrame

-- ⭐ NEW TELEPORT LOGIC ⭐
local function teleportToTargets()
    if #SelectedTargets == 0 then
        warn("No target selected to teleport to.")
        return
    end

    local targetPlayer = SelectedTargets[1] -- Teleport to the first player in the list
    local targetChar = targetPlayer.Character
    
    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
        local myChar = player.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        if myHRP then
            local targetHRP = targetChar.HumanoidRootPart
            local targetPosition = targetHRP.CFrame.Position

            myHRP.CFrame = CFrame.new(targetPosition) * CFrame.new(0, 5, 0) 
        end
    end
end

-- ⭐ CONNECT THE BUTTON ⭐
TeleportBtn.MouseButton1Click:Connect(teleportToTargets)



-- --- GRAB LOGIC FUNCTIONS ---
local function stopBodyGrab()
    if grabLoopConnection then
        grabLoopConnection:Disconnect()
        grabLoopConnection = nil
    end
    
    -- Cleanup the grabbed limbs (only LeftFoot is necessary with this logic)
    for _, targetPlayer in pairs(SelectedTargets) do
        local targetChar = targetPlayer.Character
        if targetChar then
            local limb = targetChar:FindFirstChild("LeftFoot")
            if limb and limb:IsA("BasePart") then
                limb.CFrame = CFrame.new(0, 9999, 0)
            end
        end
    end
end

local function startBodyGrab()
    -- Ensure only one loop runs at a time
    if grabLoopConnection then return end 

    local myHRP = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if not myHRP then 
        warn("Local player HRP missing, stopping grab.")
        stopBodyGrab()
        return 
    end
    
    -- FIX: Assign the single connection to the global variable
    grabLoopConnection = RunService.RenderStepped:Connect(function()
        
        local currentMyHRP = player.Character and player.Character.HumanoidRootPart
        local targetsToRemove = {}

        if not currentMyHRP then
            stopBodyGrab()
            return
        end

        -- Use a numeric index 'i' to guarantee a unique offset for each player.
        for i, targetPlayer in pairs(SelectedTargets) do 
            local targetChar = targetPlayer.Character
            local PickedFoot = targetChar and targetChar:FindFirstChild("LeftFoot")
            
            if targetChar and PickedFoot and PickedFoot:IsA("BasePart") then
                
                -- FIX: Use CFrame to prevent parts from clipping into the ground
                local targetCFrame = currentMyHRP.CFrame * CFrame.new(0, 0, -4) 

                -- Your core teleport logic, applied to the LeftFoot
                PickedFoot:BreakJoints()
                PickedFoot.CanCollide = false
                -- FIX: Use CFrame instead of Position for stable teleporting, and apply offset
                PickedFoot.CFrame = targetCFrame 
                PickedFoot.Velocity = Vector3.new(0,0,0)
            end
        end
        -- Clean up dead/missing targets
        for _, invalidTarget in ipairs(targetsToRemove) do
            local index = table.find(SelectedTargets, invalidTarget)
            if index then
                table.remove(SelectedTargets, index)
            end
        end
        
        TargetNameLabel.Text = "Targets: " .. #SelectedTargets
        
        -- Auto-stop logic
        if #SelectedTargets == 0 then 
            TargetNameLabel.Text = "Targets: None (Grab inactive)"
            stopBodyGrab() 
        end
    end)
end


-- --- TARGET SELECTION LOGIC (PLAYER BUTTONS) ---
local function isSelected(playerObject)
    return table.find(SelectedTargets, playerObject) ~= nil
end

local function toggleTarget(playerObject)
    local indexToRemove = table.find(SelectedTargets, playerObject)

    if indexToRemove then
        -- DESELECT: Remove from table
        table.remove(SelectedTargets, indexToRemove)
    else
        -- SELECT: Add to table
        table.insert(SelectedTargets, playerObject)
    end
    
    TargetNameLabel.Text = "Targets: " .. #SelectedTargets
    
    -- **AUTOPLAY LOGIC: Controls the loop based on selection count**
    if #SelectedTargets > 0 and grabLoopConnection == nil then
        -- Start the loop immediately if the first player is selected
        startBodyGrab()
    elseif #SelectedTargets == 0 and grabLoopConnection ~= nil then
        -- Stop the loop immediately if the last player is deselected
        stopBodyGrab()
    end
end

local function createPlayerButton(targetPlayer, index)
    local btn = Instance.new("TextButton")
    btn.Name = targetPlayer.Name

    
    local plr = game.Players.LocalPlayer
    if plr:IsFriendsWith(targetPlayer.UserId) then
        btn.Text = "🚨 " .. targetPlayer.Name .. " 🚨"
    else
        btn.Text = targetPlayer.Name
    end

    
    btn.Size = UDim2.new(1, 0, 0, 20)
    btn.BackgroundTransparency = 0
    
    -- CRITICAL FIX: Ensure the button's initial color reflects the *current* table state
    local isCurrentlySelected = isSelected(targetPlayer)
    btn.BackgroundColor3 = isCurrentlySelected and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(60, 60, 60)

    
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Parent = PlayerListFrame

    btn.MouseButton1Click:Connect(function()
        toggleTarget(targetPlayer)
        local isNowSelected = isSelected(targetPlayer)
        btn.BackgroundColor3 = isNowSelected and Color3.fromRGB(0, 100, 200) or Color3.fromRGB(60, 60, 60)
    end)
end

local function refreshPlayerList()
    -- Clear old buttons
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local yOffset = 0
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            createPlayerButton(p, i)
            yOffset = yOffset + 22
        end
    end
    --PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    PlayerListFrame.Size = UDim2.new(1, -20, 0, yOffset)
    TeleportBtn.Position = UDim2.new(0, 10, 0, yOffset + 50)
    SelectAllBtn.Position = UDim2.new(0, 10, 0, yOffset + 80)
	TargetFrame.CanvasSize = UDim2.new( 0, 0, 0, yOffset + 140)

    KillTargetBtn.Position = UDim2.new(0, 10, 0, yOffset + 110) 
end

refreshPlayerList()




-- --- SELECT ALL LOGIC ---
local function toggleSelectAll()
    isSelectAllActive = not isSelectAllActive

    if isSelectAllActive then
        -- SELECT ALL: Clear current list and add ALL players
        SelectedTargets = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                table.insert(SelectedTargets, p)
            end
        end
        
        SelectAllBtn.Text = "DESELECT ALL"
        SelectAllBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red to show it's active
        
        if grabLoopConnection == nil then
            startBodyGrab()
        end
    else
        -- DESELECT ALL: Clear the list
        SelectedTargets = {}
        
        SelectAllBtn.Text = "SELECT ALL"
        SelectAllBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Back to blue
        
        if grabLoopConnection ~= nil then
            stopBodyGrab()
            TargetNameLabel.Text = "Targets: 0"
        end
    end

    -- Refresh the list to update button colors
    refreshPlayerList()

end

-- ⭐ CONNECT THE SELECT ALL BUTTON ⭐
SelectAllBtn.MouseButton1Click:Connect(toggleSelectAll)

-- --- EVENT-BASED REFRESH LOGIC (THE FIX!) ---
local char = player.Character
function getRoot(char)
	local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
	return rootPart
end
Players.PlayerAdded:Connect(function(newPlayer)
    if isSelectAllActive then
        repeat wait(1) until newPlayer.Character and getRoot(newPlayer.Character)
        if table.find(SelectedTargets, newPlayer) == nil then
            table.insert(SelectedTargets, newPlayer)
        end

        if grabLoopConnection == nil then
            startBodyGrab() -- Start the loop, now guaranteed to have character parts
        end
    end
    
    -- Rebuild the UI to display the new player and their selection status
    refreshPlayerList() 

    
end)


-- Refresh the list when a player leaves
Players.PlayerRemoving:Connect(function(targetPlayer)
    local indexToRemove = table.find(SelectedTargets, targetPlayer)
    if indexToRemove then
        table.remove(SelectedTargets, indexToRemove)
    end
    
    refreshPlayerList()
end)



-- === Core systems ===
local BG, BV, flyKeyDownConn, flyKeyUpConn


local function stopFly()
	hum.PlatformStand = false
	if BG then BG:Destroy() BG = nil end
	if BV then BV:Destroy() BV = nil end
	if flyKeyDownConn then flyKeyDownConn:Disconnect() flyKeyDownConn = nil end
	if flyKeyUpConn then flyKeyUpConn:Disconnect() flyKeyUpConn = nil end
end

local function startFly()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    BG = Instance.new("BodyGyro", hrp)
    BV = Instance.new("BodyVelocity", hrp)
    BG.P = 9e4
    BG.MaxTorque = Vector3.new(9e9,9e9,9e9)
    BV.MaxForce = Vector3.new(9e9,9e9,9e9)
    BV.Velocity = Vector3.new(0,0,0)

    local CONTROL = {F=0,B=0,L=0,R=0,Q=0,E=0}

    flyKeyDownConn = mouse.KeyDown:Connect(function(k)
        local key = tostring(k):lower()
        local speed = tonumber(flyBox.Text) or _G.PlayerSettings.flySpeed or 16
        if key == "w" then CONTROL.F = speed
        elseif key == "s" then CONTROL.B = -speed
        elseif key == "a" then CONTROL.L = -speed
        elseif key == "d" then CONTROL.R = speed
        elseif key == "e" then CONTROL.Q = speed*2
        elseif key == "q" then CONTROL.E = -speed*2
        end
    end)
    flyKeyUpConn = mouse.KeyUp:Connect(function(k)
        local key = tostring(k):lower()
        if key == "w" then CONTROL.F = 0
        elseif key == "s" then CONTROL.B = 0
        elseif key == "a" then CONTROL.L = 0
        elseif key == "d" then CONTROL.R = 0
        elseif key == "e" then CONTROL.Q = 0
        elseif key == "q" then CONTROL.E = 0
        end
    end)

    task.spawn(function()
        while _G.PlayerSettings.flyEnabled and hrp and hrp.Parent do
            task.wait()
            hum.PlatformStand = true
            local speed = tonumber(flyBox.Text) or _G.PlayerSettings.flySpeed or 16
            if CONTROL.F+CONTROL.B ~= 0 or CONTROL.L+CONTROL.R ~= 0 or CONTROL.Q+CONTROL.E ~= 0 then
                BV.Velocity = ((workspace.CurrentCamera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
                    ((workspace.CurrentCamera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E)*0.2, 0)).Position -
                    workspace.CurrentCamera.CFrame.Position)) * speed
            else
                BV.Velocity = Vector3.new(0,0,0)
            end
            BG.CFrame = workspace.CurrentCamera.CFrame
        end
        if hum then hum.PlatformStand = false end
        if BG then BG:Destroy() end
        if BV then BV:Destroy() end
    end)
end

-- Noclip
local originalCanCollide = {}
local function setNoClip(state)
	local char = player.Character
	if not char then return end
	if state then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				originalCanCollide[part] = part.CanCollide
				part.CanCollide = false
			end
		end
		if _G.PlayerLoops.NoclipConn then _G.PlayerLoops.NoclipConn:Disconnect() end
		_G.PlayerLoops.NoclipConn = RunService.Stepped:Connect(function()
			for part in pairs(originalCanCollide) do
				if part and part.Parent then part.CanCollide = false end
			end
		end)
	else
		if _G.PlayerLoops.NoclipConn then _G.PlayerLoops.NoclipConn:Disconnect() end
		for part, canCollide in pairs(originalCanCollide) do
			if part and part.Parent then part.CanCollide = canCollide end
		end
		originalCanCollide = {}
	end
end

-- === Humanoid updater ===
local currentHumanoid
local function getHumanoid()
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	currentHumanoid = hum
	return hum
end

local function applyHumanoidValues(hum)
	if not hum then return end
	local ws = tonumber(walkBox.Text) or _G.PlayerSettings.walkSpeed
	local jp = tonumber(jumpBox.Text) or _G.PlayerSettings.jumpPower
	if _G.PlayerSettings.walkEnabled then
		hum.WalkSpeed = ws
	end
	if _G.PlayerSettings.jumpEnabled then
		hum.JumpPower = jp
	end
	hum.UseJumpPower = true
end

_G.PlayerLoops.RenderConn = RunService.RenderStepped:Connect(function()
	local hum = getHumanoid()
	applyHumanoidValues(hum)
end)

-- Respawn persistence
player.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid")
	task.wait(0.2)
	if _G.PlayerSettings.flyEnabled then startFly() end
	if _G.PlayerSettings.noclipEnabled then setNoClip(true) end
end)

-- === GUI Interactions ===
walkToggle.MouseButton1Click:Connect(function()
	_G.PlayerSettings.walkEnabled = not _G.PlayerSettings.walkEnabled
	walkToggle.Text = _G.PlayerSettings.walkEnabled and "WalkSpeed: ON" or "WalkSpeed: OFF"
	walkToggle.BackgroundColor3 = _G.PlayerSettings.walkEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
	if not _G.PlayerSettings.walkEnabled then
		player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	end

end)
walkBox.FocusLost:Connect(function()
	local v = tonumber(walkBox.Text) or 22
	_G.PlayerSettings.walkSpeed = v
end)

jumpToggle.MouseButton1Click:Connect(function()
	_G.PlayerSettings.jumpEnabled = not _G.PlayerSettings.jumpEnabled
	jumpToggle.Text = _G.PlayerSettings.jumpEnabled and "JumpPower: ON" or "JumpPower: OFF"
	jumpToggle.BackgroundColor3 = _G.PlayerSettings.jumpEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
	if not _G.PlayerSettings.jumpEnabled then
		player.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
	end
end)
jumpBox.FocusLost:Connect(function()
	local v = tonumber(jumpBox.Text) or 50
	_G.PlayerSettings.jumpPower = v
end)

flyToggle.MouseButton1Click:Connect(function()
	_G.PlayerSettings.flyEnabled = not _G.PlayerSettings.flyEnabled
	flyToggle.Text = _G.PlayerSettings.flyEnabled and "Fly: ON" or "Fly: OFF"
	flyToggle.BackgroundColor3 = _G.PlayerSettings.flyEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
	if _G.PlayerSettings.flyEnabled then startFly() else stopFly() end
end)
flyBox.FocusLost:Connect(function()
	local v = tonumber(flyBox.Text) or 16
	_G.PlayerSettings.flySpeed = v
end)

noclipToggle.MouseButton1Click:Connect(function()
	_G.PlayerSettings.noclipEnabled = not _G.PlayerSettings.noclipEnabled
	noclipToggle.Text = _G.PlayerSettings.noclipEnabled and "Noclip: ON" or "Noclip: OFF"
	noclipToggle.BackgroundColor3 = _G.PlayerSettings.noclipEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
	setNoClip(_G.PlayerSettings.noclipEnabled)
end)


-- Hit Actions toggle

--makeLabel("Hit Actions:", 162)  -- adjust the Y position
local hitToggle = Instance.new("TextButton")
hitToggle.Size = UDim2.new(0,100,0,30)
hitToggle.Position = UDim2.new(0,10,0,10)
hitToggle.Text = _G.PlayerSettings.hitActionsEnabled and "Hit Actions: ON" or "Hit Actions: OFF"
hitToggle.BackgroundColor3 = _G.PlayerSettings.hitActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
hitToggle.TextColor3 = Color3.new(1,1,1)
hitToggle.Parent = CombatFrame

hitToggle.MouseButton1Click:Connect(function()
    _G.PlayerSettings.hitActionsEnabled = not _G.PlayerSettings.hitActionsEnabled
    hitToggle.Text = _G.PlayerSettings.hitActionsEnabled and "Hit Actions: ON" or "Hit Actions: OFF"
    hitToggle.BackgroundColor3 = _G.PlayerSettings.hitActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
end)

-- Table of RemoteEvents
local hitEvents = {

    game:GetService("ReplicatedStorage").Modules.Net["RE/ToiletWeaponActivated"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/TrashbagHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/PipeActivated"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/stopsignalHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/trashbinDisguiseHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/mopHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/PoolNoodleActivated"],

    game:GetService("ReplicatedStorage"):WaitForChild("PUNCHEVENT"),
    game:GetService("ReplicatedStorage").Modules.Net["RE/sprayRemote"],

    game:GetService("ReplicatedStorage").Modules.Net["RE/BeachShovelHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/panHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/taserRemote"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/flamethrowerFire"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/BatonHit"],

    game:GetService("ReplicatedStorage").Modules.Net["RE/pinkStopSignalHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/baseballBatHit"],
	game:GetService("ReplicatedStorage").Modules.Net["RE/StickActivated"],
    

    game:GetService("ReplicatedStorage").Modules.Net["RE/CrowbarHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/GoldenFlameThrowerFire"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/GoldenTaserRemote"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/goldStopSignalHit"],

    game:GetService("ReplicatedStorage").Modules.Net["RE/sledgehammer"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/PurseActivated"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/PinkPanHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/ShieldHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/SpatulaHit"],


    game:GetService("ReplicatedStorage").Modules.Net["RE/chefKnifeHit"],
    game:GetService("ReplicatedStorage").Modules.Net["RE/slasherClawsHit"],

}

local p = game.Players.LocalPlayer
-- ----------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 and _G.PlayerSettings.hitActionsEnabled then
        for _, ev in ipairs(hitEvents) do
            if ev then
                ev:FireServer(1)
            end
        end
    end
end)


-- auto heal toggle

local autohealToggle = Instance.new("TextButton")
autohealToggle.Size = UDim2.new(0,100,0,30)
autohealToggle.Position = UDim2.new(0,10,0,48)
autohealToggle.Text = _G.PlayerSettings.autohealActionsEnabled and "Auto heal: ON" or "Auto heal: OFF"
autohealToggle.BackgroundColor3 = _G.PlayerSettings.autohealActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
autohealToggle.TextColor3 = Color3.new(1,1,1)
autohealToggle.Parent = CombatFrame

-- Assume p is defined as local p = game.Players.LocalPlayer


local HEALING_ITEMS = {
    "Chicken Bucket",
    "ChickenNugget",
    "Chispys",
    "Fires",
    "Grilled Chicken",
    "Ice Cream",
    "Poyo",
    "Super Pretzels",
    "TacoBall",
}


local function TryBuyItem(itemName, itemModelName)
    local char = p.Character
    if not char or not char:FindFirstChild("Head") or not char:FindFirstChild("HumanoidRootPart") then
        return false -- Cannot buy if character is missing
    end

    local itemInBackpack = p.Backpack:FindFirstChild(itemName)
    local itemEquipped = char:FindFirstChild(itemName)

    -- If the item is already owned, do nothing.
    if itemInBackpack or itemEquipped then
        return false
    end
    
    -- Find the item model in the workspace
    local Item = workspace.Cash:FindFirstChild(itemModelName)
    local prompt = Item and Item:FindFirstChildOfClass("ProximityPrompt")
    
    if not Item or not prompt then
        return false -- Item or prompt not found
    end

    -- 1. Setup Environment
    prompt.MaxActivationDistance = 10000
    prompt.RequiresLineOfSight = false 

    local OldPos = char.Head.CFrame
    local OldPos2 = Item.CFrame
    local cambefore = game.Workspace.CurrentCamera.CFrame

    -- 2. Start the buying spam loop in a new thread
    spawn(function()
        -- Loop continues AS LONG AS the item is NOT found.
        -- Note: The item name is passed dynamically now.
        while not (p.Backpack:FindFirstChild(itemName) or (char and char:FindFirstChild(itemName))) do
            -- Safety check: If the player is suddenly uncharried, stop the loop
            if not char or not char.HumanoidRootPart then break end

            char.HumanoidRootPart.CFrame = OldPos2 + Vector3.new(0, 5, 0)
            game.Workspace.CurrentCamera.CFrame = CFrame.lookAt(game.Workspace.CurrentCamera.CFrame.Position, Item.Position)
            prompt:InputHoldBegin()
            wait(0.01)
            prompt:InputHoldEnd()
            wait()
        end
    end)
    
    -- 3. Wait for the item to appear in the inventory/character (blocking the main AutoHealLoop thread)
    repeat
        wait()
    until p.Backpack:FindFirstChild(itemName) or (char and char:FindFirstChild(itemName))
    
    -- 4. Cleanup and Teleport Back
    wait(0.01)

    spawn(function()
        for i=1,1 do -- Set back to 1, since the item is confirmed to be bought
            wait(0.01)
            char.HumanoidRootPart.CFrame = OldPos
            game.Workspace.CurrentCamera.CFrame = cambefore

            prompt.MaxActivationDistance = 5
            prompt.RequiresLineOfSight = true 
        end
    end)

    return true -- Successfully bought the item
end

local function AutoHealLoop()
    while _G.PlayerSettings.autohealActionsEnabled and task.wait(0.1) do -- Use task.wait in the condition


        -- Safe character access
        local char = p.Character
        --if not char then continue end

        if not char or not char:FindFirstChildOfClass("Humanoid") or not p:FindFirstChild("Stamina") then
            continue -- If anything is missing, skip this loop iteration and wait for the next 0.1s
        end


        local BeingCarriedValue = char:FindFirstChild("BeingCarried")
        
        if not BeingCarriedValue then
            if TryBuyItem("Recovery Drink", "comprarRecovery") then
                continue -- Item bought, skip to next 0.2s iteration
            end

            if TryBuyItem("Chicken Bucket", "comprarChickenBucket") then
                continue
            end

            if TryBuyItem("ChickenNugget", "comprarChickenNugget") then
                continue
            end

            if TryBuyItem("Chispys", "comprarChispys") then
				continue
            end

            if TryBuyItem("Fires", "comprarFires") then
				continue
            end

            if TryBuyItem("Grilled Chicken", "comprarGrilledChicken") then
                continue
            end
            if TryBuyItem("Ice Cream", "comprarIceCream") then
                continue
            end
            if TryBuyItem("Poyo", "comprarPoyo") then
                continue
            end
            if TryBuyItem("Super Pretzels", "comprarSuperPretzels") then
                continue
            end
            if TryBuyItem("TacoBall", "comprarTacoBall") then
                continue
            end

        end

		if p:FindFirstChild("Stamina").Value < 100 then
			if p.Backpack:FindFirstChild("Recovery Drink") then
    			p.Backpack:FindFirstChild("Recovery Drink"):FindFirstChild("Handle"):FindFirstChild("RemoteEvent"):FireServer(1)
			end
		end
        -- ... (inside AutoHealLoop, under the health check)
        local Human = p.Character:FindFirstChildOfClass("Humanoid")
        if p.Character and Human.Health < Human.MaxHealth then
            -- Loop through the list of preferred items
            for _, itemName in ipairs(HEALING_ITEMS) do
                local itemInBackpack = p.Backpack:FindFirstChild(itemName)

                if itemInBackpack then
                    -- Item found! Use WaitForChild to ensure Handle and RemoteEvent are loaded.
                    -- Using a very small timeout (e.g., 0.5 seconds) prevents infinite yielding

                    local handle = itemInBackpack:WaitForChild("Handle", 0.5)
                    if handle then
                        local remoteEvent = handle:WaitForChild("RemoteEvent", 0.5) 

                        if remoteEvent and remoteEvent:IsA("RemoteEvent") then
                            local Human = p.Character:FindFirstChildOfClass("Humanoid")
                            if p.Character and Human.Health < Human.MaxHealth then
                                remoteEvent:FireServer(1)




		                        if p:FindFirstChild("Stamina").Value < 100 then
		                        	if p.Backpack:FindFirstChild("Recovery Drink") then
    	                        		p.Backpack:FindFirstChild("Recovery Drink"):FindFirstChild("Handle"):FindFirstChild("RemoteEvent"):FireServer(1)
		                        	end
		                        end

                                if p.Character and Human.Health > 80 then
                                    wait(0.5)
                                end
                            else
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end


autohealToggle.MouseButton1Click:Connect(function()
    _G.PlayerSettings.autohealActionsEnabled = not _G.PlayerSettings.autohealActionsEnabled
    autohealToggle.Text = _G.PlayerSettings.autohealActionsEnabled and "Auto heal: ON" or "Auto heal: OFF"
    autohealToggle.BackgroundColor3 = _G.PlayerSettings.autohealActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

    if _G.PlayerSettings.autohealActionsEnabled then
        -- Start the loop in a new thread only when turning ON
        task.spawn(AutoHealLoop)
    end

end)



-- spin the wheel toggle

local spinToggle = Instance.new("TextButton")
spinToggle.Size = UDim2.new(0,100,0,30)
spinToggle.Position = UDim2.new(0,10,0,238)
spinToggle.Text = _G.PlayerSettings.spinActionsEnabled and "Auto Spin: ON" or "Auto Spin: OFF"
spinToggle.BackgroundColor3 = _G.PlayerSettings.spinActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
spinToggle.TextColor3 = Color3.new(1,1,1)
spinToggle.Parent = PlayerFrame


local FreeSpinRemote = game:GetService("ReplicatedStorage").Modules.Net["RE/HourlySpin/FreeSpin"]
local spinLoopThread = nil

-- === 1. Dedicated Function to Manage the Loop ===
local function manageAutoSpin()
    if not _G.PlayerSettings.spinActionsEnabled and spinLoopThread then
        spinLoopThread = nil
        return
    end
    if _G.PlayerSettings.spinActionsEnabled and not spinLoopThread then
        spinLoopThread = task.spawn(function()
            while _G.PlayerSettings.spinActionsEnabled do
                -- Use the cached variable instead of the long path
                FreeSpinRemote:FireServer(1) 
                task.wait(250)
            end
            spinLoopThread = nil
        end)
    end
end
spinToggle.MouseButton1Click:Connect(function()
    _G.PlayerSettings.spinActionsEnabled = not _G.PlayerSettings.spinActionsEnabled
    spinToggle.Text = _G.PlayerSettings.spinActionsEnabled and "Auto Spin: ON" or "Auto Spin: OFF"
    spinToggle.BackgroundColor3 = _G.PlayerSettings.spinActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
    manageAutoSpin()
end)

-- === 3. Persistence: Check setting on script load ===
if _G.PlayerSettings.spinActionsEnabled then
    manageAutoSpin()
end


-- ##ESP toggle##
local espActionsEnabled = true -- controlled by GUI toggle

local cloneref = cloneref or function(o) return o end
COREGUI = cloneref(game:GetService("CoreGui"))

-- GUI Element setup
local espToggle = Instance.new("TextButton")
espToggle.Size = UDim2.new(0,100,0,30)
espToggle.Position = UDim2.new(0,10,0,162)
espToggle.Text = espActionsEnabled and "Esp: ON" or "Esp: OFF"
espToggle.BackgroundColor3 = espActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
espToggle.TextColor3 = Color3.new(1,1,1)
-- Parent must exist when the script runs, assuming 'PlayerFrame' is defined elsewhere
espToggle.Parent = PlayerFrame 


-- FIX 3: Corrected logic for starting/stopping ESP
espToggle.MouseButton1Click:Connect(function()
    espActionsEnabled = not espActionsEnabled
    espToggle.Text = espActionsEnabled and "Esp: ON" or "Esp: OFF"
    espToggle.BackgroundColor3 = espActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
    
    if espActionsEnabled then
        for i,v in pairs(Players:GetPlayers()) do
            if v.Name ~= player.Name then
                ESP(v)
            end
        end
    else
        -- TURN OFF ESP: Destroy all visuals
        for i,c in pairs(COREGUI:GetChildren()) do
            if string.sub(c.Name, -4) == '_ESP' then
                c:Destroy()
            end
        end
    end
end)

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function ESP(plr)
    local Playercheck = game.Players.LocalPlayer
	task.spawn(function()
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == plr.Name..'_ESP' then
				v:Destroy()
			end
		end
		wait()
		if plr.Character and plr.Name ~= Players.LocalPlayer.Name and not COREGUI:FindFirstChild(plr.Name..'_ESP') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = plr.Name..'_ESP'
			ESPholder.Parent = COREGUI
			repeat wait(1) until plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
			if plr.Character and plr.Character:FindFirstChild('Head') then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")
				BillboardGui.Adornee = plr.Character.Head
				BillboardGui.Name = plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0, 100, 0, 150)
				BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
				BillboardGui.AlwaysOnTop = true
				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0, 0, 0, -50)
				TextLabel.Size = UDim2.new(0, 100, 0, 100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 25
                TextLabel.TextColor3 = Color3.new(1, 1, 1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.Text = 'Name: '..plr.Name
				TextLabel.ZIndex = 10
				local espLoopFunc
                local teamChange
				local addedFunc
				addedFunc = plr.CharacterAdded:Connect(function()
					if espActionsEnabled then
						espLoopFunc:Disconnect()
						ESPholder:Destroy()
                        teamChange:Disconnect()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr)
						addedFunc:Disconnect()
					else
                        teamChange:Disconnect()
						addedFunc:Disconnect()
					end
				end)


				teamChange = plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
					if espActionsEnabled then
						espLoopFunc:Disconnect()
						addedFunc:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid")
						ESP(plr)
						teamChange:Disconnect()
					else
                        teamChange:Disconnect()
					end
				end)

				local function espLoop()
					if COREGUI:FindFirstChild(plr.Name..'_ESP') then
						if plr.Character and getRoot(plr.Character) and plr.Character:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
							local pos = math.floor((getRoot(Players.LocalPlayer.Character).Position - getRoot(plr.Character).Position).magnitude)
                            if plr:IsFriendsWith(Playercheck.UserId) then
							    TextLabel.Text = '🚨'..plr.Name..'🚨 | '..round(plr.Character:FindFirstChildOfClass('Humanoid').Health, 1)..'💗'..plr.jaladaDePeloCharge.Value..'👩‍🦰'..plr.Stamina.Value..'🩸'
                            else
							    TextLabel.Text = ''..plr.Name..' | '..round(plr.Character:FindFirstChildOfClass('Humanoid').Health, 1)..'💗'..plr.jaladaDePeloCharge.Value..'👩‍🦰'..plr.Stamina.Value..'🩸'--Picked:IsFriendsWith(7579989388)
                            end
						end
					else
                        teamChange:Disconnect()
						addedFunc:Disconnect()
						espLoopFunc:Disconnect()
					end
				end
				espLoopFunc = RunService.RenderStepped:Connect(espLoop)
			end
		end
	end)
end

-- FIX 4: CRITICAL STARTUP LOGIC

Players.PlayerAdded:Connect(function(plr)
	if espActionsEnabled then
		repeat wait(1) until plr.Character and getRoot(plr.Character)
		ESP(plr)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if espActionsEnabled or COREGUI:FindFirstChild(player.Name..'_LC') then
		for i,v in pairs(COREGUI:GetChildren()) do
			if v.Name == player.Name..'_ESP' or v.Name == player.Name..'_LC' or v.Name == player.Name..'_CHMS' then
				v:Destroy()
			end
		end
	end
end)

task.spawn(function()
    if espActionsEnabled then
        for i,v in pairs(Players:GetPlayers()) do
            if v.Name ~= player.Name then
                ESP(v)
            end
        end
    end
end)


-- ##AUTO CHIP##
local AutoChipenabled = false 
local Pad = workspace:FindFirstChild("Pad")

-- --- GUI SETUP ---
local AutoChipToggle = Instance.new("TextButton")
AutoChipToggle.Size = UDim2.new(0,100,0,30)
AutoChipToggle.Position = UDim2.new(0,10,0,200)
AutoChipToggle.Text = AutoChipenabled and "Auto Chip: ON" or "Auto Chip: OFF"
AutoChipToggle.BackgroundColor3 = AutoChipenabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
AutoChipToggle.TextColor3 = Color3.new(1,1,1)
AutoChipToggle.Parent = PlayerFrame

AutoChipToggle.MouseButton1Click:Connect(function()
    AutoChipenabled = not AutoChipenabled
    AutoChipToggle.Text = AutoChipenabled and "Auto Chip: ON" or "Auto Chip: OFF"
    AutoChipToggle.BackgroundColor3 = AutoChipenabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
    if AutoChipenabled and Pad and player.Character then
        task.spawn(function()
            while AutoChipenabled do
                local PadPart = Pad:GetChildren()[2] -- Define once

                -- Check for the PadPart before accessing its properties
                if not PadPart or not player.Character then break end 

                local Prompt = PadPart:FindFirstChildOfClass("ProximityPrompt")
                if not Prompt then break end -- Exit if the prompt is missing

                player.Character.HumanoidRootPart.CFrame = PadPart.CFrame * CFrame.new(0, 1, 0)
                task.wait(0.1) 
                Prompt:InputHoldBegin()
                task.wait(1.1)
                Prompt:InputHoldEnd()
            end
        end)
    end
end)



-- auto open fighting crate toggle
local crateActionsEnabled = false

local crateToggle = Instance.new("TextButton")
crateToggle.Size = UDim2.new(0,100,0,30)
crateToggle.Position = UDim2.new(0,120,0,200)
crateToggle.Text = crateActionsEnabled and "Auto crate: ON" or "Auto crate: OFF"
crateToggle.BackgroundColor3 = crateActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
crateToggle.TextColor3 = Color3.new(1,1,1)
crateToggle.Parent = PlayerFrame

crateToggle.MouseButton1Click:Connect(function()
    crateActionsEnabled = not crateActionsEnabled
    crateToggle.Text = crateActionsEnabled and "Auto crate: ON" or "Auto crate: OFF"
    crateToggle.BackgroundColor3 = crateActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

    -- Start the loop in a new, non-blocking thread if enabled
    if crateActionsEnabled then
        task.spawn(function()
            -- This thread will run independently of the button click handler
            while crateActionsEnabled do
                game.ReplicatedStorage.Modules.Net["RE/undergroundFightingCrates"]:FireServer("Basic")
                task.wait(0.01)
            end
        end)
    end
end)



-- auto autohit toggle
local autohitActionsEnabled = false

local autohitToggle = Instance.new("TextButton")
autohitToggle.Size = UDim2.new(0,100,0,30)
autohitToggle.Position = UDim2.new(0,120,0,10)
autohitToggle.Text = autohitActionsEnabled and "Auto autohit: ON" or "Auto autohit: OFF"
autohitToggle.BackgroundColor3 = autohitActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
autohitToggle.TextColor3 = Color3.new(1,1,1)
autohitToggle.Parent = CombatFrame

autohitToggle.MouseButton1Click:Connect(function()
    autohitActionsEnabled = not autohitActionsEnabled
    autohitToggle.Text = autohitActionsEnabled and "Auto autohit: ON" or "Auto autohit: OFF"
    autohitToggle.BackgroundColor3 = autohitActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

    -- Start the loop in a new, non-blocking thread if enabled
    if autohitActionsEnabled then
        task.spawn(function()
            -- This thread will run independently of the button click handler
            while autohitActionsEnabled do 
                for _, ev in ipairs(hitEvents) do
                    if ev then
                        ev:FireServer(1)
                    end
                end
                task.wait(0.01)
            end
        end)
    end
end)

-- flyjump toggle
local flyjumpActionsEnabled = false

local flyjumpToggle = Instance.new("TextButton")
flyjumpToggle.Size = UDim2.new(0,100,0,30)
flyjumpToggle.Position = UDim2.new(0,10,0,276)
flyjumpToggle.Text = flyjumpActionsEnabled and "flyjump: ON" or "flyjump: OFF"
flyjumpToggle.BackgroundColor3 = flyjumpActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
flyjumpToggle.TextColor3 = Color3.new(1,1,1)
flyjumpToggle.Parent = PlayerFrame

flyjumpToggle.MouseButton1Click:Connect(function()
    -- Start the loop in a new, non-blocking thread if enabled
	--flyjumpActionsEnabled = not flyjumpActionsEnabled
	
	if flyjumpActionsEnabled then
		flyjumpActionsEnabled:Disconnect()
		flyjumpActionsEnabled = false
	else
		flyjumpActionsEnabled = UserInputService.JumpRequest:Connect(function()
			Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
		end)
	end


    flyjumpToggle.Text = flyjumpActionsEnabled and "flyjump: ON" or "flyjump: OFF"
    flyjumpToggle.BackgroundColor3 = flyjumpActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

end)





-- candy toggle
local CandyActionsEnabled = false

local CandyToggle = Instance.new("TextButton")
CandyToggle.Size = UDim2.new(0,100,0,30)
CandyToggle.Position = UDim2.new(0,120,0,276)
CandyToggle.Text = CandyActionsEnabled and "Candy: ON" or "Candy: OFF"
CandyToggle.BackgroundColor3 = CandyActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
CandyToggle.TextColor3 = Color3.new(1,1,1)
CandyToggle.Parent = PlayerFrame

CandyToggle.MouseButton1Click:Connect(function()
    CandyActionsEnabled = not CandyActionsEnabled
    CandyToggle.Text = CandyActionsEnabled and "Candy: ON" or "Candy: OFF"
    CandyToggle.BackgroundColor3 = CandyActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

    local Char = player.Character or player.CharacterAdded:Wait()
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")

    while CandyActionsEnabled do
        local Target = game.Workspace.HalloweenHouses["1"]["House 2"].Doorbell
        if HRP and Target and Target:IsA("BasePart") then
            HRP.CFrame = Target.CFrame * CFrame.new(2, 0, 0)
            local Prompt = Target:FindFirstChildOfClass("ProximityPrompt")
            Prompt.MaxActivationDistance = 10
            Prompt.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt:InputHoldBegin()
            task.wait(0.01)
            Prompt:InputHoldEnd()
        end
        local Target2 = game.workspace.HalloweenHouses["2"]["House 2"].Doorbell
        if HRP and Target2 and Target2:IsA("BasePart") then
            HRP.CFrame = Target2.CFrame * CFrame.new(2, 0, 0)
            local Prompt2 = Target2:FindFirstChildOfClass("ProximityPrompt")
            Prompt2.MaxActivationDistance = 10
            Prompt2.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt2:InputHoldBegin()
            task.wait(0.01)
            Prompt2:InputHoldEnd()
        end
        local Target3 = game.workspace.HalloweenHouses["3"]["House 5"].Doorbell
        if HRP and Target3 and Target3:IsA("BasePart") then
            HRP.CFrame = Target3.CFrame * CFrame.new(2, 0, 0)
            local Prompt3 = Target3:FindFirstChildOfClass("ProximityPrompt")
            Prompt3.MaxActivationDistance = 10
            Prompt3.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt3:InputHoldBegin()
            task.wait(0.01)
            Prompt3:InputHoldEnd()
        end
        local Target4 = game.workspace.HalloweenHouses["4"]["House 7"].Doorbell
        if HRP and Target4 and Target4:IsA("BasePart") then
            HRP.CFrame = Target4.CFrame * CFrame.new(2, 0, 0)
            local Prompt4 = Target4:FindFirstChildOfClass("ProximityPrompt") 
            Prompt4.MaxActivationDistance = 10
            Prompt4.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt4:InputHoldBegin()
            task.wait(0.01)
            Prompt4:InputHoldEnd()
        end

        local Target5 = game.workspace.HalloweenHouses["5"]["House 10"].Doorbell
        if HRP and Target5 and Target5:IsA("BasePart") then
            HRP.CFrame = Target5.CFrame * CFrame.new(2, 0, 0)
            local Prompt5 = Target5:FindFirstChildOfClass("ProximityPrompt") 
            Prompt5.MaxActivationDistance = 10
            Prompt5.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt5:InputHoldBegin()
            task.wait(0.01)
            Prompt5:InputHoldEnd()
        end
        local Target6 = game.workspace.HalloweenHouses["6"]["House 7"].Doorbell
        if HRP and Target6 and Target6:IsA("BasePart") then
            HRP.CFrame = Target6.CFrame * CFrame.new(2, 0, 0)
            local Prompt6 = Target6:FindFirstChildOfClass("ProximityPrompt") 
            Prompt6.MaxActivationDistance = 10
            Prompt6.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt6:InputHoldBegin()
            task.wait(0.01)
            Prompt6:InputHoldEnd()
        end
        local Target7 = game.workspace.HalloweenHouses["7"]["House 7"].Doorbell
        if HRP and Target7 and Target7:IsA("BasePart") then
            HRP.CFrame = Target7.CFrame * CFrame.new(2, 0, 0)
            local Prompt7 = Target7:FindFirstChildOfClass("ProximityPrompt") 
            Prompt7.MaxActivationDistance = 10
            Prompt7.RequiresLineOfSight = false
            task.wait(0.2) 
            Prompt7:InputHoldBegin()
            task.wait(0.01)
            Prompt7:InputHoldEnd()
        end
    end
end)





-- RPG BUTTON toggle
local RPGActionsEnabled = false

local RPGToggle = Instance.new("TextButton")
RPGToggle.Size = UDim2.new(0,100,0,30)
RPGToggle.Position = UDim2.new(0,10,0,86)
RPGToggle.Text = RPGActionsEnabled and "RPG: ON" or "RPG: OFF"
RPGToggle.BackgroundColor3 = RPGActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)
RPGToggle.TextColor3 = Color3.new(1,1,1)
RPGToggle.Parent = CombatFrame

RPGToggle.MouseButton1Click:Connect(function()
	RPGActionsEnabled = not RPGActionsEnabled

    RPGToggle.Text = RPGActionsEnabled and "RPG: ON" or "RPG: OFF"
    RPGToggle.BackgroundColor3 = RPGActionsEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(200,0,0)

    while RPGActionsEnabled do
		wait(0.01)
		game:GetService("ReplicatedStorage").Modules.Net["RE/RPG_Reload"]:FireServer()
    end
end)


