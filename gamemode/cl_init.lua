--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Clientside
--

include( "shared.lua" )
include( "sh_items.lua" )

include( "cl_editor_room.lua" )
include( "cl_modelcache.lua" )

-- Materials
PRK_Material_Icon_Bullet = Material( "icon_bullet.png", "noclamp smooth" )
local mats = {
	Material( "prk_splat1.png", "noclamp" ),
	Material( "prk_splat2.png", "noclamp" ),
}
PRK_Material_Splat = function()
	return mats[math.random( 1, #mats - 1 )]
end

-- Resolution scaling
local BaseResW = 1600
local BaseResH = 900
function PRK_GetResolutionIndependent( num )
	return math.min( PRK_GetResolutionIndependentW( num ), PRK_GetResolutionIndependentH( num ) )
end

function PRK_GetResolutionIndependentW( x )
	return ( x / BaseResW ) * ScrW()
end

function PRK_GetResolutionIndependentH( y )
	return ( y / BaseResH ) * ScrH()
end

-- Fonts
local function loadfonts()
	local fontsizes = {
		16,
		20,
		24,
		30,
		36,
		48,
		64,
		96,
		128
	}
	for k, size in pairs( fontsizes ) do
		-- Resolution Scaled
		surface.CreateFont( "HeavyHUD" .. size, {
			font = "Alte Haas Grotesk",
			extended = false,
			size = PRK_GetResolutionIndependentH( size ),
			weight = 2000,
			blursize = 1,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false,
		} )
		-- Absolute
		surface.CreateFont( "HeavyHUD" .. size .. "_Abs", {
			font = "Alte Haas Grotesk",
			extended = false,
			size = size,
			weight = 2000,
			blursize = 1,
			scanlines = 0,
			antialias = true,
			underline = false,
			italic = false,
			strikeout = false,
			symbol = false,
			rotary = false,
			shadow = false,
			additive = false,
			outline = false,
		} )
	end
end
loadfonts()

-- Sounds
sound.Add( 
	{ 
		name = "prk_reload_alarm",
		channel = CHAN_ITEM,
		level = 75,
		volume = 0.05,
		pitch = 255,
		sound = "ambient/alarms/apc_alarm_loop1.wav"
	}
 )
sound.Add( 
	{ 
		name = "prk_death",
		channel = CHAN_STREAM,
		level = 75,
		volume = 1,
		pitch = 255,
		sound = PRK_Death_Sound
	}
 )

-- Variables
local LagX = 10
local LagY = 5
local CursorX, CursorY, LastCursorX, LastCursorY

-- Net
PRK_NetKeyValues = {}
net.Receive( "PRK_KeyValue", function( len, ply )
	local key = net.ReadString()
	local val = net.ReadString()

	PRK_NetKeyValues[key] = val
end )

net.Receive( "PRK_TakeDamage", function( len, ply )
	local ply = net.ReadEntity()
	local amount = net.ReadFloat()
	local dir = net.ReadVector()
	local pos = net.ReadVector()

	ply.PunchHUD = dir * amount * PRK_HUD_Punch_Amount
	ply.HideHurtEffect = CurTime() + PRK_Hurt_ShowTime

	-- Play blood effect
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( dir )
		effectdata:SetStart( ColourToVector( ply:GetColor() ) )
		effectdata:SetScale( 0 )
	util.Effect( "prk_blood", effectdata )
end )

net.Receive( "PRK_Blood", function( len )
	local pos = net.ReadVector()
	local dir = net.ReadVector()
	local col = net.ReadColor()

	-- Play blood effect
	local effectdata = EffectData()
		effectdata:SetOrigin( pos )
		effectdata:SetNormal( dir )
		effectdata:SetStart( ColourToVector( col ) )
		effectdata:SetScale( 0 )
	util.Effect( "prk_blood", effectdata )
end )

net.Receive( "PRK_Die", function( len )
	local ply = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()
	local killname = net.ReadString()

	-- Try death particles at bone positions ( inspired by Panic Ritual )
	local points = {}
		-- Add playermodel bones
		local bones = ply:GetBoneCount()
		for bone = 0, bones - 1 do
			local name = ply:GetBoneName( bone )
			if ( !string.find( name, "Finger" ) ) then
				local pos = ply:GetBonePosition( bone )
				local dir = VectorRand()
					if ( ply:GetBoneMatrix( bone ) ) then
						dir = ply:GetBoneMatrix( bone ):GetForward()
					end
				table.insert( points, {
					pos = pos,
					dir = dir,
				} )
			end
		end
		-- Extra for head and shell
		local head = ply:GetBonePosition( 6 )
		table.Add( points, {
			{ pos = head + Vector( 0, 0, 15 ) },
			{ pos = head + Vector( -15, 0, 15 ) },
			{ pos = head + Vector( 15, 0, 10 ) },
		} )
	for k, point in pairs( points ) do
		local effectdata = EffectData()
			effectdata:SetOrigin( point.pos )
			effectdata:SetNormal( point.dir or VectorRand() )
			-- effectdata:SetEntity( ply )
			effectdata:SetStart( ColourToVector( ply:GetColor() ) )
			effectdata:SetScale( 0.1 )
		util.Effect( "prk_blood", effectdata )
	end

	-- Self death effect
	if ( ply == LocalPlayer() ) then
		LocalPlayer().DieEffect = {
			pos,
			ang,
			0,
			killname,
			TimeMin = CurTime() + 1,
		}

		LocalPlayer():EmitSound( "prk_death" )

		-- Reset everything
		PRK_Initialise_RevolverChambers()
		LocalPlayer().PRK_Gateway = nil
		LocalPlayer().PunchHUD = Vector()
		LocalPlayer().HideHurtEffect = 0
	end
end )

net.Receive( "PRK_Drink", function( len )
	local ply = net.ReadEntity()

	ply.Bite = 0
end )

net.Receive( "PRK_Spawn", function( len, ply )
	local time = net.ReadFloat()

	LocalPlayer().SpawnTime = time
end )

net.Receive( "PRK_ResetZone", function( len, ply )
	local zone = net.ReadFloat()

	if ( LocalPlayer().PRK_Decals and LocalPlayer().PRK_Decals[zone] ) then
		LocalPlayer().PRK_Decals[zone] = {}
	end
end )

-- Gamemode Hooks
function GM:Initialize()
	PRK_Initialise_RevolverChambers()
end

function GM:Think()
	PRK_Think_Die()

	PRK_Think_RevolverChambers()
	PRK_Think_Punch()
	PRK_Think_Use()
	PRK_Think_Item()

	-- Find current room
	local zone = LocalPlayer():GetNWInt( "PRK_Zone", 0 )
	if ( zone != 0 and PRK_Zones[zone] ) then
		local size = PRK_Plate_Size
		local gridpos = LocalPlayer():GetPos() - PRK_Zones[zone].pos
			gridpos = gridpos / size
			gridpos.x = math.Round( gridpos.x )
			gridpos.y = math.Round( gridpos.y )
		local roomid = nil
			if ( PRK_Floor_Grid and PRK_Floor_Grid[zone] and PRK_Floor_Grid[zone][gridpos.x] ) then
				roomid = PRK_Floor_Grid[zone][gridpos.x][gridpos.y]
			end
		if ( roomid != nil ) then
			LocalPlayer().PRK_Room = roomid
		end
	end
end

function PRK_Think_Punch()
	if ( LocalPlayer().PunchHUD ) then
		LocalPlayer().PunchHUD = LerpVector( FrameTime() * PRK_HUD_Punch_Speed, LocalPlayer().PunchHUD, Vector() )
		-- Reset any punches on death
		if ( !LocalPlayer():Alive() ) then
			LocalPlayer().PunchHUD = Vector()
		end
	end
end

function PRK_Think_Die()
	-- Die effects
	if ( !LocalPlayer():Alive() and LocalPlayer().DieEffect ) then
		local speedpos = 5
		local speedang = 5
		local speedcol = 3
		LocalPlayer().DieEffect[1] = LerpVector( 
			FrameTime() * speedpos,
			LocalPlayer().DieEffect[1],
			Vector( LocalPlayer().DieEffect[1].x, LocalPlayer().DieEffect[1].y, LocalPlayer():GetPos().z + 3 )
		 )
		LocalPlayer().DieEffect[2] = LerpAngle( 
			FrameTime() * speedang,
			LocalPlayer().DieEffect[2],
			Angle( 0, LocalPlayer().DieEffect[2].y, 0 )
		 )
		LocalPlayer().DieEffect[3] = Lerp( 
			FrameTime() * speedcol,
			LocalPlayer().DieEffect[3],
			PRK_HUD_DieEffect_MaxAlpha
		 )
	elseif ( LocalPlayer().DieEffect and LocalPlayer().DieEffect.TimeMin <= CurTime() ) then
		LocalPlayer():StopSound( "prk_death" )
		LocalPlayer().DieEffect = nil
	end
end

function PRK_Think_Use()
	-- Look at entity
	local tr = LocalPlayer():GetEyeTrace()
	if ( tr.Entity and tr.Entity:IsValid() and tr.Entity.UseLabel ) then
		local dist = LocalPlayer():EyePos():Distance( tr.Entity:GetPos() )
		if ( dist <= PRK_UseRange ) then
			PRK_LookAtUsable( tr.Entity )
		else
			PRK_LookAwayFromUsable()
		end
	elseif ( LocalPlayer().LookingAtUsable and IsEntity( LocalPlayer().LookingAtUsable ) ) then
		PRK_LookAwayFromUsable()
	end

	-- Failsafe for looking at
	if ( LocalPlayer().LookingAtUsable and !LocalPlayer().LookingAtUsable:IsValid() ) then
		PRK_LookAwayFromUsable()
	end
end

function PRK_Think_Item()
	if ( !LocalPlayer().Item_CurrentY ) then
		LocalPlayer().Item_CurrentY = 0
		LocalPlayer().Item_TargetY = 0
	end

	-- Remove target if no item ( set every frame in HUDPaint_Item )
	if ( !PRK_GetItem( LocalPlayer() ) ) then
		LocalPlayer().Item_TargetY = ScrH() * 1.2
	end

	-- Lerp
	local speed = 10
	LocalPlayer().Item_CurrentY = Lerp( FrameTime() * speed, LocalPlayer().Item_CurrentY, LocalPlayer().Item_TargetY )
end

function PRK_LookAtUsable( ent, text )
	-- Only play sound if actually has to rotate
	-- ( i.e. wasn't already looking at something, and wasn't looking at something very recently )
	if ( 
		!LocalPlayer().LookingAtUsable and
		( !LocalPlayer().LookingAtLastTime or LocalPlayer().LookingAtLastTime + 0.04 <= CurTime() )
	 ) then
		LocalPlayer():EmitSound( "npc/barnacle/barnacle_bark1.wav", 50, 255, 0.1 )
	end

	if ( LocalPlayer().LookingAtUsable != ent ) then
		LocalPlayer().LookingAtUsable = ent

		if ( text ) then
			LocalPlayer().LabelText = text
		elseif ( ent.UseLabel ) then
			LocalPlayer().LabelText = ent.UseLabel
		else
			LocalPlayer().LabelText = "USE"
		end
	end

	LocalPlayer().LookingAtLastTime = CurTime()
end

function PRK_LookAwayFromUsable()
	if ( LocalPlayer().LookingAtUsable ) then
		LocalPlayer().LookingAtUsable = nil
		-- Allow some time to look at another usable before playing the disappear sound
		timer.Simple( 0.04, function()
			if ( !LocalPlayer().LookingAtUsable ) then
				LocalPlayer():EmitSound( "npc/barnacle/barnacle_bark1.wav", 50, 255, 0.1 )
			end
		end )
	end
end

function GM:HUDPaint()
	-- Don't draw HUD if dead
	if ( !LocalPlayer():Alive() ) then
		PRK_HUDPaint_Death()
		return
	end

	PRK_HUDPaint_Health()

	PRK_HUDPaint_Money()

	PRK_HUDPaint_ExtraAmmo()
	PRK_HUDPaint_RevolverChambers()

	PRK_HUDPaint_Item()

	-- Should also be last
	PRK_HUDPaint_Crosshair()

	-- Must be last! ( for HUD lag )
	if ( !LocalPlayer().LastEyeAngles ) then
		LocalPlayer().LastEyeAngles = LocalPlayer():EyeAngles()
	end
	LocalPlayer().LastEyeAngles = LerpAngle( FrameTime() * 10, LocalPlayer().LastEyeAngles, LocalPlayer():EyeAngles() )
end

function GM:PostRender()
	LastCursorX = CursorX
	LastCursorY = CursorY
end

function GM:RenderScreenspaceEffects()
	if ( LocalPlayer().HideHurtEffect and LocalPlayer().HideHurtEffect > CurTime() ) then
		DrawTexturize( LocalPlayer().PunchHUD:Length(), Material( PRK_Hurt_Material ) )
	elseif ( !LocalPlayer():Alive() ) then
		DrawTexturize( 1, Material( PRK_Death_Material ) )
	end
end

-- This could be tidier but it works : )
local lastlabelang = Angle()
local lastcursorang = Angle()
hook.Add( "PostDrawTranslucentRenderables", "PRK_PostDrawTranslucentRenderables_LabelHelp", function()
	-- Draw floating in front of the player for polish lerp rotation effects
	local dist = 10
	local dist_snap = 100
	local scal = 0.0125
	local speed_cursor = 20
	local speed = 7
	local forward = LocalPlayer():GetEyeTrace().Normal -- LocalPlayer():GetEyeTraceNoCursor().Normal
	local pos = LocalPlayer():EyePos() + ( forward * dist )

	-- Get target rotation
	local function gettarget( label )
		local targetang = forward:Angle()
			-- Use surface normal if close to something
			local tr = LocalPlayer():GetEyeTrace()
			local up, right
			if ( tr.Hit and tr.HitPos:Distance( LocalPlayer():EyePos() ) <= dist_snap and LocalPlayer().LookingAtUsable and !IsEntity( LocalPlayer().LookingAtUsable ) ) then
				forward = -tr.HitNormal
				targetang = forward:Angle()
				up = Vector( 0, 0, 1 )
				right = up:Cross( forward )
			else
				right = LocalPlayer():GetRight()
				up = LocalPlayer():GetUp()
				-- Emphasise lag horizontally if not using surface normal
				if ( LocalPlayer().LastEyeAngles ) then
					local x = ( LocalPlayer():EyeAngles() - LocalPlayer().LastEyeAngles ).y
					targetang:RotateAroundAxis( right, x * 4 )
				end
				if ( LastCursorX ) then
					local x = CursorX - LastCursorX
					targetang:RotateAroundAxis( right, x * 8 )
				end
			end
			-- Always emphasise lag vertically
			if ( LocalPlayer().LastEyeAngles ) then
				local y = ( LocalPlayer():EyeAngles() - LocalPlayer().LastEyeAngles ).x
				targetang:RotateAroundAxis( up, y * 4 )
			end
			if ( LastCursorX ) then
				local y = CursorY - LastCursorY
				targetang:RotateAroundAxis( up, y * 8 )
			end
			-- Label lerp in/out
			if ( !label or LocalPlayer().LookingAtUsable ) then
				targetang:RotateAroundAxis( forward, -90 )
				if ( label ) then
					LocalPlayer().LabelHideDelay = CurTime() + 0.3
				end
			end
			targetang:RotateAroundAxis( right, 180 )
			targetang:RotateAroundAxis( up, 90 )
		return targetang
	end

	-- Draw label
	local targetang = gettarget( true ) -- Must be outside of if to check for label shown
	if ( LocalPlayer().LabelHideDelay and LocalPlayer().LabelHideDelay > CurTime() ) then
		lastlabelang = LerpAngle( FrameTime() * speed, lastlabelang, targetang )
		cam.Start3D2D( pos, lastlabelang, scal )
			PRK_HUDPaint_CrosshairHelp()
		cam.End3D2D()
	end
	-- Draw cursor
	-- local targetang = gettarget( false )
	-- lastcursorang = LerpAngle( FrameTime() * speed_cursor, lastcursorang, targetang )
	-- cam.Start3D2D( pos, lastcursorang, scal )
		-- PRK_HUDPaint_Crosshair()
	-- cam.End3D2D()
end )

function GM:PostDrawHUD()
	cam.Start3D()
		local wep = LocalPlayer():GetActiveWeapon()
		if ( wep.GunModel and wep.GunModel:IsValid() ) then
			wep.GunModel:DrawModel()
		end
		-- LocalPlayer():GetViewModel():DrawModel()
	cam.End3D()
end

local hide = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
	["CHudDamageIndicator"] = true,
}
function GM:HUDShouldDraw( name )
	-- print( name )
	if ( hide[ name ] ) then return false end

	return PRK_ShouldDraw()
