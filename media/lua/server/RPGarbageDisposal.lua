local Commands = {};
local garbageDisposal = {};

local function getIncinceratorFromCommandArgs(args)
	local incineratorItem = nil;
	local x,y,z, uniqueID = args.x, args.y, args.z, args.uniqueID;
	local incineratorSquare = getWorld():getCell():getGridSquare(x, y, z);
	local worldObjects = incineratorSquare:getWorldObjects();

	Commands.serverTestNoise({ message = '>>>> LOCALS ASSIGNED..' });

	for i=0, worldObjects:size()-1 do
		Commands.serverTestNoise({ message = '>>>> LOOPING THROUGH WORLD OBJECTS..' });
		if worldObjects:get(i):getItem() and worldObjects:get(i):getItem():getType() == "RPIncinerator" then
			Commands.serverTestNoise({ message = '>>>>> INCINERATOR ITEM FOUND..' });
			local incineratorModData = worldObjects:get(i):getItem():getModData();
			Commands.serverTestNoise({ message = '>>>>> MOD DATA RETRIEVED..' });

			if incineratorModData.rptdUniqueID == uniqueID then
				Commands.serverTestNoise({ message = '>>>>> MOD DATA MATCH..' });
				incineratorItem = worldObjects:get(i):getItem();
			else
				Commands.serverTestNoise({ message = '>>>>>NO MOD DATA MATCH..' });
			end
		end
	end

	return incineratorItem;
end

function RP_onCreateIncinerator(items, incinerator, player)
	local modData = incinerator:getModData();
	modData.rptdUniqueID = player:getUsername() .. (ZombRand(1000000) + 1);
end

Commands.updateClientIncinerator = function(args)
	local incineratorItem = getIncinceratorFromCommandArgs(args);
	incineratorItem:getInventory():removeAllItems();
	incineratorItem:getInventory():setDrawDirty(true);
end

Commands.updateIncineratorContainer = function(playerObj, args)
	Commands.serverTestNoise({ message = '>>>> STARTING SERVER COMMAND..' });

	local incineratorItem = getIncinceratorFromCommandArgs(args);

	if incineratorItem ~= nil then
		incineratorItem:getInventory():removeAllItems();
		Commands.serverTestNoise({ message = '>>>>> INCINERATOR ITEMS REMOVED..' });
	else
		Commands.serverTestNoise({ message = '>>>>> NO INCINERATOR ITEM FOUND..' });
	end

	sendServerCommand('RPGarbageDisposal', 'updateClientIncinerator', args);

	Commands.serverTestNoise({ message = '>>>>> END OF SERVER COMMAND..' });
end

Commands.serverTestNoise = function(args)
	local test = false;

	if test == true then
		sendServerCommand('RPGarbageDisposal', 'printNoise', args);
	end
end

Commands.printNoise = function(args)
	print(args.message);
end

garbageDisposal.OnClientCommand = function(module, command, player, args)
	if not isServer() then return end
	if module ~= 'RPGarbageDisposal' then return end
	if Commands[command] then
		Commands[command](player, args);
	end
end

garbageDisposal.OnServerCommand = function(module, command, args)
	if not isClient() then return end
	if module ~= 'RPGarbageDisposal' then return end
	if Commands[command] then
		Commands[command](args);
	end
end

Events.OnServerCommand.Add(garbageDisposal.OnServerCommand);

if isServer() then
	Events.OnClientCommand.Add(garbageDisposal.OnClientCommand);
end