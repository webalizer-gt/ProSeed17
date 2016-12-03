-- Events for DrivingLine Specialization
--
--	@author:		gotchTOM 
--	@date: 			21-Nov-2013
--	@version: 	v1.23beta

SetDrivingLineEvent = {};
SetDrivingLineEvent_mt = Class(SetDrivingLineEvent, Event);

InitEventClass(SetDrivingLineEvent, "SetDrivingLineEvent");

function SetDrivingLineEvent:emptyNew()
  
  local self = Event:new(SetDrivingLineEvent_mt);
  self.className="SetDrivingLineEvent";
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

  local id = streamReadInt32(streamId); 
	self.drivingLineActiv = streamReadBool(streamId);   
	self.dlMode = streamReadInt8(streamId);   
	self.currentDrive = streamReadInt8(streamId);   
	self.isPaused = streamReadBool(streamId);   
	self.nSMdrives = streamReadInt8(streamId);  
	self.smWorkwith = streamReadInt8(streamId);   
	self.allowPeMarker = streamReadBool(streamId);    
  self.vehicle = networkGetObject(id); 
  self:run(connection);
	-- print("!!!!readStream! self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!
	-- print("readStream! self.drivingLineActiv: "..tostring(self.drivingLineActiv).." self.dlMode: "..tostring(self.dlMode).." self.currentDrive: "..tostring(self.currentDrive).." self.isPaused: "..tostring(self.isPaused).." self.nSMdrives: "..tostring(self.nSMdrives).." self.smWorkwith: "..tostring(self.smWorkwith).." self.allowPeMarker: "..tostring(self.allowPeMarker)) --!!!

end;

function SetDrivingLineEvent:writeStream(streamId, connection) 
  
  streamWriteInt32(streamId, networkGetObjectId(self.vehicle));	
	streamWriteBool(streamId, self.drivingLineActiv);	
	streamWriteInt8(streamId, self.dlMode);	
	streamWriteInt8(streamId, self.currentDrive);	
	streamWriteBool(streamId, self.isPaused);
	streamWriteInt8(streamId, self.nSMdrives);	
	streamWriteInt8(streamId, self.smWorkwith);	
	streamWriteBool(streamId, self.allowPeMarker);
	-- print("!!!!writeStream! self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!
	-- print("writeStream!self.drivingLineActiv: "..tostring(self.drivingLineActiv).." self.dlMode: "..tostring(self.dlMode).." self.currentDrive: "..tostring(self.currentDrive).." self.isPaused: "..tostring(self.isPaused).." self.nSMdrives: "..tostring(self.nSMdrives).." self.smWorkwith: "..tostring(self.smWorkwith)) --!!!

end;

function SetDrivingLineEvent:run(connection) 
  
	if not connection:getIsServer() then	
		for k, v in pairs(g_server.clientConnections) do
			if v ~= connection and not v:getIsLocal() then
				v:sendEvent(SetDrivingLineEvent:new(self.vehicle, self.drivingLineActiv, self.dlMode, self.currentDrive, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker));
			end;
		end;
	end;	
	self.vehicle:setDrivingLine(self.drivingLineActiv, self.dlMode, self.currentDrive, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker, true); 
	-- print("SetDrivingLineEvent:run(connection)") --!!!
end;

function SetDrivingLineEvent.sendEvent(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker, noEventSend)  
		
	if g_server ~= nil then  
		g_server:broadcastEvent(SetDrivingLineEvent:new(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker), nil, nil, vehicle);
		-- print("!!!!sendEvent: g_server:broadcast Event! vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		--print("sendEvent: g_server:broadcast Event! drivingLineActiv: "..tostring(drivingLineActiv).." dlMode: "..tostring(dlMode).." currentDrive: "..tostring(currentDrive).." isPaused: "..tostring(isPaused).." nSMdrives: "..tostring(nSMdrives).." smWorkwith: "..tostring(smWorkwith).." allowPeMarker: "..tostring(allowPeMarker)) --!!!
		
	else  
		g_client:getServerConnection():sendEvent(SetDrivingLineEvent:new(vehicle, drivingLineActiv, dlMode, currentDrive, isPaused, nSMdrives, smWorkwith, allowPeMarker));
		-- print("!!!!sendEvent: g_client:send Event! vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		--print("sendEvent: g_client:send Event! drivingLineActiv: "..tostring(drivingLineActiv).." dlMode: "..tostring(dlMode).." currentDrive: "..tostring(currentDrive).." isPaused: "..tostring(isPaused).." nSMdrives: "..tostring(nSMdrives).." smWorkwith: "..tostring(smWorkwith).." allowPeMarker: "..tostring(allowPeMarker)) --!!!
	end;
end;

SetPeMarkerEvent = {};
SetPeMarkerEvent_mt = Class(SetPeMarkerEvent, Event);

InitEventClass(SetPeMarkerEvent, "SetPeMarkerEvent");

function SetPeMarkerEvent:emptyNew()
  
    local self = Event:new(SetPeMarkerEvent_mt);
    self.className="SetPeMarkerEvent";
    return self;
end;

function SetPeMarkerEvent:new(vehicle, peMarkerActiv)

  local self = SetPeMarkerEvent:emptyNew()
  self.vehicle = vehicle;
	self.peMarkerActiv = peMarkerActiv;
  return self;
end;

function SetPeMarkerEvent:readStream(streamId, connection) 

  local id = streamReadInt32(streamId); 
	self.peMarkerActiv = streamReadBool(streamId);  
  self.vehicle = networkGetObject(id); 
  self:run(connection);
	-- print("readStream! self.peMarkerActiv: "..tostring(self.peMarkerActiv).." self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!

end;

function SetPeMarkerEvent:writeStream(streamId, connection) 
  
  streamWriteInt32(streamId, networkGetObjectId(self.vehicle));	
	streamWriteBool(streamId, self.peMarkerActiv);
	-- print("writeStream! self.peMarkerActiv: "..tostring(self.peMarkerActiv).." self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!

end;

function SetPeMarkerEvent:run(connection) 
  
	if not connection:getIsServer() then	
		for k, v in pairs(g_server.clientConnections) do
			if v ~= connection and not v:getIsLocal() then
				v:sendEvent(SetPeMarkerEvent:new(self.vehicle, self.peMarkerActiv));
			end;
		end;
	end;
	if self.vehicle ~= nil then
		self.vehicle:setPeMarker(self.peMarkerActiv, true); 
	end;	
	-- print("SetPeMarkerEvent:run(connection)") --!!!
end;

function SetPeMarkerEvent.sendEvent(vehicle, peMarkerActiv, noEventSend)  
		
	if g_server ~= nil then  
		g_server:broadcastEvent(SetPeMarkerEvent:new(vehicle, peMarkerActiv), nil, nil, vehicle);
		-- print("sendEvent: g_server:broadcast Event! peMarkerActiv: "..tostring(peMarkerActiv).." vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		
	else  
		g_client:getServerConnection():sendEvent(SetPeMarkerEvent:new(vehicle, peMarkerActiv));
		-- print("sendEvent: g_client:send Event! peMarkerActiv: "..tostring(peMarkerActiv).." vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		
	end;
end;

-- SetSPworkwidthEvent = {};
-- SetSPworkwidthEvent_mt = Class(SetSPworkwidthEvent, Event);

-- InitEventClass(SetSPworkwidthEvent, "SetSPworkwidthEvent");

-- function SetSPworkwidthEvent:emptyNew()
  
    -- local self = Event:new(SetSPworkwidthEvent_mt);
    -- self.className="SetSPworkwidthEvent";
    -- return self;
-- end;

-- function SetSPworkwidthEvent:new(vehicle, raise)

    -- local self = SetSPworkwidthEvent:emptyNew()
    -- self.vehicle = vehicle;
	-- self.raise = raise;
    -- return self;
-- end;

-- function SetSPworkwidthEvent:readStream(streamId, connection) 

    -- local id = streamReadInt32(streamId); 
	-- self.raise = streamReadBool(streamId);   
    -- self.vehicle = networkGetObject(id); 
    -- self:run(connection);
	-- print("!!!!readStream! self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!
	-- print("readStream! self.raise: "..tostring(self.raise)) --!!!

-- end;

-- function SetSPworkwidthEvent:writeStream(streamId, connection) 
  
    -- streamWriteInt32(streamId, networkGetObjectId(self.vehicle));	
	-- streamWriteBool(streamId, self.raise);
	-- print("!!!!writeStream! self.vehicle: "..tostring(self.vehicle).." streamId: "..tostring(streamId).." connection: "..tostring(connection)) --!!!
	-- print("writeStream! self.raise: "..tostring(self.raise)) --!!!

-- end;

-- function SetSPworkwidthEvent:run(connection) 
  
	-- if not connection:getIsServer() then	
		-- for k, v in pairs(g_server.clientConnections) do
			-- if v ~= connection and not v:getIsLocal() then
				-- v:sendEvent(SetSPworkwidthEvent:new(self.vehicle, self.raise));
			-- end;
		-- end;
	-- end;	
	-- self.vehicle:setSPworkwidth(self.raise, true); 
	-- print("SetSPworkwidthEvent:run(connection)") --!!!
-- end;

-- function SetSPworkwidthEvent.sendEvent(vehicle, raise, noEventSend)  
		
	-- if g_server ~= nil then  
		-- g_server:broadcastEvent(SetSPworkwidthEvent:new(vehicle, raise), nil, nil, vehicle);
		-- print("!!!!sendEvent: g_server:broadcast Event! vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		-- print("sendEvent: g_server:broadcast Event! raise: "..tostring(raise)) --!!!
		
	-- else  
		-- g_client:getServerConnection():sendEvent(SetSPworkwidthEvent:new(vehicle, raise));
		-- print("!!!!sendEvent: g_client:send Event! vehicle: "..tostring(vehicle).." noEventSend: "..tostring(noEventSend)) --!!!
		-- print("sendEvent: g_client:send Event! raise: "..tostring(raise)) --!!!
		
	-- end;
-- end;


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
