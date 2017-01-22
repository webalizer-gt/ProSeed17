--
-- SowingCounter
-- Specialization for counting seeded hectars
--
-- source: 		threshing counter v2.3 by Manuel Leithner (edit by gotchTOM)
-- @author:  	Manuel Leithner/gotchTOM
-- @date:			17-Jan-2017
-- @version:	v1.06
-- @history:	v1.0 - initial implementation
--						v1.01 - part of SowingSupplement
--						v1.01 - FS 17
--
-- free for noncommerical-usage
--

SowingCounter = {};

local mod_directory = g_currentModDirectory;

function SowingCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function SowingCounter:load(xmlFile)

	if self.activeModules ~= nil and self.activeModules.sowingCounter then
		self.resetSessionHectars = SpecializationUtil.callSpecializationsFunction("resetSessionHectars");
		self.updateSoCoGUI = SpecializationUtil.callSpecializationsFunction("updateSoCoGUI");
		self.sowingCounter = {};
		self.sowingCounter.sessionHectars = 0;
		self.sowingCounter.sessionHectarsSent = 0;
		self.sowingCounter.totalHectars = 0;
		self.sowingCounter.totalHectarsSent = 0;
		self.sowingCounter.hectarTimer = 0;
		self.sowingCounter.hectarPerHour = 0;
		self.sowingCounter.hectarPerHourSent = 0;
		self.sowingCounter.sowingCounterDirtyFlag = self:getNextDirtyFlag();
		self:updateSoCoGUI();
	end;
end;

function SowingCounter:postLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.sowingCounter then
		self.activeModules.sowingCounter = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#sowingCounterIsActiv"), self.activeModules.sowingCounter);
		self.sowingCounter.totalHectars =  Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#totalHectars"), 0);
		self:updateSoCoGUI();
	end;
end;

function SowingCounter:delete()
end;

function SowingCounter:getSaveAttributesAndNodes(nodeIdent)
	local attributes = 'sowingCounterIsActiv="' .. tostring(self.activeModules.sowingCounter) ..'"';
	attributes = attributes.. ' totalHectars="' .. tostring(self.sowingCounter.totalHectars) ..'"';
	return attributes, nil;
end;

function SowingCounter:resetSessionHectars(sessionHectars, noEventSend)

	if noEventSend == nil or noEventSend == false then
		SoCoResetSessionHectarsEvent.sendEvent(self, sessionHectars, noEventSend);
	end;
	self.sowingCounter.sessionHectars = sessionHectars;
	self:updateSoCoGUI();
end;

function SowingCounter:readStream(streamId, connection)
	if self.activeModules ~= nil and self.activeModules.sowingCounter then
		local session = streamReadFloat32(streamId);
		local total = streamReadFloat32(streamId);
		local hectarTimer = streamReadFloat32(streamId);
		if self.sowingCounter ~= nil then
			self.sowingCounter.sessionHectars = session;
			self.sowingCounter.totalHectars = total;
			self.sowingCounter.sessionHectarsSent = self.sowingCounter.sessionHectars;
			self.sowingCounter.totalHectarsSent = self.sowingCounter.totalHectars;
			self.sowingCounter.hectarTimer = hectarTimer;
			self:updateSoCoGUI();
		end;
	end;
end;

function SowingCounter:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.sowingCounter.sessionHectars);
	streamWriteFloat32(streamId, self.sowingCounter.totalHectars);
	streamWriteFloat32(streamId, self.sowingCounter.hectarTimer);
end;

function SowingCounter:readUpdateStream(streamId, timestamp, connection)
  if connection:getIsServer() then
    if streamReadBool(streamId) then
			self.sowingCounter.sessionHectars = streamReadFloat32(streamId);
			self.sowingCounter.totalHectars = streamReadFloat32(streamId);
			self.sowingCounter.hectarTimer = streamReadFloat32(streamId);
    end;
  end;
end;

