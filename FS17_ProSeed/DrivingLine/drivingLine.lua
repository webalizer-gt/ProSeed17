--
-- DrivingLine
-- Specialization for driving lines of sowing machines
--
--	@author:		gotchTOM & webalizer
--	@date: 			11-Jan-2018
--	@version: 	v1.6.19
--	@history:		v1.0 	- initial implementation (17-Jun-2012)
--							v1.5  - SowingSupplement implementation
--							v1.6  -


DrivingLine = {};

source(SowingSupp.path.."DrivingLine/drivingLine_Events.lua");
source(SowingSupp.path.."DrivingLine/HS_shutoffEvents.lua");

function DrivingLine.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function DrivingLine:preLoad(savegame)
    self.loadSpeedRotatingPartFromXML = Utils.overwrittenFunction(self.loadSpeedRotatingPartFromXML, DrivingLine.loadSpeedRotatingPartFromXML);
end

function DrivingLine:load(savegame)
	local workAreas;
	for _,workArea in pairs(self.workAreaByType) do
		for _,a in pairs(workArea) do
			local areaTypeStr = WorkArea.areaTypeIntToName[a.type];
			if areaTypeStr == "sowingMachine" then
				workAreas = self.workAreaByType[a.type];
				self.hasSowingMachineWorkArea = true;
			end;
		end;
	end;
	if not self.hasSowingMachineWorkArea then
		print(tostring(self.typeName).." has no workarea of type sowingMachine -> DrivingLine can not be used!")
		return;
	end;
	self.setDrivingLine = SpecializationUtil.callSpecializationsFunction("setDrivingLine");
	self.setSPworkwidth = SpecializationUtil.callSpecializationsFunction("setSPworkwidth");
	self.setPeMarker = SpecializationUtil.callSpecializationsFunction("setPeMarker");
	self.updateDriLiGUI = SpecializationUtil.callSpecializationsFunction("updateDriLiGUI");
	self.workAreaMinMaxHeight = SpecializationUtil.callSpecializationsFunction("self.workAreaMinMaxHeight");
	self.workAreaMinMaxHeight = DrivingLine.workAreaMinMaxHeight;
	self.setRootVehGPS = SpecializationUtil.callSpecializationsFunction("setRootVehGPS");
	local numDrivingLines = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.drivingLines#count"),0);
	local numPeMarkerLines = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.peMarkerLines#count"),0);

	if numDrivingLines == 0 or numPeMarkerLines == 0 then
    self.getIsSpeedRotatingPartActive = Utils.overwrittenFunction(self.getIsSpeedRotatingPartActive, DrivingLine.getIsSpeedRotatingPartActive);
		local componentNr = string.sub(getXMLString(self.xmlFile, "vehicle.ai.areaMarkers#leftIndex"),1,1) +1;
		self.dlRootNode = self.components[componentNr].node;
		if workAreas ~= nil then
			self:workAreaMinMaxHeight(workAreas);
			local workWidth = math.abs(self.xMax-self.xMin);
			local round = math.floor(workWidth + 0.5);
			local diff = math.abs(workWidth - round);
			if diff == .5 then
				self.smWorkwith = workWidth;
			else
				self.smWorkwith = round;
			end;
			if workWidth > .1 then
				self.wwCenter = (self.xMin+self.xMax)/2;
				if math.abs(self.wwCenter) < 0.1 then
					self.wwCenter = 0;
				end;
			end;
			self.wwCenterPoint = createTransformGroup("wwCenterPoint");
			link(self.dlRootNode, self.wwCenterPoint);
			setTranslation(self.wwCenterPoint,self.wwCenter,self.yStart,self.zHeight-.2);
		end;
	end;

	if numDrivingLines > 0 then
		self.drivingLines = {}
		for i=1, numDrivingLines do
			self.drivingLines[i] = {};
			local areanamei = string.format("vehicle.drivingLines.drivingLine" .. "%d", i);
			self.drivingLines[i].start = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areanamei .. "#startIndex"));
			self.drivingLines[i].width = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areanamei .. "#widthIndex"));
			self.drivingLines[i].height = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areanamei .. "#heightIndex"));
		end;
		self.drivingLinePresent = true;
	else
		self.createDrivingLines = SpecializationUtil.callSpecializationsFunction("self.createDrivingLines");
		self.createDrivingLines = DrivingLine.createDrivingLines;
		local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
		self.dlLaneWidth = .6;
		self.dlLineWidth = 1.6;
		self.drivingLines = {}
		self.drivingLines = self:createDrivingLines();
	end;

	if numPeMarkerLines > 0 then
		self.peMarkerLines = {}
		for i=1, numPeMarkerLines do
			self.peMarkerLines[i] = {};
			local areanamei = string.format("vehicle.peMarkerLines.peMarkerLine" .. "%d", i);
			self.peMarkerLines[i].start = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areanamei .. "#startIndex"));
			self.peMarkerLines[i].width = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areanamei .. "#widthIndex"));
			self.peMarkerLines[i].height = Utils.indexToObject(self.components, getXMLString(self.xmlFile, areanamei .. "#heightIndex"));
		end;
		self.peMarkerPresent = true;
	else
		self.createPeMarkerLines = SpecializationUtil.callSpecializationsFunction("self.createPeMarkerLines");
		self.createPeMarkerLines = DrivingLine.createPeMarkerLines;
		self.peMarkerLines = {}
		self.peMarkerLines = self:createPeMarkerLines();
	end;

	if self.peMarkerPresent then
		self.peMarkerActiv = false;
		self.allowPeMarker = true;
	end;

	self.drivingLineActiv = false;
	self.IsLoweredBackUp = false;
	self.isPaused = false;
	self.dlCheckOnLeave = false;
	self.hasChanged = false;
	self.dlMode = 0; -- 0 = manual, 1 = semiAutomatic, 2 = automatic, 3 = GPS
	self.currentLane = 1; --currentDrive
	self.nSMdrives = 2;
	self.lastGPSlaneNo = -1;
	self.lastGPSActive = false;
	if (self.nSMdrives%2 == 0) then -- gerade Zahl
		self.num_DrivingLine = (self.nSMdrives / 2) + 1;
	elseif (self.nSMdrives%2 ~= 0) then -- ungerade Zahl
		self.num_DrivingLine = (self.nSMdrives + 1) / 2;
	end;
	self.dlCultivatorDelay = 0;
	self.laneMarkers = {};
	local i = 0;
	while true do
			local key = string.format("vehicle.laneMarkers.laneMarker(%d)", i);
			if not hasXMLProperty(self.xmlFile, key) or self.animations == nil then
					break;
			end;
			local laneMarker = {};
			laneMarker.animName = getXMLString(self.xmlFile, key .. "#animName");
			table.insert(self.laneMarkers, laneMarker);
			i = i + 1;
	end;
	-------------------
	-- HS_shutoff
	-- halfside shutoff of sowing machines

	self.setShutoff = SpecializationUtil.callSpecializationsFunction("setShutoff");
	local componentNr = string.sub(getXMLString(self.xmlFile, "vehicle.ai.areaMarkers#leftIndex"),1,1) +1;
	self.areaRootNode = self.components[componentNr].node;
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

