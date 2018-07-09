include( "shared.lua" )

require( "3d2dvgui" )

-- Get global size
local size = PRK_Plate_Size
local hsize = size / 2

-- Tweakable Variables
local scale					= 0.15 -- 0.097
local hori					= 1.4
local vert					= 1

local col_text_title		= Color( 234, 0, 150 ) -- PRK_HUD_Colour_Shadow
local col_background_title	= PRK_HUD_Colour_Main
local col_background_main	= PRK_HUD_Colour_Dark
local col_background_hover	= col_text_title

local reload = true
function ENT:Think()
	self.PlayerDist = self:GetPos():Distance( LocalPlayer():GetPos() )
	self.InRange = self.PlayerDist < self.MaxUseRange

	-- Autoreload helper
	if ( reload ) then
		self:Initialize()
		reload = false
	end
end

net.Receive( "PRK_UIMachine_Stock", function( len, ply )
	local self = net.ReadEntity()
	local stock = net.ReadTable()

	print( "receive stock" )
	self.Stock = stock
	local function try()
		print( "try to init..." )
		if ( self and self:IsValid() and self.Initialize ) then
			self:Initialize()
		else
			-- Try again after the ent is available to the client
			timer.Simple( 1, function()
				if ( !self.UI ) then
					try()
				end
			end )
		end
	end
	try()
end )

function ENT:SendSelection( selection )
	net.Start( "PRK_UIMachine_Select" )
		net.WriteEntity( self )
		net.WriteString( selection )
	net.SendToServer()
end

