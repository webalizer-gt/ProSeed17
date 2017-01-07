-- Events for DrivingLine Specialization
--
--	@author:		gotchTOM
--	@date: 			15-Dec-2016
--	@version: 	v1.25

SetDrivingLineEvent = {};
SetDrivingLineEvent_mt = Class(SetDrivingLineEvent, Event);

InitEventClass(SetDrivingLineEvent, "SetDrivingLineEvent");

function SetDrivingLineEvent:emptyNew()

  local self = Event:new(SetDrivingLineEvent_mt);
  return self;
end;

function SetDrivingLineEvent:new(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker)

  local self = SetDrivingLineEvent:emptyNew()
  self.vehicle = vehicle;
	self.drivingLineActiv = drivingLineActiv;
	self.dlMode = dlMode;
	self.currentDrive = currentDrive;
	self.isPaused = isPaused;
	self.nSMdrives = nSMdrives;
	self.smWorkwith = smWorkwith;
	self.allowPeMarker = allowPeMarker;
  return self;
end;

function SetDrivingLineEvent:readStream(streamId, connection)

  self.vehicle = readNetworkNodeObject(streamId);
	self.drivingLineActiv = streamReadBool(streamId);
	self.dlMode = streamReadInt8(streamId);
	self.currentDrive = streamReadInt8(streamId);
	self.isPaused = streamReadBool(streamId);
	self.nSMdrives = streamReadInt8(streamId);
	self.smWorkwith = streamReadInt8(streamId);
	self.allowPeMarker = streamReadBool(streamId);
  self:run(connection);
end;

function SetDrivingLineEvent:writeStream(streamId, connection)

  writeNetworkNodeObject(streamId, self.vehicle);
	streamWriteBool(streamId, self.drivingLineActiv);
	streamWriteInt8(streamId, self.dlMode);
	streamWriteInt8(streamId, self.currentDrive);
	streamWriteBool(streamId, self.isPaused);
	streamWriteInt8(streamId, self.nSMdrives);
	streamWriteInt8(streamId, self.smWorkwith);
	streamWriteBool(streamId, self.allowPeMarker);
end;

function SetDrivingLineEvent:run(connection)

	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle);
	end;
	if self.vehicle ~= nil then
		self.vehicle:setDrivingLine(self.drivingLineActiv, self.dlMode, self.currentDrive, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker, true);
	end;
end;

function SetDrivingLineEvent.sendEvent(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker, noEventSend)

	if g_server ~= nil then
		g_server:broadcastEvent(SetDrivingLineEvent:new(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker), nil, nil, vehicle);
	else
		g_client:getServerConnection():sendEvent(SetDrivingLineEvent:new(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker));
	end;
end;

SetPeMarkerEvent = {};
SetPeMarkerEvent_mt = Class(SetPeMarkerEvent, Event);

InitEventClass(SetPeMarkerEvent, "SetPeMarkerEvent");

function SetPeMarkerEvent:emptyNew()

    local self = Event:new(SetPeMarkerEvent_mt);
    return self;
end;

function SetPeMarkerEvent:new(vehicle, peMarkerActiv)

  local self = SetPeMarkerEvent:emptyNew()
  self.vehicle = vehicle;
	self.peMarkerActiv = peMarkerActiv;
  return self;
end;

function SetPeMarkerEvent:readStream(streamId, connection)

  self.vehicle = readNetworkNodeObject(streamId);
	self.peMarkerActiv = streamReadBool(streamId);
  self:run(connection);
end;

function SetPeMarkerEvent:writeStream(streamId, connection)
  writeNetworkNodeObject(streamId, self.vehicle);
	streamWriteBool(streamId, self.peMarkerActiv);
end;

function SetPeMarkerEvent:run(connection)

	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle);
	end;
	if self.vehicle ~= nil then
		self.vehicle:setPeMarker(self.peMarkerActiv, true);
	end;
end;

function SetPeMarkerEvent.sendEvent(vehicle, peMarkerActiv, noEventSend)
	if peMarkerActiv ~= vehicle.peMarkerActiv then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(SetPeMarkerEvent:new(vehicle, peMarkerActiv), nil, nil, vehicle);
			else
				g_client:getServerConnection():sendEvent(SetPeMarkerEvent:new(vehicle, peMarkerActiv));
			end;
		end;
	end;
end;


DrivingLineAreaEvent = {};
DrivingLineAreaEvent_mt = Class(DrivingLineAreaEvent, Event);

InitEventClass(DrivingLineAreaEvent, "DrivingLineAreaEvent");

function DrivingLineAreaEvent:emptyNew()
     local self = Event:new(DrivingLineAreaEvent_mt);
     self.className="DrivingLineAreaEvent";
     return self;
end;

