if not (game:IsLoaded()) then game.Loaded:Wait(); end;
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/Library.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/addons/ThemeManager.lua"))()
local Window = Library:CreateWindow({
    Title = "                         scripthookv    weird strict dad(chapter 1)",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab("main"),
    ['settings'] = Window:AddTab('settings'),
}

local MainBox = Tabs.Main:AddLeftGroupbox("main")
MainBox:AddButton({
    Text = "enable prompts",
    Func = function()
        local count = 0
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and not obj.Enabled then
                obj.Enabled = true
                count += 1
            end
        end
    end,
    Tooltip = 'force enables curtains, gas, lights, ect at the beginning',
});
MainBox:AddButton("no fog", function()
    local Lighting = cloneref(game:GetService("Lighting"))
    Lighting.FogStart = 10000
    Lighting.FogEnd = 10000
    Library:Notify("fog removed", 3)
end);
MainBox:AddButton("rejoin server", function()
    queue_on_teleport[[
    loadstring(game:HttpGet("https://raw.githubusercontent.com/xectray1/realloader/refs/heads/main/books.lua"))()
    ]]
    game.Players.LocalPlayer:Kick("rejoining")
    wait()
    cloneref(game:GetService("TeleportService")):Teleport(game.PlaceId, game.Players.LocalPlayer);
end);

local InstantInteractEnabled = false
local OriginalHoldDuration = {}
local function SetInstantInteract(enabled)
    InstantInteractEnabled = enabled
    OriginalHoldDuration = {}

    local prompts = {}
    for _, obj in ipairs(game.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            table.insert(prompts, obj)
        end
    end

    for _, prompt in ipairs(prompts) do
        if enabled then
            if OriginalHoldDuration[prompt] == nil then
                OriginalHoldDuration[prompt] = prompt.HoldDuration
            end
            prompt.HoldDuration = 0
        else
            if OriginalHoldDuration[prompt] ~= nil then
                prompt.HoldDuration = OriginalHoldDuration[prompt]
            end
        end
    end
end

MainBox:AddToggle("InstantInteract", {
    Text = "instant interact",
    Default = false,
    Callback = SetInstantInteract,
})

local INFStamEnabled = false
local StaminaConnection
local function InfiniteStamina(enabled)
    INFStamEnabled = enabled

    if StaminaConnection then
        StaminaConnection:Disconnect()
        StaminaConnection = nil
    end

    if enabled then
        local StaminaValue = game.Players.LocalPlayer.PlayerGui.Time.Frame.stamina
        local lastValue = StaminaValue.Value

        StaminaConnection = cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
            if StaminaValue.Value ~= 250 then
                StaminaValue.Value = 250
            end
        end)
    end
end

MainBox:AddToggle("InfiniteStamina", {
    Text = "infinite stamina",
    Default = false,
    Callback = InfiniteStamina,
})

local FullBrightEnabled = false
local FullBrightConnection
local OriginalLightingSettings = {}

local function ToggleFullBright(enabled)
    local Lighting = cloneref(game:GetService("Lighting"))

    if FullBrightConnection then
        FullBrightConnection:Disconnect()
        FullBrightConnection = nil
    end

    FullBrightEnabled = enabled

    if enabled then
        OriginalLightingSettings = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd
        }

        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000

        FullBrightConnection = cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.FogStart = 0
            Lighting.FogEnd = 100000
        end)

    else
        if OriginalLightingSettings and next(OriginalLightingSettings) then
            Lighting.Brightness = OriginalLightingSettings.Brightness
            Lighting.Ambient = OriginalLightingSettings.Ambient
            Lighting.OutdoorAmbient = OriginalLightingSettings.OutdoorAmbient
            Lighting.FogStart = OriginalLightingSettings.FogStart
            Lighting.FogEnd = OriginalLightingSettings.FogEnd
        end

    end
end

