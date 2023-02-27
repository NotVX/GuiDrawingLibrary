local user_input_service = game:GetService("UserInputService")

local vector2_new = Vector2.new
local table_insert = table.insert
local task_wait = task.wait
local task_spawn = task.spawn
local task_cancel = task.cancel

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

            if v ~= tab then
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

    local _background = drawing("Square", {
        Visible = true,
        ZIndex = 1,
        Color = Color3.fromRGB(33, 33, 33),
        Filled = true,
        Size = gui_size, -- 300x300
        Thickness = 1,
        Position = vector2_new(100, 100)
    })
    gui.Background = _background

    local _title_background = drawing("Square", {
        Visible = true,
        ZIndex = 1,
        Color = Color3.fromRGB(22, 22, 22),
        Filled = true,
        Thickness = 1,
        Size = vector2_new(_background.Size.X, 20)
    })
    _title_background.Position = _background.Position + vector2_new(0, -_title_background.Size.Y)
    gui.TitleBackground = _title_background

    local _title_text = drawing("Text", {
        Visible = true,
        ZIndex = 3,
        Color = Color3.fromRGB(255, 255, 255),
        Center = true,
        Font = font or Drawing.Fonts.UI,
        Text = gui_name,
        Size = 15
    })
    _title_text.Position = _title_background.Position + vector2_new(_title_background.Size.X / 2, _title_background.Size.Y / _title_text.Size)
    gui.TitleText = _title_text

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
            __index = button,
            __type = "Button",
            __newindex = function(tab, key, value)
                if key == "Visible" then
                    tab.objects.Background.Visible = not tab.objects.Background.Visible
                    tab.objects.TextLabel.Visible = tab.objects.Background.Visible
                else
                    rawset(tab, key, value)
                end
            end
        })
        button.objects = {}
        button.event = Instance.new("BindableEvent")
        self[name] = button

        local position = self.Background.Position + object_position
        
        local button_background = drawing("Square", {
            Visible = true,
            ZIndex = 2,
            Color = Color3.fromRGB(55, 55, 55),
            Filled = true,
            Size = vector2_new(125, 25),
            Thickness = 1,
            Position = position
        })
        button.objects.Background = button_background
        local button_text = drawing("Text", {
            Visible = true,
            ZIndex = 3,
            Color = Color3.fromRGB(255, 255, 255),
            Center = true,
            Font = font or Drawing.Fonts.UI,
            Text = text,
            Size = 20
        })
        button_text.Position = position + vector2_new(button_background.Size.X / 2, (button_text.Size / 2) - (button_background.Size.Y / 2.5))
        button.objects.TextLabel = button_text

        function button:Remove()
            for i, v in pairs(self.objects) do
                v:Remove()
            end
        end

        button.Clicked = button.event.Event

        return button
    end

    input_began = user_input_service.InputBegan:Connect(function(key_input)
        if key_input.UserInputType == Enum.UserInputType.MouseButton1 then
            for i, v in pairs(gui) do -- Checking if mouse is hovering over button when mouseLbutton is down
                if type(v) == "table" then
                    local metatable = getmetatable(v)
                    if metatable and type(metatable.__type) == "string" and metatable.__type == "Button" then
                        if is_mouse_over(v.objects.Background) then
                            v.event:Fire()
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
