local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Fsys = require(ReplicatedStorage:WaitForChild("Fsys"))
local load = Fsys.load
local UIManager = load("UIManager")
local ClientData = load("ClientData")
local InventoryDB = load("InventoryDB")
if UIManager.wait_for_initialization then UIManager:wait_for_initialization() else task.wait(2) end

local HIGH_TIER_PETS = {
    "Bat Dragon", "Shadow Dragon", "Giraffe", "Frost Dragon", "Owl", "Parrot", "Crow", 
    "Evil Unicorn", "Arctic Reindeer", "Hedgehog", "Dalmatian", "Turtle", "Kangaroo", 
    "Flamingo", "Cow", "Peppermint Penguin", "Undead Jousting Horse", "Monkey King", "Balloon Unicorn"
}

local screenGui = Instance.new("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "PreppyWheel"; screenGui.ResetOnSpawn = false; screenGui.DisplayOrder = 15

local T = { bgDark = Color3.fromRGB(255, 102, 196), bgLight = Color3.fromRGB(250, 225, 245), text = Color3.fromRGB(130, 80, 110), font = Enum.Font.FredokaOne }

-- Paper stack effect (smaller)
local back1 = Instance.new("Frame", screenGui); back1.Size = UDim2.new(0, 290, 0, 190); back1.Position = UDim2.new(0.5, -145, 0.5, -95); back1.BackgroundColor3 = T.bgDark; back1.Rotation = -3; Instance.new("UICorner", back1).CornerRadius = UDim.new(0, 12)
local back2 = back1:Clone(); back2.Rotation = 3; back2.BackgroundColor3 = Color3.fromRGB(255, 130, 210); back2.Parent = screenGui

-- Main window (smaller)
local main = Instance.new("Frame", screenGui); main.Size = UDim2.new(0, 280, 0, 180); main.Position = UDim2.new(0.5, -140, 0.5, -90); main.BackgroundColor3 = T.bgLight; Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", main); stroke.Color = Color3.fromRGB(180, 150, 170); stroke.Thickness = 2

local title = Instance.new("TextLabel", main); title.Size = UDim2.new(1, 0, 0, 30); title.Position = UDim2.new(0, 0, 0, 10); title.BackgroundTransparency = 1; title.Font = T.font; title.TextSize = 20; title.TextColor3 = T.text; title.Text = "🎰 LUCKY WHEEL 🎰"

local resultLbl = Instance.new("TextLabel", main); resultLbl.Size = UDim2.new(1, 0, 0, 25); resultLbl.Position = UDim2.new(0, 0, 0, 40); resultLbl.BackgroundTransparency = 1; resultLbl.Font = T.font; resultLbl.TextSize = 14; resultLbl.TextColor3 = T.bgDark; resultLbl.Text = "Ready to spin?"

local spinBtn = Instance.new("TextButton", main); spinBtn.Size = UDim2.new(0.8, 0, 0, 50); spinBtn.Position = UDim2.new(0.1, 0, 0.55, 0); spinBtn.BackgroundColor3 = T.bgDark; spinBtn.Text = "SPIN THE WHEEL"; spinBtn.Font = T.font; spinBtn.TextSize = 22; spinBtn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", spinBtn).CornerRadius = UDim.new(0, 10)

-- Close button
local closeBtn = Instance.new("TextButton", main); closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -32, 0, 8); closeBtn.BackgroundColor3 = T.bgDark; closeBtn.Text = "X"; closeBtn.Font = T.font; closeBtn.TextSize = 12; closeBtn.TextColor3 = Color3.new(1,1,1); Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- SPINNER LOGIC
local isSpinning = false

local function getRandomPet()
    local name = HIGH_TIER_PETS[math.random(1, #HIGH_TIER_PETS)]
    for id, item in pairs(InventoryDB.pets or {}) do
        if item.name:lower() == name:lower() then
            return id, item.kind
        end
    end
    return nil, nil
end

local function addToInventory(petId, petKind)
    local uid = HttpService:GenerateGUID(false)
    local flags = {F = math.random(1,2)==1, R = math.random(1,2)==1, N = math.random(1,3)==1, M = math.random(1,5)==1}
    if flags.M then flags.N = false end
    
    pcall(function() setthreadidentity(2) end)
    local inv = ClientData.get("inventory")
    if inv and inv.pets then
        inv.pets[uid] = {
            unique = uid, category = "pets", id = petId, kind = petKind,
            newness_order = math.huge, 
            properties = { flyable = flags.F, rideable = flags.R, neon = flags.N, mega_neon = flags.M, age = 6, xp = 0, rp_name = "" },
            _source = "wheel"
        }
    end
    pcall(function() setthreadidentity(8) end)
    pcall(function() UIManager.apps.BackpackApp:refresh_rendered_items() end)
end

spinBtn.MouseButton1Click:Connect(function()
    if isSpinning then return end
    isSpinning = true
    
    -- Button press animation
    TweenService:Create(spinBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.75, 0, 0, 45)}):Play()
    resultLbl.Text = "Spinning..."
    resultLbl.TextColor3 = T.bgDark
    
    -- Fast scroll animation
    task.spawn(function()
        for i = 1, 20 do
            if not screenGui.Parent then return end
            local randomName = HIGH_TIER_PETS[math.random(1, #HIGH_TIER_PETS)]
            resultLbl.Text = randomName
            task.wait(0.05 + (i * 0.01)) -- Deceleration
        end
        
        -- WINNER
        local petId, petKind = getRandomPet()
        if petId then
            addToInventory(petId, petKind)
            
            local finalName = InventoryDB.pets[petId].name
            resultLbl.Text = "You won: " .. finalName .. "!"
            resultLbl.TextColor3 = Color3.fromRGB(50, 200, 50)
            
            -- Success visual
            spinBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            TweenService:Create(spinBtn, TweenInfo.new(0.3), {Size = UDim2.new(0.8, 0, 0, 50)}):Play()
            
            task.wait(2)
            spinBtn.BackgroundColor3 = T.bgDark
            resultLbl.Text = "Ready to spin again?"
            resultLbl.TextColor3 = T.bgDark
        else
            resultLbl.Text = "Error finding pet..."
        end
        isSpinning = false
    end)
end)

-- Dragging
local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        back1.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset - 5, main.Position.Y.Scale, main.Position.Y.Offset - 5)
        back2.Position = UDim2.new(main.Position.X.Scale, main.Position.X.Offset + 5, main.Position.Y.Scale, main.Position.Y.Offset + 5)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
