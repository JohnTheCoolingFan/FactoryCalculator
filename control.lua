--require
require("gui_creation")
require("gui_actions")
require("func")

--important variables
FactCalcSettings = {}
recursion_counter = 0



--destroy gui (if exist) and draw gui
script.on_init(
function()
    for i, player in pairs(game.players) do
        resetAndReloadUI(player)
	end
end
)

--"welcome" message
script.on_event(defines.events.on_player_created,
function(e)
	--starting debugger
	debugger.start("FactCalc.log", false)
	resetAndReloadUI(game.players[e.player_index])
	game.players[e.player_index].print("Welcome to Factory Calculator, to open Calculator press button at the upper left")
	game.players[e.player_index].print("Mod is in early beta, please read the tooltips and DON'T SELECT FLUIDS and DON'T SELECT MULTIPLE-OUTPUT RECIPES (like uranium or oil). Thanks.")
end
)

--main function
function calculateFactory(player)
	debugger.write("Called function calculateFactory()")
	recursion_counter = 0
	FactCalcSettings = {}
	local gui = player.gui.center["FactCalc-main-flow"]["FactCalc-result-frame"]
	local settingsGui = player.gui.center["FactCalc-main-flow"]["FactCalc-settings-frame"]
	local beltSpeedMultiplier = (40 / 0.09375) -- Calculating belt throughput multiplier depending on express transport belt
	local minsSecs = "minutes"
	local input_items = {}
	local input_fluids = {}
	
	debugger.write("Done setting up util variables. Setting input and output")
	for i = 0, 7, 1 do table.insert(input_items, get_prototype_by_name(game.item_prototypes, settingsGui["FactCalc-items-table"]["FactCalc-choose-resource-item-"..i].elem_value)) end
	for i = 0, 7, 1 do table.insert(input_fluids, get_prototype_by_name(game.fluid_prototypes, settingsGui["FactCalc-fluids-table"]["FactCalc-choose-resource-fluid-" .. i].elem_value)) end
	
	local outputRecipe = get_prototype_by_name(game.recipe_prototypes, settingsGui["FactCalc-item-choose"]["FactCalc-chooseItem"].elem_value)
	
	local outputValue = 0
	
	debugger.write("Calculating output craft value")
	if settingsGui["FactCalc-count-number"]["FactCalc-radiobutton-number"].state then
		if 		settingsGui["FactCalc-count-number"]["FactCalc-addition-number"]["FactCalc-flipbutton-number"].style.name == "flip_button_left" then
			outputValue = tonumber(settingsGui["FactCalc-count-number"]["FactCalc-textfield-number"].text)
			minsSecs = "seconds"
		elseif  settingsGui["FactCalc-count-number"]["FactCalc-addition-number"]["FactCalc-flipbutton-number"].style.name == "flip_button_right" then
			outputValue = tonumber(settingsGui["FactCalc-count-number"]["FactCalc-textfield-number"].text) * 60
			minsSecs = "minutes"
		end
	
	elseif settingsGui["FactCalc-count-belt"]["FactCalc-radiobutton-belt"].state then
		if get_prototype_by_name(game.item_prototypes, settingsGui["FactCalc-count-belt"]["FactCalc-choose-belt"].elem_value).place_result.type == "transport-belt" then
			outputValue = get_prototype_by_name(game.item_prototypes, settingsGui["FactCalc-count-belt"]["FactCalc-choose-belt"].elem_value).place_result.belt_speed * beltSpeedMultiplier
			
			if settingsGui["FactCalc-count-belt"]["FactCalc-addition-belt"]["FactCalc-flipbutton-belt"].style.name == "flip_button_right" then outputValue = outputValue / 2 end
		else
			player.print("Please, choose only transport belt items. If you selected belt item and this error message still appear, please report about this on mod page.")
		end
	
	elseif settingsGui["FactCalc-count-assembler"]["FactCalc-radiobutton-assembler"].state then
		outputValue = tonumber(settingsGui["FactCalc-count-assembler"]["FactCalc-textfield-assembler"].text) * get_prototype_by_name(game.item_prototypes, settingsGui["FactCalc-count-assembler"]["FactCalc-choose-assembler"].value).crafting_speed / outputRecipe.energy
	
	else
		debugger.write("[ERROR] Error with radiobuttons, return.")
		player.print('Error with radiobuttons. Please leave a report on mod page.')
		resetAndReloadUI(player)
		return
	end
	
	debugger.write("setting up FactCalcSettings")
	FactCalcSettings = {
		main = {
			name = "FactCalc-stats",
			output = {
				recipe = outputRecipe,
				count = outputValue
			},
			input = {
				items = input_items,
				fluids = input_fluids
			},
			time_units = minsSecs,
			input_count = {}
		},
		dropdowns = {}
	}
	
	for i = 0, 7, 1 do
		local ingredient = input_items[i]
		FactCalcSettings.main.input_count.items[ingredient.name].count = 0
	end
	for i = 0, 7, 1 do
		local ingredient = input_fluids[i]
		FactCalcSettings.main.input_count.fluids[ingredient.name].count = 0
	end
	
	local workframe = gui.add{
		name = "FactCalc-workframe",
		type = "scroll-pane",
		horizontal_scroll_policy = "auto",
		vertical_scroll_policy = "auto"
	}
	
	debugger.write("All preparings done. Calling build_recipes_tree()")
	build_recipes_tree(workframe, {outputRecipe}, outputValue, "0")
	debugger.write("build_recipes_tree() finished.\nEnd of log.\n\n\n")
	
	local statsPlace = gui.add{
		name = "FactCalc-resultStatistics",
		type = "frame",
		direction = "vertical",
		caption = "Stats:"
	}
	
	gui.style.visible = true