function DrivingLine:postLoad(savegame)
	if self.hasSowingMachineWorkArea then
		if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.drivingLine ~= nil then
			self.activeModules.drivingLine = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#drivingLineIsActiv"), self.activeModules.drivingLine);
			self.nSMdrives = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#nSMdrives"), self.nSMdrives);
			self.dlMode = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#dlMode"), self.dlMode);
			self.allowPeMarker = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#allowPeMarker"), self.allowPeMarker);
			self.currentLane = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#currentLane"), self.currentLane);
			local shutoff = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#shutoff"), self.shutoff);
			if shutoff ~= self.shutoff then
				self:setShutoff(shutoff);
			end;
			if (self.nSMdrives%2 == 0) then -- gerade Zahl
				self.num_DrivingLine = (self.nSMdrives / 2) + 1;
			elseif (self.nSMdrives%2 ~= 0) then -- ungerade Zahl
				self.num_DrivingLine = (self.nSMdrives + 1) / 2;
			end;
			self:updateDriLiGUI();
		end;
	end;
end;

function DrivingLine:delete()
end;

function DrivingLine:readStream(streamId, connection)
	if self.drivingLinePresent then
		self.drivingLineActiv = streamReadBool(streamId);
		self.dlMode = streamReadInt8(streamId);
		self.currentLane = streamReadInt8(streamId);
		self.nSMdrives = streamReadInt8(streamId);
		if (self.nSMdrives%2 == 0) then -- gerade Zahl
			self.num_DrivingLine = (self.nSMdrives / 2) + 1;
		elseif (self.nSMdrives%2 ~= 0) then -- ungerade Zahl
			self.num_DrivingLine = (self.nSMdrives + 1) / 2;
		end;
		self.isPaused = streamReadBool(streamId);
		self.allowPeMarker = streamReadBool(streamId);
		self.shutoff = streamReadInt8(streamId);
		self:updateDriLiGUI();
	end;
