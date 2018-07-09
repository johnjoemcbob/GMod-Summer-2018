--
-- Prickly Summer 2018
-- 08/07/18
--
-- Room Editor
--

-- Variable types
local VARIABLE_MULTISELECT = 1

local PlaceableEnts = {
	["spawner"] = {
		Class = nil,
		Variables = {
			["Enemy"] = {
				Type = VARIABLE_MULTISELECT,
				Values = PRK_Enemy_Types,
			},
		},
		Model = "models/props_c17/light_domelight02_on.mdl",
		Offset = Vector(),
		Angle = Angle( 180, 0, 0 ),
		Scale = 2,
	}
}

function SendInEditor( toggle )
	net.Start( "PRK_Editor" )
		net.WriteBool( toggle )
	net.SendToServer()
end

local function PRK_Editor_GUI()
	local f = vgui.Create( "DFrame" )
		f:SetSize( 140, 0 )
		f:SetPos( 10, 10 )
		f:SetTitle( "Options" )
		f:ShowCloseButton( false )
	LocalPlayer().PRK_Editor_GUI_Frame = f

	-- Initialize values
	if ( !LocalPlayer().Zoom ) then
		LocalPlayer().Zoom = 500
		LocalPlayer().TargetZoom = LocalPlayer().Zoom
		LocalPlayer().PRK_Editor_Origin = Vector()
		LocalPlayer().PRK_Editor_CameraPos = LocalPlayer().PRK_Editor_Origin

		LocalPlayer().PRK_Editor_Room_Parts = {}
		LocalPlayer().PRK_Editor_Room_Highlighted = {}
		-- PRK_Editor_Room_AddFloor( LocalPlayer().PRK_Editor_Origin )
	end
	-- Default models
	LocalPlayer().PRK_Editor_Room_Models = {}
	local origin = PRK_AddModel(
		"models/editor/axis_helper_thick.mdl",
		Vector(),
		Angle(),
		2
	)
		origin:SetNoDraw( true )
		origin:SetPos( LocalPlayer().PRK_Editor_Origin )
	table.insert( LocalPlayer().PRK_Editor_Room_Models, origin )

	local player = PRK_AddModel(
		"models/editor/playerstart.mdl",
		Vector(),
		Angle(),
		1
	)
		player:SetNoDraw( true )
		player:SetPos( LocalPlayer().PRK_Editor_Origin )
	table.insert( LocalPlayer().PRK_Editor_Room_Models, player )
end

hook.Add( "Think", "PRK_Think_Editor_Room", function()
	if ( !LocalPlayer().PRK_Editor_Room )  then return end

	-- Lerp camera zoom
	LocalPlayer().Zoom = Lerp( FrameTime() * PRK_Editor_Zoom_Speed, LocalPlayer().Zoom, LocalPlayer().TargetZoom )

	-- Move camera position
	local ang = LocalPlayer():EyeAngles() -- X/Y
	local change = Vector()
		if LocalPlayer():KeyDown( IN_FORWARD ) then
			local ang = ang:Forward()
				ang.z = 0
				ang:Normalize()
			change = change + Vector( ang.x, ang.y, 0 )
		end
		if LocalPlayer():KeyDown( IN_BACK ) then
			local ang = -ang:Forward()
				ang.z = 0
				ang:Normalize()
			change = change + Vector( ang.x, ang.y, 0 )
		end
		if LocalPlayer():KeyDown( IN_MOVERIGHT ) then
			local ang = ang:Right()
				ang.z = 0
				ang:Normalize()
			change = change + Vector( ang.x, ang.y, 0 )
		end
		if LocalPlayer():KeyDown( IN_MOVELEFT ) then
			local ang = -ang:Right()
				ang.z = 0
				ang:Normalize()
			change = change + Vector( ang.x, ang.y, 0 )
		end
	LocalPlayer().PRK_Editor_CameraPos = LocalPlayer().PRK_Editor_CameraPos + change * PRK_Editor_MoveSpeed

	-- Move any dragging edges
	if ( LocalPlayer().PRK_Editor_Room_Dragging ) then
		-- Calculate cursor movement change
		local pos = PRK_Editor_Room_RayToPlane( LocalPlayer():GetEyeTrace().Normal )
		if ( pos ) then
			pos = PRK_Editor_Room_GetClosestGrid( pos )
			local change = LocalPlayer().PRK_Editor_Room_DragStart - pos

			-- Resize parts
			for k, draggable in pairs( LocalPlayer().PRK_Editor_Room_Dragging ) do
				for _, dragging in pairs( draggable ) do
					if ( dragging ) then
						local part = LocalPlayer().PRK_Editor_Room_Parts[k]
							local edges = {
								[1] = function()
									local newsize = part.prewidth + change.x * PRK_Editor_Square_Size
									if ( newsize > 1 ) then
										part.position.x = part.preposx - change.x * PRK_Editor_Square_Size
										part.width = newsize
									end
								end,
								[2] = function()
									local newsize = part.prewidth - change.x * PRK_Editor_Square_Size
									if ( newsize > 1 ) then
										part.width = newsize
									end
								end,
								[3] = function()
									local newsize = part.prebreadth - change.y * PRK_Editor_Square_Size
									if ( newsize > 1 ) then
										part.position.y = part.preposy - change.y * PRK_Editor_Square_Size
										part.breadth = newsize
									end
								end,
								[4] = function()
									local newsize = part.prebreadth + change.y * PRK_Editor_Square_Size
									if ( newsize > 1 ) then
										part.breadth = newsize
									end
								end,
								[5] = function()
									part.position.x = part.preposx - change.x * PRK_Editor_Square_Size
									part.position.y = part.preposy - change.y * PRK_Editor_Square_Size
								end,
							}
							edges[_]()
						LocalPlayer().PRK_Editor_Room_Parts[k] = part
					end
				end
			end
		end
	end
end )

