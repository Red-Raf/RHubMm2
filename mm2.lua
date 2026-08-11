local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------------------------------------
-- 1. ЗАГРУЗКА ЦЕН (RHubMm2)
-------------------------------------------------------------------------------
local RAW_JSON_URL = "https://raw.githubusercontent.com/Red-Raf/RHubMm2/refs/heads/main/values.json"
local ItemValues = {}
local IsValuesLoaded = false

local function LoadSupremeValues()
    local targetUrl = RAW_JSON_URL .. "?t=" .. tostring(os.time())
    local success, response = pcall(function()
        return game:HttpGet(targetUrl)
    end)

    if success and response then
        local decodeSuccess, decoded = pcall(function()
            return HttpService:JSONDecode(response)
        end)
        
        if decodeSuccess and type(decoded) == "table" then
            ItemValues = decoded
            IsValuesLoaded = true
            print("[Supreme Values] База успешно загружена!")
        end
    end
end

task.spawn(function()
    while true do
        LoadSupremeValues()
        task.wait(60)
    end
end)

-------------------------------------------------------------------------------
-- 2. МОБИЛЬНЫЕ И ПК ФУНКЦИИ ИНТЕРФЕЙСА
-------------------------------------------------------------------------------
local function GetItemValue(itemName)
    if not itemName or itemName == "" then return 0 end
    return ItemValues[itemName] or 0
end

local function ExtractItemName(slot)
    local nameLabel = slot:FindFirstChild("ItemName", true) or slot:FindFirstChild("Title", true) or slot:FindFirstChild("NameLabel", true)
    if nameLabel and nameLabel:IsA("TextLabel") and nameLabel.Text ~= "" then
        return nameLabel.Text
    end
    return slot.Name
end

-- Адаптивный оранжевый бейджик в ВЕРХНЕМ ЛЕВОМ углу предмета
local function ApplyTopLeftBadge(slot, val)
    local badge = slot:FindFirstChild("TikTokValBadge")
    if val == 0 then
        if badge then badge.Visible = false end
        return
    end

    if not badge then
        badge = Instance.new("TextLabel")
        badge.Name = "TikTokValBadge"
        badge.Size = UDim2.new(0.55, 0, 0.35, 0) -- Размер с запасом под мобильные экраны
        badge.Position = UDim2.new(0, 2, 0, 1)   -- Верхний левый угол
        badge.BackgroundTransparency = 1
        badge.Font = Enum.Font.FredokaOne
        badge.TextColor3 = Color3.fromRGB(255, 140, 0)
        badge.TextStrokeTransparency = 0.15
        badge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        badge.TextScaled = true                  -- Авто-размер шрифта для телефонов
        badge.TextXAlignment = Enum.TextXAlignment.Left
        badge.ZIndex = 100                       -- Всегда поверх картинки
        badge.Parent = slot
    end

    badge.Text = tostring(val)
    badge.Visible = true
end

-- Заголовок "[XX] VALUE" НАД контейнером предметов
local function ApplySectionHeader(container, totalVal)
    local header = container:FindFirstChild("SectionValueHeader")
    if not header then
        header = Instance.new("TextLabel")
        header.Name = "SectionValueHeader"
        header.Size = UDim2.new(1, 0, 0, 20)
        header.Position = UDim2.new(0, 0, 0, -22) -- Высота подстроена под мобильный UI
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.FredokaOne
        header.TextColor3 = Color3.fromRGB(255, 140, 0)
        header.TextStrokeTransparency = 0.2
        header.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        header.TextScaled = true                  -- Текст подстраивается под экран
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.ZIndex = 50
        header.Parent = container
    end

    header.Text = string.format("%d VALUE", totalVal)
end

-- Строка статистики ПОД кнопкой DECLINE
local function ApplyDeclineStats(declineBtn, myTotal, oppTotal)
    local stats = declineBtn:FindFirstChild("DeclineStatsLabel")
    if not stats then
        stats = Instance.new("TextLabel")
        stats.Name = "DeclineStatsLabel"
        stats.Size = UDim2.new(1.8, 0, 0, 16)
        stats.Position = UDim2.new(-0.4, 0, 1, 3)
        stats.BackgroundTransparency = 1
        stats.Font = Enum.Font.FredokaOne
        stats.TextColor3 = Color3.fromRGB(255, 255, 255)
        stats.TextStrokeTransparency = 0.2
        stats.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        stats.TextScaled = true
        stats.ZIndex = 50
        stats.Parent = declineBtn
    end

    local diff = oppTotal - myTotal
    local pct = 0
    if myTotal > 0 then
        pct = math.floor((math.abs(diff) / myTotal) * 100)
    end

    local diffStr = diff >= 0 and ("+" .. tostring(diff)) or tostring(diff)
    stats.Text = string.format("YOU %d   THEM %d   %s  %d%%", myTotal, oppTotal, diffStr, pct)
end

-------------------------------------------------------------------------------
-- 3. ОСНОВНОЙ ЦИКЛ СКАНЕРА (ПОДДЕРЖКА MOBILE & PC)
-------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not IsValuesLoaded then return end

    -- Ищем окно трейда с учетом мобильных версий MM2
    local tradeGui = PlayerGui:FindFirstChild("Trade") or PlayerGui:FindFirstChild("TradeGui") or PlayerGui:FindFirstChild("Trading")
    if not tradeGui then return end

    local container = tradeGui:FindFirstChild("Container", true) or tradeGui:FindFirstChild("Frame", true) or tradeGui:FindFirstChild("Main", true)
    if not container or not container.Visible then return end

    -- Поиск предложений (Ваших и Оппонента)
    local yourOffer = container:FindFirstChild("YourOffer", true) or container:FindFirstChild("YourItems", true) or container:FindFirstChild("MyOffer", true)
    local theirOffer = container:FindFirstChild("TheirOffer", true) or container:FindFirstChild("TheirItems", true) or container:FindFirstChild("OtherOffer", true)

    local myTotal = 0
    local opponentTotal = 0

    -- 1. Подсчет Ваших предметов
    if yourOffer then
        local itemsHolder = yourOffer:FindFirstChild("Container") or yourOffer:FindFirstChild("Items") or yourOffer:FindFirstChild("Grid") or yourOffer
        for _, slot in ipairs(itemsHolder:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Visible and slot.Name ~= "UIListLayout" and slot.Name ~= "UIGridLayout" then
                local val = GetItemValue(ExtractItemName(slot))
                ApplyTopLeftBadge(slot, val)
                myTotal += val
            end
        end
        ApplySectionHeader(yourOffer, myTotal)
    end

    -- 2. Подсчет предметов Оппонента
    if theirOffer then
        local itemsHolder = theirOffer:FindFirstChild("Container") or theirOffer:FindFirstChild("Items") or theirOffer:FindFirstChild("Grid") or theirOffer
        for _, slot in ipairs(itemsHolder:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Visible and slot.Name ~= "UIListLayout" and slot.Name ~= "UIGridLayout" then
                local val = GetItemValue(ExtractItemName(slot))
                ApplyTopLeftBadge(slot, val)
                opponentTotal += val
            end
        end
        ApplySectionHeader(theirOffer, opponentTotal)
    end

    -- 3. Статистика под кнопкой DECLINE
    local declineBtn = container:FindFirstChild("Decline", true) or container:FindFirstChild("DeclineButton", true)
    if declineBtn then
        ApplyDeclineStats(declineBtn, myTotal, opponentTotal)
    end
end)
