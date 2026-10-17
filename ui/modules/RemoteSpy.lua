local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local RemoteSpy = {}
local Methods = import("modules/RemoteSpy")
local ClosureSpy = import("modules/ClosureSpy")
local Closure = import("objects/Closure")

if not hasMethods(Methods.RequiredMethods) then
    return RemoteSpy
end

local Prompt = import("ui/controls/Prompt")
local CheckBox = import("ui/controls/CheckBox")
local Dropdown = import("ui/controls/Dropdown")
local List, ListButton = import("ui/controls/List")
local MessageBox, MessageType = import("ui/controls/MessageBox")
local ContextMenu, ContextMenuButton = import("ui/controls/ContextMenu")
local TabSelector = import("ui/controls/TabSelector")

local Base = import("rbxassetid://11389137937").Base
local Assets = import("rbxassetid://5042114982").RemoteSpy

local Prompts = Base.Prompts
local Page = Base.Body.Pages.RemoteSpy

local RemoteList = Page.List
local ListFlags = RemoteList.Flags
local ListQuery = RemoteList.Query
local ListSearch = ListQuery.Search
local ListRefresh = ListQuery.Refresh
local ListResults = RemoteList.Results.Clip.Content

local RemoteLogs = Page.Logs
local LogsButtons = RemoteLogs.Buttons
local LogsRemote = RemoteLogs.RemoteObject
local LogsBack = RemoteLogs.Back
local LogsResults = RemoteLogs.Results.Clip.Content

local RemoteConditions = Page.Conditions
local ConditionsRemote = RemoteConditions.RemoteObject
local ConditionsButtons = RemoteConditions.Buttons
local ConditionsResults = RemoteConditions.Results.Clip.Content
local ConditionsBack = RemoteConditions.Back

local NewRemoteCondition = Prompts.NewRemoteCondition
local NewConditionInner = NewRemoteCondition.Inner
local NewConditionButtons = NewConditionInner.Buttons
local NewConditionContent = NewConditionInner.Content
local NewConditionIndex = NewConditionContent.Index

local remotesViewing = Methods.RemotesViewing
local currentRemotes = Methods.CurrentRemotes

local icons = {
    type = "rbxassetid://4702850565",
    status = "rbxassetid://4909102841",
    valueType = "rbxassetid://4702850565",
    block = "rbxassetid://4891641806",
    unblock = "rbxassetid://4891642508",
    ignore = "rbxassetid://4842578510",
    unignore = "rbxassetid://4842578818",
    RemoteEvent = "rbxassetid://4229806545",
    UnreliableRemoteEvent = "rbxassetid://4229806545",
    RemoteFunction = "rbxassetid://4229810474",
    BindableEvent = "rbxassetid://4229809371",
    BindableFunction = "rbxassetid://4229807624"
}

local constants = {
    fadeLength = TweenInfo.new(0.15),
    textWidth = Vector2.new(1337420, 20),
    normalColor = Color3.new(1, 1, 1),
    blockedColor = Color3.fromRGB(170, 0, 0),
    ignoredColor = Color3.fromRGB(100, 100, 100)
}

local newRemoteCondition = Prompt.new(NewRemoteCondition)
local conditionStatus = Dropdown.new(NewConditionContent.Status)
local conditionType = Dropdown.new(NewConditionContent.Type)
local conditionValueType = Dropdown.new(NewConditionContent.ValueType)

local remoteList = List.new(ListResults, true)
local remoteLogs = List.new(LogsResults)
local remoteConditions = List.new(ConditionsResults, true)

local currentLogs = {}

local selected = {
    logs = {},
    conditions = {}
}

local pathContext = ContextMenuButton.new("rbxassetid://4891705738", "Get Remote Path")
local conditionContext = ContextMenuButton.new("rbxassetid://4891633802", "Call Conditions")
local clearContext = ContextMenuButton.new("rbxassetid://4892169181", "Clear Calls")
local ignoreContext = ContextMenuButton.new("rbxassetid://4842578510", "Ignore Calls")
local blockContext = ContextMenuButton.new("rbxassetid://4891641806", "Block Calls")
local removeContext = ContextMenuButton.new("rbxassetid://4702831188", "Remove Log")
local clearAllContext = ContextMenuButton.new("rbxassetid://4892169181", "Clear All Calls")
local removeAllContext = ContextMenuButton.new("rbxassetid://4702831188", "Remove All Logs")

