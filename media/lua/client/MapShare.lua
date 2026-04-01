MapShare = {
  writingImplements = {
    { item = "Pen",     colorInfo = ColorInfo.new(0, 0, 0, 1) },
    { item = "Pencil",  colorInfo = ColorInfo.new(0.2, 0.2, 0.2, 1) },
    { item = "RedPen",  colorInfo = ColorInfo.new(1, 0, 0, 1) },
    { item = "BluePen", colorInfo = ColorInfo.new(0, 0, 1, 1) }
  },
  mapIconOscillator = 0.0,
  mapOscillationLevel = 0,
  mapOscillationDeceleration = 0.96,
  mapIconOscillatorScalar = 15.6,
  mapIconOscillatorRate = 0.8,
  mapIconOscillatorStep = 0.0,
}

function MapShare:getSymbolsAPI()
  return ISWorldMap_instance.javaObject:getAPIv1():getSymbolsAPI()
end

function MapShare:getWritingImplementForColor(r, g, b)
  if (self:approximatelyEqual(r, 0) and self:approximatelyEqual(g, 0) and self:approximatelyEqual(b, 0)) then
    return "Pen"
  elseif (self:approximatelyEqual(r, 0.2) and self:approximatelyEqual(g, 0.2) and self:approximatelyEqual(b, 0.2)) then
    return "Pencil"
  elseif (self:approximatelyEqual(r, 1) and self:approximatelyEqual(g, 0) and self:approximatelyEqual(b, 0)) then
    return "RedPen"
  elseif (self:approximatelyEqual(r, 0) and self:approximatelyEqual(g, 0) and self:approximatelyEqual(b, 1)) then
    return "BluePen"
  end
end

function MapShare:approximatelyEqual(a, b)
  local epsilon = 0.01
  return a == b or math.abs(a - b) < epsilon
end

function MapShare:getAvailableColors(player)
  print("Player in getAvailableColors")
  print(player)
  local inventory = player:getInventory()

  local availableWritingImplements = {}
  for _, info in ipairs(self.writingImplements) do
    if inventory:containsTagRecurse(info.item) or inventory:containsTypeRecurse(info.item) then
      table.insert(availableWritingImplements, info)
    end
  end
  return availableWritingImplements
end

function MapShare:getWritingImplementOrDefault(availableWritingImplements, writingImplementName)
  for _, info in ipairs(availableWritingImplements) do
    print(info.item)
    if info.item == writingImplementName then
      return info
    end
  end
  return availableWritingImplements[1]
end

function MapShare:getCurrentMapSymbols(player)
  local payload = {}
  local symAPI = self:getSymbolsAPI()
  local cnt = symAPI:getSymbolCount()
  local availableWritingImplements = self:getAvailableColors(player)
  for i = 0, cnt - 1 do
    local sym = symAPI:getSymbolByIndex(i)
    if sym:isVisible() then
      local s = {}

      local requiredImplement = self:getWritingImplementForColor(sym:getRed(), sym:getGreen(), sym:getBlue())
      local availableImplement = self:getWritingImplementOrDefault(availableWritingImplements, requiredImplement)

      s.x = sym:getWorldX()
      s.y = sym:getWorldY()
      s.r = availableImplement.colorInfo:getR()
      s.g = availableImplement.colorInfo:getG()
      s.b = availableImplement.colorInfo:getB()
      s.a = availableImplement.colorInfo:getA()
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
  print("onShareMap")
  print(player)
  print(otherPlayer)
  if player:getAccessLevel() ~= "None" then
    ISTimedActionQueue.add(MapShareAction:new(player, otherPlayer))
  else
    if luautils.walkAdj(player, otherPlayer:getCurrentSquare()) then
      ISTimedActionQueue.add(MapShareAction:new(player, otherPlayer))
    end
  end
end

function MapShare:shareMap(player, otherPlayer)
  local payload = MapShare:getCurrentMapSymbols(player)
  local otherPlayerName = otherPlayer:getDisplayName()
  local key = "MapShare_" .. otherPlayerName
  print(key)
  ModData.add(key, payload)
  ModData.transmit(key)
end

function MapShare:updateMap(key, mapData)
  print("before inject set")
  self:injectSymbolsFromTable(mapData)
  print("before wobble set")
  self.mapOscillationLevel = 1
  print("after wobble set")
  local emptyPayload = {}
  print("after payload set")
  ModData.add(key, emptyPayload)
  print("after adding")
  ModData.transmit(key)
  print("after transmit")
end

function MapShare:onReceiveGlobalModData(module, packet)
  local key = "MapShare_" .. getPlayer():getDisplayName()
  local mapData = ModData.get(key)
  if mapData then
    if not ISWorldMap_instance then
      print("you need to have opened the map at least once")
    else
      MapShare:updateMap(key, mapData)
    end
  end
end

function MapShare:shakeMap()
  local mapButton = ISEquippedItem.instance.mapBtn
  if not mapButton or self.mapOscillationLevel == 0 then
    if self.mapOscillationLevel > 0.01 then
      local fpsFrac = (UIManager.getMillisSinceLastRender() / 33.3) * 0.5;
      self.mapOscillationLevel = self.mapOscillationLevel * self.mapOscillationDeceleration
      self.mapOscillationLevel = self.mapOscillationLevel -
          (self.mapOscillationLevel * (1 - self.mapOscillationDeceleration) * fpsFrac)
      self.mapIconOscillatorStep = self.mapIconOscillatorStep + self.mapIconOscillatorRate * fpsFrac
      self.mapIconOscillator = math.sin(self.mapIconOscillatorStep)
      mapButton:setX(self.mapIconOscillator * self.mapOscillationLevel * self.mapIconOscillatorScalar)
    elseif self.mapOscillationLevel < 0.01 then
      self.mapOscillationLevel = 0.0
      mapButton:setX(self.mapIconOscillator * self.mapOscillationLevel * self.mapIconOscillatorScalar)
    end
  end
end

function MapShare:tablelength(object)
  local count = 0
  if not object then
    return count
  end
  for _ in pairs(object) do count = count + 1 end
  return count
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

    print("In shareMapButton:")
    print(player)
    print(playerObj)
    if MapShare:tablelength(MapShare:getAvailableColors(playerObj)) == 0 then
      local tooltip = ISWorldObjectContextMenu.addToolTip();
      option.notAvailable = true
      tooltip.description = "You need some sort of writing implement"
      option.toolTip = tooltip
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
Events.OnTick.Add(MapShare.shakeMap)


-- bugs
-- 1 sharing only happens on second share... This is lag.
-- Map must be opened at least once prior to anything working PER SESSION
