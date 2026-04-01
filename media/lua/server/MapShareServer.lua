local tablelength = function(object)
    local count = 0
    if not object then
        return count
    end
    for _ in pairs(object) do count = count + 1 end
    return count
end

local function sendMapToClients(module, packet)
    if not string.find(module, 'MapShare_') then
        return
    end

    ModData.add(module, packet)

    if not isServer() then
        return
    end

    if tablelength(packet) ~= 0 then
        ModData.transmit(module)
    end
end


Events.OnReceiveGlobalModData.Add(sendMapToClients)