local scriptContext = ContextMenuButton.new("rbxassetid://4800244808", "Generate Script")
local copyArgsContext = ContextMenuButton.new("rbxassetid://4891705738", "Copy Arguments")
local callingScriptContext = ContextMenuButton.new("rbxassetid://4800244808", "Get Calling Script")
local spyClosureContext = ContextMenuButton.new("rbxassetid://4666593447", "Spy Calling Function")
local repeatCallContext = ContextMenuButton.new("rbxassetid://4907151581", "Repeat Call")
local viewAsHexContext = ContextMenuButton.new("rbxassetid://9058292613", "Toggle String Hex View")

local removeConditionContext = ContextMenuButton.new("rbxassetid://4702831188", "Remove Condition")

local pathContextSelected = ContextMenuButton.new("rbxassetid://4891705738", "Get Paths")
local clearContextSelected = ContextMenuButton.new("rbxassetid://4892169181", "Clear Calls")
local ignoreContextSelected = ContextMenuButton.new("rbxassetid://4842578510", "Ignore Calls")
local blockContextSelected = ContextMenuButton.new("rbxassetid://4891641806", "Block Calls")
local unignoreContextSelected = ContextMenuButton.new("rbxassetid://4842578818", "Unignore Calls")
local unblockContextSelected = ContextMenuButton.new("rbxassetid://4891642508", "Unblock Calls")
local removeContextSelected = ContextMenuButton.new("rbxassetid://4702831188", "Remove Logs")

local removeConditionContextSelected = ContextMenuButton.new("rbxassetid://4702831188", "Remove Conditions")

local remoteListMenu = ContextMenu.new({ pathContext, conditionContext, clearContext, ignoreContext, blockContext, removeContext, clearAllContext, removeAllContext })
local remoteListMenuSelected = ContextMenu.new({ pathContextSelected, clearContextSelected, ignoreContextSelected, unignoreContextSelected, blockContextSelected, unblockContextSelected, removeContextSelected })
local remoteLogsMenu = ContextMenu.new({ scriptContext, copyArgsContext, callingScriptContext, spyClosureContext, repeatCallContext, viewAsHexContext })
local remoteConditionMenu = ContextMenu.new({ removeConditionContext })
local remoteConditionMenuSelected = ContextMenu.new({ removeConditionContextSelected })

-- these only update the buttons on the logs page, so they're a no-op until a remote is opened
local function checkCurrentIgnored()
    if not selected.remoteLog then
        return
    end

    local selectedRemote = selected.remoteLog.Remote

    LogsButtons.Ignore.Label.Text = (selectedRemote.Ignored and "Unignore") or "Ignore"
    LogsButtons.Ignore.Icon.Image = (selectedRemote.Ignored and icons.unignore) or icons.ignore

    local newWidth = TextService:GetTextSize((selectedRemote.Ignored and "Unignore") or "Ignore", 18, "SourceSans", constants.textWidth).X + 30

    LogsButtons.Ignore.Size = UDim2.new(0, newWidth, 0, 20)
end

local function checkCurrentBlocked()
    if not selected.remoteLog then
        return
    end

    local selectedRemote = selected.remoteLog.Remote

    LogsButtons.Block.Label.Text = (selectedRemote.Blocked and "Unblock") or "Block"
    LogsButtons.Block.Icon.Image = (selectedRemote.Blocked and icons.unblock) or icons.block

    local newWidth = TextService:GetTextSize((selectedRemote.Blocked and "Unblock") or "Block", 18, "SourceSans", constants.textWidth).X + 30

    LogsButtons.Block.Size = UDim2.new(0, newWidth, 0, 20)
end