end

if ( !PRK_SANDBOX ) then
function CreateContextMenu()
	-- Destroy any old
	DestroyContextMenu()

	-- Create new
	if ( PRK_ContextMenu ) then
		g_ContextMenu = vgui.Create( "EditablePanel" )
			function g_ContextMenu:Paint( w, h )
				
			end
			g_ContextMenu:SetPos( 0, 0 )
			g_ContextMenu:SetSize( ScrW(), ScrH() )
			--
			-- We're blocking clicks to the world - but we don't want to
			-- so feed clicks to the proper functions..
			--
			g_ContextMenu.OnMousePressed = function( p, code )
				hook.Run( "GUIMousePressed", code, gui.ScreenToVector( gui.MousePos() ) )
			end
			g_ContextMenu.OnMouseReleased = function( p, code )
				hook.Run( "GUIMouseReleased", code, gui.ScreenToVector( gui.MousePos() ) )
			end
			g_ContextMenu:RequestFocus()
			g_ContextMenu:MouseCapture()
			g_ContextMenu:MakePopup()
			g_ContextMenu:SetKeyboardInputEnabled( false )
			g_ContextMenu:SetMouseInputEnabled( true )
			g_ContextMenu:SetWorldClicker( true )
		LocalPlayer().ContextMenu = g_ContextMenu
	end
