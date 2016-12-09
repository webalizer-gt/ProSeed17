--
--	SowingSounds
--	Sounds for Sowing Machines (acoustic signals)
--
-- @author:  	GreenEye and gotchTOM
-- @date:			10-Nov-2016
-- @version:	v1.01
--
-- free for noncommerical-usage
--

SowingSounds = {};
-- local mod_directory = g_currentModDirectory;

function SowingSounds.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function SowingSounds:load(xmlFile)

	self.updateSoSoGUI = SpecializationUtil.callSpecializationsFunction("updateSoSoGUI");
	self.sowingSounds = {};
	self.sowingSounds.isLowered = false;
	self.sowingSounds.isRaised = false;
	self.sowingSounds.isLineActive = false;
	self.sowingSounds.isSeedLow5Percent = false;
	self.sowingSounds.isFertiLow5Percent = false;
	self.sowingSounds.isSeedLow1Percent = false;
	self.sowingSounds.isFertiLow1Percent = false;
	self.sowingSounds.isSeedEmpty = false;
	self.sowingSounds.isFertiEmpty = false;
	self.sowingSounds.isAllowed = true;
	self.sowingSounds.checkOnLeave = false;

	local SeSoSoundFile1 = Utils.getFilename("lower.wav", g_modsDirectory.."/ZZZ_sowingSupp/SowingSounds/");
    self.SeSoSoundId1 = createSample("SeSoSound1");
    loadSample(self.SeSoSoundId1, SeSoSoundFile1, false);

	local SeSoSoundFile2 = Utils.getFilename("raised.wav", g_modsDirectory.."/ZZZ_sowingSupp/SowingSounds/");
    self.SeSoSoundId2 = createSample("SeSoSound2");
    loadSample(self.SeSoSoundId2, SeSoSoundFile2, false);

	local SeSoSoundFile3 = Utils.getFilename("line.wav", g_modsDirectory.."/ZZZ_sowingSupp/SowingSounds/");
    self.SeSoSoundId3 = createSample("SeSoSound3");
    loadSample(self.SeSoSoundId3, SeSoSoundFile3, false);
		
	local SeSoSoundFile4 = Utils.getFilename("empty.wav", g_modsDirectory.."/ZZZ_sowingSupp/SowingSounds/");
    self.SeSoSoundId4 = createSample("SeSoSound4");
    loadSample(self.SeSoSoundId4, SeSoSoundFile4, false);

	self:updateSoSoGUI();
end;

function SowingSounds:postLoad(savegame)  
	if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.sowingSounds then
		self.activeModules.sowingSounds = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#sowingSoundIsActiv"), self.activeModules.sowingSounds);
		self:updateSoSoGUI();
		-- print("!!!!!!!!!!!!!!SowingSounds:postLoad_sowingSoundIsActiv = "..tostring(self.activeModules.sowingSounds))
	end;
end;

function SowingSounds:delete()

	if self.sowingSounds ~= nil then
		if self.sowingSounds.isRaised then
			stopSample(self.SeSoSoundId2);
		end;
		if self.sowingSounds.isLineActive then
			stopSample(self.SeSoSoundId3);
		end;
		if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
			stopSample(self.SeSoSoundId4);
		end;
	end;
end;

function SowingSounds:mouseEvent(posX, posY, isDown, isUp, button)
end;

function SowingSounds:keyEvent(unicode, sym, modifier, isDown)
end;

function SowingSounds:getSaveAttributesAndNodes(nodeIdent)
	local attributes = 'sowingSoundIsActiv="' .. tostring(self.activeModules.sowingSounds) ..'"';
	-- print("!!!!!!!!!!!!!!SowingSounds:getSaveAttributesAndNodes_attributes = "..tostring(attributes))
	return attributes, nil;
end;

function SowingSounds:update(dt)
end;

