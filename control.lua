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
	for i = 0, 7, 1 do table.insert(input_items, game.item_prototypes[settingsGui["FactCalc-items-table"]["FactCalc-choose-resource-item-"..i].elem_value]) end
	for i = 0, 7, 1 do table.insert(input_fluids, game.fluid_prototypes[settingsGui["FactCalc-fluids-table"]["FactCalc-choose-resource-fluid-" .. i].elem_value]) end
	
	local outputRecipe = game.recipe_prototypes[settingsGui["FactCalc-item-choose"]["FactCalc-chooseItem"].elem_value]
	
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
		if game.item_prototypes[settingsGui["FactCalc-count-belt"]["FactCalc-choose-belt"].elem_value].place_result.type == "transport-belt" then
			outputValue = game.item_prototypes[settingsGui["FactCalc-count-belt"]["FactCalc-choose-belt"].elem_value].place_result.belt_speed * beltSpeedMultiplier
			
			if settingsGui["FactCalc-count-belt"]["FactCalc-addition-belt"]["FactCalc-flipbutton-belt"].style.name == "flip_button_right" then outputValue = outputValue / 2 end
		else
			player.print("Please, choose only transport belt items. If you selected belt item and this error message still appear, please report about this on mod page.")
		end
	
	elseif settingsGui["FactCalc-count-assembler"]["FactCalc-radiobutton-assembler"].state then
		outputValue = tonumber(settingsGui["FactCalc-count-assembler"]["FactCalc-textfield-assembler"].text) * game.item_prototypes[settingsGui["FactCalc-count-assembler"]["FactCalc-choose-assembler"].value].crafting_speed / outputRecipe.energy
	
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

--The most important part. I hate it because it's not working as I want for a long time
function build_recipes_tree(gui, recipes, craft_count, index)
	debugger.write("Started cycle with index "..index)
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
	local assemblerCount = math.ceil((craft_count * recipe.energy) / assemblerSpeed)
	craft_count = (assemblerCount * assemblerSpeed) / recipe.energy
	
	debugger.write("[DEBUG][FactoryCalculator] index: "..index..", stage: calculating, recipe name: "..recipe.name..", craft_count: "..craft_count..", dropdown_index: "..dropdown_index)
	player.print("[DEBUG][FactoryCalculator] index: "..index..", stage: calculating, recipe name: "..recipe.name..", craft_count: "..craft_count..", dropdown_index: "..dropdown_index)
	
	--gui creating
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
		caption = "X" .. craft_count
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
	for ingredient_index, ingredient in pairs(recipe.ingredients) do
		--some prepare
		local craft_count_ingredient = craft_count * ingredient.amount
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
		
		--Is input ingredient or continue this recursion?
		if has_value(items_table, ingredient.name) then
			debugger.write("Got input ingredient. Index: "..index.."-"..i..", ingredient name: "..ingredient.name)
			recipes_tree_end(input_prototypes[ingredient.name], craft_count_ingredient, index.."-"..i, ingredients_flow)
		else
			debugger.write("Got non-input ingredient. Entering new cycle. Index: "..index.."-"..i..", ingredient name: "..ingredient.name)
			build_recipes_tree(ingredients_flow, get_recipes_by_result(ingredient.name), craft_count_ingredient, index.."-"..i)
		end
	end
	debugger.write("Cycle with index "..index.." ended.")
end

function recipes_tree_end(prototype, count, index, workspace)
	debugger.write("Started end function. Index: "..index)
	--Getting some variables
	local ingredient_sprite = ""
	if prototype.type == fluid then ingredient_sprite = "fluid/"..prototype.name else ingredient_sprite = "item/"..prototype.name end
	
	--Gui creation
	local workplace = gui.add {
		name = "FactCalc-end-" .. index,
		type = "horizontal",
		direction = "vertical"
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
	debugger.write("End fucntion with index "..index.."ended")
end