local AutoCollectTrash = false
local TrashConnection
local ProcessedTrash = {}

local function ToggleAutoTrash(enabled)
    AutoCollectTrash = enabled

    if TrashConnection then
        TrashConnection:Disconnect()
        TrashConnection = nil
    end

    if enabled then
        TrashConnection = cloneref(game:GetService("RunService")).Heartbeat:Connect(function()
            local LocalPlayer = game.Players.LocalPlayer
            local Character = LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
            local HRP = Character.HumanoidRootPart

            local TrashesContainers = game.Workspace:FindFirstChild("Game") and game.Workspace.Game:FindFirstChild("trashes")
            if not TrashesContainers then return end

            local FoundTrashBag = false

            for _, child in ipairs(TrashesContainers:GetDescendants()) do
                if child:IsA("Part") and child.Name == "P2" then
                    FoundTrashBag = true
                    local prompt = child:FindFirstChildOfClass("ProximityPrompt")

                    if prompt and prompt.Enabled and not ProcessedTrash[prompt] then
                        local distance = (child.Position - HRP.Position).Magnitude
                        local maxDist = prompt.MaxActivationDistance or 0

                        if distance <= maxDist then
                            ProcessedTrash[prompt] = true
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end

            for prompt in pairs(ProcessedTrash) do
                if not prompt:IsDescendantOf(game) then
                    ProcessedTrash[prompt] = nil
                end
            end

            if not FoundTrashBag then
                Library:Notify("collected all trash", 3)
                if TrashConnection then
                    TrashConnection:Disconnect()
                    TrashConnection = nil
                end
            end
        end)
    else
        if TrashConnection then
            TrashConnection:Disconnect()
            TrashConnection = nil
        end
    end
end

MainBox:AddToggle("CollectTrashToggle", {
    Text = "auto trash",
    Default = false,
    Callback = ToggleAutoTrash,
})

MainBox:AddToggle("FullBright", {
    Text = "full bright",
    Default = false,
    Callback = ToggleFullBright,
})

local function ToggleThirdPerson(enabled)
    local player = cloneref(game:GetService("Players")).LocalPlayer

    if enabled then
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMaxZoomDistance = 128
        player.CameraMinZoomDistance = 0.5
    else
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    end
end
MainBox:AddToggle("ThirdPerson", {
    Text = "third person",
    Default = false,
    Callback = ToggleThirdPerson,
})

local MainBox1 = Tabs.Main:AddRightGroupbox("teleports")
local function getKeys(tbl)
    local keys = {}
    for key, _ in pairs(tbl) do
        table.insert(keys, key)
    end
    return keys
end

local TeleportLocations = {
    ["bed"] = CFrame.new(-136, 18, 29),
    ["living room"] = CFrame.new(-156, 5, 66),
    ["kitchen"] = CFrame.new(-114, 5, 23),
    ["bathroom"] = CFrame.new(-137, 18, 69),
    ["hallway begin"] = CFrame.new(-161, 18, 20),
    ["hallway middle"] = CFrame.new(-145, 18, 19),
    ["router"] = CFrame.new(-123, 18, 20)
}
local SelectedLocation = ""

MainBox1:AddDropdown("TeleportLocationDropdown", {
    Values = getKeys(TeleportLocations), 
    Default = 1,
    Multi = false,
    Text = "locations",
    Callback = function(value)
        SelectedLocation = value
    end
})

MainBox1:AddButton("teleport", function()
    local HRP = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return
    end

    local TargetCFrame = TeleportLocations[SelectedLocation]
    if TargetCFrame then
        HRP.CFrame = TargetCFrame
        Library:Notify("teleported to " .. SelectedLocation, 3)
    else
        Library:Notify("location not found", 3)
    end
end)

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
function getRoot(char)
	local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
	return rootPart
