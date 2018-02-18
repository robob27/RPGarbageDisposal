--Forked from code written by RoboMat for Convenient Bags http://steamcommunity.com/sharedfiles/filedetails/?id=670807387
require('TimedActions/ISTimedActionQueue');
require('TimedActions/ISBaseTimedAction');
require('TimedActions/ISInventoryTransferAction');
require('UI/RPTDUITagModal');
require('luautils');

local MENU_ENTRY_PACKING  = "Pack Trash Items";
local MENU_ENTRY_TAGGING  = "Edit Trash Tags";

local SPLIT_IDENTIFIER = ',';

local function convertArrayList(arrayList)
    local itemTable = {};

    for i = 1, arrayList:size() do
        itemTable[i] = arrayList:get(i - 1);
    end

    return itemTable;
end

local function storeNewTag(button, player)
    local tag = button.parent.entry:getText();

    local modData = getSpecificPlayer(player):getModData();
    modData.rptdtags = modData.rptdtags or {};

    if button.internal == 'ADD' then
        if tag == '' then
            button.parent:destroy();
            return;
        end

        for snippet in tag:gmatch('[^' .. SPLIT_IDENTIFIER .. ']+') do
            local ntag = snippet:gsub('^%s*(.-)%s*$', '%1'); -- Trim whitespace.
            modData.rptdtags[ntag] = true;
        end

        button.parent.tagList:renderItemsFromModData(modData.rptdtags);
        button.parent:clearAndFocusEntry();
    elseif button.internal == 'REMOVE' then
        local tagList = button.parent.tagList;

        if tagList.items[tagList.selected] then
            tag = tagList.items[tagList.selected].text;
        else
            button.parent.entry:focus();
            return;
        end

        local newModData = {};
        local tagsToRemove = {};

        for snippet in tag:gmatch('[^' .. SPLIT_IDENTIFIER .. ']+') do
            local ntag = snippet:gsub('^%s*(.-)%s*$', '%1'); -- Trim whitespace.
            tagsToRemove[ntag] = true;
        end

        for key, val in pairs(modData.rptdtags) do
            local matchFound = false;

            for key2, val2 in pairs(tagsToRemove) do
                if key:lower() == key2:lower() then
                    matchFound = true;
                end
            end

            if matchFound == false then
                newModData[key] = true;
            end
        end

        modData.rptdtags = newModData;
        button.parent.tagList:renderItemsFromModData(modData.rptdtags);
        button.parent.entry:focus();
    elseif button.internal == 'DISMISS' then
        button.parent:destroy();
    end
end

local function onAddTag(items, player, playerIndex)
    local modal = RPTDUITagModal:new(0, 0, 280, 180, storeNewTag, playerIndex);
    modal.backgroundColor.r =   0;
    modal.backgroundColor.g =   0;
    modal.backgroundColor.b =   0;
    modal.backgroundColor.a = 0.9;
    modal:initialise();
    modal:addToUIManager();
end

local function ifTagMatchesQueueTransferItem(item, tag, player, garbageDisposal)
    local category = item:getCategory();

    -- handle different languages
    local categoryConstant = 'IGUI_ItemCat_' .. category;
    local translatedCategory = getText(categoryConstant);

    if not translatedCategory then
        translatedCategory = category;
    end

    if translatedCategory:lower() == tag:lower() or item:getName():lower() == tag:lower() or (tag:find('?') and item:getName():lower():find(tag:lower():sub(1,tag:len() - 1))) then
        if luautils.haveToBeTransfered(player, item) then
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, item:getContainer(), player:getInventory()));
        end
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, player:getInventory(), garbageDisposal:getInventory()));
    end
end

local function onPackGarbageDisposal(worlditems, player, playerInventory, garbageDisposal, garbageDisposalSquare)
    ISTimedActionQueue.add(ISWalkToTimedAction:new(player, garbageDisposalSquare));
    player:faceLocation(garbageDisposalSquare:getX(), garbageDisposalSquare:getY());

    local modData = player:getModData();

    if modData.rptdtags then
        for i = 1, #playerInventory do
            local item = playerInventory[i];
            
            if instanceof(item, 'InventoryItem') and item:getType() ~= 'KeyRing' and item:getType() ~= 'RPIncinerator' then
                -- if the InventoryItem is an equipped container, loop through it's contents too
                if instanceof(item, 'InventoryContainer') and player:isEquipped(item) then
                    local itemInventory = convertArrayList(item:getInventory():getItems());

                    for i2 = 1, #itemInventory do
                        local item2 = itemInventory[i2];

                        if item2 then
                            for tag, _ in pairs(modData.rptdtags) do
                                ifTagMatchesQueueTransferItem(item2, tag, player, garbageDisposal);
                            end
                        end
                    end
                elseif not player:isEquipped(item) then
                    for tag, _ in pairs(modData.rptdtags) do
                        ifTagMatchesQueueTransferItem(item, tag, player, garbageDisposal);
                    end
                end
            end
        end
    end
