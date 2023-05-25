-- ffi setup
local ffi = require("ffi")
local C = ffi.C

local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library
local menu = {}
local df_menu = {}

local dfmod = {}

local dfconfig = {
	orderDragSupport = {
	--	order name	position parameter
		["Police"]	= 9,
	},
}

local function init()
	menu = Lib.Get_Egosoft_Menu("MapMenu")

	df_menu.ego_onnUpdate = menu.onUpdate
	menu.onUpdate = df_menu.onUpdate

	df_menu.ego_onRenderTargetMouseDown = menu.onRenderTargetMouseDown
	menu.onRenderTargetMouseDown = df_menu.onRenderTargetMouseDown

	df_menu.ego_onRenderTargetMouseUp = menu.onRenderTargetMouseUp
	menu.onRenderTargetMouseUp = df_menu.onRenderTargetMouseUp
end

function df_menu.onUpdate()
	if dfmod.orderdrag and dfmod.orderdrag.isclick then
		local curtime = getElapsedTime()
		local offset = table.pack(GetLocalMousePosition())
		if menu.leftdown and ((menu.leftdown.time + 0.5 < curtime) or Helper.comparePositions(menu.leftdown.position, offset, 5)) then
			dfmod.orderdrag.isclick = false
		end
	end
	if dfmod.orderdrag and (not dfmod.orderdrag.isclick) then
		if (dfmod.orderdrag.component ~= C.GetPlayerOccupiedShipID()) and GetComponentData(ConvertStringTo64Bit(tostring(dfmod.orderdrag.component)), "assignedpilot") then
			local posrot = ffi.new("UIPosRot")

			local paramidx = dfconfig.orderDragSupport[ffi.string(dfmod.orderdrag.orderdefid)]
			local pickedorder = ffi.new("Order")
			local isintermediate = ffi.new("bool[1]", 0)
			local pickedordercomponent = C.GetPickedMapOrder(menu.holomap, pickedorder, isintermediate)
			if (pickedordercomponent == dfmod.orderdrag.component) and (not isintermediate[0]) then
				dfmod.orderdrag.order.queueidx = pickedorder.queueidx
			end

			local orderidx = (tonumber(dfmod.orderdrag.order.queueidx) == 0) and "default" or tonumber(dfmod.orderdrag.order.queueidx)
			local orderparams = GetOrderParams(ConvertStringToLuaID(tostring(dfmod.orderdrag.component)), orderidx)
			if next(orderparams) then
				if (orderparams[paramidx].type == "position") and (type(orderparams[paramidx].value[2]) == "table") then
					local eclipticoffset = ffi.new("UIPosRot", orderparams[paramidx].value[2])

					local posrotcomponent = C.GetMapPositionOnEcliptic2(menu.holomap, posrot, true, ConvertIDTo64Bit(orderparams[paramidx].value[1]), eclipticoffset)
					if (posrotcomponent ~= 0) then
						SetOrderParam(ConvertStringToLuaID(tostring(dfmod.orderdrag.component)), orderidx, paramidx, nil, { ConvertStringToLuaID(tostring(posrotcomponent)), {posrot.x, posrot.y, posrot.z} })
					end
				end
			end
		end
	end

	return df_menu.ego_onnUpdate()
end

function df_menu.onRenderTargetMouseDown(modified)
	df_menu.ego_onRenderTargetMouseDown(modified)

	local pickedorder = ffi.new("Order")
	local buf = ffi.new("bool[1]", 0)
	local pickedordercomponent = C.GetPickedMapOrder(menu.holomap, pickedorder, buf)
	if (pickedordercomponent ~= 0) then
		if GetComponentData(ConvertStringTo64Bit(tostring(pickedordercomponent)), "isplayerowned") then
			local orderdef = ffi.new("OrderDefinition")
			if C.GetOrderDefinition(orderdef, pickedorder.orderdef) then
				local orderdefid = ffi.string(orderdef.id)
				if dfconfig.orderDragSupport[orderdefid] then
					dfmod.orderdrag = { component = pickedordercomponent, order = pickedorder, orderdefid = orderdefid, isintermediate = false, isclick = true }
				end
			end
		end
	end
end

function df_menu.onRenderTargetMouseUp(modified)
	if dfmod.orderdrag then
		if (not dfmod.orderdrag.isclick) then
			if (dfmod.orderdrag.component ~= C.GetPlayerOccupiedShipID()) and GetComponentData(ConvertStringTo64Bit(tostring(dfmod.orderdrag.component)), "assignedpilot") then
				local posrot = ffi.new("UIPosRot")

				local paramidx = dfconfig.orderDragSupport[ffi.string(dfmod.orderdrag.orderdefid)]
				local orderidx = (tonumber(dfmod.orderdrag.order.queueidx) == 0) and "default" or tonumber(dfmod.orderdrag.order.queueidx)
				local orderparams = GetOrderParams(ConvertStringToLuaID(tostring(dfmod.orderdrag.component)), orderidx)
				if next(orderparams) then
					if (orderparams[paramidx].type == "position") and (type(orderparams[paramidx].value[2]) == "table") then
						local eclipticoffset = ffi.new("UIPosRot", orderparams[paramidx].value[2])

						local posrotcomponent = C.GetMapPositionOnEcliptic2(menu.holomap, posrot, true, ConvertIDTo64Bit(orderparams[paramidx].value[1]), eclipticoffset)
						if (posrotcomponent ~= 0) then
							SetOrderParam(ConvertStringToLuaID(tostring(dfmod.orderdrag.component)), orderidx, paramidx, nil, { ConvertStringToLuaID(tostring(posrotcomponent)), {posrot.x, posrot.y, posrot.z} })
						end
					end
				end
			end
		end
		dfmod.orderdrag = nil
	else
		return df_menu.ego_onRenderTargetMouseUp(modified)
	end
end

init()
