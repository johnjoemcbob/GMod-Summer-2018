--
-- Prickly Summer 2018
-- 08/07/18
--
-- Room Editor
--

-- Variable types
local VARIABLE_MULTISELECT = 1

-- TODO: move this to shared
local PlaceableEnts = {
	["Dummy"] = {
		Spawnable = false,
		Class = nil,
		Variables = nil,
		Model = "models/editor/playerstart.mdl",
		Offset = Vector(),
		Angle = Angle(),
		Scale = 1,
		Colour = Color( 255, 255, 255, 255 ),
		ClickCollision = {
			Vector( -20, -20, 0 ),
			Vector( 20, 20, 0 ),
		}
	},
	["Spawner"] = {
		Spawnable = true,
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
		Colour = Color( 255, 255, 255, 255 ),
		ClickCollision = {
			Vector( -20, -20, 0 ),
			Vector( 20, 20, 0 ),
		}
	},
	["Vendor"] = {
		Spawnable = true,
		Class = "prk_uimachine",
		Variables = {
			
		},
		Model = "models/props_interiors/vendingmachinesoda01a.mdl",
		Offset = Vector( 0, 0, 50 ),
		Angle = Angle(),
		Scale = 1,
		Colour = Color( 255, 255, 255, 255 ),
		ClickCollision = {
			Vector( -20, -30, 0 ),
			Vector( 20, 30, 0 ),
		}
	},
	["Rock"] = {
		Spawnable = true,
		Class = "prk_rock",
		Variables = {
			
		},
		Model = "models/props_wasteland/rockcliff01f.mdl",
		Offset = Vector( 0, 0, 0 ),
		Angle = Angle(),
		Scale = 1,
		Colour = Color( 255, 255, 255, 255 ),
		ClickCollision = {
			Vector( -30, -30, 0 ),
			Vector( 30, 30, 0 ),
		}
	},
}

function SendInEditor( toggle )
	net.Start( "PRK_Editor" )
		net.WriteBool( toggle )
	net.SendToServer()
end

function SendEditorExport( content )
	net.Start( "PRK_EditorExport" )
		net.WriteString( content )
	net.SendToServer()
end

local function PRK_Editor_GUI()
	-- UI
	local w = 128 -- ScrW() / 6
	local h = 224 -- ScrH() / 4
	local f = vgui.Create( "DFrame" )
		f:SetSize( w, h )
		f:SetPos( ScrW() - w, ScrH() - h )
		f:SetMouseInputEnabled( true )
		f:MouseCapture()
		f:SetTitle( "" )
		f:ShowCloseButton( false )
		function f:Paint( w, h )
			
		end
	LocalPlayer().PRK_Editor_GUI_Frame = f
	-- Import
	local b = vgui.Create( "DButton", f )
		b:SetSize( w, h / 2 )
		b:Dock( BOTTOM )
		b:SetText( "" )
		b:SetMouseInputEnabled( true )
		function b:Paint( w, h )
			PRK_DrawText(
				"⍇",
				w / 2,
				h / 2,
				Color( 255, 255, 255, 100 ),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				96,
				false
			)
		end
		function b:DoClick()
			PRK_Editor_Room_Import()
		end
	-- Export
	local b = vgui.Create( "DButton", f )
		b:SetSize( w, h / 2 )
		b:Dock( BOTTOM )
		b:SetText( "" )
		b:SetMouseInputEnabled( true )
		function b:Paint( w, h )
			PRK_DrawText(
				"⍈", -- ⮹
				w / 2,
				h / 2,
				Color( 255, 255, 255, 100 ),
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				96,
				false
			)
		end
		function b:DoClick()
			PRK_Editor_Room_Export()
			local menu = vgui.Create( "DMenu", LocalPlayer().ContextMenu )
				menu:SetPos( gui.MouseX(), gui.MouseY() )
				-- Options
				menu:AddOption(
					"Export locally",
					function()
						PRK_Editor_Room_Export()
					end
				)
				menu:AddOption(
					"Export and save to server",
					function()
						PRK_Editor_Room_Export( true )
					end
				)
			menu:Open()
		end

	-- Initialize values
	if ( !LocalPlayer().PRK_Editor_RoomData ) then
		LocalPlayer().PRK_Editor_RoomData = {
			Zoom = PRK_Editor_Zoom_Default,
			TargetZoom = PRK_Editor_Zoom_Default,
			Origin = Vector(),
			CameraPos = Vector(),

			Parts = {},

			Highlighted = {},
			HighlightedModel = {},
		}
	end

	-- Default models
	if ( !LocalPlayer().PRK_Editor_RoomData.Models ) then
		LocalPlayer().PRK_Editor_RoomData.Models = {}
		local origin = PRK_AddModel(
			"models/editor/axis_helper_thick.mdl",
			LocalPlayer().PRK_Editor_RoomData.Origin,
			Angle(),
			2
		)
			origin:SetNoDraw( true )
		table.insert( LocalPlayer().PRK_Editor_RoomData.Models, origin )

		local player = PRK_AddModel(
			"models/editor/playerstart.mdl",
			LocalPlayer().PRK_Editor_RoomData.Origin,
			Angle(),
			1
		)
			player:SetNoDraw( true )
			player.PRK_Editor_Ent = "Dummy"
		table.insert( LocalPlayer().PRK_Editor_RoomData.Models, player )
	end
