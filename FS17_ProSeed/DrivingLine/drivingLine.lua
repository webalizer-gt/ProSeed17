--
-- DrivingLine
-- Specialization for driving lines of sowing machines
--
--	@author:		gotchTOM & webalizer
--	@date: 			15-Dec-2016
--	@version: 	v1.6.12
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
    -- self.setSeedIndex = Utils.overwrittenFunction(self.setSeedIndex, DrivingLine.setSeedIndex);
end

function DrivingLine:load(savegame)

	self.setDrivingLine = SpecializationUtil.callSpecializationsFunction("setDrivingLine");
	self.setSPworkwidth = SpecializationUtil.callSpecializationsFunction("setSPworkwidth");
	self.setPeMarker = SpecializationUtil.callSpecializationsFunction("setPeMarker");
	self.updateDriLiGUI = SpecializationUtil.callSpecializationsFunction("updateDriLiGUI");
	self.workAreaMinMaxHeight = SpecializationUtil.callSpecializationsFunction("self.workAreaMinMaxHeight");
	self.workAreaMinMaxHeight = DrivingLine.workAreaMinMaxHeight;
	self.setRootVehGPS = SpecializationUtil.callSpecializationsFunction("setRootVehGPS");
	

	local numDrivingLines = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.drivingLines#count"),0);
	--print("DrivingLine load: numDrivingLines = "..tostring(numDrivingLines))--!!!
	local numPeMarkerLines = Utils.getNoNil(getXMLInt(self.xmlFile, "vehicle.peMarkerLines#count"),0);
	--print("DrivingLine load: numPeMarkerLines = "..tostring(numPeMarkerLines))--!!!
	
	if numDrivingLines == 0 or numPeMarkerLines == 0 then
	
    self.getIsSpeedRotatingPartActive = Utils.overwrittenFunction(self.getIsSpeedRotatingPartActive, DrivingLine.getIsSpeedRotatingPartActive);
    
		local componentNr = string.sub(getXMLString(self.xmlFile, "vehicle.ai.areaMarkers#leftIndex"),1,1) +1;
		self.dlRootNode = self.components[componentNr].node;
		local workAreas;
		for _,workArea in pairs(self.workAreaByType) do
			for _,a in pairs(workArea) do
				local areaTypeStr = WorkArea.areaTypeIntToName[a.type];
				if areaTypeStr == "sowingMachine" then
					workAreas = self.workAreaByType[a.type];
					--print("DrivingLine load: workarea.type = "..tostring(a.type).."  /  areaTypeStr = "..tostring(areaTypeStr))
				end;
			end;
		end;
		-- local workAreas = self:getTypedWorkAreas(WorkArea.AREATYPE_SOWINGMASHINE);
		-- print("workAreas = "..tostring(workAreas))
		if workAreas ~= nil then
			self:workAreaMinMaxHeight(workAreas);
			--print("DrivingLine load: xMin = "..tostring(self.xMin).."  xMax = "..tostring(self.xMax).."  yStart = "..tostring(self.yStart).."  zHeight = "..tostring(self.zHeight))
			local workWidth = math.abs(self.xMax-self.xMin);
			self.smWorkwith = math.floor(workWidth + 0.5);
			--print("DrivingLine load: smWorkwith = "..tostring(self.smWorkwith))
			if workWidth > .1 then
				self.wwCenter = (self.xMin+self.xMax)/2;
				if math.abs(self.wwCenter) < 0.1 then
					self.wwCenter = 0;
				end;
			end;
			self.wwCenterPoint = createTransformGroup("wwCenterPoint");
			link(self.dlRootNode, self.wwCenterPoint);
			setTranslation(self.wwCenterPoint,self.wwCenter,self.yStart,self.zHeight-.2);
		else
			self.drivingLinePresent = false;
			self.activeModules.drivingLine = false;
			self:updateDriLiGUI();
			--print(tostring(self.typeName).." has no workarea of type sowingMachine -> DrivingLine can not be used!")
			return
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
		self.dlLaneWidth = .02--.25*worldToDensity--0.4;--0.8;
		self.drivingLineWidth = 1--.75*worldToDensity;--+self.dlLaneWidth/2--1.2;--1.375;
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
	-- self.lastCurrentSeed = 0;
	-- self.blocksPerDensity = 0;

	self.dlMode = 0; -- 0 = manual, 1 = semiAutomatic, 2 = automatic, 3 = GPS
	self.currentLane = 1; --currentDrive
	self.nSMdrives = 3;
	self.lastGPSlaneNo = -1;
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
				-- print("load!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!self.animations[laneMarker.animName]"..tostring(self.animations[laneMarker.animName])) 	
			table.insert(self.laneMarkers, laneMarker);
			i = i + 1;
	end;
	
	-------------------
	-- HS_shutoff
	-- halfside shutoff of sowing machines
	
	self.setShutoff = SpecializationUtil.callSpecializationsFunction("setShutoff");
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

function DrivingLine:postLoad(savegame)  
  if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.drivingLine then
		self.activeModules.drivingLine = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#drivingLineIsActiv"), self.activeModules.drivingLine);
		self.nSMdrives = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#nSMdrives"), self.nSMdrives);
		self.dlMode = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#dlMode"), self.dlMode);
		self.allowPeMarker = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#allowPeMarker"), self.allowPeMarker);
		self.currentLane = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#currentLane"), self.currentLane);
		self.shutoff = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key .. "#shutoff"), self.shutoff);
		if (self.nSMdrives%2 == 0) then -- gerade Zahl
			self.num_DrivingLine = (self.nSMdrives / 2) + 1;
		elseif (self.nSMdrives%2 ~= 0) then -- ungerade Zahl
			self.num_DrivingLine = (self.nSMdrives + 1) / 2;
		end;
		self:updateDriLiGUI();
		-- print("!!!!!!!!!!!!!!DrivingLine:postLoad_drivingLineIsActiv = "..tostring(self.activeModules.drivingLine))
		-- print("!!!!!!!!!!!!!!DrivingLine:postLoad_nSMdrives = "..tostring(self.nSMdrives))
		-- print("!!!!!!!!!!!!!!DrivingLine:postLoad_dlMode = "..tostring(self.dlMode))
		-- print("!!!!!!!!!!!!!!DrivingLine:postLoad_allowPeMarker = "..tostring(self.allowPeMarker))
		-- print("!!!!!!!!!!!!!!DrivingLine:postLoad_currentLane = "..tostring(self.currentLane))
		-- print("!!!!!!!!!!!!!!DrivingLine:postLoad_shutoff = "..tostring(self.shutoff))
  end
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
	local attributes = 'drivingLineIsActiv="'..tostring(self.activeModules.drivingLine)..'" nSMdrives="'..tostring(self.nSMdrives)..'" dlMode="'..tostring(self.dlMode)..'" allowPeMarker="'..tostring(self.allowPeMarker)..'" currentLane="'..tostring(self.currentLane)..'" shutoff="'..tostring(self.shutoff)..'"';
	-- print("!!!!!!!!!!!!!!DrivingLine:getSaveAttributesAndNodes_attributes = "..tostring(attributes))
	return attributes, nil;
