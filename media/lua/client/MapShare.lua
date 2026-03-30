MapShare = {}

function MapShare:getSymbolsAPI()
  return ISWorldMap_instance.javaObject:getAPIv1():getSymbolsAPI()
end

function MapShare:getCurrentMapSymbols()
  local payload = {}
  local symAPI = self:getSymbolsAPI()
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

function MapShare:symbolExists(symbol)
  local symAPI = self:getSymbolsAPI()
  local cnt = symAPI:getSymbolCount()
  for i = 0, cnt - 1 do
    local existingSymbol = symAPI:getSymbolByIndex(i)

    local xMatch = existingSymbol:getWorldX() == symbol.x
    local yMatch = existingSymbol:getWorldY() == symbol.y
    local textureMatch = false

    if existingSymbol:isTexture() and symbol.type == "texture" then
      textureMatch = existingSymbol:getSymbolID() == symbol.texture
    elseif existingSymbol:isText() and symbol.type == "text" then
      textureMatch = existingSymbol:getTranslatedText() == symbol.text or
          existingSymbol:getUntranslatedText() == symbol.text
    else
      textureMatch = true
    end

    return xMatch and yMatch and textureMatch
  end
  return false
end

function MapShare:injectSymbolsFromTable(data)
  local symbolApi = self:getSymbolsAPI()
  for _, s in ipairs(data) do
    if not self:symbolExists(s) then
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
end

function MapShare:onShareMap(player, otherPlayer)
  local payload = MapShare:getCurrentMapSymbols()
  local otherPlayerName = otherPlayer:getDisplayName()
  local key = "MapShare_" .. otherPlayerName
  print(key)
  ModData.add(key, payload)
  ModData.transmit(key)
end

function MapShare:onReceiveGlobalModData(module, packet)
  local key = "MapShare_" .. getPlayer():getDisplayName()
  local mapData = ModData.get(key)
  if mapData then
    if not ISWorldMap_instance then
      print("you need to have opened the map at least once")
    else
      MapShare:injectSymbolsFromTable(mapData)
      local emptyPayload = {}
      ModData.add(key, emptyPayload)
      ModData.transmit(key)
    end
  end
end

local function shareMapButton(player, context, worldobjects, test)
  local playerObj = getSpecificPlayer(player)

  print(playerObj)
  print(clickedPlayer)
  if clickedPlayer and not (clickedPlayer == playerObj) then
    if test == true then
      return true;
    end

    local option = context:addOption("Share map", worldobjects, MapShare.onShareMap, playerObj, clickedPlayer)

    if math.abs(playerObj:getX() - clickedPlayer:getX()) > 2 or math.abs(playerObj:getY() - clickedPlayer:getY()) > 2 then
      local tooltip = ISWorldObjectContextMenu.addToolTip();
      option.notAvailable = true;
      tooltip.description = getText("ContextMenu_GetCloser", clickedPlayer:getDisplayName());
      option.toolTip = tooltip;
    end

    if not ISWorldMap_instance then
      local tooltip = ISWorldObjectContextMenu.addToolTip();
      option.notAvailable = true;
      tooltip.description = "Open your own map at least once first"
      option.toolTip = tooltip;
    end
  end
end

Events.OnReceiveGlobalModData.Add(MapShare.onReceiveGlobalModData)
Events.OnFillWorldObjectContextMenu.Add(shareMapButton)


-- bugs
-- 1 sharing only happens on second share... This is lag.
-- Map must be opened at least once prior to anything working PER SESSION
