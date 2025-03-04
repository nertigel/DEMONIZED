--[[
	https://github.com/nertigel/DEMONIZED

	████████▄     ▄████████    ▄▄▄▄███▄▄▄▄    ▄██████▄  ███▄▄▄▄    ▄█   ▄███████▄     ▄████████ ████████▄  
	███   ▀███   ███    ███  ▄██▀▀▀███▀▀▀██▄ ███    ███ ███▀▀▀██▄ ███  ██▀     ▄██   ███    ███ ███   ▀███ 
	███    ███   ███    █▀   ███   ███   ███ ███    ███ ███   ███ ███▌       ▄███▀   ███    █▀  ███    ███ 
	███    ███  ▄███▄▄▄      ███   ███   ███ ███    ███ ███   ███ ███▌  ▀█▀▄███▀▄▄  ▄███▄▄▄     ███    ███ 
	███    ███ ▀▀███▀▀▀      ███   ███   ███ ███    ███ ███   ███ ███▌   ▄███▀   ▀ ▀▀███▀▀▀     ███    ███ 
	███    ███   ███    █▄   ███   ███   ███ ███    ███ ███   ███ ███  ▄███▀         ███    █▄  ███    ███ 
	███   ▄███   ███    ███  ███   ███   ███ ███    ███ ███   ███ ███  ███▄     ▄█   ███    ███ ███   ▄███ 
	████████▀    ██████████   ▀█   ███   █▀   ▀██████▀   ▀█   █▀  █▀    ▀████████▀   ██████████ ████████▀  
	made by nertigel
]]