end;

function DrivingLine:writeStream(streamId, connection)
	if self.drivingLinePresent then
		streamWriteBool(streamId, self.drivingLineActiv);
		streamWriteInt8(streamId, self.dlMode);
		streamWriteInt8(streamId, self.currentLane);
		streamWriteInt8(streamId, self.nSMdrives);
		streamWriteBool(streamId, self.isPaused);
		streamWriteBool(streamId, self.allowPeMarker);
		streamWriteInt8(streamId, self.shutoff);
	end;
end;

function DrivingLine:getSaveAttributesAndNodes(nodeIdent)
	local attributes = "";
	if self.hasSowingMachineWorkArea and self.activeModules ~= nil and self.activeModules.drivingLine ~= nil then
		attributes = 'drivingLineIsActiv="'..tostring(self.activeModules.drivingLine)..'" nSMdrives="'..tostring(self.nSMdrives)..'" dlMode="'..tostring(self.dlMode)..'" allowPeMarker="'..tostring(self.allowPeMarker)..'" currentLane="'..tostring(self.currentLane)..'" shutoff="'..tostring(self.shutoff)..'"';
	end;
	return attributes, nil;
end;

function DrivingLine:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DrivingLine:keyEvent(unicode, sym, modifier, isDown)
end;

function DrivingLine:update(dt)
	if self:getIsActive() and self.hasSowingMachineWorkArea then
		if self.isClient and self:getIsActiveForInput() then
			if self.drivingLinePresent and self.activeModules ~= nil and self.activeModules.drivingLine then
				-- switch driving line / current drive / pause manually
				if InputBinding.hasEvent(InputBinding.DRIVINGLINE) then
					if self.dlMode == 0 then
						if self.drivingLineActiv then
							self:setDrivingLine(false, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
						else
							self:setDrivingLine(true, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
							self.dlCultivatorDelay = g_currentMission.time + 1000;
						end;
					elseif self.dlMode == 1 then
						if self.currentLane < self.nSMdrives then
							self.currentLane = self.currentLane + 1;
						else
							self.currentLane = 1;
						end;
						self:updateDriLiGUI();
					elseif self.dlMode == 2 then
						self.isPaused = not self.isPaused;
						self:updateDriLiGUI();
					elseif self.dlMode == 3 then
						local rootAttacherVehicle = self:getRootAttacherVehicle();
						if rootAttacherVehicle.GPSlaneNo ~= nil and rootAttacherVehicle.GPSlaneNo ~= 0 then
							local lhdX0 = rootAttacherVehicle.lhdX0
							local lhdZ0 = rootAttacherVehicle.lhdZ0
							local lhX0 = rootAttacherVehicle.lhX0 - rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdZ0;
							local lhZ0 = rootAttacherVehicle.lhZ0 + rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdX0;
							self:setRootVehGPS(lhX0, lhZ0);
						end;
					end;
				end;
				local rootAttacherVehicle = self:getRootAttacherVehicle();
				if InputBinding.hasEvent(InputBinding.DRIVINGLINE_TOGGLESHUTOFF) then
					if not self.drivingLineActiv then
						local shutoff = self.shutoff + 1;
						if shutoff > 2 then
							shutoff = 0;
						end;
						-- logInfo(1,('shutoff: %s'):format(shutoff));
						self:setShutoff(shutoff);
					end;
				end;
			end;
		end;
	end;
end;

function DrivingLine:setRootVehGPS(lhX0, lhZ0, noEventSend)
	RootVehGPS_Event.sendEvent(self, lhX0, lhZ0, noEventSend);
	local rootAttacherVehicle = self:getRootAttacherVehicle();
	if rootAttacherVehicle.GPSlaneNo ~= nil then
		rootAttacherVehicle.lhX0 = lhX0;
		rootAttacherVehicle.lhZ0 = lhZ0;
	end;

end;

function DrivingLine:updateTick(dt)
	if self.drivingLinePresent then
		if self:getIsActive() and self.activeModules.drivingLine then
			if self.dlMode > 0 and self.dlMode < 3 then
				if self.currentLane > self.nSMdrives then
					self.currentLane = 1;
				elseif self.currentLane < 1 then
					self.currentLane = self.nSMdrives;
				end;
				if self.currentLane == self.num_DrivingLine and not self.drivingLineActiv then
					self:setDrivingLine(true, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
					if self.allowPeMarker and not self.peMarkerActiv then
						self:setPeMarker(true);
					end;
				elseif self.currentLane ~= self.num_DrivingLine and self.drivingLineActiv then
					self:setDrivingLine(false, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
					if self.peMarkerActiv then
						self:setPeMarker(false);
					end;
				end;
			elseif self.dlMode == 3 then
				local rootAttacherVehicle = self:getRootAttacherVehicle();
				if rootAttacherVehicle.GPSlaneNo == nil then
					self.dlMode = 0;
				end;
				if rootAttacherVehicle.GPSActive ~= nil then
					if rootAttacherVehicle.GPSActive ~= self.lastGPSActive then
						self:updateDriLiGUI();
						self.lastGPSActive = rootAttacherVehicle.GPSActive;
					end;
					if rootAttacherVehicle.GPSlaneNo ~= self.lastGPSlaneNo then
						local x = math.abs(rootAttacherVehicle.GPSlaneNo)%self.nSMdrives;
						self.currentLane = x+1;
						if self.currentLane == self.num_DrivingLine and not self.drivingLineActiv then
							self:setDrivingLine(true, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
							if self.allowPeMarker and not self.peMarkerActiv then
								self:setPeMarker(true);
							end;
						elseif self.currentLane ~= self.num_DrivingLine and self.drivingLineActiv then
							self:setDrivingLine(false, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
							if self.peMarkerActiv then
								self:setPeMarker(false);
							end;
						end;
						self.lastGPSlaneNo = rootAttacherVehicle.GPSlaneNo;
						self:updateDriLiGUI();
					end;
				end;
			end;

			if self.IsLoweredBackUp ~= self.soMaIsLowered then
				if not self.soMaIsLowered then
					if self.dlMode == 2 and not self.isPaused then
						if self.currentLane < self.nSMdrives then
							self.currentLane = self.currentLane + 1;
						else
							self.currentLane = 1;
						end;
						self:updateDriLiGUI();
					end;
					self.IsLoweredBackUp = self.soMaIsLowered;
				else
					local hasGroundContact = false;
					for _, refNode in pairs(self.groundReferenceNodes) do
						local x,y,z = getWorldTranslation(refNode.node);
						local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z);
						if (terrainHeight + refNode.threshold) >= y then
							hasGroundContact = true;
							break;
						end;
					end;
					if not hasGroundContact then
						self.dlCultivatorDelay = g_currentMission.time + 500;
					end;
					if self.sowingMachineHasGroundContact then
						self.IsLoweredBackUp = self.soMaIsLowered;
					end;
				end;
			end;

			if self.isServer then
				if self.drivingLineActiv then
					local allowDrivingLine = self.soMaIsLowered;
					if allowDrivingLine and self.dlCultivatorDelay <= g_currentMission.time then
						local drivingLinesSend = {};
						for i=1, 2 do
							local area = self.drivingLines[i];
							local x,y,z = getWorldTranslation(area.start);
								if g_currentMission:getIsFieldOwnedAtWorldPos(x,z) then
									local x1,y1,z1 = getWorldTranslation(area.width);
									local x2,y2,z2 = getWorldTranslation(area.height);
									x = math.floor(x*10)*.1
									z = math.floor(z*10)*.1
									x1 = math.floor(x1*10)*.1
									z1 = math.floor(z1*10)*.1
									local wx,wz = x1-x, z1-z;
                  local hx,hz = x2-x, z2-z;
                  local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
                  x = math.floor(x*worldToDensity+0.5)/worldToDensity;
                  z = math.floor(z*worldToDensity+0.5)/worldToDensity;
                  x1, z1 = x+wx, z+wz;
                  x2, z2 = x+hx, z+hz;
									table.insert(drivingLinesSend, {x,z,x1,z1,x2,z2});
								end;
						end;
						if table.getn(drivingLinesSend) > 0 then
							DrivingLineAreaEvent.runLocally(drivingLinesSend, true);
							g_server:broadcastEvent(DrivingLineAreaEvent:new(drivingLinesSend, true));
						end;
						if self.peMarkerActiv then
							local peMarkerLinesSend = {};
							for i=1, 2 do
								local area = self.peMarkerLines[i];
								local x,y,z = getWorldTranslation(area.start);
								if g_currentMission:getIsFieldOwnedAtWorldPos(x,z) then
									local x1,y1,z1 = getWorldTranslation(area.width);
									local x2,y2,z2 = getWorldTranslation(area.height);
									local wx,wz = x1-x, z1-z;
									local hx,hz = x2-x, z2-z;
									local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
									local lcx,_,lcz = worldToLocal(self.wwCenterPoint,x,y,z);
									local xc,yc,zc = getWorldTranslation(self.wwCenterPoint);
									local diffStartXCenter = lcx;
									local diffStartZCenter = lcx;
									local xTemp = math.floor(x*worldToDensity+0.5)/worldToDensity;
									local zTemp = math.floor(z*worldToDensity+0.5)/worldToDensity;
									local diffStartXCenterTemp = math.abs(xc) - math.abs(xTemp)
									local diffStartZCenterTemp = math.abs(zc) - math.abs(zTemp)
									if i == 1 then
										if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) and math.abs(diffStartXCenter) > 1 then
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) and math.abs(diffStartZCenter) > 1 then
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;
									elseif i == 2 then
										if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) and math.abs(diffStartXCenter) > .9 then
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) and math.abs(diffStartZCenter) > .9 then
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;
									end;
									x1, z1 = x+wx, z+wz;
									x2, z2 = x+hx, z+hz;
									table.insert(peMarkerLinesSend, {x,z,x1,z1,x2,z2});
								end;
							end;
							if table.getn(peMarkerLinesSend) > 0 then
								local dx,_,dz = localDirectionToWorld(Utils.getNoNil(self.sowingDirectionNode, self.rootNode), 0, 0, 1);
                local angle = Utils.convertToDensityMapAngle(Utils.getYRotationFromDirection(dx, dz), g_currentMission.terrainDetailAngleMaxValue);
                Cultivator.processCultivatorAreas(self, peMarkerLinesSend, true, true, angle);
							end;
						end;
					end;
					if self.shutoff > 0 then --hsa abschalten wenn Fahrgasse aktiv
						local shutoff = 0;
						logInfo(1,('shutoff: %s'):format(shutoff));
						self:setShutoff(shutoff);
					end;
				end;
			end;

			if table.getn(self.laneMarkers) > 0 then
				for k,v in pairs(self.laneMarkers) do
					local name = v.animName;
					if self.soMaIsLowered then
						if self.peMarkerActiv and self.drivingLineActiv then
							if name ~= nil then
								if self.animations[name].currentTime ~= self.animations[name].duration then
									local animTime = self:getAnimationTime(name);
									self:playAnimation(name, 1, animTime, true);
								end;
							end;
						else
							local startTime = Utils.getNoNil(self.animations[name].startTime,0);
							if self.animations[name].currentTime ~= startTime then
								local animTime = self:getAnimationTime(name);
								self:playAnimation(name, -1, animTime, true);
							end;
						end;
					else
						if name ~= nil then
							local startTime = Utils.getNoNil(self.animations[name].startTime,0);
							if self.animations[name].currentTime ~= startTime then
								local animTime = self:getAnimationTime(name);
								self:playAnimation(name, -1, animTime, true);
							end;
						end;
					end;
				end;
			end;
		end;

		if self:getIsActiveForInput() then
			if not self.dlCheckOnLeave then
				self.dlCheckOnLeave = true;
			end;
		else
			if self.dlCheckOnLeave then
				if self.hasChanged then
					self:setDrivingLine(self.drivingLineActiv, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
					self.hasChanged = false;
				end;
				self.dlCheckOnLeave = false;
			end;
		end;
	end;
end;

function DrivingLine:draw()
	if self.isClient and self.drivingLinePresent then
		if self.activeModules ~= nil and self.activeModules.drivingLine then
			if self.dlMode == 0 then
				if self.drivingLineActiv then
					g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_OFF, InputBinding.DRIVINGLINE, nil, GS_PRIO_VERY_HIGH);
				else
					g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_ON, InputBinding.DRIVINGLINE, nil, GS_PRIO_VERY_HIGH);
				end;
			elseif self.dlMode == 1 then
				g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_SHIFT, InputBinding.DRIVINGLINE, nil, GS_PRIO_VERY_HIGH);
			elseif self.dlMode == 2 then
				if self.isPaused then
					g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_ENABLE, InputBinding.DRIVINGLINE, nil, GS_PRIO_VERY_HIGH);
				else
					g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_PAUSE, InputBinding.DRIVINGLINE, nil, GS_PRIO_VERY_HIGH);
				end;
			elseif self.dlMode == 3 then
				local rootAttacherVehicle = self:getRootAttacherVehicle();
				if rootAttacherVehicle ~= nil and rootAttacherVehicle.GPSActive then
					g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_GPSRESET, InputBinding.DRIVINGLINE, nil, GS_PRIO_VERY_HIGH);
				end;
			end;
			if not self.drivingLineActiv then
				g_currentMission:addHelpButtonText(SowingMachine.DRIVINGLINE_TOGGLESHUTOFF, InputBinding.DRIVINGLINE_TOGGLESHUTOFF, nil, GS_PRIO_VERY_HIGH);
			end;
		end;
	end;
