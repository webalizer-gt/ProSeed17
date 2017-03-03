--
--	ridgeMarker upgrade
--	upgrading the ridgeMarker operation of sowing machines
--
-- @author:  	webalizer & gotchTOM
-- @date:			3-Mar-2017
-- @version:	v1.09
--
-- free for noncommerical-usage
--

RidgeMarkerUpgrade = {};

function SowingCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function RidgeMarkerUpgrade:load(savegame)
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
	self.canFoldRidgeMarker = Utils.overwrittenFunction(self.canFoldRidgeMarker, RidgeMarkerUpgrade.canFoldRidgeMarker);
	self.newCanFoldRidgeMarker = RidgeMarkerUpgrade.newCanFoldRidgeMarker;
	self.lastRidgeMarkerState = 2;
	self.rmCheckInputbindings = true;
	self.rmHasSameInputbinding = true;
	self.autoRidgeMarkerState = false;
end;

function RidgeMarkerUpgrade:delete()
end;

function RidgeMarkerUpgrade:keyEvent(unicode, sym, modifier, isDown)
end;

function RidgeMarkerUpgrade:mouseEvent(posX, posY, isDown, isUp, button)
end;

function RidgeMarkerUpgrade:update(dt)
	if self:getIsActive() and self.hasSowingMachineWorkArea then
		if self.isClient and self:getIsActiveForInput() then
			if self.numRigdeMarkers ~= nil and self.numRigdeMarkers > 1 then
				if InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMleft) and InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMright) then
					local rmState = self.ridgeMarkerState;
					if rmState == 0 then
						if self.lastRidgeMarkerState == 2 then
							rmState = 1;
						elseif self.lastRidgeMarkerState == 1 then
							rmState = 2;
						end;
						if self.soMaIsLowered then
							self.autoRidgeMarkerState = true;
						end;
					else
						rmState = 0;
						self.autoRidgeMarkerState = false;
					end;
					if self:newCanFoldRidgeMarker(rmState) then
						if rmState > 0 then
							self.lastRidgeMarkerState = rmState;
						end;
						self:setRidgeMarkerState(rmState);
					end;
				elseif InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMleft) then
					local rmState = self.ridgeMarkerState;
					if rmState == 0 then
						rmState = 1;
						if self.soMaIsLowered then
							self.autoRidgeMarkerState = true;
						end;
					else
						rmState = 0;
						self.autoRidgeMarkerState = false;
					end;
					if self:newCanFoldRidgeMarker(rmState) then
						if rmState > 0 then
							self.lastRidgeMarkerState = rmState;
						end;
						self:setRidgeMarkerState(rmState);
					end;
				elseif InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMright) then
					local rmState = self.ridgeMarkerState;
					if rmState == 0 then
						rmState = 2;
						if self.soMaIsLowered then
							self.autoRidgeMarkerState = true;
						end;
					else
						rmState = 0;
						self.autoRidgeMarkerState = false;
					end;
					if self:newCanFoldRidgeMarker(rmState) then
						if rmState > 0 then
							self.lastRidgeMarkerState = rmState;
						end;
						self:setRidgeMarkerState(rmState);
					end;
				end;
			end;
		end;
	end;
 end;

function RidgeMarkerUpgrade:updateTick(dt)
	if self:getIsActive() and self.hasSowingMachineWorkArea then
		if self.isClient then
			if self.rmCheckInputbindings then
				local inputBinding1 = InputBinding.getRawKeyNamesOfDigitalAction(InputBinding.RM_UPGRADE_RMleft)
				local inputBinding2 = InputBinding.getRawKeyNamesOfDigitalAction(InputBinding.RM_UPGRADE_RMright)
				if #inputBinding1 == #inputBinding2 then
					i = 1;
					while i <= #inputBinding1 do
						if inputBinding1[i] ~= inputBinding2[i] then
							self.rmHasSameInputbinding = false;
						end;
						i = i + 1
					end;
				else
					self.rmHasSameInputbinding = false;
				end;
				self.rmCheckInputbindings = nil;
			end;
			if self.autoRidgeMarkerState then
				if self:getIsTurnedOn() then
					local rmState = self.ridgeMarkerState;
					if self.soMaIsLowered and rmState == 0 then
						if self.lastRidgeMarkerState == 1 then
							if self:newCanFoldRidgeMarker(2) then
								self.lastRidgeMarkerState = 2;
								self:setRidgeMarkerState(2);
							end;
						elseif self.lastRidgeMarkerState == 2 then
							if self:newCanFoldRidgeMarker(1) then
								self.lastRidgeMarkerState = 1;
								self:setRidgeMarkerState(1);
							end;
						end;
					elseif not self.soMaIsLowered and (rmState == 1 or rmState == 2) then
						self:setRidgeMarkerState(0);
					end;
				elseif not self:getIsTurnedOn() then
					self.autoRidgeMarkerState = false;
				end;
			end;
		end;
	end;
end;

function RidgeMarkerUpgrade:draw()
	if self.isClient and self.hasSowingMachineWorkArea then
		if self.numRigdeMarkers ~= nil and self.numRigdeMarkers > 1 then
			if self.rmHasSameInputbinding then
				g_currentMission:addHelpButtonText(g_i18n:getText("action_toggleRidgeMarker"), InputBinding.RM_UPGRADE_RMright, nil, GS_PRIO_VERY_HIGH);
			else
				g_currentMission:addHelpButtonText(SowingMachine.RM_UPGRADE_RMright, InputBinding.RM_UPGRADE_RMright, nil, GS_PRIO_VERY_HIGH);
				g_currentMission:addHelpButtonText(SowingMachine.RM_UPGRADE_RMleft, InputBinding.RM_UPGRADE_RMleft, nil, GS_PRIO_VERY_HIGH);
			end;
			if self.ridgeMarkerState == 1 then
				self.hud1.grids.main.elements.ridgeMarkerLeft.isVisible = false;
				self.hud1.grids.main.elements.ridgeMarkerLeftActive.isVisible = true;
				self.hud1.grids.main.elements.ridgeMarkerRight.isVisible = true;
				self.hud1.grids.main.elements.ridgeMarkerRightActive.isVisible = false;
			elseif self.ridgeMarkerState == 2 then
				self.hud1.grids.main.elements.ridgeMarkerLeft.isVisible = true;
				self.hud1.grids.main.elements.ridgeMarkerLeftActive.isVisible = false;
				self.hud1.grids.main.elements.ridgeMarkerRight.isVisible = false;
				self.hud1.grids.main.elements.ridgeMarkerRightActive.isVisible = true;
			else
				self.hud1.grids.main.elements.ridgeMarkerLeft.isVisible = true;
				self.hud1.grids.main.elements.ridgeMarkerLeftActive.isVisible = false;
				self.hud1.grids.main.elements.ridgeMarkerRight.isVisible = true;
				self.hud1.grids.main.elements.ridgeMarkerRightActive.isVisible = false;
			end;
		end;
	end;
end;

function RidgeMarkerUpgrade:newCanFoldRidgeMarker(state)
  if self.foldAnimTime ~= nil and (self.foldAnimTime < self.ridgeMarkerMinFoldTime or self.foldAnimTime > self.ridgeMarkerMaxFoldTime) then
      return false;
  end;
  if state ~= 0 and not self.moveToMiddle and self.foldDisableDirection ~= nil and (self.foldDisableDirection == self.foldMoveDirection or self.foldMoveDirection == 0) then
      return false;
  end;
  return true;
end;

function RidgeMarkerUpgrade:canFoldRidgeMarker(state)
	return false;
end;