
local df_mod = {}

local function init()
	RegisterEvent("convertStringToNumber", df_mod.onConvertStringToNumber)
end

function df_mod.onConvertStringToNumber(_, param)
	local result = param
	if (type(param) == "string") then
		result = tonumber(param)
	end

	return AddUITriggeredEvent("my_screen", "my_control", result)
end

init()

