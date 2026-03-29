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

function onShareMap

end


Events.OnFillWorldObjectContextMenu.Add(shareMapButton)