local Condition = {}
function Condition.new(remote, status, index, value, type)
    local condition = {}
    local instance = Assets.ConditionPod:Clone() 
    local content = instance.Content
    local identifiers = instance.Identifiers
    local button = ListButton.new(instance, remoteConditions)
    local check = CheckBox.new(content.Toggle)
    local valueType = type or typeof(value)
    local typeIcons = oh.Constants.Types
    local branch = (status == "Ignore" and remote.IgnoredArgs[index]) or remote.BlockedArgs[index]

    condition.Branch = branch
    condition.Status = status
    condition.Index = index
    condition.Value = value
    condition.Type = type
    condition.Remote = remote
    condition.Enabled = true
    condition.Instance = instance
    condition.Button = button
    condition.Toggle = Condition.toggle
    condition.Remove = Condition.remove

    check:SetCallback(function()
        condition:Toggle()
    end)

    button:SetRightCallback(function()
        selected.condition = condition
    end)

    button:SetSelectedCallback(function()
        if not table.find(selected.conditions, condition) then
            table.insert(selected.conditions, condition)
        end
    end)

    identifiers.ByType.Visible = type ~= nil
    identifiers.Status.Image = (status == "Ignore" and icons.ignore) or icons.block
    identifiers.Status.Border.Image = identifiers.Status.Image

    content.Index.Text = index
    content.Label.Text = (type and valueType) or toString(value)
    content.Label.TextColor3 = oh.Constants.Syntax[valueType] or oh.Constants.Syntax["userdata"]
    content.Type.Image = typeIcons[valueType] or typeIcons["userdata"]

    return condition
end

function Condition.toggle(condition)
    condition.Enabled = not condition.Enabled

    local branch = condition.Branch

    -- check Type rather than Value, since false is a valid value condition
    if condition.Type == nil then
        branch.values[condition.Value] = condition.Enabled or nil
    else
        branch.types[condition.Type] = condition.Enabled or nil
    end
end

function Condition.remove(condition)
    local branch = condition.Branch
    condition.Button:Remove()

    if condition.Type == nil then
        branch.values[condition.Value] = nil
    else
        branch.types[condition.Type] = nil
    end
end

local function createConditions(remote)
    remoteConditions:Clear()

    RemoteList.Visible = false
    RemoteLogs.Visible = false
    RemoteConditions.Visible = true

    local remoteInstance = remote.Instance
    local remoteInstanceName = remoteInstance.Name
    local remoteClassName = remoteInstance.ClassName
    local nameLength = TextService:GetTextSize(remoteInstanceName, 18, "SourceSans", constants.textWidth).X + 20

    ConditionsRemote.Icon.Image = icons[remoteClassName]
    ConditionsRemote.Label.Text = remoteInstanceName
    ConditionsRemote.Label.Size = UDim2.new(0, nameLength, 0, 20)
    ConditionsRemote.Position = UDim2.new(1, -nameLength, 0, 0)

    for index, arg in pairs(remote.IgnoredArgs) do
        for type in pairs(arg.types) do
            Condition.new(remote, "Ignore", index, nil, type)
        end

        for value in pairs(arg.values) do
            Condition.new(remote, "Ignore", index, value)
        end
    end

    for index, arg in pairs(remote.BlockedArgs) do
        for type in pairs(arg.types) do
            Condition.new(remote, "Block", index, nil, type)
        end

        for value in pairs(arg.values) do
            Condition.new(remote, "Block", index, value)
        end
    end
end

remoteList:BindContextMenu(remoteListMenu)
remoteList:BindContextMenuSelected(remoteListMenuSelected)
remoteLogs:BindContextMenu(remoteLogsMenu)
remoteConditions:BindContextMenu(remoteConditionMenu)
remoteConditions:BindContextMenuSelected(remoteConditionMenuSelected)

-- Log Objects
local Log = {}
local ArgsLog = {}

local searchQuery = ""

local function refreshLog(log)
    local remoteInstance = log.Remote.Instance
    local visible = remotesViewing[remoteInstance.ClassName] and true or false

    if visible and searchQuery ~= "" then
        visible = remoteInstance.Name:lower():find(searchQuery, 1, true) ~= nil
    end

    log.Button.Instance.Visible = visible
end