end

function DestroyContextMenu()
	if ( IsValid( g_ContextMenu ) ) then
		g_ContextMenu:Remove()
		g_ContextMenu = nil
	end
end

function GM:ContextMenuOpen()
	return ( CurTime() >= 1 )
end

function GM:OnContextMenuOpen()
	if ( !hook.Call( "ContextMenuOpen", GAMEMODE ) ) then return end

	-- CreateContextMenu()
end

function GM:OnContextMenuClose()
	DestroyContextMenu()
end
end

-- Blocking jump/crouch with overrides
-- Block weapon switching with no override
local blockdefault = {
	"slot1",
	"slot2",
	"slot3",
	"slot4",
	"slot5",
	"slot6",
	"slot6",
	"invprev",
	"invnext",
}
hook.Add( "PlayerBindPress", "PRK_PlayerBindPress_BlockInput", function( ply, bind )
	-- Blocking with overrides
	if string.find( bind, "+jump" ) then
		ply.Jumping = !ply.Jumping
		if ( ply.Jumping ) then
			ply:ConCommand( "+prk_jump" )
		end
		return true
	end
	if string.find( bind, "+duck" ) then
		ply.Ducking = !ply.Ducking
		if ( ply.Ducking ) then
			ply:ConCommand( "+prk_duck" )
		end
		return true
	end

	-- Blocking without overrides
	for k, v in pairs( blockdefault ) do
		if ( string.find( bind, v ) ) then
			return true
		end
	end
end )

hook.Add( "StartCommand", "PRK_StartCommand", function( ply, cmd )
	local wheel = cmd:GetMouseWheel()
	if ( wheel != 0 ) then
		hook.Call( "WhileMouseWheeling", GAMEMODE, wheel )
	end
end )

hook.Add( "OnResolutionChange", "PRK_OnResolutionChange_HUD", function()
	loadfonts()
end )

function PRK_HUDPaint_Death()
	if ( !LocalPlayer().DieEffect ) then return end

	surface.SetDrawColor( Color( 0, 0, 0, LocalPlayer().DieEffect[3] ) )
	draw.NoTexture()
	surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )

	local b = 16
	local x = ScrW() / 2
	local y = Lerp( 1 - ( LocalPlayer().DieEffect[3] / PRK_HUD_DieEffect_MaxAlpha ), ScrH() / 2, ScrH() + 100 )
	local w, h = PRK_DrawText( 
		"YOU DIED",
		x,
		y,
		PRK_HUD_Colour_Shadow,
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER,
		128
	 )

	if ( LocalPlayer().DieEffect[4] ) then
		local y = y + ScrH() / 2 - b
		local w, h = PRK_DrawText( 
			LocalPlayer().DieEffect[4],
			x,
			y,
			PRK_HUD_Colour_Shadow,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_BOTTOM,
			36
		 )

		y = y - h / 2 - b
		local w, h = PRK_DrawText( 
			"KILLED BY",
			x,
			y,
			PRK_HUD_Colour_Shadow,
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_BOTTOM,
			36
		 )
	end
end

function PRK_HUDPaint_Crosshair()
	local speed = 15
	local targetx = ScrW() / 2
	local targety = ScrH() / 2
		if ( !CursorX ) then
			CursorX = gui.MouseX()
			CursorY = gui.MouseY()
		end
		if ( vgui.CursorVisible() ) then
			targetx = gui.MouseX()
			targety = gui.MouseY()
		end
		CursorX = Lerp( FrameTime() * speed, CursorX, targetx )
		CursorY = Lerp( FrameTime() * speed, CursorY, targety )
	local x = 0
	local y = 0
	local x = CursorX
	local y = CursorY
	local size = PRK_CursorSize

	for i = 1, 3 do
		-- Draw crosshair shadow with lag behind
		local offx, offy = PRK_GetUIPosVelocity( x, y, 0, 0, PRK_HUD_Shadow_Effect * i )
		local col = Color( PRK_HUD_Colour_Shadow.r, PRK_HUD_Colour_Shadow.g, PRK_HUD_Colour_Shadow.b, 35 )
			col.a = col.a - i * 10
		surface.SetDrawColor( col )
		draw.NoTexture()
		local size = size * i
		surface.DrawTexturedRect( offx - ( size / 2 ), offy - ( size / 2 ), size, size )
	end

	-- Draw crosshair shadow with lag behind
	local offx, offy = PRK_GetUIPosVelocity( x, y, 0, 0, PRK_HUD_Shadow_Effect * 2 )
	surface.SetDrawColor( PRK_HUD_Colour_Shadow )
	draw.NoTexture()
	surface.DrawTexturedRect( offx - ( size / 2 ), offy - ( size / 2 ), size, size )

	-- Draw base crosshair always in the center
	surface.SetDrawColor( PRK_HUD_Colour_Main )
	draw.NoTexture()
	surface.DrawTexturedRect( x - ( size / 2 ), y - ( size / 2 ), size, size )
end

function PRK_HUDPaint_CrosshairHelp()
	if ( !CursorX ) then
		CursorX = gui.MouseX()
		CursorY = gui.MouseY()
	end
	local x = 0 -- CursorX - ScrW() / 2
	local y = 0 -- CursorY - ScrH() / 2
	-- local x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY, 2 )

	local text = LocalPlayer().LabelText or "USE"
	local fontsize = 24
	surface.SetFont( "HeavyHUD" .. fontsize )

	local width, height = surface.GetTextSize( text )
		width = width * 1.5
		height = height * 1.25
	local tri_width = width / 4
	local tri_height = height / 2

	x = x + tri_width / 2

	local function drawlabel( x, y )
		-- Draw label shape
		local tri = {
			{
				x = x + tri_width,
				y = y - tri_height,
			},
			{
				x = x + tri_width,
				y = y + tri_height,
			},
			{
				x = x,
				y = y,
			},
		}
		surface.DrawPoly( tri )

		draw.NoTexture()
		surface.DrawTexturedRect( x + tri_width, y - tri_height, width, height )
	end

	-- Draw shadow label
	surface.SetDrawColor( PRK_HUD_Colour_Shadow )
	local offx, offy = PRK_GetUIPosVelocity( x, y, LagX / 2, LagY / 2, 2 )
	drawlabel( offx, offy )

	-- Draw main label
	surface.SetDrawColor( PRK_HUD_Colour_Main )
	drawlabel( x, y )

	-- Draw help text
	PRK_DrawText( 
		text,
		x + tri_width + width / 2,
		y,
		PRK_HUD_Colour_Shadow,
		TEXT_ALIGN_CENTER,
		TEXT_ALIGN_CENTER,
		fontsize,
		false
	 )
