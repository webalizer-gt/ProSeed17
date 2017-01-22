--
--	Fertilization
--	fertilizer switch
--
-- @author:  	gotchTOM
-- @date:			20-Jan-2017
-- @version:	v1.06
--
-- free for noncommerical-usage
--

Fertilization = {};

function Fertilization.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;
function Fertilization:preLoad(savegame)
	self.getIsTurnedOnAllowed = Utils.overwrittenFunction(self.getIsTurnedOnAllowed, Fertilization.getIsTurnedOnAllowed);
end;

function Fertilization:load(savegame)

	self.setFertilization = SpecializationUtil.callSpecializationsFunction("setFertilization");
	self.updateFertiGUI = SpecializationUtil.callSpecializationsFunction("updateFertiGUI");
	self:updateFertiGUI();
end;

function Fertilization:postLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.fertilization then
		self.activeModules.fertilization = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#fertilizationSwitchIsActiv"), self.activeModules.fertilization);
		self.allowsSpraying = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#fertilization"), self.allowsSpraying);
		self:updateFertiGUI();
	end;
end;

function Fertilization:readStream(streamId, connection)
	if self.allowsSpraying ~= nil then
		local allowsSpraying = streamReadBool(streamId);
		self:setFertilization(allowsSpraying, true)
	end;
end;

function Fertilization:writeStream(streamId, connection)
  if self.allowsSpraying ~= nil then
		streamWriteBool(streamId, self.allowsSpraying);
	end;
end;

function Fertilization:delete()
end;

function Fertilization:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Fertilization:keyEvent(unicode, sym, modifier, isDown)
end;

function Fertilization:getSaveAttributesAndNodes(nodeIdent)
	local attributes;
	if self.activeModules ~= nil and self.activeModules.fertilization ~= nil then
		attributes = 'fertilizationSwitchIsActiv="' .. tostring(self.activeModules.fertilization) ..'" fertilization="'..tostring(self.allowsSpraying)..'"';
	end;
	return attributes, nil;
end;

function Fertilization:update(dt)
end;

function Fertilization:updateTick(dt)
end;

function Fertilization:draw()
end;

function Fertilization:getIsTurnedOnAllowed(superFunc, isTurnedOn)
		local attacherVehicle = self:getRootAttacherVehicle();
    if not self.allowsSpraying and attacherVehicle.isMotorStarted then
        return true;
    end;
    if superFunc ~= nil then
        return superFunc(self, isTurnedOn);
    end;
    return true;
end;

function Fertilization:setFertilization(allowsSpraying, noEventSend)

	if noEventSend == nil or noEventSend == false then
		ProSeedFertilizationEvent.sendEvent(self, allowsSpraying, noEventSend);
	end;
	self.allowsSpraying = allowsSpraying;
	self:updateFertiGUI();
end;

function Fertilization:updateFertiGUI()
	if self.activeModules ~= nil then
		if self.activeModules.fertilization then
			self.hud1.grids.main.elements.fertilizer.value = self.allowsSpraying;
			self.hud1.grids.main.elements.fertilizer.isVisible = true;
		else
			self.hud1.grids.main.elements.fertilizer.isVisible = false;
			self.hud1.grids.config.elements.fertiModul.value = false;
		end;
	end;
end;


--
--
--
--
ProSeedFertilizationEvent = {};
ProSeedFertilizationEvent_mt = Class(ProSeedFertilizationEvent, Event);

InitEventClass(ProSeedFertilizationEvent, "ProSeedFertilizationEvent");

function ProSeedFertilizationEvent:emptyNew()
  local self = Event:new(ProSeedFertilizationEvent_mt);
  return self;
end;

function ProSeedFertilizationEvent:new(vehicle, allowsSpraying)
  local self = ProSeedFertilizationEvent:emptyNew()
  self.vehicle = vehicle;
	self.allowsSpraying = allowsSpraying;
  return self;
end;

function ProSeedFertilizationEvent:readStream(streamId, connection)
  self.vehicle = readNetworkNodeObject(streamId);
	self.allowsSpraying = streamReadBool(streamId);
  self:run(connection);
end;

function ProSeedFertilizationEvent:writeStream(streamId, connection)
  writeNetworkNodeObject(streamId, self.vehicle);
	streamWriteBool(streamId, self.allowsSpraying);
end;

function ProSeedFertilizationEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(ProSeedFertilizationEvent:new(self.vehicle, self.allowsSpraying), nil, connection, self.vehicle);
	end;
	if self.vehicle ~= nil then
		self.vehicle:setFertilization(self.allowsSpraying, true);
	end;
end;

function ProSeedFertilizationEvent.sendEvent(vehicle, allowsSpraying, noEventSend)
	if g_server ~= nil then
		g_server:broadcastEvent(ProSeedFertilizationEvent:new(vehicle, allowsSpraying), nil, nil, vehicle);
	else
		g_client:getServerConnection():sendEvent(ProSeedFertilizationEvent:new(vehicle, allowsSpraying));
	end;
end;