function Log.new(remote)
    local log = {}
    local button = Assets.RemoteLog:Clone()
    local remoteInstance = remote.Instance
    local remoteInstanceName = remoteInstance.Name
    local remoteClassName = remoteInstance.ClassName
    local listButton = ListButton.new(button, remoteList)
    
    local normalAnimation = TweenService:Create(button.Label, constants.fadeLength, { TextColor3 = constants.normalColor })
    local blockAnimation = TweenService:Create(button.Label, constants.fadeLength, { TextColor3 = constants.blockedColor })
    local ignoreAnimation = TweenService:Create(button.Label, constants.fadeLength, { TextColor3 = constants.ignoredColor })

    button.Name = remoteInstanceName
    button.Label.Text = remoteInstanceName
    button.Icon.Image = icons[remoteClassName]

    local function viewLogs()
        remoteLogs:Clear()
        
        local nameLength = TextService:GetTextSize(remoteInstanceName, 18, "SourceSans", constants.textWidth).X + 20
        
        selected.remoteLog = log

        for _i, call in pairs(remote.Logs) do
            ArgsLog.new(log, call)
        end

        checkCurrentBlocked()
        checkCurrentIgnored()

        LogsRemote.Icon.Image = icons[remoteClassName]
        LogsRemote.Label.Text = remoteInstanceName
        LogsRemote.Label.Size = UDim2.new(0, nameLength, 0, 20)
        LogsRemote.Position = UDim2.new(1, -nameLength, 0, 0)

        remoteLogs:Recalculate()
    end

    local function showLogsPage()
        RemoteList.Visible = false
        RemoteLogs.Visible = true
    end

    listButton:SetCallback(function()
        if selected.remoteLog == log then
            return showLogsPage()
        end

        local function open()
            viewLogs()
            showLogsPage()
        end

        if #remote.Logs > 400 then
            MessageBox.Show("Warning",
                "This remote seems to have a lot of calls, opening this may cause your game to freeze for a few seconds.\n\nContinue?",
                MessageType.YesNo,
                open)
        else
            open()
        end
    end)

    listButton:SetRightCallback(function()
        ignoreContext:SetIcon((remote.Ignored and icons.unignore) or icons.ignore)
        ignoreContext:SetText((remote.Ignored and "Unignore Calls") or "Ignore Calls")
        blockContext:SetIcon((remote.Blocked and icons.unblock) or icons.block)
        blockContext:SetText((remote.Blocked and "Unblock Calls") or "Block Calls")

        selected.logContext = log
    end)

    listButton:SetSelectedCallback(function()
        if not table.find(selected.logs, log) then
            table.insert(selected.logs, log)
        end
    end)

    currentLogs[remoteInstance] = log

    log.Remote = remote
    log.Button = listButton
    log.BlockAnimation = blockAnimation
    log.IgnoreAnimation = ignoreAnimation
    log.NormalAnimation = normalAnimation
    log.Clear = Log.clear
    log.PlayBlock = Log.playBlock
    log.PlayIgnore = Log.playIgnore
    log.PlayNormal = Log.playNormal
    log.PlayStatus = Log.playStatus
    log.Adjust = Log.adjust
    log.IncrementCalls = Log.incrementCalls
    log.DecrementCalls = Log.decrementCalls
    log.Remove = Log.remove

    -- a remote that was ignored/blocked before its log was removed keeps that state
    if remote.Blocked or remote.Ignored then
        button.Label.TextColor3 = (remote.Blocked and constants.blockedColor) or constants.ignoredColor
    end

    log:Adjust()
    refreshLog(log)
    return log
end

local function createArg(instance, index, value)
    local arg = Assets.RemoteArg:Clone()
    local valueType = type(value)

    arg.Icon.Image = oh.Constants.Types[valueType]
    arg.Index.Text = index
    
    if valueType == "table" then
        arg.Label.Text = toString(value)
    else
        arg.Label.Text = dataToString(value)
    end
    
    arg.Label.TextColor3 = oh.Constants.Syntax[valueType]
    arg.Name = tostring(index)
    arg.Parent = instance.Contents

    return arg.AbsoluteSize.Y + 5
end

function ArgsLog.new(log, callInfo)
    local instance = Assets.CallPod:Clone()
    local args = callInfo.args

    if selected.remoteLog ~= log then
        instance.Visible = false
    end

    local button = ListButton.new(instance, remoteLogs)
    local height = 0
    local argCount = args.n or #args

    if argCount == 0 then
        height = height + createArg(instance, 1, nil)
    else
        for i = 1, argCount do
            height = height + createArg(instance, i, args[i])
        end
    end

    button:SetRightCallback(function()
        selected.args = callInfo.args
        selected.callingScript = callInfo.script
        selected.func = callInfo.func
        selected.callPodButton = button
    end)

    button.Instance.Size = button.Instance.Size + UDim2.new(0, 0, 0, height)

    return button 
end

function Log.playIgnore(log)
    log.IgnoreAnimation:Play()
end

function Log.playBlock(log)
    log.BlockAnimation:Play()
end

function Log.playNormal(log)
    log.NormalAnimation:Play()
end

