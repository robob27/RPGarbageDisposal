require "TimedActions/ISBaseTimedAction"

ISLandfillMenu = {};

local DIG_LANDFILL_ENTRY = 'Dig Landfill';
local FILL_LANDFILL_ENTRY = 'Fill Landfill';

ISLandfillMenu.doDigLandfillMenu = function(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local existingLandfillItem, existingLandfillSquare = ISLandfillMenu.canFillLandfillHere(worldobjects);

    if existingLandfillItem == false then
        local playerObj = getSpecificPlayer(player);
        local playerInv = playerObj:getInventory();
        local digLandfillSquare = ISLandfillMenu.canDigLandfillHere(worldobjects);

        if playerInv:contains("Shovel") and ISLandfillMenu.canDigLandfillHere(worldobjects) ~= false then
            if test then return ISWorldObjectContextMenu.setTest() end
            local handItem = playerObj:getPrimaryHandItem();

            context:addOption(DIG_LANDFILL_ENTRY, worldobjects, ISLandfillMenu.DigLandfillTA, player, handItem, digLandfillSquare);
        end
    end
end

ISLandfillMenu.doWorldFillLandfillMenu = function(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    local playerObj = getSpecificPlayer(player);
    local playerInv = playerObj:getInventory();

    local landfillItem, landfillSquare = ISLandfillMenu.canFillLandfillHere(worldobjects);
    
    if playerInv:contains("Shovel") and landfillItem ~= false then
        if test then return ISWorldObjectContextMenu.setTest() end
        local handItem = playerObj:getPrimaryHandItem();

        context:addOption(FILL_LANDFILL_ENTRY, worldobjects, ISLandfillMenu.FillLandfillTA, player, handItem, landfillItem, landfillSquare);
    end
end

ISLandfillMenu.doInventoryFillLandfillMenu = function(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex);

    if #items > 1 then
        return;
    end

    local playerInventory = player:getInventory();
    local handItem;

    if playerInventory:contains("Shovel") then
        handItem = player:getPrimaryHandItem();
    else
        return;
    end

    local item;
    local stack;

    -- Iterate through all clicked items
    for _, entry in ipairs(items) do
        local isLandfill = instanceof(entry, "InventoryItem") and entry:getType() == "RPLandfill";

        if isLandfill then
            item = entry;
            break;
        elseif type(entry) == "table" then
            stack = entry;
            break;
        end
    end

    if item then
        local garbageDisposalWorldItem = item:getWorldItem();
        local landfillSquare;

        if garbageDisposalWorldItem then
            landfillSquare = garbageDisposalWorldItem:getSquare();
        else
            landfillSquare = nil;
        end

        context:addOption(FILL_LANDFILL_ENTRY, nil, ISLandfillMenu.FillLandfillTA, playerIndex, handItem, landfillItem, landfillSquare);
        return;
    end

    if stack and stack.items then
        for i = 1, #stack.items do
            local stackItem = stack.items[i];
            local isLandfill = instanceof(stackItem, "InventoryItem") and stackItem:getType() == "RPLandfill";

            if isLandfill then
                local landfillItem = stackItem:getWorldItem();
                local landfillSquare;

                if landfillItem then
                    landfillSquare = landfillItem:getSquare();
                else
                    landfillSquare = nil;
                end

                context:addOption(FILL_LANDFILL_ENTRY, nil, ISLandfillMenu.FillLandfillTA, playerIndex, handItem, landfillItem, landfillSquare);
                return;
            end
        end
    end
end

ISLandfillMenu.FillLandfillTA = function(worldobjects, player, handItem, landfillItem, landfillSquare)
    local playerObj = getSpecificPlayer(player);
    local handItem = playerObj:getPrimaryHandItem();

    if not (handItem and handItem:getType() == "Shovel") then
        handItem = ISWorldObjectContextMenu.equip(playerObj, handItem, "Shovel", true)
        if handItem:getType() ~= "Shovel" then
            handItem = nil;
        end
    end

    if handItem then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, landfillSquare));
        ISTimedActionQueue.add(RPFillLandfillAction:new(playerObj, worldobjects, handItem, landfillItem, landfillSquare, 300));
    end
end

ISLandfillMenu.DigLandfillTA = function(worldobjects, player, handItem, digLandfillSquare)
    local playerObj = getSpecificPlayer(player);
    local handItem = playerObj:getPrimaryHandItem();

    if not (handItem and handItem:getType() == "Shovel") then
        handItem = ISWorldObjectContextMenu.equip(playerObj, handItem, "Shovel", true)
        if handItem:getType() ~= "Shovel" then
            handItem = nil;
        end
    end
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, digLandfillSquare));
    ISTimedActionQueue.add(RPDigLandfillAction:new(playerObj, worldobjects, handItem, digLandfillSquare, 300));
end

ISLandfillMenu.onDigLandfill = function(worldobjects, playerObj, handItem)
    playerObj:getCurrentSquare():AddWorldInventoryItem("RPGarbageDisposal.RPLandfill", 0.0, 0.0, 0.0);
end

