require("gui_creation")

script.on_event(defines.events.on_gui_click,
function(event)
	local player = game.players[event.player_index]
	local cGui = player.gui.center
	local clicked = event.element

	if not string.find(clicked.name, "FactCalc") then return end -- Check if this is fro FactCalc

	if event.button == defines.mouse_button_type.right then -- Redraw GUI on RMB click
		player.print("Resetting UI...")
		resetAndReloadUI(player)
		return
	end

	local settingsFrame = cGui["FactCalc-main-flow"]["FactCalc-settings-frame"]

	if clicked.name == "FactCalc-open-calculator" then   -- "Open calculator" button
		settingsFrame.visible = true
	elseif string.find(clicked.name, "radiobutton") then -- Radiobuttons
		if clicked.name == "FactCalc-radiobutton-number" then
			settingsFrame["FactCalc-count-belt"]["FactCalc-radiobutton-belt"].state = false
			settingsFrame["FactCalc-count-assembler"]["FactCalc-radiobutton-assembler"].state = false
		elseif clicked.name == "FactCalc-radiobutton-belt" then
			settingsFrame["FactCalc-count-number"]["FactCalc-radiobutton-number"].state = false
			settingsFrame["FactCalc-count-assembler"]["FactCalc-radiobutton-assembler"].state = false
		elseif clicked.name == "FactCalc-radiobutton-assembler" then
			settingsFrame["FactCalc-count-belt"]["FactCalc-radiobutton-belt"].state = false
			settingsFrame["FactCalc-count-number"]["FactCalc-radiobutton-number"].state = false
		end
	elseif string.find(clicked.name, "secmin") then -- Flip buttons
		if     clicked.caption == "sec"  then clicked.caption = "min"
		elseif clicked.caption == "min"  then clicked.caption = "sec"  end
	elseif string.find(clicked.name, "fullhalf") then
		if     clicked.caption == "full" then clicked.caption = "half"
		elseif clicked.caption == "half" then clicked.caption = "full" end
	elseif clicked.name == "FactCalc-calculate" then
		calculateFactory(player)
	end
end
)