end;

function DrivingLine:mouseEvent(posX, posY, isDown, isUp, button)
end;

function DrivingLine:keyEvent(unicode, sym, modifier, isDown)
end;

function DrivingLine:update(dt)
	
	if self:getIsActiveForInput() then
		if self.drivingLinePresent and self.activeModules ~= nil and self.activeModules.drivingLine then
			-- switch driving line / current drive / pause manually
			if InputBinding.hasEvent(InputBinding.DRIVINGLINE) then
				if self.dlMode == 0 then
					if self.drivingLineActiv then
						self:setDrivingLine(false, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
					else
						self:setDrivingLine(true, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
						-- print("InputBinding.hasEvent(InputBinding.DRIVINGLINE) self:setDrivingLine(true);")
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
				elseif self.dlMode == 3 then
					local rootAttacherVehicle = self:getRootAttacherVehicle();
					if rootAttacherVehicle.GPSlaneNo ~= nil and rootAttacherVehicle.GPSlaneNo ~= 0 then
						local lr = rootAttacherVehicle.GPSdirectionPlusMinus--*(-1);
						local lhdX0 = rootAttacherVehicle.lhdX0
						local lhdZ0 = rootAttacherVehicle.lhdZ0
						local diff = math.abs(lhdX0) - math.abs(lhdZ0)
						-- print("lhdX0: "..tostring(lhdX0))
						-- print("lhdZ0: "..tostring(lhdZ0))
						-- print("diff: "..tostring(diff))
						-- print("lr: "..tostring(lr))
						if diff < 0.00001 then
							lr = rootAttacherVehicle.GPSdirectionPlusMinus*(-1);
							if lhdZ0 ~= 0 then
								lhdX0 = 0;
							else
								lhdX0 = 1;
							end;
							if lr > 0 then
								-- local lhX0 = rootAttacherVehicle.lhX0 - lr*rootAttacherVehicle.GPSlaneNo*(rootAttacherVehicle.GPSWidth+math.abs(diff))*lhdZ0;
								-- local lhZ0 = rootAttacherVehicle.lhZ0 - lr*rootAttacherVehicle.GPSlaneNo*(rootAttacherVehicle.GPSWidth+math.abs(diff))*lhdX0;
								local lhX0 = rootAttacherVehicle.lhX0 - lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdZ0;
								local lhZ0 = rootAttacherVehicle.lhZ0 - lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdX0;
								self:setRootVehGPS(lhX0, lhZ0);
							elseif lr < 0 then
								local lhX0 = rootAttacherVehicle.lhX0 + lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdZ0;
								local lhZ0 = rootAttacherVehicle.lhZ0 + lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdX0;
								self:setRootVehGPS(lhX0, lhZ0);
							end;
						else
							if lr < 0 then
								local lhX0 = rootAttacherVehicle.lhX0 - lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdZ0;
								local lhZ0 = rootAttacherVehicle.lhZ0 - lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdX0;
								self:setRootVehGPS(lhX0, lhZ0);
							elseif lr > 0 then
								local lhX0 = rootAttacherVehicle.lhX0 + lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdZ0;
								local lhZ0 = rootAttacherVehicle.lhZ0 + lr*rootAttacherVehicle.GPSlaneNo*rootAttacherVehicle.GPSWidth*lhdX0;
								self:setRootVehGPS(lhX0, lhZ0);
							end;
						end;
						
						-- print("lr: "..tostring(lr))
						-- print("GPSlaneNo: "..tostring(rootAttacherVehicle.GPSlaneNo))
						-- print("-----------------------------------------------")
					end;
				end;
			end;
			local rootAttacherVehicle = self:getRootAttacherVehicle();
			-- renderText(0.1,0.1,0.015,"rootAttacherVehicle.GPSlaneNo = "..tostring(rootAttacherVehicle.GPSlaneNo))
			if InputBinding.hasEvent(InputBinding.DRIVINGLINE_TOGGLESHUTOFF) then
				if not self.drivingLineActiv then
					local shutoff = self.shutoff + 1;
					if shutoff > 2 then
						shutoff = 0;
					end;
					logInfo(1,('shutoff: %s'):format(shutoff));
					self:setShutoff(shutoff);
				end;	
			end;
			
			
			
			--[[ if InputBinding.hasEvent(InputBinding.TOGGLE_WORK_LIGHT_BACK) then
				-- self.dlLaneWidth = self.dlLaneWidth + .001;
				-- self.drivingLines = self:createDrivingLines();
			-- end;
			-- if InputBinding.hasEvent(InputBinding.TOGGLE_WORK_LIGHT_FRONT) then
				-- self.dlLaneWidth = self.dlLaneWidth - .001;
				-- self.drivingLines = self:createDrivingLines();
			-- end;
			
			-- if InputBinding.hasEvent(InputBinding.INCREASE_TIMESCALE) then
				-- self.drivingLineWidth = self.drivingLineWidth + .01;
				-- self.drivingLines = self:createDrivingLines();
			-- end;
			-- if InputBinding.hasEvent(InputBinding.DECREASE_TIMESCALE) then
				-- self.drivingLineWidth = self.drivingLineWidth - .01;
				-- self.drivingLines = self:createDrivingLines();
			-- end;
			
			-- if InputBinding.hasEvent(InputBinding.RADIO_NEXT_CHANNEL) then
				-- self.blocksPerDensity = self.blocksPerDensity + .1;
				-- self.drivingLines = self:createDrivingLines();
			-- end;
			-- if InputBinding.hasEvent(InputBinding.RADIO_PREVIOUS_CHANNEL) then
				-- self.blocksPerDensity = self.blocksPerDensity - .1;
				-- self.drivingLines = self:createDrivingLines();
			-- end;]]
		end;

		
		--[[test
		-- if self.isTurnedOn and self.dlLastTime < g_currentMission.time - 1000 then
			-- self.diff = self.fillLevel - self.dlLastFillLevel;

			-- self.dlLastFillLevel = self.fillLevel;
			-- self.dlLastTime = g_currentMission.time;
		-- end;]]
	end;
end;

function DrivingLine:setRootVehGPS(lhX0, lhZ0, noEventSend)
	-- print("DrivingLine:setRootVehGPS(lhX0="..tostring(lhX0)..", lhZ0="..tostring(lhZ0)..", noEventSend)")
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
				if self.currentLane == self.num_DrivingLine and not self.drivingLineActiv then--and self.dlCultivatorDelay <= g_currentMission.time then
					self:setDrivingLine(true, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
						--print("self.currentLane == self.num_DrivingLine self:setDrivingLine(true); self.num_DrivingLine: "..tostring(self.num_DrivingLine))
					if self.allowPeMarker and not self.peMarkerActiv then
						self:setPeMarker(true);
					end;
				elseif self.currentLane ~= self.num_DrivingLine and self.drivingLineActiv then--and self.dlCultivatorDelay <= g_currentMission.time then
					self:setDrivingLine(false, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
						--print("self.currentLane ~= self.num_DrivingLine self:setDrivingLine(false); self.num_DrivingLine: "..tostring(self.num_DrivingLine))
					if self.peMarkerActiv then
						self:setPeMarker(false);
					end;
				end;
			elseif self.dlMode == 3 then
				local rootAttacherVehicle = self:getRootAttacherVehicle();
				if rootAttacherVehicle.GPSlaneNo == nil then
					-- print("->update(dt) self.dlMode == 3 and rootAttacherVehicle.GPSlaneNo == nil")
					self.dlMode = 0;
				end;
				if rootAttacherVehicle.GPSActive ~= nil and rootAttacherVehicle.GPSlaneNo ~= self.lastGPSlaneNo then
					local x = math.abs(rootAttacherVehicle.GPSlaneNo)%self.nSMdrives;
					-- print("x: "..tostring(x))
					self.currentLane = x+1;
					if self.currentLane == self.num_DrivingLine and not self.drivingLineActiv then--and self.dlCultivatorDelay <= g_currentMission.time then
						self:setDrivingLine(true, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
						--print("self.currentLane == self.num_DrivingLine self:setDrivingLine(true); self.num_DrivingLine: "..tostring(self.num_DrivingLine))
						if self.allowPeMarker and not self.peMarkerActiv then
							self:setPeMarker(true);
						end;
					elseif self.currentLane ~= self.num_DrivingLine and self.drivingLineActiv then--and self.dlCultivatorDelay <= g_currentMission.time then
						self:setDrivingLine(false, self.dlMode, self.currentLane, self.isPaused, self.nSMdrives, self.smWorkwith, self.allowPeMarker);
							--print("self.currentLane ~= self.num_DrivingLine self:setDrivingLine(false); self.num_DrivingLine: "..tostring(self.num_DrivingLine))
						if self.peMarkerActiv then
							self:setPeMarker(false);
						end;
					end;
					self.lastGPSlaneNo = rootAttacherVehicle.GPSlaneNo;
					self:updateDriLiGUI();
					-- print("self.lastGPSlaneNo: "..tostring(self.lastGPSlaneNo))
					-- print("self.currentLane: "..tostring(self.currentLane))
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
				else	
					self.dlCultivatorDelay = g_currentMission.time + 1000;
				end;
				self.IsLoweredBackUp = self.soMaIsLowered;
			end;
		
			if self.isServer then
				--[[if self:getIsTurnedOn() then--and self.seeds[self.currentSeed] ~= self.lastCurrentSeed then
					local selectedSeedFruitType = self.seeds[self.currentSeed];
					if selectedSeedFruitType == FruitUtil.FRUITTYPE_SUGARBEET then
					print("selectedSeedFruitType == FruitUtil.FRUITTYPE_SUGARBEET")
						self.blocksPerDensity = 4
						self.dlLaneWidth = .025;
						self.drivingLineWidth = 1;
						self.drivingLines = self:createDrivingLines();
						self.lastCurrentSeed = self.seeds[self.currentSeed];
					elseif selectedSeedFruitType == FruitUtil.FRUITTYPE_WHEAT then
						print("selectedSeedFruitType == FruitUtil.FRUITTYPE_WHEAT")
						self.blocksPerDensity = 1.5
						self.dlLaneWidth = .066;
						self.drivingLineWidth = 1.32;
						self.drivingLines = self:createDrivingLines();
						self.lastCurrentSeed = self.seeds[self.currentSeed];
					end;
				end;]]
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
									-- x2 = math.floor(x2*10)*.1
									-- z2 = math.floor(z2*10)*.1
									
									--[[ x = math.floor(x)
									-- z = math.floor(z)
									-- x1 = math.floor(x1)
									-- z1 = math.floor(z1)
									-- x2 = math.floor(x2)
									-- z2 = math.floor(z2)
									
									
									-- x = math.floor(x*100)*.01
									-- z = math.floor(z*100)*.01
									-- x1 = math.floor(x1*100)*.01
									-- z1 = math.floor(z1*100)*.01
									-- x2 = math.floor(x2*100)*.01
									-- z2 = math.floor(z2*100)*.01]]
									
									--[[ local xOrg = x;
									-- local zOrg = z;
									-- local x1Org = x1;
									-- local z1Org = z1;
									-- local x2Org = x2;
									-- local z2Org = z2;
									
									-- local xTemp = x*self.blocksPerDensity
									-- local deciX = math.abs(xTemp)- math.abs(math.floor(xTemp))
									-- local deltaX = deciX / self.blocksPerDensity;
									-- x = x - deltaX
									-- local zTemp = z*self.blocksPerDensity
									-- local deciZ = math.abs(zTemp)- math.abs(math.floor(zTemp))
									-- local deltaZ = deciZ / self.blocksPerDensity;
									-- z = z - deltaZ
									
									-- local x1Temp = x1*self.blocksPerDensity
									-- local deciX1 = math.abs(x1Temp)- math.abs(math.floor(x1Temp))
									-- local deltaX1 = deciX1 / self.blocksPerDensity;
									-- x1 = x1 - deltaX1
									-- local z1Temp = z1*self.blocksPerDensity
									-- local deciZ1 = math.abs(z1Temp)- math.abs(math.floor(z1Temp))
									-- local deltaZ1 = deciZ1 / self.blocksPerDensity;
									-- z1 = z1 - deltaZ1
									
									-- local x2Temp = x2*self.blocksPerDensity
									-- local deciX2 = math.abs(x2Temp)- math.abs(math.floor(x2Temp))
									-- local deltaX2 = deciX2 / self.blocksPerDensity;
									-- x2 = x2 - deltaX2
									-- local z2Temp = z2*self.blocksPerDensity
									-- local deciZ2 = math.abs(z2Temp)- math.abs(math.floor(z2Temp))
									-- local deltaZ2 = deciZ2 / self.blocksPerDensity;
									-- z2 = z2 - deltaZ2]]
									
									
									local wx,wz = x1-x, z1-z;
                  local hx,hz = x2-x, z2-z;

                  local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
                  x = math.floor(x*worldToDensity+0.5)/worldToDensity;
                  z = math.floor(z*worldToDensity+0.5)/worldToDensity;

                  x1, z1 = x+wx, z+wz;
                  x2, z2 = x+hx, z+hz;

									--[[local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;

									local lcx,_,lcz = worldToLocal(self.wwCenterPoint,x,y,z);
									local xc,yc,zc = getWorldTranslation(self.wwCenterPoint);
									local diffStartXCenter = lcx--math.abs(xc) - math.abs(x)
									local diffStartZCenter = lcx--math.abs(zc) - math.abs(z)

									local xTemp = math.floor(x*worldToDensity+0.5)/worldToDensity;
									local zTemp = math.floor(z*worldToDensity+0.5)/worldToDensity;
									local diffStartXCenterTemp = math.abs(xc) - math.abs(xTemp)
									local diffStartZCenterTemp = math.abs(zc) - math.abs(zTemp)]]

									--[[local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
									x = math.floor(x*worldToDensity+0.5)/worldToDensity;
									z = math.floor(z*worldToDensity+0.5)/worldToDensity;
									x1, z1 = x+wx, z+wz;
									x2, z2 = x+hx, z+hz;
									local rx,ry,rz = getTranslation(area.start)
									local rx1,ry1,rz1 = getTranslation(area.width);
									local rx2,ry2,rz2 = getTranslation(area.height);
									local rwx,rwz = rx1-rx, rz1-rz;
									local rhx,rhz = rx2-rx, rz2-rz;
									local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)]]

									if i == 1 then
										-- local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
										-- renderText(0.1,0.3,0.015," x = "..tostring(x).. "    (x = "..tostring(xOrg)..")")
										-- renderText(0.1,0.32,0.015," z = "..tostring(z).. "    (z = "..tostring(zOrg)..")")
										-- renderText(0.1,0.34,0.015,"x1 = "..tostring(x1).. "    (x1 = "..tostring(x1Org)..")")
										-- renderText(0.1,0.36,0.015,"z1 = "..tostring(z1).. "    (z1 = "..tostring(z1Org)..")")
										-- renderText(0.1,0.38,0.015,"x2 = "..tostring(x2).. "    (x2 = "..tostring(x2Org)..")")
										-- renderText(0.1,0.42,0.015,"z2 = "..tostring(z2).. "    (z2 = "..tostring(z2Org)..")")
										-- renderText(0.1,0.44,0.015,"terrainHeight = "..tostring(terrainHeight))
									
										-- renderText(0.1,0.3,0.015,"diffStartXCTemp = "..tostring(diffStartXCenterTemp))
										-- renderText(0.1,0.32,0.015,"diffStartXCenter = "..tostring(math.abs(diffStartXCenter)))
										-- renderText(0.1,0.34,0.015,"diffStartZCTemp = "..tostring(math.abs(diffStartZCenterTemp)))
										-- renderText(0.1,0.36,0.015,"diffStartZCenter = "..tostring(math.abs(diffStartZCenter)))
										-- renderText(0.1,0.38,0.015,"x_area.start = "..tostring(x))
										-- renderText(0.1,0.42,0.015,"z_area.start = "..tostring(z))
										-- renderText(0.1,0.46,0.015,"xTemp = "..tostring(xTemp))
										-- renderText(0.1,0.48,0.015,"zTemp = "..tostring(zTemp))
										-- renderText(0.1,0.5,0.015,"hx = "..tostring(hx))
										-- renderText(0.1,0.52,0.015,"hz = "..tostring(hz))
										--[[if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) and math.abs(diffStartXCenter) > 1 then
											-- renderText(0.1,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) and math.abs(diffStartZCenter) > 1 then
											-- renderText(0.1,0.64,0.015,"math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter)")
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;]]
										-- renderText(0.1,0.4,0.015,"x_b = "..tostring(x))
										-- renderText(0.1,0.44,0.015,"z_b = "..tostring(z))
									elseif i == 2 then
										-- local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)
										-- renderText(0.6,0.3,0.015," x = "..tostring(x).. "    (x = "..tostring(xOrg)..")")
										-- renderText(0.6,0.32,0.015," z = "..tostring(z).. "    (z = "..tostring(zOrg)..")")
										-- renderText(0.6,0.34,0.015,"x1 = "..tostring(x1).. "    (x1 = "..tostring(x1Org)..")")
										-- renderText(0.6,0.36,0.015,"z1 = "..tostring(z1).. "    (z1 = "..tostring(z1Org)..")")
										-- renderText(0.6,0.38,0.015,"x2 = "..tostring(x2).. "    (x2 = "..tostring(x2Org)..")")
										-- renderText(0.6,0.42,0.015,"z2 = "..tostring(z2).. "    (z2 = "..tostring(z2Org)..")")
										-- renderText(0.6,0.44,0.015,"terrainHeight = "..tostring(terrainHeight))
										
										
										-- renderText(0.6,0.3,0.015,"x = "..tostring(x))
										-- renderText(0.6,0.32,0.015,"z = "..tostring(math.abs(z)))
										-- renderText(0.6,0.34,0.015,"x1 = "..tostring(math.abs(x1)))
										-- renderText(0.6,0.36,0.015,"z1 = "..tostring(math.abs(z1)))
										-- renderText(0.6,0.38,0.015,"x2 = "..tostring(x2))
										-- renderText(0.6,0.42,0.015,"z2 = "..tostring(z2))
										
										-- renderText(0.6,0.3,0.015,"diffStartXCTemp = "..tostring(diffStartXCenterTemp))
										-- renderText(0.6,0.32,0.015,"diffStartXCenter = "..tostring(math.abs(diffStartXCenter)))
										-- renderText(0.6,0.34,0.015,"diffStartZCTemp = "..tostring(math.abs(diffStartZCenterTemp)))
										-- renderText(0.6,0.36,0.015,"diffStartZCenter = "..tostring(math.abs(diffStartZCenter)))
										-- renderText(0.6,0.38,0.015,"x_area.start = "..tostring(x))
										-- renderText(0.6,0.42,0.015,"z_area.start = "..tostring(z))
										-- renderText(0.6,0.46,0.015,"xTemp = "..tostring(xTemp))
										-- renderText(0.6,0.48,0.015,"zTemp = "..tostring(zTemp))
										-- renderText(0.6,0.5,0.015,"hx = "..tostring(hx))
										-- renderText(0.6,0.52,0.015,"hz = "..tostring(hz))
										--[[if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) and math.abs(diffStartXCenter) > .9 then
											-- renderText(0.6,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) and math.abs(diffStartZCenter) > .9 then
											-- renderText(0.6,0.64,0.015,"math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter)")
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;]]
										-- renderText(0.6,0.4,0.015,"x_b = "..tostring(x))
										-- renderText(0.6,0.44,0.015,"z_b = "..tostring(z))
									end;
									
									-- x1, z1 = x+self.dlLaneWidth, z+self.dlLaneWidth;
									-- x2, z2 = x+self.dlLaneWidth, z+self.dlLaneWidth;
									--[[x1, z1 = x+wx, z+wz;
									x2, z2 = x+hx, z+hz;]]
									table.insert(drivingLinesSend, {x,z,x1,z1,x2,z2});
								end;
						end;
						if table.getn(drivingLinesSend) > 0 then
							DrivingLineAreaEvent.runLocally(drivingLinesSend, true);
							g_server:broadcastEvent(DrivingLineAreaEvent:new(drivingLinesSend, true));
						end;
						
						
						if self.peMarkerActiv then
							local peMarkerLinesSend = {};
							-- renderText(0.1,0.64,0.015,"self.xMin = "..tostring(self.xMin))
							-- renderText(0.1,0.66,0.015,"self.xMax = "..tostring(self.xMax))
							-- renderText(0.1,0.68,0.015,"self.zHeight = "..tostring(self.zHeight))
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
									local diffStartXCenter = lcx--math.abs(xc) - math.abs(x)
									local diffStartZCenter = lcx--math.abs(zc) - math.abs(z)

									local xTemp = math.floor(x*worldToDensity+0.5)/worldToDensity;
									local zTemp = math.floor(z*worldToDensity+0.5)/worldToDensity;
									local diffStartXCenterTemp = math.abs(xc) - math.abs(xTemp)
									local diffStartZCenterTemp = math.abs(zc) - math.abs(zTemp)
									-- local lcxTemp,_,lczTemp = worldToLocal(self.wwCenterPoint,xTemp,y,zTemp);

									if i == 1 then
										-- renderText(0.1,0.3,0.015,"diffStartXCTemp = "..tostring(diffStartXCenterTemp))
										-- renderText(0.1,0.32,0.015,"diffStartXCenter = "..tostring(math.abs(diffStartXCenter)))
										-- renderText(0.1,0.34,0.015,"diffStartZCTemp = "..tostring(math.abs(diffStartZCenterTemp)))
										-- renderText(0.1,0.36,0.015,"diffStartZCenter = "..tostring(math.abs(diffStartZCenter)))
										-- renderText(0.1,0.38,0.015,"x_a = "..tostring(x))
										-- renderText(0.1,0.42,0.015,"z_a = "..tostring(z))
										-- renderText(0.1,0.46,0.015,"wx = "..tostring(wx))
										-- renderText(0.1,0.48,0.015,"wz = "..tostring(wz))
										-- renderText(0.1,0.5,0.015,"hx = "..tostring(hx))
										-- renderText(0.1,0.52,0.015,"hz = "..tostring(hz))
										-- local as,bs,cs = getTranslation(area.start)
										-- local aw,bw,cw = getTranslation(area.width)
										-- local ah,bh,ch = getTranslation(area.height)
										-- renderText(0.1,0.54,0.015,"as = "..tostring(as))
										-- renderText(0.1,0.56,0.015,"aw = "..tostring(aw))
										-- renderText(0.1,0.58,0.015,"ch = "..tostring(ch))
										if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) and math.abs(diffStartXCenter) > 1 then
											-- renderText(0.1,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) and math.abs(diffStartZCenter) > 1 then
											-- renderText(0.1,0.64,0.015,"math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter)")
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;
										--[[ if math.abs(diffStartXCenter) > math.abs(diffStartZCenter) then
											if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) then
												renderText(0.1,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
												x = math.floor(x*worldToDensity)/worldToDensity;
												z = math.floor(z*worldToDensity)/worldToDensity;
											else
												x = xTemp;
												z = zTemp;
											end;
										elseif math.abs(diffStartXCenter) < math.abs(diffStartZCenter) then
											if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) then
												renderText(0.1,0.64,0.015,"math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter)")
												x = math.floor(x*worldToDensity)/worldToDensity;
												z = math.floor(z*worldToDensity)/worldToDensity;
											else
												x = xTemp;
												z = zTemp;
											end;
										end;]]
										--[[ if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) or  math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) then
											renderText(0.1,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											x = xTemp;
											z = zTemp;
										end;]]

										-- renderText(0.1,0.4,0.015,"x_b = "..tostring(x))
										-- renderText(0.1,0.44,0.015,"z_b = "..tostring(z))
									elseif i == 2 then
										-- renderText(0.6,0.3,0.015,"diffStartXCTemp = "..tostring(diffStartXCenterTemp))
										-- renderText(0.6,0.32,0.015,"diffStartXCenter = "..tostring(math.abs(diffStartXCenter)))
										-- renderText(0.6,0.34,0.015,"diffStartZCTemp = "..tostring(math.abs(diffStartZCenterTemp)))
										-- renderText(0.6,0.36,0.015,"diffStartZCenter = "..tostring(math.abs(diffStartZCenter)))
										-- renderText(0.6,0.38,0.015,"x_a = "..tostring(x))
										-- renderText(0.6,0.42,0.015,"z_a = "..tostring(z))
										-- renderText(0.6,0.46,0.015,"wx = "..tostring(wx))
										-- renderText(0.6,0.48,0.015,"wz = "..tostring(wz))
										-- renderText(0.6,0.5,0.015,"hx = "..tostring(hx))
										-- renderText(0.6,0.52,0.015,"hz = "..tostring(hz))
										-- local as,bs,cs = getTranslation(area.start)
										-- local aw,bw,cw = getTranslation(area.width)
										-- local ah,bh,ch = getTranslation(area.height)
										-- renderText(0.6,0.54,0.015,"as = "..tostring(as))
										-- renderText(0.6,0.56,0.015,"aw = "..tostring(aw))
										-- renderText(0.6,0.58,0.015,"ch = "..tostring(ch))
										if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) and math.abs(diffStartXCenter) > .9 then
											-- renderText(0.6,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) and math.abs(diffStartZCenter) > .9 then
											-- renderText(0.6,0.64,0.015,"math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter)")
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;
										--[[
										-- if math.abs(lcxTemp) > math.abs(lcx) then
										if math.abs(lcxTemp) > math.abs(diffStartXCenter) then
											renderText(0.6,0.62,0.015,"math.abs(lcxTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
										else
											x = xTemp;
										end;
										-- if math.abs(lczTemp) > math.abs(lcz) then
										if math.abs(lczTemp) > math.abs(diffStartZCenter) then
											renderText(0.6,0.64,0.015,"math.abs(lczTemp) > math.abs(diffStartZCenter)")
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											z = zTemp;
										end;]]
										--[[ if math.abs(diffStartXCenter) > math.abs(diffStartZCenter) then
											if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) then
												renderText(0.6,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
												x = math.floor(x*worldToDensity)/worldToDensity;
												z = math.floor(z*worldToDensity)/worldToDensity;
											else
												x = xTemp;
												z = zTemp;
											end;
										elseif math.abs(diffStartXCenter) < math.abs(diffStartZCenter) then
											if math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) then
												renderText(0.6,0.64,0.015,"math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter)")
												x = math.floor(x*worldToDensity)/worldToDensity;
												z = math.floor(z*worldToDensity)/worldToDensity;
											else
												x = xTemp;
												z = zTemp;
											end;
										end;]]
										--[[ if math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter) or  math.abs(diffStartZCenterTemp) > math.abs(diffStartZCenter) then
											renderText(0.6,0.62,0.015,"math.abs(diffStartXCenterTemp) > math.abs(diffStartXCenter)")
											x = math.floor(x*worldToDensity)/worldToDensity;
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											x = xTemp;
											z = zTemp;
										end;]]
										-- renderText(0.6,0.4,0.015,"x_b = "..tostring(x))
										-- renderText(0.6,0.44,0.015,"z_b = "..tostring(z))
									end;

									--[[local xc,yc,zc = getWorldTranslation(self.wwCenterPoint);
									local lcx,_,lcz = worldToLocal(self.wwCenterPoint,x,y,z);
									-- local lcx1,_,lcz1 = worldToLocal(self.wwCenterPoint,x1,y1,z1);

									if i == 1 then
										local diffStartXCenter = math.abs(xc) - math.abs(x)
										local diffStartZCenter = math.abs(zc) - math.abs(z)
										renderText(0.1,0.3,0.015,"lcx = "..tostring(lcx))
										renderText(0.1,0.32,0.015,"diffStartXCenter = "..tostring(diffStartXCenter))
										renderText(0.1,0.34,0.015,"lcz = "..tostring(lcz))
										renderText(0.1,0.36,0.015,"diffStartZCenter = "..tostring(diffStartZCenter))
										renderText(0.1,0.38,0.015,"x_a = "..tostring(x))
										renderText(0.1,0.42,0.015,"z_a = "..tostring(z))
										if math.abs(diffStartXCenter) > math.abs(lcx) then--or math.abs(diffStartZCenter) > math.abs(lcz) then
											renderText(0.1,0.62,0.015,"math.abs(diffStartXCenter) > self.drivingLineWidth")
											x = math.floor(x*worldToDensity)/worldToDensity;
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											x = math.floor(x*worldToDensity+0.5)/worldToDensity;
											z = math.floor(z*worldToDensity+0.5)/worldToDensity;
										end;
										renderText(0.1,0.4,0.015,"x_b = "..tostring(x))
										renderText(0.1,0.44,0.015,"z_b = "..tostring(z))
									elseif i == 2 then
										local diffStartXCenter = math.abs(xc) - math.abs(x)
										local diffStartZCenter = math.abs(zc) - math.abs(z)
										renderText(0.6,0.3,0.015,"lcx = "..tostring(lcx))
										renderText(0.6,0.32,0.015,"diffStartXCenter = "..tostring(diffStartXCenter))
										renderText(0.6,0.34,0.015,"lcz = "..tostring(lcz))
										renderText(0.6,0.36,0.015,"diffStartZCenter = "..tostring(diffStartZCenter))
										renderText(0.6,0.38,0.015,"x_a = "..tostring(x))
										renderText(0.6,0.42,0.015,"z_a = "..tostring(z))
										if math.abs(diffStartXCenter) > math.abs(lcx) then--or math.abs(diffStartZCenter) > math.abs(lcz) then
										renderText(0.6,0.62,0.015,"math.abs(diffStartXCenter) > self.drivingLineWidth")
											x = math.floor(x*worldToDensity)/worldToDensity;
											z = math.floor(z*worldToDensity)/worldToDensity;
										else
											x = math.floor(x*worldToDensity+0.5)/worldToDensity;
											z = math.floor(z*worldToDensity+0.5)/worldToDensity;
										end;
										renderText(0.6,0.4,0.015,"x_b = "..tostring(x))
										renderText(0.6,0.44,0.015,"z_b = "..tostring(z))
									end;	]]

									x1, z1 = x+wx, z+wz;
									x2, z2 = x+hx, z+hz;
									table.insert(peMarkerLinesSend, {x,z,x1,z1,x2,z2});
								end;
							end;
							--[[for _,area in pairs(self.peMarkerLines) do
								-- if self:getIsAreaActive(area) then
									local x,y,z = getWorldTranslation(area.start);
									if g_currentMission:getIsFieldOwnedAtWorldPos(x,z) then
										local x1,y1,z1 = getWorldTranslation(area.width);
										local x2,y2,z2 = getWorldTranslation(area.height);


										local wx,wz = x1-x, z1-z;
										local hx,hz = x2-x, z2-z;

										local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
										x = math.floor(x*worldToDensity+0.5)/worldToDensity;
										z = math.floor(z*worldToDensity+0.5)/worldToDensity;

										x1, z1 = x+wx, z+wz;
										x2, z2 = x+hx, z+hz;

										table.insert(peMarkerLinesSend, {x,z,x1,z1,x2,z2});
									end;
								-- end;
							end;]]
							if table.getn(peMarkerLinesSend) > 0 then
								-- CultivatorAreaEvent.runLocally(peMarkerLinesSend, true);
								-- g_server:broadcastEvent(CultivatorAreaEvent:new(peMarkerLinesSend, true));
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
								-- renderText(0.1,0.1,0.02,"self.animations[name].currentTime = "..tostring(self.animations[name].currentTime))
								-- renderText(0.1,0.12,0.02,"self.animations[name].duration = "..tostring(self.animations[name].duration))
								if self.animations[name].currentTime ~= self.animations[name].duration then
									local animTime = self:getAnimationTime(name);
									-- renderText(0.1,0.14,0.02,"animTime"..tostring(animTime))
									self:playAnimation(name, 1, animTime, true);
									-- renderText(0.1,0.08,0.02,"playAnimation")
								end;	
							end;
						else
							-- renderText(0.1,0.1,0.02,"self.animations[name].currentTime = "..tostring(self.animations[name].currentTime))
							-- renderText(0.1,0.12,0.02,"self.animations[name].duration = "..tostring(self.animations[name].duration))
							local startTime = Utils.getNoNil(self.animations[name].startTime,0);
							if self.animations[name].currentTime ~= startTime then 
								local animTime = self:getAnimationTime(name);
								-- renderText(0.1,0.14,0.02,"animTime"..tostring(animTime))
								self:playAnimation(name, -1, animTime, true);
								-- renderText(0.1,0.08,0.02,"playAnimation")
							end;	
						end;
					else
						if name ~= nil then --self.laneMarkers[1].animName ~= nil then
							-- renderText(0.1,0.1,0.02,"self.animations[name].currentTime = "..tostring(self.animations[name].currentTime))
							-- renderText(0.1,0.12,0.02,"self.animations[name].duration = "..tostring(self.animations[name].duration))
							local startTime = Utils.getNoNil(self.animations[name].startTime,0);
							if self.animations[name].currentTime ~= startTime then 
								local animTime = self:getAnimationTime(name);
								-- renderText(0.1,0.14,0.02,"animTime"..tostring(animTime))
								self:playAnimation(name, -1, animTime, true);
								-- renderText(0.1,0.08,0.02,"playAnimation")
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
					--print("not self:getIsActiveForInput(),dlCheckOnLeave, hasChanged self:setDrivingLine(nil, "..tostring(self.dlMode)..", "..tostring(self.currentLane)..", "..tostring(self.isPaused)..", "..tostring(self.nSMdrives)..", "..tostring(self.smWorkwith))
					self.hasChanged = false;
				end;
				self.dlCheckOnLeave = false;
			end;
		end;
	end;