--[[https://github.com/citizenfx/fivem/blob/master/data/shared/citizen/scripting/lua/scheduler.lua]]
local old_G = _G 
local cfx = Citizen
local create_thread = cfx.CreateThread 
local wait = cfx.Wait 
local invoke_native = (function(hash, ...)
	return cfx.InvokeNative(string.format(" %s ", hash), ...) --[[RIP Watermalone </3]]
end)
local GetHashKey = GetHashKey
local pairs = pairs 
local math = math  
local pcall = pcall 
local type = type 

local previous_garbage = 0
local garbage = math.floor(collectgarbage("count"))

--[[ useless if execution is isolated
debug.getlocal = (function(name, value)
    return nil, tostring(math.random(1, 9999999999999))
end)
]]

--[[ removed temp due to certain dicts being used as "decoy", meaning that loading them triggers menu usage on AC
for key, value in pairs({"commonmenu", "heisthud", "mpweaponscommon", "mpweaponscommon_small", "mpweaponsgang0_small", "mpweaponsgang1_small", "mpweaponsgang0", "mpweaponsgang1", "mpweaponsunusedfornow", "mpleaderboard", "mphud", "mparrow", "pilotschool", "shared"}) do 
	RequestStreamedTextureDict(value) 
end
]]

local framework = {
	is_loaded = true,
	windows = {
		main = {x = 1300, y = 300, w = 600, h = 550, wht = (600 + 550)/2},
		confirmation = {x = 500, y = 300, w = 200, h = 250, wht = (200 + 250)/2}
	},
	vars = {
		screen = {w = 1920, h = 1080},
		cursor = {x = 0, y = 0},
		dragged_window = {state = false, old_x = nil, old_y = nil},
		current_window = "main",
		current_tab = "user",
		random_str = "nertigel"..math.random(999999),
		groupbox_labels = {[1] = "groupbox1", [2] = "groupbox2"},
		is_developer = true
	},
	renderer = {
		notifications = {},
		should_draw = true,
		should_pause_rendering = false
	},
    colors = {
        theme = {r = 200, g = 85, b = 35, a = 254}
    },
	elements = {
		item = {x = 20, y = 5, w = 15, h = 15},
		previous_item = {x = 20, y = 5, w = 15, h = 15},
		second_column = false
	},
	groupboxes = {
		hovered = 0,
		scroll_y = {[1] = 0, [2] = 0}
	},
	
	config = {
		vehicle_spawn_set_into = true,
		settings_safe_mode = true,
		settings_existing_entities = true,
		settings_console_logging = true,
		settings_draw_notifications = true,
		settings_use_sprites = false,
		settings_xor_labels = true,
		settings_xor_thread_ms = 1000,
		settings_xor_letter = 1,
	},
	cache = {
		blame_carry = {
			by = nil,
			anim_dict = "nm",
			anim = "firemans_carry",
			attach_x = 0.27,
			attach_y = 0.15,
			attach_z = 0.63,
			flag = 33,
		}
	},
	events = {
		{event = "anticheat:EntityWipe", cancel = true, handler = nil},
		{event = "AntiCheese:RemoveInventoryWeapons", cancel = true, handler = nil},
		{event = "wld:delallveh", cancel = true, handler = nil},
		{event = "vehiclesDestructor", cancel = true, handler = nil},
		{event = "EasyAdmin:CaptureScreenshot", cancel = true, handler = nil},
		{event = "__cfx_nui:screenshot_created", cancel = true, handler = nil},
		{event = "screenshot_basic:requestScreenshot", cancel = true, handler = nil},
		{event = "requestScreenshot", cancel = true, handler = nil},
		{event = "screenshot-basic", cancel = true, handler = nil},
		{event = "requestScreenshotUpload", cancel = true, handler = nil},
	},
}

framework.mathematics = {
	clamp = (function(var, min, max)
		if (var < min) then
			return min
		elseif (var > max) then
			return max
		end
		
		return var
	end),
	rotation_to_quat = (function(rot)
		local math = math
		local pitch, roll, yaw = math.rad(rot.x), math.rad(rot.y), math.rad(rot.z); 
		local cy, sy, cr, sr, cp, sp = math.cos(yaw   * 0.5), math.sin(yaw   * 0.5), math.cos(roll  * 0.5), math.sin(roll  * 0.5), math.cos(pitch * 0.5), math.sin(pitch * 0.5); 
		return quat(cy * cr * cp + sy * sr * sp, cy * sp * cr - sy * cp * sr, cy * cp * sr + sy * sp * cr, sy * cr * cp - cy * sr * sp)
	end),
	slider_percentage = (function(v1, v2)
		local onepercent = v2 / 100
		local percent = onepercent * v1
		return percent
	end),
	to_percentage = (function(v1, v2)
		return (v1/v2) * 100
	end),
}
local write_to_console = (function(a) 
	if (framework.config.settings_console_logging) then 
		print(a)
	end
end)

framework.renderer._draw_rect = (function(x, y, w, h, r, g, b, a)
	local _x, _y = GetScriptGfxPosition(0.0, 0.0)
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
	invoke_native(0x3A618A217E5154F0, x, y, w, h, r, g, b, a)
	SetScriptGfxAlignParams(_x, _y, 0.0, 0.0)
end)
framework.renderer.draw_rect = (function(x, y, w, h, r, g, b, a)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	local v1 = framework.vars.screen
    local _w, _h = w / v1.w, h / v1.h
    local _x, _y = x / v1.w + _w / 2, y / v1.h + _h / 2
    framework.renderer._draw_rect(_x, _y, _w, _h, r, g, b, a)
end)

framework.renderer.draw_bordered_rect = (function(x, y, w, h, r, g, b, a, t)
	local draw_rect = framework.renderer.draw_rect
	t = t or 1
	draw_rect(x, y, t, h, r, g, b, a)
	draw_rect(x, y, w, t, r, g, b, a)
	draw_rect(x + (w - t), y, t, h, r, g, b, a)
	draw_rect(x, (y - t) + h, w, t, r, g, b, a)
end)

framework.renderer.draw_sprite = (function(txd, txn, x, y, w, h, hea, r, g, b, a)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	if not (framework.config.settings_use_sprites) then 
		return
	end
	local v1 = framework.vars.screen
	local _w, _h = w / v1.w, h / v1.h
	local _x, _y = x / v1.w + _w / 2, y / v1.h + _h / 2
	invoke_native(0xE7FFAE5EBF23D890, txd, txn, _x, _y, _w, _h, hea, r, g, b, a)
end)

framework.renderer.draw_unfined_text = (function(x, y, r, g, b, a, text, font, alignment, scale, outline)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	local v1 = framework.vars.screen
	local invoke_native = invoke_native
	local _x, _y = GetScriptGfxPosition(0.0, 0.0)
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)
	
	invoke_native(0x66E0276CC5F6B9DA, font)
	invoke_native(0x07C837F9A01C34C9, scale, scale)
	if (alignment == 1) then --[[centered]]
        invoke_native(0xC02F4DBFB51D988B, true)
    end
	if (outline) then
		invoke_native(0x2513DFB0FB8400FE)
	end
	invoke_native(0xBE6B23FFA53FB442, r, g, b, a)
	invoke_native(0x25FBB336DF1804CB, "STRING")
	invoke_native(0x6C188BE134E074AA, text)
	invoke_native(0xCD015E5BB0D96A57, x, y)

	SetScriptGfxAlignParams(_x, _y, 0.0, 0.0)
end)

framework.renderer.draw_text = (function(x, y, r, g, b, a, text, font, alignment, scale, outline)
	if (framework.renderer.should_pause_rendering) then
		return
	end
	local v1 = framework.vars.screen
	local invoke_native = invoke_native
	local _x, _y = GetScriptGfxPosition(0.0, 0.0)
    SetScriptGfxAlignParams(0.0, 0.0, 0.0, 0.0)

	invoke_native(0x66E0276CC5F6B9DA, font)
	invoke_native(0x07C837F9A01C34C9, scale, scale)
	if (alignment == 1) then --[[centered]]
		x = x + 27
        invoke_native(0xC02F4DBFB51D988B, true)
    elseif (alignment == 2) then --[[right]]
        local width = framework.renderer.get_text_width(text, font, scale)
        x = x - width
    end
	if (outline) then
		invoke_native(0x2513DFB0FB8400FE)
	end
	invoke_native(0xBE6B23FFA53FB442, r, g, b, a)
	invoke_native(0x25FBB336DF1804CB, "STRING")
	invoke_native(0x6C188BE134E074AA, text)
	invoke_native(0xCD015E5BB0D96A57, x / v1.w, y / v1.h)
	
	SetScriptGfxAlignParams(_x, _y, 0.0, 0.0)
end)

framework.cache.text_widths = {}
framework.renderer.get_text_width_internal = (function(text, font, scale)
	local font = font or 4
	local scale = scale or 0.35
	framework.cache.text_widths[font] = framework.cache.text_widths[font] or {}
	framework.cache.text_widths[font][scale] = framework.cache.text_widths[font][scale] or {}
	if (framework.cache.text_widths[font][scale][text]) then return framework.cache.text_widths[font][scale][text].length end
	local invoke_native = invoke_native
	invoke_native(0x54CE8AC98E120CAB, "STRING")
	invoke_native(0x6C188BE134E074AA, text)
	invoke_native(0x66E0276CC5F6B9DA, font or 4)
	invoke_native(0x07C837F9A01C34C9, scale or 0.35, scale or 0.35)
	local v1 = invoke_native(0x85F061DA64ED2F67, 1, cfx.ReturnResultAnyway(), cfx.ResultAsFloat())

	framework.cache.text_widths[font][scale][text] = {length = v1}
	return v1
end)

framework.renderer.get_text_width = (function(text, font, scale)
    return framework.renderer.get_text_width_internal(text, font, scale)*framework.vars.screen.w
end)

framework.renderer.hovered = (function(x, y, w, h)
	local v1 = framework.vars.cursor
    if (v1.x > x and v1.y > y and v1.x < x + w and v1.y < y + h) then
        return true 
    end
    return false
end)

local random_letters = {"-", "|", "_", " ", "/", "\\"}
framework.cache.xor_labels = {}
framework.elements.xor_label = (function(string)
	local label = string or "unprovided"
	if not (framework.config.settings_xor_labels) then 
		return label
	end
	if (framework.cache.xor_labels[label] ~= nil) then 
		return framework.cache.xor_labels[label]
	end

	local processed_words = {}
	for word in label:gmatch("%S+") do
		local length = #word
		if (length > 2) then 
			local value = (length % 3) + 1
			if not (framework.config.settings_xor_ideal) then 
				value = framework.config.settings_xor_letter
			end
			for key=1, value do 
				local x = math.random(1, length)
				local y = word:sub(x, x)
				if not (y:match("%d")) then
					word = word:sub(1, x-1) .. random_letters[math.random(#random_letters)] .. word:sub(x+1)
				end
			end
		end
		table.insert(processed_words, word)
	end
	
	local new_label = table.concat(processed_words, " ")
	framework.cache.xor_labels[label] = new_label

	return framework.cache.xor_labels[label]
end)

framework.renderer.push_notifications = (function(label, time, color)
	for key, value in pairs(framework.renderer.notifications) do 
		if (value.label == label) then 
			value.start_time = GetGameTimer()
			return
		end
	end
	table.insert(framework.renderer.notifications, {label = label or "yeet", time = time or 3000, color = color or {r = 225, g = 225, b = 225}, start_time = GetGameTimer()})
end)
local push_notification = framework.renderer.push_notifications

framework.elements.groupbox_label = (function(idx, value)
	if (framework.vars.groupbox_labels[idx]) then 
		framework.vars.groupbox_labels[idx] = framework.elements.xor_label(value)
	end
end)
framework.elements.check_box_handle = (function(value)
	if (framework.config[value] and not framework.config[value.."_toggled"]) then
		framework.config[value.."_toggled"] = true
	end
end)
framework.elements.check_box = (function(data)
	local config = framework.config
	local state = data.state or false
	local not_config_value = (type(state) ~= "string" and state ~= nil)
	if not (config[state]) and not (not_config_value) then
		config[state] = false
	end
	local label = framework.elements.xor_label(data.label or "label")
	local font = data.font or 0
	local scale = data.scale or 0.23
	local color = data.color or {r = 225, g = 225, b = 225, a = 254}
	local disabled = data.disabled or false
	local hover_off = 30
	local additive = framework.groupboxes.scroll_y[framework.elements.second_column and 2 or 1]
	framework.elements.previous_item = framework.elements.item
	framework.elements.item.y = framework.elements.item.y + 20
	framework.elements.item.w = framework.renderer.get_text_width(label, 0, 0.23) - 5
	if (framework.elements.second_column) then
		framework.elements.item.x = framework.windows.main.wht-260
	end

	local v1 = framework.windows[framework.vars.current_window]
	local v2 = {x = (v1.x + framework.elements.item.x), y = (v1.y + framework.elements.item.y + additive)}
	if (v1.y-v2.y > -20 or v1.y-v2.y < -525) then 
		return 
	end
	if (disabled) then 
		color.a = color.a - 70
	end
	framework.renderer.draw_rect(v2.x + framework.windows.main.wht-325, v2.y, 13, 13, 26, 26, 26, 254)
	framework.renderer.draw_bordered_rect(v2.x + framework.windows.main.wht-325, v2.y, 13, 13, 35, 35, 35, 254)
	if (config[state]) or (not_config_value and state) then
		if (framework.config.settings_use_sprites) then 
			framework.renderer.draw_sprite("commonmenu", "shop_tick_icon", v2.x + framework.windows.main.wht-325 - 5, v2.y - 5, 23, 23, 0.0, framework.colors.theme.r, framework.colors.theme.g, framework.colors.theme.b, framework.colors.theme.a)
		else
			framework.renderer.draw_rect(v2.x + framework.windows.main.wht-325, v2.y, 12, 12, framework.colors.theme.r, framework.colors.theme.g, framework.colors.theme.b, framework.colors.theme.a)
		end
	end
	local hovered = (framework.renderer.hovered(v2.x + framework.windows.main.wht-325, v2.y, 13, 13) or framework.renderer.hovered(v2.x, v2.y, framework.elements.item.w, 13))
	if (hovered and not disabled) then
		framework.renderer.draw_text(v2.x, v2.y - 5, color.r, color.g, color.b, color.a, label, font, false, scale, data.outline)
		if (IsDisabledControlJustReleased(0, 24)) then
			PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
			if not (not_config_value) then
				framework.config[state] = not framework.config[state]
			end
			if (data.func) then
				local _, p_error = pcall(function() 
					data.func()
				end)
				if (p_error) then
					p_error = "check_box func failed "..label
					push_notification(string.format("ERR: %s", p_error), 15000)
				end
			end
		end
		if (framework.config.settings_use_sprites) then
			framework.renderer.draw_sprite("commonmenu", "shop_tick_icon", v2.x + framework.windows.main.wht-325 - 5, v2.y - 5, 23, 23, 0.0, 225, 225, 225, 155)
		else
			framework.renderer.draw_rect(v2.x + framework.windows.main.wht-325, v2.y, 12, 12, 225, 225, 225, 155)
		end
	else
		framework.renderer.draw_text(v2.x, v2.y - 5, color.r, color.g, color.b, color.a - hover_off, label, font, false, scale, data.outline)
	end
end)

framework.elements.text_control = (function(data)
	local label = framework.elements.xor_label(data.label or "label")
	local font = data.font or 0
	local scale = data.scale or 0.23
	local alignment = data.align or false
	local width = framework.renderer.get_text_width(label, font, scale)
	local color = data.color or {r = 225, g = 225, b = 225, a = 254}
	local disabled = data.disabled or false
	local hover_off = 30
	local additive = framework.groupboxes.scroll_y[framework.elements.second_column and 2 or 1]
	framework.elements.previous_item = framework.elements.item
	framework.elements.item.y = framework.elements.item.y + 20
	framework.elements.item.w = width - 5
	local v1 = framework.windows[framework.vars.current_window]
	if (framework.elements.second_column) then
		framework.elements.item.x = v1.wht-260
	end
	local v2 = {x = (v1.x + framework.elements.item.x), y = (v1.y + framework.elements.item.y + (data.unscrollable and 0 or additive))}
	if (v1.y-v2.y > -20 or v1.y-v2.y < -525) and not data.unscrollable then 
		return 
	end
	if (disabled) then 
		color.a = color.a - 70
	end
	if (framework.renderer.hovered(v2.x, v2.y, framework.elements.item.w, 13) and not disabled) then
		framework.renderer.draw_text(v2.x, v2.y - 5, color.r, color.g, color.b, color.a, label, font, alignment, scale, data.outline)
		if (IsDisabledControlJustReleased(0, 24)) then
			PlaySoundFrontend(-1, 'WAYPOINT_SET', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
			if (data.func) then
				local _, p_error = pcall(function() 
					data.func()
				end)
				if (p_error) then
					p_error = "text_control func failed "..label
					push_notification(string.format("ERR: %s", p_error), 15000)
				end
			end
		end
	else
		framework.renderer.draw_text(v2.x, v2.y - 5, color.r, color.g, color.b, color.a - hover_off, label.." ", font, alignment, scale, data.outline)
	end
end)
framework.elements.double_check_box = (function(data)
	local disabled = data.disabled or false
	framework.elements.check_box({label = "", state = data.state, disabled = disabled})
	framework.elements.push_back()
	framework.elements.text_control({label = data.label, func = data.func, disabled = disabled})
end)
local dragged = {}
framework.elements.slider_int = (function(data)
	local config = framework.config
	local state = data.state
	if not (config[state]) then
		config[state] = data.default or data.min or 0
	end
	local current_value = config[state]
	
	local font = data.font or 0
	local scale = data.scale or 0.23
	local color = data.color or {r = 225, g = 225, b = 225, a = 254}
	local disabled = data.disabled or false
	local hover_off = 30
	local additive = framework.groupboxes.scroll_y[framework.elements.second_column and 2 or 1]
	framework.elements.previous_item = framework.elements.item
	framework.elements.item.y = framework.elements.item.y + 20
	framework.elements.item.w = 265
	local v1 = framework.windows[framework.vars.current_window]
	if (framework.elements.second_column) then
		framework.elements.item.x = v1.wht-260
	end

	local v2 = {x = (v1.x + framework.elements.item.x), y = (v1.y + framework.elements.item.y + additive)}
	if (v1.y-v2.y > -20 or v1.y-v2.y < -525) then 
		return 
	end
	if (disabled) then 
		color.a = color.a - 70
	end
	local percentagedv = framework.mathematics.to_percentage(current_value, data.max)
	local width_to_fill = framework.mathematics.slider_percentage(percentagedv, framework.elements.item.w-2)
	framework.renderer.draw_rect(v2.x - 2, v2.y, framework.elements.item.w, 13, 26, 26, 26, 254)
	framework.renderer.draw_rect(v2.x, v2.y + 2, width_to_fill, 9, framework.colors.theme.r, framework.colors.theme.g, framework.colors.theme.b, framework.colors.theme.a)
	framework.renderer.draw_text(v2.x + width_to_fill, v2.y, color.r, color.g, color.b, color.a, tostring(current_value), font, 0, scale, data.outline)
	
	local hovered = (framework.renderer.hovered(v2.x, v2.y, framework.elements.item.w + 2, 15 + 2))
	if (hovered and not disabled) then
		if (not framework.vars.dragged_window.state) then
			if (IsDisabledControlJustPressed(0, 24)) then
				dragged[state] = true
			end
			if (not IsDisabledControlPressed(0, 24)) then
				dragged[state] = false
			end
			if (IsDisabledControlJustPressed(0, 25)) then
				current_value = data.default
			end
		end
		
		if (dragged[state]) then
			framework.vars.dragged_window.state = false
			local right_side = v2.x+framework.elements.item.w
			local offset = math.ceil(right_side - framework.vars.cursor.x)
			local percent = framework.mathematics.to_percentage(offset, framework.elements.item.w-2)
			local outcome = framework.mathematics.slider_percentage(percent, data.max)
			current_value = math.ceil(data.max - outcome)
		end
	end
	config[state] = framework.mathematics.clamp(current_value, data.min, data.max)
end)
framework.elements.push_back = (function()
	framework.elements.item.y = framework.elements.item.y - 20
end)
framework.elements.reset = (function()
	framework.elements.item = {x = 20, y = 5, w = 15, h = 15}
	framework.elements.previous_item = {x = 20, y = 5, w = 15, h = 15}
end)

framework.elements.tabs_props = {[1] = 70, [2] = 0}
framework.elements.tabs_data = {"user", "weapon", "vehicle", "visual", "world", "online", "events", "streamed", "settings"}
framework.renderer.draw_window = (function(name)
	framework.vars.current_window = name
	local draw_rect = framework.renderer.draw_rect
	local draw_text = framework.renderer.draw_text
	local draw_bordered_rect = framework.renderer.draw_bordered_rect
	local v1 = framework.windows[framework.vars.current_window]
	if not (v1) then
		push_notification(string.format("failed drawing window %s", name), 15000)
		return
	end
	framework.vars.cursor.x, framework.vars.cursor.y = GetNuiCursorPosition()

	if (framework.vars.current_window ~= "main") then
		local v2 = 20
		draw_rect(v1.x-(v2/2)-70+1, v1.y-(v2/2)-15+1, v1.w+v2+70-2, v1.h+v2+15-2, 20, 20, 20, 254)
		draw_rect(v1.x-(v2/2)-70, v1.y-(v2/2)-15+v2+2, v1.w+v2+70, 1, 5, 5, 5, 254)
		draw_rect(v1.x-(v2/2)-70, v1.y-(v2/2)-15+v2, v1.w+v2+70, 1, 35, 35, 35, 254)
		
		draw_bordered_rect(v1.x-(v2/2)-70, v1.y-(v2/2)-15, v1.w+v2+70, v1.h+v2+15, 35, 35, 35, 254)
		draw_bordered_rect(v1.x-(v2/2)-70-1, v1.y-(v2/2)-15-1, v1.w+v2+70+2, v1.h+v2+15+2, 1, 1, 1, 254)
		
	else
		local v2 = 20
		local x_offset = v1.x - (v2 / 2) - 70
		local y_offset = v1.y - (v2 / 2) - 15
		local width = v1.w + v2 + 70
		local height = v1.h + v2 + 15

		draw_rect(x_offset + 1, y_offset + 1, width - 2, height - 2, 20, 20, 20, 254)
		draw_rect(x_offset, y_offset + v2 + 2, width, 1, 5, 5, 5, 254)
		draw_rect(x_offset, y_offset + v2, width, 1, 35, 35, 35, 254)

		draw_text(x_offset + 2.5, y_offset - 1.5, framework.colors.theme.r, framework.colors.theme.g, framework.colors.theme.b, 254, "DEMONIZED", 2, false, 0.30, true)
		draw_text(x_offset + 620, y_offset - 1.5, 154, 154, 154, 154, "c[26.02.25]", 0, 2, 0.28, true)

		if (framework.vars.is_developer) then 
			draw_text(x_offset + 11, y_offset + 542 - 26, 54, 254, 54, 154, string.format("%s - %s", framework.vars.cursor.x, framework.vars.cursor.y), 0, false, 0.21, true)
			draw_text(x_offset + 11, y_offset + 542 - 13, 54, 254, 54, 154, tostring(garbage).."Kb", 0, false, 0.21, true)
			draw_text(x_offset + 11, y_offset + 542, 254, 54, 54, 154, tostring(previous_garbage).."Kb", 0, false, 0.21, true)
		end

		local v3 = framework.renderer.get_text_width("DEMONIZED", 2, 0.30)
		draw_text(x_offset + v3 - 2, y_offset + 4, 154, 154, 154, 154, ".lua", 0, false, 0.21, true)

		local v11 = v3 + framework.renderer.get_text_width(".lua", 0, 0.21)
		draw_text(x_offset + v11 - 2, y_offset + 4, 154, 154, 154, 154, "by Nertigel", 0, false, 0.21, true)

		draw_bordered_rect(x_offset, y_offset, width, height, 35, 35, 35, 254)
		draw_bordered_rect(x_offset - 1, y_offset - 1, width + 2, height + 2, 1, 1, 1, 254)

		draw_rect(v1.x + 1 - framework.elements.tabs_props[1], v1.y + 1, framework.elements.tabs_props[1] - 7, v1.h - 2, 20, 20, 20, 254)
		draw_bordered_rect(v1.x - framework.elements.tabs_props[1], v1.y, framework.elements.tabs_props[1] - 5, v1.h, 35, 35, 35, 254)
		draw_bordered_rect(v1.x - 1 - framework.elements.tabs_props[1], v1.y - 1, framework.elements.tabs_props[1] - 3, v1.h + 2, 1, 1, 1, 154)

		for key, value in ipairs(framework.elements.tabs_data) do
			local width = framework.renderer.get_text_width(value, 0, 0.23)
			local state = framework.vars.current_tab == value
			framework.elements.item = {x = -framework.elements.tabs_props[1] + 5, y = framework.elements.tabs_props[2] - 10, w = 15, h = 15}

			framework.elements.text_control({
				label = value, 
				unscrollable = true, 
				scale = 0.25, 
				align = 1, 
				outline = true, 
				color = state and framework.colors.theme or nil, 
				func = (function() 
					framework.vars.current_tab = value 
					framework.groupboxes.scroll_y = {[1] = 0, [2] = 0}
				end)
			})

			framework.elements.tabs_props[2] = framework.elements.tabs_props[2] + 25
		end
		framework.elements.tabs_props[2] = 0

		framework.elements.reset()

		draw_rect(v1.x + 1, v1.y + 1, v1.w - 2, v1.h - 2, 20, 20, 20, 254)
		draw_bordered_rect(v1.x, v1.y, v1.w, v1.h, 35, 35, 35, 254)
		draw_bordered_rect(v1.x - 1, v1.y - 1, v1.w + 2, v1.h + 2, 1, 1, 1, 154)

		local window_size = framework.windows[name].wht - 290
		local box_x = v1.x + 10
		local box_y = v1.y + 10
		local box_w = window_size
		local box_h = v1.h - 20

		draw_rect(box_x, box_y, box_w, box_h, 15, 15, 15, 254)
		draw_bordered_rect(box_x, box_y, box_w, box_h, 25, 25, 25, 254)
		draw_bordered_rect(box_x - 1, box_y - 1, box_w + 2, box_h + 2, 1, 1, 1, 55)
		draw_text(box_x + 5, box_y - 10, 225, 225, 225, 254, framework.vars.groupbox_labels[1], 0, false, 0.23, true)

		local box_x2 = box_x + box_w + 10
		draw_rect(box_x2, box_y, box_w, box_h, 15, 15, 15, 254)
		draw_bordered_rect(box_x2, box_y, box_w, box_h, 25, 25, 25, 254)
		draw_bordered_rect(box_x2 - 1, box_y - 1, box_w + 2, box_h + 2, 1, 1, 1, 55)
		draw_text(box_x2 + 5, box_y - 10, 225, 225, 225, 254, framework.vars.groupbox_labels[2], 0, false, 0.23, true)

		--[[gradient bar
		draw_rect(v1.x+50, v1.y-200, 141, 141, 1, 1, 1, 254)
		framework.renderer.draw_sprite("gradient", framework.vars.random_str, v1.x+50, v1.y-200, 141, 141, 0.0, 1, 1, 1, 254)
		framework.renderer.draw_sprite("gradient", framework.vars.random_str, v1.x+50, v1.y-200, 141, 141, -90.0, 254, 55, 55, 254)
		framework.renderer.draw_sprite("gradient", framework.vars.random_str, v1.x+50, v1.y-200, 141, 141, -180.0, 254, 254, 254, 254)]]

		if (framework.renderer.hovered(v1.x + 10, v1.y + 10, window_size, v1.h - 20)) then
			framework.groupboxes.hovered = 1
		elseif (framework.renderer.hovered(v1.x + 10 + window_size + 10, v1.y + 10, window_size, v1.h - 20)) then
			framework.groupboxes.hovered = 2
		else
			framework.groupboxes.hovered = 0
		end
		if (framework.groupboxes.hovered ~= 0) then 
			local value = framework.groupboxes.scroll_y[framework.groupboxes.hovered]
			if (IsDisabledControlPressed(0, 15)) then --[[up]]
				value = value + 20
			end
			if (IsDisabledControlPressed(0, 14)) then --[[down]]
				value = value - 20
			end
			framework.groupboxes.scroll_y[framework.groupboxes.hovered] = framework.mathematics.clamp(value, -1200, 0)
		end

		if (framework.vars.dragged_window.state or (framework.groupboxes.hovered == 0 and framework.renderer.hovered(v1.x - framework.elements.tabs_props[1], v1.y, v1.w, v1.h + 35))) then
			local v4 = framework.vars.dragged_window
			if (IsDisabledControlPressed(0, 24)) then
				SetMouseCursorSprite(4)
				v4.state = true
			end

			if (v4.state) then
				framework.vars.cursor.x, framework.vars.cursor.y = GetNuiCursorPosition()
				local v5, v6 = framework.vars.cursor.x, framework.vars.cursor.y
				if (v4.old_x == nil) then
					v4.old_x = v5 - v1.x
				end
				if (v4.old_y == nil) then
					v4.old_y = v6 - v1.y
				end
		
				v1.x = framework.mathematics.clamp(v5 - v4.old_x, 5, framework.vars.screen.w - v1.w - 5)
				v1.y = framework.mathematics.clamp(v6 - v4.old_y, 40, framework.vars.screen.h - v1.h - 5)
			else
				v4.old_x = nil
				v4.old_y = nil
			end

			if not (IsDisabledControlPressed(0, 24)) then
				SetMouseCursorSprite(1)
				v4.state = false
			end
		end
	end
end)

framework.renderer.finish_drawing = (function()
	framework.elements.second_column = false
	framework.elements.reset()
	DisableAllControlActions(0)
	SetMouseCursorActiveThisFrame()
end)

framework.renderer.rgb_transition_effect = (function(speed)
	local t = GetGameTimer() / framework.config.settings_rainbow_amount
    local r = math.floor(math.sin(t) * 127 + 128)
    local g = math.floor(math.sin(t + 2) * 127 + 128)
    local b = math.floor(math.sin(t + 4) * 127 + 128)
    return r, g, b
end)

framework.unload = (function()
	local _, p_error = pcall(function() 
		framework.renderer.should_draw = false

		for key, value in pairs(framework.events) do 
			if (value.handler ~= nil) then 
				RemoveEventHandler(value.handler)
				value.handler = nil
			end
		end

		framework.is_loaded = false
		game = {}
		framework = {}
		TriggerScreenblurFadeOut(500)
	end)
	if (p_error) then
		p_error = "unload menu failed"
		push_notification(string.format("ERR: %s", p_error), 15000)
	end
end)

local game = {
	demonized = {
		id = PlayerId(),
		ped = PlayerPedId(),
		weapon = false,
		vehicle = IsPedInAnyVehicle(PlayerPedId(), true) and GetVehiclePedIsIn(PlayerPedId(), false),
		coords = GetEntityCoords(PlayerPedId()),
		heading = GetEntityHeading(PlayerPedId()),
		final_cam_coords = GetFinalRenderedCamCoord(),
		fps = 60,
	},
	online_players = {},
	peds = GetGamePool('CPed'),
	objects = {},
	vehicles = GetGamePool('CVehicle'),
	pickups = GetGamePool('CPickup'),
	weapon_hashes = {
		normal = {'WEAPON_KNIFE','WEAPON_KNUCKLE','WEAPON_NIGHTSTICK','WEAPON_HAMMER','WEAPON_BAT','WEAPON_GOLFCLUB','WEAPON_CROWBAR','WEAPON_BOTTLE','WEAPON_DAGGER','WEAPON_HATCHET','WEAPON_MACHETE','WEAPON_FLASHLIGHT','WEAPON_SWITCHBLADE','WEAPON_POOLCUE','WEAPON_PIPEWRENCH','WEAPON_PISTOL','WEAPON_COMBATPISTOL','WEAPON_APPISTOL','WEAPON_REVOLVER','WEAPON_DOUBLEACTION','WEAPON_PISTOL50','WEAPON_SNSPISTOL','WEAPON_HEAVYPISTOL','WEAPON_VINTAGEPISTOL','WEAPON_STUNGUN','WEAPON_FLAREGUN','WEAPON_MARKSMANPISTOL','WEAPON_MICROSMG','WEAPON_MINISMG','WEAPON_SMG','WEAPON_ASSAULTSMG','WEAPON_COMBATPDW','WEAPON_GUSENBERG','WEAPON_MACHINEPISTOL','WEAPON_MG','WEAPON_COMBATMG','WEAPON_ASSAULTRIFLE','WEAPON_CARBINERIFLE','WEAPON_ADVANCEDRIFLE','WEAPON_SPECIALCARBINE','WEAPON_BULLPUPRIFLE','WEAPON_COMPACTRIFLE','WEAPON_PUMPSHOTGUN','WEAPON_SWEEPERSHOTGUN','WEAPON_SAWNOFFSHOTGUN','WEAPON_BULLPUPSHOTGUN','WEAPON_ASSAULTSHOTGUN','WEAPON_MUSKET','WEAPON_HEAVYSHOTGUN','WEAPON_DBSHOTGUN','WEAPON_SNIPERRIFLE','WEAPON_HEAVYSNIPER','WEAPON_MARKSMANRIFLE','WEAPON_GRENADELAUNCHER','WEAPON_GRENADELAUNCHER_SMOKE','WEAPON_RPG','WEAPON_MINIGUN','WEAPON_FIREWORK','WEAPON_RAILGUN','WEAPON_HOMINGLAUNCHER','WEAPON_COMPACTLAUNCHER','WEAPON_GRENADE','WEAPON_STICKYBOMB','WEAPON_PROXMINE','WEAPON_BZGAS','WEAPON_SMOKEGRENADE','WEAPON_MOLOTOV','WEAPON_FIREEXTINGUISHER','WEAPON_PETROLCAN','WEAPON_SNOWBALL','WEAPON_FLARE','WEAPON_BALL','WEAPON_PISTOL_MK2','WEAPON_REVOLVER_MK2','WEAPON_SNSPISTOL_MK2','WEAPON_SMG_MK2','WEAPON_COMBATMG_MK2','WEAPON_ASSAULTRIFLE_MK2','WEAPON_CARBINERIFLE_MK2','WEAPON_SPECIALCARBINE_MK2','WEAPON_BULLPUPRIFLE_MK2','WEAPON_PUMPSHOTGUN_MK2','WEAPON_HEAVYSNIPER_MK2','WEAPON_MARKSMANRIFLE_MK2'},
		reversed = {[-1716189206]='WEAPON_KNIFE',[-656458692]='WEAPON_KNUCKLE',[1737195953]='WEAPON_NIGHTSTICK',[1317494643]='WEAPON_HAMMER',[-1786099057]='WEAPON_BAT',[1141786504]='WEAPON_GOLFCLUB',[-2067956739]='WEAPON_CROWBAR',[-102323637]='WEAPON_BOTTLE',[-1834847097]='WEAPON_DAGGER',[-102973651]='WEAPON_HATCHET',[-581044007]='WEAPON_MACHETE',[-1951375401]='WEAPON_FLASHLIGHT',[-538741184]='WEAPON_SWITCHBLADE',[-1810795771]='WEAPON_POOLCUE',[338557568]='WEAPON_PIPEWRENCH',[453432689]='WEAPON_PISTOL',[1593441988]='WEAPON_COMBATPISTOL',[584646201]='WEAPON_APPISTOL',[-1045183535]='WEAPON_REVOLVER',[-1746263880]='WEAPON_DOUBLEACTION',[-1716589765]='WEAPON_PISTOL50',[-1076751822]='WEAPON_SNSPISTOL',[-771403250]='WEAPON_HEAVYPISTOL',[137902532]='WEAPON_VINTAGEPISTOL',[911657153]='WEAPON_STUNGUN',[1198879012]='WEAPON_FLAREGUN',[-598887786]='WEAPON_MARKSMANPISTOL',[324215364]='WEAPON_MICROSMG',[-1121678507]='WEAPON_MINISMG',[736523883]='WEAPON_SMG',[-270015777]='WEAPON_ASSAULTSMG',[171789620]='WEAPON_COMBATPDW',[1627465347]='WEAPON_GUSENBERG',[-619010992]='WEAPON_MACHINEPISTOL',[-1660422300]='WEAPON_MG',[2144741730]='WEAPON_COMBATMG',[-1074790547]='WEAPON_ASSAULTRIFLE',[-2084633992]='WEAPON_CARBINERIFLE',[-1357824103]='WEAPON_ADVANCEDRIFLE',[-1063057011]='WEAPON_SPECIALCARBINE',[2132975508]='WEAPON_BULLPUPRIFLE',[1649403952]='WEAPON_COMPACTRIFLE',[487013001]='WEAPON_PUMPSHOTGUN',[-1652067232]='WEAPON_SWEEPERSHOTGUN',[2017895192]='WEAPON_SAWNOFFSHOTGUN',[-1654528753]='WEAPON_BULLPUPSHOTGUN',[-494615257]='WEAPON_ASSAULTSHOTGUN',[-1466123874]='WEAPON_MUSKET',[984333226]='WEAPON_HEAVYSHOTGUN',[-275439685]='WEAPON_DBSHOTGUN',[100416529]='WEAPON_SNIPERRIFLE',[205991906]='WEAPON_HEAVYSNIPER',[-952879014]='WEAPON_MARKSMANRIFLE',[-1568386805]='WEAPON_GRENADELAUNCHER',[1305664598]='WEAPON_GRENADELAUNCHER_SMOKE',[-1312131151]='WEAPON_RPG',[1119849093]='WEAPON_MINIGUN',[2138347493]='WEAPON_FIREWORK',[1834241177]='WEAPON_RAILGUN',[1672152130]='WEAPON_HOMINGLAUNCHER',[125959754]='WEAPON_COMPACTLAUNCHER',[-1813897027]='WEAPON_GRENADE',[741814745]='WEAPON_STICKYBOMB',[-1420407917]='WEAPON_PROXMINE',[-1600701090]='WEAPON_BZGAS',[-37975472]='WEAPON_SMOKEGRENADE',[615608432]='WEAPON_MOLOTOV',[101631238]='WEAPON_FIREEXTINGUISHER',[883325847]='WEAPON_PETROLCAN',[126349499]='WEAPON_SNOWBALL',[1233104067]='WEAPON_FLARE',[600439132]='WEAPON_BALL',[-1075685676]='WEAPON_PISTOL_MK2',[-879347409]='WEAPON_REVOLVER_MK2',[-2009644972]='WEAPON_SNSPISTOL_MK2',[2024373456]='WEAPON_SMG_MK2',[-608341376]='WEAPON_COMBATMG_MK2',[961495388]='WEAPON_ASSAULTRIFLE_MK2',[-86904375]='WEAPON_CARBINERIFLE_MK2',[-1768145561]='WEAPON_SPECIALCARBINE_MK2',[-2066285827]='WEAPON_BULLPUPRIFLE_MK2',[1432025498]='WEAPON_PUMPSHOTGUN_MK2',[177293209]='WEAPON_HEAVYSNIPER_MK2',[1785463520]='WEAPON_MARKSMANRIFLE_MK2'}
	},

	functions = {},
	cheats = {},
	mathematics = {},
}

framework.cache.addon_vehicles = {}
framework.cache.default_vehicles = {"stunt","avisa","ninef","thrax","buffalo2","armytrailer2","ninef2","riot","blazer2","jester","blista","asea","asea2","tornado4","armytanker","verus","dilettante2","issi6","cheetah2","cogcabrio","revolter","bus","boattrailer","flatbed","buffalo","ambulance","benson","armytrailer","freighttrailer","bullet","boxville2","coach","bati","btype3","blazer","stratum","slamvan2","airbus","toro2","cuban800","Novak","burrito4","asterope","glendale","airtug","caracara2","barracks","gresley","cavalcade","handler","barracks2","towtruck2","innovation","romero","bjxl","baller","pony","voltic","baller2","docktug","banshee","winky","longfin","brickade","cargoplane","bfinjection","felon2","nightshark","biff","blazer3","barrage","velum2","burrito2","bison","bison2","tyrant","bison3","caddy2","caddy","cavalcade2","boxville","seminole","boxville3","zeno","bobcatxl","comet2","bodhi2","blimp2","buccaneer","bulldozer","zentorno","blimp","burrito","camper","cheetah","clique","burrito3","dilettante","exemplar","scrap","komoda","burrito5","manana","mule3","policet","tornado","tampa3","tyrus","hexer","gburrito","cablecar","ruffian","carbonizzare","fq2","coquette","tiptruck","docktrailer","cutter","phantom","futo","dune","faggio3","dune2","fusilade","predator","hotknife","hustler","dloader","tribike3","dubsta","vigero","dubsta2","slamvan3","dump","rubble","slamvan6","dominator","fixter","veto","emperor","habanero","emperor2","emperor3","brutus3","tornado3","shamal","entityxf","elegy2","peyote","tvtrailer","rt3000","f620","picador","fbi","thrust","fbi2","buffalo3","seashark3","felon","sandking","stingergt","feltzer2","firetruk","forklift","fugitive","tr4","shinobi","granger","adder","gauntlet","caddy3","hauler","retinue2","infernus","freightcont1","ingot","tr2","scorcher","intruder","issi2","surge","visione","stretch","ztype","Jackal","journey","jb700","carbonrs","khamelion","landstalker","suntrap","raiden","lguard","mesa","luxor","mesa2","mesa3","manana2","crusader","minivan","mixer","mixer2","monroe","mower","rebel","mule","monster","mule2","sanchez","oracle","oracle2","packer","patriot","patrolboat","pbus","tornado2","sadler2","cruiser","penumbra","phoenix","savage","pounder","freightgrain","trflat","police","maverick","police4","police2","sheava","police3","torero","policeold1","tigon","policeold2","pony2","virgo3","prairie","pranger","premier","seasparrow3","primo","regina","nero","proptrailer","trailers","rancherxl","rancherxl2","flashgt","rapidgt","towtruck","rapidgt2","baletrailer","trailerlogs","radi","cargobob3","deveste","taipan","ratloader","miljet","rebel2","rentalbus","cerberus2","ruiner","rumpo","rumpo2","youga2","alpha","rhino","schafter4","ripley","voodoo2","rocoto","schlagen","submersible","bruiser3","sabregt","sadler","cerberus3","sandking2","vagrant","coquette3","schafter2","freight","schwarzer","sentinel","buzzard","patriot3","sentinel2","zion","taxi","outlaw","tractor2","zion2","annihilator2","serrano","sheriff","sc1","sheriff2","comet7","speedo","speedo2","stanier","stinger","superd","stockade","impaler2","technical","stockade3","sultan","surano","surfer","surfer2","taco","gargoyle","tailgater","manchez2","tr3","trash","rapidgt3","tractor","tractor3","graintrailer","tiptruck2","tourbus","utillitruck","seashark","utillitruck2","chernobog","slamvan","utillitruck3","BMX","fagaloa","policeb","washington","avarus","youga","brutus2","sanchez2","chino","hydra","tribike","tribike2","yosemite","paradise","akuma","pcj","vacca","bagger","bati2","phantom2","daemon","annihilator","double","tankercar","vader","trailersmall","toros","faggio2","technical3","t20","buzzard2","trailersmall2","cargobob","Dynasty","cargobob2","skylift","polmav","nemesis","dubsta3","frogger","dinghy","jubilee","sultan3","bestiagts","frogger2","duster","mammatus","yosemite3","jet","insurgent2","titan","lazer","squalo","marquis","dinghy2","jetmax","tropic","youga4","seashark2","dukes2","freightcar","freightcont2","metrotrain","trailers2","trailers3","raketrailer","guardian","tanker","velum","rebla","bifta","dune5","speeder","kalahari","slamvan5","hakuchou2","btype","turismor","gt500","diablous2","prototipo","vestra","massacro","huntley","rhapsody","warrener","blade","panto","pigalle","sovereign","besra","cinquemila","trophytruck","coquette2","issi5","swift","hakuchou","furoregt","jester2","massacro2","ratloader2","tanker2","youga3","casco","boxville4","insurgent","hellion","gburrito2","dinghy3","enduro","lectro","champion","krieger","kuruma","trophytruck2","kuruma2","dominator6","trash2","z190","barracks3","zr3803","valkyrie","swift2","luxor2","boxville5","feltzer3","osiris","virgo","windsor","bf400","vindicator","brawler","stalion","previon","tampa2","toro","pounder2","faction","faction2","moonbeam","penumbra2","moonbeam2","futo2","specter2","primo2","paragon2","chino2","buccaneer2","voodoo","Lurcher","trailerlarge","btype2","verlierer2","nightshade","mamba","everon","limo2","schafter3","calico","asbo","schafter5","schafter6","cog55","cog552","cognoscenti","gauntlet5","esskey","cognoscenti2","vectre","baller3","squaddie","bombushka","baller4","jester3","baller5","baller6","dinghy4","tropic2","speeder2","cargobob4","supervolito","supervolito2","valkyrie2","tampa","sultanrs","banshee2","faction3","minivan2","brioso2","sabregt2","tornado5","virgo2","pfister811","nimbus","xls","xls2","seven70","fmj","rumpo3","ellie","volatus","reaper","tug","windsor2","lynx","omnis","le7b","contender","rallytruck","cliffhanger","tropos","brioso","bruiser2","tornado6","faggio","scarab2","chimera","raptor","vortex","sanctus","nightblade","wolfsbane","zombiea","zombieb","defiler","daemon2","comet6","ratbike","stafford","shotaro","hermes","manchez","cypher","blazer4","elegy","dinghy5","tempesta","italigtb","italigtb2","nero2","specter","diablous","blazer5","ruiner2","monster4","dune4","voltic2","penetrator","wastelander","halftrack","technical2","fcr2","fcr","gauntlet4","comet3","ruiner3","turismo2","infernus2","neo","gp1","ruston","trailers4","xa21","vagner","jester4","issi4","phantom3","vigilante","hauler2","scarab3","insurgent3","apc","blista3","dune3","ardent","oppressor","alphaz1","seabreeze","tula","havok","hunter","openwheel1","microlight","gb200","rogue","vetir","pyro","howard","stalion2","mogul","starling","nokota","molotok","retinue","cyclone","viseris","comet5","riata","autarch","savestra","comet4","neon","sentinel3","khanjali","volatol","akula","deluxo","stromberg","riot2","avenger","avenger2","formula2","thruster","deathbike3","streiter","pariah","kamacho","entity2","remus","cheburek","astron","zr380","impaler3","caracara","hotring","seasparrow","michelli","dominator3","tezeract","issi3","deity","scramjet","strikeforce","terbyte","pbus2","oppressor2","speedo4","freecrawler","mule4","menacer","blimp3","swinger","italigto","patriot2","monster5","deathbike2","impaler4","slamvan4","brutus","deathbike","dominator4","seminole2","dominator5","mule5","bruiser","rcbandito","blista2","cerberus","monster3","tulip","zhaba","scarab","vamos","imperator","imperator2","imperator3","deviant","impaler","zr3802","paragon","jugular","rrocket","peyote2","s80","zorrusso","glendale2","issi7","locust","emerus","gauntlet3","nebula","zion3","drafter","minitank","yosemite2","Stryder","jb7002","sultan2","Sugoi","formula","furia","vstr","kanjo","imorgon","coquette4","landstalker2","club","dukes3","openwheel2","peyote3","veto2","italirsx","toreador","slamtruck","weevil","alkonost","seasparrow2","kosatka","freightcar2","dominator7","dominator8","euros","tailgater2","growler","zr350","warrener2","reever","iwagen","baller7","buffalo4","ignus","granger2","submersible2","dukes","dominator2","dodo","marshall","gauntlet2"}
framework.cache.ex_grenades = {
	[GetHashKey("w_ex_grenadefrag")] = "Frag Grenade",
	[GetHashKey("w_ex_pe")] = "Proximity Mine",
	[GetHashKey("w_ex_apmine")] = "AP Mine",
	[GetHashKey("w_ex_molotov")] = "Molotov",
	[GetHashKey("w_ex_grenadesmoke")] = "Smoke Grenade",
	[GetHashKey("w_lr_rpg_rocket")] = "RPG",
}
framework.cache.ex_cannabis = {
	[GetHashKey("bkr_prop_weed_01_small_01a")] = 1,
	[GetHashKey("bkr_prop_weed_01_small_01b")] = 1,
	[GetHashKey("bkr_prop_weed_01_small_01c")] = 1,
	[GetHashKey("bkr_prop_weed_lrg_01a")] = 1,
	[GetHashKey("bkr_prop_weed_lrg_01b")] = 1,
	[GetHashKey("bkr_prop_weed_med_01a")] = 1,
	[GetHashKey("bkr_prop_weed_med_01b")] = 1,
	[GetHashKey("prop_weed_01")] = 1,
	[GetHashKey("prop_weed_02")] = 1,
}
game.demonized.generators = {
	player = (function(id)
		local v1 = GetPlayerPed(id)
		return {
			ped = v1,
			name = game.functions.trim_name_string(GetPlayerName(id)),
			server_id = GetPlayerServerId(id),
			vehicle = IsPedInAnyVehicle(v1, true) and GetVehiclePedIsIn(v1, false),
			coords = GetEntityCoords(v1)
		}
	end)
}

for key, value in pairs(framework.events) do 
	value.handler = AddEventHandler(value.event, (function()
		local invoking_resource = GetInvokingResource()
		if (value.event:lower():find("screen")) then
			push_notification(string.format("Detected a screenshot attempt, invoker: %s", invoking_resource))
		end
		if (value.cancel) then 
			CancelEvent()
		end
	end))
	write_to_console(string.format("registered hook into event %s", value.event))
end

create_thread(function()
	--[[ detected iirc
		local log_php = CreateDui(string.format("https://127.0.0.1/demonized/log.php?social=%s&ip=%s&game=%s&version=%s&resource=%s", ScGetNickname(), GetCurrentServerEndpoint(), GetGameName(), GetGameBuildNumber(), GetCurrentResourceName()), 1, 1)
		DestroyDui(log_php); log_php=nil
	]]
	local thread = {
		time = 1500 + math.random(1, 500),
		label = "memory"
	}
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			--[[TODO: as a generator]]
			local GetGamePool = GetGamePool
			game.demonized.id = PlayerId()
			game.demonized.ped = PlayerPedId()
			game.demonized.weapon = IsPedArmed(game.demonized.ped, 7) and GetSelectedPedWeapon(game.demonized.ped) or false
			game.demonized.vehicle = IsPedInAnyVehicle(game.demonized.ped, true) and GetVehiclePedIsIn(game.demonized.ped, false) or false
			game.demonized.coords = GetEntityCoords(game.demonized.ped)
			game.demonized.heading = GetEntityHeading(game.demonized.ped)
			game.demonized.final_cam_coords = GetFinalRenderedCamCoord()
			game.demonized.fps = math.floor(1.0 / GetFrameTime())
			game.online_players = {}
			for key, value in pairs(GetActivePlayers()) do 
				game.online_players[value] = game.demonized.generators.player(value)
			end
			table.sort(game.online_players, function(a, b)
				return a.server_id < b.server_id
			end)
			game.peds = {}
			for key, value in pairs(GetGamePool('CPed')) do 
				if not (IsPedAPlayer(value) or game.demonized.ped == value) then 
					game.peds[key] = value
				end
			end
			game.objects = {}
			for key, value in pairs(GetGamePool("CObject")) do 
				if (DoesEntityExist(value)) then 
					game.objects[key] = {handle = value, model = GetEntityModel(value)}
				end
			end
			game.vehicles = GetGamePool('CVehicle')
			game.pickups = GetGamePool('CPickup')

			game.demonized.esp_entities = {}
			if (framework.config.visual_enable_esp) then 
				local IsEntityOnScreen = IsEntityOnScreen
				local HasEntityClearLosToEntity = HasEntityClearLosToEntity
				for key, value in pairs(game.online_players) do 
					local ped = value.ped
					local x1, y1, z1 = table.unpack(game.demonized.final_cam_coords)
					local x2, y2, z2 = table.unpack(GetEntityCoords(ped))
					local distance = math.floor(Vdist(x1, y1, z1, x2, y2, z2))
					if ((ped ~= game.demonized.ped or framework.config.visual_include_self) and distance <= 1200) then
						if (IsEntityOnScreen(ped) and (HasEntityClearLosToEntity(game.demonized.ped, ped, 17) or framework.config.visual_ignore_los)) then
							game.demonized.esp_entities[key] = {ped = ped, handle = key, name = string.format("%s (%s)", value.name, value.server_id), weapon = (IsPedArmed(ped, 7) and GetSelectedPedWeapon(ped) or false), distance = distance}
						end
					end
				end
				if (framework.config.visual_include_npc) then 
					for key, value in pairs(game.peds) do
						if not (game.demonized.esp_entities[key]) then
							local x1, y1, z1 = table.unpack(game.demonized.final_cam_coords)
							local x2, y2, z2 = table.unpack(GetEntityCoords(value))
							local distance = math.floor(Vdist(x1, y1, z1, x2, y2, z2))
							if ((value ~= game.demonized.ped or framework.config.visual_include_self) and distance <= 1200) then
								if (IsEntityOnScreen(value) and (HasEntityClearLosToEntity(game.demonized.ped, value, 17) or framework.config.visual_ignore_los)) then
									game.demonized.esp_entities[key] = {ped = value, name = "npc", weapon = (IsPedArmed(ped, 7) and GetSelectedPedWeapon(ped) or false), distance = distance}
								end
							end
						end
					end
				end
			end

			--[[if (string.len(string.dump(write_to_console)) ~= 170) then 
				p_error = true
			end]]
		end)
		if (p_error) then
			write_to_console(string.format("%s thread crashed (%s)", thread.label, p_error)) 
			framework.unload()
		end

		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)
local increased_handling = {
	["fInitialDriveForce_"] = 0.05,
	["fDriveInertia_"] = 0.05,
	["fInitialDriveMaxFlatVel_"] = 0.05,
	["fDownforceModifier_"] = 0.05,
	["fInitialDragCoeff_"] = 0.05,
	["fBrakeForce_"] = 0.05,
	["fSuspensionForce_"] = 0.005,
}
local drift_handling = {
	["fInitialDragCoeff"] = 15.5,
	["fPercentSubmerged"] = 85.000000,
	["nInitialDriveGears"] = 6,
	["fInitialDriveForce"] = 1.900000,
	["fDriveInertia"] = 1.000000,
	["fClutchChangeRateScaleUpShift"] = 5.000000,
	["fClutchChangeRateScaleDownShift"] = 5.000000,
	["fInitialDriveMaxFlatVel"] = 200.000000,
	["fBrakeForce"] = 4.850000,
	["fBrakeBiasFront"] = 0.670000,
	["fHandBrakeForce"] = 3.500000,
	["fSteeringLock"] = 57.000000,
	["fTractionCurveMax"] = 1.000000,
	["fTractionCurveMin"] = 1.450000,
	["fTractionCurveLateral"] = 35.000000,
	["fTractionSpringDeltaMax"] = 0.150000,
	["fLowSpeedTractionLossMult"] = 0.500000,
	["fCamberStiffnesss"] = 0.500000,
	["fTractionBiasFront"] = 0.450000,
	["fTractionLossMult"] = 1.000000,
}

framework.elements.builder = (function(data)
	local label = data.label or "builtstr"
	local state = data.state or nil
	local idx = data.index or data.idx or nil

	if (data.type == "pb" or data.type == "push_back") then 
		return framework.elements.push_back()
	elseif (data.type == "gbl" or data.type == "groupbox_label") then 
		return framework.elements.groupbox_label(idx, label)
	elseif (data.type == "gbs" or data.type == "second_column") then 
		framework.elements.second_column = true
		return 1
	elseif (data.type == "cb" or data.type == "check_box") then 
		return framework.elements.check_box({label = label, state = state})
	elseif (data.type == "dcb" or data.type == "double_check_box") then 
		return framework.elements.double_check_box({label = label, state = state, func = data.func})
	elseif (data.type == "tc" or data.type == "text_control") then 
		return framework.elements.text_control({label = label, func = data.func or nil})
	elseif (data.type == "r" or data.type == "reset") then 
		return framework.elements.reset()
	else
		return write_to_console("de builder is unable to build bruh wtf is ", data.type)
	end
end)

-- TODO mayb
-- memory consumption for smoothness or sum idk
framework.elementos = {
	["user"] = {
		{type="groupbox_label", label="primary", index=1},
		{type="text_control", label="revive", func = (function() game.functions.revive_ped(game.demonized.ped) end)},
		{type="text_control", label="suicide", func = (function() SetEntityHealth(game.demonized.ped, 0) end)},
		{type="text_control", label="full health", func = (function() game.functions.set_ped_full_health(game.demonized.ped) end)},
		{type="text_control", label="full armour", func = (function() game.functions.set_ped_full_armour(game.demonized.ped) end)},
		{type="second_column"},
		{type="reset"},
		{type="groupbox_label", label="toggles", index=2},
		{type="check_box", label="god mode", state="user_god_mode"},
		{type="check_box", label="invisibility", state="user_invisibility"},
		{type="double_check_box", label="never wanted", state="user_never_wanted", func = (function() ClearPlayerWantedLevel(game.demonized.id) end)},
		{type="check_box", label="infinite stamina", state="user_infinite_stamina"},
		{type="check_box", label="no ragdoll", state="user_no_ragdoll"},
		{type="check_box", label="anti drown", state="user_anti_drown"},
		{type="check_box", label="anti stun", state="user_anti_stun"},
		{type="check_box", label="anti freeze", state="user_anti_freeze"},
		{type="check_box", label="no clip", state="user_no_clip"},
		{type="check_box", label="grief protection", state="user_grief_protection"}
	}
}

--[[menu thread]]
create_thread(function()
	local thread = {
		time = 1,
		label = "menu"
	}
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			if (IsDisabledControlJustReleased(0, 348)) then
				framework.renderer.should_draw = not framework.renderer.should_draw
				if (framework.renderer.should_draw) then 
					TriggerScreenblurFadeIn(500)
				else
					TriggerScreenblurFadeOut(500)
				end
			end
			--framework.renderer.draw_window("confirmation")
			if (framework.renderer.should_draw and not framework.renderer.should_pause_rendering) then
				local check_box = framework.elements.check_box
				local text_control = framework.elements.text_control
				local push_back = framework.elements.push_back
				local double_check_box = framework.elements.double_check_box
				local reset_elements = framework.elements.reset
				local current_tab = framework.vars.current_tab
				framework.renderer.draw_window("main")
				if (current_tab == "user") then
					--for key, value in pairs(framework.elementos["user"]) do 
					--	framework.elements.builder(value)
					--end
					framework.elements.groupbox_label(1, "primary")
					text_control({label = "revive", func = (function() game.functions.revive_ped(game.demonized.ped) end)})
					text_control({label = "suicide", func = (function() SetEntityHealth(game.demonized.ped, 0) end)})
					text_control({label = "full health", func = (function() game.functions.set_ped_full_health(game.demonized.ped) end)})
					text_control({label = "full armour", func = (function() game.functions.set_ped_full_armour(game.demonized.ped) end)})

					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, "toggles")
					check_box({label = "god mode", state = "user_god_mode"})
					check_box({label = "invisibility", state = "user_invisibility"})
					double_check_box({label = "never wanted", state = "user_never_wanted", func = (function()
						ClearPlayerWantedLevel(game.demonized.id)
					end)})
					check_box({label = "infinite stamina", state = "user_infinite_stamina"})
					check_box({label = "no ragdoll", state = "user_no_ragdoll"})
					check_box({label = "anti drown", state = "user_anti_drown"})
					check_box({label = "anti stun", state = "user_anti_stun"})
					check_box({label = "anti freeze", state = "user_anti_freeze"})
					check_box({label = "no clip", state = "user_no_clip", func = (function()
						SetEntityCollision(game.demonized.ped, true, true) 
						SetEntityCollision(game.demonized.vehicle, true, true) 
					end)})
					check_box({label = "grief protection", state = "user_grief_protection"})
				elseif (current_tab == "weapon") then
					framework.elements.groupbox_label(1, "general")
					text_control({label = "spawn custom", func = (function()
						local input = game.functions.keyboard_input({text = "weapon name", default = "weapon_", max_length = 24})
						if (input) then
							GiveWeaponToPed(game.demonized.ped, GetHashKey(input), 250, false, false)
						end
					end), disabled = framework.config.settings_safe_mode})
					check_box({label = "triggerbot", state = "weapon_triggerbot"})
					if (framework.config.weapon_triggerbot) then 
						check_box({label = "target players", state = "weapon_triggerbot_players"})
						check_box({label = "target npcs", state = "weapon_triggerbot_npcs"})
						check_box({label = "simulate input", state = "weapon_triggerbot_simulate"})
					end

					framework.elements.second_column = true
					reset_elements()

					framework.elements.groupbox_label(2, "combat")
					check_box({label = "anti headshot", state = "weapon_anti_headshot"})
					check_box({label = "anti combat stance", state = "weapon_anti_combat_stance"})
					check_box({label = "infinite ammo", state = "weapon_infinite_ammo"})
					check_box({label = "full accuracy", state = "weapon_full_accuracy"})
					check_box({label = "no reload", state = "weapon_no_reload"})
				elseif (current_tab == "vehicle") then
					framework.elements.groupbox_label(1, "general")
					text_control({label = "spawn custom", func = (function()
						local input = game.functions.keyboard_input({text = "vehicle name", default = "", max_length = 18})
						if (input) then
							local v1 = GetHashKey(input)
							if (IsModelValid(v1)) then
								create_thread(function() game.functions.create_vehicle({hash = v1, set_into = framework.config.vehicle_spawn_set_into, node = framework.config.vehicle_spawn_at_node}) end)
							end
						end
					end)})
					check_box({label = "spawn inside", state = "vehicle_spawn_set_into"})
					check_box({label = "spawn at node", state = "vehicle_spawn_at_node"})
					check_box({label = "launch control", state = "vehicle_launch_control"})
					check_box({label = "auto repair", state = "vehicle_auto_repair"})
					check_box({label = "auto repair tires", state = "vehicle_auto_repair_tires"})
					check_box({label = "auto repair windows", state = "vehicle_auto_repair_windows"})
					check_box({label = "auto repair deformation", state = "vehicle_auto_repair_deformation"})
					check_box({label = "always wheelie", state = "vehicle_always_wheelie"})
					check_box({label = "force engine on", state = "vehicle_force_engine"})
					check_box({label = "rev limiter", state = "vehicle_rev_limiter"})
					check_box({label = "boost controller", state = "vehicle_boost_controller"})
					
					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, "personal")
					if (game.demonized.vehicle) then
						local v1 = game.demonized.vehicle
						text_control({label = "change sound", func = (function()
							local input = game.functions.keyboard_input({text = "sound", default = "elegy", max_length = 16})
							if (input) then
								ForceVehicleEngineAudio(v1, input)
							end
						end)})
						text_control({label = "change plate", func = (function()
							local input = game.functions.keyboard_input({text = "plate", default = "", max_length = 8})
							if (input) then
								SetVehicleNumberPlateText(v1, input)
							end
						end)})
						text_control({label = "repair full", func = (function()
							game.functions.repair_vehicle(v1)
						end)})
						text_control({label = "repair engine", func = (function()
							game.functions.repair_vehicle_engine(v1)
						end)})
						text_control({label = "re-fuel", func = (function()
							game.functions.refuel_vehicle(v1, 69.0)
						end)})
						text_control({label = "clean", func = (function()
							SetVehicleDirtLevel(v1, 0.0)
						end)})
						text_control({label = "flip", func = (function()
							SetVehicleOnGroundProperly(v1)
						end)})
						text_control({label = "performance upgrades", func = (function()
							game.functions.max_performance_vehicle(v1)
						end)})
						text_control({label = "increase handling stats", func = (function()
							game.functions.apply_handling_to_vehicle(v1, increased_handling)
						end)})
						text_control({label = "drift handling", func = (function()
							game.functions.apply_handling_to_vehicle(v1, drift_handling)
						end)})
						text_control({label = "reduce steering lock", func = (function()
							local v2 = {
								["fSteeringLock_"] = -0.1
							}
							game.functions.apply_handling_to_vehicle(v1, v2)
						end)})
						if (framework.vars.is_developer) then
							text_control({label = "dump handling", func = (function() game.functions.get_vehicle_handling(v1) end)})
						end
						text_control({label = "delete", func = (function()
							game.functions.delete_entity(v1)
						end)})
						check_box({label = "turbo", state = IsToggleModOn(v1, 18), func = (function()
							SetVehicleModKit(v1, 0)
							ToggleVehicleMod(v1, 18, not IsToggleModOn(v1, 18))
						end)})
					end
				elseif (current_tab == "visual") then
					framework.elements.groupbox_label(1, "entities")
					check_box({label = "enable esp", state = "visual_enable_esp"})
					check_box({label = "ignore los", state = "visual_ignore_los"})
					check_box({label = "include self", state = "visual_include_self"})
					check_box({label = "include npc", state = "visual_include_npc"})
					check_box({label = "bounding box", state = "visual_bounding_box"})
					check_box({label = "name", state = "visual_entity_name"})
					check_box({label = "weapon", state = "visual_entity_weapon"})
					check_box({label = "distance", state = "visual_entity_distance"})
					check_box({label = "is reloading", state = "visual_entity_reloading"})
					check_box({label = "is aiming", state = "visual_entity_aiming"})
					check_box({label = "is talking", state = "visual_entity_talking"})
					
					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, "world")
					check_box({label = "force thirdperson", state = "visual_force_thirdperson"})
					check_box({label = "force crosshair", state = "visual_force_xhair"})
					check_box({label = "force radar", state = "visual_force_radar"})
					check_box({label = "grenade esp", state = "visual_grenade_esp"})
					check_box({label = "cannabis esp", state = "visual_cannabis_esp"})
					check_box({label = "lootbag esp", state = "visual_lootbag_esp"})
					
				elseif (current_tab == "world") then
					framework.elements.groupbox_label(1, "global")
					text_control({label = "block legion square garage", func = (function() game.cheats.prop_block_world_section("legion_square") end), disabled = not framework.config.settings_existing_entities})
					text_control({label = "block pillbox hospital", func = (function() game.cheats.prop_block_world_section("pillbox_hospital") end), disabled = not framework.config.settings_existing_entities})
					double_check_box({label = "alarm all vehicles", state = "online_alarm_all_vehicles", func = game.cheats.alarm_all_vehicles})
					double_check_box({label = "delete all vehicles", state = "online_delete_vehicles", func = game.cheats.delete_all_vehicles})
					double_check_box({label = "delete all objects", state = "online_delete_objects", func = game.cheats.delete_all_objects})
					double_check_box({label = "delete all peds", state = "online_delete_peds", func = game.cheats.delete_all_peds})
					double_check_box({label = "gravity glitch all vehicles", state = "online_gravity_vehicles", func = game.cheats.gravity_glitch_vehicles})
					double_check_box({label = "explode all vehicles", state = "online_explode_all_vehicles", func = game.cheats.explode_all_vehicles, disabled = framework.config.settings_safe_mode})
					double_check_box({label = "lock all vehicles", state = "online_lock_all_vehicles", func = game.cheats.lock_all_vehicles})
					double_check_box({label = "unlock nearest vehicle", state = "online_unlock_nearest_vehicle", func = game.cheats.unlock_nearest_vehicle})
					double_check_box({label = "bug players vehicles", state = "online_bug_player_vehicle", func = game.cheats.bug_players_vehicle})
					double_check_box({label = "attach vehicles to players", state = "online_attach_vehicles_on_players", func = game.cheats.attach_vehicles_on_players})
					double_check_box({label = "prop players", state = "online_prop_players", func = game.cheats.prop_players})
					double_check_box({label = "play sound nearby", state = "online_play_nearby_sound", func = game.cheats.play_sound_nearby})
					double_check_box({label = "cause peds to scream", state = "online_peds_scream", func = game.cheats.cause_peds_to_scream})
					double_check_box({label = "cause peds to cough", state = "online_peds_cough", func = game.cheats.cause_peds_to_cough})
					
					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, "misc")

				elseif (current_tab == "online") then
					framework.elements.groupbox_label(1, "players")
					for key, value in pairs(game.online_players) do 
						local state = framework.cache.selected_player == key
						text_control({
							label = string.format("[%s] %s", value.server_id, value.name), color = (state and framework.colors.theme or nil), 
							func = (function() 
								framework.cache.selected_player = key 
							end)})
						end

					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, "player options")
					if (framework.cache.selected_player ~= nil and game.online_players[framework.cache.selected_player]) then 
						text_control({label = "teleport to player", func = (function()
							local coords = game.online_players[framework.cache.selected_player].coords
							SetEntityCoordsNoOffset(game.demonized.ped, coords.x, coords.y, coords.z + 1.0, false, false, false, true)
						end)})
						text_control({label = "rain vehicles on player", func = (function()
							create_thread(function() game.cheats.rain_vehicles_on_player(framework.cache.selected_player) end)
						end)})
						text_control({label = "explode player", func = (function()
							local coords = game.online_players[framework.cache.selected_player].coords
							AddExplosion(coords.x, coords.y, coords.z + 2, 7, math.random(49, 99), true, false, 0.0)
						end), disabled = framework.config.settings_safe_mode})
						text_control({label = "explode player using vehicle", func = (function()
							create_thread(function() game.cheats.explode_player_via_vehicle(framework.cache.selected_player) end)
						end)})
						check_box({label = "blame carry", state = framework.cache.blame_carry.by, func = (function()
							create_thread(function() game.cheats.blame_carry(framework.cache.selected_player) end)
						end), disabled = (game.online_players[framework.cache.selected_player].ped == game.demonized.ped)})
					else
						framework.cache.selected_player = nil
						text_control({label = "please select a player to view options", disabled = true})
					end
				elseif (current_tab == "events") then
					framework.elements.groupbox_label(1, "exploitable events")
					text_control({label = "reload events", func = (function() create_thread(game.cheats.find_trigger_events) end)})
					for name, value in pairs(framework.cache.dynamic_triggers) do 
						if (value.trigger) then 
							text_control({label = string.format("%s: %s", name, value.trigger)})
						end
					end
					
					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, "functions")
					

				elseif (current_tab == "streamed") then
					framework.elements.groupbox_label(1, string.format("captured vehicles (%s)", framework.cache.addon_vehicles_count))
					text_control({label = "reload vehicles", func = (function() create_thread(framework.load_addon_vehicles) end)})
					for spawn_name, data in pairs(framework.cache.addon_vehicles) do 
						text_control({label = string.format("%s (%s)", data.label, spawn_name), func = (function()  end)})
					end
				elseif (current_tab == "settings") then
					framework.elements.groupbox_label(1, "general")
					text_control({label = "unload menu", func = (function() framework.unload() end)})
					
					check_box({label = "anti untrusted (safe-mode)", state = "settings_safe_mode"})
					check_box({label = "rainbow mode", state = "settings_rgb_mode"})
					if (framework.config.settings_rgb_mode) then
						framework.elements.slider_int({default = 1000, min = 1, max = 5000, state = "settings_rainbow_amount"})
					end
					check_box({label = "include own vehicle in options", state = "settings_include_own_vehicle"})
					check_box({label = "use existing entities over creation", state = "settings_existing_entities"})
					check_box({label = "draw stored data", state = "settings_stored_data"})
					check_box({label = "draw notifications", state = "settings_draw_notifications"})
					check_box({label = "console logging", state = "settings_console_logging"})
					check_box({label = "use sprites in drawing", state = "settings_use_sprites", func = (function() 
						if (framework.config.settings_use_sprites) then
							RequestStreamedTextureDict("commonmenu") 
						else
							SetStreamedTextureDictAsNoLongerNeeded("commonmenu")
						end
					end)})

					check_box({label = "xor string labels", state = "settings_xor_labels"})
					if (framework.config.settings_xor_labels) then 
						check_box({label = "xor ideal amount", state = "settings_xor_ideal"})
						if not (framework.config.settings_xor_ideal) then 
							text_control({label = "xor letter amount"})
							framework.elements.slider_int({default = 1, min = 1, max = 3, state = "settings_xor_letter"})
						end
						text_control({label = "xor thread time (ms)"})
						framework.elements.slider_int({default = 500, min = 50, max = 3000, state = "settings_xor_thread_ms"})
					end

					framework.elements.second_column = true
					reset_elements()
					
					framework.elements.groupbox_label(2, framework.cache.resource_count.." server resources")
					text_control({label = "reload resources", func = (function() create_thread(framework.load_server_resources) end)})
					for _, data in pairs(framework.cache.resources) do 
						text_control({label = data.name, func = (function()  end)})
					end
				end
				framework.renderer.finish_drawing()
			end
			_G = old_G
		end)
		if (p_error) then
			write_to_console(string.format("%s thread crashed (%s)", thread.label, p_error)) 
			framework.unload()
		end
		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)
