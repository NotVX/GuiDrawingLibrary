local user_input_service = game:GetService("UserInputService")
local gui_service = game:GetService("GuiService")
local run_service = game:GetService("RunService")

local vector2_new = Vector2.new
local table_insert = table.insert
local task_wait = task.wait
local task_spawn = task.spawn
local task_cancel = task.cancel
local string_format = string.format

local screen_resoltuion = gui_service:GetScreenResolution()

local drawing_new = Drawing.new

local GuiModule = {}
GuiModule.__index = GuiModule

local function drawing(class, props)
    local object = drawing_new(class)
    for i, v in pairs(props) do
        object[i] = v
    end
    return object
end
local function is_mouse_over(obj)
	local posX, posY = obj.Position.X, obj.Position.Y
	local sizeX, sizeY = posX + obj.Size.X, posY + obj.Size.Y
	local mousepos = user_input_service:GetMouseLocation()

	if mousepos.X >= posX and mousepos.Y >= posY and mousepos.X <= sizeX and mousepos.Y <= sizeY then
		return true, mousepos
	end
	
	return false, mousepos
end
local function get_render_objects(tab)
    local render_objects = {}
    for i, v in pairs(tab) do
        if type(v) == "table" then
            local metatable = getmetatable(v)

            if metatable and type(metatable.__type) == "string" then
                render_objects[i] = v
            end

            if v ~= tab then -- to avoid overflow (my retardness hits here)
                get_render_objects(v)
            end
        end
    end

    return render_objects
end