end

hook.Add( "OnContextMenuOpen", "PRK_OnContextMenuOpen_Editor", function()
	if ( LocalPlayer().PRK_Editor_Room ) then
		LocalPlayer().PRK_Editor_GUI_Frame:MakePopup()
		LocalPlayer().PRK_Editor_GUI_Frame:SetKeyboardInputEnabled( false )
		-- LocalPlayer():ConCommand( "prk_editor_room" )
	end
end )

hook.Add( "OnContextMenuClose", "PRK_OnContextMenuClose_Editor", function()
	if ( LocalPlayer().PRK_Editor_Room ) then
		LocalPlayer().PRK_Editor_GUI_Frame:SetMouseInputEnabled( false )
		LocalPlayer().PRK_Editor_GUI_Frame:SetKeyboardInputEnabled( false )
	end
end )

local lastdown = {}
hook.Add( "Think", "PRK_Think_Editor_Room", function()
	if ( !LocalPlayer().PRK_Editor_Room ) then return end

	-- Mouse input
	local codes = {
		MOUSE_LEFT,
		MOUSE_RIGHT,
	}
	for k, code in pairs( codes ) do
		if ( input.IsMouseDown( code ) ) then
			if ( !lastdown[code] ) then
				PRK_GUIMousePressed( code, gui.ScreenToVector( gui.MousePos() ) )
				lastdown[code] = true
			end
		elseif ( lastdown[code] ) then
			PRK_GUIMouseReleased( code, gui.ScreenToVector( gui.MousePos() ) )
			lastdown[code] = nil
		end
	end

	-- Lerp camera zoom
	LocalPlayer().PRK_Editor_RoomData.Zoom = Lerp( FrameTime() * PRK_Editor_Zoom_Speed, LocalPlayer().PRK_Editor_RoomData.Zoom, LocalPlayer().PRK_Editor_RoomData.TargetZoom )

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
	LocalPlayer().PRK_Editor_RoomData.CameraPos = LocalPlayer().PRK_Editor_RoomData.CameraPos + change * PRK_Editor_MoveSpeed

	local pos = PRK_Editor_Room_RayToPlane( LocalPlayer():GetEyeTrace().Normal )
	if ( pos ) then
		-- Move the rectangle selector
		if ( LocalPlayer().PRK_Editor_RoomData.RectangleSelector and !LocalPlayer().PRK_Editor_RoomData.RectangleSelector.Menu ) then
			LocalPlayer().PRK_Editor_RoomData.RectangleSelector.End = pos
		end

		-- Move any dragging objects
		if ( LocalPlayer().PRK_Editor_RoomData.DraggingModel ) then
			for k, dragging in pairs( LocalPlayer().PRK_Editor_RoomData.DraggingModel ) do
				if ( dragging ) then
					local model = LocalPlayer().PRK_Editor_RoomData.Models[k]
					local pos = pos
						if ( LocalPlayer().PRK_Editor_RoomData.DraggingModelSelectorSnap ) then
							pos = PRK_Editor_Room_GetClosestGrid( pos )
							pos.x = model.preposx + ( pos.x * PRK_Editor_Square_Size )
							pos.y = model.preposy + ( pos.y * PRK_Editor_Square_Size )
						else
							pos = pos + Vector( model.preposx, model.preposy, 0 )
							if LocalPlayer():KeyDown( IN_SPEED ) then
								pos = PRK_Editor_Room_GetClosestGrid( pos ) * PRK_Editor_Square_Size
							end
							pos = pos
						end
					model:SetPos( pos + PlaceableEnts[model.PRK_Editor_Ent].Offset )
				end
			end
		end

		-- Move any dragging edges
		if ( LocalPlayer().PRK_Editor_RoomData.Dragging ) then
			-- Calculate cursor movement change
			pos = PRK_Editor_Room_GetClosestGrid( pos )
			local change = LocalPlayer().PRK_Editor_RoomData.DragStart - pos

			-- Resize parts
			for k, draggable in pairs( LocalPlayer().PRK_Editor_RoomData.Dragging ) do
				for _, dragging in pairs( draggable ) do
					if ( dragging ) then
						local part = LocalPlayer().PRK_Editor_RoomData.Parts[k]
						if ( part ) then
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
						end
						LocalPlayer().PRK_Editor_RoomData.Parts[k] = part
					end
				end
			end
		end
	end
end )

