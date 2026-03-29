function shareMapButton(player, context, worldobjects, test)

  base_menu =  context:addOption("Share map no logic", worldobjects, nil)

  local playerObj = getSpecificPlayer(player)
  



  if clickedPlayer then
    if test == true then
      return true;
    end

    -- lISWorldObjectContextMenu.onMedicalCheck
    local option = context:addOption('Share map with logic', worldobjects, onShareMap, playerObj, clickedPlayer)

    if math.abs(playerObj:getX() - clickedPlayer:getX()) > 2 or math.abs(playerObj:getY() - clickedPlayer:getY()) > 2 then
			local tooltip = ISWorldObjectContextMenu.addToolTip();
			option.notAvailable = true;
			tooltip.description = getText("ContextMenu_GetCloser", clickedPlayer:getDisplayName());
			option.toolTip = tooltip;
		end
  end
end

function onShareMap()

end


function getCurrentMapSymbols()
    local payload = {}
    local symAPI = self:getSymbolsApi()
    local cnt = symAPI:getSymbolCount()
    for i = 0, cnt - 1 do
        local sym = symAPI:getSymbolByIndex(i)
        if sym:isVisible() then
            local s = {}
            s.x = sym:getWorldX()
            s.y = sym:getWorldY()
            s.r = sym:getRed()
            s.g = sym:getGreen()
            s.b = sym:getBlue()
            s.a = sym:getAlpha()
            if sym:isTexture() then
                s.type = "texture"
                s.texture = sym:getSymbolID()
            elseif sym:isText() then
                s.type = "text"
                s.text = sym:getTranslatedText() or sym:getUntranslatedText()
            else
                error("unknown symbol type at index " .. i)
            end

            table.insert(payload, s)
        end
    end
    return payload
end


-- [[ NETWORKING ]] --

function FactionMap:sendFactionMapData()
    ModData.transmit(self:getPlayerFactionId())
end

function FactionMap:requestFactionMapData()
    ModData.request(self:getPlayerFactionId())
end

local function onReceiveGlobalModData(module, packet)
    if not string.find(module, "FactionMap_")
            or module == "FactionMap_None"
            or not packet then
        return
    end

    local factionName = string.gsub(module, "FactionMap_", "")
    if factionName ~= FactionMap:getPlayerFactionName() then
        return
    end

    FactionMap:setFactionData(packet);

    if not ISWorldMap_instance or not FactionMap.isToggled then
        return
    end

    FactionMap:wipeCurrentMap()
    local moddata = FactionMap:getStoredFactionSymbols()
    FactionMap:injectSymbolsFromTable(moddata)
end

Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData);

Events.OnFillWorldObjectContextMenu.Add(shareMapButton)