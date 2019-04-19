data:extend({
	{
		type = "int-setting",
		name = "FactCalc-max-recursion",
		setting_type = "runtime-per-user",
		default_value = 100,
		minimum_value = 10,
		maximum_value = 500
	},
	{
		type = "string-setting",
		name = "FactCalc-ceil-numbers",
		setting_type = "runtime-per-user",
		default_value = "show-ceil",
		allowed_values = {"calculate-ceil", "show-ceil", "no-ceil"}
	}
})