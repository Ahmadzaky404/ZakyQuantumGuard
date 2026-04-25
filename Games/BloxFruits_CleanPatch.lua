--[[
    Zaky Quantum - Clean Patch (Readable)
    This file is intended to stay readable and easy to maintain.
    It loads the existing main BloxFruits script, then applies UI branding
    and a simple player Auto Attack GUI.
]]

local CONFIG = {
    BaseScriptUrl = "https://raw.githubusercontent.com/Ahmadzaky404/ZakyQuantumGuard/main/Games/BloxFruits.lua",
    EnableBrandingOverride = true,
    EnablePlayerAutoAttackGui = true,
    EnableMainFarmGui = true,
    BrandMap = {
        { "Quantum Onyx Project", "Zaky Quantum Project" },
        { "Quantum Onyx", "Zaky Quantum" },
        { "QuantumOnyx", "ZakyQuantum" },
    },
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRootPart(model)
    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
end

local function getEnemyTarget(range)
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then
        return nil
    end

    local myCharacter = getCharacter()
    local myRoot = getRootPart(myCharacter)
    if not myRoot then
        return nil
    end

    local closest, closestDist = nil, range
    for _, model in ipairs(enemiesFolder:GetChildren()) do
        if model:IsA("Model") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = getRootPart(model)
            if humanoid and root and humanoid.Health > 0 then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist <= closestDist then
                    closest = model
                    closestDist = dist
                end
            end
        end
    end

    return closest
end

local function getAliveEnemiesInRange(centerPos, range)
    local enemiesFolder = workspace:FindFirstChild("Enemies")
    if not enemiesFolder then
        return {}
    end

    local found = {}
    for _, model in ipairs(enemiesFolder:GetChildren()) do
        if model:IsA("Model") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local root = getRootPart(model)
            if humanoid and root and humanoid.Health > 0 then
                local dist = (root.Position - centerPos).Magnitude
                if dist <= range then
                    table.insert(found, model)
                end
            end
        end
    end

    return found
end

local function tryTakeNearestQuest()
    local myCharacter = getCharacter()
    local myRoot = getRootPart(myCharacter)
    if not myRoot then
        return false
    end

    local nearestPrompt
    local nearestDist = 25
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("ProximityPrompt") and inst.Enabled then
            local holder = inst.Parent
            if holder and holder:IsA("BasePart") then
                local name = string.lower(holder.Name)
                if name:find("quest", 1, true) or name:find("mission", 1, true) then
                    local dist = (holder.Position - myRoot.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestPrompt = inst
                    end
                end
            end
        end
    end

    if nearestPrompt and fireproximityprompt then
        fireproximityprompt(nearestPrompt)
        return true
    end

    return false
end

local function applyBrandingToInstance(instance)
    if not (instance:IsA("TextLabel") or instance:IsA("TextButton")) then
        return
    end

    local text = instance.Text
    if text == "" then
        return
    end

    local updated = text
    for _, pair in ipairs(CONFIG.BrandMap) do
        updated = updated:gsub(pair[1], pair[2])
    end

    if updated ~= text then
        instance.Text = updated
    end
end

local function startBrandingOverride()
    if not CONFIG.EnableBrandingOverride then
        return
    end

    for _, desc in ipairs(PlayerGui:GetDescendants()) do
        applyBrandingToInstance(desc)
    end

    PlayerGui.DescendantAdded:Connect(function(desc)
        task.defer(function()
            applyBrandingToInstance(desc)
        end)
    end)

    task.spawn(function()
        while task.wait(1) do
            for _, desc in ipairs(PlayerGui:GetDescendants()) do
                applyBrandingToInstance(desc)
            end
        end
    end)
end

local function createPlayerAutoAttackGui()
    if not CONFIG.EnablePlayerAutoAttackGui then
        return
    end

    if PlayerGui:FindFirstChild("ZQ_PlayerGUI") then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ZQ_PlayerGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.fromOffset(240, 132)
    frame.Position = UDim2.fromOffset(12, 220)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 0, 24)
    title.Position = UDim2.fromOffset(6, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Zaky Quantum - Player GUI"
    title.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "AutoAttackToggle"
    toggleButton.Size = UDim2.new(1, -12, 0, 36)
    toggleButton.Position = UDim2.fromOffset(6, 34)
    toggleButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    toggleButton.BorderSizePixel = 0
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.TextSize = 13
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Text = "Auto Attack: OFF"
    toggleButton.Parent = frame

    local state = {
        enabled = false,
        range = 32,
        minRange = 8,
        maxRange = 120,
        interval = 0.12,
        lastSwing = 0,
    }

    local rangeLabel = Instance.new("TextLabel")
    rangeLabel.Name = "RangeLabel"
    rangeLabel.Size = UDim2.new(1, -12, 0, 20)
    rangeLabel.Position = UDim2.fromOffset(6, 74)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextSize = 12
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    rangeLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
    rangeLabel.Parent = frame

    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "SliderTrack"
    sliderTrack.Size = UDim2.new(1, -16, 0, 8)
    sliderTrack.Position = UDim2.fromOffset(8, 103)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = frame

    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Size = UDim2.fromScale(0, 1)
    sliderFill.BackgroundColor3 = Color3.fromRGB(40, 150, 70)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack

    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "SliderKnob"
    sliderKnob.Size = UDim2.fromOffset(12, 12)
    sliderKnob.Position = UDim2.fromOffset(-6, -2)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderTrack

    local function setRange(newRange)
        local range = math.clamp(math.floor(newRange + 0.5), state.minRange, state.maxRange)
        state.range = range
        rangeLabel.Text = ("Range: %d"):format(range)

        local alpha = (range - state.minRange) / (state.maxRange - state.minRange)
        sliderFill.Size = UDim2.fromScale(alpha, 1)
        sliderKnob.Position = UDim2.new(alpha, -6, 0, -2)
    end

    setRange(state.range)

    local sliderDragging = false
    local function updateRangeFromInput(input)
        local x = input.Position.X
        local trackPos = sliderTrack.AbsolutePosition.X
        local trackSize = sliderTrack.AbsoluteSize.X
        local alpha = math.clamp((x - trackPos) / trackSize, 0, 1)
        local range = state.minRange + (state.maxRange - state.minRange) * alpha
        setRange(range)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = true
            updateRangeFromInput(input)
        end
    end)

    sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = true
            updateRangeFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateRangeFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging = false
        end
    end)

    local dragging = false
    local dragInput, dragStart, startPos

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            dragInput = input
        end
    end)

    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local attackConnection
    local function stopAutoAttack()
        if attackConnection then
            attackConnection:Disconnect()
            attackConnection = nil
        end
    end

    local function startAutoAttack()
        stopAutoAttack()
        attackConnection = RunService.Heartbeat:Connect(function()
            if not state.enabled then
                return
            end

            local now = os.clock()
            if now - state.lastSwing < state.interval then
                return
            end

            local character = getCharacter()
            local tool = character:FindFirstChildOfClass("Tool")
            if not tool then
                return
            end

            local target = getEnemyTarget(state.range)
            if not target then
                return
            end

            state.lastSwing = now
            tool:Activate()
        end)
    end

    toggleButton.MouseButton1Click:Connect(function()
        state.enabled = not state.enabled
        if state.enabled then
            toggleButton.Text = "Auto Attack: ON"
            toggleButton.BackgroundColor3 = Color3.fromRGB(24, 120, 45)
            startAutoAttack()
        else
            toggleButton.Text = "Auto Attack: OFF"
            toggleButton.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
            stopAutoAttack()
        end
    end)
