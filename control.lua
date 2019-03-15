-- Require files
require("gui_creation")
require("gui_actions")
require("func")

-- "Global" variables
FactCalcData = {}
FactCalcSettings = {}
recursion_counter = 0

-- Destroy GUI (if exist) and draw a new
script.on_init(
function()
	for i, player in pairs(game.players) do
		resetAndReloadUI(player)
	end
end
)

script.on_event(defines.events.on_player_created,
function(e)
	debugger.start("FactCalc.log", false)          -- debugger init
	resetAndReloadUI(game.players[e.player_index]) -- Redraw GUI
	-- "Welcome" and a small tutorial
	game.players[e.player_index].print("Welcome to Factory Calculator, to open Calculator press button at the upper left")
	game.players[e.player_index].print("Mod is in early beta, report any issues on the GitHub or Factorio mod page")
end
)

-- Main function
function calculateFactory(player)
	debugger.write("Start of log\nStart of calculateFactory()")
	recursion_counter = 0
	FactCalcSettings = {}
	local gui = player.gui.center["FactCalc-main-flow"]["FactCalc-result-frame"]
	local settingsGui = player.gui.center["FactCalc-main-flow"]["FactCalc-settings-frame"]
	local beltSpeedMultiplier = (40 / 0.09375) -- Calculating belt throughput multiplier depending on express transport belt
	local minsSecs = "minutes"
	local input_items = {}
	local input_fluids = {}

	debugger.write("Done setting up and calculating util variables. Setting up and calculating input and output variables")
	for i = 0, 7, 1 do
		if settingsGui["FactCalc-items-table"]["FactCalc-choose-resource-item-"..i].elem_value ~= nil then
			table.insert(input_items, game.item_prototypes[settingsGui["FactCalc-items-table"]["FactCalc-choose-resource-item-"..i].elem_value])
		end
	end
	for i = 0, 7, 1 do
		if settingsGui["FactCalc-fluids-table"]["FactCalc-choose-resource-fluid-"..i].elem_value ~= nil then
			table.insert(input_fluids, game.fluid_prototypes[settingsGui["FactCalc-fluids-table"]["FactCalc-choose-resource-fluid-" .. i].elem_value])
		end
	end

	local outputRecipe = game.recipe_prototypes[settingsGui["FactCalc-item-choose"]["FactCalc-chooseItem"].elem_value]

	local outputValue = 0

	debugger.write("Calculating output craft value")
	if settingsGui["FactCalc-count-number"]["FactCalc-radiobutton-number"].state then
		--if 		settingsGui["FactCalc-count-number"]["FactCalc-addition-number"]["FactCalc-flipbutton-number"].style.name == "flip_button_left" then
			outputValue = tonumber(settingsGui["FactCalc-count-number"]["FactCalc-textfield-number"].text)
			minsSecs = "seconds"
		--[[elseif  settingsGui["FactCalc-count-number"]["FactCalc-addition-number"]["FactCalc-flipbutton-number"].style.name == "flip_button_right" then
			outputValue = tonumber(settingsGui["FactCalc-count-number"]["FactCalc-textfield-number"].text) * 60
			minsSecs = "minutes"
		end]]

	elseif settingsGui["FactCalc-count-belt"]["FactCalc-radiobutton-belt"].state then
		if game.item_prototypes[settingsGui["FactCalc-count-belt"]["FactCalc-choose-belt"].elem_value].place_result.type == "transport-belt" then
			outputValue = game.item_prototypes[settingsGui["FactCalc-count-belt"]["FactCalc-choose-belt"].elem_value].place_result.belt_speed * beltSpeedMultiplier
			if settingsGui["FactCalc-count-belt"]["FactCalc-addition-belt"]["FactCalc-flipbutton-belt"].style.name == "flip_button_right" then outputValue = outputValue / 2 end
		else
			player.print("Please, choose only transport belt items. If you selected belt item and this error message still appear, please report about this on mod page or on GitHub.")
		end

	elseif settingsGui["FactCalc-count-assembler"]["FactCalc-radiobutton-assembler"].state then
		outputValue = tonumber(settingsGui["FactCalc-count-assembler"]["FactCalc-textfield-assembler"].text) * game.item_prototypes[settingsGui["FactCalc-count-assembler"]["FactCalc-choose-assembler"].elem_value].place_result.crafting_speed / outputRecipe.energy

	else
		debugger.write("[ERROR] Error with radiobuttons, return.")
		player.print('Error with radiobuttons. Please leave a report on mod page or on GitHub.')
		resetAndReloadUI(player)
		return
	end

	debugger.write("Setting up FactCalcSettings")
	FactCalcSettings = {
		main = {
			output = {
				recipe = outputRecipe,
				count = outputValue
			},
			input = {
				items = input_items,
				fluids = input_fluids
			},
			time_units = minsSecs,
			input_count = {
				item = {},
				fluid = {}
			}
		}
	}

	debugger.write("Setting up FactCalcData")
	FactCalcData = {
		inputs = {}
	}

	debugger.write("Creating input count variables.")
	for i, ingredient in pairs(input_items) do
		debugger.write("    Item: "..ingredient.name..", i: "..i)
		FactCalcSettings.main.input_count.item[ingredient.name] = 0
	end
	for i, ingredient in pairs(input_fluids) do
		debugger.write("    Fluid: "..ingredient.name..", i: "..i)
		FactCalcSettings.main.input_count.fluid[ingredient.name] = 0
	end

	--Creating workframe GUI element
	local workframe = gui.add{
		name = "FactCalc-workframe",
		type = "scroll-pane",
		horizontal_scroll_policy = "auto",
		vertical_scroll_policy = "auto"
	}

	debugger.write("All preparations done. Calling build_recipes_tree()")
	build_recipes_tree(workframe, {outputRecipe}, outputValue, "0")
	debugger.write("Main build_recipes_tree() finished.\nEnd of log.\n\n\n")

	--Calculate FactCalcSettings input data basing on FactCalcData
	for i, entry in pairs(FactCalcData.inputs) do
		FactCalcSettings.main.input_count[entry.type][entry.name] = FactCalcSettings.main.input_count[entry.type][entry.name] + entry.count
	end

	--Creating stats GUI
	local stats_place = gui.add{
		name = "FactCalc-resultStatistics",
		type = "frame",
		direction = "vertical",
		caption = "Stats:"
	}

	--Items
	local stats_items = stats_place.add{
		name = "FactCalc-stats-items-table",
		type = "table",
		column_count = 2,
		caption = "Items",
		draw_horizontal_lines = true
	}
	for i, count in pairs(FactCalcSettings.main.input_count.item) do
		stats_items.add{
			name = "FactCalc-input-stats-item-sprite-"..i,
			type = "sprite",
			sprite = "item/"..i
		}
		stats_items.add{
			name = "FactCalcSettings-input-stats-items-count-"..i,
			type = "label",
			caption = "X"..count
		}
	end

	--Fluids
	local stats_fluids = stats_place.add{
		name = "FactCalc-stats-fluids-table",
		type = "table",
		column_count = 2,
		caption = "Fluids",
		draw_horizontal_lines = true
	}
	for i, count in pairs(FactCalcSettings.main.input_count.fluid) do
		stats_items.add{
			name = "FactCalc-input-stats-fluid-sprite-"..i,
			type = "sprite",
			sprite = "item/"..i
		}
		stats_items.add{
			name = "FactCalcSettings-input-stats-fluid-count-"..i,
			type = "label",
			caption = "X"..count
		}
	end

	--Make finished GUI visible
	gui.visible = true
