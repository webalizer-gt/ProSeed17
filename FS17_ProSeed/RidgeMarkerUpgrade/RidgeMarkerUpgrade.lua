--
--	ridgeMarker upgrade
--	upgrading the ridgeMarker operation of sowing machines
--
-- @author:  	webalizer & gotchTOM
-- @date:			15-Dec-2016
-- @version:	v1.06
--
-- free for noncommerical-usage
--

RidgeMarkerUpgrade = {};

function SowingCounter.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;

function RidgeMarkerUpgrade:load(savegame)
		self.canFoldRidgeMarker = Utils.overwrittenFunction(self.canFoldRidgeMarker, RidgeMarkerUpgrade.canFoldRidgeMarker);
		self.newCanFoldRidgeMarker = RidgeMarkerUpgrade.newCanFoldRidgeMarker;
		self.lastRidgeMarkerState = 2;
		self.rmCheckInputbindings = true;
		self.rmHasSameInputbinding = true;
end;

function RidgeMarkerUpgrade:delete()
end;

function RidgeMarkerUpgrade:readStream(streamId, connection)
end;

function RidgeMarkerUpgrade:writeStream(streamId, connection)
end;

function RidgeMarkerUpgrade:keyEvent(unicode, sym, modifier, isDown)
end;

function RidgeMarkerUpgrade:mouseEvent(posX, posY, isDown, isUp, button)
end;

function RidgeMarkerUpgrade:update(dt)
	if self:getIsActiveForInput() then
		if self.numRigdeMarkers ~= nil and self.numRigdeMarkers > 1 then
			if InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMleft) and InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMright) then
				local rmState = self.ridgeMarkerState;
				if rmState == 0 then
					if self.lastRidgeMarkerState == 2 then
						rmState = 1;
					elseif self.lastRidgeMarkerState == 1 then
						rmState = 2;
					end;
				else
					rmState = 0;
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
				else
					rmState = 0;
				end;
				if self:newCanFoldRidgeMarker(rmState) then
					self:setRidgeMarkerState(rmState);
				end;
			elseif InputBinding.hasEvent(InputBinding.RM_UPGRADE_RMright) then
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
	end;
 end;

function RidgeMarkerUpgrade:updateTick(dt)
	if self:getIsActive() then
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
	end;
end;

function RidgeMarkerUpgrade:draw()
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
