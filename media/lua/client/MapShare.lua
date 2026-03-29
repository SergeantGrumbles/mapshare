function shareMapButton(player, context, worldobjects, test)

  base_menu =  context:addOption("Share map no logic", worldobjects, nil)

  local playerObj = getSpecificPlayer(player)
  local clickedPlayer = findClickedPlayer(worldobjects, player)


  if clickedPlayer then
  --if clickedPlayer and clickedPlayer ~= playerObj then
    if test == true then
      return true;
    end

    local option = context:addOption('Share map with logic', worldobjects, ISWorldObjectContextMenu.onMedicalCheck, playerObj, clickedPlayer)

    if math.abs(playerObj:getX() - clickedPlayer:getX()) > 2 or math.abs(playerObj:getY() - clickedPlayer:getY()) > 2 then
			local tooltip = ISWorldObjectContextMenu.addToolTip();
			option.notAvailable = true;
			tooltip.description = getText("ContextMenu_GetCloser", clickedPlayer:getDisplayName());
			option.toolTip = tooltip;
		end
  end
end

function findClickedPlayer(worldobjects, player)
  for i,v in ipairs(worldobjects) do
    local o = worldobjects[i]
		--if instanceof(v, "IsoPlayer") and (v ~= player) then
    
		if instanceof(v, "IsoPlayer") then
      return v
    end
  end
  return nil
end

 

Events.OnFillWorldObjectContextMenu.Add(shareMapButton)