function PRK_Editor_Room_RayToPlane( aim )
	local aim = gui.ScreenToVector( gui.MousePos() )
	local ray = {
		position = LocalPlayer().PRK_Editor_RoomData.ViewOrigin,
		direction = aim,
	}
	local plane = {
		position = LocalPlayer().PRK_Editor_RoomData.Origin,
		normal = Vector( 0, 0, -1 ),
	}
	local pos = intersect_ray_plane( ray, plane )
	return pos
end

function PRK_Editor_Room_StopDrag()
	LocalPlayer().PRK_Editor_RoomData.Dragging = nil
	LocalPlayer().PRK_Editor_RoomData.DraggingModel = nil
	LocalPlayer().PRK_Editor_RoomData.DraggingModelSelectorSnap = nil
end

function PRK_Editor_Room_HandleDrag()
	local pos_raw = PRK_Editor_Room_RayToPlane( LocalPlayer():GetEyeTrace().Normal )
	if ( pos_raw ) then
		local draggingsomething = false

		-- End drag if was already dragging
		if (
			( LocalPlayer().PRK_Editor_RoomData.Dragging and #LocalPlayer().PRK_Editor_RoomData.Dragging > 0 ) or
			( LocalPlayer().PRK_Editor_RoomData.DraggingModel and #LocalPlayer().PRK_Editor_RoomData.DraggingModel > 0 )
		) then
			PRK_Editor_Room_StopDrag()
			return
		end

		-- Models
		local pos = PRK_Editor_Room_GetClosestGrid( pos_raw )
		LocalPlayer().PRK_Editor_RoomData.DraggingModel = table.shallowcopy( LocalPlayer().PRK_Editor_RoomData.HighlightedModel )
			-- Store predrag cursor/models offset
			for k, draggable in pairs( LocalPlayer().PRK_Editor_RoomData.DraggingModel ) do
				if ( draggable ) then
					local model = LocalPlayer().PRK_Editor_RoomData.Models[k]
					LocalPlayer().PRK_Editor_RoomData.Models[k].preposx = model:GetPos().x - pos_raw.x
					LocalPlayer().PRK_Editor_RoomData.Models[k].preposy = model:GetPos().y - pos_raw.y
					draggingsomething = true
				end
			end
		-- Floors
		LocalPlayer().PRK_Editor_RoomData.Dragging = table.shallowcopy( LocalPlayer().PRK_Editor_RoomData.Highlighted )
			-- Store predrag sizes
			for k, draggable in pairs( LocalPlayer().PRK_Editor_RoomData.Dragging ) do
				for _, dragging in pairs( draggable ) do
					if ( dragging ) then
						if ( LocalPlayer().PRK_Editor_RoomData.Parts[k] ) then
							LocalPlayer().PRK_Editor_RoomData.Parts[k].preposx = LocalPlayer().PRK_Editor_RoomData.Parts[k].position.x
							LocalPlayer().PRK_Editor_RoomData.Parts[k].preposy = LocalPlayer().PRK_Editor_RoomData.Parts[k].position.y
							LocalPlayer().PRK_Editor_RoomData.Parts[k].prewidth = LocalPlayer().PRK_Editor_RoomData.Parts[k].width
							LocalPlayer().PRK_Editor_RoomData.Parts[k].prebreadth = LocalPlayer().PRK_Editor_RoomData.Parts[k].breadth
						end
						draggingsomething = true
					end
				end
			end
		LocalPlayer().PRK_Editor_RoomData.DragStart = pos

		-- If not dragging, make a rectangle selector instead
		if ( !draggingsomething ) then
			if ( !LocalPlayer().PRK_Editor_RoomData.RectangleSelector ) then
				LocalPlayer().PRK_Editor_RoomData.RectangleSelector = { Start = pos_raw }
				LocalPlayer().PRK_Editor_RoomData.Highlighted = {}
			else
				PRK_Editor_Room_StopDrag()
				return
			end
		end
	end
end

-- Opening chat while in the room editor messes stuff up, so just exit if the user opens it
hook.Add( "StartChat", "PRK_StartChat_Editor_Room", function( isTeamChat )
	if ( LocalPlayer().PRK_Editor_Room )  then
		LocalPlayer():ConCommand( "prk_editor_room" )
	end
end )

function PRK_GUIMousePressed( code, aim )
	if ( !LocalPlayer().PRK_Editor_Room )  then return end

	-- Mouse clicks
	if ( code == MOUSE_LEFT ) then
		-- Start dragging any highlighted edges
		PRK_Editor_Room_HandleDrag()
	elseif ( code == MOUSE_RIGHT ) then
		local pos = PRK_Editor_Room_RayToPlane( aim )

		if ( pos ) then
			local clickedfloors = {}
				-- Check if point is inside any of the floor bounds
				for k, v in pairs( LocalPlayer().PRK_Editor_RoomData.Parts ) do
					local square = {
						x = { v.position.x, v.position.x + v.width },
						y = { v.position.y, v.position.y - v.breadth },
					}
					if ( intersect_point_square( pos, square ) ) then
						table.insert( clickedfloors, k )
					end
				end
			local clickedobjects = {}
				-- Check if any models are highlighted
				for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.Models ) do
					if ( model.Highlighted ) then
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
					if ( #clickedfloors == 0 ) then
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
						"Attach Point",
						function()
							PRK_Editor_Room_AddFloor( pos, true )
						end
					)
				local menu_sub_delete
					local function add_submenu_delete()
						if ( !menu_sub_delete ) then
							menu_sub_delete = menu:AddSubMenu( "Delete" )
						end
					end
				add_submenu_create()
				for name, data in pairs( PlaceableEnts ) do
					menu_sub_create:AddOption(
						name,
						function()
							PRK_Editor_Room_AddEnt( pos, name )
						end
					)
				end
				for k, v in pairs( clickedfloors ) do
					add_submenu_delete()
					menu_sub_delete:AddOption(
						"Delete Floor #" .. v,
						function()
							PRK_Editor_Room_RemoveFloor( v )
						end
					)
				end
				for k, v in pairs( clickedobjects ) do
					add_submenu_delete()
					menu_sub_delete:AddOption(
						"Delete " .. LocalPlayer().PRK_Editor_RoomData.Models[v].PRK_Editor_Ent,
						function()
							PRK_Editor_Room_RemoveEnt( v )
						end
					)
				end
			menu:Open()
		end
	end

	-- Refocus to UI
	LocalPlayer().PRK_Editor_GUI_Frame:MakePopup()
	LocalPlayer().PRK_Editor_GUI_Frame:SetKeyboardInputEnabled( false )
end

function PRK_GUIMouseReleased( code, aim )
	if ( !LocalPlayer().PRK_Editor_Room )  then return end

	LocalPlayer().PRK_Editor_RoomData.Dragging = nil
	LocalPlayer().PRK_Editor_RoomData.DraggingModel = nil

	local rect = LocalPlayer().PRK_Editor_RoomData.RectangleSelector
	if ( rect ) then
		local function selection()
			-- Find all parts and models inside this range
			for k, v in pairs( LocalPlayer().PRK_Editor_RoomData.Parts ) do
				local squarefloor = {
					x = {
						v.position.x,
						v.position.x + v.width,
					},
					y = {
						v.position.y,
						v.position.y - v.breadth,
					},
				}
				local squarerect = {
					x = {
						rect.Start.x,
						rect.End.x,
					},
					y = {
						rect.Start.y,
						rect.End.y,
					},
				}
				v.Highlighted = intersect_squares( squarefloor, squarerect )
				LocalPlayer().PRK_Editor_RoomData.Highlighted[k] = {}
				LocalPlayer().PRK_Editor_RoomData.Highlighted[k][5] = v.Highlighted
			end
			for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.Models ) do
				if ( model.PRK_Editor_Ent ) then
					local data = PlaceableEnts[model.PRK_Editor_Ent]
					if ( data and data.ClickCollision ) then
						local x = model:GetPos().x
						local y = model:GetPos().y
						local c = data.ClickCollision
						local squareobj = {
							x = {
								x + c[1].x,
								x + c[2].x,
							},
							y = {
								y + c[1].y,
								y + c[2].y,
							},
						}
						local squarerect = {
							x = {
								rect.Start.x,
								rect.End.x,
							},
							y = {
								rect.Start.y,
								rect.End.y,
							},
						}
						model.Highlighted = intersect_squares( squareobj, squarerect )
						LocalPlayer().PRK_Editor_RoomData.HighlightedModel[k] = model.Highlighted
						LocalPlayer().PRK_Editor_RoomData.DraggingModelSelectorSnap = true
					end
				end
			end

			-- Move cursor to mid point
			-- local mid = rect.Start + ( rect.End - rect.Start ) / 2
			-- print( mid )
			-- input.SetCursorPos( ScrW() / 2, ScrH() / 2 )

			-- Start dragging these
			PRK_Editor_Room_HandleDrag()
		end
		local function createfloor()
			
		end

		-- local menu = vgui.Create( "DMenu", LocalPlayer().ContextMenu )
			-- menu:SetPos( gui.MouseX(), gui.MouseY() )
			-- menu:AddOption(
				-- "Select",
				-- function()
					-- selection()
					-- LocalPlayer().PRK_Editor_RoomData.RectangleSelector = nil
				-- end
			-- )
			-- menu:AddOption(
				-- "Create Floor",
				-- function()
					-- createfloor()
					-- LocalPlayer().PRK_Editor_RoomData.RectangleSelector = nil
				-- end
			-- )
		-- menu:Open()
		selection()
		LocalPlayer().PRK_Editor_RoomData.RectangleSelector = nil
		-- LocalPlayer().PRK_Editor_RoomData.RectangleSelector.Menu = menu
	end