function DrivingLineAreaEvent:new(cuttingAreas, limitToField)
    local self = DrivingLineAreaEvent:emptyNew()
    assert(table.getn(cuttingAreas) > 0);
    self.cuttingAreas = cuttingAreas;
    self.limitToField = limitToField;
    return self;
end;

function DrivingLineAreaEvent:readStream(streamId, connection)
    local limitToField = streamReadBool(streamId);
    local numAreas = streamReadUIntN(streamId, 4);

    local refX = streamReadFloat32(streamId);
    local refY = streamReadFloat32(streamId);
    local values = Utils.readCompressed2DVectors(streamId, refX, refY, numAreas*3-1, 0.01, true);
    for i=1,numAreas do
        local vi = i-1;
        local x = values[vi*3+1].x;
        local z = values[vi*3+1].y;
        local x1 = values[vi*3+2].x;
        local z1 = values[vi*3+2].y;
        local x2 = values[vi*3+3].x;
        local z2 = values[vi*3+3].y;
		Utils.updateDestroyCommonArea(x,z,x1,z1,x2,z2,limitToField);
    end;
end;


function DrivingLineAreaEvent:writeStream(streamId, connection)
    local numAreas = table.getn(self.cuttingAreas);
    streamWriteBool(streamId, self.limitToField);
    streamWriteUIntN(streamId, numAreas, 4);

    local refX, refY;
    local values = {};
    for i=1, numAreas do
      local d = self.cuttingAreas[i];
      if i==1 then
          refX = d[1];
          refY = d[2];
          streamWriteFloat32(streamId, d[1]);
          streamWriteFloat32(streamId, d[2]);
			else
        table.insert(values, {x=d[1], y=d[2]});
			end;
			table.insert(values, {x=d[3], y=d[4]});
      table.insert(values, {x=d[5], y=d[6]});
		end;
    assert(table.getn(values) == numAreas*3 - 1);
    Utils.writeCompressed2DVectors(streamId, refX, refY, values, 0.01);
end;

function DrivingLineAreaEvent:run(connection)
    --print("Error: Do not run DrivingLineAreaEvent locally");
end;

function DrivingLineAreaEvent.runLocally(cuttingAreas, limitToField)

    local numAreas = table.getn(cuttingAreas);

    local refX, refY;
    local values = {};
    for i=1, numAreas do
      local d = cuttingAreas[i];
			if i==1 then
        refX = d[1];
				refY = d[2];
      else
        table.insert(values, {x=d[1], y=d[2]});
      end;
      table.insert(values, {x=d[3], y=d[4]});
      table.insert(values, {x=d[5], y=d[6]});
    end;
    assert(table.getn(values) == numAreas*3 - 1);

    local values = Utils.simWriteCompressed2DVectors(refX, refY, values, 0.01, true);

    for i=1, numAreas do
        local vi = i-1;
        local x = values[vi*3+1].x;
        local z = values[vi*3+1].y;
        local x1 = values[vi*3+2].x;
        local z1 = values[vi*3+2].y;
        local x2 = values[vi*3+3].x;
        local z2 = values[vi*3+3].y;
		Utils.updateDestroyCommonArea(x,z,x1,z1,x2,z2,limitToField);
    end;
end;


RootVehGPS_Event = {};
RootVehGPS_Event_mt = Class(RootVehGPS_Event, Event);

InitEventClass(RootVehGPS_Event, "RootVehGPS_Event");

function RootVehGPS_Event:emptyNew()
    local self = Event:new(RootVehGPS_Event_mt);
    return self;
end;

function RootVehGPS_Event:new(object, lhX0, lhZ0)
    local self = RootVehGPS_Event:emptyNew()
    self.object = object;
    self.lhX0 = lhX0;
    self.lhZ0 = lhZ0;
    return self;
end;

function RootVehGPS_Event:readStream(streamId, connection)
  self.object = readNetworkNodeObject(streamId);
  self.lhX0 = streamReadFloat32(streamId);
  self.lhZ0 = streamReadFloat32(streamId);
  self:run(connection);
end;

function RootVehGPS_Event:writeStream(streamId, connection)
	writeNetworkNodeObject(streamId, self.object);
	streamWriteFloat32(streamId, self.lhX0);
	streamWriteFloat32(streamId, self.lhZ0);
end;

function RootVehGPS_Event:run(connection)

  if not connection:getIsServer() then
		g_server:broadcastEvent(RootVehGPS_Event:new(self.object, self.lhX0, self.lhZ0), nil, connection, self.object);
	end;
	if self.object ~= nil then
		self.object:setRootVehGPS(self.lhX0, self.lhZ0, true);
	end;
end;

function RootVehGPS_Event.sendEvent(object, lhX0, lhZ0, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(RootVehGPS_Event:new(object, lhX0, lhZ0), nil, nil, object);
		else
			g_client:getServerConnection():sendEvent(RootVehGPS_Event:new(object, lhX0, lhZ0));
		end;
	end;
end;