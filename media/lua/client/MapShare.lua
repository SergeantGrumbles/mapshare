MapShare = {}

function MapShare:shareMapButton(player, context, worldobjects, test)

  local playerObj = getSpecificPlayer(player)
  
  if clickedPlayer then
    if test == true then
      return true;
    end

    local option = context:addOption('Share map', worldobjects, onShareMap, playerObj, self:clickedPlayer)

    if math.abs(playerObj:getX() - clickedPlayer:getX()) > 2 or math.abs(playerObj:getY() - clickedPlayer:getY()) > 2 then
			local tooltip = ISWorldObjectContextMenu.addToolTip();
			option.notAvailable = true;
			tooltip.description = getText("ContextMenu_GetCloser", clickedPlayer:getDisplayName());
			option.toolTip = tooltip;
		end
  end
end


function MapShare:getCurrentMapSymbols()
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

function MapShare:injectSymbolsFromTable(data)
    local symbolApi = self:getSymbolsApi();
    for _, s in ipairs(data) do
        if s.type == "texture" then
            local sym = symbolApi:addTexture(s.texture, s.x, s.y)
            sym:setRGBA(s.r, s.g, s.b, s.a)
            sym:setAnchor(0.5, 0.5)
            sym:setScale(ISMap.SCALE)
        elseif s.type == "text" then
            local sym = symbolApi:addTranslatedText(s.text, UIFont.Handwritten, s.x, s.y)
            sym:setRGBA(s.r, s.g, s.b, s.a)
            sym:setAnchor(0.0, 0.0)
            sym:setScale(ISMap.SCALE)
        else
            error("unknown type found in payload " .. (s.type or "nil"))
        end

        if s.visited then
            local offset = 5
            WorldMapVisited.getInstance():setKnownInSquares(
                    s.x - offset, s.y - offset, s.x + offset, s.y + offset
            )
        end
    end
end


-- [[ NETWORKING ]] --
function MapShare:onShareMap(clickedPlayer)
  -- get the players current map symbols as the payload
  local payload = getCurrentMapSymbols()
  local key = 'MapShare:' + clickedPlayer.getDisplayName()
  ModData.add(key, payload)
  ModData.transmit(key)
end

function MapShare:onReceiveGlobalModData(module, packet)
    local key = 'MapShare:' + getPlayer().getDisplayName()
    local mapData = ModData.get(key)
    if mapData then
      injectSymbolsFromTable(mapData)
      ModData.add(key, nil)
      ModData.transmit(key)
    end
end

Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData);

Events.OnFillWorldObjectContextMenu.Add(shareMapButton)