-- picks the right color for the remote's current state (blocked takes priority)
function Log.playStatus(log)
    local remote = log.Remote

    if remote.Blocked then
        log:PlayBlock()
    elseif remote.Ignored then
        log:PlayIgnore()
    else
        log:PlayNormal()
    end
end

function Log.adjust(log)
    local remoteClassName = log.Remote.Instance.ClassName
    local logInstance = log.Button.Instance
    local logIcon = logInstance.Icon
    local isRemoteEvent = remoteClassName == "RemoteEvent" or remoteClassName == "UnreliableRemoteEvent"

    local callWidth = TextService:GetTextSize(logInstance.Calls.Text, 18, "SourceSans", constants.textWidth).X + 10
    local iconPosition = callWidth - (((isRemoteEvent or remoteClassName == "BindableEvent") and 4) or 0)
    local labelWidth = iconPosition + 21

    logInstance.Calls.Size = UDim2.new(0, callWidth, 1, 0)
    logIcon.Position = UDim2.new(0, iconPosition, 0.5, (isRemoteEvent and -9) or -7)
    logInstance.Label.Position = UDim2.new(0, labelWidth, 0, 0)
    logInstance.Label.Size = UDim2.new(1, -labelWidth, 1, 0)
end

function Log.clear(log)
    local logInstance = log.Button.Instance

    log.Remote:Clear()

    if selected.remoteLog == log then
        remoteLogs:Clear()
    end

    logInstance.Calls.Text = 0
    log:Adjust()
end

function Log.incrementCalls(log, callInfo)
    local buttonInstance = log.Button.Instance
    local remote = log.Remote
    local calls = remote.Calls

    buttonInstance.Calls.Text = (calls < 10000 and calls) or "..."

    log:Adjust()
    
    if selected.remoteLog == log then
        ArgsLog.new(log, callInfo)
        remoteLogs:Recalculate()
    end
end

function Log.decrementCalls(log, args)
    local buttonInstance = log.Button.Instance
    local remote = log.Remote

    remote:DecrementCalls(args)

    local calls = remote.Calls
    buttonInstance.Calls.Text = (calls < 10000 and calls) or "..."
    log:Adjust()
end

-- the log comes back (starting from zero) the next time the remote fires
function Log.remove(log)
    local remote = log.Remote

    remote:Clear()
    log.Button:Remove()
    currentLogs[remote.Instance] = nil

    if selected.remoteLog == log then
        selected.remoteLog = nil
        remoteLogs:Clear()

        RemoteLogs.Visible = false
        RemoteList.Visible = true
    end

    if selected.logContext == log then
        selected.logContext = nil
    end
end

-- UI Functionality

local function refreshLogs()
    for _remoteInstance, log in pairs(currentLogs) do
        refreshLog(log)
    end

    remoteList:Recalculate()
end

for _i,flag in pairs(ListFlags:GetChildren()) do
    if flag:IsA("Frame") then
        local check = CheckBox.new(flag)

        check:SetCallback(function(enabled)
            remotesViewing[flag.Name] = enabled

            -- UnreliableRemoteEvent has no flag of its own in the UI asset
            if flag.Name == "RemoteEvent" then
                remotesViewing.UnreliableRemoteEvent = enabled
            end

            refreshLogs()
        end)
    end
end

-- filters as you type; the query stays in the box instead of being wiped
ListSearch:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = ListSearch.Text:lower()
    refreshLogs()
end)

ListRefresh.MouseButton1Click:Connect(function()
    ListSearch.Text = ""
    refreshLogs()
end)

LogsBack.MouseButton1Click:Connect(function()
    RemoteLogs.Visible = false
    RemoteList.Visible = true
end)

LogsButtons.Ignore.MouseButton1Click:Connect(function()
    selected.remoteLog.Remote:Ignore()

    checkCurrentIgnored()
    selected.remoteLog:PlayStatus()
end)

LogsButtons.Block.MouseButton1Click:Connect(function()
    selected.remoteLog.Remote:Block()

    checkCurrentBlocked()
    selected.remoteLog:PlayStatus()
end)

LogsButtons.Clear.MouseButton1Click:Connect(function()
    selected.remoteLog:Clear()
end)

LogsButtons.Conditions.MouseButton1Click:Connect(function()
    selected.conditionLog = selected.logContext or selected.remoteLog

    createConditions(selected.conditionLog.Remote)
end)

ConditionsBack.MouseButton1Click:Connect(function()
    RemoteConditions.Visible = false

    if selected.remoteLog then
        RemoteLogs.Visible = true
    else
        RemoteList.Visible = true
    end
end)