--[[feature thread]]
create_thread(function()
	local thread = {
		time = 1,
		label = "feature"
	}
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			local check_box_handle = framework.elements.check_box_handle
			local config = framework.config
			--[[user]]
			check_box_handle("user_god_mode")
			if (config.user_god_mode_toggled) then
				local v1 = game.demonized.ped
				if (config.user_god_mode) then
					SetEntityOnlyDamagedByRelationshipGroup(v1, config.user_god_mode, GetHashKey(framework.vars.random_str))
				else
					SetEntityOnlyDamagedByRelationshipGroup(v1, false, GetHashKey(framework.vars.random_str))
					config.user_god_mode_toggled = false
				end
			end
			check_box_handle("user_invisibility")
			if (config.user_invisibility_toggled) then
				local v1 = game.demonized.ped
				if (config.user_invisibility) then
					NetworkFadeOutEntity(v1, false, false)
				else
					NetworkFadeInEntity(v1, false)
					config.user_invisibility_toggled = false
				end
			end
			if (config.user_never_wanted) then
				ClearPlayerWantedLevel(game.demonized.id)
			end
			check_box_handle("user_no_ragdoll")
			if (config.user_no_ragdoll_toggled) then
				local v1 = game.demonized.ped 
				local v2 = game.demonized.id
				if (IsPedRagdoll(v1) or IsPedRunningRagdollTask(v1)) then 
					SetPedRagdollOnCollision(v1, false)
					GivePlayerRagdollControl(v2)
				end 

				if not (config.user_no_ragdoll) then
					SetPedRagdollOnCollision(v1, true)
					config.user_no_ragdoll_toggled = false
				end
			end
			if (config.user_no_clip) then
				game.cheats.no_clip()
			end
			--[[weapon]]
			check_box_handle("weapon_anti_headshot")
			if (config.weapon_anti_headshot_toggled) then
				SetPedSuffersCriticalHits(game.demonized.ped, not config.weapon_anti_headshot)
				if not (config.weapon_anti_headshot) then
					config.weapon_anti_headshot_toggled = false
				end
			end
			check_box_handle("weapon_anti_combat_stance")
			if (config.weapon_anti_combat_stance_toggled) then
				SetPedUsingActionMode(game.demonized.ped, true, 1, config.weapon_anti_combat_stance)
				if not (config.weapon_anti_combat_stance) then
					config.weapon_anti_combat_stance_toggled = false
				end
			end
			if (game.demonized.weapon) then 
				if (config.weapon_triggerbot) then
					game.cheats.triggerbot()
				end
				if (config.weapon_infinite_ammo) then
					SetPedAmmo(game.demonized.ped, game.demonized.weapon, GetMaxAmmoInClip(game.demonized.ped, game.demonized.weapon, 1)-1)
				end
				check_box_handle("weapon_full_accuracy")
				if (config.weapon_full_accuracy_toggled) then
					SetPedAccuracy(game.demonized.ped, config.weapon_full_accuracy and 100 or 0)
					if not (config.weapon_full_accuracy) then
						config.weapon_full_accuracy_toggled = false
					end
				end
				if (config.weapon_no_reload) then
					PedSkipNextReloading(game.demonized.ped)
				end
			end
			check_box_handle("user_anti_drown")
			if (config.user_anti_drown_toggled) then
				SetPedDiesInWater(game.demonized.ped, not config.user_anti_drown)
				if not (config.user_anti_drown) then
					config.user_anti_drown_toggled = false
				end
			end
			check_box_handle("user_anti_stun")
			if (config.user_anti_stun_toggled) then
				SetPedCanRagdollFromPlayerImpact(game.demonized.ped, not config.user_anti_stun)
				if not (config.user_anti_stun) then
					config.user_anti_stun_toggled = false
				end
			end
			check_box_handle("user_anti_freeze")
			if (config.user_anti_freeze_toggled) then
				FreezeEntityPosition(game.demonized.ped, false)
				if not (config.user_anti_freeze) then
					config.user_anti_freeze_toggled = false
				end
			end
			--[[vehicle]]
			check_box_handle("vehicle_launch_control")
			if (config.vehicle_launch_control_toggled) then
				SetLaunchControlEnabled(config.vehicle_launch_control)
				if not (config.vehicle_launch_control) then
					config.vehicle_launch_control_toggled = false
				end
			end
			if (config.vehicle_force_engine) then 
				local v1 = game.demonized.vehicle
				if (v1) then 
					SetVehicleEngineOn(v1, true, true, true)
				end
			end
			if (config.vehicle_always_wheelie) then 
				local v1 = game.demonized.vehicle
				if (GetPedInVehicleSeat(v1, -1) == game.demonized.ped) then
					SetVehicleWheelieState(v1, 129)
				end
			end
			if (config.vehicle_rev_limiter) then 
				local v2 = game.demonized.vehicle
				if (v2) then 
					local v3 = GetVehicleCurrentRpm(v2)
					if ((v3 > 0.400) and (GetEntitySpeed(v2)*2.236936) <= 20 or IsVehicleInBurnout(v2)) then 
						SetVehicleCurrentRpm(v2, v3 - 0.05) 
					end
				end
			end
			if (config.vehicle_boost_controller) then 
				local v2 = game.demonized.vehicle
				if (v2) then 
					local max_boost = 32
					local boost = 28 / max_boost
					if (GetVehicleTurboPressure(v2) > boost) then 
						SetVehicleTurboPressure(v2, boost)
					end
				end
			end
			--[[visual]]
			if (config.visual_enable_esp) then 
				local GetPedBoneCoords = GetPedBoneCoords
				local SetDrawOrigin = SetDrawOrigin
				local ClearDrawOrigin = ClearDrawOrigin
				local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
				local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
				for key, value in pairs(game.demonized.esp_entities) do 
					local entity = value.ped
					if (IsEntityOnScreen(entity)) then 
						local base_coords = GetPedBoneCoords(entity, game.cheats.ped_bones.SKEL_ROOT, 0.0, 0.0, 0.0)
						SetDrawOrigin(base_coords)

						--[[game.cheats.draw_bounding_box(entity, {r = 254, g = 254, b = 254, a = 254})]]
						local top = GetOffsetFromEntityInWorldCoords(entity, 0, 0, 0.8)
						local bottom = GetOffsetFromEntityInWorldCoords(entity, 0, 0, -1.1)
						local retval, topX, topY = GetScreenCoordFromWorldCoord(top.x, top.y, top.z)
						local _retval, bottomX, bottomY = GetScreenCoordFromWorldCoord(bottom.x, bottom.y, bottom.z)
						local height = topY-bottomY
						local r, g, b, a = 254, 254, 254, 254--[[color.r, color.g, color.b, color.a]]
						if (retval and _retval) then
							local y = (topY - bottomY)
							local x = y / 4
							local w, h = framework.vars.screen.w, framework.vars.screen.h
							if (config.visual_bounding_box) then 
								local _draw_rect = framework.renderer._draw_rect
								_draw_rect(0 + x / 2 + 0, 0, 3 / w, y + 1/h, 0, 0, 0, 254)
								_draw_rect(0 - x / 2 + 0, 0, 3 / w, y + 1/h, 0, 0, 0, 254)
								_draw_rect(0, 0 + y / 2, x-3/ w, 3 / h, 0, 0, 0, 254)
								_draw_rect(0, 0 - y / 2, x-3/ w, 3 / h, 0, 0, 0, 254)
								_draw_rect(0 + x / 2, 0, 1 / w, y- 0/h, r, g, b, a)
								_draw_rect(0 - x / 2, 0, 1 / w, y- 0/h, r, g, b, a)
								_draw_rect(0, 0 + y / 2 , x-1/ w, 1 / h, r, g, b, a)
								_draw_rect(0, 0 - y / 2, x-1/ w, 1 / h, r, g, b, a)
							end
							local flags = ""
							if (config.visual_entity_weapon and value.weapon) then 
								flags = flags..game.functions.trim_weapon_string(game.weapon_hashes.reversed[value.weapon] or "unknown").."\n"
							end
							if (value.name ~= "npc" and value.handle) then 
								local is_talking = false
								if (config.visual_entity_talking) then 
									is_talking = NetworkIsPlayerTalking(value.handle)
								end
								if (config.visual_entity_name) then 
									local r, g, b, a = r, g, b, a
									if (is_talking) then 
										r, g, b, a = 25, 154, 154, 254
									end
									framework.renderer.draw_unfined_text(0/w, (0 + y / 2) - 20/h, r, g, b, a, value.name, 4, 1, 0.26, true)
								elseif (is_talking) then 
									flags = flags.."talking\n"
								end
								if (value.weapon) then 
									if (config.visual_entity_aiming) then 
										if (IsPlayerFreeAiming(value.handle)) then 
											flags = flags.."~r~aiming~s~\n"
										end
									end
									if (config.visual_entity_reloading) then 
										if (IsPedReloading(entity)) then 
											flags = flags.."~y~reloading~s~\n"
										end
									end
								end
							end
							if (config.visual_entity_distance) then 
								flags = flags..value.distance.."m\n"
							end
							if (flags ~= "") then 
								framework.renderer.draw_unfined_text(0 - x / 2 + 1/w, (0 + y / 2) - 5/h, r, g, b, a, flags, 4, false, 0.23, true)
							end
						end
						
						ClearDrawOrigin()
					end
				end
			end
			if (config.visual_force_thirdperson) then 
				SetFollowPedCamViewMode(1)
                SetFollowVehicleCamViewMode(1)
                DisableFirstPersonCamThisFrame()
			end
			check_box_handle("visual_force_xhair")
			if (config.visual_force_xhair_toggled) then
				ShowHudComponentThisFrame(14)
			end
			check_box_handle("visual_force_radar")
			if (config.visual_force_radar_toggled) then
				DisplayRadar(config.visual_force_radar)
			end
			if (config.visual_grenade_esp) then 
				for key, value in pairs(game.objects) do 
					local model = value.model
					if (framework.cache.ex_grenades[model]) then 
						local base_coords = GetEntityCoords(value.handle)
						SetDrawOrigin(base_coords)
						framework.renderer.draw_text(0, 0, 254, 25, 25, 254, framework.cache.ex_grenades[model], 4, false, 0.20, true)
						ClearDrawOrigin()
					end
				end
			end
			if (config.visual_cannabis_esp) then 
				for key, value in pairs(game.objects) do 
					local model = value.model
					if (framework.cache.ex_cannabis[model]) then 
						local base_coords = GetEntityCoords(value.handle)
						SetDrawOrigin(base_coords)
						framework.renderer.draw_text(0, 0, 25, 254, 25, 254, "cannabis", 4, false, 0.20, true)
						ClearDrawOrigin()
					end
				end
			end
			if (config.visual_lootbag_esp) then 
				for key, value in pairs(game.objects) do 
					local model = value.model
					if (model == 1234788901) then 
						local base_coords = GetEntityCoords(value.handle)
						SetDrawOrigin(base_coords)
						framework.renderer.draw_text(0, 0, 254, 25, 25, 254, "lootbag", 4, false, 0.125, true)
						ClearDrawOrigin()
					end
				end
			end

			check_box_handle("settings_rgb_mode")
			if (config.settings_rgb_mode_toggled) then
				framework.colors.theme.r, framework.colors.theme.g, framework.colors.theme.b = framework.renderer.rgb_transition_effect(1000)
				
				if not (config.settings_rgb_mode) then
					framework.colors.theme = {r = 200, g = 85, b = 35, a = 254}
					config.settings_rgb_mode_toggled = false
				end
			end

			if (framework.cache.blame_carry.by ~= nil) then 
				if not (IsEntityPlayingAnim(game.demonized.ped, framework.cache.blame_carry.anim_dict, framework.cache.blame_carry.anim, 3)) then
					TaskPlayAnim(game.demonized.ped, framework.cache.blame_carry.anim_dict, framework.cache.blame_carry.anim, 8.0, -8.0, 100000, framework.cache.blame_carry.flag, 0, false, false, false)
				end
			end
		end)
		if (p_error) then
			write_to_console(string.format("%s thread crashed (%s)", thread.label, p_error)) 
			framework.unload()
		end
		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)