end;

function DrivingLine:setDrivingLine(drivingLineActiv, dlMode, currentLane, isPaused, nSMdrives, smWorkwith, allowPeMarker, noEventSend)
	if noEventSend == nil or noEventSend == false then
		SetDrivingLineEvent.sendEvent(self, drivingLineActiv, dlMode, currentLane, isPaused, nSMdrives, smWorkwith, allowPeMarker, noEventSend);
	end;
	if drivingLineActiv ~= nil then
		self.drivingLineActiv = drivingLineActiv;
	end;
	if dlMode ~= nil then
		self.dlMode = dlMode;
	end;
	if currentLane ~= nil then
		self.currentLane = currentLane;
	end;
	if isPaused ~= nil then
		self.isPaused = isPaused;
	end;
	if nSMdrives ~= nil then
		self.nSMdrives = nSMdrives;
	end;
	if smWorkwith ~= nil then
		self.smWorkwith = smWorkwith;
	end;
	if allowPeMarker ~= nil then
		self.allowPeMarker = allowPeMarker;
	end;
	self:updateDriLiGUI();
end;

function DrivingLine:setSPworkwidth(raise, noEventSend)
	if not raise then
		if self.nSMdrives > 2 and self.spWorkwith < 73 then
			self.nSMdrives = self.nSMdrives - 1;
			if self.currentLane > self.nSMdrives then
				self.currentLane = self.nSMdrives;
			end;
		end;
	else
		if self.spWorkwith <= 57 then
			self.nSMdrives = self.nSMdrives + 1;
		end;
	end;
	self.lastGPSlaneNo = -1;
	self:updateDriLiGUI();