end

function PRK_HUDPaint_Health()
	local r = PRK_GetResolutionIndependent( 32 )
	local s = r
	local sb = r + 4
	local x = r * 3
	local y = ScrH() - r * 3
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	local maxhealth = LocalPlayer():GetMaxHealth()
	local health = LocalPlayer():Health()

	-- Draw heart icons for max health shadow
	local function mask()
		local offx, offy = PRK_GetUIPosVelocity( x, y, -PRK_HUD_Shadow_DistX, PRK_HUD_Shadow_DistY, PRK_HUD_Shadow_Effect )
		for i = 1, maxhealth / 2 do
			surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
			draw.Heart( offx + ( sb + s ) * i, offy - s, s, 16 )
		end
	end
	local function inner()
		-- Draw filled rectangle for health bar
		surface.SetDrawColor( PRK_HUD_Colour_Shadow )
		draw.NoTexture()
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
		-- surface.DrawTexturedRect( x + sb, y - s * 2, ( sb + s ) * health / 2, s * 2 )
	end
	draw.StencilBasic( mask, inner )

	-- Draw heart icons for max health
	local function mask()
		for i = 1, maxhealth / 2 do
			surface.SetDrawColor( PRK_HUD_Colour_Heart_Dark )
			draw.Heart( x + ( sb + s ) * i, y - s, s, 16 )
		end
	end
	local function inner()
		-- Draw filled rectangle for health bar
		surface.SetDrawColor( PRK_HUD_Colour_Heart_Light )
		draw.NoTexture()
		-- surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
		surface.DrawTexturedRect( x + sb, y - s * 2, ( sb + s ) * health / 2, s * 2 )
	end
	draw.StencilBasic( mask, inner )
end

function PRK_HUDPaint_Money()
	local r = PRK_GetResolutionIndependent( 64 )
	local s = r
	local sb = r + 4
	local x = r * 2.2
	local y = ScrH() - r * 1
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	local money_add = LocalPlayer():GetNWInt( "PRK_Money_Add" )
	local money = LocalPlayer():GetNWInt( "PRK_Money" )
		if ( money_add ) then
			-- money = money - money_add
			local temp = money
			money = math.max( 0, money - money_add )
			money_add = temp - money
		end
	local w, h = PRK_DrawText( 
		PRK_GetAsCurrency( money ),
		x,
		y,
		PRK_HUD_Colour_Money,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
	)

	-- Temp test TODO remove
	local zone = LocalPlayer():GetNWInt( "PRK_Zone", 0 )
	if ( zone != 0 and PRK_Zones[zone] ) then
		local size = PRK_Plate_Size
		local gridpos = LocalPlayer():GetPos() - PRK_Zones[zone].pos
			gridpos = gridpos / size
			gridpos.x = math.Round( gridpos.x )
			gridpos.y = math.Round( gridpos.y )
		local roomid = ""
			if ( PRK_Floor_Grid[zone][gridpos.x] ) then
				roomid = PRK_Floor_Grid[zone][gridpos.x][gridpos.y]
			end
		local w, h = PRK_DrawText( 
			tostring( gridpos ) .. " " .. tostring( roomid ),
			x,
			64,
			PRK_HUD_Colour_Money,
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER
		)
	end

	if ( money_add and money_add != 0 ) then
		local offy = 0
		local plus = ""
			if ( money_add > 0 ) then
				plus = "+"
			end
		PRK_DrawText( 
			plus .. PRK_GetAsCurrency( money_add ),
			x + w,
			y + offy,
			PRK_HUD_Colour_Money,
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER
		 )
	end
end