ISLandfillMenu.onFillLandfill = function(landfillItem, character)
    if instanceof(landfillItem, 'InventoryContainer') then
        landfillItem = landfillItem:getWorldItem();
    end

    landfillItem:getSquare():transmitRemoveItemFromSquare(landfillItem);
    landfillItem:removeFromSquare();

    local pdata = getPlayerData(character:getPlayerNum());

    if pdata then
        pdata.lootInventory:refreshBackpacks();
    end
end

ISLandfillMenu.canFillLandfillHere = function(worldObjects)
    local squares = {}
    local didSquare = {}

    for _,worldObj in ipairs(worldObjects) do
        if not didSquare[worldObj:getSquare()] then
            table.insert(squares, worldObj:getSquare())
            didSquare[worldObj:getSquare()] = true
        end
    end

    for _,square in ipairs(squares) do
        local items = square:getWorldObjects();

        for i=0,items:size()-1 do
            local item = items:get(i):getItem();
            local itemName = item:getDisplayName();
                
            if item and itemName == "Landfill" then
                return items:get(i):getItem(), square
            end
        end
    end

    return false, false
end

ISLandfillMenu.canDigLandfillHere = function(worldObjects)
    local squares = {}
    local didSquare = {}
    for _,worldObj in ipairs(worldObjects) do
        if not didSquare[worldObj:getSquare()] then
            table.insert(squares, worldObj:getSquare())
            didSquare[worldObj:getSquare()] = true
        end
    end
    for _,square in ipairs(squares) do
        for i=1,square:getObjects():size() do
            local obj = square:getObjects():get(i-1);
            if obj:getTextureName() and (luautils.stringStarts(obj:getTextureName(), "floors_exterior_natural") or
                    luautils.stringStarts(obj:getTextureName(), "blends_natural_01")) then
                return square
            end
        end
    end
    return false
end


RPDigLandfillAction = ISBaseTimedAction:derive("RPDigLandfillAction");

function RPDigLandfillAction:isValid()
    return self.character:getInventory():contains("Shovel");
end

function RPDigLandfillAction:update()
    local swingAnimation = self.item:getSwingAnim();
    self.character:PlayAnim("Attack_" .. swingAnimation);
    self.character:faceLocation(self.digLandfillSquare:getX(), self.digLandfillSquare:getY())
    self.item:setJobDelta(self:getJobDelta());
end

function RPDigLandfillAction:start()
    self.item:setJobType("Digging Landfill..");
    self.item:setJobDelta(0.0);

    self.sound = getSoundManager():PlayWorldSound("shoveling", self.digLandfillSquare, 0, 10, 1, true);
end

function RPDigLandfillAction:stop()
    if self.sound and self.sound:isPlaying() then
        self.sound:stop();
    end
    self.character:PlayAnim("Idle");
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function RPDigLandfillAction:perform()
    self.item:getContainer():setDrawDirty(true);
    self.item:setJobDelta(0.0);

    if self.sound and self.sound:isPlaying() then
        self.sound:stop();
    end

    self.character:PlayAnim("Idle");

    ISLandfillMenu.onDigLandfill(self.worldobjects, self.character, self.item);
    ISBaseTimedAction.perform(self);
end

function RPDigLandfillAction:new(character, worldobjects, item, digLandfillSquare, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.worldobjects = worldobjects;
    o.item = item;
    o.digLandfillSquare = digLandfillSquare;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o
end

RPFillLandfillAction = ISBaseTimedAction:derive("RPFillLandfillAction");

function RPFillLandfillAction:isValid()
    return self.character:getInventory():contains("Shovel");
end

function RPFillLandfillAction:update()
    local swingAnimation = self.item:getSwingAnim();
    self.character:PlayAnim("Attack_" .. swingAnimation);

    self.character:faceLocation(self.landfillSquare:getX(), self.landfillSquare:getY())
    self.item:setJobDelta(self:getJobDelta());
end

function RPFillLandfillAction:start()
    self.item:setJobType("Filling Landfill..");
    self.item:setJobDelta(0.0);

    self.sound = getSoundManager():PlayWorldSound("shoveling", self.landfillSquare, 0, 10, 1, true);
end

function RPFillLandfillAction:stop()
    if self.sound and self.sound:isPlaying() then
        self.sound:stop();
    end
    self.character:PlayAnim("Idle");
    ISBaseTimedAction.stop(self);
    self.item:setJobDelta(0.0);
end

function RPFillLandfillAction:perform()
    self.item:getContainer():setDrawDirty(true);

    self.item:setJobDelta(0.0);

    if self.sound and self.sound:isPlaying() then
        self.sound:stop();
    end

    self.character:PlayAnim("Idle");


    ISLandfillMenu.onFillLandfill(self.landfillItem, self.character);
    ISBaseTimedAction.perform(self);
end

function RPFillLandfillAction:new(character, worldobjects, item, landfillItem, landfillSquare, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.worldobjects = worldobjects;
    o.landfillItem = landfillItem;
    o.landfillSquare = landfillSquare;
    o.item = item;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o
end