function ENT:Initialize()
	print( "initialising..." )
	if ( self.UI ) then self.UI:Remove() self.UI = nil end
	print( "creating ui..." )
	if ( self.Stock ) then
		PrintTable( self.Stock )
	end

	local ui_w = PRK_Plate_Size / scale * hori
	local ui_h = PRK_Plate_Size / scale * vert
	local ui_main_h = ui_h / 3.5 * 2

	-- Main mission select UI
	self.UI = vgui.Create( "DFrame" )
	self.UI:SetPos( 0, 0 )
	self.UI:SetSize( ui_w, ui_h )
	self.UI:SetTitle( "" )
	self.UI:ShowCloseButton( false )
	self.UI:SetDraggable( false )
	self.UI.Entity = self
	function self.UI:Paint( w, h )
		local x, y = 0, 0

		local function draw_panel_title()
			-- Background
			draw.RoundedBox( 0, 0, 0, w, h / 3, col_background_title )

			-- Title text
			x = w / 2
			y = 32
			PRK_DrawText(
				"BULLETS",
				x,
				y,
				col_text_title,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				64,
				false
			)
			PRK_DrawText(
				"AND STUFF",
				x,
				y + 24 * 1.5,
				col_text_title,
				TEXT_ALIGN_CENTER,
				TEXT_ALIGN_CENTER,
				24,
				false
			)
		end

		local function draw_panel_main()
			local function mask()
				draw.RoundedBox( 0, 0, h / 2.5, w, ui_main_h, col_background_main )

				if (
					( self.Entity.ButtonHovered and self.Entity.ButtonHovered:IsValid() ) or
					( self.Entity.LastButtonHovered and self.Entity.LastButtonHovered:IsValid() )
				) then
					-- Large rectangular cursor
						-- For if no buttons are hovered, but was still lerping
						local butt = self.Entity.ButtonHovered
						if ( butt != nil ) then
							self.Entity.LastButtonHovered = butt
						else
							butt = self.Entity.LastButtonHovered
						end
						local border = 4
						local frametime = FrameTime() -- 0.016
						local speed = 10
						local x, y = butt:GetPos()
							x = x - border
						-- Store for lerping
						if ( !self.RectCursY ) then
							self.RectCursY = y
						end
						local old = self.RectCursY
							self.RectCursY = Lerp( frametime * speed, self.RectCursY, y )
						local change = math.abs( self.RectCursY - old )
						local w, h = butt:GetSize()
							w = w + border
						-- Squash/stretch while moving
							y = self.RectCursY
							local effect = 20
							local dirx = -1
							local diry = 1
							change = change * effect
							x = x + dirx * change / 2
							w = w - dirx * change
							y = y + diry * change / 2
							h = h - diry * change
					draw.RoundedBox( 0, x, y, w, h, col_background_hover )
				end
			end
			local function inner()
				if ( self.Entity.InRange ) then-- and !self.Entity.ButtonHovered ) then
					-- Small square cursor
					-- CursorX = gui.MouseX()
					-- CursorY = gui.MouseY()
					-- if ( CursorX > 0 and CursorX < ui_w and CursorY > 0 and CursorY < ui_h ) then
						-- local cursorw = PRK_CursorSize
						-- local cursorh = cursorw
						-- draw.Box( CursorX - cursorw / 2, CursorY - cursorh / 2, cursorw, cursorh, Color( 255, 255, 255, 255 ) )
					-- end
				end
			end
			draw.StencilBasic( mask, inner )
		end

		draw_panel_title()
		draw_panel_main()
	end

	local function canpurchase( price )
		local money = LocalPlayer():GetNWInt( "PRK_Money" )
		local afford = ( money >= price )
		return ( self.Entity.InRange && afford )
	end

	-- Main buttons
	local borderx = 4
	local bordery = 32
	local buttons = 4
	local but_w = ui_w + borderx * 2
	local but_h = ( ui_main_h - bordery ) / buttons
	local x = -borderx
	local y = ( ui_h + bordery ) / 2.5
	if ( self.Stock ) then
		local buttonid = 1
		for name, data in pairs( self.Stock ) do
			local price = data[1]
			local button = vgui.Create( "DButton", self.UI )
			button:SetPos( x, y )
			button:SetSize( but_w, but_h )
			button:SetText( "" )
			button.Entity = self
			button.ButtonLeftText = name
			button.ButtonRightText = PRK_GetAsCurrency( price )
			function button:OnCursorEntered()
				if ( self.Entity.InRange and self.Entity.ButtonHovered != self ) then
					self.Hovered = true
					self.Entity.ButtonHovered = self
					self.Entity:EmitSound( "hl1/fvox/blip.wav" )
					PRK_LookAtUsable( self, "BUY" )
				end
			end
			function button:OnCursorExited()
				if ( self.Entity.ButtonHovered == self ) then
					self.Hovered = false
					self.Entity.ButtonHovered = nil
					PRK_LookAwayFromUsable()
				end
			end
			function button:Think()
				if ( self.Entity.ButtonHovered == self ) then
					if ( self.Entity.InRange ) then
						PRK_LookAtUsable( self, "BUY" )
					else
						PRK_LookAwayFromUsable()
					end
				end
			end
			function button:Paint( w, h )
				-- Left
				PRK_DrawText(
					self.ButtonLeftText,
					32,
					h / 2,
					PRK_HUD_Colour_Highlight,
					TEXT_ALIGN_LEFT,
					TEXT_ALIGN_CENTER,
					36,
					false
				)

				-- Right
				PRK_DrawText(
					self.ButtonRightText,
					w - 32,
					h / 2,
					PRK_HUD_Colour_Highlight,
					TEXT_ALIGN_RIGHT,
					TEXT_ALIGN_CENTER,
					36,
					false
				)
			end
			function button:DoClick( button )
				if ( self.Entity.InRange ) then
					if ( canpurchase( price ) ) then
						self.Entity:SendSelection( name )
					else
						-- Deny sound
						self.Entity:EmitSound( "npc/scanner/combat_scan3.wav", 75, math.random( 90, 110 ) )
					end
				end
			end
			y = y + but_h

			-- Count buttons and stop after max reached
			buttonid = buttonid + 1
			if ( buttonid > buttons ) then
				break
			end
		end
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	if ( self.UI ) then
		self.UI:Remove()
		self.UI = nil
	end
end

hook.Add( "PostDrawOpaqueRenderables", "PRK_PostDrawOpaqueRenderables_UIMachine", function()
	for k, ent in pairs( ents.FindByClass( "prk_uimachine" ) ) do
		if ( ent.UI ) then
			local ang = ent:GetAngles()
				ang:RotateAroundAxis( ent:GetAngles():Right(), -90 )
				ang:RotateAroundAxis( ent:GetAngles():Forward(), 90 )
			vgui.Start3D2D(
				ent:GetPos() +
				ent:GetAngles():Up() * size * ( vert + 0.2 ) +
				ent:GetAngles():Forward() * ( hsize + 0.2 ) +
				ent:GetAngles():Right() * hsize * hori
				,
				ang,
				scale
			)
				ent.UI:Paint3D2D()
			vgui.End3D2D()
		end
	end
end )