end;

function DrivingLine:draw()

	if self.drivingLinePresent and self.activeModules ~= nil and self.activeModules.drivingLine then
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
		-- setTextColor(1,1,1,1);
		-- if self.dlCultivatorDelay > g_currentMission.time then
			-- renderText(0.1,0.16,0.015,"self.dlCultivatorDelay > g_currentMission.time")
		-- end;
		-- local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
		-- renderText(0.1,0.1,0.015,"g_currentMission.terrainDetailMapSize = "..tostring(g_currentMission.terrainDetailMapSize))
		-- renderText(0.1,0.12,0.015,"g_currentMission.terrainSize = "..tostring(g_currentMission.terrainSize))
		-- renderText(0.1,0.14,0.015,"self.drivingLineWidth = "..tostring(self.drivingLineWidth))
		-- renderText(0.1,0.16,0.015,"self.dlLaneWidth = "..tostring(self.dlLaneWidth))
		-- renderText(0.1,0.18,0.015,"self.blocksPerDensity = "..tostring(self.blocksPerDensity))
		-- renderText(0.1,0.20,0.015,"self.blocksPerDensity = "..tostring(self.blocksPerDensity))
		-- renderText(0.1,0.22,0.015,"self.testFaktordrivingLineWidth = "..tostring(self.testFaktordrivingLineWidth))
	end;
