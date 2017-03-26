function SowingSupp:draw()
	if SowingSupp.stopMouse then
		InputBinding.setShowMouseCursor(true);
	end;
	if self.sosuHUDisActive then
		self.hud1.renderMe();
		g_currentMission:addHelpButtonText(SowingMachine.SOWINGSUPP_HUDoff, InputBinding.SOWINGSUPP_HUD, nil, GS_PRIO_VERY_HIGH);
	else
		g_currentMission:addHelpButtonText(SowingMachine.SOWINGSUPP_HUDon, InputBinding.SOWINGSUPP_HUD, nil, GS_PRIO_VERY_HIGH);
	end;
end;