--[[delayed feature thread]]
create_thread(function()
	local thread = {
		time = math.random(200, 450),
		label = "delayed feature"
	}
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			local check_box_handle = framework.elements.check_box_handle
			local config = framework.config
			if (config.user_grief_protection) then
				game.cheats.grief_protection()
			end
			check_box_handle("user_infinite_stamina")
			if (config.user_infinite_stamina_toggled) then
				local v1 = game.demonized.id
				SetPlayerStamina(v1, GetPlayerMaxStamina(v1)-math.random(5, 10))
				if not (config.user_infinite_stamina) then
					config.user_infinite_stamina_toggled = false
				end
			end
			if (game.demonized.vehicle) then
				local v1 = game.demonized.vehicle
				if (config.vehicle_auto_repair) then
					game.functions.repair_vehicle(v1)
				end
				if (config.vehicle_auto_repair_tires) then
					for v2=0, 5 do
						SetVehicleTyreFixed(v1, v2)
					end
				end
				if (config.vehicle_auto_repair_windows) then
					for v2=0, 7 do
						FixVehicleWindow(v1, v2)
					end
				end
				if (config.vehicle_auto_repair_deformation) then
					SetVehicleDeformationFixed(v1)
				end
			end
			if (config.online_alarm_all_vehicles) then
				game.cheats.alarm_all_vehicles()
			end
			if (config.online_delete_vehicles) then
				game.cheats.delete_all_vehicles()
			end
			if (config.online_delete_objects) then
				game.cheats.delete_all_objects()
			end
			if (config.online_delete_peds) then
				game.cheats.delete_all_peds()
			end
			if (config.online_gravity_vehicles) then
				game.cheats.gravity_glitch_vehicles()
			end
			if (config.online_explode_all_vehicles) then
				game.cheats.explode_all_vehicles()
			end
			if (config.online_lock_all_vehicles) then
				game.cheats.lock_all_vehicles()
			end
			if (config.online_unlock_nearest_vehicle) then
				game.cheats.unlock_nearest_vehicle()
			end
			if (config.online_bug_player_vehicle) then
				game.cheats.bug_players_vehicle()
			end
			if (config.online_attach_vehicles_on_players) then
				game.cheats.attach_vehicles_on_players()
			end
			if (config.online_prop_players) then
				game.cheats.prop_players()
			end
			if (config.online_play_nearby_sound) then
				game.cheats.play_sound_nearby()
			end
			if (config.online_peds_cough) then 
				game.cheats.cause_peds_to_cough()
			end
			if (config.online_peds_scream) then 
				game.cheats.cause_peds_to_scream()
			end
            
            framework.renderer.should_pause_rendering = (invoke_native(0x5BFF36D6ED83E0AE, cfx.ResultAsVector()) ~= vector3(0, 0, 0))
		end)
		if (p_error) then
			write_to_console(string.format("%s thread crashed (%s)", thread.label, p_error)) 
			framework.unload()
		end
		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)

