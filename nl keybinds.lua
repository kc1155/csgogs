local fonts = {
    museosans = render.load_font("Museo Sans Cyrl 700", 14, "a"),
    museosans_bold = render.load_font("Museo Sans Cyrl 500", 14, "a")
}
utils.in_bounds = function(pos_a, pos_b, point)
    return point.x > pos_a.x and point.y > pos_a.y and point.x < pos_b.x and point.y < pos_b.y
end
local draggable = {}
function draggable:new(name, start_pos, region_size)
    start_pos = start_pos or vector(100, 100)
    local new_drag = {
        name = name,
        start_pos = start_pos,
        region_size = region_size or vector(100, 100),
        x = ui.find("Config", "Config"):slider_int(name .. "_x", 0, render.screen_size().x, start_pos.x),
        y = ui.find("Config", "Config"):slider_int(name .. "_y", 0, render.screen_size().y, start_pos.y),
        captured = false,
        clicked = false,
        mouse_offset = vector(0, 0)
    }
    new_drag.x:visible(false)
    new_drag.y:visible(false)
    setmetatable(new_drag, self)
    self.__index = self
    return new_drag
end
function draggable:get()
    return vector(self.x:get(), self.y:get())
end

local bg_color_anim = 0
local bg_alpha_anim = 0
local is_rendering_rect = false
function draggable:update(region_size, lock_x)
    if not ui.is_open() then self.captured = false self.clicked = false end
    if region_size ~= nil then self.region_size = region_size end
    if lock_x == nil then lock_x = false end
    if self.captured then
        bg_alpha_anim = math.lerp(bg_alpha_anim, 100, 2 * globals.frametime)
        bg_color_anim = math.clamp(0, 255, math.lerp(bg_color_anim, -62, 2.5 * globals.frametime))
    else
        bg_alpha_anim = math.lerp(bg_alpha_anim, 0, 1 * globals.frametime)
        bg_color_anim = math.lerp(bg_color_anim, 45, 1 * globals.frametime)
    end
    is_rendering_rect = true

    if math.floor(bg_alpha_anim) <= 5 then
        is_rendering_rect = false
    end
    if utils.is_key_pressed(0x1) then
        local cur_pos = self:get()
        local mouse_pos = utils.get_mouse_position()
        if not self.clicked then
            self.clicked = true
            if utils.in_bounds(cur_pos, cur_pos + self.region_size, mouse_pos) then
                self.captured = true 
                self.mouse_offset = mouse_pos - cur_pos 
            end
        end

        if self.captured then
            self.x:set(type(lock_x) == 'boolean' and mouse_pos.x - self.mouse_offset.x or lock_x)
            self.y:set(mouse_pos.y - self.mouse_offset.y)
        end
    else
        self.captured = false
        self.clicked = false
    end
end
function entity_get_weapon_name()
    if not entity.get_local_player() or not entity.get_local_player():is_alive() or not entity.get_local_player():get_active_weapon() then return end
    local weapon_ind = {[589828] = "Pistol",[4] = "Pistol",[589827] = "Pistol",[3] = "Pistol",[589860] = "Pistol",[36] = "Pistol",[589854] = "Pistol",[30] = "Pistol",[589887] = "Pistol",[63] = "Pistol",[589826] = "Pistol",[2] = "Pistol",[589856] = "Pistol",[32] = "Pistol",[589885] = "Pistol",[262205] = "Pistol",[61] = "Pistol",[589825] = "Deagle",[1] = "Deagle",[589888] = "Revolver",[262208] = "Revolver",[64] = "Revolver",[42] = "Global",[589841] = "Global",[17] = "Global",[589857] = "Global",[33] = "Global",[589858] = "Global",[34] = "Global",[589850] = "Global",[26] = "Global",[589843] = "Global",[19] = "Global",[589848] = "Global",[24] = "Global",[589847] = "Global",[262167] = "Global",[23] = "Global",[589831] = "Global",[7] = "Global",[589840] = "Global",[16] = "Global",[589884] = "Global",[60] = "Global",[589837] = "Global",[13] = "Global",[589834] = "Global",[10] = "Global",[589832] = "Global",[8] = "Global",[589863] = "Global",[39] = "Global",[589852] = "Global",[28] = "Global",[589838] = "Global",[14] = "Global",[589851] = "Global",[27] = "Global",[589859] = "Global",[35] = "Global",[589853] = "Global",[29] = "Global",[589849] = "Global",[25] = "Global",[589864] = "Scout",[40] = "Scout",[589835] = "Auto",[11] = "Auto",[589862] = "Auto",[38] = "Auto",[589833] = "AWP",[9] = "AWP"}
    return weapon_ind[entity.get_local_player():get_active_weapon():weapon_index()]