ConditionsButtons.New.MouseButton1Click:Connect(function()
    newRemoteCondition:Show()
end)

NewConditionButtons.Add.MouseButton1Click:Connect(function()
    if not conditionStatus.Selected then
        return MessageBox.Show("Error", "Invalid condition status", MessageType.OK)
    elseif not conditionType.Selected then
        return MessageBox.Show("Error", "Pick a condition type", MessageType.OK)
    elseif not conditionValueType.Selected then
        return MessageBox.Show("Error", "Pick whether the condition matches a value or a type", MessageType.OK)
    elseif not (selected.conditionLog and tonumber(NewConditionIndex.Value.Input.Text)) then
        return MessageBox.Show("Error", "Invalid argument index", MessageType.OK)
    end

    local status = conditionStatus.Selected.Name
    local type = conditionType.Selected.Name
    local valueType = conditionValueType.Selected.Name
    local value = NewConditionContent.Value.Input.Text

    if status ~= "Ignore" and status ~= "Block" then
        MessageBox.Show("Error", "Invalid condition status", MessageType.OK)
    elseif not oh.Constants.Types[type] and not isUserdata(type) then
        MessageBox.Show("Error", "Invalid condition type", MessageType.OK)
    elseif valueType ~= "Value" and valueType ~= "Type" then
        MessageBox.Show("Error", "Invalid condition value association", MessageType.OK)
    elseif valueType == "Value" then
        if type == "string" then
            value = toString(value)
        elseif type == "number" then
            value = tonumber(value)

            if not value then
                return MessageBox.Show("Error", "Your input does not match the type you selected", MessageType.OK)
            end
        elseif type == "boolean" then
            if value == "true" then
                value = true
            elseif value == "false" then
                value = false
            else
                return MessageBox.Show("Error", "Your input does not match the type you selected", MessageType.OK)
            end
        else
            local chunk = loadstring("return " .. value)
            local success, result = false, nil

            if chunk then
                success, result = pcall(chunk)
            end

            if valueType == "Value" then
                if not success then
                    return MessageBox.Show("Error", "There was an error interpreting your input value", MessageType.OK)
                elseif typeof(result) ~= type then
                    return MessageBox.Show("Error", "Your input does not match the type you selected", MessageType.OK)
                else
                    value = result
                end
            end
        end
    else
        value = type
    end

    if value == nil then
        return MessageBox.Show("Error", 'nil can\'t be matched by value, use "Type" with the nil type instead', MessageType.OK)
    end

    local selectedRemote = selected.conditionLog.Remote
    local argIndex = tonumber(NewConditionIndex.Value.Input.Text)
    local byType = valueType == "Type"

    if status == "Block" then
        selectedRemote:BlockArg(argIndex, value, byType)
    else
        selectedRemote:IgnoreArg(argIndex, value, byType)
    end

    if byType then
        Condition.new(selectedRemote, status, argIndex, nil, value)
    else
        Condition.new(selectedRemote, status, argIndex, value)
    end

    newRemoteCondition:Hide()
end)

NewConditionButtons.Cancel.MouseButton1Click:Connect(function()
    newRemoteCondition:Hide()
end)

NewConditionIndex.Add.MouseButton1Click:Connect(function()
    local newIndex = (tonumber(NewConditionIndex.Value.Input.Text) or 0) + 1
    NewConditionIndex.Value.Input.Text = newIndex
end)

NewConditionIndex.Sub.MouseButton1Click:Connect(function()
    local newIndex = (tonumber(NewConditionIndex.Value.Input.Text) or 2) - 1
    NewConditionIndex.Value.Input.Text = (newIndex <= 0 and 1) or newIndex
end)

NewConditionIndex.Value.Input.FocusLost:Connect(function()
    local newIndex = tonumber(NewConditionIndex.Value.Input.Text)

    if not newIndex or newIndex <= 0 then
        NewConditionIndex.Value.Input.Text = 1
    end
end)

pathContext:SetCallback(function()
    local selectedInstance = selected.logContext.Remote.Instance
    local oldStatus = oh.getStatus()

    oh.setStatus("Copying " .. selectedInstance.Name .. "'s path")
    setClipboard(getInstancePath(selectedInstance))
    wait(0.25)
    oh.setStatus(oldStatus)
end)