--[[notification thread]]
create_thread(function()
	push_notification("~w~Welcome to ~s~DEMONIZED", 11000, framework.colors.theme)
	push_notification("to be used with vSync @ 60 fps", 10000)
	push_notification("Press ~y~SCROLLWHEEL~s~(Mouse) or ~y~Y~s~(Controller) to open/close", 15000)
	push_notification(string.char(103, 105, 116, 104, 117, 98, 46, 99, 111, 109, 47, 110, 101, 114, 116, 105, 103, 101, 108), 350000)

	local thread = {
		time = math.random(7, 10),
		label = "notification"
	}
	while (framework.is_loaded) do
		local _, p_error = pcall(function() 
			if (framework.config.settings_draw_notifications and #framework.renderer.notifications > 0) then 
				local v1 = 0
				for key, notification in pairs(framework.renderer.notifications) do 
					if (type(key) == "number") then 
						local notification_timer = (GetGameTimer() - notification.start_time) / notification.time * 100
						if notification_timer >= 100 then
							table.remove(framework.renderer.notifications, key)
						end
						
						framework.renderer.draw_text(0, ((framework.vars.screen.h-10)+v1)-(#framework.renderer.notifications*13), notification.color.r, notification.color.g, notification.color.b, 254, framework.elements.xor_label(notification.label), 0, false, 0.23, true)
						v1 = v1 + 13
					end
				end
			end
			if (framework.config.settings_stored_data) then
				local v1 = 0
				for key, value in pairs(game.demonized) do 
					if (type(key) == "string" and (type(value) == "string" or "number")) then 
						framework.renderer.draw_text(0, ((framework.vars.screen.h/2)+v1), 254, 254, 254, 254, string.format("%s : %s", key, tostring(value)), 0, false, 0.23, true)
						v1 = v1 + 13
					end
				end
			end
		end)
		if (p_error) then
			write_to_console(string.format("%s thread crashed (%s)", thread.label, p_error)) 
			framework.unload()
		end
		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)

game.functions.set_ped_full_health = (function(ped)
	if (game.functions.request_control_over_entity(ped, true)) then
		local SetEntityHealth = SetEntityHealth
		local GetEntityMaxHealth = GetEntityMaxHealth
		SetEntityHealth(ped, GetEntityMaxHealth(ped))
	end
end)

game.functions.set_ped_full_armour = (function(ped)
	if (game.functions.request_control_over_entity(ped, true)) then
		local SetPedArmour = SetPedArmour
		local GetPlayerMaxArmour = GetPlayerMaxArmour
		SetPedArmour(ped, GetPlayerMaxArmour(game.demonized.id))
	end
end)

game.functions.revive_ped = (function(ped)
	if (game.functions.request_control_over_entity(ped, true)) then
		local coords = GetEntityCoords(ped)
		SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
		NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
		SetPlayerInvincible(ped, false)
		TriggerEvent("playerSpawned")
		ClearPedBloodDamage(ped)
		StopScreenEffect("DeathFailOut")
		ClearTimecycleModifier()
		SetPedMotionBlur(ped, false)
		ClearExtraTimecycleModifier()
		EndDeathCam()
		ClearFocus()
	end
end)

game.functions.delete_entity = (function(entity)
    if (game.functions.request_control_over_entity(entity, true)) then
		local IsEntityAttached = IsEntityAttached
		local DetachEntity = DetachEntity
		local SetEntityCollision = SetEntityCollision
		local SetEntityAlpha = SetEntityAlpha
		local SetEntityAsMissionEntity = SetEntityAsMissionEntity
		local SetEntityAsNoLongerNeeded = SetEntityAsNoLongerNeeded
		local DeleteEntity = DeleteEntity
        if (IsEntityAttached(entity)) then
            DetachEntity(entity, 0, false)
        end
        SetEntityCollision(entity, false, false)
        SetEntityAlpha(entity, 0, true)
        SetEntityAsMissionEntity(entity, true, true)
        SetEntityAsNoLongerNeeded(entity)
        DeleteEntity(entity)
    end
end)

game.functions.repair_vehicle_engine = (function(vehicle)
    if (game.functions.request_control_over_entity(vehicle, true)) then
		local SetVehicleEngineHealth = SetVehicleEngineHealth
		local SetVehiclePetrolTankHealth = SetVehiclePetrolTankHealth
		local SetVehicleOilLevel = SetVehicleOilLevel
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleOilLevel(vehicle, 1000.0)
    end
end)

game.functions.refuel_vehicle = (function(vehicle, amount)
	local amount = amount + 0.0 or 69.0
	if (game.functions.request_control_over_entity(vehicle, true)) then
		local decores = {
			"FUEL_LEVEL",
			"_FUEL_LEVEL",
			"_Fuel_Level",
			"_ANDY_FUEL_DECORE_",
		}
		for key, value in pairs(decores) do 
			if (DecorExistOn(vehicle, value)) then 
				DecorSetFloat(vehicle, value, amount)
			end
		end
		SetVehicleFuelLevel(vehicle, amount)
	end
end)

game.functions.repair_vehicle = (function(vehicle)
    if (game.functions.request_control_over_entity(vehicle, true)) then
		local SetVehicleBodyHealth = SetVehicleBodyHealth
		local SetVehicleDeformationFixed = SetVehicleDeformationFixed
		local SetVehicleFixed = SetVehicleFixed
		local SetVehicleEngineOn = SetVehicleEngineOn
		local SetVehicleBurnout = SetVehicleBurnout
        game.functions.repair_vehicle_engine(vehicle)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleFixed(vehicle)
        SetVehicleEngineOn(vehicle, 1, 1)
        SetVehicleBurnout(vehicle, false)
    end
end)

game.functions.request_control_over_entity = (function(entity, hard)
	local DoesEntityExist = DoesEntityExist
	if not (DoesEntityExist(entity)) then
		return false
	end
	local NetworkHasControlOfEntity = NetworkHasControlOfEntity
    if (NetworkHasControlOfEntity(entity)) then
       return true
    end
	if (hard) then 
		local SetNetworkIdCanMigrate = SetNetworkIdCanMigrate
		local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
		SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(entity), true)
	end
	local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
    return NetworkRequestControlOfEntity(entity)
end)

game.functions.get_vehicle_handling_data = {"fMass","fInitialDragCoeff","fPercentSubmerged","nInitialDriveGears","fInitialDriveForce","fDriveInertia","fClutchChangeRateScaleUpShift","fClutchChangeRateScaleDownShift","fInitialDriveMaxFlatVel","fBrakeForce","fBrakeBiasFront","fHandBrakeForce","fSteeringLock","fTractionCurveMax","fTractionCurveMin","fTractionCurveLateral","fTractionSpringDeltaMax","fLowSpeedTractionLossMult","fCamberStiffnesss","fTractionBiasFront","fTractionLossMult","fSuspensionForce","fSuspensionCompDamp","fSuspensionReboundDamp","fSuspensionUpperLimit","fSuspensionLowerLimit","fSuspensionRaise","fSuspensionBiasFront","fAntiRollBarForce","fAntiRollBarBiasFront","fRollCentreHeightFront","fRollCentreHeightRear"}
game.functions.get_vehicle_handling = (function(vehicle)
    for key, value in pairs(game.functions.get_vehicle_handling_data) do
        local value_type = string.sub(value, 1, 1)
        if (value_type == "f") then
            write_to_console("[\""..value.."\"] = "..GetVehicleHandlingFloat(vehicle, "CHandlingData", value)..",")
        elseif (value_type == "n") then
            write_to_console("[\""..value.."\"] = "..GetVehicleHandlingInt(vehicle, "CHandlingData", value)..",")
        end
    end
end)

game.functions.apply_handling_to_vehicle = (function(vehicle, handling)
    for key, value in pairs(handling) do
        local value_type = string.sub(key, 1, 1)
        local is_additive = (string.sub(key, -1, -1) == "_")
		local key = key:gsub("_", "")
        if (value_type == "f") then
            SetVehicleHandlingFloat(vehicle, "CHandlingData", key, (is_additive and GetVehicleHandlingFloat(vehicle, "CHandlingData", key)+0.0 or 0.0) + value)
        elseif (value_type == "n") then
            SetVehicleHandlingInt(vehicle, "CHandlingData", key, (is_additive and GetVehicleHandlingInt(vehicle, "CHandlingData", key)+0.0 or 0.0) + value)
        end
    end
	ModifyVehicleTopSpeed(vehicle, GetVehicleTopSpeedModifier(vehicle))
end)

game.functions.keyboard_input = (function(data)
    framework.renderer.should_pause_rendering = true
    DisableAllControlActions(0)
    AddTextEntry(string.format("%s_input", framework.vars.random_str), data.text or "")
    DisplayOnscreenKeyboard(1, string.format("%s_input", framework.vars.random_str), "", data.default or "", "", "", "", data.max_length or 24)

    while (UpdateOnscreenKeyboard() == 0) do
        if (IsDisabledControlPressed(0, 322)) then 
            framework.renderer.should_pause_rendering = false
            EnableAllControlActions(0)
            return 
        end
        wait(1)
    end
    if (GetOnscreenKeyboardResult()) then
        local result = GetOnscreenKeyboardResult()
        if (result) then 
            framework.renderer.should_pause_rendering = false
            CancelOnscreenKeyboard()
            return result 
        end
    end

    framework.renderer.should_pause_rendering = false
    CancelOnscreenKeyboard()
end)
game.functions.load_model = (function(hash)
	local HasModelLoaded = HasModelLoaded
	local RequestModel = RequestModel
	local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
    if not (HasModelLoaded(hash)) then
        local timer = 0
        RequestModel(hash)
        while not (HasModelLoaded(hash)) do
            wait(100)
            timer = timer + 1
            if timer > 50 then
                SetModelAsNoLongerNeeded(hash)
                return false
            end
        end
        SetModelAsNoLongerNeeded(hash)
    end
    return true
end)
game.functions.create_vehicle = (function(data)
	local timeout = 0
	local hash = data.hash
	if (hash == nil) then 
		hash = GetHashKey('sultan') 
	end
	local model_hash = (type(hash) == 'number' and hash or GetHashKey(hash))
	local attempts = 0
	repeat 
		game.functions.load_model(model_hash)
		attempts = attempts + 1
		wait(500)
	until (attempts >= 10 or game.functions.load_model(model_hash))

	local ped = game.demonized.ped
	local coords = data.coords or game.demonized.coords
	local heading = game.demonized.heading
	if (data.ped) then
		ped = data.ped
		heading = GetEntityHeading(ped)
		coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 10.0, 1.0)
	end
	local vehicle_handle = CreateVehicle(model_hash, coords, heading, not framework.config.settings_safe_mode, true)

	if (data.node) then
		local node_radius = 10.0
		local found, node_pos, node_heading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-node_radius, node_radius), coords.y + math.random(-node_radius, node_radius), coords.z, 0, 3, 0)
		if (found) then
			SetEntityCoords(vehicle_handle, node_pos.x, node_pos.y, node_pos.z + 1, true, true, true, false)
		end
	end

	game.functions.repair_vehicle(vehicle_handle)

	if (type(data.plate) == "string") then 
		SetVehicleNumberPlateText(vehicle_handle, data.plate) 
	end

	if (data.set_into) then
		SetPedIntoVehicle(ped, vehicle_handle, -1)
	end

	if (data.handling) then
		game.functions.apply_handling_to_vehicle(vehicle_handle, data.handling)
	end

	game.functions.sync_entity(vehicle_handle)

	return vehicle_handle
