--
--	SowingSounds
--	Sounds for Sowing Machines (acoustic signals)
--
-- @authors:  	GreenEye and gotchTOM
-- @date:				15-Feb-2017
-- @version:		v1.05
--
-- free for noncommerical-usage
--

SowingSounds = {};

function SowingSounds.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function SowingSounds:load(savegame)
	if self.hasSowingMachineWorkArea == nil then
		for _,workArea in pairs(self.workAreaByType) do
			for _,a in pairs(workArea) do
				local areaTypeStr = WorkArea.areaTypeIntToName[a.type];
				if areaTypeStr == "sowingMachine" then
					self.hasSowingMachineWorkArea = true;
				end;
			end;
		end;
	end;
	if not self.hasSowingMachineWorkArea then
		return
	end;
	self.updateSoSoGUI = SpecializationUtil.callSpecializationsFunction("updateSoSoGUI");
	if self.sowingSounds == nil then
		self.sowingSounds = {};
	end;
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
	if self.sowingSounds.soundVolume == nil then
		self.sowingSounds.soundVolume = {lower = 1.0, raised = 1.0, tramline = 1.0, empty = 1.0};
	end;
	local SeSoSoundFile1 = Utils.getFilename("lower.wav", SowingSupp.path.."SowingSounds/");
		self.SeSoSoundId1 = createSample("SeSoSound1");
		loadSample(self.SeSoSoundId1, SeSoSoundFile1, false);
	local SeSoSoundFile2 = Utils.getFilename("raised.wav", SowingSupp.path.."SowingSounds/");
		self.SeSoSoundId2 = createSample("SeSoSound2");
		loadSample(self.SeSoSoundId2, SeSoSoundFile2, false);
	local SeSoSoundFile3 = Utils.getFilename("line.wav", SowingSupp.path.."SowingSounds/");
		self.SeSoSoundId3 = createSample("SeSoSound3");
		loadSample(self.SeSoSoundId3, SeSoSoundFile3, false);
	local SeSoSoundFile4 = Utils.getFilename("empty.wav", SowingSupp.path.."SowingSounds/");
		self.SeSoSoundId4 = createSample("SeSoSound4");
		loadSample(self.SeSoSoundId4, SeSoSoundFile4, false);
	self:updateSoSoGUI();
end;

function SowingSounds:postLoad(savegame)
	if self.hasSowingMachineWorkArea then
		if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.sowingSounds ~= nil and self.sowingSounds ~= nil then
			self.activeModules.sowingSounds = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#sowingSoundIsActiv"), self.activeModules.sowingSounds);
			self.sowingSounds.isAllowed = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#sowingSoundIsAllowed"), self.sowingSounds.isAllowed);
			self:updateSoSoGUI();
		end;
	end;
end;

function SowingSounds:delete()
	if self.hasSowingMachineWorkArea then
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
end;

function SowingSounds:mouseEvent(posX, posY, isDown, isUp, button)
end;

function SowingSounds:keyEvent(unicode, sym, modifier, isDown)
end;

function SowingSounds:getSaveAttributesAndNodes(nodeIdent)
	local attributes = "";
	if self.hasSowingMachineWorkArea and self.activeModules ~= nil and self.activeModules.sowingSounds ~= nil then
		attributes = 'sowingSoundIsActiv="' .. tostring(self.activeModules.sowingSounds) ..'"';
		attributes = attributes.. ' sowingSoundIsAllowed="' .. tostring(self.sowingSounds.isAllowed) ..'"';
	end;
	return attributes, nil;
end;

function SowingSounds:update(dt)
end;

