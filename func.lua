--This file contains functions used in other files

function has_value (tab, val) --Thanks Oka for this function ( https://stackoverflow.com/users/2505965/oka ). I modified it for my code.
	for index, value in ipairs(tab) do
		if value.name == val then
			return true
		end
	end

	return false
end

function get_recipes_by_result(result_name)
	local output = {}
	for i, e in pairs(game.recipe_prototypes) do
		if has_value(e.products, result_name) then
			table.insert(output, e)
		end
	end
	return output
end

function form_dropdown(recipes)
	local result = {}
	for i, recipe in pairs(recipes) do
		table.insert(result, recipe.name)
	end
	return result
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--Debugger
debugger = {}

debugger.start = function(filename, continue)
	debugger.filename = filename
	game.write_file(filename, "[Debugger] Start of log.\n\n", continue)
end

debugger.write = function(message)
	game.write_file(debugger.filename, message.."\n", true)
end
