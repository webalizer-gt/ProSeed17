--
--	HS_shutoff
--	halfside shutoff of sowing machines
--
-- @author:  	webalizer & gotchTOM
-- @date:			14-Dec-2016
-- @version:	v1.04
--
-- free for noncommerical-usage
--

HS_shutoff = {};
source(SowingSupp.path.."HS_shutoff/HS_shutoffEvents.lua");

function SowingCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function HS_shutoff:load(savegame)
		self.setShutoff = SpecializationUtil.callSpecializationsFunction("setShutoff");
		self.updateShutoffGUI = SpecializationUtil.callSpecializationsFunction("updateShutoffGUI");
		self.canFoldRidgeMarker = Utils.overwrittenFunction(self.canFoldRidgeMarker, HS_shutoff.canFoldRidgeMarker);
		self.newCanFoldRidgeMarker = HS_shutoff.newCanFoldRidgeMarker;

		local componentNr = string.sub(getXMLString(self.xmlFile, "vehicle.ai.areaMarkers#leftIndex"),1,1) +1;
		self.areaRootNode = self.components[componentNr].node;
		local workAreas;
		for _,workArea in pairs(self.workAreaByType) do
			for _,a in pairs(workArea) do
				local areaTypeStr = WorkArea.areaTypeIntToName[a.type];
				if areaTypeStr == "sowingMachine" then
					workAreas = self.workAreaByType[a.type];
				end;
			end;
		end;
		if workAreas ~= nil then
			--for k,v in pairs(workAreas[1].refNode) do
			--	logInfo(1,('workAreas.%s: %s'):format(k,v));
			--end;
			for _,workArea in pairs(workAreas) do
				local x1,y1,z1 = getWorldTranslation(workArea.start);
				local x2,y2,z2 = getWorldTranslation(workArea.width);
				local x3,y3,z3 = getWorldTranslation(workArea.height);
				self.origWorkArea = {};
				self.origWorkArea.start, self.origWorkArea.width, self.origWorkArea.height = {},{},{};
				self.origWorkArea.start.id = workArea.start;
				self.origWorkArea.width.id = workArea.width;
				self.origWorkArea.height.id = workArea.height;
				self.origWorkArea.start.x, self.origWorkArea.start.y, self.origWorkArea.start.z = worldToLocal(self.areaRootNode,x1,y1,z1);
				self.origWorkArea.width.x, self.origWorkArea.width.y, self.origWorkArea.width.z = worldToLocal(self.areaRootNode,x2,y2,z2);
				self.origWorkArea.height.x, self.origWorkArea.height.y, self.origWorkArea.height.z = worldToLocal(self.areaRootNode,x3,y3,z3);
				logInfo(1,('lx1: %s, lx2: %s, lx3: %s'):format(self.origWorkArea.start.x, self.origWorkArea.width.x, self.origWorkArea.height.x));
			end;
		end;
		self.shutoff = 0;
end;

function HS_shutoff:delete()
end;

function HS_shutoff:readStream(streamId, connection)
  local shutoff = streamReadInt8(streamId);
	self:setShutoff(shutoff, true);
end;

function HS_shutoff:writeStream(streamId, connection)
  streamWriteInt8(streamId, self.shutoff);
end;

function HS_shutoff:keyEvent(unicode, sym, modifier, isDown)
end;

function HS_shutoff:mouseEvent(posX, posY, isDown, isUp, button)
end;

function HS_shutoff:update(dt)
	if self:getIsActiveForInput() then
		if self.numRigdeMarkers > 1 then
			if InputBinding.hasEvent(self.ridgeMarkerInputButton) then
				local rmState = self.ridgeMarkerState;
				if rmState == 0 then
					rmState = 1;
				else
					rmState = 0;
				end;
				if self:newCanFoldRidgeMarker(rmState) then
					self:setRidgeMarkerState(rmState);
				end;	
			end;
			if InputBinding.hasEvent(InputBinding.HS_SHUTOFF_RMright) then
				local rmState = self.ridgeMarkerState;
				if rmState == 0 then
					rmState = 2;
				else
					rmState = 0;
				end;
				if self:newCanFoldRidgeMarker(rmState) then
					self:setRidgeMarkerState(rmState);
				end;	
			end;
		end;
		if self.drivingLineActiv == nil or not self.drivingLineActiv then
			if InputBinding.hasEvent(InputBinding.HS_SHUTOFF_TOGGLESHUTOFF) then
				local shutoff = self.shutoff + 1;
				if shutoff > 2 then
					shutoff = 0;
				end;
				logInfo(1,('shutoff: %s'):format(shutoff));
				self:setShutoff(shutoff);
			end;
		end;
	end;
 end;

