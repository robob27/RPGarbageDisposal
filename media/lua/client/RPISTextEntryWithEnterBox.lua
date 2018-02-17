require "ISUI/ISTextEntryBox"

RPISTextEntryWithEnterBox = ISTextEntryBox:derive("RPISTextEntryWithEnterBox");

function RPISTextEntryWithEnterBox:onCommandEntered()
	self.parentWindow.onclick(self.buttonTarget, self.player, self.target);

	if self.destroyParentOnEntry then
		self.parentWindow:destroy();
	end
end

function RPISTextEntryWithEnterBox:new (title, x, y, width, height, parentWindow, buttonTarget, player, target, destroyParentOnEntry)
	local o = {}
	o = ISUIElement:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.x = x;
	o.y = y;
	o.title = title;
	o.backgroundColor = {r=0, g=0, b=0, a=0.5};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	o.width = width;
	o.height = height;
    o.keeplog = false;
    o.logIndex = 0;
	o.anchorLeft = true;
	o.anchorRight = false;
	o.anchorTop = true;
	o.anchorBottom = false;
	o.fade = UITransition.new()
	o.font = UIFont.Small
    o.currentText = title;
    o.onEnterKey = onEnterKey;
    o.parentWindow = parentWindow;
    o.buttonTarget = buttonTarget;
    o.player = player;
    o.target = target;
    o.destroyParentOnEntry = destroyParentOnEntry;
	return o
end