end;

--[[function DrivingLine:setIsTurnedOn()
  if self.drivingLinePresent then
		local rootAttacherVehicle = self:getRootAttacherVehicle();
		if rootAttacherVehicle ~= nil then
			if not self.allowsLowering	and self.dlMode == 2 and not self.isPaused and not self.isTurnedOn
			and (rootAttacherVehicle.isControlled or rootAttacherVehicle.isHired) then
				if self.currentLane < self.nSMdrives then
					self.currentLane = self.currentLane + 1;
				else
					self.currentLane = 1;
				end;
				-- self.hasChanged = true;
				self:updateDriLiGUI();
			end;
		end;
	end;
end;]]

function DrivingLine:setDrivingLine(drivingLineActiv, dlMode, currentLane, isPaused, nSMdrives, smWorkwith, allowPeMarker, noEventSend)
--print("DrivingLine:setDrivingLine(drivingLineActiv: "..tostring(drivingLineActiv)..", dlMode: "..tostring(dlMode)..", currentLane: "..tostring(currentLane)..", isPaused: "..tostring(isPaused)..", nSMdrives: "..tostring(nSMdrives)..", smWorkwith: "..tostring(smWorkwith)..", noEventSend: "..tostring(noEventSend)..")")
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

	-- Kuhn Moduliner
	if self.drivemark ~= nil then
		self.drivemark = self.drivingLineActiv;
	end;