end

--Grow up this tree
function build_recipes_tree(gui, recipes, craft_count, index)
	debugger.write("Started cycle with index: "..index) -- Log another cycle...
	local player = game.players[gui.player_index]       -- Oftenly used variable

	-- "The Big Kostyl'"
	recursion_counter = recursion_counter + 1
	if recursion_counter > settings.get_player_settings(player)["FactCalc-max-recursion"].value then
		debugger.write(settings.get_player_settings(player)["FactCalc-max-recursion"].value.." cycles done. exiting build_recipes_tree().")
		player.print("[DEBUG][FactoryCalculator] "..settings.get_player_settings(player)["FactCalc-max-recursion"].value.." cycles done. Calling return.")
		player.print("Set higher number if calculation stopped before end")
		return
	end -- Thanks _romanchik_ for this kostyl'

	local assembler_speed = 0.75 -- TODO: Make assembler choice

	debugger.write("Getting recipe") -- GOTTA DEBUG EVERYTHING

	-- Getting recipe
	local recipe = recipes[1]
	debugger.write("Table length: "..tablelength(recipes))
	debugger.write("Recipe got succesfully")

	-- Calculating count of assemblers and output items. Intrenally this step named "calculating"
	local shown_count = 0
	local assembler_count = craft_count * recipe.energy / assembler_speed / recipe.products[1].amount -- Count of assemblers
	-- Calculate numbers depending on player's settings
	if settings.get_player_settings(player)["FactCalc-ceil-numbers"].value == "calculte-ceil" then -- Calculate with ceiled numbers
		assembler_count = math.ceil(assembler_count)
		shown_count = assembler_count
	elseif settings.get_player_settings(player)["FactCalc-ceil-numbers"].value == "show-ceil" then -- Only show ceiled numbers
		shown_count = math.ceil(assembler_count)
	elseif settings.get_player_settings(player)["FactCalc-ceil-numbers"].value == "no-ceil" then   -- Show and use raw numbers
		shown_count = assembler_count
	else -- What if?
		debugger.write("Got wrong ceil-numbers setting value at calculating stage. Applying default.")
		shown_count = math.ceil(assembler_count)
	end

	-- Logging these variables case they are important or calculations
	debugger.write("Stage: calculating, index: "..index.."\nCalculations: assembler_count = math.ceil(("..craft_count.." * "..recipe.energy..") / "..assembler_speed.." / "..recipe.products[1].amount..") = "..assembler_count.."\nRecipe name: "..recipe.name..", craft_count: "..craft_count)

	craft_count = (assembler_count * assembler_speed) / recipe.energy * recipe.products[1].amount --Calulate craft count
	player.print("[DEBUG][FactoryCalculator] index: "..index..", stage: calculating, recipe name: "..recipe.name..", craft_count: "..craft_count) -- Debug into game chat for easy in-game debug

	-- Create GUI
	local workplace = gui.add {
		name = "FactCalc-workplace-" .. index,
		type = "table",
		column_count = 4
	}
	local ingredients_flow = workplace.add{
		name = "FactCalc-ingredients-flow-" .. index,
		type = "flow",
		direction = "vertical"
	}
	local infoTable = workplace.add{
		name = "FactCalc-info-table" .. index,
		type = "table",
		column_count = 2,
		draw_horizontal_lines = true
	}
	workplace.add{
		name = "FactCalc-arrow-" .. index,
		type = "sprite",
		sprite = "FactCalc-arrow-sprite"
	}
	infoTable.add{
		name = "FactCalc-assembler-sprite-" .. index,
		type = "sprite",
		sprite = "entity/assembling-machine-2"
	}
	infoTable.add{
		name = "FactCalc-assembler-count-label-" .. index,
		type = "label",
		caption = "X" .. shown_count
	}
	infoTable.add{
		name = "FactCalc-recipe-sprite-" .. index,
		type = "sprite",
		sprite = "recipe/" .. recipe.name
	}
	infoTable.add{
		name = "FactCalc-recipe-count-label-" .. index,
		type = "label",
		caption = "X" .. craft_count
	}

	debugger.write("gui creation done")

	-- Next "branches"
	for ingredient_index, ingredient in pairs(recipe.ingredients) do
		local craft_count_ingredient = craft_count * ingredient.amount -- Craft count for current ingredient
		local items_table
		local input_prototypes

		-- Set variables depending on ingredient type
		if ingredient.type == "item" then                    -- item
			items_table = FactCalcSettings.main.input.items
			input_prototypes = game.item_prototypes
		elseif ingredient.type == "fluid" then               -- fluid
			items_table = FactCalcSettings.main.input.fluids
			input_prototypes = game.fluid_prototypes
		else                                                 -- What if?
			debugger.write("Unknown ingredient type: "..ingredient.type.." at "..index.."-"..ingredient_index.."-"..ingredient_index)
			player.print("An error occured while calculating. Please leave a report on mod page and add log-file from script-output folder (script-output/FactCalc.log).")
			return
		end

		-- Decide what ingrediet is this: input or mid-ingredient
		if has_value(items_table, ingredient.name) then
			debugger.write("Got input ingredient. Index: "..index.."-"..ingredient_index..", ingredient name: "..ingredient.name)
			recipes_tree_end(ingredient, craft_count_ingredient, index.."-"..ingredient_index, ingredients_flow) -- End of "branch"
		else
			debugger.write("Got mid-ingredient. Continuing tree. Index: "..index.."-"..ingredient_index..", ingredient name: "..ingredient.name)
			build_recipes_tree(ingredients_flow, get_recipes_by_result(ingredient.name), craft_count_ingredient, index.."-"..ingredient_index) -- Continue tree
		end
	end

	-- Log end of function
	debugger.write("Cycle with index "..index.." ended.")
end

function recipes_tree_end(ingredient, count, index, gui)
	-- Log start of the function
	debugger.write("Started end function. Index: "..index..", ingredient: "..ingredient.name)

	-- Get ingredient sprite
	local ingredient_sprite = ""

	-- Get ingredient type
	if ingredient.type == "fluid" then ingredient_sprite = "fluid/"..ingredient.name else ingredient_sprite = "item/"..ingredient.name end

	-- Create GUI
	local workplace = gui.add {
		name = "FactCalc-end-" .. index,
		type = "flow",
		direction = "horizontal"
	}
	workplace.add{
		name = "FactCalc-end-ingredient-sprite-"..index,
		type = "sprite",
		sprite = ingredient_sprite
	}
	workplace.add{
		name = "FactCalc-end-count-label-"..index,
		type = "label",
		caption = "X"..count
	}
	workplace.add{
		name = "FactCalc-arrow-" .. index,
		type = "sprite",
		sprite = "FactCalc-arrow-sprite"
	}
	-- Remember index and count. Used in recalcultions
	table.insert(FactCalcData.inputs, {index = index, count = count, name = ingredient.name, type = ingredient.type})

	-- Log end of the function
	debugger.write("End fucntion with index "..index.." ended")
end
