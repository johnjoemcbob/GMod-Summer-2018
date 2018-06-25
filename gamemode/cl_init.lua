--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Clientside
--

include( "shared.lua" )

-- Materials
PRK_Material_Icon_Bullet = Material( "icon_bullet.png", "noclamp smooth" )

-- Fonts
local function loadfonts()
	surface.CreateFont( "HeavyHUD", {
		font = "Alte Haas Grotesk", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = false,
		size = 36,
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
loadfonts()

-- Variables
local LagX = 10
local LagY = 5

-- Gamemode Hooks
function GM:Initialize()
	PRK_Initialise_RevolverChambers()
end

function GM:Think()
	PRK_Think_RevolverChambers()
end

function GM:HUDPaint()
	PRK_HUDPaint_Health()

	PRK_HUDPaint_Money()

	PRK_HUDPaint_ExtraAmmo()
	PRK_HUDPaint_RevolverChambers()

	-- Must be last!
	LocalPlayer().LastEyeAngles = LocalPlayer():EyeAngles()
end

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
	["CHudBattery"] = true
}
function GM:HUDShouldDraw( name )
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

function PRK_HUDPaint_Health()
	local r = 16
	local s = r
	local sb = r + 4
	local x = r * 3
	local y = ScrH() - r * 3
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	local maxhealth = LocalPlayer():GetMaxHealth()
	local health = LocalPlayer():Health()
	local function mask()
		-- Draw heart icons for max health
		for i = 1, maxhealth / 2 do
			surface.SetDrawColor( 70, 20, 30, 255 )
			draw.Heart( x + ( sb + s ) * i, y - s, s, 16 )
		end
	end
	local function inner()
		-- Draw filled rectangle for health bar
		surface.SetDrawColor( 150, 20, 70, 255 )
		draw.NoTexture()
		surface.DrawTexturedRect( x + sb, y - s * 2, ( sb + s ) * health / 2, s * 2 )
	end
	draw.StencilBasic( mask, inner )
end

function PRK_HUDPaint_Money()
	local r = 32
	local s = r
	local sb = r + 4
	local x = r * 2.2
	local y = ScrH() - r * 1
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	local money = LocalPlayer():GetNWInt( "PRK_Money" )
		money = "€" .. money
	PRK_DrawText(
		money,
		x,
		y,
		Color( 255, 255, 50, 255 ),
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
	)
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
end

function PRK_HUDPaint_ExtraAmmo()
	local r = 64
	local s = 32
	local x = ScrW() - r * 3
	local y = ScrH() - r * 1
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	-- Draw ammo icon
	surface.SetDrawColor( 100, 190, 190, 255 )
	surface.SetMaterial( PRK_Material_Icon_Bullet )
		surface.DrawTexturedRect( x - s / 1.5, y - s / 2, s / 2, s )
	draw.NoTexture()

	-- Draw ammo number
	local extraammo = LocalPlayer():GetNWInt( "PRK_ExtraAmmo" )
		if ( extraammo < 10 ) then
			extraammo = "0" .. extraammo
		end
		extraammo = "x" .. extraammo
	PRK_DrawText(
		extraammo,
		x,
		y,
		Color( 255, 255, 255, 255 ),
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
	)
end

function PRK_HUDPaint_RevolverChambers()
	if ( !LocalPlayer():GetActiveWeapon() or !LocalPlayer():GetActiveWeapon():IsValid() or LocalPlayer():GetActiveWeapon():GetClass() != "prk_gun" ) then return end

	local r = 48
		r = r + PRK_RevolverChambers.LastChange * 4
	local x = ScrW() - r * 5.7
	local y = ScrH() - r * 1.2
	local ang = PRK_RevolverChambers.Ang
	-- Move slightly with player
	x, y = PRK_GetUIPosVelocity( x, y, LagX, LagY )

	local chambers = LocalPlayer():GetActiveWeapon().MaxClip

	-- Draw background
	surface.SetDrawColor( 230, 230, 240, 255 )
	if ( PRK_RevolverChambers.NoAmmoWarning ) then
		surface.SetDrawColor( 230, 130, 130, 255 )
	end
	draw.Circle( x, y, r, chambers, ang )

	-- Draw individual chambers
	local points = PRK_GetCirclePoints( x, y, r - chambers * 3, chambers, ang + 180 )
	local cham_rad = r / chambers * 1.5
	local ammo = LocalPlayer():GetNWInt( "PRK_Clip" )
	for k, point in pairs( points ) do
		if ( k <= ammo + 1 ) then
			surface.SetDrawColor( 100, 190, 190, 255 )
		else
			surface.SetDrawColor( 0, 20, 20, 255 )
		end
		draw.Circle( point.x, point.y, cham_rad, 32, 0 )
	end

	-- Draw 'No Ammo' warning
	if ( PRK_RevolverChambers.NoAmmoWarning ) then
		-- Draw message above empty chambers
		local message = "RELOAD"
			local extraammo = LocalPlayer():GetNWInt( "PRK_ExtraAmmo" )
			if ( extraammo == 0 ) then
				message = "FIND AMMO"
			end
		local pulsespeed = 10
		local pulsemag = 105
		PRK_DrawText(
			message,
			x,
			y - r * 1.3,
			Color( 255, 255, 255, 255 - pulsemag + math.sin( CurTime() * pulsespeed ) * pulsemag ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)

		-- Draw R in the middle of chambers
		local pulsemag = 20
		PRK_DrawText(
			"R",
			x,
			y - 2,
			Color( 255, 255, 255, 255 - pulsemag + math.sin( CurTime() * pulsespeed ) * pulsemag ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)
	end
end

function PRK_Gun_UseAmmo()
	PRK_RevolverChambers.TargetAng = PRK_RevolverChambers.TargetAng - 60
end

function PRK_Gun_AddAmmo()
	PRK_RevolverChambers.TargetAng = PRK_RevolverChambers.TargetAng + 60
	PRK_RevolverChambers.NoAmmoWarning = false
	PRK_RevolverChambers.ExtraChange = 1
end

function PRK_Gun_NoAmmoWarning()
	PRK_RevolverChambers.NoAmmoWarning = true
end
------------------
  -- /PRK Gun --
------------------

local function MyCalcView( ply, pos, angles, fov )
	local view = {}

	view.origin = pos -- ( angles:Forward() * 100 )
	view.angles = angles
	view.fov = fov
	view.drawviewer = false
	view.zfar = 3050

	return view
end
hook.Add( "CalcView", "PRK_CalcView_DrawDistance", MyCalcView )

concommand.Add( "prk_effect", function( ply, cmd, args )
	local effectdata = EffectData()
		effectdata:SetOrigin( LocalPlayer():GetPos() )
	util.Effect( "prk_grass", effectdata )
end )

--------------
  -- Util --
--------------
function PRK_DrawText( text, x, y, col, xalign, yalign )
	-- Shadow
	local offx, offy = PRK_GetUIPosVelocity( x, y, -2, 2, 2 )
	-- local left = ( x <= ScrW() / 2 )
	-- local bott = ( y <= ScrH() / 2 )
	-- local offx = 2
		-- if ( left ) then
			-- offx = -offx
		-- end
	-- local offy = -2
		-- if ( bott ) then
			-- offy = -offy
		-- end
	draw.SimpleText(
		text,
		"HeavyHUD",
		offx,
		offy,
		Color( 255, 100, 150, 255 ),
		xalign,
		yalign
	)

	-- Real text
	draw.SimpleText(
		text,
		"HeavyHUD",
		x,
		y,
		col,
		xalign,
		yalign
	)
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
		-- Velocity effect
		local vel = LocalPlayer():GetVelocity()
		local rgt = -LocalPlayer():GetRight()
		local up  = LocalPlayer():GetUp()
			targetx = targetx + vel:Dot( rgt ) / PRK_Speed * effect
			targety = targety + vel:Dot( up ) / PRK_Speed * effect
		-- Turn effect (stored on DrawHUD)
		-- if ( vel:Length() < PRK_Speed / 10 ) then
			-- if ( LocalPlayer().LastEyeAngles ) then
				-- local bac = -LocalPlayer():GetForward()
				-- local movingback = 1 -- vel:Dot( bac ) > 0 and -1 or 1
				-- print( movingback )
				-- local max = 5
				-- local eye = LocalPlayer():EyeAngles()
					-- targetx = targetx + movingback * math.Clamp( math.AngleDifference( eye.y, LocalPlayer().LastEyeAngles.y ), -max, max ) * effectrotate * effect
					-- targety = targety + movingback * -math.Clamp( math.AngleDifference( eye.x, LocalPlayer().LastEyeAngles.x ), -max, max ) * effectrotate * effect
			-- end
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
---------------
  -- /Util --
---------------