end

hook.Add( "WhileMouseWheeling", "PRK_WhileMouseWheeling_Editor_Room_Zoom", function( wheel )
	if ( !LocalPlayer().PRK_Editor_Room )  then return end

	-- Zoom in/out with mouse wheel
	LocalPlayer().PRK_Editor_RoomData.TargetZoom = math.Clamp(
		LocalPlayer().PRK_Editor_RoomData.TargetZoom - ( wheel * PRK_Editor_Zoom_Step ),
		PRK_Editor_Zoom_Min,
		PRK_Editor_Zoom_Max
	)
end )

function PRK_Editor_Room_GetClosestGrid( pos )
	local ret = Vector()
		if ( pos ) then
			ret.x = math.Round( ( pos.x ) / PRK_Editor_Square_Size - 0.5 )
			ret.y = math.Round( ( pos.y ) / PRK_Editor_Square_Size + 0.5 )
		end
	return ret
end

function PRK_Editor_Room_AddFloor( pos, isattach )
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
		isattach = isattach,
	}
	table.insert( LocalPlayer().PRK_Editor_RoomData.Parts, part )
end

function PRK_Editor_Room_RemoveFloor( index )
	table.remove( LocalPlayer().PRK_Editor_RoomData.Parts, index )
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
			model:SetColor( PlaceableEnts[ent].Colour )
			model.PRK_Editor_Ent = ent
		table.insert( LocalPlayer().PRK_Editor_RoomData.Models, model )
		return model
	end
