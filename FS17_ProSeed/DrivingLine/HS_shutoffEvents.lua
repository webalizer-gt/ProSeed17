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
end;

function HS_shutoffEvent:writeStream(streamId, connection)
  writeNetworkNodeObject(streamId, self.vehicle);
	streamWriteInt8(streamId, self.shutoff);
end;

function HS_shutoffEvent:run(connection)
	self.vehicle:setShutoff(self.shutoff, true);
  if not connection:getIsServer() then
    g_server:broadcastEvent(HS_shutoffEvent:new(self.vehicle, self.shutoff), nil, connection, self.vehicle);
  end;
end;

function HS_shutoffEvent.sendEvent(vehicle, shutoff, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(HS_shutoffEvent:new(vehicle, shutoff), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(HS_shutoffEvent:new(vehicle, shutoff));
		end;
	end;
end;