end
FLYING = false
QEfly = true
iyflyspeed = 50
vehicleflyspeed = 50
local flyKeyDown, flyKeyUp
function sFLY(vfly)
	local plr = game.Players.LocalPlayer
	local char = plr.Character or plr.CharacterAdded:Wait()
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
		humanoid = char:FindFirstChildOfClass("Humanoid")
	end

	if flyKeyDown or flyKeyUp then
		flyKeyDown:Disconnect()
		flyKeyUp:Disconnect()
	end

	local T = getRoot(char)
	if T then
		T.CanCollide = false
	end

	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0
	local UIS = game:GetService("UserInputService")
	local function GetSpeed()
        return vfly and vehicleflyspeed or iyflyspeed
    end
if not UIS:GetFocusedTextBox() then
    CONTROL.F = UIS:IsKeyDown(Enum.KeyCode.W) and GetSpeed() or 0
    CONTROL.B = UIS:IsKeyDown(Enum.KeyCode.S) and -GetSpeed() or 0
    CONTROL.L = UIS:IsKeyDown(Enum.KeyCode.A) and -GetSpeed() or 0
    CONTROL.R = UIS:IsKeyDown(Enum.KeyCode.D) and GetSpeed() or 0
    if QEfly then
        CONTROL.E = UIS:IsKeyDown(Enum.KeyCode.Space) and GetSpeed() * 2 or 0
        CONTROL.Q = UIS:IsKeyDown(Enum.KeyCode.C) and -GetSpeed() * 2 or 0
    end
else
    CONTROL.F = 0
    CONTROL.B = 0
    CONTROL.L = 0
    CONTROL.R = 0
    CONTROL.E = 0
    CONTROL.Q = 0
end

	local function FLY()
		FLYING = true
		local BG = Instance.new('BodyGyro')
		local BV = Instance.new('BodyVelocity')
		BG.P = 9e4
		BG.Parent = T
		BV.Parent = T
		BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.CFrame = T.CFrame
		BV.Velocity = Vector3.new(0, 0, 0)
		BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		task.spawn(function()
			while FLYING do
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") and not part.Anchored then
						part.CanCollide = false
					end
				end
				task.wait(0.1)
			end
		end)

		task.spawn(function()
            repeat
                task.wait()
                local camera = workspace.CurrentCamera
                if not vfly and humanoid then
                    humanoid.PlatformStand = true
                    T.CanCollide = false
                end
                if not UIS:GetFocusedTextBox() then
                    CONTROL.F = UIS:IsKeyDown(Enum.KeyCode.W) and GetSpeed() or 0
	                CONTROL.B = UIS:IsKeyDown(Enum.KeyCode.S) and -GetSpeed() or 0
	                CONTROL.L = UIS:IsKeyDown(Enum.KeyCode.A) and -GetSpeed() or 0
	                CONTROL.R = UIS:IsKeyDown(Enum.KeyCode.D) and GetSpeed() or 0
                    if QEfly then
                        CONTROL.E = UIS:IsKeyDown(Enum.KeyCode.Space) and GetSpeed() * 2 or 0
		                CONTROL.Q = UIS:IsKeyDown(Enum.KeyCode.C) and -GetSpeed() * 2 or 0
                    end
                else
                    CONTROL.F = 0
                    CONTROL.B = 0
	                CONTROL.L = 0
	                CONTROL.R = 0
	                CONTROL.E = 0
	                CONTROL.Q = 0
                end
                
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = GetSpeed() * 0.01
                elseif SPEED ~= 0 then
                    SPEED = 0
                end
                
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
                    ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R,
                    (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif SPEED ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) +
                    ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R,
                    (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                else
                    BV.Velocity = Vector3.new(0, 0, 0)
                end
                BG.CFrame = camera.CFrame
            until not FLYING

			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			SPEED = 1
			BG:Destroy()
			BV:Destroy()

			if humanoid then
				humanoid.PlatformStand = false
			end

			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and not part.Anchored then
					part.CanCollide = true
				end
			end
		end)
	end

flyKeyDown = UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.W then
        CONTROL.F = GetSpeed()
    elseif input.KeyCode == Enum.KeyCode.S then
        CONTROL.B = -GetSpeed()
    elseif input.KeyCode == Enum.KeyCode.A then
        CONTROL.L = -GetSpeed()
    elseif input.KeyCode == Enum.KeyCode.D then
        CONTROL.R = GetSpeed()
    elseif input.KeyCode == Enum.KeyCode.Space and QEfly then
        CONTROL.E = GetSpeed() * 2
    elseif input.KeyCode == Enum.KeyCode.C and QEfly then
        CONTROL.Q = -GetSpeed() * 2
    end
end)