end;

function DrivingLine:setSPworkwidth(raise, noEventSend)
-- print("DrivingLine:setSPworkwidth(raise, noEventSend)")
	if not raise then
		if self.nSMdrives > 3 and self.spWorkwith < 67 then
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

	-- if noEventSend == nil or noEventSend == false then
		-- SetSPworkwidthEvent.sendEvent(self, raise, noEventSend);
	-- end;
end;

function DrivingLine:setPeMarker(peMarkerActiv, noEventSend)
-- print("DrivingLine:setPeMarker(peMarkerActiv, noEventSend)")
	if noEventSend == nil or noEventSend == false then
		SetPeMarkerEvent.sendEvent(self, peMarkerActiv, noEventSend);
		-- print("DrivingLine:setPeMarker->SetPeMarkerEvent.sendEvent(self, peMarkerActiv, noEventSend);")
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
			self.zHeight = math.min(self.zHeight, lz1, lz2, lz3);
		end;
	end;
end;

function DrivingLine:createDrivingLines()
	local drivingLines = {};
	
	local x = self.wwCenter + self.drivingLineWidth;
	local y = self.yStart;
	local z = self.zHeight - .2;
	local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
	local hz = z - self.dlLaneWidth;
	for i=1, 2 do
		local startId = createTransformGroup("start"..i);
		link(self.dlRootNode, startId);
		setTranslation(startId,x,y,z);
		-- print("DrivingLine"..tostring(i).." start x: "..tostring(x).." y: "..tostring(y).." z: "..tostring(z));
		local heightId = createTransformGroup("height"..i);
		link(self.dlRootNode, heightId);
		setTranslation(heightId,x,y,hz);
		-- print("DrivingLine"..tostring(i).." height x: "..tostring(x).." y: "..tostring(y).." hz: "..tostring(hz));
		x = x - self.dlLaneWidth;
		local widthId = createTransformGroup("width"..i);
		link(self.dlRootNode, widthId);
		setTranslation(widthId,x,y,z);
		-- print("DrivingLine"..tostring(i).." width x: "..tostring(x).." y: "..tostring(y).." z: "..tostring(z));
		x = self.wwCenter - (self.drivingLineWidth-self.dlLaneWidth);--0.65;

		table.insert(drivingLines, {foldMinLimit=0,start=startId,height=heightId,foldMaxLimit=0.2,width=widthId});
	end;
	self.drivingLinePresent = true;
	--print("Created driving lines!");
	-- print("DrivingLine:createDrivingLines -> self.dlLaneWidth: "..tostring(self.dlLaneWidth))
	-- print("DrivingLine:createDrivingLines -> self.drivingLineWidth: "..tostring(self.drivingLineWidth))
	return drivingLines;
