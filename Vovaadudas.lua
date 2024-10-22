-- Ensure the script runs only on the client
if not game:GetService("RunService"):IsClient() then
    return
end

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- Function to create a draggable frame with rounded corners
local function createDraggableFrame(parent, size, position, backgroundColor, cornerRadius)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = backgroundColor
    frame.BackgroundTransparency = 0.1 -- More opaque for a cleaner look
    frame.BorderSizePixel = 0
    frame.Parent = parent

    -- Make frame draggable
    local dragging = false
    local dragInput, dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius
    corner.Parent = frame

    return frame
end

-- Create main GUI frame
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerTrackerGui"
screenGui.Parent = playerGui

local mainFrame = createDraggableFrame(screenGui, UDim2.new(0.3, 0, 0.5, 0), UDim2.new(0.35, 0, 0.25, 0), Color3.fromRGB(0, 0, 0), UDim.new(0, 12))

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.1, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
titleLabel.BackgroundTransparency = 0.1
titleLabel.BorderSizePixel = 0
titleLabel.Text = "Select a player to track"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextScaled = true
titleLabel.TextSize = 14
titleLabel.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 0.7, 0)
scrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Default to no scrolling
scrollFrame.ScrollBarThickness = 6
scrollFrame.BackgroundTransparency = 1
scrollFrame.Parent = mainFrame
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Automatically adjust the CanvasSize based on content size

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 5)
playerListLayout.Parent = scrollFrame

local function createButton(parent, size, position, text, backgroundColor, cornerRadius, textSize)
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.Text = text
    button.BackgroundColor3 = backgroundColor
    button.BackgroundTransparency = 0.1
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.TextSize = textSize
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius
    corner.Parent = button

    return button
end

local backButton = createButton(mainFrame, UDim2.new(0.3, 0, 0.1, 0), UDim2.new(0.1, 0, 0.85, 0), "Back", Color3.fromRGB(50, 50, 50), UDim.new(0, 10), 14)
local closeButton = createButton(mainFrame, UDim2.new(0.1, 0, 0.1, 0), UDim2.new(0.9, 0, 0, 0), "X", Color3.fromRGB(50, 50, 50), UDim.new(0, 10), 14)

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

backButton.MouseButton1Click:Connect(function()
    camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid") or nil
    camera.CameraType = Enum.CameraType.Custom
end)

local currentTargetPlayer = nil

local function setCameraToFreeView(targetPlayer)
    currentTargetPlayer = targetPlayer
    local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        camera.CameraSubject = humanoid
        camera.CameraType = Enum.CameraType.Custom
    end
end

-- Update player list
local function updatePlayerList()
    -- Clear previous list
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Create new buttons for each player
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            local playerButton = createButton(scrollFrame, UDim2.new(1, 0, 0.07, 0), UDim2.new(0, 0, 0, 0), p.Name, Color3.fromRGB(70, 70, 70), UDim.new(0, 10), 14)

            playerButton.MouseButton1Click:Connect(function()
                -- Start tracking the player
                print("Tracking player: " .. p.Name)
                setCameraToFreeView(p)
            end)
        end
    end

    -- Automatically adjust CanvasSize for scrolling
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0.07 * (#game.Players:GetPlayers() - 1), 0)
end

-- Update player list on start
updatePlayerList()

-- Update player list when players are added or removed
game.Players.PlayerAdded:Connect(updatePlayerList)
game.Players.PlayerRemoving:Connect(function(leavingPlayer)
    updatePlayerList()
    if currentTargetPlayer == leavingPlayer then
        -- Reset camera to the player if the tracked player leaves
        camera.CameraSubject = player.Character and player.Character:FindFirstChild("Humanoid") or nil
        camera.CameraType = Enum.CameraType.Custom
        currentTargetPlayer = nil
    end
end)
