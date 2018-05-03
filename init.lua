local digits = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0"}
local base_chars = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
    "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
}
local special_chars = {
    "!", "#", "$", "%", "&", "(", ")", "*", "+", ",", "-", ".", "/", ":", ";",
    "<", "=", ">", "?", "@", "'", '"'
}
local german_chars = {"Ä", "Ö", "Ü", "ß"}
local cyrillic_chars = {
    "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н",
    "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь",
    "Э", "Ю", "Я"
}
local characters = {}

ehlphabet = {}
ehlphabet.path = minetest.get_modpath(minetest.get_current_modname())

local function table_merge(t1, t2)
    for k, v in ipairs(t2) do
       table.insert(t1, v)
    end
    return t1
end

local function is_multibyte(ch)
    local byte = ch:byte()
    return (195 == byte) or (208 == byte) or (209 == byte)
end

table_merge(characters, base_chars)
table_merge(characters, digits)
table_merge(characters, special_chars)
table_merge(characters, german_chars)
table_merge(characters, cyrillic_chars)

local create_alias = true

-- generate all available blocks
for _, name in ipairs(characters) do
    local desc = "The '" .. name .. "' Character"
    local byte = name:byte()
    local mb = is_multibyte(name)
    local file, key

    if mb then
        mb = byte
        byte = name:byte(2)
        key = "ehlphabet:" .. mb .. byte
        file = ("%03d_%03d"):format(mb, byte)
    else
        key = "ehlphabet:" .. byte
        file = ("%03d"):format(byte)
    end

    minetest.register_node(
        key,
        {
            description = "Ehlphabet Block '" .. name .. "'",
            tiles = {"ehlphabet_" .. file .. ".png"},
	    paramtype2 = "facedir",      -- neu
            on_rotate = screwdriver.rotate_simple ,   -- neu
            is_ground_content = false,   --neu
            groups = {cracky = 3, not_in_creative_inventory = 1, not_in_crafting_guide = 1}
        }
    )
    minetest.register_craft({type = "shapeless", output = "ehlphabet:block", recipe = {key}})

    if create_alias then
        minetest.register_alias("abjphabet:" .. name, key)
    end

    -- deactivate alias creation on last latin character
    if name == "Z" then
        create_alias = false
    end
end

minetest.register_node(
    "ehlphabet:machine",
    {
        description = "Letter Machine",
        tiles = {
            "ehlphabet_machine_top.png",
            "ehlphabet_machine_bottom.png",
            "ehlphabet_machine_side.png",
            "ehlphabet_machine_side.png",
            "ehlphabet_machine_back.png",
            "ehlphabet_machine_front.png"
        },
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {cracky = 2},

        -- "Can you dig it?" -Cyrus
        can_dig = function(pos, player)
            local meta = minetest.env:get_meta(pos)
            local inv = meta:get_inventory()
            if not inv:is_empty("input") or not inv:is_empty("output") then
                if player then
                    minetest.chat_send_player(
                        player:get_player_name(),
                        "You cannot dig the Letter Machine with blocks inside"
                    )
                end -- end if player
                return false
            end -- end if not empty
            return true
        end, -- end can_dig function

        after_place_node = function(pos, placer)
            local meta = minetest.env:get_meta(pos)
        end,

        on_construct = function(pos)
            local meta = minetest.env:get_meta(pos)
            meta:set_string(
                "formspec",
                "invsize[8,6;]" ..
                "field[3.8,.5;1,1;lettername;Letter;]" ..
                "list[current_name;input;2.5,0.2;1,1;]" ..
                "list[current_name;output;4.5,0.2;1,1;]" ..
                "list[current_player;main;0,2;8,4;]" ..
                "button[2.54,-0.25;3,4;name;Blank -> Letter]"
            )
            local inv = meta:get_inventory()
            inv:set_size("input", 1)
            inv:set_size("output", 1)
        end,

        on_receive_fields = function(pos, formname, fields, sender)
            local meta = minetest.env:get_meta(pos)
            local inv = meta:get_inventory()
            local inputstack = inv:get_stack("input", 1)
            local ch = fields.lettername

            if ch ~= nil and inputstack:get_name() == "ehlphabet:block" then
                local mb = is_multibyte(ch)
                local key = mb and (ch:byte(1) .. ch:byte(2)) or ch:byte()
                for _, v in pairs(characters) do
                    if v == ch then
                        local give = {}
                        give[1] = inv:add_item("output", "ehlphabet:" .. key)
                        inputstack:take_item()
                        inv:set_stack("input", 1, inputstack)
                        break
                    end
                end
            end
        end
    }
)

--  Alias  (Och_Noe 20180124)
minetest.register_alias("abjphabet:machine", "ehlphabet:machine")
--

minetest.register_node(
    "ehlphabet:block",
    {
        description = "Ehlphabet Block (blank)",
        tiles = {"ehlphabet_000.png"},
        groups = {cracky = 3}
    }
)

--RECIPE: blank blocks
minetest.register_craft({
    output = "ehlphabet:block 8",
    recipe = {
        {"default:paper", "default:paper", "default:paper"},
        {"default:paper", "", "default:paper"},
        {"default:paper", "default:paper", "default:paper"}
    }
})

--RECIPE: build the machine!
minetest.register_craft({
    output = "ehlphabet:machine",
    recipe = {
        {"default:stick", "default:coal_lump", "default:stick"},
        {"default:coal_lump", "ehlphabet:block", "default:coal_lump"},
        {"default:stick", "default:coal_lump", "default:stick"}
    }
})

--RECIPE: craft unused blocks back into paper
minetest.register_craft({
    output = "default:paper",
    recipe = {"ehlphabet:block"},
    type = "shapeless"
})
