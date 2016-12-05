SpecializationUtil.registerSpecialization("sowingSupp", "SowingSupp", g_currentModDirectory.."sowingSupp.lua")
SpecializationUtil.registerSpecialization("sowingCounter", "SowingCounter", g_currentModDirectory.."SowingCounter/sowingCounter.lua")
SpecializationUtil.registerSpecialization("sowingSounds", "SowingSounds", g_currentModDirectory.."SowingSounds/sowingSounds.lua")
SpecializationUtil.registerSpecialization("drivingLine", "DrivingLine", g_currentModDirectory.."DrivingLine/drivingLine.lua")

SowingSupp_Register = {};
local modItem = ModsUtil.findModItemByModName(g_currentModName);
SowingSupp_Register.version = (modItem and modItem.version) and modItem.version or "?.?.?";

function SowingSupp_Register:loadMap(name)
	if self.firstRun == nil then
		self.firstRun = false;
		print('*** SowingSupplement v'..SowingSupp_Register.version..' specialization loading ***');

		for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
			if v ~= nil then
				for i = 1, table.maxn(v.specializations) do
					local vs = v.specializations[i];
					if vs ~= nil and vs == SpecializationUtil.getSpecialization("sowingMachine") then
						local allowInsertion = true;
						local v_name_string = v.name
						local point_location = string.find(v_name_string, ".", nil, true)
						if point_location ~= nil then
							local _name = string.sub(v_name_string, 1, point_location-1);
							if rawget(SpecializationUtil.specializations, string.format("%s.sowingSupp", _name)) ~= nil then
								allowInsertion = false;
								print(tostring(v.name)..": Specialization sowingSupp is present! SowingSupp was not inserted!");
							end;
							if rawget(SpecializationUtil.specializations, string.format("%s.SowingSupp", _name)) ~= nil then
								allowInsertion = false;
								print(tostring(v.name)..": Specialization SowingSupp is present! SowingSupp was not inserted!");
							end;
							if rawget(SpecializationUtil.specializations, string.format("%s.F_35", _name)) ~= nil then
								allowInsertion = false;
								print(tostring(v.name)..": Specialization F_35 is present! SowingSupp was not inserted!");
							end;
						end;
						if allowInsertion then
							-- print("adding SowingSupp to:"..tostring(v.name));
							table.insert(v.specializations, SpecializationUtil.getSpecialization("sowingSupp"));
							vs.SOWINGSUPP_CONFIGLABEL = g_i18n:getText("SOWINGSUPP_CONFIGLABEL");
							vs.SOWINGSUPP_HUDon = g_i18n:getText("SOWINGSUPP_HUDon");
							vs.SOWINGSUPP_HUDoff = g_i18n:getText("SOWINGSUPP_HUDoff");
							vs.SOWINGCOUNTER = g_i18n:getText("SOWINGCOUNTER");
							vs.SOWINGSOUNDS = g_i18n:getText("SOWINGSOUNDS");
							vs.SOWINGSOUNDS_SIGNAL = g_i18n:getText("SOWINGSOUNDS_SIGNAL");
							vs.DRIVINGLINE = g_i18n:getText("DRIVINGLINE");
							vs.DRIVINGLINE_OFF = g_i18n:getText("DRIVINGLINE_OFF");
							vs.DRIVINGLINE_ON = g_i18n:getText("DRIVINGLINE_ON");
							vs.DRIVINGLINE_SHIFT = g_i18n:getText("DRIVINGLINE_SHIFT");
							vs.DRIVINGLINE_PAUSE = g_i18n:getText("DRIVINGLINE_PAUSE");
							vs.DRIVINGLINE_ENABLE = g_i18n:getText("DRIVINGLINE_ENABLE");
							vs.DRIVINGLINE_MANUAL = g_i18n:getText("DRIVINGLINE_MANUAL");
							vs.DRIVINGLINE_SEMIAUTO = g_i18n:getText("DRIVINGLINE_SEMIAUTO");
							vs.DRIVINGLINE_AUTO = g_i18n:getText("DRIVINGLINE_AUTO");
							vs.DRIVINGLINE_GPS = g_i18n:getText("DRIVINGLINE_GPS");
							vs.DRIVINGLINE_MODE = g_i18n:getText("DRIVINGLINE_MODE");
							vs.DRIVINGLINE_SPWORKWIDTH = g_i18n:getText("DRIVINGLINE_SPWORKWIDTH");
							vs.DRIVINGLINE_CURRENTLANE = g_i18n:getText("DRIVINGLINE_CURRENTLANE");
							vs.DRIVINGLINE_WORKWIDTH = g_i18n:getText("DRIVINGLINE_WORKWIDTH");
							vs.DRIVINGLINE_NUMDRILINE = g_i18n:getText("DRIVINGLINE_NUMDRILINE");
							table.insert(v.specializations, SpecializationUtil.getSpecialization("sowingCounter"));
							table.insert(v.specializations, SpecializationUtil.getSpecialization("sowingSounds"));
							table.insert(v.specializations, SpecializationUtil.getSpecialization("drivingLine"));
						end;
					end;
				end;
			end;
		end;
	end;
end;

function SowingSupp_Register:deleteMap()

end;

function SowingSupp_Register:keyEvent(unicode, sym, modifier, isDown)

end;

function SowingSupp_Register:mouseEvent(posX, posY, isDown, isUp, button)

end;

function SowingSupp_Register:update(dt)

end;

function SowingSupp_Register:draw()

end;

addModEventListener(SowingSupp_Register);