function HS_shutoff:updateTick(dt)
end;

function HS_shutoff:draw()
	--if self.isClient then
		if self.drivingLineActiv == nil or not self.drivingLineActiv then
			g_currentMission:addHelpButtonText(SowingMachine.HS_SHUTOFF_TOGGLESHUTOFF, InputBinding.HS_SHUTOFF_TOGGLESHUTOFF, nil, GS_PRIO_VERY_HIGH);
		end;
		if self.numRigdeMarkers > 1 then
			g_currentMission:addHelpButtonText(SowingMachine.HS_SHUTOFF_RMright, InputBinding.HS_SHUTOFF_RMright, nil, GS_PRIO_VERY_HIGH);
		end;
	--end;
	
	-- renderText(0.1,0.12,0.02,"self.ridgeMarkerState: "..tostring(self.ridgeMarkerState))	
end;

function HS_shutoff:setShutoff(shutoff, noEventSend)
  --synchronize shutoff state in mp
  HS_shutoffEvent.sendEvent(self, shutoff, noEventSend);

	if shutoff == 1 then
		if self.origWorkArea.start.x < 0 then
			setTranslation(self.origWorkArea.start.id, 0, self.origWorkArea.start.y, self.origWorkArea.start.z);
		elseif self.origWorkArea.width.x < 0 then
			setTranslation(self.origWorkArea.width.id, 0, self.origWorkArea.width.y, self.origWorkArea.width.z);
		end;
		if self.origWorkArea.height.x < 0 then
			setTranslation(self.origWorkArea.height.id, 0, self.origWorkArea.height.y, self.origWorkArea.height.z);
		end;
	elseif shutoff == 2 then
		if self.origWorkArea.start.x > 0 then
			setTranslation(self.origWorkArea.start.id, 0, self.origWorkArea.start.y, self.origWorkArea.start.z);
			setTranslation(self.origWorkArea.width.id, self.origWorkArea.width.x, self.origWorkArea.width.y, self.origWorkArea.width.z);
		elseif self.origWorkArea.width.x > 0 then
			setTranslation(self.origWorkArea.width.id, 0, self.origWorkArea.width.y, self.origWorkArea.width.z);
			setTranslation(self.origWorkArea.start.id, self.origWorkArea.start.x, self.origWorkArea.start.y, self.origWorkArea.start.z);
		end;
		if self.origWorkArea.height.x > 0 then
			setTranslation(self.origWorkArea.height.id, 0, self.origWorkArea.height.y, self.origWorkArea.height.z);
		else
			setTranslation(self.origWorkArea.height.id, self.origWorkArea.height.x, self.origWorkArea.height.y, self.origWorkArea.height.z);
		end;
	elseif shutoff == 0 then
		setTranslation(self.origWorkArea.start.id, self.origWorkArea.start.x, self.origWorkArea.start.y, self.origWorkArea.start.z);
		setTranslation(self.origWorkArea.width.id, self.origWorkArea.width.x, self.origWorkArea.width.y, self.origWorkArea.width.z);
		setTranslation(self.origWorkArea.height.id, self.origWorkArea.height.x, self.origWorkArea.height.y, self.origWorkArea.height.z);
	end;
	self.shutoff = shutoff;
	self:updateShutoffGUI();
end;

function HS_shutoff:updateShutoffGUI()
	-- print("updateShutoffGUI() -> self.shutoff: "..tostring(self.shutoff))
	local yOffset = 0.0195;
	if self.shutoff == 1 then
		self.hud1.grids.main.elements.barImage.uvs = {0,0.521+yOffset, 0,0.54+yOffset, 1,0.521+yOffset, 1,0.54+yOffset}
	elseif self.shutoff == 2 then
		self.hud1.grids.main.elements.barImage.uvs = {0,0.521+(2*yOffset), 0,0.54+(2*yOffset), 1,0.521+(2*yOffset), 1,0.54+(2*yOffset)}
	else
		self.hud1.grids.main.elements.barImage.uvs = {0,0.521, 0,0.54, 1,0.521, 1,0.54}
	end;
end;

function HS_shutoff:newCanFoldRidgeMarker(state)
  if self.foldAnimTime ~= nil and (self.foldAnimTime < self.ridgeMarkerMinFoldTime or self.foldAnimTime > self.ridgeMarkerMaxFoldTime) then
      return false;
  end;
  if state ~= 0 and not self.moveToMiddle and self.foldDisableDirection ~= nil and (self.foldDisableDirection == self.foldMoveDirection or self.foldMoveDirection == 0) then
      return false;
  end;
  return true;
end;

function HS_shutoff:canFoldRidgeMarker(state)
	return false;
end;