end

function PRK_Editor_Room_RemoveEnt( index )
	LocalPlayer().PRK_Editor_RoomData.Models[index]:Remove()
	table.remove( LocalPlayer().PRK_Editor_RoomData.Models, index )
end

function PRK_Editor_Room_Import()
	-- Cleanup any old stuff
	if ( LocalPlayer().PRK_Editor_RoomData and LocalPlayer().PRK_Editor_RoomData.Models ) then
		-- Remove models
		for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.Models ) do
			model:Remove()
		end
	end

	-- Import new
	local dir = PRK_DataPath
	local filename = LocalPlayer():SteamID64()
	if ( file.Exists( dir .. filename .. ".txt", "DATA" ) ) then
		local json = file.Read( dir .. filename .. ".txt" )
		LocalPlayer().PRK_Editor_RoomData = util.JSONToTable( json )
	end

	-- Create any imported stuff with extra steps
	-- Add models
	LocalPlayer().PRK_Editor_RoomData.Models = {}
	for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.ModelExportInstructions ) do
		local ent = PRK_Editor_Room_AddEnt( model.Pos, model.Editor_Ent )
		if ( ent ) then
			ent:SetPos( model.Pos )
			ent:SetAngles( model.Angles )
		else
			local ent = PRK_AddModel(
				model.Model,
				model.Pos,
				model.Angles,
				model.Scale
			)
				ent:SetNoDraw( true )
			table.insert( LocalPlayer().PRK_Editor_RoomData.Models, ent )
		end
	end

	-- Add missing empty tables
	LocalPlayer().PRK_Editor_RoomData.Highlighted = {}
	LocalPlayer().PRK_Editor_RoomData.HighlightedModel = {}