end

--The most important part. I hate it because it's not working as I want
function build_recipes_tree(gui, recipes, craftCount, index)
	debugger.write("Started build_recipe_tree(). Index: "..index)
	local player = game.players[gui.player_index]
	
	--"The Big Kostyl"
	recursion_counter = recursion_counter + 1
	if recursion_counter > settings.get_player_settings(player)["FactCalc-max-recursion"].value then
	debugger.write(settings.get_player_settings(player)["FactCalc-max-recursion"].value.." cycles done. exiting build_recipes_tree().")
	player.print("[DEBUG][FactoryCalculator] 100 cycles done. Calling return.")
	return
	end --thanks _romanchik_ for this костыль
	
	local assemblerSpeed = 0.75 -- In russian language this named "костыль". I need to make ability to choose assembler for each recipe...
	
	debugger.write("Getting recipe")
	--getting needed recipe
	local recipe = recipes[1]
	local mark_dropdown = tablelength(recipes) > 1
	local dropdown = {}
	local dropdown_index = 0
	debugger.write("table length: "..tablelength(recipes))
	if mark_dropdown then
		if FactCalcSettings.dropdowns["dropdown-"..index] ~= nil then
			recipe = FactCalcSettings.dropdowns["dropdown-"..index].recipes[FactCalcSettings.dropdowns["dropdown-"..index].selected + 1]
		else
			FactCalcSettings.dropdowns["dropdown-"..index] = {}
			FactCalcSettings.dropdowns["dropdown-"..index].selected = 0
			FactCalcSettings.dropdowns["dropdown-"..index].recipes = recipes
			dropdown = form_dropdown(recipes)
		end
		dropdown_index = FactCalcSettings.dropdowns["dropdown-"..index].selected
		debugger.write("dropdown_index: "..dropdown_index)
	elseif recipes == {} then
		debugger.write("[ERROR] Got null recipes at "..index)
		player.print("[ERROR][FactCalc] Got null recipes at "..index)
		return
	else recipe = recipes[1] end
	debugger.write("Recipe getting done.")
	
	--calculating
	local assemblerCount = math.ceil((craftCount * recipe.energy) / assemblerSpeed)
	craftCount = (assemblerCount * assemblerSpeed) / recipe.energy
	
	debugger.write("[DEBUG][FactoryCalculator] index: "..index..", stage: calculating, recipe name: "..recipe.name..", craftCount: "..craftCount..", dropdown_index: "..dropdown_index)
	player.print("[DEBUG][FactoryCalculator] index: "..index..", stage: calculating, recipe name: "..recipe.name..", craftCount: "..craftCount..", dropdown_index: "..dropdown_index)
	
	--gui creating
	local workplace = gui.add {
		name = "FactCalc-workplace-" .. index,
		type = "table",
		column_count = 4
	}
	local ingredientsFlow = workplace.add{
		name = "FactCalc-ingredients-flow-" .. index,
		type = "flow",
		direction = "vertical"
	}
	local infoFlow = workplace.add{
		name = "FactCalc-info-flow-" .. index,
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
		caption = "X" .. assemblerCount
	}
	infoTable.add{
		name = "FactCalc-recipe-sprite-" .. index,
		type = "sprite",
		sprite = "recipe/" .. recipe.name
	}
	infoTable.add{
		name = "FactCalc-recipe-count-label-" .. index,
		type = "label",
		caption = "X" .. craftCount
	}
	if mark_dropdown then
	dropdown_element = infoTable.add{
		name = "FactCalc-recipe-dropdown-"..index,
		type = "drop-down",
		items = dropdown,
		selected_index = dropdown_index
	}
	FactCalcSettings.dropdowns["dropdown-"..index].element = dropdown_element
	end
	debugger.write("gui creation done")
	
	local flag_input_item = true
	
	--next cycle
	for i, ingredient in pairs(recipe.ingredients) do
		craftCount = craftCount * ingredient.amount
		if ingredient.type == "item" then
			for _, item in pairs(FactCalcSettings.main.input.items) do
				debugger.write("index: "..index..", stage: next cycle, ingredient: item; "..ingredient.name)
				player.print("[DEBUG][FactoryCalculator] index: "..index..", stage: next cycle, ingredient: item; "..ingredient.name.."")
				if item and item.name == ingredient.name then
					local var = 0
					local flag, indexOfATable = has_valueSecond(FactCalcSettings.main.inputCount, item)
					if flag then
						var = FactCalcSettings.main.inputCount[indexOfATable].count
					end
					var = var + craftCount
					table.insert(FactCalcSettings.main.inputCount, {ingredient = item, count = var})
					debugger.write("Got input ingredient. Index: "..index..i)
					player.print("[DEBUG][FactoryCalculator] Got input ingredient. Index: "..index..i)
					
					flag_input_item = false
					break
				end
			end
			if flag_input_item then
				debugger.write("Not got input ingredient. Index: "..index..i..", before calling next cycle")
				player.print("[DEBUG][FactoryCalculator] Not got input ingredient. Index: "..index..i..", before calling next cycle")
				build_recipes_tree(ingredientsFlow, get_recipes_by_result(ingredient.name), craftCount, index.."-"..i)
				debugger.write("Not got input ingredient. Index: "..index..i..", after calling next cycle")
				player.print("[DEBUG][FactoryCalculator] Not got input ingredient. Index: "..index..i..", after calling next cycle")
			else
				
			end
		elseif ingredient.type == "fluid" then
			for _, fluid in pairs(FactCalcSettings.main.input.fluids) do
				debugger.write("index: "..index..", stage: next cycle, ingredient: fluid; "..ingredient.name)
				player.print("[DEBUG][FactoryCalculator] index: "..index..i..", stage: next cycle, ingredient: fluid; "..ingredient.name.."")
				if fluid and fluid.name == ingredient.name then
					local var = 0
					local flag, indexOfATable = has_valueSecond(FactCalcSettings.main.inputCount, fluid)
					if flag then
						var = FactCalcSettings.main.inputCount[indexOfATable].count
					end
					var = var + craftCount
					table.insert(FactCalcSettings.main.inputCount, {ingredient = fluid, count = var})
					game.write_file("FactCalc.log", "[DEBUG][FactoryCalculator] Got input ingredient. Index: "..index..i.."\n", true)
					player.print("[DEBUG][FactoryCalculator] Got input ingredient. Index: "..index)
					
					flag_input_item = false
					break
				end
			end
			if flag_input_item then
				debugger.write("Not got input ingredient. Index: "..index..i..", before calling next cycle")
				player.print("[DEBUG][FactoryCalculator] Not got input ingredient. Index: "..index..i..", before calling next cycle")
				build_recipes_tree(ingredientsFlow, get_recipes_by_result(ingredient.name), craftCount, index.."-"..i)
				debugger.write("Not got input ingredient. Index: "..index..i..", after calling next cycle")
				player.print("[DEBUG][FactoryCalculator] Not got input ingredient. Index: "..index..i..", after calling next cycle")
			end
		else
			debugger.write("unknown ingredient type")
			player.print("Unknown ingredient type. Please leave report on mod page. Error try code: "..index)
			plater.print("Or it's my mistake in the code. Whatever, leave a report.")
		end
	end
	
	for ingredient_index, ingredient in pairs(recipe.ingredients) do
		local craft_count_ingredient = craftCount * ingredient.amount
		if ingredient.type ~= "item" or ingredient.type ~= "fluid" then
			debugger.write("Unknown ingredient type: "..ingredient.type.." at "..index..ingredient_index)
			player.print("An error occured while calculating. Please leave a report on mod page and add log-file from script-output folder.")
			return
		end
		local items_table
		local input_prototypes
		if ingredient.type == "item" then
			items_table = FactCalcSettings.main.input.items
			input_prototypes = game.item_prototypes
		elseif inredient.type == "fluid" then
			items_table = FactCalcSettings.main.input.fluids
			input_prototypes = game.fluid_prototypes
		end
		
		if has_value(items_table, ingredient.name) then
			recipes_tree_end(input_prototypes[ingredient.name], craft_count_ingredient, index.."-"..i, ingredientsFlow)
		else
			
		end
	end
end

function recipes_tree_end(ingredient, count, index, workspace)

end