end

local function createMainFarmGui()
    if not CONFIG.EnableMainFarmGui then
        return
    end

    if PlayerGui:FindFirstChild("ZQ_MainFarmGUI") then
        return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "ZQ_MainFarmGUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.Size = UDim2.fromOffset(270, 220)
    frame.Position = UDim2.fromOffset(12, 360)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 0, 24)
    title.Position = UDim2.fromOffset(6, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Text = "Zaky Quantum - Main Farm"
    title.Parent = frame

    local autoFarmToggle = Instance.new("TextButton")
    autoFarmToggle.Name = "AutoFarmToggle"
    autoFarmToggle.Size = UDim2.new(0.5, -9, 0, 34)
    autoFarmToggle.Position = UDim2.fromOffset(6, 34)
    autoFarmToggle.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
    autoFarmToggle.BorderSizePixel = 0
    autoFarmToggle.Font = Enum.Font.GothamBold
    autoFarmToggle.TextSize = 12
    autoFarmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoFarmToggle.Text = "Auto Farm: OFF"
    autoFarmToggle.Parent = frame

    local takeQuestToggle = Instance.new("TextButton")
    takeQuestToggle.Name = "TakeQuestToggle"
    takeQuestToggle.Size = UDim2.new(0.5, -9, 0, 34)
    takeQuestToggle.Position = UDim2.new(0.5, 3, 0, 34)
    takeQuestToggle.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
    takeQuestToggle.BorderSizePixel = 0
    takeQuestToggle.Font = Enum.Font.GothamBold
    takeQuestToggle.TextSize = 12
    takeQuestToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    takeQuestToggle.Text = "Take Quest: OFF"
    takeQuestToggle.Parent = frame

    local state = {
        autoFarm = false,
        takeQuest = false,
        farmDistance = 10,
        farmMin = 3,
        farmMax = 30,
        bringRadius = 180,
        bringMin = 40,
        bringMax = 450,
        attackInterval = 0.12,
        lastAttack = 0,
        questInterval = 2.0,
        lastQuest = 0,
        bringInterval = 0.2,
        lastBring = 0,
    }

    local function createSlider(yOffset, labelText, minValue, maxValue, getValue, setValue)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -12, 0, 20)
        label.Position = UDim2.fromOffset(6, yOffset)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Parent = frame

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -16, 0, 8)
        track.Position = UDim2.fromOffset(8, yOffset + 22)
        track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        track.BorderSizePixel = 0
        track.Parent = frame

        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundColor3 = Color3.fromRGB(34, 180, 90)
        fill.BorderSizePixel = 0
        fill.Parent = track

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(12, 12)
        knob.Position = UDim2.fromOffset(-6, -2)
        knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
        knob.BorderSizePixel = 0
        knob.Parent = track

        local dragging = false

        local function refreshLabelAndBar()
            local value = getValue()
            label.Text = ("%s: %d"):format(labelText, value)
            local alpha = (value - minValue) / (maxValue - minValue)
            fill.Size = UDim2.fromScale(alpha, 1)
            knob.Position = UDim2.new(alpha, -6, 0, -2)
        end

        local function updateFromInput(input)
            local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = minValue + (maxValue - minValue) * alpha
            setValue(math.floor(value + 0.5))
            refreshLabelAndBar()
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        refreshLabelAndBar()
        return refreshLabelAndBar
    end

    createSlider(76, "Farm Distance", state.farmMin, state.farmMax, function()
        return state.farmDistance
    end, function(v)
        state.farmDistance = math.clamp(v, state.farmMin, state.farmMax)
    end)

    createSlider(132, "Bring Radius", state.bringMin, state.bringMax, function()
        return state.bringRadius
    end, function(v)
        state.bringRadius = math.clamp(v, state.bringMin, state.bringMax)
    end)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -12, 0, 20)
    info.Position = UDim2.fromOffset(6, 190)
    info.BackgroundTransparency = 1
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextColor3 = Color3.fromRGB(180, 180, 180)
    info.Text = "Status: Idle"
    info.Parent = frame

    local dragging = false
    local dragInput, dragStart, startPos

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            dragInput = input
        end
    end)

    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    autoFarmToggle.MouseButton1Click:Connect(function()
        state.autoFarm = not state.autoFarm
        if state.autoFarm then
            autoFarmToggle.Text = "Auto Farm: ON"
            autoFarmToggle.BackgroundColor3 = Color3.fromRGB(24, 120, 45)
            info.Text = "Status: Farming..."
        else
            autoFarmToggle.Text = "Auto Farm: OFF"
            autoFarmToggle.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
            info.Text = "Status: Idle"
        end
    end)

    takeQuestToggle.MouseButton1Click:Connect(function()
        state.takeQuest = not state.takeQuest
        if state.takeQuest then
            takeQuestToggle.Text = "Take Quest: ON"
            takeQuestToggle.BackgroundColor3 = Color3.fromRGB(24, 120, 45)
        else
            takeQuestToggle.Text = "Take Quest: OFF"
            takeQuestToggle.BackgroundColor3 = Color3.fromRGB(95, 95, 95)
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not state.autoFarm then
            return
        end

        local character = getCharacter()
        local myRoot = getRootPart(character)
        if not myRoot then
            return
        end

        local now = os.clock()
        local target = getEnemyTarget(state.bringRadius)
        if not target then
            info.Text = "Status: No enemy in range"
            return
        end

        local targetRoot = getRootPart(target)
        if not targetRoot then
            return
        end

        info.Text = "Status: Targeting " .. target.Name

        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, state.farmDistance)

        if now - state.lastBring >= state.bringInterval then
            state.lastBring = now
            local list = getAliveEnemiesInRange(myRoot.Position, state.bringRadius)
            for i, enemy in ipairs(list) do
                local enemyRoot = getRootPart(enemy)
                if enemyRoot and enemy ~= target then
                    local side = (i % 2 == 0) and 2 or -2
                    enemyRoot.CFrame = targetRoot.CFrame * CFrame.new(side, 0, -2 - (i % 4))
                end
            end
        end

        if now - state.lastAttack >= state.attackInterval then
            state.lastAttack = now
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end

        if state.takeQuest and now - state.lastQuest >= state.questInterval then
            state.lastQuest = now
            local questOk = tryTakeNearestQuest()
            if questOk then
                info.Text = "Status: Quest accepted"
            end
        end
    end)
end

local function loadBaseScript()
    local ok, src = pcall(function()
        return game:HttpGet(CONFIG.BaseScriptUrl)
    end)
    if not ok then
        warn("[Zaky Quantum] Failed to download base BloxFruits script.")
        return
    end

    local fn, err = loadstring(src)
    if not fn then
        warn("[Zaky Quantum] Failed to compile base script: " .. tostring(err))
        return
    end

    local runOk, runErr = pcall(fn)
    if not runOk then
        warn("[Zaky Quantum] Base script runtime error: " .. tostring(runErr))
    end
end

loadBaseScript()
task.defer(startBrandingOverride)
task.defer(createPlayerAutoAttackGui)
task.defer(createMainFarmGui)