end

function PRK_Editor_Room_Export( server )
	local dir = PRK_DataPath
	local filename = LocalPlayer():SteamID64()
	local content = ""
		-- Convert tables to json
		local tab = table.shallowcopy( LocalPlayer().PRK_Editor_RoomData )
			-- Store new instruction data
			tab.ModelExportInstructions = {}
			for k, model in pairs( tab.Models ) do
				local instructions = {
					Model = model:GetModel(),
					Pos = model:GetPos(),
					Angles = model:GetAngles(),
					Scale = model:GetModelScale(),
					Editor_Ent = model.PRK_Editor_Ent,
				}
				table.insert( tab.ModelExportInstructions, instructions )
			end
			-- Nullify anything not needed to generate this room again
			tab.Highlighted = nil
			tab.HighlightedModel = nil
			tab.Models = nil
			-- Remove extra data from parts
			for k, part in pairs( tab.Parts ) do
				part.Highlighted = nil
				part.prebreadth = nil
				part.prewidth = nil
				part.preposx = nil
				part.preposy = nil
			end
		content = util.TableToJSON( tab )
	if ( server ) then
		SendEditorExport( content )
	else
		file.CreateDir( dir )
		file.Write( dir .. filename .. ".txt", content )
	end
end

function PRK_CalcView_Editor_Room( ply, origin, angles, fov )
	if LocalPlayer().PRK_Editor_Room then
		local view = {}
			view.angles = angles
				-- From -180->180 to 5->180
				local min = 30
				local max = 90
				-- print( view.angles.p )
				view.angles.p = ( ( 1 - ( view.angles.p + 90 ) / 180 ) * ( max - min ) ) + min
			view.origin = LocalPlayer().PRK_Editor_RoomData.CameraPos + view.angles:Forward():GetNormal() * -LocalPlayer().PRK_Editor_RoomData.Zoom
			LocalPlayer().PRK_Editor_RoomData.ViewOrigin = view.origin
		return view
	end
	return false
end