end;

function DrivingLine:setPeMarker(peMarkerActiv, noEventSend)
	if noEventSend == nil or noEventSend == false then
		SetPeMarkerEvent.sendEvent(self, peMarkerActiv, noEventSend);
	end;
	self.peMarkerActiv = peMarkerActiv;
end;

function DrivingLine:setShutoff(shutoff, noEventSend)
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
	self:updateDriLiGUI();
end;

function DrivingLine:workAreaMinMaxHeight(areas)
	self.xMin = 0;
	self.xMax = 0;
	self.yStart = 0;
	self.zHeight = 0;
	if areas ~= nil then
		for _,workArea in pairs(areas) do
			local x1,y1,z1 = getWorldTranslation(workArea.start);
			local x2,y2,z2 = getWorldTranslation(workArea.width);
			local x3,y3,z3 = getWorldTranslation(workArea.height);
			local lx1,ly1,lz1 = worldToLocal(self.dlRootNode,x1,y1,z1);
			local lx2,ly2,lz2 = worldToLocal(self.dlRootNode,x2,y2,z2);
			local lx3,ly3,lz3 = worldToLocal(self.dlRootNode,x3,y3,z3);

			self.xMin = math.min(self.xMin, lx1, lx2, lx3)
			self.xMax = math.max(self.xMax, lx1, lx2, lx3)
			self.yStart = ly1;
			self.zHeight = math.min(lz1, lz2, lz3);
		end;
	end;
