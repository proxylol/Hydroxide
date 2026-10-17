local Remote = {}

function Remote.new(instance)
    local remote = {}

    remote.Instance = instance
    remote.Logs = {}
    remote.Calls = 0
    remote.Blocked = false
    remote.Ignored = false
    remote.Clear = Remote.clear
    remote.Block = Remote.block
    remote.Ignore = Remote.ignore
    remote.SetBlocked = Remote.setBlocked
    remote.SetIgnored = Remote.setIgnored
    remote.BlockedArgs = {}
    remote.IgnoredArgs = {}
    remote.BlockArg = Remote.blockArg
    remote.IgnoreArg = Remote.ignoreArg
    remote.AreArgsBlocked = Remote.areArgsBlocked
    remote.AreArgsIgnored = Remote.areArgsIgnored
    remote.IncrementCalls = Remote.incrementCalls
    remote.DecrementCalls = Remote.decrementCalls

    return remote
end

function Remote.clear(remote)
    remote.Calls = 0
    remote.Logs = {}
end

function Remote.block(remote)
    remote.Blocked = not remote.Blocked
end

function Remote.ignore(remote)
    remote.Ignored = not remote.Ignored
end

function Remote.setBlocked(remote, blocked)
    remote.Blocked = blocked and true or false
end

function Remote.setIgnored(remote, ignored)
    remote.Ignored = ignored and true or false
end

function Remote.blockArg(remote, index, value, byType)
    local blockedArgs = remote.BlockedArgs
    local blockedIndex = blockedArgs[index]

    if not blockedIndex then
        blockedIndex = {
            types = {},
            values = {}
        }
        blockedArgs[index] = blockedIndex
    end

    if byType then
        blockedIndex.types[value] = true
    else
        blockedIndex.values[value] = true
    end
end

function Remote.ignoreArg(remote, index, value, byType)
    local ignoredArgs = remote.IgnoredArgs
    local indexIgnore = ignoredArgs[index]

    if not indexIgnore then
        indexIgnore = {
            types = {},
            values = {}
        }

        ignoredArgs[index] = indexIgnore
    end

    if byType then
        indexIgnore.types[value] = true
    else
        indexIgnore.values[value] = true
    end
end

function Remote.areArgsBlocked(remote, args)
    local blockedArgs = remote.BlockedArgs

    for index, value in pairs(args) do
        local indexBlock = blockedArgs[index]
        
        if indexBlock and ( indexBlock.types[typeof(value)] or indexBlock.values[value] ~= nil ) then
            return true
        end
    end
end

function Remote.areArgsIgnored(remote, args)
    local ignoredArgs = remote.IgnoredArgs

    for index, value in pairs(args) do
        local indexIgnore = ignoredArgs[index]

        if indexIgnore and ( indexIgnore.types[typeof(value)] or indexIgnore.values[value] ~= nil ) then
            return true
        end
    end
end

function Remote.incrementCalls(remote, vargs)
    remote.Calls = remote.Calls + 1
    table.insert(remote.Logs, vargs)
end

function Remote.decrementCalls(remote, vargs)
    local logs = remote.Logs
    local index = table.find(logs, vargs)

    if index then
        remote.Calls = remote.Calls - 1
        table.remove(logs, index)
    end
end

return Remote