end

local function createWorldObjectMenuEntry(garbageDisposalItem, garbageDisposalSquare, worldobjects, player, playerIndex, context)
    if garbageDisposalSquare then
        local itemsOnPlayer = convertArrayList(player:getInventory():getItems());

        context:addOption(MENU_ENTRY_PACKING, worldobjects, onPackGarbageDisposal, player, itemsOnPlayer, garbageDisposalItem, garbageDisposalSquare);
    end

    context:addOption(MENU_ENTRY_TAGGING, worldobjects, onAddTag, player, playerIndex);
end

local function createInventoryObjectMenuEntry(player, playerIndex, context, garbageDisposalItem)
    local itemsOnPlayer = convertArrayList(player:getInventory():getItems());
    local garbageDisposalWorldItem = garbageDisposalItem:getWorldItem();
    local garbageDisposalSquare;

    if garbageDisposalWorldItem then
        garbageDisposalSquare = garbageDisposalItem:getWorldItem():getSquare();
    else
        garbageDisposalSquare = nil;
    end

    if garbageDisposalSquare then
        context:addOption(MENU_ENTRY_PACKING, nil, onPackGarbageDisposal, player, itemsOnPlayer, garbageDisposalItem, garbageDisposalSquare);
    end

    context:addOption(MENU_ENTRY_TAGGING, nil, onAddTag, player, playerIndex);
end


local function canPackTrashHere(worldObjects)
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
                
            if item and itemType and (itemType == "RPLandfill" or itemType == "RPIncinerator") then
                return items:get(i):getItem(), square
            end
        end
    end

    return false
end

local function createWorldObjectMenu(playerIndex, context, worldobjects)
    local player = getSpecificPlayer(playerIndex);

    local garbageDisposalItem, garbageDisposalSquare = canPackTrashHere(worldobjects);

    if garbageDisposalItem then
        createWorldObjectMenuEntry(garbageDisposalItem, garbageDisposalSquare, worldobjects, player, playerIndex, context);
    end
end

local function createInventoryMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex);

    if #items > 1 then
        return;
    end

    local playerInventory = player:getInventory();

    local item;
    local stack;

    -- Iterate through all clicked items
    for _, entry in ipairs(items) do
        local isGarbageDisposalItem = instanceof(entry, "InventoryItem") and (entry:getType() == "RPIncinerator" or entry:getType() == "RPLandfill");

        if isGarbageDisposalItem then
            item = entry;
            break;
        elseif type(entry) == "table" then
            stack = entry;
            break;
        end
    end

    if item then
        createInventoryObjectMenuEntry(player, playerIndex, context, item);
        return;
    end

    if stack and stack.items then
        for i = 1, #stack.items do
            local stackItem = stack.items[i];
            local isGarbageDisposalItem = instanceof(stackItem, "InventoryItem") and (stackItem:getType() == "RPIncinerator" or stackItem:getType() == "RPLandfill");

            if isGarbageDisposalItem then
                createInventoryObjectMenuEntry(player, playerIndex, context, stackItem);
                return;
            end
        end
    end
end

Events.OnPreFillWorldObjectContextMenu.Add(createWorldObjectMenu);
Events.OnPreFillInventoryObjectContextMenu.Add(createInventoryMenu);

Events.OnFillWorldObjectContextMenu.Add(ISIncineratorMenu.doWorldObjectIncinerateMenu);
Events.OnPreFillInventoryObjectContextMenu.Add(ISIncineratorMenu.doInventoryIncinerateMenu);

Events.OnFillWorldObjectContextMenu.Add(ISLandfillMenu.doDigLandfillMenu);
Events.OnFillWorldObjectContextMenu.Add(ISLandfillMenu.doWorldFillLandfillMenu);
Events.OnPreFillInventoryObjectContextMenu.Add(ISLandfillMenu.doInventoryFillLandfillMenu);