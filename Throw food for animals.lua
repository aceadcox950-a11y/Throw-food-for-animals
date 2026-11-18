if not game:IsLoaded() then game.Loaded:Wait() end

queue_on_teleport([[task.wait(10) loadstring(game:HttpGet("https://loadstring.net/raw/oxX8zemdta"))()]])

local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Plr = game:GetService("Players").LocalPlayer

--// Settings
local FILE = "ThrowFoodForAnimalsVaehzFarm.json"
local AutofarmData = { Enabled = false, ThrowAmt = 5, PowerTime = 10, AutoStand = true, AutoFood = true }
if isfile(FILE) then
    local ok, saved = pcall(function() return HttpService:JSONDecode(readfile(FILE)) end)
    if ok and type(saved) == "table" then
        for k, v in pairs(saved) do AutofarmData[k] = v end
    end
end

--// Game
local DataController = require(Plr:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("DataController"))
local StandsConfig = require(RS:WaitForChild("Config"):WaitForChild("StandsConfig"))
local FoodsConfig = require(RS:WaitForChild("Config"):WaitForChild("FoodsConfig"))
local BalanceCurve = require(RS:WaitForChild("Shared"):WaitForChild("BalanceCurve"))
local Remotes = RS:WaitForChild("Remotes")
local StartThrowPos = Vector3.new(0, 5, -39)
local Plot = workspace:WaitForChild("Plots"):WaitForChild(tostring(Plr:GetAttribute("PlotIndex")))
local function R(name) return Remotes:WaitForChild(name) end

--// UI helpers
local C = {
    Bg = Color3.fromRGB(16, 16, 22), Card = Color3.fromRGB(26, 26, 36), Stroke = Color3.fromRGB(46, 46, 62),
    Off = Color3.fromRGB(52, 52, 68), Text = Color3.fromRGB(240, 240, 245), Sub = Color3.fromRGB(150, 150, 172),
    Accent = Color3.fromRGB(255, 60, 70), Good = Color3.fromRGB(80, 220, 130),
}

local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    i.Parent = parent
    return i
end
local function round(i, r) new("UICorner", { CornerRadius = UDim.new(0, r) }, i) end
local function stroke(i) new("UIStroke", { Color = C.Stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, i) end
local function tween(i, p) TweenService:Create(i, TweenInfo.new(0.15), p):Play() end
local function list(parent, pad, horiz)
    new("UIListLayout", {
        Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = horiz and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
    }, parent)
end
local function lbl(parent, txt, size, color, pos, sz, props)
    props = props or {}
    props.Text, props.TextSize, props.TextColor3 = txt, size, color
    props.Position, props.Size = pos, sz
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.GothamMedium
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return new("TextLabel", props, parent)
end
local function card(parent, h, button)
    local props = { Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.Card, BorderSizePixel = 0 }
    if button then props.Text = "" props.AutoButtonColor = false end
    local f = new(button and "TextButton" or "Frame", props, parent)
    round(f, 8) stroke(f)
    return f
end
local function short(n)
    if type(n) ~= "number" then return tostring(n) end
    local s = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
    local i = 1
    while n >= 1000 and i < #s do
        n /= 1000
        i += 1
    end
    return i == 1 and tostring(math.floor(n)) or string.format("%.2f%s", n, s[i])
end

--// Window
local ok, hui = pcall(function() return gethui and gethui() or game:GetService("CoreGui") end)
local GuiParent = ok and hui or Plr:WaitForChild("PlayerGui")
local old = GuiParent:FindFirstChild("VaehzFarmUI")
if old then old:Destroy() end

local Gui = new("ScreenGui", { Name = "Onyx's FarmUI", ResetOnSpawn = false, DisplayOrder = 999, IgnoreGuiInset = true }, GuiParent)
local Main = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 40), Size = UDim2.fromOffset(300, 0),
    AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Bg, BorderSizePixel = 0, ClipsDescendants = true,
}, Gui)
round(Main, 12) stroke(Main) list(Main)

-- Dragging (one shared handler for the window and the sliders)
local drag
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local conns = {
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then drag(i.Position) end
    end),
    UIS.InputEnded:Connect(function(i) if isPress(i) then drag = nil end end),
    UIS.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == Enum.KeyCode.RightShift then Main.Visible = not Main.Visible end
    end),
}