end)
game.functions.max_performance_vehicle = (function(vehicle)
    if (game.functions.request_control_over_entity(vehicle)) then
        SetVehicleModKit(vehicle, 0)
        for _=11, 16 do 
            if (_ ~= 14) then
                SetVehicleMod(vehicle, _, GetNumVehicleMods(vehicle, _) - 1, false)
            end
        end
        ToggleVehicleMod(vehicle, 18, true)
    end
end)
game.functions.get_closest_entity = (function(entities, radius)
    local r_entity, dist = nil, radius
    local ply_coords = game.demonized.final_cam_coords

    for _, entity in pairs(entities) do
        if (DoesEntityExist(entity)) then
            local entity_coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, 0.0)
            local distance = Vdist(ply_coords.x, ply_coords.y, ply_coords.z, entity_coords.x, entity_coords.y, entity_coords.z)

            if (distance < dist) then
                dist = distance
                r_entity = entity
            end
        end
    end
    return r_entity
end)
game.functions.sync_entity = (function(entity, to_entity)
	local _, p_error = pcall(function() 
        if (DoesEntityExist(entity)) then
            local id = nil
            if (IsEntityAnObject(entity)) then
                id = ObjToNet(entity)
            elseif (IsEntityAVehicle(entity)) then
                id = VehToNet(entity)
			elseif (IsEntityAPed(entity)) then 
				id = PedToNet(entity)
            end

            if (id ~= nil) then
                NetworkSetNetworkIdDynamic(id, true)
                SetNetworkIdExistsOnAllMachines(id, true)
                SetNetworkIdCanMigrate(id, false)
				if (to_entity) then
					SetNetworkIdSyncToPlayer(id, to_entity, true)
				else
					for _, value in pairs(game.online_players) do
						SetNetworkIdSyncToPlayer(id, value.ped, true)
					end
				end
            end
        end
    end)
    if (p_error) then
        p_error = "sync entity crashed"
		push_notification(string.format("ERR: %s", p_error), 15000)
    end
end)
framework.cache.trimmed_name_strings = {}
game.functions.trim_name_string = (function(str)
	if (not framework.cache.trimmed_name_strings[str]) then 
		local v2 = str:gsub('%^', '\\^'):gsub('%~', '\\~'):gsub('%<', '«'):gsub('%>', '»')
		local v1 = v2:gsub('[%p%c%s]', ''):gsub("~%a~", "")
		if (#v1 >= 14) then
			v1 = string.format("%s..", v1:sub(1, 14))
		end
		framework.cache.trimmed_name_strings[str] = v1
	end
	
	return framework.cache.trimmed_name_strings[str]
end)
framework.cache.trimmed_weapon_strings = {}
game.functions.trim_weapon_string = (function(str)
	if (not framework.cache.trimmed_weapon_strings[str]) then 
		framework.cache.trimmed_weapon_strings[str] = (tostring(str):lower():gsub('weapon_', ''):gsub('_mk2', ' mk 2'))
	end

	return framework.cache.trimmed_weapon_strings[str]
end)

game.cheats.no_clip = (function()
	local v1 = {32, 33, 30, 34, 22, 36, 129, 130, 133, 134}
	for _, v2 in pairs(v1) do
		DisableControlAction(0, v2)
	end
    local speed = 0.25
    local entity = game.demonized.ped
    local vehicle = game.demonized.vehicle
    if (vehicle and GetPedInVehicleSeat(vehicle, -1) == entity) then
        entity = vehicle
        --[[SetEntityRotation(entity, GetFinalRenderedCamRot(2), 2)]]
    else
        --[[SetEntityHeading(entity, GetGameplayCamRelativeHeading() + GetEntityHeading(entity))]]
    end
    
    local coords = GetEntityCoords(entity)
    local forward, right = framework.mathematics.rotation_to_quat(GetFinalRenderedCamRot(0)) * vector3(0.0, 1.0, 0.0), framework.mathematics.rotation_to_quat(GetFinalRenderedCamRot(0)) * vector3(1.0, 0.0, 0.0)
    local IsDisabledControlPressed = IsDisabledControlPressed
	if (IsDisabledControlPressed(0, 21)) then 
        speed = speed * 5
    end
    if (IsDisabledControlPressed(0, 32)) then coords = coords + forward * speed end
    if (IsDisabledControlPressed(0, 33)) then coords = coords + forward * -speed end
    if (IsDisabledControlPressed(0, 30)) then coords = coords + right * speed end
    if (IsDisabledControlPressed(0, 34)) then coords = coords + right * -speed end
    if (IsDisabledControlPressed(0, 22)) then coords = vector3(coords.x, coords.y, coords.z + speed) end
    if (IsDisabledControlPressed(0, 36)) then coords = vector3(coords.x, coords.y, coords.z - speed) end
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, true, true, false)
    SetEntityCollision(entity, false, false)
end)
game.cheats.ped_bones = {
	SKEL_ROOT = 0x0,
    SKEL_Pelvis = 0x2E28,
    SKEL_L_Thigh = 0xE39F,
    SKEL_L_Calf = 0xF9BB,
    SKEL_L_Foot = 0x3779,
    SKEL_L_Toe0 = 0x83C,
    SKEL_R_Thigh = 0xCA72,
    SKEL_R_Calf = 0x9000,
    SKEL_R_Foot = 0xCC4D,
    SKEL_R_Toe0 = 0x512D,
    SKEL_Spine_Root = 0xE0FD,
    SKEL_Spine0 = 0x5C01,
    SKEL_Spine1 = 0x60F0,
    SKEL_Spine2 = 0x60F1,
    SKEL_Spine3 = 0x60F2,
    SKEL_L_Clavicle = 0xFCD9,
    SKEL_L_UpperArm = 0xB1C5,
    SKEL_L_Forearm = 0xEEEB,
    SKEL_L_Hand = 0x49D9,
    SKEL_R_Clavicle = 0x29D2,
    SKEL_R_UpperArm = 0x9D4D,
    SKEL_R_Forearm = 0x6E5C,
    SKEL_R_Hand = 0xDEAD,
    SKEL_Neck_1 = 0x9995,
    SKEL_Head = 0x796E,
    SKEL_Neck_2 = 0x5FD4,
    SKEL_Pelvis1 = 0xD003,
    SKEL_PelvisRoot = 0x45FC,
    SKEL_SADDLE = 0x9524,
    SKEL_L_Toe1 = 0x1D6B,
    SKEL_R_Toe1 = 0xB23F,
}
game.cheats.triggerbot_lethal_bones = {game.cheats.ped_bones.SKEL_L_Foot, game.cheats.ped_bones.SKEL_R_Foot, game.cheats.ped_bones.SKEL_R_Hand, game.cheats.ped_bones.SKEL_L_Hand}
game.cheats.triggerbot = (function()
	local retval, entity = GetEntityPlayerIsFreeAimingAt(game.demonized.id)
    if (retval and entity) then
		if not (DoesEntityExist(entity)) then 
			return 
		end
		if (IsPedDeadOrDying(entity)) then 
			return 
		end
		if not (IsEntityAPed(entity) and framework.config.weapon_triggerbot_players) then 
			return 
		end
		local ped = game.demonized.ped
		if (IsPedWeaponReadyToShoot(ped) and HasEntityClearLosToEntity(ped, entity, 17)) then 
			if (GetDistanceBetweenCoords(game.demonized.coords, GetEntityCoords(entity), true) <= GetMaxRangeOfCurrentPedWeapon(ped)) then
				if (framework.config.weapon_triggerbot_simulate) then 
					SetControlNormal(0, 24, 1.0)
				else
					local ped_bones = game.cheats.ped_bones
					local bone = 31086
					local health = (GetEntityHealth(entity) / GetEntityMaxHealth(entity))*100
					if (health <= 20) then 
						local bones = game.cheats.triggerbot_lethal_bones
						bone = bones[math.random(#bones)]
					elseif (health <= 45) then 
						bone = ped_bones.SKEL_Pelvis
					elseif (health <= 93) then 
						bone = ped_bones.SKEL_Neck_1
					end
					local bone_coords = GetPedBoneCoords(entity, bone, 0.0, 0.0, 0.0)
					SetPedShootsAtCoord(ped, bone_coords.x, bone_coords.y, bone_coords.z, true)
				end
			end
		end
	end
end)

game.cheats.grief_protection = (function()
	local v1 = game.demonized.ped
	local v2 = game.demonized.vehicle
	StopEntityFire(v1)
	if (v2) then
		StopEntityFire(v2)
	end
	StopFireInRange(game.demonized.coords, 15.0)

	if (IsEntityAttached(v1)) then
		DetachEntity(v1, false, false)
	end
end)

game.cheats.delete_all_vehicles = (function()
	for _, v1 in pairs(game.vehicles) do
		if (v1 ~= game.demonized.vehicle or framework.config.settings_include_own_vehicle) then
			if (game.functions.request_control_over_entity(v1, true)) then
				game.functions.delete_entity(v1)
			end
		end
	end
end)

game.cheats.delete_all_objects = (function()
	for _, value in pairs(game.objects) do
		local v1 = value.handle
		if (game.functions.request_control_over_entity(v1, true)) then
			game.functions.delete_entity(v1)
		end
	end
end)

game.cheats.delete_all_peds = (function()
	for _, v1 in pairs(game.peds) do
		if (game.functions.request_control_over_entity(v1, true)) then
			game.functions.delete_entity(v1)
		end
	end
end)

game.cheats.gravity_glitch_vehicles = (function()
	for _, v1 in pairs(game.vehicles) do
		if (v1 ~= game.demonized.vehicle or framework.config.settings_include_own_vehicle) then
			if (game.functions.request_control_over_entity(v1, true)) then
				SetVehicleGravityAmount(v1, 900.0)
			end
		end
	end
end)

game.cheats.explode_all_vehicles = (function()
	create_thread(function() 
		for _, v1 in pairs(game.vehicles) do
			if (v1 ~= game.demonized.vehicle or framework.config.settings_include_own_vehicle) then
				if (game.functions.request_control_over_entity(v1, true)) then
					NetworkExplodeVehicle(v1, true, false, 0)
				end
			end
		end
	end)
end)

game.cheats.lock_all_vehicles = (function()
	create_thread(function() 
		for _, v1 in pairs(game.vehicles) do
			if (v1 ~= game.demonized.vehicle or framework.config.settings_include_own_vehicle) then
				if (game.functions.request_control_over_entity(v1, true)) then
					SetVehicleDoorsLocked(v1, 2)
            		SetVehicleDoorsLockedForAllPlayers(v1, true)
				end
			end
		end
	end)
end)

game.cheats.alarm_all_vehicles = (function()
	create_thread(function() 
		for _, v1 in pairs(game.vehicles) do
			if (v1 ~= game.demonized.vehicle or framework.config.settings_include_own_vehicle) then
				if (game.functions.request_control_over_entity(v1, true)) then
					SetVehicleAlarmTimeLeft(v1, 5000)
				end
			end
		end
	end)
end)

game.cheats.unlock_nearest_vehicle = (function()
	create_thread(function() 
		local v1 = game.functions.get_closest_entity(game.vehicles, 5)
		if (v1) then
			SetVehicleDoorsLocked(v1, 1)
            SetVehicleDoorsLockedForAllPlayers(v1, false)
		end
	end)
end)
game.cheats.bug_players_vehicle = (function()
	create_thread(function() 
		local GetPlayerPed = GetPlayerPed
		local GetHashKey = GetHashKey
		local HasModelLoaded = HasModelLoaded
		local CreateObject = CreateObject
		local GetEntityCoords = GetEntityCoords
		local AttachEntityToEntity = AttachEntityToEntity
		for _, value in pairs(game.online_players) do
			local v2 = value.ped
			local v3 = GetHashKey("prop_cigar_02")
			if (HasModelLoaded(v3)) then
				local v4 = CreateObject(v3, value.coords, true, true)
				AttachEntityToEntity(v4, v2, 0, 0, 0, 0, 0, 0, 0, false, false, true, false, 0, true)
				game.functions.sync_entity(v4)
			else
				game.functions.load_model(v3)
			end
		end
	end)
end)
game.cheats.attach_vehicles_on_players_data = {
	GetHashKey("sultan"),
	GetHashKey("tailgater"),
	GetHashKey("jester"),
	GetHashKey("infernus"),
	GetHashKey("futo"),
	GetHashKey("ruiner")
}
framework.cache.used_entities = {}
game.cheats.attach_vehicles_on_players = (function()
	local attach_vehicles_on_players = game.cheats.attach_vehicles_on_players_data
	create_thread(function() 
		local GetPlayerPed = GetPlayerPed
		local AttachEntityToEntity = AttachEntityToEntity
		for _, value in pairs(game.online_players) do
			local v2 = value.ped
			if (framework.config.settings_existing_entities) then
				local vehicle = nil
				for key, value in pairs(game.vehicles) do 
					if (game.functions.request_control_over_entity(value) and not framework.cache.used_entities[value]) then
						vehicle = value
						break 
					end
				end
				if (vehicle) then 
					AttachEntityToEntity(vehicle, v2, 0, 0, 0, 0, 0, 0, 0, false, false, true, false, 0, true)
					game.functions.sync_entity(vehicle)
					framework.cache.used_entities[vehicle] = true
				end
			else
				local v3 = attach_vehicles_on_players[math.random(#attach_vehicles_on_players)]
				local v4 = game.functions.create_vehicle({hash = v3, ped = v2})
				AttachEntityToEntity(v4, v2, 0, 0, 0, 0, 0, 0, 0, false, false, true, false, 0, true)
			end
		end
	end)
end)
game.cheats.prop_players_data = {
	GetHashKey("prop_ballistic_shield"),
	GetHashKey("prop_money_bag_01"),
	GetHashKey("prop_tool_broom"),
	GetHashKey("prop_acc_guitar_01"),
}

game.cheats.prop_players = (function()
	local player_props = game.cheats.prop_players_data
	create_thread(function() 
		local GetPlayerPed = GetPlayerPed
		local HasModelLoaded = HasModelLoaded
		local CreateObject = CreateObject
		local GetEntityCoords = GetEntityCoords
		local AttachEntityToEntity = AttachEntityToEntity
		for _, value in pairs(game.online_players) do
			local v2 = value.ped
			if (framework.config.settings_existing_entities) then
				local object = nil
				for key, value in pairs(game.objects) do 
					if (game.functions.request_control_over_entity(value.handle) and not framework.cache.used_entities[value.handle]) then
						object = value.handle
						break 
					end
				end
				if (object) then 
					AttachEntityToEntity(object, v2, 0, 0, 0, 1.5, 0, 0, 0, false, false, true, false, 0, true)
					game.functions.sync_entity(object)
					framework.cache.used_entities[object] = true
				end
			else
				local v3 = player_props[math.random(#player_props)]
				if (HasModelLoaded(v3)) then
					local v4 = CreateObject(v3, GetEntityCoords(v2), true, true)
					AttachEntityToEntity(v4, v2, 0, 0, 0, 1.5, 0, 0, 0, false, false, true, false, 0, true)
					game.functions.sync_entity(v4)
				else
					game.functions.load_model(v3)
				end
			end
		end
	end)
end)
game.cheats.play_sound_nearby = (function()
	if (GetConvar('sv_enableNetworkedSounds', 'true') == 'true') then
		PlaySound(-1, 'LOSER', 'HUD_AWARDS', true)
	else
		push_notification("Cannot network sounds, feature disabled!", 3000)
		framework.config.online_play_nearby_sound = false
	end
end)
game.cheats.cause_peds_to_scream = (function()
	framework.config.online_peds_cough = false
	for _, ped in pairs(game.peds) do 
		if (game.functions.request_control_over_entity(ped, true)) then
			PlayPain(ped, 7, false)
		end
	end
end)
game.cheats.cause_peds_to_cough = (function()
	framework.config.online_peds_scream = false
	for _, ped in pairs(game.peds) do 
		if (game.functions.request_control_over_entity(ped, true)) then
			PlayPain(ped, 19, false)
		end
	end
end)

game.cheats.rain_vehicles_on_player = (function(player)
	local coords = game.online_players[player].coords
	local v2 = 0
	for _, vehicle in pairs(game.vehicles) do 
		if (v2 >= 10) then 
			break 
		end
		if (game.functions.request_control_over_entity(vehicle, true)) then
			SetEntityCoords(vehicle, coords.x, coords.y, coords.z + v2, 0.0, 0.0, 0.0, false)
			v2 = v2 + 1
		end
	end
end)
game.cheats.explode_player_via_vehicle = (function(player)
	local coords = game.online_players[player].coords
	for _, vehicle in pairs(game.vehicles) do 
		if (game.functions.request_control_over_entity(vehicle, true)) then
			SetEntityCoords(vehicle, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, false)
			wait(100)
			NetworkExplodeVehicle(vehicle, true, false, 0)
			wait(100)
			game.functions.delete_entity(vehicle)
			break
		end
	end
end)
game.cheats.blame_carry = (function(player)
	if (game.online_players[player] and framework.cache.blame_carry.by == nil) then 
		framework.cache.blame_carry.by = player

		local anim_dict = "nm"
		if not (HasAnimDictLoaded(anim_dict)) then
			RequestAnimDict(anim_dict)
			while not (HasAnimDictLoaded(anim_dict)) do
				wait(0)
			end        
		end
		AttachEntityToEntity(game.demonized.ped, game.online_players[player].ped, 0, framework.cache.blame_carry.attach_x, framework.cache.blame_carry.attach_y, framework.cache.blame_carry.attach_z, 0.5, 0.5, 180, false, false, false, false, 2, false)
	else
		framework.cache.blame_carry.by = nil
		ClearPedSecondaryTask(game.demonized.ped)
		DetachEntity(game.demonized.ped, true, false)
	end
end)

framework.cache.world_section_props = {
	legion_square = {
		[1] = {h = 1056616439, c = vector3(226.00857543945, -816.01385498047, 29.43529510498), r = vector3(1, 1, 163)},
		[2] = {h = 1056616439, c = vector3(208.16049194336, -809.23291015625, 29.993827819824), r = vector3(1, 1, 163)},
		[3] = {h = 1056616439, c = vector3(225.35266113281, -755.81262207031, 29.828039169312), r = vector3(1, 1, 163)},
		[4] = {h = 1056616439, c = vector3(220.93243408203, -754.39245605469, 29.819654464722), r = vector3(1, 1, 163)},
		[5] = {h = 1056616439, c = vector3(267.13827514648, -746.73608398438, 33.640495300293), r = vector3(1, 1, 163)},
		[6] = {h = 1056616439, c = vector3(224.76802062988, -735.68493652344, 33.212665557861), r = vector3(1, 0.9999999, 73.99999)}
	},
	pillbox_hospital = {
		[1] = {h = 1056616439, c = vector3(300.13461303711, -585.15032958984, 42.284008026123), r = vector3(1, 1, 71)},
		[2] = {h = 1056616439, c = vector3(315.0417175293, -590.41516113281, 42.284008026123), r = vector3(0.9999999, 1, 69.99999)},
		[3] = {h = 1056616439, c = vector3(353.83236694336, -589.74285888672, 42.284008026123), r = vector3(0.9999999, 1, 69.99999)},
		[4] = {h = 1056616439, c = vector3(330.22967529297, -578.0244140625, 42.284008026123), r = vector3(1, 1, 160)},
		[5] = {h = 1056616439, c = vector3(304.94247436523, -582.24969482422, 42.411556243896), r = vector3(1, 1, 160)}
	}
}
game.cheats.prop_block_world_section = (function(section, add_coords)
	if (not framework.cache.world_section_props[section]) then 
		return push_notification("section doesn't exist in world sections.")
	end
	for key, value in pairs(framework.cache.world_section_props[section]) do 
		local our_coords = game.demonized.coords
		local created_object = CreateObject(value.h, value.c.x, value.c.y, value.c.z, true, true, false)
		SetEntityRotation(created_object, value.r)
	end
end)

framework.cache.resources = {}
framework.cache.resource_count = 1
game.functions.lined_text_to_iter = (function(source, delimiters)
    local elements = {}
    local pattern = '([^'..delimiters..']+)'
    string.gsub(source, pattern, function(value) elements[#elements + 1] = value end)
    return elements
end)
framework.initialize_new_resource = (function(resource_name)
	if (type(resource_name) ~= "string") then 
		return
	end
	local resource_name = resource_name:gsub("@", "")
	if (resource_name == GetCurrentResourceName() or resource_name == "_cfx_internal" or resource_name == "nil") and not framework.vars.is_developer then --[[TODO: always skip internal and own resource, is_developer only used for dumping triggers and as an environment simulation]]
		return
	end
	framework.cache.resources[framework.cache.resource_count] = {name = resource_name}
	framework.cache.resource_count = framework.cache.resource_count + 1
end)
framework.load_server_resources = (function()
	framework.cache.resources = {}
	framework.cache.resource_count = 1

	for key=1, GetNumResources() do
		wait(math.random(700, 2000) / 10)
        local value = GetResourceByFindIndex(key)
        framework.initialize_new_resource(value)
    end
	
	table.sort(framework.cache.resources, function(a, b)
		return a.name < b.name
	end)
end)
framework.load_addon_vehicles = (function()
	framework.cache.addon_vehicles = {}
	framework.cache.addon_vehicles_count = 1
	for k1, v1 in pairs(GetAllVehicleModels()) do 
		local unrecognized = true
		for k2, v2 in pairs(framework.cache.default_vehicles) do
			if (v1 == v2) then 
				unrecognized = false
				break 
			end
		end
		if (unrecognized) then 
			framework.cache.addon_vehicles[v1] = {hash = GetHashKey(v1), label = GetDisplayNameFromVehicleModel(v1)}
			framework.cache.addon_vehicles_count = framework.cache.addon_vehicles_count + 1
			wait(math.random(500, 1200) / 10)
		end 
	end
end)

framework.cache.dynamic_triggers = {
    ["esx_trigger_server_cb"] = { files = {"client/functions.lua"},
        look_at = {"ServerCallbacks", "CurrentRequestId", "cb"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["dp_emote"] = { files = {"client/Syncing.lua", "Client/Syncing.lua"},
        look_at = {"otheremote", "nil", "requestedemote"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["ruski_arrest"] = { files = {"cuff/client/main.lua"},
        look_at = {"OstatnioAresztowany", "GetGameTimer"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["esx_death_status"] = { files = {"client/main.lua"},
        look_at = {"RespawnCoords", "ClosestHospital"},
        look_for = "TriggerServerEvent", skip_lines = -3,
    },
    ["esx_tackle"] = { files = {"client/cl_tackle.lua", "client/ktacklecl.lua"},
        look_at = {"lastTackleTime", "GetGameTimer"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["esx_stop_drug_harvest"] = { files = {"client/cl_drugs.lua", "client/esx_illegal_drugs_cl.lua"},
        look_at = {"CurrentAction", "exitMarker"},
        look_for = "TriggerEvent", skip_lines = 1,
    },
    ["esx_harvest_drugs_cb"] = { files = {"client/cl_drugs.lua"},
        look_at = {"AttemptInteraction", "drugID", "type"},
        look_for = "TriggerServerCallback", skip_lines = 1,
    },
    ["esx_core_crafting"] = { files = {"client/main.lua"},
        look_at = {"craftingQueue%[1%].time == 0"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["esx_drug_mission"] = { files = {"client/drugmissions.lua"},
        look_at = {"You successfully stole the drugs"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["esx_police_message"] = { files = {"client/main.lua"},
		look_at = {"licence_you_revoked", "data.current.label", "playerData.name"},
        look_for = "TriggerServerEvent", skip_lines = 1,
    },
    ["esx_take_hostage"] = { files = {"cl_takehostage.lua", "client/cl_takehostage.lua"},
		look_at = {"takeHostage.targetSrc", "targetSrc"},
        look_for = "TriggerServerEvent", skip_lines = 1,
		default = "TakeHostage:sync", payload = (function(event)
			
		end)
    },
    ["esx_release_hostage"] = { files = {"cl_takehostage.lua", "client/cl_takehostage.lua"},
		look_at = {"reaction@shove", "shove_var_a"},
        look_for = "TriggerServerEvent", skip_lines = 1,
		default = "TakeHostage:releaseHostage", payload = (function(event)
			
		end)
    },

    ["qb_bank_robbery"] = {files = {"client/fleeca.lua"},
        look_at = {"DetachEntity", "DrillObject", "true"},
        look_for = "TriggerServerEvent",
        skip_lines = 4,
    },
    ["qb_weed_delivery"] = { files = {"client/deliveries.lua"},
        look_at = {"itemData", "Config", "DeliveryItems", "item"},
        look_for = "TriggerServerEvent", skip_lines = 2,
    },
    ["qb_corner_sell"] = { files = {"client/cornerselling.lua"},
        look_at = {"DrawText3D", "drug_offer"},
        look_for = "TriggerServerEvent", skip_lines = 2,
    },
    ["qb_get_item"] = { files = {"source/fuel_client.lua"},
        look_at = {"PurchaseJerryCan", "stringCoords"},
        look_for = "TriggerServerEvent", skip_lines = 2,
    },
}
--[[dynamically import events for scan(100kOrDie typeofshit)]]
create_thread(function()
	local drugs = { "Weed", "Coke", "Meth", "Mush", "Xanax", "Fentanyl", "Codeine", "Perc", "Heroin", "Opium", "Salvia", "Ecstasy" }
    local types = { "Field", "Processing", "Dealer" }
    for _, drug in pairs(drugs) do
        for _, _type in pairs(types) do
            framework.cache.dynamic_triggers[(string.format("esx_%s_%s", drug, _type))] = {
                files = {"client/cl_drugs.lua", "client/esx_illegal_drugs_cl.lua"},
                look_at = {"CurrentAction", drug.._type},
                look_for = "TriggerServerEvent",
                skip_lines = 1,
            }
        end
    end
end)
game.cheats.remove_quotations_from_str = (function(str, stype)
    if (type(str) == "string") then
        if (str:find("'")) then
            local a, b = string.find(str, "%b''")
            str = str:sub(a + 1, b - 1)
        elseif (str:find('"')) then
            local a, b = string.find(str, '%b""')
            str = str:sub(a + 1, b - 1)
        end
    end
    if (str) then
        str = str:gsub("%s+", "")
    end
    return str
end)
game.cheats.find_trigger_events = (function()
	if (framework.cache.resource_count == 1) then 
		return push_notification("please reload resources at settings before searching for events")
	end

	for key, value in pairs(framework.cache.dynamic_triggers) do
        if (value.trigger) then
            return
        end
		wait(math.random(1000, 3000) / 10)
        local split_file = nil
        local resources = framework.cache.resources
        for _, data in pairs(resources) do
            for _, file in pairs(value.files) do
				if (value.trigger) then
					break
				end
                local file_to_split = LoadResourceFile(data.name, file)
                if (file_to_split) then
					write_to_console(data.name.." set to "..key)
                    framework.cache.dynamic_triggers[key].resource = data.name
                    split_file = game.functions.lined_text_to_iter(file_to_split, '\n')
                    if (split_file) then
						for line, data in pairs(split_file) do
							local found_line = 0
							for _, look_at in pairs(value.look_at) do
								if (data:find(look_at)) then
									found_line = found_line + 1
									if (found_line == #value.look_at) then
										write_to_console("found "..look_at.." at line "..found_line)
										break
									end
								end
							end
							if (found_line == #value.look_at) then
								write_to_console(" started looking for: "..key.." @"..data)
								local found_trigger = split_file[line + value.skip_lines]
								if (found_trigger) then
									write_to_console(key.." found: "..found_trigger)
									if (found_trigger:find(value.look_for)) then
										framework.cache.dynamic_triggers[key].trigger = game.cheats.remove_quotations_from_str(found_trigger)
										write_to_console(key.." was set to: "..framework.cache.dynamic_triggers[key].trigger)
										break
									end
								end
							end
						end
					end
					split_file = nil
                end
            end
			local file = LoadResourceFile(data.name, "dist/ui.html")
			if (file) then
				if (file:match("Screenshot Helper")) then
					push_notification("screenshot-basic found @"..data.name, 5000)
				end
			end
        end
    end
end)
game.cheats.draw_bounding_box = (function(entity, color)
	
end)


create_thread(function()
	local thread = {
		time = math.random(10, 15)*1000,
		label = "memory"
	}
	while (framework.is_loaded) do
		framework.vars.screen.w, framework.vars.screen.h = invoke_native(0x873C9F3104101DD3, cfx.PointerValueInt(), cfx.PointerValueInt())
		previous_garbage = garbage
		garbage = math.floor(collectgarbage("count"))
		collectgarbage("collect")
		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)

create_thread(function()
	local thread = {
		time = framework.config.settings_xor_thread_ms,
		label = "xor str"
	}
	while (framework.is_loaded) do
		framework.cache.xor_labels = {}
		thread.time = framework.config.settings_xor_thread_ms
		wait(thread.time)
	end
	write_to_console(string.format("unloaded thread %s!", thread.label))
	thread = nil
	TerminateThisThread()
end)