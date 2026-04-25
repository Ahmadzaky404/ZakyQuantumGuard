local Guard = (function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local plr = Players.LocalPlayer
    local PlayerGui = plr:WaitForChild("PlayerGui")
    local BLOCKED_METHODS = {
        Destroy = true,
        Remove = true,
        ClearAllChildren = true,
    }

    local function getCharacter()
        return plr.Character or plr.CharacterAdded:Wait()
    end

    local function getRootPart(model)
        return model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("Torso")
            or model:FindFirstChild("UpperTorso")
    end

    local function getEnemyTarget(range)
        local enemies = workspace:FindFirstChild("Enemies")
        if not enemies then
            return nil
        end

        local character = getCharacter()
        local myRoot = getRootPart(character)
        if not myRoot then
            return nil
        end

        local closestModel, closestDistance = nil, range
        for _, model in ipairs(enemies:GetChildren()) do
            if model:IsA("Model") then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                local root = getRootPart(model)
                if humanoid and root and humanoid.Health > 0 then
                    local distance = (root.Position - myRoot.Position).Magnitude
                    if distance <= closestDistance then
                        closestModel = model
                        closestDistance = distance
                    end
                end
            end
        end

        return closestModel
    end

    local function createAutoAttackGui()
        local old = PlayerGui:FindFirstChild("ZQ_PlayerGUI")
        if old then
            old:Destroy()
        end

        local gui = Instance.new("ScreenGui")
        gui.Name = "ZQ_PlayerGUI"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = false
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
            lastSwing = 0,
            interval = 0.12,
            minRange = 8,
            maxRange = 120,
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
        rangeLabel.Text = "Range: 32"
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

                -- Only swing when an attackable target is in range.
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

    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if checkcaller() then
            return OldNamecall(self, ...)
        end
        if typeof(self) == "Instance" and self == PlayerGui and BLOCKED_METHODS[method] then
            task.defer(function()
                warn(("[ Zaky Quantum Guard ] Blocked '%s' on PlayerGui"):format(method))
            end)
            return nil
        end
        return OldNamecall(self, ...)
    end))

    task.defer(function()
        print("[Guard] PlayerGui protection active")
        createAutoAttackGui()
    end)
end)()
