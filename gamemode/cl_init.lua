--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Clientside
--

include( "shared.lua" )

-- Materials
PRK_Material_Icon_Bullet = Material( "icon_bullet.png", "noclamp smooth" )

function GM:Initialize()
	PRK_Initialise_RevolverChambers()
end

function GM:Think()
	PRK_Think_RevolverChambers()
end

function GM:HUDPaint()
	PRK_HUDPaint_Health()

	PRK_HUDPaint_ExtraAmmo()
	PRK_HUDPaint_RevolverChambers()
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
	local x = 0
	local y = ScrH() - r * 1

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
		surface.SetDrawColor( 255, 20, 30, 255 )
		draw.NoTexture()
		surface.DrawTexturedRect( x + s, y - s * 2, x + ( sb + s ) * health / 2, s * 2 )
	end
	draw.StencilBasic( mask, inner )
end

-----------------
  -- PRK Gun --
-----------------
function PRK_Initialise_RevolverChambers()
	PRK_RevolverChambers = {
		Ang = 0,
		TargetAng = 0,
		NoAmmoWarning = false,
	}
end

function PRK_Think_RevolverChambers()
	local speed = FrameTime() * 10
	PRK_RevolverChambers.Ang = Lerp( speed, PRK_RevolverChambers.Ang, PRK_RevolverChambers.TargetAng )
	-- PRK_RevolverChambers.Ang = math.ApproachAngle( PRK_RevolverChambers.Ang, PRK_RevolverChambers.TargetAng, speed )
end

function PRK_HUDPaint_ExtraAmmo()
	local r = 64
	local s = 32
	local x = ScrW() - r * 1
	local y = ScrH() - r * 1

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
	draw.SimpleText(
		extraammo,
		"CloseCaption_Bold",
		x,
		y,
		Color( 255, 255, 255, 255 ),
		TEXT_ALIGN_LEFT,
		TEXT_ALIGN_CENTER
	)
end

function PRK_HUDPaint_RevolverChambers()
	local r = 48
	local x = ScrW() - r * 3
	local y = ScrH() - r * 1.2
	local ang = PRK_RevolverChambers.Ang

	-- Draw background
	surface.SetDrawColor( 230, 230, 240, 255 )
	if ( PRK_RevolverChambers.NoAmmoWarning ) then
		surface.SetDrawColor( 230, 130, 130, 255 )
	end
	draw.Circle( x, y, r, 6, ang )

	-- Draw individual chambers
	local chambers = 6
	local points = PRK_GetCirclePoints( x, y, r / 10 * 6, chambers, ang + 180 )
	local cham_rad = r / 4
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
		draw.SimpleText(
			message,
			"CloseCaption_Bold",
			x,
			y - r * 1.3,
			Color( 255, 255, 255, 255 - pulsemag + math.sin( CurTime() * pulsespeed ) * pulsemag ),
			TEXT_ALIGN_CENTER,
			TEXT_ALIGN_CENTER
		)

		-- Draw R in the middle of chambers
		local pulsemag = 20
		draw.SimpleText(
			"R",
			"CloseCaption_Bold",
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
