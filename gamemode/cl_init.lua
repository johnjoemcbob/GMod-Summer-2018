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
	PRK_HUDPaint_ExtraAmmo()
	PRK_HUDPaint_RevolverChambers()
end

function GM:PostDrawHUD()
	cam.Start3D()
		local wep = LocalPlayer():GetActiveWeapon()
		if ( wep.GunModel ) then
			wep.GunModel:DrawModel()
		end
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
		local message = "RELOAD"
			local extraammo = LocalPlayer():GetNWInt( "PRK_ExtraAmmo" )
			if ( extraammo == 0 ) then
				message = "FIND AMMO"
			end
		draw.SimpleText(
			message,
			"CloseCaption_Bold",
			x,
			y - r * 1.3,
			Color( 255, 255, 255, 150 + math.sin( CurTime() * 10 ) * 105 ),
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
-- From: http://wiki.garrysmod.com/page/surface/DrawPoly
function draw.Circle( x, y, radius, seg, rotate )
	local cir = PRK_GetCirclePoints( x, y, radius, seg, rotate )
	surface.DrawPoly( cir )
end

function PRK_GetCirclePoints( x, y, radius, seg, rotate )
	local cir = {}
		-- table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( ( i / seg ) * -360 ) + rotate )
			table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end

		-- local a = math.rad( 0 ) -- This is need for non absolute segment counts
		-- table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	return cir
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
