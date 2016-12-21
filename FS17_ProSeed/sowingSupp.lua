-- ProSeed
--
-- a collection of several seeder modifications
--
--	@author:		gotchTOM & webalizer
--	@date: 			15-Dec-2016
--	@version: 	v0.01.09
--
-- included modules: sowingCounter, sowingSounds, drivingLine, fertilization
--
-- added modules:
-- 		sowingCounter:				hectar counter for seeders
-- 		sowingSounds:					acoustic signals for seeders
--		drivingLine:					"tramlines" for seeders + halfside shutoff
--		fertilization:				switch fertilizer
--		RidgeMarkerUpgrade:		switch ridgemarker
--


SowingSupp = {}
SowingSupp.path = g_currentModDirectory;
source(SowingSupp.path.."gui.lua");
source(SowingSupp.path.."draw.lua");

function SowingSupp.prerequisitesPresent(specializations)
		return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

local debugmode = 10;
local modItem = ModsUtil.findModItemByModName(g_currentModName);
local version = (modItem and modItem.version) and modItem.version or "?.?.?";
local versionText = '*** ProSeed v'..version;

function logInfo(mode,message)
	if (mode >= debugmode and mode < 5) then
		print(('%s DEBUG | %s'):format(versionText, message));
	elseif mode == 5 then
		print(('%s | %s'):format(versionText, message));
	end;
end;