end
function dmg_indicator()
    if not entity_get_weapon_name() then return end
	local mindmg = ui.find("Aimbot", "Aimbot", "Min. damage override"):get()
	if mindmg then
		return ui.find("Aimbot", "Settings", "[".. entity_get_weapon_name() .."] Minimum damage override"):get()
	else
		return ui.find("Aimbot", "Settings", "[".. entity_get_weapon_name() .."] Minimum damage"):get()
	end
end
local color_extension; do
    local color_mt = getmetatable(color());
    color_mt.alpha = function(s, a) return color(s.r, s.g, s.b, a) end
    color_mt.alp = function(s, a) return s:alpha(a * 255) end
    color_mt.alp_self = function(s, a) return s:alpha((a * s.a / 255) * 255) end
    function color_mt:unpack() return self.r, self.g, self.b, self.a end 
    function color_mt:to_hex() return string.format("%02x%02x%02x%02x", self:unpack()) end 
end
local renderer = {}; do
    renderer.rounded_shadow = function(from, to, color, r, size)
        if color.a ~= 0 then
            for i = 1, size do
                render.rect(from - vector(i*3, i*3 - 1), to + vector(i*3, i*3), color:alp_self((size - i) / size), r + i*2)
            end
        end
    end
end
local misc = ui.find("Scripts", "Scripts")
local check = misc:checkbox("NL keybinds")
local col = misc:color_picker("NL keybinds")
local kto_prochital_tot_lox = misc:label("~ by n3xrot/unblockmen3xrot")

local cvet = render.load_image(network.get('https://s2.radikal.cloud/2024/11/14/NORNS-no-bg-preview-carve.photos.png'), vector(19.9, 23))
local image_on = render.load_image(network.get('https://s2.radikal.cloud/2024/11/14/KNOPKA.png'), vector(17, 17))

local projat = 0;local projat_0 = 0;local projat_1 = 0
local anims = 0;local anims_0 = 0;local anims_1 = 0;local anims_2 = 0
local anims_dmg = 0;local anims_dmg_0 = 0
local anims_pick = 0;local anims_pick_0 = 0
local anims_ping = 0;local anims_ping_0 = 0
local anims_fd = 0;local anims_fd_0 = 0