function PRK_Editor_Room_RayToPlane( aim )
	local ray = {
		position = LocalPlayer().PRK_Editor_ViewOrigin,
		direction = aim,
	}
	local plane = {
		position = LocalPlayer().PRK_Editor_Origin,
		normal = Vector( 0, 0, -1 ),
	}
	local pos = intersect_ray_plane( ray, plane )
	if ( pos ) then
		-- PRK_BasicDebugSphere( pos )
	end
	return pos
end

hook.Add( "GUIMousePressed", "PRK_GUIMousePressed_Editor_Room", function( code, aim )
	-- Mouse clicks
	if ( code == MOUSE_LEFT ) then
		-- Start dragging any highlighted edges
		local pos = PRK_Editor_Room_RayToPlane( aim )
			pos = PRK_Editor_Room_GetClosestGrid( pos )
		LocalPlayer().PRK_Editor_Room_Dragging = table.shallowcopy( LocalPlayer().PRK_Editor_Room_Highlighted )
			-- Store predrag sizes
			for k, draggable in pairs( LocalPlayer().PRK_Editor_Room_Dragging ) do
				for _, dragging in pairs( draggable ) do
					if ( dragging ) then
						LocalPlayer().PRK_Editor_Room_Parts[k].preposx = LocalPlayer().PRK_Editor_Room_Parts[k].position.x
						LocalPlayer().PRK_Editor_Room_Parts[k].preposy = LocalPlayer().PRK_Editor_Room_Parts[k].position.y
						LocalPlayer().PRK_Editor_Room_Parts[k].prewidth = LocalPlayer().PRK_Editor_Room_Parts[k].width
						LocalPlayer().PRK_Editor_Room_Parts[k].prebreadth = LocalPlayer().PRK_Editor_Room_Parts[k].breadth
					end
				end
			end
		LocalPlayer().PRK_Editor_Room_DragStart = pos
	elseif ( code == MOUSE_RIGHT ) then
		local pos = PRK_Editor_Room_RayToPlane( aim )

		if ( pos ) then
			local clickedobjects = {}
				-- Check if point is inside any of the floor bounds
				for k, v in pairs( LocalPlayer().PRK_Editor_Room_Parts ) do
					local square = {
						x = { v.position.x, v.position.x + v.width },
						y = { v.position.y, v.position.y - v.breadth },
					}
					if ( intersect_point_square( pos, square ) ) then
						table.insert( clickedobjects, k )
					end
				end
			-- Create and populate menu
			local menu = vgui.Create( "DMenu", LocalPlayer().ContextMenu )
				menu:SetPos( gui.MouseX(), gui.MouseY() )
				-- Options
				local menu_sub_create
				local function add_submenu_create()
					if ( !menu_sub_create ) then
						menu_sub_create = menu:AddSubMenu( "Create" )
					end
				end
				if ( #clickedobjects == 0 ) then
					add_submenu_create()
					menu_sub_create:AddOption(
						"Floor",
						function()
							PRK_Editor_Room_AddFloor( pos )
						end
					)
				end
				add_submenu_create()
				menu_sub_create:AddOption(
					"Spawner",
					function()
						PRK_Editor_Room_AddEnt( pos, "spawner" )
					end
				)
				menu:AddOption(
					"Move Dummy Here",
					function()
						LocalPlayer().PRK_Editor_Room_Models[2]:SetPos( pos )
					end
				)
				for k, v in pairs( clickedobjects ) do
					-- Assumes all are floors currently
					menu:AddOption(
						"Delete Floor #" .. v,
						function()
							PRK_Editor_Room_RemoveFloor( v )
						end
					)
				end
			menu:Open()
		end
	end
end )

hook.Add( "GUIMouseReleased", "PRK_GUIMouseReleased_Editor_Room", function( code, aim )
	LocalPlayer().PRK_Editor_Room_Dragging = nil
end )

hook.Add( "WhileMouseWheeling", "PRK_WhileMouseWheeling_Editor_Room_Zoom", function( wheel )
	if ( !LocalPlayer().PRK_Editor_Room )  then return end

	-- Zoom in/out with mouse wheel
	LocalPlayer().TargetZoom = math.Clamp(
		LocalPlayer().TargetZoom - ( wheel * PRK_Editor_Zoom_Step ),
		PRK_Editor_Zoom_Min,
		PRK_Editor_Zoom_Max
	)
end )

function PRK_Editor_Room_GetClosestGrid( pos )
	pos.x = math.Round( ( pos.x ) / PRK_Editor_Square_Size - 0.5 )
	pos.y = math.Round( ( pos.y ) / PRK_Editor_Square_Size + 0.5 )
	return pos
end

function PRK_Editor_Room_AddFloor( pos )
	local width = 1
	local breadth = 1
	-- Find closest grid point
	pos.x = math.Round( ( pos.x ) / PRK_Editor_Square_Size - width / 2 ) * PRK_Editor_Square_Size
	pos.y = math.Round( ( pos.y ) / PRK_Editor_Square_Size - breadth / 2 ) * PRK_Editor_Square_Size
	-- Store size in world units
	width = width * PRK_Editor_Square_Size
	breadth = breadth * PRK_Editor_Square_Size
	-- Create and store part
	local part = {
		position = pos,
		width = width,
		breadth = breadth,
	}
	table.insert( LocalPlayer().PRK_Editor_Room_Parts, part )
end

function PRK_Editor_Room_RemoveFloor( index )
	table.remove( LocalPlayer().PRK_Editor_Room_Parts, index )
end

function PRK_Editor_Room_AddEnt( pos, ent )
	if ( PlaceableEnts[ent] ) then
		local model = PRK_AddModel(
			PlaceableEnts[ent].Model,
			pos + PlaceableEnts[ent].Offset,
			PlaceableEnts[ent].Angle,
			PlaceableEnts[ent].Scale
		)
			model:SetNoDraw( true )
		table.insert( LocalPlayer().PRK_Editor_Room_Models, model )
	end
end

local view_origin, view_angles
function PRK_CalcView_Editor_Room( ply, origin, angles, fov )
	if LocalPlayer().PRK_Editor_Room then
		local view = {}
			view.angles = angles
				-- From -180->180 to 5->180
				local min = 5
				view.angles.p = ( view.angles.p - 180 - min ) / 2 + 90 + 45 + min
			view.origin = LocalPlayer().PRK_Editor_CameraPos + view.angles:Forward():GetNormal() * -LocalPlayer().Zoom
			LocalPlayer().PRK_Editor_ViewOrigin = view.origin
		return view
	end
	return false
end

hook.Add( "PostDrawHUD", "PRK_PostDrawHUD_Editor", function()
	if ( PRK_ShouldDraw() ) then return end

	-- Draw all editor models
	cam.Start3D()
		-- Draw grid with falloff
		local colour = Color( 255, 255, 255, 10 )
		local colour_green = Color( 0, 255, 0, 10 )-- Color( 220, 255, 220, 10 )
		local colour_red = Color( 255, 0, 0, 10 ) --Color( 255, 220, 220, 10 )
		local width = 1
		local width_axis = 5
		local scale = PRK_Editor_Grid_Scale
		local between = PRK_Editor_Square_Size / scale
		local length = PRK_Editor_Grid_Size * 1 / scale
		local fulllength = ( length + between ) * 2
		local magic = 7.25 -- TODO: Figure out the math to make the grid squares match the floor segments
		cam.Start3D2D( LocalPlayer().PRK_Editor_Origin + Vector( 0, 0, 0 ), Angle( 0, 0, 0 ), scale )
			-- Draw grid with fadeout faking (drawing alpha'd rectangles on top a increasing distances)
			local function mask()
				local x = 0
				local y = 0
				local segs = 30
				local dif = ( length + between ) / segs
				local size = dif
				local alpha = 0
				local alphadif = 255 / segs
				for seg = 1, segs do
					size = math.floor( size + dif )
					alpha = alpha + alphadif
					surface.SetDrawColor( 0, 0, 0, alpha )
					surface.DrawRectBorder( x - size + between, y - size + between, size * 2, size * 2, dif )
				end
			end
			local function grid()
				surface.SetDrawColor( colour )
				for dir = 1, -1, -2 do
					local x = 0
					while ( x < length ) do
						local width = width
						local y = -length
						if ( math.abs( x ) <= between / 2 ) then
							surface.SetDrawColor( colour_green )
							width = width * width_axis
							x = x - width / 2
						else
							surface.SetDrawColor( colour )
						end
						surface.DrawRect( x * dir, y, width, fulllength )
						x = x + between
					end
				end
				for dir = 1, -1, -2 do
					local y = 0
					while ( y < length ) do
						local width = width
						local x = -length
						if ( math.abs( y ) <= between / 2 ) then
							surface.SetDrawColor( colour_red )
							width = width * width_axis
							y = y - width / 2
						else
							surface.SetDrawColor( colour )
						end
						surface.DrawRect( x, y * dir, fulllength, width )
						y = y + between
					end
				end
			end
			grid()
			mask()

			-- Draw floors
			local colour_floor = Color( 200, 100, 100, 100 )
			surface.SetDrawColor( colour_floor )
			if ( LocalPlayer().PRK_Editor_Room_Parts ) then
				for k, v in pairs( LocalPlayer().PRK_Editor_Room_Parts ) do
					surface.DrawRect(
						v.position.x / scale,
						-v.position.y / scale,
						v.width / scale,
						v.breadth / scale
					)
				end
			end

			-- Draw floor edge drag highlight
			local border_highlight = PRK_Editor_Square_Border_Min + PRK_Editor_Square_Border_Add / PRK_Editor_Zoom_Max * LocalPlayer().Zoom
			local colour_highlight = Color( 200, 200, 200, 100 )
			surface.SetDrawColor( colour_highlight )
			local pos = PRK_Editor_Room_RayToPlane( LocalPlayer():GetEyeTrace().Normal )
			if ( pos ) then
				for k, v in pairs( LocalPlayer().PRK_Editor_Room_Parts ) do
					LocalPlayer().PRK_Editor_Room_Highlighted[k] = {}

					-- Check each edge of the floor part
					local sides = {
						-- Left
						{
							x = 0,
							y = 0,
							w = 0,
							b = 1,
						},
						-- Right
						{
							x = 1,
							y = 0,
							w = 0,
							b = 1,
						},
						-- Top
						{
							x = 0,
							y = 0,
							w = 1,
							b = 0,
						},
						-- Right
						{
							x = 0,
							y = 1,
							w = 1,
							b = 0,
						},
						-- Middle
						{
							x = 0,
							y = 0,
							w = -1,
							b = -1,
						},
					}
					for _, side in pairs( sides ) do
						local x = ( v.position.x + ( v.width - border_highlight ) * side.x ) / scale
						local y = ( -v.position.y + ( v.breadth - border_highlight ) * side.y ) / scale
						local w = v.width / scale
							if ( side.w < 0 ) then
								x = x + border_highlight / scale
								w = w - border_highlight / scale * 2
							elseif ( side.w != 0 ) then
								w = w * side.w
							else
								w = border_highlight / scale
							end
						local b = v.breadth / scale
							if ( side.b < 0 ) then
								y = y + border_highlight / scale
								b = b - border_highlight / scale * 2
							elseif ( side.b != 0 ) then
								b = b * side.b
							else
								b = border_highlight / scale
							end
						local pos = pos / scale
						local square = {
							x = { x, x + w },
							y = { -y, -y - b },
						}
						if ( !LocalPlayer().PRK_Editor_Room_Dragging and vgui.CursorVisible() ) then
							-- Only look for new highlights when not currently dragging
							LocalPlayer().PRK_Editor_Room_Highlighted[k][_] = intersect_point_square( pos, square )
						end
						-- if ( LocalPlayer().PRK_Editor_Room_Highlighted[k][_] or _ ==5 ) then
						if ( LocalPlayer().PRK_Editor_Room_Highlighted[k][_] or ( LocalPlayer().PRK_Editor_Room_Dragging and LocalPlayer().PRK_Editor_Room_Dragging[k][_] ) ) then
							surface.DrawRect(
								x,
								y,
								w,
								b
							)
						end
					end
				end
			end
		cam.End3D2D()

		-- Draw models
		for k, model in pairs( LocalPlayer().PRK_Editor_Room_Models ) do
			model:DrawModel()
		end
	cam.End3D()
end )

concommand.Add( "prk_editor_room", function( ply, cmd, args )
	ply.PRK_Editor_Room = !ply.PRK_Editor_Room

	-- Clientside logic
	if ( ply.PRK_Editor_Room ) then
		PRK_Editor_GUI()
	else
		-- Remove all GUI
		local frame = LocalPlayer().PRK_Editor_GUI_Frame
		if ( frame and frame:IsValid() ) then
			frame:Remove()
		end
		-- Remove models
		for k, model in pairs( LocalPlayer().PRK_Editor_Room_Models ) do
			model:Remove()
		end
	end

	-- Serverside logic
	SendInEditor( ply.PRK_Editor_Room )
end )