function SowingSounds:updateTick(dt)

	if self:getIsActive() and self.hasSowingMachineWorkArea then
		if self.isClient and self:getIsActiveForSound() then
			if self.activeModules ~= nil and self.activeModules.sowingSounds and self.sowingSounds ~= nil and self.sowingSounds.isAllowed then
				if not self.sowingSounds.checkOnLeave then
					self.sowingSounds.checkOnLeave = true;
				end;
				if self:getIsTurnedOn() then
					if not self.sowingSounds.isLowered then
						if self.soMaIsLowered then
							playSample(self.SeSoSoundId1, 1, self.sowingSounds.soundVolume["lower"], 0);
							self.sowingSounds.isLowered = true;
						end;
					else
						if not self.soMaIsLowered then
							self.sowingSounds.isLowered = false;
						end;
					end;
					if not self.sowingSounds.isRaised then
						if not self.soMaIsLowered then
							playSample(self.SeSoSoundId2, 0, self.sowingSounds.soundVolume["raised"], 0);
							self.sowingSounds.isRaised = true;
						end;
					else
						if self.soMaIsLowered then
							self.sowingSounds.isRaised = false;
							stopSample(self.SeSoSoundId2);
						end;
					end;
					if not self.sowingSounds.isLineActive then					--> falls drivingLine.lua vorhanden
						if self.drivingLineActiv then
							playSample(self.SeSoSoundId3, 0, self.sowingSounds.soundVolume["tramline"], 0);
							self.sowingSounds.isLineActive = true;
						end;
					else
						if not self.drivingLineActiv then
							self.sowingSounds.isLineActive = false;
							stopSample(self.SeSoSoundId3);
						end;
					end;
					-- fillLevel
					local fillLevelInformations = {};
					if self.getFillLevelInformation ~= nil then
						self:getFillLevelInformation(fillLevelInformations);
						for _,fillLevelInformation in pairs(fillLevelInformations) do
								if fillLevelInformation.fillLevel <= 0.05 * fillLevelInformation.capacity then
									if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER or fillLevelInformation.fillType == FillUtil.FILLTYPE_LIQUIDFERTILIZER then
										if not self.sowingSounds.isFertiLow5Percent then
											playSample(self.SeSoSoundId4, 1, self.sowingSounds.soundVolume["empty"], 0);
											self.sowingSounds.isFertiLow5Percent = true;
										else
											if fillLevelInformation.fillLevel > 0.05 * fillLevelInformation.capacity then
												self.sowingSounds.isFertiLow5Percent = false;
											end;
										end;
									else
										if not self.sowingSounds.isSeedLow5Percent then
											playSample(self.SeSoSoundId4, 1, self.sowingSounds.soundVolume["empty"], 0);
											self.sowingSounds.isSeedLow5Percent = true;
										else
											if fillLevelInformation.fillLevel > 0.05 * fillLevelInformation.capacity then
												self.sowingSounds.isSeedLow5Percent = false;
											end;
										end;
									end;
								end;
								if fillLevelInformation.fillLevel <= 0.01 * fillLevelInformation.capacity then
									if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER or fillLevelInformation.fillType == FillUtil.FILLTYPE_LIQUIDFERTILIZER then
										if not self.sowingSounds.isFertiLow1Percent then
											playSample(self.SeSoSoundId4, 1, self.sowingSounds.soundVolume["empty"], 0);
											self.sowingSounds.isFertiLow1Percent = true;
										else
											if fillLevelInformation.fillLevel > 0.01 * fillLevelInformation.capacity then
												self.sowingSounds.isFertiLow1Percent = false;
											end;
										end;
									else
										if not self.sowingSounds.isSeedLow1Percent then
											playSample(self.SeSoSoundId4, 1, self.sowingSounds.soundVolume["empty"], 0);
											self.sowingSounds.isSeedLow1Percent = true;
										else
											if fillLevelInformation.fillLevel > 0.01 * fillLevelInformation.capacity then
												self.sowingSounds.isSeedLow1Percent = false;
											end;
										end;
									end;
								end;
								if fillLevelInformation.fillLevel <= 10 then
									if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER or fillLevelInformation.fillType == FillUtil.FILLTYPE_LIQUIDFERTILIZER then
										if not self.sowingSounds.isFertiEmpty then
											playSample(self.SeSoSoundId4, 1, self.sowingSounds.soundVolume["empty"], 0);
											self.sowingSounds.isFertiEmpty = true;
										end;
									else
										if not self.sowingSounds.isSeedEmpty then
											playSample(self.SeSoSoundId4, 0, self.sowingSounds.soundVolume["empty"], 0);
											self.sowingSounds.isSeedEmpty = true;
										end;
									end;
								elseif fillLevelInformation.fillLevel > 0 then
									if fillLevelInformation.fillType == FillUtil.FILLTYPE_FERTILIZER or fillLevelInformation.fillType == FillUtil.FILLTYPE_LIQUIDFERTILIZER then
										if self.sowingSounds.isFertiEmpty then
											self.sowingSounds.isFertiEmpty = false;
											stopSample(self.SeSoSoundId4);
										end;
									else
										if self.sowingSounds.isSeedEmpty then
											self.sowingSounds.isSeedEmpty = false;
											stopSample(self.SeSoSoundId4);
										end;
									end;
								end;
						end;
					end;
				else								--> Deaktivieren beim Abschalten
					if self.sowingSounds.isRaised then
						self.sowingSounds.isRaised = false;
						stopSample(self.SeSoSoundId2);
					end;
					if self.sowingSounds.isLineActive then
						self.sowingSounds.isLineActive = false;
						stopSample(self.SeSoSoundId3);
					end;
					if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
						self.sowingSounds.isSeedEmpty = false;
						self.sowingSounds.isFertiEmpty = false;
						stopSample(self.SeSoSoundId4);
					end;
				end;
			else										--> Deaktivieren beim Verbieten des Sounds
				if self.sowingSounds.isRaised then
					self.sowingSounds.isRaised = false;
					stopSample(self.SeSoSoundId2);
				end;
				if self.sowingSounds.isLineActive then
					self.sowingSounds.isLineActive = false;
					stopSample(self.SeSoSoundId3);
				end;
				if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
					self.sowingSounds.isSeedEmpty = false;
					self.sowingSounds.isFertiEmpty = false;
					stopSample(self.SeSoSoundId4);
				end;
			end;
		end;
	else 											--> Deaktivieren beim Aussteigen
		if self.sowingSounds ~= nil and self.sowingSounds.checkOnLeave then
			if self.sowingSounds.isRaised then
				self.sowingSounds.isRaised = false;
				stopSample(self.SeSoSoundId2);
			end;
			if self.sowingSounds.isLineActive then
				self.sowingSounds.isLineActive = false;
				stopSample(self.SeSoSoundId3);
			end;
			if self.sowingSounds.isSeedEmpty or self.sowingSounds.isFertiEmpty then
				self.sowingSounds.isSeedEmpty = false;
				self.sowingSounds.isFertiEmpty = false;
				stopSample(self.SeSoSoundId4);
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