hook.Add( "PostDrawHUD", "PRK_PostDrawHUD_Editor", function()
	if !LocalPlayer().PRK_Editor_Room then return end

	-- Draw all editor models
	cam.Start3D()
		-- Draw models
		for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.Models ) do
			if ( model.Highlighted ) then
				render.SetColorModulation( 50, 50, 50 )
			else
				render.SetColorModulation( 1, 1, 1 )
			end
			model:DrawModel()
		end

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
		cam.Start3D2D( LocalPlayer().PRK_Editor_RoomData.Origin + Vector( 0, 0, 0 ), Angle( 0, 0, 0 ), scale )
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
			local colour_attach = Color( 100, 200, 100, 100 )
			if ( LocalPlayer().PRK_Editor_RoomData.Parts ) then
				for k, v in pairs( LocalPlayer().PRK_Editor_RoomData.Parts ) do
					surface.SetDrawColor( colour_floor )
						if ( v.isattach ) then
							surface.SetDrawColor( colour_attach )
						end
					surface.DrawRect(
						v.position.x / scale,
						-v.position.y / scale,
						v.width / scale,
						v.breadth / scale
					)
				end
			end
			
			-- Draw rectangle selector
			if ( LocalPlayer().PRK_Editor_RoomData.RectangleSelector ) then
				local rect = LocalPlayer().PRK_Editor_RoomData.RectangleSelector
				if ( rect.End ) then
					surface.SetDrawColor( Color( 200, 100, 200, 100 ) )
					surface.DrawRect(
						rect.Start.x / scale,
						-rect.Start.y / scale,
						( rect.End.x - rect.Start.x ) / scale,
						-( rect.End.y - rect.Start.y ) / scale
					)
				end
			end

			local pos = PRK_Editor_Room_RayToPlane( LocalPlayer():GetEyeTrace().Normal )
			if ( pos ) then
				local colour_highlight = Color( 200, 200, 200, 100 )

				-- Draw model highlight
				local modelhighlighted = false
				for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.Models ) do
					if ( model.PRK_Editor_Ent ) then
						local data = PlaceableEnts[model.PRK_Editor_Ent]
						if ( data and data.ClickCollision ) then
							-- local pos = pos / scale
							local x = model:GetPos().x
							local y = model:GetPos().y
							local c = data.ClickCollision
							local square = {
								x = {
									x + c[1].x,
									x + c[2].x,
								},
								y = {
									y + c[1].y,
									y + c[2].y,
								},
							}
							model.Highlighted = intersect_point_square( pos, square ) and vgui.CursorVisible()
							modelhighlighted = modelhighlighted or model.Highlighted
							LocalPlayer().PRK_Editor_RoomData.HighlightedModel[k] = model.Highlighted
						end
					end
				end

				-- Draw floor edge drag highlight
				local border_highlight = PRK_Editor_Square_Border_Min + PRK_Editor_Square_Border_Add / PRK_Editor_Zoom_Max * LocalPlayer().PRK_Editor_RoomData.Zoom
				surface.SetDrawColor( colour_highlight )
				for k, v in pairs( LocalPlayer().PRK_Editor_RoomData.Parts ) do
					LocalPlayer().PRK_Editor_RoomData.Highlighted[k] = {}

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
						if ( !LocalPlayer().PRK_Editor_RoomData.Dragging and vgui.CursorVisible() and !modelhighlighted ) then
							-- Only look for new highlights when not currently dragging
							LocalPlayer().PRK_Editor_RoomData.Highlighted[k][_] = intersect_point_square( pos, square )
						end
						-- if ( LocalPlayer().PRK_Editor_RoomData.Highlighted[k][_] or _ ==5 ) then
						if ( LocalPlayer().PRK_Editor_RoomData.Highlighted[k][_] or ( LocalPlayer().PRK_Editor_RoomData.Dragging and LocalPlayer().PRK_Editor_RoomData.Dragging[k] and LocalPlayer().PRK_Editor_RoomData.Dragging[k][_] ) ) then
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
		-- for k, model in pairs( LocalPlayer().PRK_Editor_RoomData.Models ) do
			-- model:Remove()
		-- end
	end

	-- Serverside logic
	SendInEditor( ply.PRK_Editor_Room )
end )