-- Header
local Header = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, Main)
new("UIGradient", { Color = ColorSequence.new(C.Accent, Color3.fromRGB(255, 140, 60)) },
    new("Frame", { Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0 }, Header))
lbl(Header, "Throw Food For Animals", 14, C.Text, UDim2.fromOffset(14, 8), UDim2.new(1, -100, 0, 18), { Font = Enum.Font.GothamBold })
lbl(Header, "discord.gg/Soon not yet", 11, C.Accent, UDim2.fromOffset(14, 26), UDim2.new(1, -100, 0, 14))

local function hbtn(txt, x)
    local b = new("TextButton", {
        Text = txt, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.Sub, Size = UDim2.fromOffset(28, 28),
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 1), BackgroundColor3 = C.Card, AutoButtonColor = false,
    }, Header)
    round(b, 8)
    return b
end
local MinBtn, CloseBtn = hbtn("–", -46), hbtn("×", -12)

Header.InputBegan:Connect(function(i)
    if isPress(i) then
        local start, pos = i.Position, Main.Position
        drag = function(p)
            local d = p - start
            Main.Position = UDim2.new(pos.X.Scale, pos.X.Offset + d.X, pos.Y.Scale, pos.Y.Offset + d.Y)
        end
    end
end)

-- Body + tabs
local Body = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, Main)
local P = UDim.new(0, 12)
new("UIPadding", { PaddingTop = P, PaddingBottom = P, PaddingLeft = P, PaddingRight = P }, Body)
list(Body, 8)

local Tabs = new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, Body)
list(Tabs, 8, true)
local pages, tabBtns, showTab = {}, {}, nil

local function newTab(name, order)
    local b = new("TextButton", {
        Size = UDim2.new(0.5, -4, 1, 0), Text = name, Font = Enum.Font.GothamBold, TextSize = 13,
        BorderSizePixel = 0, AutoButtonColor = false, LayoutOrder = order,
    }, Tabs)
    round(b, 8)
    b.MouseButton1Click:Connect(function() showTab(name) end)
    local p = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1 }, Body)
    list(p, 8)
    tabBtns[name], pages[name] = b, p
    return p
end

showTab = function(name)
    for n, p in pairs(pages) do
        p.Visible = n == name
        tween(tabBtns[n], { BackgroundColor3 = n == name and C.Accent or C.Card, TextColor3 = n == name and C.Text or C.Sub })
    end
end

local Farm, Upgrades = newTab("Farm", 1), newTab("Upgrades", 2)

local function toggle(parent, order, title, sub)
    local c = card(parent, 52, true)
    c.LayoutOrder = order
    lbl(c, title, 14, C.Text, UDim2.fromOffset(12, 9), UDim2.new(1, -80, 0, 18), { Font = Enum.Font.GothamBold })
    local s = lbl(c, sub, 12, C.Sub, UDim2.fromOffset(12, 28), UDim2.new(1, -80, 0, 16), { TextTruncate = Enum.TextTruncate.AtEnd })
    local sw = new("Frame", {
        Size = UDim2.fromOffset(44, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
        BackgroundColor3 = C.Off, BorderSizePixel = 0,
    }, c)
    round(sw, 12)
    local k = new("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = C.Text, BorderSizePixel = 0 }, sw)
    round(k, 9)
    return c, s, function(on)
        tween(sw, { BackgroundColor3 = on and C.Accent or C.Off })
        tween(k, { Position = UDim2.fromOffset(on and 23 or 3, 3) })
    end
end

--// Farm page
local Stats = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 1 }, Farm)
list(Stats, 8, true)
local function stat(title, order)
    local c = card(Stats, 52)
    c.Size, c.LayoutOrder = UDim2.new(1 / 3, -6, 1, 0), order
    lbl(c, title, 10, C.Sub, UDim2.fromOffset(8, 8), UDim2.new(1, -12, 0, 12))
    return lbl(c, "-", 15, C.Text, UDim2.fromOffset(8, 24), UDim2.new(1, -12, 0, 20),
        { Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd })
end
local Money, Stand, Thrown = stat("MONEY", 1), stat("STAND", 2), stat("THROWN", 3)

local FarmBtn, FarmSub, setFarmSw = toggle(Farm, 2, "Autofarm", "Idle")

local function slider(parent, order, name, min, max, key, fmt)
    local c = card(parent, 54)
    c.LayoutOrder = order
    lbl(c, name, 13, C.Text, UDim2.fromOffset(12, 8), UDim2.new(0.5, -12, 0, 16))
    local val = lbl(c, "", 13, C.Accent, UDim2.new(0.5, 0, 0, 8), UDim2.new(0.5, -12, 0, 16),
        { Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right })
    local track = new("Frame", { Size = UDim2.new(1, -24, 0, 6), Position = UDim2.fromOffset(12, 36), BackgroundColor3 = C.Off, BorderSizePixel = 0 }, c)
    round(track, 3)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, track)
    round(fill, 3)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.Text, BorderSizePixel = 0, ZIndex = 2,
    }, track)
    round(knob, 8)

    local function set(v)
        v = math.clamp(math.floor(v + 0.5), min, max)
        local a = (v - min) / (max - min)
        fill.Size, knob.Position = UDim2.fromScale(a, 1), UDim2.fromScale(a, 0.5)
        val.Text = fmt(v)
        AutofarmData[key] = v
    end
    local function fromX(x)
        set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
    end

    local hit = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 24), ZIndex = 3 }, c)
    hit.InputBegan:Connect(function(i)
        if isPress(i) then
            drag = function(p) fromX(p.X) end
            fromX(i.Position.X)
        end
    end)
    set(tonumber(AutofarmData[key]) or min)
end