end;

function DrivingLine:createDrivingLines()
	local drivingLines = {};
	local x = self.wwCenter + self.dlLineWidth;
	local y = self.yStart;
	local z = self.zHeight - .3;
	local hz = z - self.dlLaneWidth;
	for i=1, 2 do
		local startId = createTransformGroup("start"..i);
		link(self.dlRootNode, startId);
		setTranslation(startId,x,y,z);
		local heightId = createTransformGroup("height"..i);
		link(self.dlRootNode, heightId);
		setTranslation(heightId,x,y,hz);
		x = x - self.dlLaneWidth;
		local widthId = createTransformGroup("width"..i);
		link(self.dlRootNode, widthId);
		setTranslation(widthId,x,y,z);
		x = self.wwCenter - (self.dlLineWidth-self.dlLaneWidth);
		table.insert(drivingLines, {foldMinLimit=0,start=startId,height=heightId,foldMaxLimit=0.2,width=widthId});
	end;
	self.drivingLinePresent = true;
	return drivingLines;
end;

function DrivingLine:createPeMarkerLines()
	local peMarkerLines = {};
	local x = self.wwCenter + self.dlLineWidth;
	local y = self.yStart;
	local z = self.zHeight - .3;
	local hz = z - self.dlLaneWidth;
	for i=1, 2 do
		local startId = createTransformGroup("start"..i);
		link(self.dlRootNode, startId);
		setTranslation(startId,x,y,z);
		local heightId = createTransformGroup("height"..i);
		link(self.dlRootNode, heightId);
		setTranslation(heightId,x,y,hz);
		local widthId = createTransformGroup("width"..i);
		link(self.dlRootNode, widthId);
		setTranslation(widthId,x,y,z);
		x = self.wwCenter - (self.dlLineWidth-self.dlLaneWidth);
		table.insert(peMarkerLines, {foldMinLimit=0,start=startId,height=heightId,foldMaxLimit=0.2,width=widthId});
	end;
	self.peMarkerPresent = true;
	return peMarkerLines;