function SowingCounter:writeUpdateStream(streamId, connection, dirtyMask)
  if not connection:getIsServer() then
    if streamWriteBool(streamId, bitAND(dirtyMask, self.sowingCounter.sowingCounterDirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, self.sowingCounter.sessionHectarsSent);
			streamWriteFloat32(streamId, self.sowingCounter.totalHectarsSent);
			streamWriteFloat32(streamId, self.sowingCounter.hectarTimer);
    end;
  end;
end;

function SowingCounter:mouseEvent(posX, posY, isDown, isUp, button)
end;

function SowingCounter:keyEvent(unicode, sym, modifier, isDown)
end;

function SowingCounter:update(dt)
	if self:getIsActive() then
		if self:getIsActiveForInput(false) then
			if self.activeModules ~= nil and self.activeModules.sowingCounter then
				if InputBinding.hasEvent(InputBinding.SOWINGCOUNTER_RESETSESSIONHA) then
					local sessionHectars = 0;
					self:resetSessionHectars(sessionHectars);
				end;
			end;
		end;
	end;
end;

function SowingCounter:updateTick(dt)
	if self.activeModules ~= nil and self.activeModules.sowingCounter then
		if self:getIsTurnedOn() then
			local ha =  self.lastSowingArea;
			local session = self.sowingCounter.sessionHectars;
			local total = self.sowingCounter.totalHectars;
			self.sowingCounter.sessionHectars = session + ha;
			self.sowingCounter.totalHectars = total + ha;
			if math.abs(self.sowingCounter.sessionHectars - self.sowingCounter.sessionHectarsSent) > 0.01 or math.abs(self.sowingCounter.totalHectars - self.sowingCounter.totalHectarsSent) > 0.01 then
				self:raiseDirtyFlags(self.sowingCounter.sowingCounterDirtyFlag);
				self.sowingCounter.sessionHectarsSent = self.sowingCounter.sessionHectars;
				self.sowingCounter.totalHectarsSent = self.sowingCounter.totalHectars;
				if self.sosuHUDisActive then
					self:updateSoCoGUI();
				end;
			end;
			local timer = self.sowingCounter.hectarTimer;
			self.sowingCounter.hectarTimer = timer + dt;
			local hectarTimer = self.sowingCounter.hectarTimer/3600000
			self.sowingCounter.hectarPerHour = self.sowingCounter.sessionHectars/hectarTimer;
			if math.abs(self.sowingCounter.hectarPerHour - self.sowingCounter.hectarPerHourSent) > 0.1 then
				self:updateSoCoGUI();
			end;
		end;
	end;
end;

function SowingCounter:draw()
end;

function SowingCounter:updateSoCoGUI()
	if self.activeModules ~= nil then
		if self.activeModules.sowingCounter then
			local counterSession = math.floor(self.sowingCounter.sessionHectars*100 + 0.5) / 100;
			local counterTotal = math.floor(self.sowingCounter.totalHectars*10 + 0.5) / 10;
			local fullSession = math.floor(counterSession);
			local fullTotal = math.floor(counterTotal);
			local deciSession = math.floor((counterSession - fullSession)*100);
			if deciSession < 10 then
				deciSession = "0" .. deciSession;
			end;
			local deciTotal = math.floor((counterTotal - fullTotal)*10);
			local counterHaPerHour = math.floor(self.sowingCounter.hectarPerHour*10 + 0.5) / 10;
			local fullHaPerHour = math.floor(counterHaPerHour);
			local deciHaPerHour = (counterHaPerHour - fullHaPerHour)*10;
			self.hud1.grids.main.elements.scSession.isVisible = true;
			self.hud1.grids.main.elements.scTotal.isVisible = true;
			self.hud1.grids.main.elements.scSession.value = fullSession.."."..deciSession.."ha   ("..fullHaPerHour.."."..deciHaPerHour.."ha/h)";
			self.hud1.grids.main.elements.scTotal.value = fullTotal.."."..deciTotal.."ha";
		else
			self.hud1.grids.main.elements.scSession.isVisible = false;
			self.hud1.grids.main.elements.scTotal.isVisible = false;
			self.hud1.grids.config.elements.soCoModul.value = false;
		end;
	end;
end;

--
--
--
--
SoCoResetSessionHectarsEvent = {};
SoCoResetSessionHectarsEvent_mt = Class(SoCoResetSessionHectarsEvent, Event);

InitEventClass(SoCoResetSessionHectarsEvent, "SoCoResetSessionHectarsEvent");

function SoCoResetSessionHectarsEvent:emptyNew()
  local self = Event:new(SoCoResetSessionHectarsEvent_mt);
  return self;
end;

function SoCoResetSessionHectarsEvent:new(vehicle, sessionHectars)
  local self = SoCoResetSessionHectarsEvent:emptyNew()
  self.vehicle = vehicle;
	self.sessionHectars = sessionHectars;
  return self;
end;

function SoCoResetSessionHectarsEvent:readStream(streamId, connection)
  self.vehicle = readNetworkNodeObject(streamId);
	self.sessionHectars = streamReadInt8(streamId);
  self:run(connection);
end;

function SoCoResetSessionHectarsEvent:writeStream(streamId, connection)
  writeNetworkNodeObject(streamId, self.vehicle);
	streamWriteInt8(streamId, self.sessionHectars);
end;

function SoCoResetSessionHectarsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(SoCoResetSessionHectarsEvent:new(self.vehicle, self.sessionHectars), nil, connection, self.vehicle);
	end;
	if self.vehicle ~= nil then
		self.vehicle:resetSessionHectars(self.sessionHectars, true);
	end;
end;

function SoCoResetSessionHectarsEvent.sendEvent(vehicle, sessionHectars, noEventSend)
	if g_server ~= nil then
		g_server:broadcastEvent(SoCoResetSessionHectarsEvent:new(vehicle, sessionHectars), nil, nil, vehicle);
	else
		g_client:getServerConnection():sendEvent(SoCoResetSessionHectarsEvent:new(vehicle, sessionHectars));
	end;
end;