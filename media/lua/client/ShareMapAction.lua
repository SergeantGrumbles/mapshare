require "TimedActions/ISBaseTimedAction"

MapShareAction = ISBaseTimedAction:derive("MapShareAction");


function MapShareAction:isValid()
    return self.character:getAccessLevel() ~= "None" or
        (self.otherPlayerX == self.otherPlayer:getX() and self.otherPlayerY == self.otherPlayer:getY());
end

-- function MapShareAction:waitToStart()
--     if self.character:isSeatedInVehicle() then
--         return false
--     end
--     self.character:faceThisObject(self.otherPlayer)
--     return self.character:shouldBeTurning()
-- end

function MapShareAction:update()
    self.character:faceThisObject(self.otherPlayer)
end

function MapShareAction:start()
    self:setActionAnim(CharacterActionAnims.Read)
    self:setOverrideHandModelsString(nil, "MapInHand")
end

function MapShareAction:stop()
    ISBaseTimedAction.stop(self);
end

function MapShareAction:perform()
    MapShare:shareMap(self.character, self.otherPlayer)
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end

function MapShareAction:new(player, otherPlayer)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = player;
    o.otherPlayer = otherPlayer;
    o.otherPlayerX = otherPlayer:getX();
    o.otherPlayerY = otherPlayer:getY();
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = 150;
    o.forceProgressBar = true;
    if player:isTimedActionInstant() then
        o.maxTime = 1;
    end
    return o;
end