end;

function DrivingLine:updateDriLiGUI()
	if self.activeModules ~= nil then
		if self.activeModules.drivingLine then
			self.hud1.grids.main.elements.driLiMode.isVisible = true;
			local rootAttacherVehicle = self:getRootAttacherVehicle();
			if rootAttacherVehicle.GPSlaneNo ~= nil then
				self.hud1.grids.main.elements.gpsWidth.isVisible = true;
			else
				self.hud1.grids.main.elements.gpsWidth.isVisible = false;
			end;
			if self.dlMode == 0 then
				self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_MANUAL;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = false;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = true;
			elseif self.dlMode == 1 then
				self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_SEMIAUTO;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = true;
				self.hud1.grids.main.elements.driLiCurDrive.color = {1,1,1,1};
			elseif self.dlMode == 2 then
				if rootAttacherVehicle.GPSlaneNo ~= nil then
					self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_AUTO;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = true;
				else
					self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_AUTO;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = false;
				end;
				if self.isPaused then
					self.hud1.grids.main.elements.driLiCurDrive.color = {1,.1,0,1};
				else
					self.hud1.grids.main.elements.driLiCurDrive.color = {1,1,1,1};
				end;
			elseif self.dlMode == 3 then
				self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_GPS;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = false;
			end;

			self.hud1.grids.main.elements.driLiPeMarker.isVisible = true;
			self.hud1.grids.main.elements.driLiPeMarker.value = self.allowPeMarker;
			if self.allowPeMarker then
				if self.drivingLineActiv and not self.peMarkerActiv then
					self:setPeMarker(true);
				end;
			else
				if self.drivingLineActiv and self.peMarkerActiv then
					self:setPeMarker(false);
				end;
			end;

			local yOffset = 0.0195;
			if self.drivingLineActiv then
				self.hud1.grids.main.elements.barImage.uvs = {0,0.521-yOffset, 0,0.54-yOffset, 1,0.521-yOffset, 1,0.54-yOffset}
			elseif self.shutoff == 1 then
				self.hud1.grids.main.elements.barImage.uvs = {0,0.521+yOffset, 0,0.54+yOffset, 1,0.521+yOffset, 1,0.54+yOffset}
			elseif self.shutoff == 2 then
				self.hud1.grids.main.elements.barImage.uvs = {0,0.521+(2*yOffset), 0,0.54+(2*yOffset), 1,0.521+(2*yOffset), 1,0.54+(2*yOffset)}
			else
				self.hud1.grids.main.elements.barImage.uvs = {0,0.521, 0,0.54, 1,0.521, 1,0.54}
			end;

			self.hud1.grids.main.elements.info_workWidth.isVisible = true;
			self.hud1.grids.main.elements.info_workWidth.value = self.smWorkwith.."m";

			if self.dlMode > 0 then
				self.hud1.grids.main.elements.driLiSpWorkWidth.isVisible = true;
				self.spWorkwith = self.smWorkwith * self.nSMdrives;
				if (self.nSMdrives%2 == 0) then -- gerade Zahl
					self.num_DrivingLine = (self.nSMdrives / 2) + 1;
				elseif (self.nSMdrives%2 ~= 0) then -- ungerade Zahl
					self.num_DrivingLine = (self.nSMdrives + 1) / 2;
				end;
				self.hud1.grids.main.elements.driLiSpWorkWidth.value = self.spWorkwith.."m";

				if self.nSMdrives == 2 then
					self.hud1.grids.main.elements.driLiSpWorkWidth.buttonSet.button1IsActive = false;
					self.hud1.grids.main.elements.driLiSpWorkWidth.buttonSet.button2IsActive = true;
				elseif self.spWorkwith >= 57 then
					self.hud1.grids.main.elements.driLiSpWorkWidth.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiSpWorkWidth.buttonSet.button2IsActive = false;
				else
					self.hud1.grids.main.elements.driLiSpWorkWidth.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiSpWorkWidth.buttonSet.button2IsActive = true;
				end;

				self.hud1.grids.main.elements.driLiCurDrive.isVisible = true;
				self.hud1.grids.main.elements.driLiCurDrive.value = self.currentLane.." / "..self.nSMdrives;
				if self.dlMode == 3 then
					self.hud1.grids.main.elements.driLiCurDrive.buttonSet.button1IsActive = false;
					self.hud1.grids.main.elements.driLiCurDrive.buttonSet.button2IsActive = false;
					if rootAttacherVehicle.GPSActive then
						self.hud1.grids.main.elements.driLiCurDrive.color = {1,1,1,1};
					elseif not rootAttacherVehicle.GPSActive then
						self.hud1.grids.main.elements.driLiCurDrive.color = {1,.1,0,1};
					end;
				else
					self.hud1.grids.main.elements.driLiCurDrive.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiCurDrive.buttonSet.button2IsActive = true;
				end;

				self.hud1.grids.main.elements.info_numDrivingLine.isVisible = true;
				self.hud1.grids.main.elements.info_numDrivingLine.value = self.num_DrivingLine;
			elseif self.dlMode == 0 then
				self.hud1.grids.main.elements.driLiSpWorkWidth.isVisible = false;
				self.hud1.grids.main.elements.driLiCurDrive.isVisible = false;
				self.hud1.grids.main.elements.info_numDrivingLine.isVisible = false;
			end;
			self.hasChanged = true;
		else -- = not self.activeModules.drivingLine
			self.hud1.grids.main.elements.driLiSpWorkWidth.isVisible = false;
			self.hud1.grids.main.elements.driLiMode.isVisible = false;
			self.hud1.grids.main.elements.driLiPeMarker.isVisible = false;
			self.hud1.grids.main.elements.driLiCurDrive.isVisible = false;
			self.hud1.grids.main.elements.info_workWidth.isVisible = false;
			self.hud1.grids.main.elements.info_numDrivingLine.isVisible = false;
			self.hud1.grids.main.elements.gpsWidth.isVisible = false;
			self.hud1.grids.main.elements.barImage.uvs = {0,0.521, 0,0.54, 1,0.521, 1,0.54}

			self.hud1.grids.config.elements.driLiModul.value = false;
		end;
	end;
end;

function DrivingLine:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
    if superFunc ~= nil then
        if not superFunc(self, speedRotatingPart, xmlFile, key) then
            return false;
        end
    end
    speedRotatingPart.laneMarkerAnim = getXMLString(self.xmlFile, key .. "#laneMarkerAnim");
    speedRotatingPart.laneMarkerAnimTimeMax = Utils.getNoNil(getXMLFloat(self.xmlFile, key .. "#laneMarkerAnimTimeMax"), 0.99);
    return true;
end;

function DrivingLine:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
    if speedRotatingPart.laneMarkerAnim ~= nil and self:getAnimationTime(speedRotatingPart.laneMarkerAnim) < speedRotatingPart.laneMarkerAnimTimeMax then
        return false;
    end;
    if superFunc ~= nil then
        return superFunc(self, speedRotatingPart);
    end
    return true;
end;