--[[
    MM2 SUPREME VALUES HELPER (RAYFIELD UI EDITION)
    - Полная поддержка Delta / Hydrogen / Codex (Mobile & PC)
    - База цен: RHubMm2
    - Авто-подсветка ценников в трейде + W/L Калькулятор
    - Поиск цен на любые предметы прямо в меню
--]]

-- Загрузка библиотеки Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-------------------------------------------------------------------------------
-- 1. ДАННЫЕ И БАЗА ЦЕН
-------------------------------------------------------------------------------
local RAW_JSON_URL = "https://raw.githubusercontent.com/Red-Raf/RHubMm2/refs/heads/main/values.json"
local ItemValues = {}
local IsValuesLoaded = false
local OverlayEnabled = true

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
            return true
        end
    end
    return false
end

-------------------------------------------------------------------------------
-- 2. СОЗДАНИЕ ОКНА RAYFIELD
-------------------------------------------------------------------------------
local Window = Rayfield:CreateWindow({
   Name = "MM2 Supreme Values | Delta",
   Icon = 0,
   LoadingTitle = "Загрузка цен Supreme...",
   LoadingSubtitle = "by Rocket",
   Theme = "Default",

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,

   ConfigurationSaving = {
      Enabled = false
   },

   KeySystem = false
})

-- Создаем вкладки
local MainTab = Window:CreateTab("Трейд Помощник", 4483362458)
local SearchTab = Window:CreateTab("Поиск Цен", 4483362458)

-- Загружаем данные
local loadSuccess = LoadSupremeValues()

local StatusParagraph = MainTab:CreateParagraph({
    Title = "Статус базы цен",
    Content = loadSuccess and "🟢 База RHubMm2 успешно подключена!" or "🔴 Ошибка загрузки базы цен"
})

local TradeStatusParagraph = MainTab:CreateParagraph({
    Title = "Текущий трейд",
    Content = "Ожидание открытия окна трейда..."
})

MainTab:CreateToggle({
   Name = "Отображать оранжевые цифры в трейде",
   CurrentValue = true,
   Flag = "TradeOverlayToggle",
   Callback = function(Value)
      OverlayEnabled = Value
   end,
})

MainTab:CreateButton({
   Name = "Обновить цены вручную",
   Callback = function()
      if LoadSupremeValues() then
          Rayfield:Notify({
             Title = "Успех!",
             Content = "Цены успешно обновлены из сети.",
             Duration = 3,
             Image = 4483362458,
          })
      else
          Rayfield:Notify({
             Title = "Ошибка",
             Content = "Не удалось обновить цены.",
             Duration = 3,
             Image = 4483362458,
          })
      end
   end,
})

-------------------------------------------------------------------------------
-- 3. ВКЛАДКА ПОИСКА ЦЕН В МЕНЮ
-------------------------------------------------------------------------------
local SearchResultLabel = SearchTab:CreateParagraph({
    Title = "Результат поиска",
    Content = "Введите название предмета ниже..."
})

SearchTab:CreateInput({
   Name = "Поиск предмета",
   PlaceholderText = "Например: Gingerscope",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      if Text == "" then return end
      
      local found = false
      for name, val in pairs(ItemValues) do
          if string.lower(name) == string.lower(Text) or string.find(string.lower(name), string.lower(Text)) then
              SearchResultLabel:Set({
                  Title = "Предмет: " .. name,
                  Content = "Цена: " .. tostring(val) .. " Value"
              })
              found = true
              break
          end
      end

      if not found then
          SearchResultLabel:Set({
              Title = "Не найдено",
              Content = "Предмет '" .. Text .. "' не найден в базе."
          })
      end
   end,
})

-------------------------------------------------------------------------------
-- 4. ЛОГИКА НАЛОЖЕНИЯ НА ТРЕЙД MM2
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

local function ApplyTopLeftBadge(slot, val)
    local badge = slot:FindFirstChild("RayfieldValBadge")
    if not OverlayEnabled or val == 0 then
        if badge then badge.Visible = false end
        return
    end

    if not badge then
        badge = Instance.new("TextLabel")
        badge.Name = "RayfieldValBadge"
        badge.Size = UDim2.new(0.6, 0, 0.35, 0)
        badge.Position = UDim2.new(0, 2, 0, 1)
        badge.BackgroundTransparency = 1
        badge.Font = Enum.Font.FredokaOne
        badge.TextColor3 = Color3.fromRGB(255, 140, 0)
        badge.TextStrokeTransparency = 0.1
        badge.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        badge.TextScaled = true
        badge.TextXAlignment = Enum.TextXAlignment.Left
        badge.ZIndex = 1000
        badge.Parent = slot
    end

    badge.Text = tostring(val)
    badge.Visible = true
end

-- Автоматический фоновый цикл сканера трейда
RunService.RenderStepped:Connect(function()
    if not IsValuesLoaded then return end

    local tradeGui = PlayerGui:FindFirstChild("Trade") or PlayerGui:FindFirstChild("TradeGui") or PlayerGui:FindFirstChild("Trading")
    if not tradeGui then
        TradeStatusParagraph:Set({ Title = "Текущий трейд", Content = "Трейд не активен" })
        return
    end

    local container = tradeGui:FindFirstChild("Container", true) or tradeGui:FindFirstChild("Frame", true) or tradeGui:FindFirstChild("Main", true)
    if not container or not container.Visible then
        TradeStatusParagraph:Set({ Title = "Текущий трейд", Content = "Трейд не активен" })
        return
    end

    local yourOffer = container:FindFirstChild("YourOffer", true) or container:FindFirstChild("YourItems", true) or container:FindFirstChild("MyOffer", true)
    local theirOffer = container:FindFirstChild("TheirOffer", true) or container:FindFirstChild("TheirItems", true) or container:FindFirstChild("OtherOffer", true)

    local myTotal = 0
    local opponentTotal = 0

    if yourOffer then
        local itemsHolder = yourOffer:FindFirstChild("Container") or yourOffer:FindFirstChild("Items") or yourOffer:FindFirstChild("Grid") or yourOffer
        for _, slot in ipairs(itemsHolder:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Visible and slot.Name ~= "UIListLayout" and slot.Name ~= "UIGridLayout" then
                local val = GetItemValue(ExtractItemName(slot))
                ApplyTopLeftBadge(slot, val)
                myTotal += val
            end
        end
    end

    if theirOffer then
        local itemsHolder = theirOffer:FindFirstChild("Container") or theirOffer:FindFirstChild("Items") or theirOffer:FindFirstChild("Grid") or theirOffer
        for _, slot in ipairs(itemsHolder:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Visible and slot.Name ~= "UIListLayout" and slot.Name ~= "UIGridLayout" then
                local val = GetItemValue(ExtractItemName(slot))
                ApplyTopLeftBadge(slot, val)
                opponentTotal += val
            end
        end
    end

    local diff = opponentTotal - myTotal
    local resultText = ""
    if diff > 0 then
        resultText = string.format("ВЫГОДА: +%d (Win)", diff)
    elseif diff < 0 then
        resultText = string.format("УБЫТОК: -%d (Lose)", math.abs(diff))
    else
        resultText = "РОВНЫЙ ТРЕЙД (Fair)"
    end

    TradeStatusParagraph:Set({
        Title = "Статистика трейда",
        Content = string.format("ВЫ: %d | ОППОНЕНТ: %d\nИтог: %s", myTotal, opponentTotal, resultText)
    })
end)

-- Авто-обновление цен каждые 60 секунд
task.spawn(function()
    while true do
        task.wait(60)
        LoadSupremeValues()
    end
end)
