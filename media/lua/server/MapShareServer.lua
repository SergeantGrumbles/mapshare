local function sendMapToClients(module, packet) 
    if not string.find(module, 'MapShare_') then
        return
    end

    ModData.add(module, packet)

    if not isServer() then
        return
    end

    ModData.transmit(module)
end

Events.OnReceiveGlobalModData.Add(sendMapToClients)