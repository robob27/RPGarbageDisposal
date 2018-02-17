RPTDUIScrollingListBox = ISScrollingListBox:derive("RPTDUIScrollingListBox");

function RPTDUIScrollingListBox:onMouseDoubleClick(x, y)
	if self.onmousedblclick and self.items[self.selected] ~= nil then
		local removedItem = self:removeItemByIndex(self.selected);
		
		self.onmousedblclick(removedItem, self.target1, self.target2, self.target3);
		
		local newModData = self:createModDataFromItems();
		local existingModData = getSpecificPlayer(self.player):getModData();

		existingModData.rptdtags = newModData;
	end
end

function RPTDUIScrollingListBox:renderItemsFromModData(modData)
	self:clear();
    if modData then
        for tag, _ in pairs(modData) do
            local itemQuantityTable = {};
            itemQuantityTable[tag] = _;
            self:addItem(tag);
        end
    end

    self:sort();
end

function RPTDUIScrollingListBox.sortByName(a, b)
    return not string.sort(a.text:lower(), b.text:lower());
end

function RPTDUIScrollingListBox:sort()
    table.sort(self.items, RPTDUIScrollingListBox.sortByName);
end

function RPTDUIScrollingListBox:createModDataFromItems()
	local newModData = {};

	for i = 1, #self.items do
		local item = self.items[i];

		newModData[item.text] = item.text;
	end

	return newModData;
end

function RPTDUIScrollingListBox:setOnMouseDoubleClick(onmousedblclick, target1, target2, target3)
	self.onmousedblclick = onmousedblclick;
	self.target1 = target1;
	self.target2 = target2;
	self.target3 = target3;
end

function RPTDUIScrollingListBox:new (x, y, width, height, player)
	local o = {}
	o = ISPanelJoypad:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.x = x;
	o.y = y;
	o:noBackground();
	o.backgroundColor = {r=0, g=0, b=0, a=0.8};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.9};
	o.altBgColor = {r=0.2, g=0.3, b=0.2, a=0.1}
	o.altBgColor = nil
	o.drawBorder = false
	o.width = width;
	o.height = height;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
	o.font = UIFont.Large
	o.fontHgt = getTextManager():getFontFromEnum(o.font):getLineHeight()
	o.itemPadY = 7
	o.itemheight = o.fontHgt + o.itemPadY * 2;
	o.selected = 1;
    o.count = 0;
	o.itemheightoverride = {}
	o.items = {}
	o.player = player;
	o.columns = {};
	return o
end