conditionContext:SetCallback(function()
    selected.conditionLog = selected.logContext or selected.remoteLog

    createConditions(selected.conditionLog.Remote)
end)

clearContext:SetCallback(function()
    selected.logContext:Clear()
end)

ignoreContext:SetCallback(function()
    selected.logContext.Remote:Ignore()

    checkCurrentIgnored()
    selected.logContext:PlayStatus()
end)

blockContext:SetCallback(function()
    selected.logContext.Remote:Block()

    checkCurrentBlocked()
    selected.logContext:PlayStatus()
end)

removeContext:SetCallback(function()
    selected.logContext:Remove()
    remoteList:Recalculate()
end)

clearAllContext:SetCallback(function()
    for _remoteInstance, log in pairs(currentLogs) do
        log:Clear()
    end
end)

removeAllContext:SetCallback(function()
    MessageBox.Show("Remove all logs?", "Every remote will be removed from the list. Remotes reappear the next time they fire; ignore and block settings are kept.", MessageType.YesNo, function()
        local logs = {}

        for _remoteInstance, log in pairs(currentLogs) do
            table.insert(logs, log)
        end

        for _i, log in ipairs(logs) do
            log:Remove()
        end

        remoteList:Recalculate()
    end)
end)

pathContextSelected:SetCallback(function()
    local paths = ""

    for _i, log in pairs(selected.logs) do
        paths = paths .. getInstancePath(log.Remote.Instance) .. '\n'
    end

    setClipboard(paths)
    selected.logs = {}
end)

local function setSelectedStatus(setter, state)
    for _i, log in pairs(selected.logs) do
        local remote = log.Remote

        remote[setter](remote, state)
        log:PlayStatus()
    end

    checkCurrentIgnored()
    checkCurrentBlocked()
    selected.logs = {}
end

ignoreContextSelected:SetCallback(function()
    setSelectedStatus("SetIgnored", true)
end)

unignoreContextSelected:SetCallback(function()
    setSelectedStatus("SetIgnored", false)
end)

blockContextSelected:SetCallback(function()
    setSelectedStatus("SetBlocked", true)
end)

unblockContextSelected:SetCallback(function()
    setSelectedStatus("SetBlocked", false)
end)

clearContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        log:Clear()
    end

    selected.logs = {}
end)

removeContextSelected:SetCallback(function()
    for _i, log in pairs(selected.logs) do
        log:Remove()
    end

    remoteList:Recalculate()
    selected.logs = {}
end)

scriptContext:SetCallback(function()
    local script = "-- This script was generated by Hydroxide's RemoteSpy: https://github.com/Upbolt/Hydroxide\n\n"
    local selectedRemote = selected.remoteLog.Remote.Instance
    local remotePath = getInstancePath(selectedRemote)
    local method = Methods.ClassMethods[selectedRemote.ClassName]
    local selectedArgs = selected.args
    local argCount = selectedArgs.n or #selectedArgs
    local prefix = ((method == "InvokeServer" or method == "Invoke") and "local result = ") or ""

    local oldStatus = oh.getStatus()
    oh.setStatus("Generating RemoteSpy Pseudocode ...")

    if argCount == 0 then
        setClipboard(script .. prefix .. remotePath .. ':' .. method .. "()")
    else
        local args = ""

        for i = 1, argCount do
            local v = selectedArgs[i]
            local valueType = type(v)
            local robloxValueType = typeof(v)
            local variableName = robloxValueType:sub(1, 1):upper() .. robloxValueType:sub(2)

            if valueType == "userdata" or valueType == "vector" then
                v = (typeof(v) == "Instance" and getInstancePath(v)) or userdataValue(v)
            elseif valueType == "table" then
                v = tableToString(v)
            elseif valueType == "string" then
                v = dataToString(v)
            else
                v = toString(v)
            end

            script = script .. ("local oh%s%d = %s\n"):format(variableName, i, v)
            args = args .. ("oh%s%d, "):format(variableName, i)
        end

        setClipboard(script .. '\n' .. prefix .. remotePath .. ':' .. method .. '(' .. args:sub(1, -3) .. ')')
    end

    wait(0.25)
    oh.setStatus(oldStatus)
end)