function PRK_HUDPaint_Item()
	local r = PRK_GetResolutionIndependent( 96 )
	local w = r * 4
	local h = r * 2
	local dx = ScrW() / 2
	local dy = LocalPlayer().Item_CurrentY or 0
	LocalPlayer().Item_TargetY = ScrH() - r * 0.1
	-- Move slightly with player
	local x, y = PRK_GetUIPosVelocity( dx, dy, LagX, LagY )

	local function drw( x, y, col )
		surface.SetDrawColor( col )
		draw.RoundedBox( r / 4, x - w / 2, y - r / 2, w, h, col )
		draw.NoTexture()
		draw.Circle( x, y, r, 32, 0 )
	end

	-- Draw shadow
	local offx, offy = PRK_GetUIPosVelocity( x, y, -PRK_HUD_Shadow_DistX, PRK_HUD_Shadow_DistY, PRK_HUD_Shadow_Effect )
	drw( offx, offy, PRK_HUD_Colour_Shadow )

	-- Draw real
	drw( x, y, PRK_HUD_Colour_Use )

	local item = PRK_GetItem( LocalPlayer() )
	if ( item ) then
		-- Draw model thumb
		render.SuppressEngineLighting( true )
			cam.Start3D()
				local div = 4
				local lagx = -( dx - x ) / div
				local lagy = ( dy - y ) / div
				local off = Vector()
					if ( PRK_Items[item].ThumbOffset ) then
						off = PRK_Items[item].ThumbOffset
					end
				local pos = LocalPlayer():EyePos() +
					LocalPlayer():EyeAngles():Forward() * ( 200 + off.x ) +
					LocalPlayer():EyeAngles():Right() * ( -4 + lagx + off.y ) +
					LocalPlayer():EyeAngles():Up() * ( -LocalPlayer().Item_CurrentY / ScrH() * 85 + lagy + off.z )
				local ang = LocalPlayer():EyeAngles()
					ang:RotateAroundAxis( LocalPlayer():EyeAngles():Up(), -20 + CurTime() * 10 )
					ang:RotateAroundAxis( LocalPlayer():EyeAngles():Forward(), -15 + math.sin( CurTime() ) * 2 )
					ang:RotateAroundAxis( LocalPlayer():EyeAngles():Right(), 10 )
				PRK_Items[item]:Draw( LocalPlayer(), pos, ang )
			cam.End3D()
		render.SuppressEngineLighting( false )

		-- Draw info
		local y = y - ( r / 4 )
		PRK_DrawText( 
			PRK_Items[item].PrettyName,
			x,
			y,
			Color( 255, 255, 255, 255 ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER,
			48,
			false
		 )
	end
end

-----------------
  -- PRK Gun --
-----------------
function PRK_Initialise_RevolverChambers()
	PRK_RevolverChambers = {
		Ang = 0,
		TargetAng = 0,
		NoAmmoWarning = false,
		ExtraChange = 0,
	}
end

function PRK_Think_RevolverChambers()
	local speed = FrameTime() * PRK_Gun_HUDLerpSpeed
	local old = PRK_RevolverChambers.Ang
	PRK_RevolverChambers.Ang = Lerp( speed, PRK_RevolverChambers.Ang, PRK_RevolverChambers.TargetAng )
	PRK_RevolverChambers.LastChange = math.abs( old - PRK_RevolverChambers.Ang )
	-- PRK_RevolverChambers.Ang = math.ApproachAngle( PRK_RevolverChambers.Ang, PRK_RevolverChambers.TargetAng, speed )

	if ( !LocalPlayer():Alive() ) then
		PRK_Initialise_RevolverChambers()
	end
end

function PRK_HUDPaint_RevolverChambers()
	local wep = LocalPlayer():GetActiveWeapon()
	if ( !wep or !wep:IsValid() or wep:GetClass() != "prk_gun" or !wep.ChamberBullets ) then return end

	draw.NoTexture()

	-- local chambers = math.floor( math.max( 3, math.abs( math.sin( CurTime() / 2 ) ) * 15 ) )
	local chambers = LocalPlayer():GetActiveWeapon().MaxClip

	local r = PRK_GetResolutionIndependent( 80 )
	local r_def = r
	local r_add = 0
		if ( PRK_RevolverChambers.LastChange ) then
			r_add = math.min( PRK_RevolverChambers.LastChange, 10 ) * PRK_Gun_HUDScaleMultiplier
			r = r + r_add
		end
	local x = ScrW() - r * 4.5
	local y = ScrH() - r * 1.2
	local ang = PRK_RevolverChambers.Ang
	-- print( ang )
	-- print( chambers )
		-- local off = 180 -- ( ( 1 / chambers ) * -360 ) + 180
		local off = ( ( 1 / chambers ) * 360 ) + 180
		off = off + ( 360 / chambers )
		ang = ang - off
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	-- Draw blur
	local offx, offy = PRK_GetUIPosVelocity( x, y, -PRK_HUD_Shadow_DistX, PRK_HUD_Shadow_DistY, PRK_HUD_Shadow_Effect )
	surface.SetDrawColor( PRK_HUD_Colour_Shadow )
	draw.Circle( offx, offy, r, chambers, ang )

	-- Get chamber positions
	local cham_rad = math.min( 32, ( r_def / chambers * 1.5 ) )
	local points = PRK_GetCirclePoints( x, y, r - cham_rad * 1.5, chambers, ang )
		-- Remove middle point
		table.remove( points, 1 )

	-- Draw background
	surface.SetDrawColor( 230, 230, 240, 255 )
	if ( PRK_RevolverChambers.NoAmmoWarning ) then
		surface.SetDrawColor( 230, 130, 130, 255 )
	end
	-- Special cases
	local specialcase = {
		[1] = function()
			local segs = 6
			local mult = 0.75
			draw.Circle( x, y, r * mult, segs, ang )
			points = {
				{ x = x, y = y }
			}
			-- cham_rad = r * mult
		end,
		[2] = function()
			local segs = 5
			local mult = 0.75
			local dif = ( r * mult ) / 2
			draw.Ellipses( x, y, r * mult * 1.25, r * mult, 8, ang )
		end,
	}
	if ( specialcase[chambers] ) then
		specialcase[chambers]()
	else
		draw.Circle( x, y, r, chambers, ang )
	end

	-- Draw individual chambers
	for chamber, point in pairs( points ) do
		local function inner()
			local info = PRK_BulletTypeInfo[wep.ChamberBullets[chamber]]
			if ( info ) then
				info:Paint( wep, point.x, point.y, math.min( 18, cham_rad ) )
			end
			if ( LocalPlayer().ChamberWarning and LocalPlayer().ChamberWarning[chamber] ) then
				surface.SetDrawColor( 255, 20, 20, LocalPlayer().ChamberWarning[chamber] )
				draw.Circle( point.x, point.y, math.min( 18, cham_rad ), 32, 0 )
			end
		end
		local function mask()
			surface.SetDrawColor( 0, 20, 20, 255 )
			draw.Circle( point.x, point.y, math.min( 18, cham_rad ), 32, 0 )
		end
		draw.StencilBasic( mask, inner )
	end

	-- Draw 'No Ammo' warning
	if ( PRK_RevolverChambers.NoAmmoWarning ) then
		-- Draw message above empty chambers
		local message = "RELOAD"
			local extraammo = LocalPlayer():GetNWInt( "PRK_ExtraAmmo" )
			if ( extraammo == 0 ) then
				message = "FIND AMMO"
			end
		local pulsespeed = 8.35 -- 8.3
		local pulsemag = 105
		local time = CurTime() - PRK_RevolverChambers.NoAmmoWarningStart
		PRK_DrawText( 
			message,
			x,
			y - r * 1.3,
			Color( 255, 255, 255, 255 - pulsemag + math.sin( time * pulsespeed ) * pulsemag ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		 )

		-- Draw R in the middle of chambers
		local pulsemag = 20
		PRK_DrawText( 
			"R",
			x,
			y - 2,
			Color( 255, 255, 255, 255 - pulsemag + math.sin( time * pulsespeed ) * pulsemag ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		 )

		LocalPlayer():EmitSound( "prk_reload_alarm" )
	else
		LocalPlayer():StopSound( "prk_reload_alarm" )
	end
end

function PRK_HUDPaint_ExtraAmmo()
	local r = PRK_GetResolutionIndependent( 112 )
	local s = r / 2
	local x = ScrW() - r * 2
	local y = ScrH() - r * 1
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	-- Draw ammo icon shadow
	local offx, offy = PRK_GetUIPosVelocity( x, y, -PRK_HUD_Shadow_DistX, PRK_HUD_Shadow_DistY, PRK_HUD_Shadow_Effect )
	surface.SetDrawColor( PRK_HUD_Colour_Shadow )
	surface.SetMaterial( PRK_Material_Icon_Bullet )
		surface.DrawTexturedRect( offx - s / 1.5, offy - s / 2, s / 2, s )
	draw.NoTexture()

	-- Draw ammo icon
	surface.SetDrawColor( PRK_HUD_Colour_Highlight )
	surface.SetMaterial( PRK_Material_Icon_Bullet )
		surface.DrawTexturedRect( x - s / 1.5, y - s / 2, s / 2, s )
	draw.NoTexture()

	-- Draw ammo number
	local extraammo = LocalPlayer():GetNWInt( "PRK_ExtraAmmo" )
	local extraammo_add = LocalPlayer():GetNWInt( "PRK_ExtraAmmo_Add" )
		-- Clamp difference between current extraammo and additional extra ammo just picked up
		local temp = extraammo
		extraammo = math.max( 0, extraammo - extraammo_add )
		extraammo_add = temp - extraammo
		if ( extraammo < 10 ) then
			extraammo = "0" .. extraammo
		end
		extraammo = "x" .. extraammo
	local w, h = PRK_DrawText( 
		extraammo,
		x,
		y,
		PRK_HUD_Colour_Main,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
	 )

	if ( extraammo_add and extraammo_add != 0 ) then
		local offy = 0
		if ( extraammo_add > 0 ) then
			extraammo_add = "+" .. extraammo_add
		end
		PRK_DrawText( 
			extraammo_add,
			x + w,
			y + offy,
			PRK_HUD_Colour_Main,
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER
		 )
	end
end

function PRK_Gun_UseAmmo()
	if ( LocalPlayer():GetActiveWeapon() and LocalPlayer():GetActiveWeapon():IsValid() ) then
		local chambers = LocalPlayer():GetActiveWeapon().MaxClip or 6
		PRK_RevolverChambers.TargetAng = PRK_RevolverChambers.TargetAng - ( 360 / chambers )
	end
end

function PRK_Gun_AddAmmo( dir )
	local wep = LocalPlayer():GetActiveWeapon()
	if ( wep and wep:IsValid() ) then
		local chambers = wep.MaxClip or 6
		PRK_RevolverChambers.TargetAng = PRK_RevolverChambers.TargetAng + ( 360 / chambers ) * dir
		PRK_RevolverChambers.NoAmmoWarning = ( wep:GetFilledChamberCount() == 0 )
		PRK_RevolverChambers.ExtraChange = 1
	end
end

function PRK_Gun_NoAmmoWarning()
	PRK_RevolverChambers.NoAmmoWarning = true
	PRK_RevolverChambers.NoAmmoWarningStart = CurTime()
end
------------------
  -- /PRK Gun --
------------------

local models = {}
local height = 10
local scale = 0.5

local function think_eye( ent, ply, left )
	local boneid = ply:LookupBone( "ValveBiped.Bip01_Head1" )
	local matrix = ply:GetBoneMatrix( boneid )
	local pos = matrix:GetTranslation()
	local ang = matrix:GetAngles()

	local origin = Vector( ( height + 14 ) * scale, -16 * scale, 2 * ent.Left )
	pos = LocalToWorld( origin, Angle(), matrix:GetTranslation(), matrix:GetAngles() )

	if ( ent.Pupil ) then
		local dist = 1.2 * scale
		local poi = LocalPlayer():EyePos()
			-- Testing/fun
			if ( LocalPlayer() == ply ) then
				poi = ents.FindByClass( "gmod_cameraprop" )[1]:GetPos()
			end
			-- Wander around
			local wander = math.max( 0, math.sin( CurTime() ) - 0.7 )
			if ( ply.Wandering and ply.Wandering > CurTime() ) then
				-- Wait
			elseif ( !ply.NextWander or ply.NextWander <= CurTime() ) then
				local effect = 10
				ply.TargetEyePos = pos + ( ply:EyeAngles():Up() * math.random( -effect, effect ) + ply:EyeAngles():Right() * math.random( -effect, effect ) + ply:EyeAngles():Forward() * 10 )
				ply.NextWander = CurTime() + math.random( 0, 150 ) / 10
				ply.Wandering = CurTime() + 0.5-- + math.random( 10, 10 ) / 10
			else
				ply.TargetEyePos = poi
			end
			-- Lerp last
			if ( !ply.CurrentEyePos ) then
				ply.CurrentEyePos = ply.TargetEyePos
			end
			ply.CurrentEyePos = LerpVector( FrameTime() * 5, ply.CurrentEyePos, ply.TargetEyePos )
			poi = ply.CurrentEyePos
		local dir = ( poi - pos ):GetNormal()
		pos = pos + dir * dist
	end

	if ( ply.Bite != nil ) then
		pos = pos + ang:Forward() * ply.Bite * 0.5
		-- pos = pos + ang:Right() * math.min( 0, ply.Bite * 0.2 )
		-- ent:SetModelScale( scale * ent.Scale * math.max( 0, ply.Bite * 0.2 ) )
	end

	ent:SetPos( pos )
end

models = {
	{
		"models/ichthyosaur.mdl",
		Vector( height * scale, -13.6 * scale, 0 ),
		Angle( 180, 90, 90 ),
		true,
		SpawnFunc = function( ent )
			ent:SetModelScale( scale )

			local scale_main = Vector( 1, 1, 1 ) * 0.5
			local scale_ignore = Vector( 1, 1, 1 ) * 0.01
			local ignore = {
				[9] = true,
				[13] = true,
			}
			local pos = {
				Vector( 0, 0, 0 ), -- Root
				Vector( 0, 0, 0 ),
				Vector( -50, 0, 0 ),
				Vector( -20, 0, 0 ),
				Vector( -50, 0, 0 ),
				Vector( -20, 0, 0 ),
				Vector( -20, 0, 0 ),
				Vector( -20, 0, 0 ),
				Vector( 0, 0, 0 ),
				Vector( 0, 0, 0 ),
				Vector( 0, 0, 0 ),
				Vector( 0, 0, 0 ),
				Vector( 0, 0, 0 ),
				Vector( 0, 0, 0 ),
				Vector( -20, 10, 10 ),
				Vector( -10, 0, 10 ),
				Vector( -10, 0, 10 ),
				Vector( -10, 10, -10 ),
				Vector( 0, -20, 0 ),
				Vector( -10, 0, -10 ),
			}
			for i = 1, ent:GetBoneCount() do
				if ( !ignore[i] ) then
					if ( pos[i] ) then
						ent:ManipulateBonePosition( i, pos[i] )
					end
					ent:ManipulateBoneScale( i, scale_ignore )
				else
					ent:ManipulateBoneScale( i, scale_main )
				end
			end
		end,
		Think = function( ent, ply )
			ply.Bite = Lerp( FrameTime() * 2, ply.Bite or 0, PRK_MouthDefault )

			-- If not animating bite for another reason, try get player voice
			if ( ply:VoiceVolume() != 0 ) then
				ply.Bite = Lerp( FrameTime() * 10, ply.Bite, PRK_MouthDefault + ply:VoiceVolume() * PRK_MouthVoice )
			end

			local head = 9
			local jaw = 13
			local pos = Vector( 0, 1, 0 ) * ply.Bite
			ent:ManipulateBonePosition( head, pos )
			ent:ManipulateBonePosition( jaw, pos )
		end,
	},
	{
		"models/Combine_Helicopter/helicopter_bomb01.mdl",
		Vector( height * scale, 23.6 * scale, 0 ),
		Angle( 0, 0, 0 ),
		true,
		SpawnFunc = function( ent )
			ent:SetModelScale( scale * 1.75 )
		end,
	},
	{
		"models/Combine_Helicopter/helicopter_bomb01.mdl",
		Vector( ( height + 14 ) * scale, -16 * scale, 2 ),
		Angle( 0, 0, 0 ),
		Color( 255, 255, 255, 255 ),
		SpawnFunc = function( ent )
			ent.Scale = 0.15
			ent:SetModelScale( scale * 0.15 )
			ent.Left = 1
		end,
		Think = think_eye,
	},
	{
		"models/Combine_Helicopter/helicopter_bomb01.mdl",
		Vector( ( height + 14 ) * scale, -16 * scale, -2 ),
		Angle( 0, 0, 0 ),
		Color( 255, 255, 255, 255 ),
		SpawnFunc = function( ent )
			ent.Scale = 0.15
			ent:SetModelScale( scale * 0.15 )
			ent.Left = -1
		end,
		Think = think_eye,
	},
	{
		"models/Combine_Helicopter/helicopter_bomb01.mdl",
		Vector( ( height + 14 ) * scale, -19 * scale, 2 ),
		Angle( 0, 0, 0 ),
		Color( 0, 0, 0, 255 ),
		SpawnFunc = function( ent )
			ent.Scale = 0.1
			ent:SetModelScale( scale * ent.Scale )
			ent.Left = 1
			ent.Pupil = true
		end,
		Think = think_eye,
	},
	{
		"models/Combine_Helicopter/helicopter_bomb01.mdl",
		Vector( ( height + 14 ) * scale, -19 * scale, -2 ),
		Angle( 0, 0, 0 ),
		Color( 0, 0, 0, 255 ),
		SpawnFunc = function( ent )
			ent.Scale = 0.1
			ent:SetModelScale( scale * ent.Scale )
			ent.Left = -1
			ent.Pupil = true
		end,
		Think = think_eye,
	},
}

for k, mod in pairs( models ) do
	local ent = ClientsideModel( mod[1] )
		ent:SetNoDraw( true )
		if ( mod.SpawnFunc ) then
			mod.SpawnFunc( ent )
		end
	mod.Ent = ent
end

hook.Add( "PostPlayerDraw" , "manual_model_draw_example" , function( ply )
	local boneid = ply:LookupBone( "ValveBiped.Bip01_Head1" )

	if not boneid then
		return
	end

	local matrix = ply:GetBoneMatrix( boneid )

	if not matrix then
		return
	end

	for k, mod in pairs( models ) do
		local ent = mod.Ent
		local newpos, newang = LocalToWorld( mod[2], mod[3], matrix:GetTranslation(), matrix:GetAngles() )

		ent:SetPos( newpos )
		ent:SetAngles( newang )
		ent:SetMaterial( PRK_Material_Base )
		local col = mod[4]
			if ( col == true ) then
				col = ply:GetColor()
			end
		render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
			if ( mod.Think ) then
				mod.Think( ent, ply )
			end
			ent:SetupBones()
			ent:DrawModel()
		render.SetColorModulation( 1, 1, 1 )
	end
end )

function PRK_AddDecal( pos, col )
	local zone = LocalPlayer():GetNWInt( "PRK_Zone", 0 )

	if ( !LocalPlayer().PRK_Decals ) then
		LocalPlayer().PRK_Decals = {}
	end
	if ( !LocalPlayer().PRK_Decals[zone] ) then
		LocalPlayer().PRK_Decals[zone] = {}
	end

	local decal = {
		pos = pos,
		col = col,
		rot = math.random( 0, 360 ),
		mat = PRK_Material_Splat(),
		siz = math.random( 10, 20 ) / 10,
	}

	-- Try to combine this with any other close splat decals
	for k, otherdecal in pairs( LocalPlayer().PRK_Decals[zone] ) do
		local dist = decal.pos:Distance( otherdecal.pos )
		if ( dist <= PRK_Decal_CombineDist ) then
			decal.siz = ( decal.siz + otherdecal.siz + dist ) / 4
			decal.pos = ( decal.pos + otherdecal.pos ) / 2
			table.remove( LocalPlayer().PRK_Decals[zone], k )
		end
	end

	-- Remove the first if there are too many
	if ( #LocalPlayer().PRK_Decals[zone] >= PRK_Decal_Max ) then
		table.remove( LocalPlayer().PRK_Decals[zone], 1 )
	end
	table.insert( LocalPlayer().PRK_Decals[zone], decal )
	-- print( #LocalPlayer().PRK_Decals[zone] )
end

hook.Add( "PreDrawTranslucentRenderables", "PRK_PreDrawTranslucentRenderables_Decal", function( depth, skybox )
	if ( !PRK_ShouldDraw() ) then return end
	if ( depth or skybox ) then return end

	-- Render decals
	local zone = LocalPlayer():GetNWInt( "PRK_Zone", 0 )
	if ( PRK_Decal and LocalPlayer().PRK_Decals and LocalPlayer().PRK_Decals[zone] ) then
		local width = 1
		-- print( PRK_Material_Splat() )
		local size = 48
		local rendercount = 0
		for k, decal in pairs( LocalPlayer().PRK_Decals[zone] ) do
			render.SetMaterial( decal.mat )
			render.DrawQuadEasy( 
				decal.pos + Vector( 0, 0, 1 ) * 0.01 * k,
				Vector( 0, 0, 1 ),
				decal.siz * size * width, decal.siz * size * width,
				decal.col,
				decal.rot
			 )
		end
	end
end )

-- Converts an existing ClientsideModel into a physics debris object
function PRK_ModelToDebris( ent )
	ent:PhysicsInitSphere( 5, SOLID_VPHYSICS )
	ent:PhysWake()
	local phys = ent:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( true )
		phys:AddVelocity( Vector( 0, 0, -10 ) )
	end
	ent:SetNoDraw( false )

	timer.Simple( 2, function()
		if ( ent and ent:IsValid() ) then
			ent:Remove()
		end
	end )
end

-- Don't draw map outside of generated PRK stuff
function GM:PreDrawOpaqueRenderables()
	if ( !PRK_DrawMap ) then
		render.Clear( 0, 0, 0, 255 )
	end

	return !PRK_ShouldDraw()
end

function GM:PreDrawTranslucentRenderables()
	return !PRK_ShouldDraw()
end

function GM:PreDrawHalos()

end

function GM:PostDrawEffects()
	
end

function PRK_ShouldDraw()
	return !( LocalPlayer().PRK_Editor_Room or LocalPlayer().PRK_Gateway )
end

-- View range limiter
-- Also handles death view
local function PRK_CalcView( ply, pos, angles, fov )
	-- Editor first
	local override = PRK_CalcView_Editor_Room( ply, origin, angles, fov )
	-- Then gateway
	if ( !override ) then
		override = PRK_CalcView_Gateway( ply, origin, angles, fov )
	end
	-- Then normal/death
	if ( !override ) then
		local view = {}
			view.origin = pos -- ( angles:Forward() * 100 )
			view.angles = angles
			view.fov = fov
				if ( !LocalPlayer():Alive() and LocalPlayer().DieEffect ) then
					view.origin = LocalPlayer().DieEffect[1]
					view.angles = LocalPlayer().DieEffect[2]
					local off = PRK_HUD_DieEffect_MaxAlpha / 100 * 99
					if ( LocalPlayer().DieEffect[3] > off ) then
						view.fov = 90 - ( 89 / ( PRK_HUD_DieEffect_MaxAlpha - off ) * ( LocalPlayer().DieEffect[3] - off ) )
					end
				end
			view.drawviewer = false
			view.zfar = PRK_DrawDistance
		return view
	else
		return override
	end
end
hook.Add( "CalcView", "PRK_CalcView", PRK_CalcView )

-- Resolution changing
local LastScrW = ScrW()
local LastScrH = ScrH()
timer.Create( "DetectResolutionChange", 1, 0, function()
	if ( LastScrW != ScrW() or LastScrH != ScrH() ) then
		LastScrW = ScrW()
		LastScrH = ScrH()
		hook.Call( "OnResolutionChange", GAMEMODE )
	end 
end )

--------------
  -- Util --
--------------
function PlayerInZone( ent, zone )
	if ( zone == nil ) then
		if ( !PRK_Zones ) then
			PRK_Zones = GAMEMODE:FlatgrassZones()
		end

		for k, zone in pairs( PRK_Zones ) do
			local square = {
				x = { zone.pos.x - zone.width / 2, zone.pos.x + zone.width / 2 },
				y = { zone.pos.y - zone.breadth / 2, zone.pos.y + zone.breadth / 2 },
			}
			if ( intersect_point_square( ent:GetPos(), square ) ) then
				ent.Zone = k
				zone = k
				break
			end
		end
	end

	return ( LocalPlayer():GetNWInt( "PRK_Zone" ) == zone )
end

function PRK_DrawText( text, x, y, col, xalign, yalign, fontsize, shadow )
	-- Default args
	if ( fontsize == nil ) then
		fontsize = 36
	end
	if ( shadow == nil ) then
		shadow = PRK_HUD_Colour_Shadow
	end

	-- Negative font size means absolute, don't scale with screen res
	if ( fontsize < 0 ) then
		fontsize = math.abs( fontsize ) .. "_Abs"
	end

	-- Shadow
	if ( shadow ) then
		local offx, offy = PRK_GetUIPosVelocity( x, y, -PRK_HUD_Shadow_DistX, PRK_HUD_Shadow_DistY, PRK_HUD_Shadow_Effect )
		draw.SimpleText( 
			text,
			"HeavyHUD" .. fontsize,
			offx,
			offy,
			shadow,
			xalign,
			yalign
		 )
	end

	-- Real text
	draw.SimpleText( 
		text,
		"HeavyHUD" .. fontsize,
		x,
		y,
		col,
		xalign,
		yalign
	 )

	surface.SetFont( "HeavyHUD" .. fontsize )
	local w, h = surface.GetTextSize( text )
	return w, h
end

function PRK_GetUIPosVelocity( x, y, lagx, lagy, effect )
	-- Default variables
	if ( !effect ) then
		effect = 20
	end
	effectpunch = 0.25
	effectrotate = 0.25

	local targetx = x
	local targety = y
		local left = ( x <= ScrW() / 2 )
		local bott = ( y <= ScrH() / 2 )
		-- Default effect + punch effect ( From gun firing, etc )
		local wep = LocalPlayer():GetActiveWeapon()
		if ( wep.GunPunch ) then
			local offx = lagx + wep.GunPunch * effectpunch * effect * 2
				if ( left ) then
					targetx = targetx - offx
				else
					targetx = targetx + offx
				end
			local offy = lagy + wep.GunPunch * effectpunch * effect * 2
				if ( bott ) then
					targety = targety - offy
				else
					targety = targety + offy
				end
		end
		if ( LocalPlayer().PunchHUD ) then
			local vel = LocalPlayer().PunchHUD
			local rgt = -LocalPlayer():GetRight()
			local forw  = LocalPlayer():GetForward()
				targetx = targetx + vel:Dot( rgt ) * effect
				targety = targety + vel:Dot( forw ) * effect
		end
		-- Velocity effect
		local vel = LocalPlayer():GetVelocity()
		local rgt = -LocalPlayer():GetRight()
		local up  = LocalPlayer():GetUp()
			targetx = targetx + vel:Dot( rgt ) / PRK_Speed * effect
			targety = targety + vel:Dot( up ) / PRK_Speed * effect
		-- Turn effect ( stored on DrawHUD )
		-- if ( vel:Length() < PRK_Speed / 10 ) then
			if ( LocalPlayer().LastEyeAngles ) then
				local bac = -LocalPlayer():GetForward()
				local angeffect = 0.5 -- vel:Dot( bac ) > 0 and -1 or 1
				local max = 5
				local eye = LocalPlayer():EyeAngles()
					targetx = targetx + angeffect * math.Clamp( math.AngleDifference( eye.y, LocalPlayer().LastEyeAngles.y ), -max, max ) * effectrotate * effect
					targety = targety + angeffect * -math.Clamp( math.AngleDifference( eye.x, LocalPlayer().LastEyeAngles.x ), -max, max ) * effectrotate * effect
			end
		-- end
	-- Lerp
	local frametime = 0.016 -- FrameTime()
	local speed = 50
	x = Lerp( frametime * speed, x, targetx )
	y = Lerp( frametime * speed, y, targety )
	-- x = targetx
	-- y = targety
	return x, y
end

function surface.DrawRectBorder( x, y, w, h, border )
	-- Top
	surface.DrawRect( 
		x - border,
		y - border,
		w + border * 2,
		border
	 )
	-- Bottom
	surface.DrawRect( 
		x - border,
		y + h,
		w + border * 2,
		border
	 )

	-- Left
	surface.DrawRect( 
		x - border,
		y,
		border,
		h
	 )
	-- Right
	surface.DrawRect( 
		x + w,
		y,
		border,
		h
	 )
end

function draw.Rect( x, y, w, h, color )
	draw.Box( x, y, w, h, color )
end
function draw.Box( x, y, w, h, color )
	if ( color ) then
		draw.SetDrawColor( color )
	end
	surface.DrawRect( x, y, w, h )
end

function draw.SetDrawColor( color )
	surface.SetDrawColor( color.r, color.g, color.b, color.a )
end

-- Points table of { x, y, width }
function draw.Line( dir, points )
	local verts = {}
		for point = 2, #points do
			local last = points[point-1]
				-- last.x = last.x - 100
				-- last.y = last.y - 100
			local curr = points[point]
			table.Add( verts, {
				{ x = last.x + dir.x * last.width, y = last.y + dir.y * last.width },
				{ x = last.x - dir.x * last.width, y = last.y - dir.y * last.width },
				{ x = curr.x + dir.x * curr.width, y = curr.y + dir.y * curr.width },
				{ x = curr.x + dir.x * curr.width, y = curr.y + dir.y * curr.width },
				{ x = curr.x - dir.x * curr.width, y = curr.y - dir.y * curr.width },
				{ x = last.x - dir.x * last.width, y = last.y - dir.y * last.width },
			} )
		end
	surface.DrawPoly( verts )
end

function draw.Heart( x, y, radius, seg )
	local circle_rad = radius / 2
	local circle_off = circle_rad

	-- Left circle
	local cir_left = PRK_GetCirclePoints( x - circle_off, y - circle_off, circle_rad, seg, 0 )
	surface.DrawPoly( cir_left )

	-- Right circle
	local cir_right = PRK_GetCirclePoints( x + circle_off, y - circle_off, circle_rad, seg, 0 )
	surface.DrawPoly( cir_right )

	-- Bottom triangle
	local triangle_off = -circle_rad
	local tri = {
		{
			x = cir_left[1].x + triangle_off,
			y = cir_left[1].y + triangle_off,
		},
		{
			x = cir_right[1].x - triangle_off,
			y = cir_right[1].y + triangle_off,
		},
		{
			x = x,
			y = y + radius,
		},
	}
	surface.DrawPoly( tri )
end

-- From: https://codea.io/talk/discussion/3430/has-somebody-an-ellipse-mesh-code
function draw.Ellipses( x, y, radius, width, seg, rotate )
    local offx = 0
	local offy = 0
	local rotate = -math.rad( rotate )
    local verts = {}
	local add = 360 / seg
    for i = 1, seg do
		local i = i * add
        table.insert( verts, { x = x + offx, y = y + offy } )

        angle = math.rad( i-add )
        offx = width*math.cos( angle ) 
        offy = radius*math.sin( angle )
			local newx = offx * math.cos( rotate ) - offy * math.sin( rotate );
			local newy = offx * math.sin( rotate ) + offy * math.cos( rotate );
        table.insert( verts, { x = x + newx, y = y + newy } )

        angle = math.rad( i )
        offx = width*math.cos( angle ) 
        offy = radius*math.sin( angle )
			local newx = offx * math.cos( rotate ) - offy * math.sin( rotate );
			local newy = offx * math.sin( rotate ) + offy * math.cos( rotate );
        table.insert( verts, { x = x + newx, y = y + newy } )

		offx = newx
		offy = newy
    end
	surface.DrawPoly( verts )
end

-- More in shared.lua
function draw.Circle( x, y, radius, seg, rotate )
	local cir = PRK_GetCirclePoints( x, y, radius, seg, rotate )
	surface.DrawPoly( cir )
end

function draw.StencilBasic( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable( true )
		render.SetStencilWriteMask( 255 )
		render.SetStencilTestMask( 255 )
		render.SetStencilFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_REPLACE )
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
		render.SetBlend( 0 ) --makes shit invisible
		render.SetStencilReferenceValue( 10 )
			mask()
		render.SetBlend( 1 )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
			inner()
	render.SetStencilEnable( false )
end

function draw.StencilCut( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable( true )
		render.SetStencilWriteMask( 255 )
		render.SetStencilTestMask( 255 )
		render.SetStencilFailOperation( STENCIL_KEEP )
		render.SetStencilZFailOperation( STENCIL_REPLACE )
		render.SetStencilPassOperation( STENCIL_REPLACE )
		render.SetStencilCompareFunction( STENCIL_NEVER )
		render.SetStencilReferenceValue( 1 )
			mask()
		render.SetStencilCompareFunction( STENCIL_NOTEQUAL )
		render.SetStencilFailOperation( STENCIL_KEEP )
			inner()
	render.SetStencilEnable( false )
end

-- From: https://github.com/caosdoar/spheres/blob/master/src/spheres.cpp
-- local mat = Material( PRK_Material_Base )
local mat = Material( "editor/wireframe" ) -- The material ( a wireframe )
-- local mat = PRK_Material_Icon_Bullet
local once = false
local once = true
function mesh.GenerateSphere( point, scale, meridians, parallels )
	-- Gen
	local triangles = {}
	local function gen()
		local verts = {}
		local count = 0
		local function addvert( id )
			table.insert( triangles, point + verts[id] * scale )
			count = count + 1
		end
		local function addtri( a, b, c )
			addvert( a )
			addvert( b )
			addvert( c )
		end
		local function addquad( a, b, c, d )
			addtri( a, b, c )
			addtri( a, c, d )
		end

		verts[0] = Vector( 0, 1, 0 )
		for j = 0, parallels - 1 do
			local polar = math.pi * ( j + 1 ) / parallels
			local sp = math.sin( polar )
			local cp = math.cos( polar )
			for i = 0, meridians do
				local azimuth = 2 * math.pi * i / meridians
				local sa = math.sin( azimuth )
				local ca = math.cos( azimuth )
				local x = sp * ca
				local y = cp
				local z = sp * sa
				table.insert( verts, Vector( x, y, z ) )
			end
		end
		table.insert( verts, Vector( 0, -1, 0 ) )
		if ( !once ) then
			for k, vert in pairs( verts ) do
				PRK_BasicDebugSphere( point + vert * scale )
			end
		end

		for i = 0, meridians do
			local a = i + 1
			local b = ( i + 2 )
				if ( i + 2 > meridians ) then
					b = 1
				end
			addtri( 0, b, a )
		end

		for j = 0, parallels - 2 do
			local aStart = j * meridians + 1
			local bStart = ( j + 1 ) * meridians + 1
			for i = 0, meridians do
				local a = aStart + i
				local a1 = aStart + ( i + 1 ) % meridians
				local b = bStart + i
				local b1 = bStart + ( i + 1 ) % meridians

				addquad( a, a1, b1, b )
			end
		end

		for i = 0, meridians do
			local a = i + meridians * ( parallels - 2 ) + 1
			local b = ( i + 1 ) % meridians + meridians * ( parallels - 2 ) + 1
			addtri( #verts - 1, a, b )
		end
	end
	gen()

	-- Render
	render.SetMaterial( mat ) -- Apply the material
	local primitives = #triangles / 3
	mesh.Begin( MATERIAL_TRIANGLES, primitives ) -- Begin writing to the dynamic mesh
		for k, pri in pairs( triangles ) do
			mesh.Position( pri )
			mesh.AdvanceVertex()
		end
	mesh.End()
	once = true
end

hook.Add( "PostDrawOpaqueRenderables", "MeshLibTest", function()
	-- mesh.GenerateSphere( LocalPlayer():GetPos(), 400, 8, 8 )
end )

function PRK_AddModel( mdl, pos, ang, scale, mat, col, ren )
	if ( !ren ) then ren = RENDERGROUP_OTHER end

	local model = ClientsideModel( mdl, ren )
		model:SetPos( pos )
		model:SetAngles( ang )
		model:SetModelScale( scale )
		model:SetMaterial( mat )
		model:SetColor( col )
		model.Pos = pos
		model.Ang = ang
		-- model.RenderBoundsMin, model.RenderBoundsMax = model:GetRenderBounds()
	return model
end

function PRK_RenderScale( ent, scale )
	local mat = Matrix()
		mat:Scale( scale )
	ent:EnableMatrix( "RenderMultiply", mat )
end
---------------
  -- /Util --
---------------
