local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Interface = import("rbxassetid://11389137937")

if oh.Cache["ui/main"] then
	return Interface
end

import("ui/controls/TabSelector")
local MessageBox, MessageType = import("ui/controls/MessageBox")

local RemoteSpy
local ClosureSpy
local ScriptScanner
local ModuleScanner
local UpvalueScanner
local ConstantScanner

xpcall(function()
	RemoteSpy = import("ui/modules/RemoteSpy")
	ClosureSpy = import("ui/modules/ClosureSpy")
	ScriptScanner = import("ui/modules/ScriptScanner")
	ModuleScanner = import("ui/modules/ModuleScanner")
	UpvalueScanner = import("ui/modules/UpvalueScanner")
	ConstantScanner = import("ui/modules/ConstantScanner")
end, function(err)
	err = tostring(err)

	local message
	if err:find("valid member") then
		message = "The UI has updated, please rejoin and restart. If you get this message more than once, screenshot this message and report it in the Hydroxide server.\n\n" .. err
	else
		message = "Report this error in Hydroxide's server:\n\n" .. err
	end

	MessageBox.Show("An error has occurred", message, MessageType.OK, function()
		Interface:Destroy() 
	end)
end)

local constants = {
	opened = UDim2.new(0.5, -325, 0.5, -175),
	closed = UDim2.new(0.5, -325, 0, -400),
	reveal = UDim2.new(0.5, -15, 0, 20),
	conceal = UDim2.new(0.5, -15, 0, -75)
}

local Open = Interface.Open
local Base = Interface.Base
local Drag = Base.Drag
local Status = Base.Status
local Collapse = Drag.Collapse

function oh.setStatus(text)
	Status.Text = '• Status: ' .. tostring(text)
end

function oh.getStatus()
	return (Status.Text:gsub('• Status: ', ''))
end

local dragging
local dragInput
local dragStart
local startPos

local function isDragInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

Drag.InputBegan:Connect(function(input)
	if isDragInput(input) then
		local dragEnded

		dragging = true
		dragInput = input
		dragStart = input.Position
		startPos = Base.Position

		dragEnded = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
				dragEnded:Disconnect()
			end
		end)
	end
end)

oh.Events.Drag = UserInput.InputChanged:Connect(function(input)
	local isMove = input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput

	if dragging and isMove then
		local delta = input.Position - dragStart
		local viewport = Interface.AbsoluteSize
		local size = Base.AbsoluteSize
		local anchor = Vector2.new(startPos.X.Scale * viewport.X, startPos.Y.Scale * viewport.Y)

		-- keep at least part of the title bar reachable so the window can't be lost off-screen
		local x = math.clamp(startPos.X.Offset + delta.X, -anchor.X - size.X + 60, viewport.X - anchor.X - 60)
		local y = math.clamp(startPos.Y.Offset + delta.Y, -anchor.Y, viewport.Y - anchor.Y - 30)

		Base.Position = UDim2.new(startPos.X.Scale, x, startPos.Y.Scale, y)
	end
end)

local opened = true
-- change at runtime with oh.ToggleKey = Enum.KeyCode.<key>
oh.ToggleKey = oh.ToggleKey or Enum.KeyCode.RightShift

local function setOpened(open)
	opened = open

	if open then
		Open:TweenPosition(constants.conceal, "Out", "Quad", 0.15, true)
		Base:TweenPosition(constants.opened, "Out", "Quad", 0.15, true)
	else
		Base:TweenPosition(constants.closed, "Out", "Quad", 0.15, true)
		Open:TweenPosition(constants.reveal, "Out", "Quad", 0.15, true)
	end
end

Open.MouseButton1Click:Connect(function()
	setOpened(true)
end)

Collapse.MouseButton1Click:Connect(function()
	setOpened(false)
end)

-- toggle the window without having to find the open button
oh.Events.ToggleKey = UserInput.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == oh.ToggleKey then
		setOpened(not opened)
	end
end)

Interface.Name = HttpService:GenerateGUID(false)
if getHui then
	Interface.Parent = getHui()
else
	if syn then
		syn.protect_gui(Interface)
	end

	Interface.Parent = CoreGui
end

return Interface
