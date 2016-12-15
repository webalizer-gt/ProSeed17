-- MP Events for HS_shutoff Specialization
--
--	@author:		webalizer
--	@date: 			13-Dec-2016
--	@version: 	v1.01


-- shutoff state
HS_shutoffEvent = {};
HS_shutoffEvent_mt = Class(HS_shutoffEvent, Event);

InitEventClass(HS_shutoffEvent, "HS_shutoffEvent");

function HS_shutoffEvent:emptyNew()
  local self = Event:new(HS_shutoffEvent_mt);
  -- self.className="HS_shutoffEvent";
  return self;
end;

function HS_shutoffEvent:new(vehicle, shutoff)
  local self = HS_shutoffEvent:emptyNew()
  self.vehicle = vehicle;
  self.shutoff = shutoff;
  return self;
end;

function HS_shutoffEvent:readStream(streamId, connection)
  self.vehicle = readNetworkNodeObject(streamId);
  self.shutoff = streamReadInt8(streamId);
  self:run(connection);
	-- print("!!!!readStream! self.shutoff: "..tostring(self.shutoff).. " self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!
end;

function HS_shutoffEvent:writeStream(streamId, connection)
  writeNetworkNodeObject(streamId, self.vehicle);
	streamWriteInt8(streamId, self.shutoff);
	-- print("!!!!writeStream! self.shutoff: "..tostring(self.shutoff).." self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!
end;

function HS_shutoffEvent:run(connection)
-- print("!!!! HS_shutoffEvent:run(connection) -> self.vehicle:setShutoff(self.shutoff: "..tostring(self.shutoff)..", true)") --!!!
	self.vehicle:setShutoff(self.shutoff, true);
  if not connection:getIsServer() then
    g_server:broadcastEvent(HS_shutoffEvent:new(self.vehicle, self.shutoff), nil, connection, self.vehicle);
		-- print("!!!! HS_shutoffEvent:run(connection) -> g_server:broadcastEvent(HS_shutoffEvent:new(self.vehicle: "..tostring(self.vehicle)..", self.shutoff: "..tostring(self.shutoff).."), nil, connection, self.vehicle: "..tostring(self.vehicle)..")")
  end;
end;

function HS_shutoffEvent.sendEvent(vehicle, shutoff, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(HS_shutoffEvent:new(vehicle, shutoff), nil, nil, vehicle);
			-- print("!!!!sendEvent: g_server:broadcast Event! shutoff: "..tostring(shutoff).. " vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		else
			g_client:getServerConnection():sendEvent(HS_shutoffEvent:new(vehicle, shutoff));
			-- print("!!!!sendEvent: g_client:send Event! shutoff: "..tostring(shutoff).." vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		end;
	end;
end;