flyKeyUp = UIS.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.W then
        CONTROL.F = 0
    elseif input.KeyCode == Enum.KeyCode.S then
        CONTROL.B = 0
    elseif input.KeyCode == Enum.KeyCode.A then
        CONTROL.L = 0
    elseif input.KeyCode == Enum.KeyCode.D then
        CONTROL.R = 0
    elseif input.KeyCode == Enum.KeyCode.Space then
        CONTROL.E = 0
    elseif input.KeyCode == Enum.KeyCode.C then
        CONTROL.Q = 0
		end
	end)
	FLY()
end
function NOFLY()
	FLYING = false

	if flyKeyDown then
		flyKeyDown:Disconnect()
	end
	if flyKeyUp then
		flyKeyUp:Disconnect()
	end

	local char = Players.LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
	end

	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part.CanCollide = true
		end
	end

	pcall(function()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end)
end
local FlightToggle = MainBox1:AddToggle("flighttoggle", {
    Text = "Fly",
    Default = false,
    Callback = function(state)
        if state then
            sFLY(false)
        else
            NOFLY()
        end
    end
})

FlightToggle:AddKeyPicker("flighttoggle_key", {
    Default = "X",
    NoUI = false,
    Text = "fly",
    Mode = "Toggle",
    SyncToggleState = true,
})

MainBox1:AddSlider("flightspeed", {
    Text = "speed",
    Default = 50,
    Min = 50,
    Max = 1000,
    Rounding = 0,
    Compact = true,
    Callback = function(value)
        iyflyspeed = value
        vehicleflyspeed = value
    end
})

