-- A file that holds all the functions this mod uses for gui creation.

function resetAndReloadUI(player)
	local lGui = player.gui.left
	local cGui = player.gui.center

	-- Clear the existing mod's GUI
	if cGui["FactCalc-main-flow"] then
		cGui["FactCalc-main-flow"].destroy()
	end

	if lGui["FactCalc-open-calculator"] then
		lGui["FactCalc-open-calculator"].destroy()
	end

	-- Add the button to open main interface
	lGui.add{
		type = "sprite-button",
		tooltip = "Click to open Factory Calculator.",
		name = "FactCalc-open-calculator",
		sprite = "FactCalc-main-sprite",
		style = "FactCalc_small_buttons"
	}

	constructMainWindow(cGui.add{name = "FactCalc-main-flow", type = "flow", direction = "horizontal"})
end

function constructMainWindow(gui)
	local frame = gui.add{
		name = "FactCalc-settings-frame",
		type = "frame",
		caption = "Settings",
		direction = "vertical"
	}
	frame.visible = false
	local frameResult = gui.add{
		name = "FactCalc-result-frame",
		type = "frame",
		caption = "Calculation result:",
		direction = "horizontal"
	}
	frameResult.visible = false

	local chooseItem = frame.add{
		name = "FactCalc-item-choose",
		type = "flow",
		direction = "horizontal"
	}
	chooseItem.add{
		name = "FactCalc-item-label",
		type = "label",
		caption = "Recipe:"
	}
	chooseItem.add{
		name = "FactCalc-chooseItem",
		type = "choose-elem-button",
		elem_type = "recipe"
	}

	frame.add{
		name = "FactCalc-count-label",
		type = "label",
		caption = "Count:"
	}

	local countNumber = frame.add{
		name = "FactCalc-count-number",
		type = "flow",
		direction = "horizontal"
	}
	countNumber.add{
		name = "FactCalc-radiobutton-number",
		type = "radiobutton",
		state = true
	}
	local TextfieldNumber = countNumber.add{
		name = "FactCalc-textfield-number",
		type = "textfield",
		text = "1"
	}
	TextfieldNumber.style.width = 40
	countNumber.add{
		name = "FactCalc-slash-number",
		type = "label",
		caption = "/"
	}
	countNumber.add{
		name = "FactCalc-secmin-number",
		type = "button",
		caption = "sec"
	}

	local countBelt = frame.add{
		name = "FactCalc-count-belt",
		type = "flow",
		direction = "horizontal"
	}
	countBelt.add{
		name = "FactCalc-radiobutton-belt",
		type = "radiobutton",
		state = false
	}
	countBelt.add{
		name = "FactCalc-label-belt",
		type = "label",
		caption = "Output belt:"
	}
	countBelt.add{
		name = "FactCalc-choose-belt",
		type = "choose-elem-button",
		elem_type = "item",
		item = "transport-belt",
		tooltip = "Please, select only belts."
	}
	countBelt.add{
		name = "FactCalc-fullhalf-belt",
		type = "button",
		caption = "full"
	}

	local countAssembler = frame.add{
		name = "FactCalc-count-assembler",
		type = "flow",
		direction = "horizontal"
	}
	countAssembler.add{
		name = "FactCalc-radiobutton-assembler",
		type = "radiobutton",
		state = false
	}
	countAssembler.add{
		name = "FactCalc-choose-assembler",
		type = "choose-elem-button",
		elem_type = "item",
		item = "assembling-machine-1",
		tooltip = "Please, select only assembling machines."
	}
	countAssembler.add{
		name = "FactCalc-X-assembler",
		type = "label",
		caption = "X"
	}
	local TextfieldAssembler = countAssembler.add{
		name = "FactCalc-textfield-assembler",
		type = "textfield",
		text = "1"
	}
	TextfieldAssembler.style.width = 40

	local itemsTable = frame.add{
		name = "FactCalc-items-table",
		type = "table",
		column_count = 4,
		caption = "Input resources (items)"
	}
	local fluidsTable = frame.add{
		name = "FactCalc-fluids-table",
		type = "table",
		column_count = 4,
		caption = "Input resources (fluids)"
	}

	for i = 0, 7, 1 do
		itemsTable.add{
			name = "FactCalc-choose-resource-item-" .. i,
			type = "choose-elem-button",
			elem_type = "item",
			tooltip = "Select items that will come into this factory"
		}
		fluidsTable.add{
			name = "FactCalc-choose-resource-fluid-" .. i,
			type = "choose-elem-button",
			elem_type = "fluid",
			tooltip = "Select fluids that will come into this factory"
		}
	end

	local buttonsFlow = frame.add{
		name = "FactCalc-buttons-flow",
		type = "flow",
		direction = "horizontal"
	}
	buttonsFlow.add{
		name = "FactCalc-calculate",
		type = "sprite-button",
		tooltip = "Left mouse button click to calculate",
		sprite = "FactCalc-main-sprite",
		style = "FactCalc_small_buttons"
	}
	buttonsFlow.add{
		name = "FactCalc-recalculate",
		type = "sprite-button",
        tooltip = "Left mouse button click to recalculate",
        sprite = "FactCalc-recalc-sprite",
        style = "FactCalc_small_buttons"
	}

end
