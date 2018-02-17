--RPTDUITagModal forked from code written by RoboMat for Convenient Bags http://steamcommunity.com/sharedfiles/filedetails/?id=670807387
require('UI/RPISTextEntryWithEnterBox');
RPTDUITagModal = ISPanel:derive("RPTDUITagModal");

local DEFAULT_FONT = UIFont.Small;
local BUTTON_ADD_ID = 'ADD';
local BUTTON_REMOVE_ID = 'REMOVE';
local BUTTON_DISMISS_ID = 'DISMISS';

function RPTDUITagModal:initialise()
    ISPanel.initialise(self);

    local fontHgt = getTextManager():getFontFromEnum(DEFAULT_FONT):getLineHeight();
    local buttonAddW = getTextManager():MeasureStringX(DEFAULT_FONT, "Add") + 12;
    local buttonRemW = getTextManager():MeasureStringX(DEFAULT_FONT, "Remove") + 12;
    local buttonDismissW = getTextManager():MeasureStringX(DEFAULT_FONT, "Dismiss") + 12;
    local textboxHgt = 20;
    local textboxW = 20;

    local buttonHgt = fontHgt + 6
    local padding = 5;

    local totalWidth = buttonAddW + padding + buttonRemW + padding + buttonDismissW;

    -- Create button for adding
    local posX = self:getWidth() * 0.5 - totalWidth * 0.5;
    self.add = ISButton:new(posX, self:getHeight() - 12 - buttonHgt, buttonAddW, buttonHgt, 'Add', self, RPTDUITagModal.onClick);
    self.add.internal = BUTTON_ADD_ID;
    self.add:initialise();
    self.add:instantiate();
    self.add.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.add);

    -- Create button for removal
    posX = posX + buttonAddW + padding;
    self.rem = ISButton:new(posX, self:getHeight() - 12 - buttonHgt, buttonRemW, buttonHgt, 'Remove', self, RPTDUITagModal.onClick);
    self.rem.internal = BUTTON_REMOVE_ID;
    self.rem:initialise();
    self.rem:instantiate();
    self.rem.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.rem);

    -- Create button for aborting
    posX = posX + buttonRemW + padding;
    self.dismiss = ISButton:new(posX, self:getHeight() - 12 - buttonHgt, buttonDismissW, buttonHgt, 'Dismiss', self, RPTDUITagModal.onClick);
    self.dismiss.internal = BUTTON_DISMISS_ID;
    self.dismiss:initialise();
    self.dismiss:instantiate();
    self.dismiss.borderColor = {r=1, g=1, b=1, a=0.1};
    self:addChild(self.dismiss);

    self.fontHgt = getTextManager():getFontFromEnum(DEFAULT_FONT):getLineHeight()
    local inset = 2
    local height = inset + self.fontHgt + inset
    self.entry = RPISTextEntryWithEnterBox:new(self.defaultEntryText, self:getWidth() / 2 - ((self:getWidth() - 40) / 2), 120, self:getWidth() - 40, height, self, self.add, self.player, false);
    self.entry:initialise();
    self.entry:instantiate();
    self:addChild(self.entry);

    posX = posX + buttonAddW + padding;

    self.tagList = RPTDUIScrollingListBox:new(10, 25, 260, 80, self.player);
    self.tagList:setFont(getTextManager():getFontFromEnum(DEFAULT_FONT));
    self.tagList:setOnMouseDoubleClick(RPTDlistItemDoubleClickEvent, self.entry, 1, 1);

    local modData = getSpecificPlayer(self.player):getModData();

    if modData.rptdtags then
        self.tagList:renderItemsFromModData(modData.rptdtags);
    end

    self.tagList:initialise();
    self:addChild(self.tagList);

    self.entry:focus();
end

function RPTDlistItemDoubleClickEvent(removedItem, target)
    local targetText = target:getText();
    local removedItemText = removedItem.text;

    if targetText ~= '' and targetText ~= removedItemText and
        targetText:match(',%s*' .. removedItemText) == nil and targetText:match(removedItemText .. ',%s*') == nil then
        target:setText(targetText .. ', ' .. removedItemText);
        target:focus();
    elseif targetText == '' then
        target:setText(removedItemText);
        target:focus();
    end
end

function RPTDUITagModal:clearAndFocusEntry()
    self.entry:setText('');
    self.entry:focus();
end

function RPTDUITagModal:setOnlyNumbers(onlyNumbers)
    self.entry:setOnlyNumbers(onlyNumbers);
end

function RPTDUITagModal:destroy()
    self:setVisible(false);
    self:removeFromUIManager();
end

function RPTDUITagModal:onClick(button)
    if self.onclick then
        self.onclick(button, self.player, self);
    end
end

function RPTDUITagModal:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
    self:drawTextCentre(self.text, self:getWidth() / 2, 5, 1, 1, 1, 1, DEFAULT_FONT);
end

function RPTDUITagModal:render()
    return;
end

function RPTDUITagModal:new(x, y, width, height, onclick, player)
    local o = ISPanel:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    -- TODO rewrite
    local playerObj = player and getSpecificPlayer(player) or nil
    if y == 0 then
        if playerObj and playerObj:getJoypadBind() ~= -1 then
            o.y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
        else
            o.y = o:getMouseY() - (height / 2)
        end
        o:setY(o.y)
    end
    if x == 0 then
        if playerObj and playerObj:getJoypadBind() ~= -1 then
            o.x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
        else
            o.x = o:getMouseX() - (width / 2)
        end
        o:setX(o.x)
    end

    o.backgroundColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.5 };
    o.borderColor     = { r = 0.4, g = 0.4, b = 0.4, a = 1.0 };

    local txtWidth = getTextManager():MeasureStringX(DEFAULT_FONT, text) + 10;
    o.width = width < txtWidth and txtWidth or width;
    o.height = height;

    o.anchorLeft = true;
    o.anchorRight = false;  
    o.anchorTop = true;
    o.anchorBottom = false;
    o.moveWithMouse = true;

    o.text = "Edit trash tags:"
    o.onclick = onclick;
    o.player = player;
    o.defaultEntryText = '';
    return o;
end