end;

function DrivingLine:createPeMarkerLines()
	local peMarkerLines = {};
	local worldToDensity = g_currentMission.terrainDetailMapSize / g_currentMission.terrainSize;
	local x = self.wwCenter + .6*worldToDensity--1.1;--self.drivingLineWidth;--1.225;
	local y = self.yStart;
	local z = self.zHeight - .2;
	local hz = z-- - .05*worldToDensity
	for i=1, 2 do
		local startId = createTransformGroup("start"..i);
		link(self.dlRootNode, startId);
		setTranslation(startId,x,y,z);
		-- print("peMarkerLine"..tostring(i).." start x: "..tostring(x).." y: "..tostring(y).." z: "..tostring(z));
		local heightId = createTransformGroup("height"..i);
		link(self.dlRootNode, heightId);
		setTranslation(heightId,x,y,hz);
		-- print("peMarkerLine"..tostring(i).." height x: "..tostring(x).." y: "..tostring(y).." hz: "..tostring(hz));
		-- x = x - .05*worldToDensity;
		local widthId = createTransformGroup("width"..i);
		link(self.dlRootNode, widthId);
		setTranslation(widthId,x,y,z);
		-- print("peMarkerLine"..tostring(i).." width x: "..tostring(x).." y: "..tostring(y).." z: "..tostring(z));
		x = self.wwCenter - .5*worldToDensity --+.025*worldToDensity;--self.drivingLineWidth-0.1--1.125;

		table.insert(peMarkerLines, {foldMinLimit=0,start=startId,height=heightId,foldMaxLimit=0.2,width=widthId});
	end;
	self.peMarkerPresent = true;
	--print("Created peMarker Lines!");
	return peMarkerLines;
