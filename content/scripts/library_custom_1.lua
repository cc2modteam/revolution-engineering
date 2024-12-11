-- revolution crafting system
--
-- when you are near and/or control particular island types you will be able to
-- unlock extra loadout options for some units, doing so will involve a "cost"
-- to be paid in carrier inventory stock (dumped over the side).
-- once fitted out in one of these special modes, if you remove anything
-- added by the alternate loadout, you wont be permitted to re-add it.

function custom_dynamic_vehicle_loadout_rows(vehicle, dynamic)
	return dynamic
end

function custom_dynamic_vehicle_loadout_options(vehicle, dynamic, attachment_index)
	return dynamic
end


function rev_engineering_can_upgrade(vehicle)
	return rev_get_custom_upgrade_option(vehicle) ~= nil
end

g_prompt_upgrade_vehicle = nil

function rev_get_custom_upgrade_option(vehicle)
	if vehicle and vehicle:get() then
		local def = vehicle:get_definition_index()
		for _, value in pairs(g_revolution_crafting_items) do
			if value.chassis == def then
				return value
			end
		end
	end
	return nil
end


function custom_vehicle_input_event(event, action)
	if g_prompt_upgrade_vehicle then
		if event == e_input.back then
			g_prompt_upgrade_vehicle = nil
		end
	end
end

function custom_vehicle_loadout_update(screen_w, screen_h, ticks)
	if g_prompt_upgrade_vehicle then
		local vehicle = update_get_map_vehicle_by_id(g_prompt_upgrade_vehicle)
		local upgrade_option = rev_get_custom_upgrade_option(vehicle)

		if upgrade_option ~= nil then
			local carrier = get_managed_vehicle()
			update_add_ui_interaction(update_get_loc(e_loc.interaction_back), e_game_input.back)
			local ui = g_ui
			ui:begin_ui()
			local window = ui:begin_window("Engineering", 0, 0, screen_w, screen_h, nil, true, 1)
			-- title
			update_ui_rectangle(0, 0, screen_w, 14, color_white)
			window.cy = 3 + update_ui_text(0, 4, "UPGRADE UNIT", screen_w, 1, color_black, 0)
			local v_def = vehicle:get_definition_index()

			-- body
			local v_name, v_icon, v_abbr, v_desc = get_chassis_data_by_definition_index(v_def)

			ui:text_basic(v_name, color_white, color_white)
			ui:text_basic("> " .. upgrade_option.name)
			ui:text_basic(upgrade_option.details)
			ui:text_basic("COST:")
			for inv_item, inv_count in pairs(upgrade_option.cost) do
				ui:text_basic(string.format("%d x %s", inv_count, g_item_data[inv_item].name))
			end

			if ui:button("upgrade", true, 1) then
				g_prompt_upgrade_vehicle = nil
				if update_get_is_focus_local() then
					-- do the upgrade
					for anum, adef in pairs(upgrade_option.attachments) do
						carrier:set_attached_vehicle_attachment(g_selected_bay_index, anum, adef)
					end
				end
			end

			ui:end_window()
			ui:end_ui()
			return true
		else
			g_prompt_upgrade_vehicle = nil
		end
	end

	return false
end

function custom_ui_vehicle_loadout_chassis(ui, vehicle)
	if rev_engineering_can_upgrade(vehicle) then
		if ui.prompt_upgrade then
			ui:text("hello world foo bar")
		else
			rev_custom_button(ui, "UPGRADE",
					4, 72, 47, 18, true, function()
						if vehicle and vehicle:get() then
							g_prompt_upgrade_vehicle = vehicle:get_id()
						end
					end)
		end
	else
		g_prompt_upgrade_vehicle = nil
	end
end

--

local g__crafting_reduced_wing = {
	e_game_object_type.attachment_turret_plane_chaingun,
	e_game_object_type.attachment_hardpoint_bomb_1,
	e_game_object_type.attachment_hardpoint_missile_ir,
	e_game_object_type.attachment_hardpoint_missile_laser,
	e_game_object_type.attachment_hardpoint_missile_aa,
	e_game_object_type.attachment_hardpoint_missile_tv,
	e_game_object_type.attachment_hardpoint_torpedo,
	e_game_object_type.attachment_hardpoint_torpedo_noisemaker,
	e_game_object_type.attachment_hardpoint_torpedo_decoy,
	e_game_object_type.fuel_tank_aircraft,
}

local g__crafting_aa_extra_wing = {
	e_game_object_type.attachment_hardpoint_missile_aa,
}

local g__crafting_flare_wing = {
	e_game_object_type.fuel_tank_aircraft,
	e_game_object_type.flare_launcher,
}

g_revolution_crafting_items = {
    -- Guardian Petrel
    --  - 1 flare launcher
    --  - 1 sonic pulse
    --  - 1 golfball radar
    --  - 1 torpedo_noisemaker
    --  - 1 tv missile
    --  - unable to airlift
    -- cost:
    --  - 1x razorbill
    --  - 1x flare launcher
    {
		name="Petrel S1",
		details="Anti-ship & AEW",
        chassis=e_game_object_type.chassis_air_rotor_heavy,
        attachments={
            [1] = e_game_object_type.attachment_radar_golfball,
		},
		options={
			[1] = {},
			[2] = g__crafting_reduced_wing,
			[3] = g__crafting_reduced_wing,
			[4] = g__crafting_reduced_wing,
			[5] = g__crafting_flare_wing,
		},
		rows={},
        cost={
            [e_inventory_item.vehicle_rotor_light] = 1,
            [e_inventory_item.attachment_flare_launcher] = 1,
        }
    },
	{
		name="Manta F2",
		details="Air combat",
		chassis=e_game_object_type.chassis_air_wing_heavy,
		attachments={
			[10] = e_game_object_type.attachment_camera_observation,
		},
		options={
			[8] = g__crafting_aa_extra_wing,
			[9] = g__crafting_aa_extra_wing,
		},
		rows={
		   {
			   { i = 8, x = -11, y = 24 }, -- left wing
			   { i = 9, x = 11, y = 24 }   -- right wing
			}
		},
		cost={
            [e_inventory_item.vehicle_wheel_light] = 1,
            [e_inventory_item.fuel_barrel] = 2,
			[e_inventory_item.ammo_cruise_missile] = 2,
        }
	}
}