local NoclipEnabled = false
local NoclipConnection
local function ToggleNoclip(enabled)
    NoclipEnabled = enabled

    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    if enabled then
        local player = game.Players.LocalPlayer
        NoclipConnection = cloneref(game:GetService("RunService")).RenderStepped:Connect(function()
            local character = player.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end
local NoclipToggle = MainBox1:AddToggle("NoclipToggle", {
    Text = "noclip",
    Default = false,
    Callback = ToggleNoclip,
});
NoclipToggle:AddKeyPicker("NoclipToggleKey", {
    Default = "Z",
    NoUI = false,
    Text = "noclip",
    Mode = "Toggle",
    SyncToggleState = true,
});
local WalkSpeedEnabled = false
local WalkSpeedMultiplier = 1
local WalkSpeedConnection
local function ToggleWalkSpeed(enabled)
    WalkSpeedEnabled = enabled

    if WalkSpeedConnection then
        WalkSpeedConnection:Disconnect()
        WalkSpeedConnection = nil
    end

    if enabled then
        local player = game.Players.LocalPlayer
        WalkSpeedConnection = cloneref(game:GetService("RunService")).Heartbeat:Connect(function(deltaTime)
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                local HRP = character.HumanoidRootPart
                local humanoid = character.Humanoid
                local MoveDirection = humanoid.MoveDirection
                if MoveDirection.Magnitude > 0 then
                    local moveDelta = MoveDirection.Unit * humanoid.WalkSpeed * WalkSpeedMultiplier * deltaTime
                    HRP.CFrame = HRP.CFrame + moveDelta
                end
            end
        end)
    end
end
local WalkSpeedToggle = MainBox1:AddToggle("WalkSpeedToggle", {
    Text = "speed",
    Default = false,
    Callback = ToggleWalkSpeed,
})
WalkSpeedToggle:AddKeyPicker("WalkSpeedToggleKey", {
    Default = "C",
    NoUI = false,
    Text = "speed",
    Mode = "Toggle",
    SyncToggleState = true,
})
MainBox1:AddSlider("WalkSpeedMultiplier", {
    Text = "amount",
    Default = 1,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = true,
    Callback = function(value)
        WalkSpeedMultiplier = value
    end,
});
MainBox1:AddToggle("voidenabled", {
    Text = "void desync",
    Default = false,
}):AddKeyPicker("voidenabledkey", {
    Default = "Y",
    NoUI = false,
    Text = "void",
    SyncToggleState = false,
    Callback = function(Value)
        if Toggles.voidenabled.Value then
            is_enabled = Value;
        end;
    end;
});
(getgenv()).clientcframe = (getgenv()).clientcframe or { Connections = {}, History = {} };
local data = (getgenv()).clientcframe
for _, conn in pairs(data.Connections) do
    if conn.Connected then conn:Disconnect(); end;
end;
data.Connections = {};
data.History = {};
local runservice = game:GetService("RunService");
local uis = cloneref(game:GetService("UserInputService"));
local localplayer = game:GetService("Players").LocalPlayer;
local character = localplayer.Character or localplayer.CharacterAdded:Wait();
local primarypart = character:WaitForChild("HumanoidRootPart");
local client_cframe = primarypart.CFrame;
local function add_to_history()
    if primarypart and primarypart.Parent then
        local realpos = primarypart.Position;
        table.insert(data.History, realpos);
        if #data.History > 50 then
            table.remove(data.History, 1);
        end;
    end;
end;
if not data.IndexHook then
    local __index; __index = hookmetamethod(game, "__index", newcclosure(function(self, property)
        if not checkcaller() and self == primarypart and property == "CFrame" then
            return client_cframe;
        end;
        return __index(self, property);
    end));
    data.IndexHook = true;
end;
table.insert(data.Connections, localplayer.CharacterAdded:Connect(function(newchar)
    character = newchar;
    primarypart = newchar:WaitForChild("HumanoidRootPart");
    humanoid = newchar:WaitForChild("Humanoid");
    client_cframe = primarypart.CFrame;
    data.History  = {};
    task.wait(1);
end));
local function targetcframe()
    if not primarypart then return client_cframe; end;
    local basePos = primarypart.Position;
    local X = math.random(-500, 500)
    local Y = 500
    local Z = math.random(-500, 500)
    return CFrame.new(X, Y, Z);
end;
table.insert(data.Connections, runservice.Heartbeat:Connect(function()
    if not (primarypart and primarypart.Parent) then return; end;
    client_cframe = primarypart.CFrame;
    if tick() % 0.2 < 0.03 then
        add_to_history();
    end;
    local humanoid = localplayer.Character:WaitForChild("Humanoid");
    if is_enabled and isnetworkowner(primarypart) then
        local target = targetcframe();
        primarypart.CFrame = target;
    else
        primarypart.CFrame = client_cframe;
    end;
    runservice.RenderStepped:Wait();
    primarypart.CFrame = client_cframe;
end));
Library.KeybindFrame.Visible = true;
local MenuGroup = Tabs['settings']:AddLeftGroupbox('ui')
MenuGroup:AddLabel('toggle ui'):AddKeyPicker("uitoggle", { Default = 'End', NoUI = true, Text = 'UI Bind' })
MenuGroup:AddButton('Unload', function() Library:Unload() end)
Library.ToggleKeybind = Options.uitoggle
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:BuildConfigSection(Tabs['settings'])
ThemeManager:ApplyToTab(Tabs['settings'])