slider(Farm, 3, "Throws per cycle", 1, 100, "ThrowAmt", tostring)
slider(Farm, 4, "Training time", 5, 1800, "PowerTime", function(v)
    return v >= 60 and string.format("%dm %02ds", v // 60, v % 60) or v .. "s"
end)

--// Upgrades page
local StandBtn, StandSub, setStandSw = toggle(Upgrades, 1, "Auto Stand Upgrade", "Checking...")
local FoodBtn, FoodSub, setFoodSw = toggle(Upgrades, 2, "Auto Buy Food", "Checking...")
lbl(Upgrades, "Only buys when a toggle is on and you have enough money.", 11, C.Sub, UDim2.new(), UDim2.new(1, 0, 0, 16), { LayoutOrder = 3 })

for _, t in ipairs({ { StandBtn, "AutoStand", setStandSw }, { FoodBtn, "AutoFood", setFoodSw } }) do
    t[1].MouseButton1Click:Connect(function()
        AutofarmData[t[2]] = not AutofarmData[t[2]]
        t[3](AutofarmData[t[2]])
    end)
    t[3](AutofarmData[t[2]])
end

--// Upgrade logic (only buys if a toggle is on AND money >= price)
local function getInfo()
    local money = DataController:Get("Money")
    local owned = 0
    for i = 1, FoodsConfig.Count() do
        if DataController:GetPath("OwnedFoods." .. i) == true then owned = i end
    end
    local info = { money = money }
    for i = owned + 1, FoodsConfig.Count() do
        local f = FoodsConfig.Get(i)
        local p = BalanceCurve.GetItemPrice(Plr, f)
        if p > 0 then
            info.nextFood = info.nextFood or p
            if p <= money then info.food, info.foodPrice = f, p end -- highest affordable food
        end
    end
    local nextStand = StandsConfig.Get(DataController:Get("Stand") + 1)
    info.standPrice = nextStand and BalanceCurve.GetItemPrice(Plr, nextStand)
    return info
end

local function buyUpgrades(info)
    local stand = AutofarmData.AutoStand and info.standPrice and info.money >= info.standPrice
    local food = AutofarmData.AutoFood and info.food
    if stand and (not food or info.standPrice >= info.foodPrice) then
        R("Stand_Upgrade"):InvokeServer()
    elseif food then
        R("Shop_Buy"):InvokeServer(info.food.Index)
    end
end

local buying = false
local function tryBuy(info)
    if buying then return end
    buying = true
    task.spawn(function()
        pcall(buyUpgrades, info)
        buying = false
    end)
end

local function show(sub, price, money, none)
    if not price then
        sub.Text, sub.TextColor3 = none, C.Sub
    elseif money >= price then
        sub.Text, sub.TextColor3 = "$" .. short(price) .. " · Affordable", C.Good
    else
        sub.Text, sub.TextColor3 = "$" .. short(price) .. " · Need $" .. short(price - money), C.Sub
    end
end

--// Farm logic (no upgrading in here)
local thrown, running = 0, false
local function setStatus(t) FarmSub.Text = AutofarmData.Enabled and t or "Idle" end

local function cycle()
    -- Throw
    local n = 0
    while n < AutofarmData.ThrowAmt and AutofarmData.Enabled do
        setStatus(("Throwing %d/%d"):format(n + 1, AutofarmData.ThrowAmt))
        Plr.Character:MoveTo(StartThrowPos)
        task.wait(0.5)
        local startthrow = R("Throw_Start"):InvokeServer()
        if not startthrow.Ok then
            setStatus("Throw rejected, retrying")
            task.wait(0.25)
            continue
        end
        task.wait()
        R("Throw_MeterStarted"):FireServer()
        task.wait()
        R("Throw_Resolve"):InvokeServer(1)
        task.wait()
        R("Throw_Complete"):InvokeServer()
        n += 1
        thrown += 1
        task.wait()
    end
    if not AutofarmData.Enabled then return end

    -- Equip best
    setStatus("Equipping best")
    R("Plot_EquipBest"):InvokeServer()
    task.wait()

    -- Train
    Plr.Character:MoveTo(Plot:WaitForChild("Server"):WaitForChild("PullUpStand"):GetPivot().Position)
    for t = AutofarmData.PowerTime, 1, -1 do
        if not AutofarmData.Enabled then break end
        setStatus("Training " .. t .. "s")
        task.wait(1)
    end
    R("Training_Stop"):InvokeServer()
    task.wait(0.5)
end

local function setEnabled(on)
    AutofarmData.Enabled = on
    setFarmSw(on)
    tween(FarmSub, { TextColor3 = on and C.Good or C.Sub })
    setStatus("Starting...")
    if on and not running then
        running = true
        task.spawn(function()
            while AutofarmData.Enabled do
                local ok, err = pcall(cycle)
                if not ok then
                    warn("[Vaehz Farm] " .. tostring(err))
                    task.wait(1)
                end
            end
            running = false
            setStatus("Idle")
        end)
    end
end

FarmBtn.MouseButton1Click:Connect(function() setEnabled(not AutofarmData.Enabled) end)

MinBtn.MouseButton1Click:Connect(function()
    Body.Visible = not Body.Visible
    MinBtn.Text = Body.Visible and "–" or "+"
end)

CloseBtn.MouseButton1Click:Connect(function()
    AutofarmData.Enabled = false
    pcall(writefile, FILE, HttpService:JSONEncode(AutofarmData))
    for _, c in ipairs(conns) do c:Disconnect() end
    Gui:Destroy()
end)

--// Background loop: counters, upgrade labels, upgrades (only if a toggle is on), autosave
task.spawn(function()
    local n = 0
    while Gui.Parent do
        pcall(function()
            Money.Text = "$" .. short(DataController:Get("Money"))
            Stand.Text = tostring(DataController:Get("Stand"))
        end)
        Thrown.Text = tostring(thrown)

        local ok, info = pcall(getInfo)
        if ok then
            pcall(function()
                show(StandSub, info.standPrice, info.money, "Maxed out")
                show(FoodSub, info.foodPrice or info.nextFood, info.money, "Nothing left to buy")
            end)
            if (AutofarmData.AutoStand or AutofarmData.AutoFood) and n % 2 == 0 then
                tryBuy(info)
            end
        end

        if n % 4 == 0 then pcall(writefile, FILE, HttpService:JSONEncode(AutofarmData)) end
        n += 1
        task.wait(0.5)
    end
end)

task.spawn(function()
    R("Training_Bonus").OnClientEvent:Connect(function(this)
        R("Training_TapBonus"):InvokeServer(this)
    end)
end)

--// Start
showTab("Farm")
setEnabled(AutofarmData.Enabled)