end;

function DrivingLine:updateDriLiGUI()
	if self.activeModules ~= nil then
		if self.activeModules.drivingLine then
			-- print("DrivingLine:updateDriLiGUI()")
			self.hud1.grids.main.elements.driLiMode.isVisible = true;
			if self.dlMode == 0 then
				self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_MANUAL;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = false;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = true;
				self.hud1.grids.main.elements.gpsWidth.isVisible = false;
			elseif self.dlMode == 1 then
				self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_SEMIAUTO;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = true;
				self.hud1.grids.main.elements.gpsWidth.isVisible = false;
			elseif self.dlMode == 2 then
				local rootAttacherVehicle = self:getRootAttacherVehicle();
				if rootAttacherVehicle.GPSlaneNo ~= nil then
					-- print("-> updateDriLiGUI()  rootAttacherVehicle.GPSlaneNo: "..tostring(rootAttacherVehicle.GPSlaneNo))
					self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_AUTO;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = true;
				else
					self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_AUTO;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = false;
				end;
				self.hud1.grids.main.elements.gpsWidth.isVisible = false;
			elseif self.dlMode == 3 then
				self.hud1.grids.main.elements.driLiMode.value = SowingMachine.DRIVINGLINE_GPS;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button1IsActive = true;
				self.hud1.grids.main.elements.driLiMode.buttonSet.button2IsActive = false;
				self.hud1.grids.main.elements.gpsWidth.isVisible = true;
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
			
			if self.dlMode > 0 then--and self.dlMode < 3 then
				self.hud1.grids.main.elements.driLiSpWorkWidth.isVisible = true;
				self.spWorkwith = self.smWorkwith * self.nSMdrives;
				-- print("DrivingLine:updateDriLiGUI() "..tostring(self.spWorkwith).."="..tostring(self.smWorkwith).."*"..tostring(self.nSMdrives))
				if (self.nSMdrives%2 == 0) then -- gerade Zahl
					self.num_DrivingLine = (self.nSMdrives / 2) + 1;
				elseif (self.nSMdrives%2 ~= 0) then -- ungerade Zahl
					self.num_DrivingLine = (self.nSMdrives + 1) / 2;
				end;
				self.hud1.grids.main.elements.driLiSpWorkWidth.value = self.spWorkwith.."m";
				
				if self.nSMdrives == 3 then
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
				else	
					self.hud1.grids.main.elements.driLiCurDrive.buttonSet.button1IsActive = true;
					self.hud1.grids.main.elements.driLiCurDrive.buttonSet.button2IsActive = true;
				end;
				
				
				self.hud1.grids.main.elements.info_numDrivingLine.isVisible = true;
				self.hud1.grids.main.elements.info_numDrivingLine.value = self.num_DrivingLine;
			-- elseif self.dlMode == 3 then
			
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

			self.hud1.grids.config.elements.driLiModul.value = false;
		end;
	end;
end;

function DrivingLine:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)--(speedRotatingPart, xmlFile, key)
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

-- function DrivingLine:setSeedIndex(seedIndex, noEventSend)
	-- print("self.currentSeed = "..tostring(self.currentSeed))
	
-- end;