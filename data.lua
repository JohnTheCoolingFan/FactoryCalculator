data:extend({
    {
        type="sprite",
        name="FactCalc-main-sprite",
        filename = "__core__/graphics/no-building-material-icon.png",
        priority = "extra-high",
        width = 64,
        height = 64,
    },
    {
        type="sprite",
        name="FactCalc-arrow-sprite",
        filename = "__core__/graphics/icons/go-to-minibutton-arrow.png",
        priority = "extra-high",
        width = 16,
        height = 16,
    },
    {
        type="sprite",
        name="FactCalc-recalc-sprite",
        filename = "__core__/graphics/icons/reset.png",
        priority = "extra-high",
        width = 32,
        height = 32,
    }
})

data.raw["gui-style"]["default"]["FactCalc_buttons"] = {
    type="button_style",
    parent="button",
    maximal_height = 65,
    minimal_height = 65,
    maximal_width = 65,
    minimal_width = 65,
    top_padding = 0,
    bottom_padding = 0,
    right_padding = 0,
    left_padding = 0,
    left_click_sound = {
        {
            filename = "__core__/sound/gui-click.ogg",
            volume = 1
        }
    },
    right_click_sound = {
        {
            filename = "__core__/sound/gui-click.ogg",
            volume = 1
        }
    }
}

data.raw["gui-style"]["default"]["FactCalc_small_buttons"] = {
    type="button_style",
    parent="button",
    maximal_height = 45,
    minimal_height = 45,
    maximal_width = 45,
    minimal_width = 45,
    top_padding = 0,
    bottom_padding = 0,
    right_padding = 0,
    left_padding = 0,
    left_click_sound = {
        {
            filename = "__core__/sound/gui-click.ogg",
            volume = 1
        }
    },
    right_click_sound = {
        {
            filename = "__core__/sound/gui-click.ogg",
            volume = 1
        }
    }
}
