--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Clientside
--

include( "shared.lua" )

-- Materials
PRK_Material_Icon_Bullet = Material( "icon_bullet.png", "noclamp smooth" )

-- Resolution sccaling
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
	local amount = net.ReadFloat()
	local dir = net.ReadVector()

	LocalPlayer().PunchHUD = dir * amount * PRK_HUD_Punch_Amount
	LocalPlayer().HideHurtEffect = CurTime() + PRK_Hurt_ShowTime
end )

net.Receive( "PRK_Die", function( len, ply )
	local pos = net.ReadVector()
	local ang = net.ReadAngle()
	local killname = net.ReadString()

	LocalPlayer().DieEffect = {
		pos,
		ang,
		0,
		killname,
		TimeMin = CurTime() + 1,
	}

	LocalPlayer():EmitSound( "prk_death" )

	PRK_Initialise_RevolverChambers()
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
end

function PRK_Think_Punch()
	if ( LocalPlayer().PunchHUD ) then
		LocalPlayer().PunchHUD = LerpVector( FrameTime() * PRK_HUD_Punch_Speed, LocalPlayer().PunchHUD, Vector() )
	end
end

function PRK_Think_Die()
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
	if ( tr.Entity and tr.Entity:IsValid() and tr.Entity.UseLabel and tr.Entity.MaxUseRange ) then
		local dist = LocalPlayer():GetPos():Distance( tr.Entity:GetPos() )
		if ( dist <= tr.Entity.MaxUseRange ) then
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

function PRK_LookAtUsable( ent, text )
	-- Only play sound if actually has to rotate
	-- (i.e. wasn't already looking at something, and wasn't looking at something very recently)
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

	-- Must be last!
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

-- This could be tidier but it works :)
local lastlabelang = Angle()
local lastcursorang = Angle()
hook.Add( "PostDrawTranslucentRenderables", "PRK_PostDrawTranslucentRenderables_LabelHelp", function()
	-- Draw floating in front of the player for polish lerp rotation effects
	local dist = 10
	local dist_snap = 100
	local scal = 0.0125
	local speed_cursor = 20
	local speed = 7
	local forward = LocalPlayer():GetEyeTraceNoCursor().Normal
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
	local targetang = gettarget( false )
	lastcursorang = LerpAngle( FrameTime() * speed_cursor, lastcursorang, targetang )
	cam.Start3D2D( pos, lastcursorang, scal )
		PRK_HUDPaint_Crosshair()
	cam.End3D2D()
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

	return true
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
		-- ply:ConCommand( "prk_effect" )
		return true
	end
	if string.find( bind, "+duck" ) then
		-- ply:ConCommand( "prk_effect" )
		return true
	end

	-- Blocking without overrides
	for k, v in pairs( blockdefault ) do
		if ( string.find( bind, v ) ) then
			return true
		end
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
	local x = CursorX - ScrW() / 2
	local y = CursorY - ScrH() / 2
	local size = 8

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
	local x = CursorX - ScrW() / 2
	local y = CursorY - ScrH() / 2
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
			money = money - money_add
		end
	local w, h = PRK_DrawText(
		PRK_GetAsCurrency( money ),
		x,
		y,
		PRK_HUD_Colour_Money,
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
	)

	if ( money_add and money_add != 0 ) then
		local offy = 0
		PRK_DrawText(
			"+" .. PRK_GetAsCurrency( money_add ),
			x + w,
			y + offy,
			PRK_HUD_Colour_Money,
			TEXT_ALIGN_LEFT,
			TEXT_ALIGN_CENTER
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
	local speed = FrameTime() * 10
	local old = PRK_RevolverChambers.Ang
	PRK_RevolverChambers.Ang = Lerp( speed, PRK_RevolverChambers.Ang, PRK_RevolverChambers.TargetAng )
	PRK_RevolverChambers.LastChange = math.abs( old - PRK_RevolverChambers.Ang )
	-- PRK_RevolverChambers.Ang = math.ApproachAngle( PRK_RevolverChambers.Ang, PRK_RevolverChambers.TargetAng, speed )

	if ( !LocalPlayer():Alive() ) then
		PRK_Initialise_RevolverChambers()
	end
end

function PRK_HUDPaint_RevolverChambers()
	if ( !LocalPlayer():GetActiveWeapon() or !LocalPlayer():GetActiveWeapon():IsValid() or LocalPlayer():GetActiveWeapon():GetClass() != "prk_gun" ) then return end

	draw.NoTexture()

	-- local chambers = math.floor( math.max( 3, math.abs( math.sin( CurTime() / 2 ) ) * 15 ) )
	local chambers = LocalPlayer():GetActiveWeapon().MaxClip

	local r = PRK_GetResolutionIndependent( 80 )
	local r_def = r
	local r_add = 0
		if ( PRK_RevolverChambers.LastChange ) then
			r_add = math.min( PRK_RevolverChambers.LastChange, 10 ) * 4
			r = r + r_add
		end
	local x = ScrW() - r * 4.5
	local y = ScrH() - r * 1.2
	local ang = PRK_RevolverChambers.Ang
	-- print( ang )
	-- print( chambers )
		local off = 180 -- ( ( 1 / chambers ) * -360 ) + 180
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
			draw.Circle( x, y - dif, r * mult, segs, ang )
			draw.Circle( x, y + dif, r * mult, segs, ang + 180 )
		end,
	}
	if ( specialcase[chambers] ) then
		specialcase[chambers]()
	else
		draw.Circle( x, y, r, chambers, ang )
	end

	-- Draw individual chambers
	local ammo = LocalPlayer():GetNWInt( "PRK_Clip" )
	for k, point in pairs( points ) do
		local id = k -- #points - k + 1
		if ( id <= ammo ) then
			surface.SetDrawColor( 100, 190, 190, 255 )
		else
			surface.SetDrawColor( 0, 20, 20, 255 )
		end
		if ( id == 1 ) then
			-- surface.SetDrawColor( 255, 20, 20, 255 )
		end
		-- draw.Circle( point.x, point.y, cham_rad, 32, 0 )
		draw.Circle( point.x, point.y, math.min( 18, cham_rad ), 32, 0 ) -- TODO; fix this for all resolutions (only current problem is large size on 3 chambers?)
		PRK_DrawText(
			id,
			point.x,
			point.y,
			Color( 255, 255, 255, 255 ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER,
			16
		)
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

function PRK_Gun_AddAmmo()
	if ( LocalPlayer():GetActiveWeapon() and LocalPlayer():GetActiveWeapon():IsValid() ) then
		local chambers = LocalPlayer():GetActiveWeapon().MaxClip or 6
		PRK_RevolverChambers.TargetAng = PRK_RevolverChambers.TargetAng + ( 360 / chambers )
		PRK_RevolverChambers.NoAmmoWarning = false
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

-- Don't draw map outside of generated PRK stuff
function GM:PreDrawOpaqueRenderables()
	render.Clear( 0, 0, 0, 255, true, true )
end

-- View range limiter
-- Also handles death view
local function PRK_CalcView( ply, pos, angles, fov )
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
end
hook.Add( "CalcView", "PRK_CalcView_DrawDistance&Death", PRK_CalcView )

concommand.Add( "prk_effect", function( ply, cmd, args )
	local effectdata = EffectData()
		effectdata:SetOrigin( LocalPlayer():GetPos() )
	util.Effect( "prk_grass", effectdata )
end )

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

-- Mesh tests
-- local mat = Material( "editor/wireframe" ) -- The material ( a wireframe )
local mat = Material( "prk_gradient.png" ) -- The material ( a wireframe )

local pos = Vector( 267, -757.5, -12200 )
local x = 0
local y = 0
local angle = 0
local a = 2
local b = 2
local maxPoints = 200
local angleadd = 0.1
local width = 10
local forward = Vector( 0, -1, 0 )
local maxdepth = 500
local depth = 0

local verts = {}
	-- Generate a thick spiral
		for i = 0, maxPoints do
			-- Calculate this inner point
			angle = angleadd * i
			local size = angle
			x = ( a + b * size ) * math.cos( angle )
			y = ( a + b * size ) * math.sin( angle )
			local firstpoint = { pos = Vector( x, 0, y ), u = i % 3, v = i % 3 }

			-- First connect with the last triangle
			if ( i != 0 ) then
				local i = #verts
				table.insert( verts, verts[i - 2] )
				table.insert( verts, verts[i] )
				table.insert( verts, firstpoint )
			end

			-- Add the inner point after adding the joiner
			table.insert( verts, firstpoint )

			-- Add first outer triangle
			local size = size + width
			x = ( a + b * size ) * math.cos( angle )
			y = ( a + b * size ) * math.sin( angle )

			table.insert( verts, { pos = Vector( x, 0, y ), u = i % 3, v = i % 3 } )

			local angle = angle + angleadd
			size = size + angleadd
			x = ( a + b * size ) * math.cos( angle )
			y = ( a + b * size ) * math.sin( angle )

			table.insert( verts, { pos = Vector( x, 0, y ), u = i % 3, v = i % 3 } )
		end
local obj = Mesh()
-- mesh.Begin( obj, MATERIAL_TRIANGLES, maxPoints ) -- Begin writing to the dynamic mesh
	-- for i = 1, #verts do
		-- mesh.Position( pos + verts[i].pos ) -- Set the position
		-- mesh.TexCoord( 0, verts[i].u, verts[i].v ) -- Set the texture UV coordinates
		-- mesh.AdvanceVertex() -- Write the vertex
	-- end
-- mesh.End() -- Finish writing the mesh and draw it

local tunnel
local nextparticle = 0
hook.Add( "PostDrawOpaqueRenderables", "MeshLibTest", function()
	if ( !tunnel ) then
		tunnel = PRK_AddModel(
			"models/props_phx/construct/metal_plate_curve360x2.mdl",
			pos + forward * PRK_Plate_Size * 4,
			Angle( 90, 90, 0 ),
			1,
			"models/debug/debugwhite",
			Color( 0, 200, 0, 255 )
		)
		tunnel:SetNoDraw( true )
	end

	render.SetMaterial( mat ) -- Apply the material

	local scale = math.Clamp( math.sin( CurTime() / 2 ) * 2, 0.5, 1 ) * 3
	local length = scale * 100

	-- Particles
	if ( !PRK_Gateway_Emitters ) then
		PRK_Gateway_Emitters = {}
	end
	if ( nextparticle <= CurTime() ) then
		local effectdata = EffectData()
			effectdata:SetOrigin( pos + forward * scale * 5 )
			effectdata:SetNormal( forward )
			effectdata:SetRadius( scale * 4 )
		util.Effect( "prk_gateway", effectdata )
		nextparticle = CurTime() + 0.1
		-- print( "part" )
	end

	local tunnelscalemult = 1
	PRK_RenderScale( tunnel, Vector( scale * tunnelscalemult, scale * tunnelscalemult, length ) )
	tunnel:SetPos( pos + forward * PRK_Plate_Size * length )
	local function inner()
		-- Center
		cam.Start3D2D( pos + forward * 0, Angle( 90, 90, 0 ), scale )
			surface.SetDrawColor( 0, 0, 0, 255 )
			draw.Circle( 0, 0, 24, 24, 0 )
		cam.End3D2D()

		local function inner_mask()
			-- Center
			cam.Start3D2D( pos + forward * 0, Angle( 90, 90, 0 ), scale )
				surface.SetDrawColor( PRK_HUD_Colour_Shadow )
				draw.Circle( 0, 0, 24, 24, 0 )
			cam.End3D2D()
		end
		local function inner_inner()
			-- tunnel:DrawModel()
			for k, v in pairs( PRK_Gateway_Emitters ) do
				if ( v:IsValid() ) then
					v:Draw()
				end
			end
		end
		draw.StencilBasic( inner_inner, inner_mask )
	end
	local function mask()
		tunnel:DrawModel()

		-- Back wall
		cam.Start3D2D( pos + forward * 100, Angle( 90, 90, 0 ), 1000 )
			surface.DrawRect( -8, -8, 16, 16 )
		cam.End3D2D()
	end
	draw.StencilBasic( mask, inner )
	-- draw.StencilCut( mask, inner )
	-- inner()
		-- tunnel:DrawModel()
end )

--------------
  -- Util --
--------------
function PRK_DrawText( text, x, y, col, xalign, yalign, fontsize, shadow )
	-- Default args
	if ( fontsize == nil ) then
		fontsize = 36
	end
	if ( shadow == nil ) then
		shadow = true
	end

	-- Shadow
	if ( shadow ) then
		local offx, offy = PRK_GetUIPosVelocity( x, y, -PRK_HUD_Shadow_DistX, PRK_HUD_Shadow_DistY, PRK_HUD_Shadow_Effect )
		draw.SimpleText(
			text,
			"HeavyHUD" .. fontsize,
			offx,
			offy,
			PRK_HUD_Colour_Shadow,
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
		-- Default effect + punch effect (From gun firing, etc)
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
		-- Turn effect (stored on DrawHUD)
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

function draw.Box( x, y, w, h, color )
	if ( color ) then
		draw.SetDrawColor( color )
	end
	surface.DrawRect( x, y, w, h )
end

function draw.SetDrawColor( color )
	surface.SetDrawColor( color.r, color.g, color.b, color.a )
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

-- More in shared.lua
function draw.Circle( x, y, radius, seg, rotate )
	local cir = PRK_GetCirclePoints( x, y, radius, seg, rotate )
	surface.DrawPoly( cir )
end

function draw.StencilBasic( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetBlend(0) --makes shit invisible
		render.SetStencilReferenceValue(10)
			mask()
		render.SetBlend(1)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
			inner()
	render.SetStencilEnable(false)
end

function draw.StencilCut( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_REPLACE)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilCompareFunction(STENCIL_NEVER)
		render.SetStencilReferenceValue(1)
			mask()
		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
		render.SetStencilFailOperation(STENCIL_KEEP)
			inner()
	render.SetStencilEnable(false)
end

function PRK_AddModel( mdl, pos, ang, scale, mat, col )
	local model = ClientsideModel( mdl )
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