function GuiModule.new(gui_name, gui_size, keybind, font)
    local gui = {}
    local input_began = nil

    gui.__index = gui
    gui.Keybind = keybind or Enum.KeyCode.F5

    gui.Background = drawing("Square", {
        Visible = true,
        ZIndex = 1,
        Color = Color3.fromRGB(33, 33, 33),
        Filled = true,
        Size = gui_size,
        Thickness = 1,
        Position = vector2_new(100, 100)
    })

    gui.TitleBackground = drawing("Square", {
        Visible = true,
        ZIndex = 1,
        Color = Color3.fromRGB(22, 22, 22),
        Filled = true,
        Thickness = 1,
        Size = vector2_new(gui.Background.Size.X, 20)
    })
    gui.TitleBackground.Position = gui.Background.Position + vector2_new(0, -gui.TitleBackground.Size.Y)

    gui.TitleText = drawing("Text", {
        Visible = true,
        ZIndex = 3,
        Color = Color3.fromRGB(255, 255, 255),
        Center = true,
        Font = font or Drawing.Fonts.UI,
        Text = gui_name,
        Size = 15
    })
    gui.TitleText.Position = gui.TitleBackground.Position + vector2_new(gui.TitleBackground.Size.X / 2, gui.TitleBackground.Size.Y / gui.TitleText.Size)

    function gui:Remove()
        input_began:Disconnect()
        for i, v in pairs(self) do
            if type(v) == "table" then
                local metatable = getmetatable(v)
                if metatable and type(metatable.__type) == "string" then
                    v:Remove()
                end
            end
        end
    end

    function gui:AddButton(name, text, object_position)
        local button = setmetatable({}, {
            __type = "Button",
            __event = Instance.new("BindableEvent"),
            __newindex = function(tab, key, value)
                if key == "Visible" then
                    tab.Background.Visible = not tab.Background.Visible
                    tab.TextLabel.Visible = tab.Background.Visible
                else
                    rawset(tab, key, value)
                end
            end,
            __index = function(tab, key)
                if key == "Visible" then
                    return tab.Background.Visible
                else
                    return rawget(tab, key)
                end
            end
        })
        self[name] = button

        button.Clicked = getmetatable(button).__event.Event

        local position = self.Background.Position + object_position
        
        button.Background = drawing("Square", {
            Visible = true,
            ZIndex = 2,
            Color = Color3.fromRGB(55, 55, 55),
            Filled = true,
            Size = vector2_new(125, 25),
            Thickness = 1,
            Position = position
        })

        button.TextLabel = drawing("Text", {
            Visible = true,
            ZIndex = 3,
            Color = Color3.fromRGB(255, 255, 255),
            Center = true,
            Font = font or Drawing.Fonts.UI,
            Text = text,
            Size = 20
        })
        button.TextLabel.Position = position + vector2_new(button.Background.Size.X / 2, (button.TextLabel.Size / 2) - (button.Background.Size.Y / 2.5))

        function button:Remove()
            for i, v in pairs(self) do
                if type(v) == "table" then
                    local metatable = getmetatable(v)
                    if metatable and type(metatable.__type) == "string" then
                        v:Remove()
                    end
                end
            end
        end

        return button
    end

    function gui:Notification(text, wait_time, border_size)
        local notification = setmetatable({}, {
            __type = "Notification",
            __index = function(tab, key)
                if key == "Position" then
                    return tab.Background.Position
                else
                    return rawget(tab, key)
                end
            end,
            __newindex = function(tab, key, value)
                if key == "Position" then
                    tab.Background.Position = value
                    tab.Outline.Position = value
                    tab.TextLabel.Position = value + vector2_new(tab.TextLabel.TextBounds.X / 2, tab.TextLabel.TextBounds.Y / (tab.TextLabel.Size / 2))
                else
                    rawset(tab, key, value)
                end
            end
        })
        local offset = 20
        local notification_size = vector2_new(300, 20)

        function notification:Remove()
            for i, v in pairs(self) do
                if type(v) == "table" then
                    local metatable = getmetatable(v)
                    if metatable and type(metatable.__type) == "string" then
                        v:Remove()
                    end
                end
            end
        end

        notification.Background = drawing("Square", {
            Visible = true,
            ZIndex = 2,
            Color = Color3.fromRGB(45, 45, 45),
            Filled = true,
            Size = notification_size,
            Thickness = 1
        })
        notification.Outline = drawing("Square", {
            Visible = true,
            ZIndex = 1,
            Color = Color3.fromRGB(3, 252, 198),
            Filled = true,
            Size = notification_size + vector2_new(border_size, border_size),
            Thickness = 1
        })
        notification.TextLabel = drawing("Text", {
            Visible = true,
            ZIndex = 3,
            Color = Color3.fromRGB(255, 255, 255),
            Center = true,
            Font = Drawing.Fonts.System,
            Text = text
        })
        notification.TextLabel.Size = math.floor( (notification.Background.Size.X / text:len()) + (notification.TextLabel.TextBounds.X / text:len()))

        local num = 0
        for i, v in pairs(self) do
            if tostring(i):lower():match("notification") then
                num = num + 1
            end
        end
        local name = string_format("Notification%d", num)

        task_spawn(function()
            local delta = notification.Background.Size.X / offset

            notification.Position = vector2_new(screen_resoltuion.X, screen_resoltuion.Y - 50)
            for i = 1, offset do
                notification.Position = notification.Position - vector2_new(delta, 0)
                task_wait()
            end
            wait(wait_time)
            for i = 1, offset do
                notification.Position = notification.Position - vector2_new(0, i)
                task_wait()
            end
            wait(0.5)
            for i = 1, offset do
                notification.Position = notification.Position + vector2_new(i, 0)
                task_wait()
            end
            
            notification:Remove()
        end)
    end

    input_began = user_input_service.InputBegan:Connect(function(key_input)
        if key_input.UserInputType == Enum.UserInputType.MouseButton1 then

            for i, v in pairs(gui) do
                if type(v) == "table" then
                    local metatable = getmetatable(v)
                    if metatable and type(metatable.__type) == "string" and metatable.__type == "Button" then
                        if is_mouse_over(v.Background) and v.Visible then
                            metatable.__event:Fire()
                        end
                    end
                end
            end
        elseif key_input.KeyCode == gui.Keybind then
            local objects = get_render_objects(gui)

            for i, v in pairs(objects) do
                v.Visible = not v.Visible
            end
        end
    end)

    return gui
end

return GuiModule