local drag = draggable:new("sasasasa")
local key_anims = { alpha = 0 }
function keybinds()
    if not check:get() then return end

    local dt_on, hs_on, dmg_on, pick_on = ui.find("Aimbot", "Aimbot", "Double Tap"):get(0), ui.find("Aimbot", "Aimbot", "Hide Shots"):get(0), ui.find("Aimbot", "Aimbot", "Min. damage override"):get(0), ui.find("Aimbot", "Aimbot", "Peek Assist key"):get(0)
    local ping_on, fd_on = ui.find("Misc", "Miscellaneous", "Ping spike"):get(0), ui.find("Anti aim", "Other", "Fake duck"):get(0)
    local ping_procent = ui.find("Misc", "Miscellaneous", "Amount"):get()
    local dmg = dmg_indicator()
    if dt_on == true then projat = 1 else projat = 0 end
    if hs_on == true then projat_0 = 1 else projat_0 = 0 end
    if hc_on == true then projat_1 = 1 else projat_1 = 0 end
    if dmg_on == true then anims_dmg_0 = 1 else anims_dmg_0 = 0 end
    if pick_on == true then anims_pick_0 = 1 else anims_pick_0 = 0 end
    if ping_on == true then anims_ping_0 = 1 else anims_ping_0 = 0 end
    if fd_on == true then anims_fd_0 = 1 else anims_fd_0 = 0 end
    anims = math.lerp(anims, projat, 10 * globals.frametime)--dt
    anims_0 = math.lerp(anims_0, projat_0, 10 * globals.frametime)--hs
    anims_1 = math.lerp(anims_1, projat_1, 10 * globals.frametime)--hcc
    anims_dmg = math.lerp(anims_dmg, anims_dmg_0, 10 * globals.frametime)--dmg
    anims_pick = math.lerp(anims_pick, anims_pick_0, 10 * globals.frametime)--peek
    anims_ping = math.lerp(anims_ping, anims_ping_0, 10 * globals.frametime)--ping
    anims_fd = math.lerp(anims_fd, anims_fd_0, 10 * globals.frametime)--fd

    FD_0_anim = math.lerp(anims_fd, anims_fd_0, 10 * globals.frametime)--fd
    PING_0_anim = math.lerp(anims_ping, anims_ping_0, 10 * globals.frametime)--ping
    PEREKLYCHATEL_anim = math.lerp(anims, projat, 10 * globals.frametime)--dt okoshko
    PEREKLYCHATEL_0_anim = math.lerp(anims_0, projat_0, 10 * globals.frametime)--hs okoshko
    DMG_0_anim = math.lerp(anims_dmg, anims_dmg_0, 10 * globals.frametime)
    PEEK_0_anim = math.lerp(anims_pick, anims_pick_0, 10 * globals.frametime)

    local anim_fd_pr = 41 -- FD
    anim_fd_pr = 1 and anim_fd_pr * anims_fd or anim_fd_pr

    local FD_0 = 8 -- FD_0
    FD_0 = 1 and FD_0 * FD_0_anim or FD_0

    local anim_ping_pr = 41 -- PING
    anim_ping_pr = 1 and anim_ping_pr * anims_ping or anim_ping_pr

    local PING_0 = 8 -- PING_0
    PING_0 = 1 and PING_0 * PING_0_anim or PING_0

    local pricel_aah = 41 -- dt
    pricel_aah = 1 and pricel_aah * anims or pricel_aah

    local pricel_aah_2 = 41 -- hs
    pricel_aah_2 = 1 and pricel_aah_2 * anims_0 or pricel_aah_2

    local anim_dmg_pr = 41 -- DMG
    anim_dmg_pr = 1 and anim_dmg_pr * anims_dmg or anim_dmg_pr

    local anim_peek_pr = 41 -- PEEK
    anim_peek_pr = 1 and anim_peek_pr * anims_pick or anim_peek_pr

    local PEEK_0 = 8 -- PEEK
    PEEK_0 = 1 and PEEK_0 * PEEK_0_anim or PEEK_0

    local DMG_0 = 8 -- DMG_0
    DMG_0 = 1 and DMG_0 * DMG_0_anim or DMG_0

    local hit_1 = 41 -- hc(word)
    hit_1 = 1 and hit_1 * anims_1 or hit_1

    local hit_12 = 10 -- hc
    hit_12 = 1 and hit_12 * anims_1 or hit_12

    local PEREKLYCHATEL = 8 -- dt
    PEREKLYCHATEL = 1 and PEREKLYCHATEL * PEREKLYCHATEL_anim or PEREKLYCHATEL

    local PEREKLYCHATEL_0 = 8 -- hs
    PEREKLYCHATEL_0 = 1 and PEREKLYCHATEL_0 * PEREKLYCHATEL_0_anim or PEREKLYCHATEL_0

    local sadd_yy = 0

    key_anims.alpha = math.lerp(key_anims.alpha, ((not dt_on and not hs_on and not dmg_on and not pick_on and not ping_on and not fd_on)) and 0 or 255, 7 * globals.frametime)

    drag:update(vector(120, 34))
    local pos = drag:get()

    if not dt_on and not hs_on and not dmg_on and not pick_on and not ping_on and not fd_on then return end
    renderer.rounded_shadow(vector(pos.x-43,pos.y-14.5), vector(pos.x+ 34, pos.y+5.5), (col:get():alpha_modulate(35 * (key_anims.alpha/255))),8,8)

    render.rect(vector(pos.x-45,pos.y-15), vector(pos.x+ 35, pos.y+6), color(30,30,30, 255):alpha_modulate(255 * (key_anims.alpha/255)),6) -- global
    render.texture(cvet, vector(pos.x-39, pos.y-16), (col:get():alpha_modulate(255 * (key_anims.alpha/255))))
    
    render.text(fonts.museosans_bold, vector(pos.x + 6, pos.y - 12), color(255,255,255,255),"c", "Hotkeys")

    if ping_on then ----------------------------------------------------------------------------------------------
        render.rect(vector(pos.x-48.5+PING_0,pos.y+12 + sadd_yy), vector(pos.x-26+PING_0, pos.y+26 + sadd_yy), color(15,15,15, 27),5)

        render.rect(vector(pos.x-55+anim_ping_pr,pos.y+12 + sadd_yy), vector(pos.x+20+anim_ping_pr, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.text(fonts.museosans, vector(pos.x-17+anim_ping_pr, pos.y+11.5 + sadd_yy), color(255,255,255,255), "c", "Fake Latency")
        render.text(fonts.museosans, vector(pos.x-38+PING_0, pos.y+12.5 + sadd_yy), color(255,255,255,255), "c", ping_procent.."")
        
        sadd_yy = sadd_yy + 18
    end
    if ui.find("Aimbot", "Aimbot", "Double Tap"):get(0) then ----------------------------------------------------------------------------------------------
        render.rect(vector(pos.x-48.5+PEREKLYCHATEL,pos.y+12 + sadd_yy), vector(pos.x-28+PEREKLYCHATEL, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.rect(vector(pos.x-38+PEREKLYCHATEL,pos.y+16 + sadd_yy), vector(pos.x-33+PEREKLYCHATEL, pos.y+21 + sadd_yy), color(255,255,255, 255), 3) -- circle
        render.texture(image_on, vector(pos.x-46.5+PEREKLYCHATEL, pos.y+10.5 + sadd_yy), color(225,225,225,255))

        render.rect(vector(pos.x-55+pricel_aah,pos.y+12 + sadd_yy), vector(pos.x+10+pricel_aah, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.text(fonts.museosans, vector(pos.x-22+pricel_aah, pos.y+11.5 + sadd_yy), color(255,255,255,255), "c", "Double Tap")
        
        sadd_yy = sadd_yy + 18
        end
    if ui.find("Aimbot", "Aimbot", "Hide Shots"):get(0) then
        render.rect(vector(pos.x-48.5+PEREKLYCHATEL_0,pos.y+12 + sadd_yy), vector(pos.x-28+PEREKLYCHATEL_0, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.rect(vector(pos.x-38+PEREKLYCHATEL_0,pos.y+16 + sadd_yy), vector(pos.x-33+PEREKLYCHATEL_0, pos.y+21 + sadd_yy), color(255,255,255, 255), 3) -- circle
        render.texture(image_on, vector(pos.x-46.5+PEREKLYCHATEL_0, pos.y+10.5 + sadd_yy), color(255,255,255,255))

        render.rect(vector(pos.x-55+pricel_aah_2,pos.y+12 + sadd_yy), vector(pos.x+9+pricel_aah_2, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.text(fonts.museosans, vector(pos.x-22+pricel_aah_2, pos.y+11.5 + sadd_yy), color(255,255,255,255), "c", "Hide Shots")

        sadd_yy = sadd_yy + 18
    end
    if ui.find("Aimbot", "Aimbot", "Min. damage override"):get(0) then
        render.rect(vector(pos.x-49+DMG_0,pos.y+12 + sadd_yy), vector(pos.x-28+DMG_0, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        --render.rect(vector(pos.x-48.5+DMG_0,pos.y+12 + sadd_yy), vector(pos.x-28+DMG_0, pos.y+25 + sadd_yy), color(15,15,15, 27),5)--old
        --render.rect(vector(pos.x-38+DMG_0,pos.y+16 + sadd_yy), vector(pos.x-33+DMG_0, pos.y+21 + sadd_yy), color(255,255,255, 255), 3) -- circle
        --render.texture(image_on, vector(pos.x-46.5+DMG_0, pos.y+10.5 + sadd_yy), color(255,255,255,255))

        render.rect(vector(pos.x-55+anim_dmg_pr,pos.y+12 + sadd_yy), vector(pos.x+19+anim_dmg_pr, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.text(fonts.museosans, vector(pos.x-18+anim_dmg_pr, pos.y+11.5 + sadd_yy), color(255,255,255,255), "c", "Min damage")

        if not globals.is_in_game then 
            render.text(fonts.museosans, vector(pos.x-38+DMG_0, pos.y+12.5 + sadd_yy), color(255,255,255,255), "c", "28")
        else
            render.text(fonts.museosans, vector(pos.x-38+DMG_0, pos.y+12.5 + sadd_yy), color(255,255,255,255), "c", dmg.."")
        end
        sadd_yy = sadd_yy + 18
    end
    if ui.find("Aimbot", "Aimbot", "Peek Assist key"):get(0) then
        render.rect(vector(pos.x-48.5+PEEK_0,pos.y+12 + sadd_yy), vector(pos.x-28+PEEK_0, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.rect(vector(pos.x-38+PEEK_0,pos.y+16 + sadd_yy), vector(pos.x-33+PEEK_0, pos.y+21 + sadd_yy), color(255,255,255, 255), 3) -- circle
        render.texture(image_on, vector(pos.x-46.5+PEEK_0, pos.y+10.5 + sadd_yy), color(255,255,255,255))

        render.rect(vector(pos.x-55+anim_peek_pr,pos.y+12 + sadd_yy), vector(pos.x+12+anim_peek_pr, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.text(fonts.museosans, vector(pos.x-21+anim_peek_pr, pos.y+11.5 + sadd_yy), color(255,255,255,255), "c", "Peek Assist")

        sadd_yy = sadd_yy + 18
    end
    if fd_on then ----------------------------------------------------------------------------------------------
        render.rect(vector(pos.x-48.5+FD_0,pos.y+12 + sadd_yy), vector(pos.x-26+FD_0, pos.y+26 + sadd_yy), color(15,15,15, 27),5)
        render.rect(vector(pos.x-38+FD_0,pos.y+16 + sadd_yy), vector(pos.x-33+FD_0, pos.y+21 + sadd_yy), color(255,255,255, 255), 3) -- circle
        render.texture(image_on, vector(pos.x-46.5+FD_0, pos.y+10.5 + sadd_yy), color(225,225,225,255))

        render.rect(vector(pos.x-55+anim_fd_pr,pos.y+12 + sadd_yy), vector(pos.x+15+anim_fd_pr, pos.y+25 + sadd_yy), color(15,15,15, 27),5)
        render.text(fonts.museosans, vector(pos.x-20+anim_fd_pr, pos.y+11.5 + sadd_yy), color(255,255,255,255), "c", "Duck Assist")
        
        sadd_yy = sadd_yy + 18
        end
end
client.add_callback("render", function()
if is_rendering_rect then render.rect(render.screen_size(), vector(0, 0), color(bg_color_anim, bg_color_anim, bg_color_anim, bg_alpha_anim)) end
keybinds()
end)
