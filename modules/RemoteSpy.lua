local RemoteSpy = {}
local Remote = import("objects/Remote")

local requiredMethods = {
    ["checkCaller"] = true,
    ["newCClosure"] = true,
    ["hookFunction"] = true,
    ["isReadOnly"] = true,
    ["setReadOnly"] = true,
    ["getInfo"] = true,
    ["getMetatable"] = true,
    ["setClipboard"] = true,
    ["getNamecallMethod"] = true,
    ["getCallingScript"] = true,
}

-- namecall method names are case-insensitive in Roblox (fireServer, fireserver, ...)
local remoteMethods = {
    fireserver = "FireServer",
    invokeserver = "InvokeServer",
    fire = "Fire",
    invoke = "Invoke"
}

local classMethods = {
    RemoteEvent = "FireServer",
    UnreliableRemoteEvent = "FireServer",
    RemoteFunction = "InvokeServer",
    BindableEvent = "Fire",
    BindableFunction = "Invoke"
}

local remotesViewing = {
    RemoteEvent = true,
    UnreliableRemoteEvent = true,
    RemoteFunction = false,
    BindableEvent = false,
    BindableFunction = false
}

local methodHooks = {
    RemoteEvent = Instance.new("RemoteEvent").FireServer,
    RemoteFunction = Instance.new("RemoteFunction").InvokeServer,
    BindableEvent = Instance.new("BindableEvent").Fire,
    BindableFunction = Instance.new("BindableFunction").Invoke
}

do
    local ran, unreliable = pcall(Instance.new, "UnreliableRemoteEvent")

    if ran and unreliable then
        local fireServer = unreliable.FireServer

        -- only hook separately if it isn't the same C function as RemoteEvent.FireServer
        if fireServer ~= methodHooks.RemoteEvent then
            methodHooks.UnreliableRemoteEvent = fireServer
        end
    end
end

local currentRemotes = {}

local remoteDataEvent = Instance.new("BindableEvent")
local eventSet = false

local function connectEvent(callback)
    remoteDataEvent.Event:Connect(callback)

    if not eventSet then
        eventSet = true
    end
end

local function getScript()
    local ran, script = pcall(getCallingScript, (PROTOSMASHER_LOADED ~= nil and 2) or nil)
    return ran and script or nil
end

-- returns true when the call should be blocked
local function handleCall(instance, vargs, caller)
    local remote = currentRemotes[instance]

    if not remote then
        remote = Remote.new(instance)
        currentRemotes[instance] = remote
    end

    if eventSet and not remote.Ignored and not remote:AreArgsIgnored(vargs) then
        local call = {
            script = getScript(),
            args = vargs,
            func = caller,
            time = os.clock()
        }

        remote:IncrementCalls(call)
        remoteDataEvent:Fire(instance, call)
    end

    return remote.Blocked or remote:AreArgsBlocked(vargs)
end

local function shouldLog(instance, method)
    if typeof(instance) ~= "Instance" or instance == remoteDataEvent then
        return false
    end

    local ran, className = pcall(function()
        return instance.ClassName
    end)

    return ran and remotesViewing[className] and classMethods[className] == method
end

local enabled = true

local nmcTrampoline
nmcTrampoline = hookMetaMethod(game, "__namecall", function(...)
    if not enabled then
        return nmcTrampoline(...)
    end

    local instance = ...
    local method = getNamecallMethod()
    local normalized = method and remoteMethods[method:lower()]

    if normalized and shouldLog(instance, normalized) then
        local info = getInfo(3)

        if handleCall(instance, table.pack(select(2, ...)), info and info.func) then
            return
        end
    end

    return nmcTrampoline(...)
end)

-- oh.Exit disconnects every entry in oh.Events; this turns the namecall hook into a passthrough
oh.Events.RemoteSpyNamecall = {
    Disconnect = function()
        enabled = false
    end
}

for className, hook in pairs(methodHooks) do
    local method = classMethods[className]
    local originalMethod

    originalMethod = hookFunction(hook, newCClosure(function(...)
        local instance = ...

        if enabled and shouldLog(instance, method) then
            local info = getInfo(3)

            if handleCall(instance, table.pack(select(2, ...)), info and info.func) then
                return
            end
        end

        return originalMethod(...)
    end))

    oh.Hooks[originalMethod] = hook
end

RemoteSpy.RemotesViewing = remotesViewing
RemoteSpy.CurrentRemotes = currentRemotes
RemoteSpy.ClassMethods = classMethods
RemoteSpy.ConnectEvent = connectEvent
RemoteSpy.RequiredMethods = requiredMethods
return RemoteSpy
