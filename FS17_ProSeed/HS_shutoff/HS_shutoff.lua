--
--	HS_shutoff
--	halfside shutoff of sowing machines
--
-- @author:  	webalizer
-- @date:			10-Dec-2016
-- @version:	v1.00
--
-- free for noncommerical-usage
--

HS_shutoff = {};

function SowingCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function HS_shutoff:load(savegame)
		self.setShutoff = SpecializationUtil.callSpecializationsFunction("setShutoff");
		self.updateShutoffGUI = SpecializationUtil.callSpecializationsFunction("updateShutoffGUI");

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

function HS_shutoff:keyEvent(unicode, sym, modifier, isDown)
end;

function HS_shutoff:mouseEvent(posX, posY, isDown, isUp, button)
end;

function HS_shutoff:update(dt)
	if self:getIsActiveForInput() then
		if self.ridgeMarkerState ~= nil then
			if InputBinding.hasEvent(InputBinding.IMPLEMENT_EXTRA3) then
				local rmState = self.ridgeMarkerState;
				if rmState == 0 then
					rmState = 1;
				else
					rmState = 0;
				end;
				--self:setRidgeMarkerState(rmState);
			end;
			if InputBinding.hasEvent(InputBinding.HS_SHUTOFF_RMright) then
				local rmState = self.ridgeMarkerState;
				if rmState == 0 then
					rmState = 2;
				else
					rmState = 0;
				end;
				self:setRidgeMarkerState(rmState);
			end;
		end;
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

function HS_shutoff:updateTick(dt)
end;

function HS_shutoff:draw()
	if self.isClient then
		g_currentMission:addHelpButtonText(SowingMachine.HS_SHUTOFF_TOGGLESHUTOFF, InputBinding.HS_SHUTOFF_TOGGLESHUTOFF, nil, GS_PRIO_HIGH);
		if self.ridgeMarkerState ~= nil then
			g_currentMission:addHelpButtonText(SowingMachine.HS_SHUTOFF_RMright, InputBinding.HS_SHUTOFF_RMright, nil, GS_PRIO_HIGH);
		end;
	end;
end;

function HS_shutoff:setShutoff(shutoff)
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
	local yOffset = 0.0195;
	if self.shutoff == 1 then
		self.hud1.grids.main.elements.barImage.uvs = {0,0.521+yOffset, 0,0.54+yOffset, 1,0.521+yOffset, 1,0.54+yOffset}
	elseif self.shutoff == 2 then
		self.hud1.grids.main.elements.barImage.uvs = {0,0.521+(2*yOffset), 0,0.54+(2*yOffset), 1,0.521+(2*yOffset), 1,0.54+(2*yOffset)}
	else
		self.hud1.grids.main.elements.barImage.uvs = {0,0.521, 0,0.54, 1,0.521, 1,0.54}
	end;
end;