callingScriptContext:SetCallback(function()
    local callingScript = selected.callingScript

    if typeof(callingScript) ~= "Instance" then
        return MessageBox.Show("Unavailable", "The calling script for this call could not be resolved (it may have been fired from a thread with no script, or from your executor).", MessageType.OK)
    end

    local oldStatus = oh.getStatus()

    oh.setStatus("Copying " .. callingScript.Name .. "'s path")
    setClipboard(getInstancePath(callingScript))
    wait(0.25)
    oh.setStatus(oldStatus)
end)

local SpyHook = ClosureSpy.Hook
spyClosureContext:SetCallback(function()
    if not selected.func then
        return MessageBox.Show("Unavailable", "The calling function for this call could not be resolved.", MessageType.OK)
    end

    if TabSelector.SelectTab("ClosureSpy") then
        local selectedClosure = Closure.new(selected.func)
        local result = SpyHook.new(selectedClosure)

        if result == false then
            MessageBox.Show("Already hooked", "You are already spying " .. selectedClosure.Name, MessageType.OK)
        elseif result == nil then
            MessageBox.Show("Cannot hook", ('Cannot hook "%s" because there are no upvalues'):format(selectedClosure.Name), MessageType.OK)
        end
    end
end)

repeatCallContext:SetCallback(function()
    local remoteInstance = selected.remoteLog.Remote.Instance
    local method = Methods.ClassMethods[remoteInstance.ClassName]
    local args = selected.args

    local oldStatus = oh.getStatus()
    oh.setStatus("Recalling " .. remoteInstance.Name)

    -- InvokeServer yields, so don't hold up the UI thread on it
    task.spawn(function()
        local ran, err = pcall(remoteInstance[method], remoteInstance, unpack(args, 1, args.n or #args))

        if not ran then
            MessageBox.Show("Repeat call failed", tostring(err), MessageType.OK)
        end
    end)

    wait(0.25)

    oh.setStatus(oldStatus)
end)

copyArgsContext:SetCallback(function()
    local args = selected.args
    local argCount = args.n or #args
    local out = {}

    for i = 1, argCount do
        out[i] = dataToString(args[i])
    end

    setClipboard(table.concat(out, ", "))
end)

viewAsHexContext:SetCallback(function()
    selected.callPodButton.hexViewEnabled = not selected.callPodButton.hexViewEnabled
    if not selected.callPodButton.oldStrings then
        selected.callPodButton.oldStrings = {}
    end

    for idx, arg in pairs(selected.args) do
        if type(arg) == "string" then
            local textObject = selected.callPodButton.Instance.Contents[tostring(idx)].Label
            if selected.callPodButton.hexViewEnabled then
                selected.callPodButton.oldStrings[idx] = arg
                local hexString = ""
                for i = 1, #arg do
                    hexString = hexString .. string.format("%02X ", arg:byte(i, i))
                end
                textObject.Text = hexString
            else
                textObject.Text = dataToString(selected.callPodButton.oldStrings[idx])
            end
        end
    end
end)

removeConditionContext:SetCallback(function()
    selected.condition:Remove()
    selected.condition = nil
end)

removeConditionContextSelected:SetCallback(function()
    for _i, condition in pairs(selected.conditions) do
        condition:Remove()
    end

    selected.conditions = {}
end)

conditionStatus:SetCallback(function(_dropdown, selected)
    local iconCondition = (selected.Name == "Ignore" and icons.ignore) or icons.block
    local icon = NewConditionContent.Status.Icon 

    icon.Image = iconCondition
    icon.Border.Image = iconCondition
end)

conditionType:SetCallback(function(_dropdown, selected)
    local icon = NewConditionContent.Type.Icon 
    local typeIcons = oh.Constants.Types
    local iconCondition = typeIcons[selected.Name] or typeIcons["userdata"]
    
    icon.Image = iconCondition
    icon.Border.Image = iconCondition
end)

conditionValueType:SetCallback(function(_dropdown, selected)
    local iconCondition = (selected.Name == "Type" and icons.type) or oh.Constants.Types["integral"]
    local icon = NewConditionContent.ValueType.Icon 

    icon.Image = iconCondition
    icon.Border.Image = iconCondition
end)

Methods.ConnectEvent(function(remoteInstance, callInfo)
    local remote = currentRemotes[remoteInstance]

    if not remote then
        return
    end

    local log = currentLogs[remoteInstance]

    if not log then
        log = Log.new(remote)
        log:IncrementCalls(callInfo)
        remoteList:Recalculate()
    else
        log:IncrementCalls(callInfo)
    end
end)

return RemoteSpy