function SowingSounds:updateTick(dt)

	if self:getIsActive() then
		if self.activeModules ~= nil and self.activeModules.sowingSounds and self.sowingSounds ~= nil and self.sowingSounds.isAllowed and self:getIsActiveForSound() then
			-- renderText(0.1,0.3,0.02,"self.soMaIsLowered: "..tostring(self.soMaIsLowered))
			-- renderText(0.1,0.32,0.02,"self.sowingSounds.isLowered: "..tostring(self.sowingSounds.isLowered))
			-- renderText(0.1,0.34,0.02,"self.sowingSounds.isSeedLow5Percent: "..tostring(self.sowingSounds.isSeedLow5Percent))
			-- renderText(0.1,0.36,0.02,"self.sowingSounds.isSeedLow1Percent: "..tostring(self.sowingSounds.isSeedLow1Percent))
			-- renderText(0.1,0.38,0.02,"self.sowingSounds.isFertiLow5Percent: "..tostring(self.sowingSounds.isFertiLow5Percent))
			-- renderText(0.1,0.4,0.02,"self.sowingSounds.isFertiLow1Percent: "..tostring(self.sowingSounds.isFertiLow1Percent))
			-- renderText(0.1,0.42,0.02,"self.sowingSounds.isSeedEmpty: "..tostring(self.sowingSounds.isSeedEmpty))
			-- renderText(0.1,0.44,0.02,"self.sowingSounds.isFertiEmpty: "..tostring(self.sowingSounds.isFertiEmpty))
			if not self.sowingSounds.checkOnLeave then
				self.sowingSounds.checkOnLeave = true;
			end;
			if self:getIsTurnedOn() then
				if not self.sowingSounds.isLowered then
					if self.soMaIsLowered then
						playSample(self.SeSoSoundId1, 1, 1, 0);
						-- print("playSample(self.lower, 1, 1, 0);")
						self.sowingSounds.isLowered = true;
					end;
				else
					if not self.soMaIsLowered then
						self.sowingSounds.isLowered = false;
					end;
				end;

				if not self.sowingSounds.isRaised then
					if not self.soMaIsLowered then
						playSample(self.SeSoSoundId2, 0, 1, 0);
						-- print("playSample(self.raised, 0, 1, 0);")
						self.sowingSounds.isRaised = true;
					end;
				else
					if self.soMaIsLowered then
						self.sowingSounds.isRaised = false;
						stopSample(self.SeSoSoundId2);
						-- print("stopSample(self.raised);")
					end;
				end;
				if not self.sowingSounds.isLineActive then					--> falls drivingLine.lua vorhanden
					if self.drivingLineActiv then
						playSample(self.SeSoSoundId3, 0, 1, 0);
						--print("playSample(self.line, 0, 1, 0);")
						self.sowingSounds.isLineActive = true;
					end;
				else
					if not self.drivingLineActiv then
						self.sowingSounds.isLineActive = false;
						stopSample(self.SeSoSoundId3);
						--print("stopSample(self.line);")
					end;
				end;
				
				-- fillLevel
				local fillLevelInformations = {};
				if self.getFillLevelInformation ~= nil then
				 	self:getFillLevelInformation(fillLevelInformations);
					for _,fillLevelInformation in pairs(fillLevelInformations) do
							-- local fillTypeName = FillUtil.fillTypeIntToName[fillLevelInformation.fillType];
							-- renderText(0.1,0.56,0.02,"fillLevelInformation.fillType: "..tostring(fillLevelInformation.fillType))
							-- local x = FillUtil.FILLTYPE_SEEDS;
							-- print("fillLevelInformation.fillType"..tostring(fillLevelInformation.fillType))
							if fillLevelInformation.fillLevel <= 0.05 * fillLevelInformation.capacity then
								if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER then
									if not self.sowingSounds.isFertiLow5Percent then
										playSample(self.SeSoSoundId4, 1, 1, 0);
										-- print("playSample(Ferti 5%, 1, 1, 0);")
										self.sowingSounds.isFertiLow5Percent = true;
									else
										if fillLevelInformation.fillLevel > 0.05 * fillLevelInformation.capacity then
											self.sowingSounds.isFertiLow5Percent = false;
										end;
									end;
								else
									if not self.sowingSounds.isSeedLow5Percent then
										playSample(self.SeSoSoundId4, 1, 1, 0);
										-- print("playSample(Seed 5%, 1, 1, 0);")
										self.sowingSounds.isSeedLow5Percent = true;
									else
										if fillLevelInformation.fillLevel > 0.05 * fillLevelInformation.capacity then
											self.sowingSounds.isSeedLow5Percent = false;
										end;
									end;
								end;
							end;
							
							if fillLevelInformation.fillLevel <= 0.01 * fillLevelInformation.capacity then
								if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER then
									if not self.sowingSounds.isFertiLow1Percent then
										playSample(self.SeSoSoundId4, 1, 1, 0);
										-- print("playSample(Ferti 1%, 1, 1, 0);")
										self.sowingSounds.isFertiLow1Percent = true;
									else
										if fillLevelInformation.fillLevel > 0.01 * fillLevelInformation.capacity then
											self.sowingSounds.isFertiLow1Percent = false;
										end;
									end;
								else
									if not self.sowingSounds.isSeedLow1Percent then
										playSample(self.SeSoSoundId4, 1, 1, 0);
										-- print("playSample(Seed 1%, 1, 1, 0);")
										self.sowingSounds.isSeedLow1Percent = true;
									else
										if fillLevelInformation.fillLevel > 0.01 * fillLevelInformation.capacity then
											self.sowingSounds.isSeedLow1Percent = false;
										end;
									end;
								end;
							end;
							
							if fillLevelInformation.fillLevel <= 10 then
								if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER then
									if not self.sowingSounds.isFertiEmpty then
										playSample(self.SeSoSoundId4, 1, 1, 0);
										-- print("playSample(Ferti <= 10, 1, 1, 0);")
										self.sowingSounds.isFertiEmpty = true;
									end;
								else
									if not self.sowingSounds.isSeedEmpty then
										playSample(self.SeSoSoundId4, 0, 1, 0);
										-- print("playSample(Seed <= 10, 0, 1, 0);")
										self.sowingSounds.isSeedEmpty = true;
									end;
								end;
							elseif fillLevelInformation.fillLevel > 0 then
								if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER then
									if self.sowingSounds.isFertiEmpty then
										self.sowingSounds.isFertiEmpty = false;
										stopSample(self.SeSoSoundId4);
										-- print("!!!stopSample(self.SeSoSoundId4);")
									end;
								else
									if self.sowingSounds.isSeedEmpty then
										self.sowingSounds.isSeedEmpty = false;
										stopSample(self.SeSoSoundId4);
										-- print("!!!stopSample(self.SeSoSoundId4);")
									end;
								end;
							end;
					end;	
				end;
			else								--> Deaktivieren beim Abschalten
				if self.sowingSounds.isRaised then
					self.sowingSounds.isRaised = false;
					stopSample(self.SeSoSoundId2);
					-- print("stopSample(self.SeSoSoundId2);")
				end;
				if self.sowingSounds.isLineActive then
					self.sowingSounds.isLineActive = false;
					stopSample(self.SeSoSoundId3);
					-- print("stopSample(self.SeSoSoundId3);")
				end;
				if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
					self.sowingSounds.isSeedEmpty = false;
					self.sowingSounds.isFertiEmpty = false;
					stopSample(self.SeSoSoundId4);
					-- print("stopSample(self.SeSoSoundId4);")
				end;
			end;
		else										--> Deaktivieren beim Verbieten des Sounds
			if self.sowingSounds.isRaised then
				self.sowingSounds.isRaised = false;
				stopSample(self.SeSoSoundId2);
					-- print("stopSample(self.SeSoSoundId2);")
			end;
			if self.sowingSounds.isLineActive then
				self.sowingSounds.isLineActive = false;
				stopSample(self.SeSoSoundId3);
					-- print("stopSample(self.SeSoSoundId3);")
			end;
			if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
				self.sowingSounds.isSeedEmpty = false;
				self.sowingSounds.isFertiEmpty = false;
				stopSample(self.SeSoSoundId4);
					-- print("stopSample(self.SeSoSoundId4);")
			end;
		end;
	else 											--> Deaktivieren beim Aussteigen
		if self.sowingSounds ~= nil and self.sowingSounds.checkOnLeave then
			if self.sowingSounds.isRaised then
				self.sowingSounds.isRaised = false;
				stopSample(self.SeSoSoundId2);
					-- print("stopSample(self.SeSoSoundId2);")
			end;
			if self.sowingSounds.isLineActive then
				self.sowingSounds.isLineActive = false;
				stopSample(self.SeSoSoundId3);
					-- print("stopSample(self.SeSoSoundId3);")
			end;
			if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
				self.sowingSounds.isSeedEmpty = false;
				self.sowingSounds.isFertiEmpty = false;
				stopSample(self.SeSoSoundId4);
					-- print("stopSample(self.SeSoSoundId4);")
			end;
			self.sowingSounds.checkOnLeave = false;
		end;
	end;
end;

function SowingSounds:draw()
end;

function SowingSounds:updateSoSoGUI()
	if self.activeModules ~= nil then
		if self.activeModules.sowingSounds then
			self.hud1.grids.main.elements.sowingSound.value = self.sowingSounds.isAllowed;
			self.hud1.grids.main.elements.sowingSound.isVisible = true;
		else
			self.hud1.grids.main.elements.sowingSound.isVisible = false;
			self.hud1.grids.config.elements.soSoModul.value = false;
		end;
	end;
end;
