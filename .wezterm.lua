local wezterm = require("wezterm")
local config = wezterm.config_builder()

local io = require("io")
local os = require("os")
local brightness = 0.03
local act = wezterm.action
local tabs = {
  -- Position the tab bar at the bottom of the window
  tab_bar_at_bottom = true,

  -- Controls visibility of the tab bar when only one tab exists
  hide_tab_bar_if_only_one_tab = false,

  -- Maximum width of each tab in cells
  tab_max_width = 32,

  -- Whether to restore zoom level when switching panes
  unzoom_on_switch_pane = true,
  
}

wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-status')
  .apply_to_config(config, {
    cells = {
      -- Battery status with percentage
      battery = {
        enabled = true,
      },
      -- Date and time with more detailed format
      date = {
        enabled = true,
        format = "%a %b %d %H:%M"
      }
    }
  })

wezterm.plugin
  .require('https://github.com/yriveiro/wezterm-tabs')
  .apply_to_config(config, tabs)


-- image setting
local user_home = os.getenv("HOME")
local background_folder = user_home .. "/.config/nvim/bg"
local function pick_random_background(folder)
    local handle = io.popen('ls "' .. folder .. '"')
    if handle ~= nil then
        local files = handle:read("*a")
        handle:close()

        local images = {}
        for file in string.gmatch(files, "[^\n]+") do
            table.insert(images, file)
        end

        if #images > 0 then
            return folder .. "/" .. images[math.random(#images)]
        else
            return nil
        end
    end
end

config.window_background_image_hsb = {
    -- Darken the background image by reducing it
    brightness = brightness,
    hue = 1.0,
    saturation = 0.8,
}

-- default background
-- local bg_image = user_home .. "/.config/nvim/bg/bg.jpg"

-- config.window_background_image = bg_image
-- end image setting

-- window setting
config.window_background_opacity = 0.90
config.macos_window_background_blur = 85
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

config.color_scheme = 'Material (terminal.sexy)'
config.font = wezterm.font('D2CodingLigature Nerd Font', { weight = "Medium", stretch = "Expanded" })
config.font_size = 10
config.window_decorations = "RESIZE"


-- tab
-- config.enable_tab_bar = false
-- config.keys = {}
-- config.keys = {
--   { key = '{', mods = 'ALT', action = act.ActivateTabRelative(-1) },
--   { key = '}', mods = 'ALT', action = act.ActivateTabRelative(1) },
-- }


-- keys
config.keys = {
    {
        key = "b",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            bg_image = pick_random_background(background_folder)
            if bg_image then
                window:set_config_overrides({
                    window_background_image = bg_image,
                })
                wezterm.log_info("New bg:" .. bg_image)
            else
                wezterm.log_error("Could not find bg image")
            end
        end),
    },
    {
        key = "L",
        mods = "CTRL|SHIFT",
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
    {
        key = ">",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            brightness = math.min(brightness + 0.01, 1.0)
            window:set_config_overrides({
                window_background_image_hsb = {
                    brightness = brightness,
                    hue = 1.0,
                    saturation = 0.8,
                },
                window_background_image = bg_image
            })
        end),
    },
    {
        key = "<",
        mods = "CTRL|SHIFT",
        action = wezterm.action_callback(function(window)
            brightness = math.max(brightness - 0.01, 0.01)
            window:set_config_overrides({
                window_background_image_hsb = {
                    brightness = brightness,
                    hue = 1.0,
                    saturation = 0.8,
                },
                window_background_image = bg_image
            })
        end),
    },
}


-- hyperlinks
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[\b[tt](\d+)\b]],
  format = 'https://example.com/tasks/?t=$1',
})
table.insert(config.hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = 'https://www.github.com/$1/$3',
})


-- others
config.default_cursor_style = "BlinkingUnderline"
config.cursor_thickness = 2
return config