function SowingSupp:load(xmlFile)

	if self.activeModules == nil then
		self.activeModules = {};
		self.activeModules.sowingCounter = true;
		self.activeModules.sowingSounds = true;
		self.activeModules.drivingLine = true;
		self.activeModules.fertilization = self.allowsSpraying;
		if SowingSupp.isDedi == nil then
			SowingSupp.isDedi = SowingSupp:checkIsDedi();
		end;
		if not SowingSupp.isDedi then
			SowingSupp:loadConfigFile(self);
		end;

		--print("SowingSupp: load - check:")
		-- for name,value in pairs(self.activeModules) do
			--print(name," ",tostring(value))
		-- end;
	end;
	self.sosuHUDisActive = false;
	self.lastNumActiveHUDs = -1;
	SowingSupp.stopMouse = false;
	self.soMaIsLowered = false;-- is required by sowingSounds and drivingLine, because self.sowingMachineHasGroundContact doesn´t work like it should :(

	SowingSupp.snd_click = createSample("snd_click");
	loadSample(SowingSupp.snd_click, Utils.getFilename("snd/snd_click.wav", SowingSupp.path), false);

	local xPos, yPos = g_currentMission.vehicleHudBg.x, g_currentMission.vehicleHudBg.y + g_currentMission.fuelLevelIconOverlay.height;

	self.hud1 = {};
	self.hud1 = SowingSupp.container:New(xPos, yPos, true);

	local gridWidth = g_currentMission.vehicleHudBg.width/3;
	local gridHeight = g_currentMission.vehicleHudBg.height/6;

	-- create grid (container [table], offset x [int], offset y [int], rows [int], columns [int], width [int], height [int] is visible [bool], is master [bool], showGrid [bool])
	self.hud1.grids.main = {};
	self.hud1.grids.main = SowingSupp.hudGrid:New(self.hud1, 0, 0, 9, 3, gridWidth, gridHeight, true, true, false);

	self.hud1.grids.config = {};
	self.hud1.grids.config = SowingSupp.hudGrid:New(self.hud1, -(gridWidth*2) - (gridWidth*.038), 0, 5, 2, gridWidth, gridHeight, false, false, false);

	-- create gui elements ( grid position [int], function to call [string], parameter1, parameter2, style [string], label [string], value [], is visible [bool], [Grafik], textSize [int], textAlignment []) ]
	-- main elements
	--NewTitlebar ( gridPos [int], functionToCall [string], parameter1 [], parameter2 [], label [string], isVisible [bool], textSize [int]]
	self.hud1.grids.main.elements.titleBar = SowingSupp.guiElement:NewTitlebar( 25, "titleBar", "configHud", "close", "ProSeed", true, 5);

	--NewImage ( gridPos [int], offsetX [number], offsetY [number], width [number], height [number], color [{r,g,b,a}], isVisible [bool], graphic, uvs  [{u0,v0,u1,v1,u2,v2,u3,v3})
	self.hud1.grids.main.elements.ridgeMarkerLeft = SowingSupp.guiElement:NewImage( 4, -.017,.0165, .066, .0915, {.35,.35,.35,1}, false, "sowing_machine", {0,0.332, 0,0.4, 0.051,0.332, 0.051,0.4});
	self.hud1.grids.main.elements.ridgeMarkerLeftActive = SowingSupp.guiElement:NewImage( 4, -.017,.0005, .066, .0915, {0,.4,0,1}, false, "sowing_machine", {0,0.4, 0,0.332, 0.051,0.4, 0.051,0.332});
	self.hud1.grids.main.elements.ridgeMarkerRight = SowingSupp.guiElement:NewImage( 6, .017,.0165, .066, .0915, {.35,.35,.35,1}, false, "sowing_machine", {0.051,0.332, 0.051,0.4, 0,0.332, 0,0.4});
	self.hud1.grids.main.elements.ridgeMarkerRightActive = SowingSupp.guiElement:NewImage( 6, .017,.0005, .066, .0915, {0,.4,0,1}, false, "sowing_machine", {0.051,0.4, 0.051,0.332, 0,0.4, 0,0.332});

	self.hud1.grids.main.elements.sowImage = SowingSupp.guiElement:NewImage( 5, 0,.0085, .8, .47, {1,1,1,1}, true, "sowing_machine", {0,0, 0,0.3, 1,0, 1,0.3});
	self.hud1.grids.main.elements.barImage = SowingSupp.guiElement:NewImage( 5, 0,.0085, .8, .021, {1,1,1,1}, true, "sowing_machine", {0,0.521, 0,0.54, 1,0.521, 1,0.54});
	self.hud1.grids.main.elements.proSeedImage = SowingSupp.guiElement:NewImage( 5, 0,0.0285, .2, .31, {.1,.1,.1,.5}, true, "sowing_machine", {0,0.586, 0,0.828, 0.168,0.586, 0.168,0.828});

	--NewSeparator ( gridPos [int], offsetX [number], offsetY [number], color [{r,g,b,a}], style ["h" or "v"], isVisible [bool])
	self.hud1.grids.main.elements.separator1 = SowingSupp.guiElement:NewSeparator( 19, 0,0, {1,1,1,1}, "h", true);

	--NewInteraction ( gridPos [int], offsetX [number], offsetY [number], textColor [{r,g,b,a}], functionToCall [string], parameter1, parameter2, style [string], label [string], value [], isvisible [bool], [graphics], labelTextSize [int], valueTextSize [int], textBold [bool])
	self.hud1.grids.main.elements.driLiMode = SowingSupp.guiElement:NewInteraction( 19, 0,0, {1,1,1,1}, "changeDriLiMode", -1, 1, "arrow", SowingMachine.DRIVINGLINE_MODE, SowingMachine.DRIVINGLINE_MANUAL, true, nil, 1, 4, false );
	self.hud1.grids.main.elements.driLiSpWorkWidth = SowingSupp.guiElement:NewInteraction( 20, 0,0, {1,1,1,1}, "changeSpWorkWidth", -1, 1, "plusminus", SowingMachine.DRIVINGLINE_SPWORKWIDTH, 0, true, nil, 1, 4, false );
	self.hud1.grids.main.elements.driLiCurDrive = SowingSupp.guiElement:NewInteraction( 21, 0,0, {1,1,1,1}, "changeCurDrive", -1, 1, "plusminus", SowingMachine.DRIVINGLINE_CURRENTLANE, 1, true, nil, 1, 4, false );

	--NewText ( gridPos [int], offsetX [number], offsetY [number], color [{r,g,b,a}], label [string], value [string], isVisible [bool] , labelTextSize [int], valueTextSize [int], textBold [bool], textAlignment [])
	self.hud1.grids.main.elements.info_workWidth = SowingSupp.guiElement:NewText( 14, 0,0, {0,0,0,1}, SowingMachine.DRIVINGLINE_WORKWIDTH, 0, true, 2, 4, true, RenderText.ALIGN_CENTER);
	self.hud1.grids.main.elements.info_numDrivingLine = SowingSupp.guiElement:NewText( 11, 0,-0.01, {0,0,0,1}, SowingMachine.DRIVINGLINE_NUMDRILINE, 0, true, 2, 4, true, RenderText.ALIGN_CENTER);

	self.hud1.grids.main.elements.sowingSound = SowingSupp.guiElement:NewInteraction( 9, 0,0, {1,1,1,1}, "toggleSound", nil, nil, "toggle", nil, true, self.activeModules.sowingSounds, "button_Sound", 1, _, false );

	self.hud1.grids.main.elements.gpsWidth = SowingSupp.guiElement:NewInteraction( 15, 0,0, {1,1,1,1}, "setGPSWidth", nil, nil, "push", nil, true, false, "button_GPS", 1, _, false );
	-- if self.activeModules.fertilization ~= nil then
		self.hud1.grids.main.elements.fertilizer = SowingSupp.guiElement:NewInteraction( 13, 0,0, {1,1,1,1}, "setFertilization", nil, nil, "toggle", nil, self.allowsSpraying, true, "button_Fertilizer", 1, _, false);
	-- end;

	--NewIconText ( gridPos [int], offsetX [number], offsetY [number], color [{r,g,b,a}], value [string], valueTextSize [int], textBold [bool], isVisible [bool], graphic, uvs [{u0,v0,u1,v1,u2,v2,u3,v3}]
	self.hud1.grids.main.elements.scSession = SowingSupp.guiElement:NewIconText( 2, 0,0, {1,1,1,1}, "0.00ha   (0.0ha/h)", 4, false, self.activeModules.sowingCounter, "SowingCounter_sessionHUD", nil);

	self.hud1.grids.main.elements.scTotal = SowingSupp.guiElement:NewIconText( 1, 0,0, {1,1,1,1}, "0.0ha", 4, false, self.activeModules.sowingCounter, "SowingCounter_totalHUD", nil);


	self.hud1.grids.main.elements.driLiPeMarker = SowingSupp.guiElement:NewInteraction( 7, 0,0, {1,1,1,1}, "togglePeMarker", nil, nil, "toggle", nil, true, true, "button_peMarker",1, _, false);

	-- self.hud1.grids.main.elements.separator1 = SowingSupp.guiElement:New( 19, nil, nil, nil, "separator", nil, nil, true, "row_bg", nil);

	-- self.hud1.grids.main.elements.changeSomething = SowingSupp.guiElement:New( 20, "changeSomething", -3, 1, "plusminus", "Verschieben", 21, true, nil);

	-- config
	self.hud1.grids.config.elements.soCoModul = SowingSupp.guiElement:NewInteraction( 1, 0,0, {1,1,1,1}, "toggleSoCoModul", nil, nil, "option", SowingMachine.SOWINGCOUNTER, self.activeModules.sowingCounter, true, "button_Option", 2, _, false);
	self.hud1.grids.config.elements.separator1 = SowingSupp.guiElement:NewSeparator( 3, 0,0, {1,1,1,1}, "h", true);
	self.hud1.grids.config.elements.soSoModul = SowingSupp.guiElement:NewInteraction( 3, 0,0, {1,1,1,1}, "toggleSoSoModul", nil, nil, "option", SowingMachine.SOWINGSOUNDS, self.activeModules.sowingSounds, true, "button_Option", 2, _, false);
	self.hud1.grids.config.elements.separator2 = SowingSupp.guiElement:NewSeparator( 5, 0,0, {1,1,1,1}, "h", true);
	self.hud1.grids.config.elements.driLiModul = SowingSupp.guiElement:NewInteraction( 5, 0,0, {1,1,1,1}, "toggleDriLiModul", nil, nil, "option", SowingMachine.DRIVINGLINE, self.activeModules.drivingLine, true, "button_Option", 2, _, false);
	self.hud1.grids.config.elements.separator3 = SowingSupp.guiElement:NewSeparator( 7, 0,0, {1,1,1,1}, "h", true);
	self.hud1.grids.config.elements.fertiModul = SowingSupp.guiElement:NewInteraction( 7, 0,0, {1,1,1,1},"toggleFertiModul", nil, nil, "option", SowingMachine.FERTILIZATION, self.activeModules.fertilization, true, "button_Option", 2, _, false);

	self.hud1.grids.config.elements.separator4 = SowingSupp.guiElement:NewSeparator( 9, 0,0, {1,1,1,1}, "h", true);
	self.hud1.grids.config.elements.configLabel = SowingSupp.guiElement:NewIconText( 9, 0,0, {1,1,1,1}, SowingMachine.SOWINGSUPP_CONFIGLABEL, 3, true, true, nil, nil );

end;

function SowingSupp:checkIsDedi()
	return g_dedicatedServerInfo ~= nil;
	-- local pixelX, pixelY = getScreenModeInfo(getScreenMode());
	-- return pixelX*pixelY < 1;
end;

function SowingSupp:delete()
end;

function SowingSupp:mouseEvent(posX, posY, isDown, isUp, button)
	self.hud1.mouseEvent(self, posX, posY, isDown, isUp, button);
	--self.hud1.grids.config:mouseEvent(self, posX, posY, isDown, isUp, button);
end;

function SowingSupp:keyEvent(unicode, sym, modifier, isDown)

end;

function SowingSupp:modules(grid, container, vehicle, guiElement, parameter)
	playSample(SowingSupp.snd_click, 1, 1, 0);
	-- Call other functions instead of doing it directly
	-- if guiElement.functionToCall == "changeMode" then
		-- if parameter == 1 then
			-- guiElement.value = "erhöht";

		-- elseif parameter == -1 then
			-- guiElement.value = "vermindert";
		-- end;
	-- end;
	if guiElement.functionToCall == "changeDriLiMode" then
		if parameter == 1 then
			if vehicle.dlMode == 0 then
				vehicle.dlMode = 1;
				guiElement.value = SowingMachine.DRIVINGLINE_SEMIAUTO;
			elseif vehicle.dlMode == 1 then
				vehicle.dlMode = 2;
				guiElement.value = SowingMachine.DRIVINGLINE_AUTO;
			elseif vehicle.dlMode == 2 then
				if vehicle.AttacherVehicleBackup ~= nil and vehicle.AttacherVehicleBackup.GPSlaneNo ~= nil then
					vehicle.dlMode = 3;
					guiElement.value = SowingMachine.DRIVINGLINE_GPS;
				else
					vehicle.dlMode = 0;
					guiElement.value = SowingMachine.DRIVINGLINE_MANUAL;
					if vehicle.isPaused then
						vehicle.isPaused = false;
					end;
				end;
			elseif vehicle.dlMode == 3 then
				vehicle.dlMode = 0;
				guiElement.value = SowingMachine.DRIVINGLINE_MANUAL;
				if vehicle.isPaused then
					vehicle.isPaused = false;
				end;
			end;
		elseif parameter == -1 then
			-- if vehicle.dlMode == 0 then
				-- vehicle.dlMode = 2;
				-- guiElement.value = SowingMachine.DRIVINGLINE_AUTO;
			if vehicle.dlMode == 1 then
				vehicle.dlMode = 0;
				guiElement.value = SowingMachine.DRIVINGLINE_MANUAL;
			elseif vehicle.dlMode == 2 then
				vehicle.dlMode = 1;
				guiElement.value = SowingMachine.DRIVINGLINE_SEMIAUTO;
				if vehicle.isPaused then
					vehicle.isPaused = false;
				end;
			elseif vehicle.dlMode == 3 then
				vehicle.dlMode = 2;
				guiElement.value = SowingMachine.DRIVINGLINE_AUTO;
			end;
		end;
		vehicle.lastGPSlaneNo = -1;
		vehicle:updateDriLiGUI();
		-- vehicle.hasChanged = true;
	end;
	if guiElement.functionToCall == "changeSpWorkWidth" then
		if parameter == 1 then
			vehicle:setSPworkwidth(true);
		elseif parameter == -1 then
			vehicle:setSPworkwidth(false);
		end;
	end;
	if guiElement.functionToCall == "changeCurDrive" then
		if parameter == 1 then
			if vehicle.currentLane < vehicle.nSMdrives then
				vehicle.currentLane = vehicle.currentLane + 1;
			else
				vehicle.currentLane = 1;
			end;
		elseif parameter == -1 then
			if vehicle.currentLane > 1 then
				vehicle.currentLane = vehicle.currentLane - 1;
			else
				vehicle.currentLane = vehicle.nSMdrives;
			end;
		end;
		vehicle:updateDriLiGUI();
	end;

	-- if guiElement.functionToCall == "changeSomething" then
		-- guiElement.value = guiElement.value + parameter;
		-- if guiElement.value <= 1 then
			-- guiElement.value = 1;
			-- guiElement.buttonSet.button1IsActive = false;
		-- else
			-- guiElement.buttonSet.button1IsActive = true;
		-- end;
		-- if guiElement.value >= 21 then
			-- guiElement.value = 21;
			-- guiElement.buttonSet.button2IsActive = false;
		-- else
			-- guiElement.buttonSet.button2IsActive = true;
		-- end;
		-- grid.elements.toggleFunction.gridPos = guiElement.value;
	-- end;
	-- if guiElement.functionToCall == "toggleOnOff" then
		-- guiElement.value = not guiElement.value;
	-- end;

	if guiElement.functionToCall == "titleBar" then
		if parameter == "configHud" then
			vehicle.hud1.grids.config.isVisible = not vehicle.hud1.grids.config.isVisible;
		end;
		if parameter == "close" then
			vehicle.sosuHUDisActive = false;
			InputBinding.setShowMouseCursor(false);
		end;
	end;
	if guiElement.functionToCall == "toggleSound" then
		guiElement.value = not guiElement.value;
		vehicle.sowingSounds.isAllowed = guiElement.value;
	end;
	if guiElement.functionToCall == "setFertilization" then
		guiElement.value = not guiElement.value;
		vehicle.allowsSpraying = guiElement.value;
	end;
	if guiElement.functionToCall == "toggleSoCoModul" then
		guiElement.value = not guiElement.value;
		vehicle.activeModules.sowingCounter = guiElement.value;
		vehicle:updateSoCoGUI();
	end;
	if guiElement.functionToCall == "toggleSoSoModul" then
		guiElement.value = not guiElement.value;
		vehicle.activeModules.sowingSounds = guiElement.value;
		vehicle:updateSoSoGUI();
	end;
	if guiElement.functionToCall == "toggleDriLiModul" and vehicle.drivingLinePresent then
		guiElement.value = not guiElement.value;
		vehicle.activeModules.drivingLine = guiElement.value;
		vehicle:updateDriLiGUI();
	end;
	if guiElement.functionToCall == "togglePeMarker" then
		guiElement.value = not guiElement.value;
		vehicle.allowPeMarker = guiElement.value;
		if not vehicle.allowPeMarker and vehicle.peMarkerActiv then
			vehicle.peMarkerActiv = vehicle.allowPeMarker;
		end;
		-- vehicle:setDrivingLine(vehicle.drivingLineActiv, vehicle.dlMode, vehicle.currentLane, vehicle.isPaused, vehicle.nSMdrives, vehicle.smWorkwith, vehicle.allowPeMarker);
		-- if vehicle.allowPeMarker then
			-- if vehicle.drivingLineActiv then
				-- vehicle:setPeMarker(true);
			-- end;
		-- else
			-- if vehicle.drivingLineActiv then
				-- vehicle:setPeMarker(false);
			-- end;
		-- end;
		vehicle:updateDriLiGUI();
	end;
	if guiElement.functionToCall == "toggleFertiModul" then
		guiElement.value = not guiElement.value;
		vehicle.activeModules.fertilization = guiElement.value;
		vehicle:updateFertiGUI();
	end;
	 if guiElement.functionToCall == "setGPSWidth" then
		local rootAttacherVehicle = vehicle:getRootAttacherVehicle();
		if rootAttacherVehicle.GPSWidth ~= nil then
			rootAttacherVehicle.GPSWidth = vehicle.smWorkwith;
		end;	
	 end;
end;

function SowingSupp:update(dt)

	if self:getIsActiveForInput() then
		-- switch HUD
		if InputBinding.hasEvent(InputBinding.SOWINGSUPP_HUD) then
			self.sosuHUDisActive = not self.sosuHUDisActive;
			if self.sosuHUDisActive then
				self.hud1.isVisible = true;
				if self.activeModules.drivingLine then
					self:updateDriLiGUI();
				end;
			end;
		end;
		if InputBinding.isPressed(InputBinding.SOWINGSUPP_MOUSE) and self.sosuHUDisActive then
			if not SowingSupp.stopMouse then
				SowingSupp.stopMouse = true;
				InputBinding.setShowMouseCursor(true);
			end;
		else
			if SowingSupp.stopMouse then
				SowingSupp.stopMouse = false;
				InputBinding.setShowMouseCursor(false);
			end;
		end;
	end;
end;

-- function SowingSupp:onAttach(attacherVehicle)
	-- self.AttacherVehicleBackup = attacherVehicle;
-- end;

function SowingSupp:updateTick(dt)
	-- update y-position if HUD is on initial position (exact x-position) and there are other HUDs (like OperatingHours of AGes Sonnenschein)
	if self:getIsActive() then
		if self.sosuHUDisActive then
			if self.AttacherVehicleBackup == nil then
				local attacherVehicle = self:getRootAttacherVehicle();
				self.AttacherVehicleBackup = attacherVehicle;
			end;
			-- renderText(0.1,0.1,0.02,"self.AttacherVehicleBackup.GPSlaneNo: "..tostring(self.AttacherVehicleBackup.GPSlaneNo))
			-- renderText(0.1,0.12,0.02,"self.AttacherVehicleBackup.GPSlaneNoOffset: "..tostring(self.AttacherVehicleBackup.GPSlaneNoOffset))
			if self.AttacherVehicleBackup.ActiveHUDs == nil then
				self.AttacherVehicleBackup.ActiveHUDs = {};
				self.AttacherVehicleBackup.ActiveHUDs.numActiveHUDs = 0;
			end;
			if self.AttacherVehicleBackup.ActiveHUDs.numActiveHUDs ~= self.lastNumActiveHUDs and self.hud1.baseX == g_currentMission.vehicleHudBg.x then
				local yPos = g_currentMission.vehicleHudBg.y + g_currentMission.fuelLevelIconOverlay.height * (self.AttacherVehicleBackup.ActiveHUDs.numActiveHUDs) + g_currentMission.vehicleHudBg.height * .038 + g_currentMission.vehicleHudBg.height;
				self.hud1.moveMe(self.hud1.baseX, yPos);
				self.lastNumActiveHUDs = self.AttacherVehicleBackup.ActiveHUDs.numActiveHUDs;
			end;
		end;
		if self.activeModules.sowingSounds or self.activeModules.drivingLine then
			self.soMaIsLowered = self:isLowered();
		end;
	end;
end;

function SowingSupp:loadConfigFile(self)
	-- local path = getUserProfileAppPath();
	local Xml;
	local file = g_modsDirectory.."/sowingSupplement_config.xml";

	if fileExists(file) then
		--print("loading "..file.." for sowingSupplement-Mod configuration");
		Xml = loadXMLFile("sowingSupplement_XML", file, "sowingSupplement");
	else
		--print("creating "..file.." for sowingSupplement-Mod configuration");
		Xml = createXMLFile("sowingSupplement_XML", file, "sowingSupplement");
	end;

	local moduleList = {"sowingCounter","sowingSounds","drivingLine","fertilization"};

	for _,field in pairs(moduleList) do
		local XmlField = string.upper(string.sub(field,1,1))..string.sub(field,2);

		local res = getXMLBool(Xml, "sowingSupplement.Modules."..XmlField);

		if res ~= nil then
			self.activeModules[field] = res;
			if res then
				--print("sowingSupplement module "..field.." started")
			else
				--print("sowingSupplement module "..field.." not started");
			end;
		else
			setXMLBool(Xml, "sowingSupplement.Modules."..XmlField, true);
			--print("sowingSupplement module "..field.." inserted into xml and started");
		end;
	end;

	saveXMLFile(Xml);
end;
