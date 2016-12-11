--
--	Fertilization
--	fertilizer switch
--
-- @author:  	gotchTOM
-- @date:			09-Dec-2016
-- @version:	v1.04
--
-- free for noncommerical-usage
--

Fertilization = {};
-- local mod_directory = g_currentModDirectory;

function Fertilization.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(SowingMachine, specializations);
end;
function Fertilization:preLoad(savegame)
	self.getIsTurnedOnAllowed = Utils.overwrittenFunction(self.getIsTurnedOnAllowed, Fertilization.getIsTurnedOnAllowed);
end;

function Fertilization:load(savegame)
	
	self.updateFertiGUI = SpecializationUtil.callSpecializationsFunction("updateFertiGUI");
	-- self:updateFertiGUI();
end;

function Fertilization:postLoad(savegame)  
	if savegame ~= nil and not savegame.resetVehicles and self.activeModules ~= nil and self.activeModules.fertilization then
		self.activeModules.fertilization = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key .. "#fertilizationSwitchIsActiv"), self.activeModules.fertilization);
		self:updateFertiGUI();
		-- print("!!!!!!!!!!!!!!Fertilization:postLoad_fertilizationSwitchIsActiv = "..tostring(self.activeModules.fertilization))
	end;
end;

function Fertilization:delete()
end;

function Fertilization:mouseEvent(posX, posY, isDown, isUp, button)
end;

function Fertilization:keyEvent(unicode, sym, modifier, isDown)
end;

function Fertilization:getSaveAttributesAndNodes(nodeIdent)
	if self.activeModules ~= nil and self.activeModules.fertilization ~= nil then
		local attributes = 'fertilizationSwitchIsActiv="' .. tostring(self.activeModules.fertilization) ..'"';
		-- print("!!!!!!!!!!!!!!Fertilization:getSaveAttributesAndNodes_attributes = "..tostring(attributes))
	end;	
	return attributes, nil;
end;

function Fertilization:update(dt)
end;

function Fertilization:updateTick(dt)
end;

function Fertilization:draw()
-- renderText(0.1,0.1,0.02,"self.allowsSpraying "..tostring(self.allowsSpraying))
end;

function Fertilization:getIsTurnedOnAllowed(superFunc, isTurnedOn)
		local attacherVehicle = self:getRootAttacherVehicle();
    if not self.allowsSpraying and attacherVehicle.isMotorStarted then
        return true;
    end;
    if superFunc ~= nil then
        return superFunc(self, isTurnedOn);
    end;
    return true;
end;

function Fertilization:updateFertiGUI()
-- print("Fertilization:updateFertiGUI()")
	if self.activeModules ~= nil then
		if self.activeModules.fertilization then
			self.hud1.grids.main.elements.fertilizer.value = self.allowsSpraying;
			self.hud1.grids.main.elements.fertilizer.isVisible = true;
		else
			self.hud1.grids.main.elements.fertilizer.isVisible = false;
			self.hud1.grids.config.elements.fertiModul.value = false;
		end;
	end;
end;
