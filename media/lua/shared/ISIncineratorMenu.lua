require "TimedActions/ISBaseTimedAction"

local MENU_ENTRY_BURNING  = "Incinerate Trash";

ISIncineratorMenu = {};

ISIncineratorMenu.doWorldObjectIncinerateMenu = function(playerIndex, context, worldobjects, test)
    local incineratorItem, incineratorSquare = ISIncineratorMenu.canIncinerateTrashHere(worldobjects);
    local player = getSpecificPlayer(playerIndex);

    if incineratorItem and incineratorSquare ~= nil and (player:getInventory():contains("Matches") or player:getInventory():contains("Lighter")) then
        context:addOption(MENU_ENTRY_BURNING, worldobjects, ISIncineratorMenu.onIncinerateTA, playerIndex, incineratorItem, incineratorSquare);
    end
end

ISIncineratorMenu.doInventoryIncinerateMenu = function(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex);

    if not player:getInventory():contains("Matches") and not player:getInventory():contains("Lighter") then
        return;
    end

    if #items > 1 then
        return;
    end

    local playerInventory = player:getInventory();

    local item;
    local stack;

    -- Iterate through all clicked items
    for _, entry in ipairs(items) do
        local isIncincerator = instanceof(entry, "InventoryItem") and entry:getType() == "RPIncinerator";

        if isIncincerator then
            item = entry;
            break;
        elseif type(entry) == "table" then
            stack = entry;
            break;
        end
    end

    if item then
        local modData = item:getModData();

        local incineratorWorldItem = item:getWorldItem();
        local incineratorSquare;

        if incineratorWorldItem then
            incineratorSquare = incineratorWorldItem:getSquare();
        else
            incineratorSquare = nil;
        end

        if incineratorSquare ~= nil then
            context:addOption(MENU_ENTRY_BURNING, nil, ISIncineratorMenu.onIncinerateTA, playerIndex, item, incineratorSquare);
            return;
        end
    end

    if stack and stack.items then
        for i = 1, #stack.items do
            local stackItem = stack.items[i];
            local isIncincerator = instanceof(stackItem, "InventoryItem") and stackItem:getType() == "RPIncinerator";

            if isIncincerator then
                local modData = stackItem:getModData();

                local incineratorWorldItem = stackItem:getWorldItem();
                local incineratorSquare;

                if incineratorWorldItem then
                    incineratorSquare = incineratorWorldItem:getSquare();
                else
                    incineratorSquare = nil;
                end

                if incineratorSquare ~= nil then
                    context:addOption(MENU_ENTRY_BURNING, nil, ISIncineratorMenu.onIncinerateTA, playerIndex, stackItem, incineratorSquare);
                    return;
                end
            end
        end
    end
end

ISIncineratorMenu.onIncinerate = function(incineratorItem, playerObj)    
    if isClient() then
        playerObj:getCurrentSquare():playSound("PZ_Fire", false);

        local incineratorSquare = incineratorItem:getWorldItem():getSquare();
        local x,y,z = incineratorSquare:getX(), incineratorSquare:getY(), incineratorSquare:getZ();
        local incineratorItemUniqueId = incineratorItem:getModData();

        if incineratorItemUniqueId.rptdUniqueID == nil then
            --backwards compatability for incinerators made after the mod data change
            incineratorItemUniqueId.rptdUniqueID = playerObj:getUsername() .. (ZombRand(1000000) + 1);
        end

        incineratorItemUniqueId = incineratorItemUniqueId.rptdUniqueID;

        args = { x = x, y = y, z = z, uniqueID = incineratorItemUniqueId };

        sendClientCommand(playerObj, 'RPGarbageDisposal', 'updateIncineratorContainer', args);
    end
end

ISIncineratorMenu.onIncinerateTA = function(worldobjects, playerIndex, incineratorItem, incineratorSquare)
    local player = getSpecificPlayer(playerIndex);

    if incineratorSquare ~= nil then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(player, incineratorSquare));
        player:faceLocation(incineratorSquare:getX(), incineratorSquare:getY());
    end

    ISTimedActionQueue.add(RPIncinerateTrashAction:new(player, incineratorItem, incineratorSquare, 100));
end

ISIncineratorMenu.canIncinerateTrashHere = function(worldObjects)
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
            local itemType = item:getType();
                
            if item and itemType and itemType == "RPIncinerator" then
                return items:get(i):getItem(), square
            end
        end
    end

    return false
end

RPIncinerateTrashAction = ISBaseTimedAction:derive("RPIncinerateTrashAction");

function RPIncinerateTrashAction:isValid()
    return self.character:getInventory():contains("Matches") or self.character:getInventory():contains("Lighter");
end

function RPIncinerateTrashAction:update()
    if self.incineratorSquare ~= nil then
        self.character:faceLocation(self.incineratorSquare:getX(), self.incineratorSquare:getY())
    end

    self.incineratorItem:setJobDelta(self:getJobDelta());
end

function RPIncinerateTrashAction:start()
    self.incineratorItem:setJobType("Incinerating Trash..");
    self.incineratorItem:setJobDelta(0.0);
end

function RPIncinerateTrashAction:stop()
    ISBaseTimedAction.stop(self);
    self.incineratorItem:setJobDelta(0.0);
end

function RPIncinerateTrashAction:perform()
    self.incineratorItem:getContainer():setDrawDirty(true);

    self.incineratorItem:setJobDelta(0.0);

    ISIncineratorMenu.onIncinerate(self.incineratorItem, self.character);
    ISBaseTimedAction.perform(self);
end

function RPIncinerateTrashAction:new(character, incineratorItem, incineratorSquare, time)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.character = character;
    o.incineratorItem = incineratorItem;
    o.incineratorSquare = incineratorSquare;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    return o
end