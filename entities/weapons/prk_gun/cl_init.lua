
include( "shared.lua" )

PRK_Initialise_RevolverChambers()

net.Receive( "PRK_Gun_Fire", function( len, ply )
	local self = net.ReadEntity()
	local tab = net.ReadTable()
	local spn = net.ReadBool()

	self.ChamberBullets = tab

	self.GunPunch = 1
	self.GunPunchRnd = math.random( -10, 10 )
	if ( spn ) then
		PRK_Gun_UseAmmo() -- In main cl_init.lua
	end
end )

net.Receive( "PRK_Gun_Reload", function( len, ply )
	local self = net.ReadEntity()
	local tab = net.ReadTable()
	local dir = net.ReadFloat()

	self.ChamberBullets = tab

	self.GunPunch = -0.4
	self.GunPunchRnd = math.random( -10, 10 )
	PRK_Gun_AddAmmo( dir ) -- In main cl_init.lua
end )

net.Receive( "PRK_Gun_NoAmmo", function( len, ply )
	local self = net.ReadEntity()

	PRK_Gun_NoAmmoWarning()
end )

net.Receive( "PRK_Gun_SetNumChambers", function( len, ply )
	local self = net.ReadEntity()
	local tab = net.ReadTable()
	local chambers = net.ReadFloat()

	self.ChamberBullets = tab

	-- Offset for new chambers, to keep current chamber at the top ready to be fired
	local targ = self.TargetMaxClip or self.MaxClip
	local oldoff = PRK_RevolverChambers.TargetAng / 360 * targ - 1
	self.TargetMaxClip = chambers
	PRK_RevolverChambers.TargetAng = 360 / self.TargetMaxClip * oldoff
end )

function SWEP:OnEntityCreated()
	PRK_Initialise_RevolverChambers()

	self:CreateGunModel()
end

function SWEP:CreateGunModel()
	-- Requires focus to create the viewmodel (otherwise it doesn't show)
	if ( system.HasFocus() ) then
		-- Create if non-existant
		local pos = LocalPlayer():GetViewModel():GetPos()
		local ang = LocalPlayer():GetViewModel():GetAngles()
		self.GunModel = PRK_AddModel( self.WorldModel, pos, ang, 1, "models/shiny", Color( 100, 100, 100, 255 ) )

		-- Scale
		local scale = Vector( 1, 3, 3 )

		local mat = Matrix()
			mat:Scale( scale )
		self.GunModel:EnableMatrix( "RenderMultiply", mat )

		self.GunModel:SetParent( LocalPlayer():GetViewModel() )
	end
end

local curpos = Vector()
function SWEP:GetViewModelPosition( pos, ang )
	if ( PRK_InEditor( self.Owner ) ) then return end

	if ( !system.HasFocus() ) then
		if ( self.GunModel and self.GunModel:IsValid() ) then
			self.GunModel:Remove()
			self.GunModel = nil
		end
		return
	end
	if ( !self.GunModel or !self.GunModel:IsValid() ) then
		self:CreateGunModel()
	end

	local frametime = PRK_GetFrameTime()
		-- Default pos/ang
		local target = 
			pos +
			ang:Forward() * 20 +
			ang:Right() * 10 * self.RightHanded +
			ang:Up() * -15
		local speedpunch = PRK_Gun_PunchLerpSpeed
		local speed = PRK_Gun_MoveLerpSpeed * PRK_Speed / 400
		if ( !game.SinglePlayer() ) then
			curpos = LocalPlayer():GetViewModel():GetPos()
		end
		local dist = 1
		local targetang =
			ang +
			Angle( 0, 1, 0 ) * 10 * self.RightHanded

		-- Gun punch
		if ( !self.GunPunch ) then
			self.GunPunch = 0
			self.GunPunchRnd = 0
		end
		target =
			target +
			ang:Up() * 10 * self.GunPunch +
			ang:Forward() * -20 * self.GunPunch +
			ang:Right() * self.GunPunchRnd / 10
		targetang =
			targetang +
			Angle( -1, 0, 0 ) * 150 * self.GunPunch
		self.GunPunch = math.Approach( self.GunPunch, 0, frametime * speedpunch )
		self.GunPunchRnd = math.Approach( self.GunPunchRnd, 0, frametime * speedpunch )

		-- Lerp
		-- print( frametime * speed * dist )
		pos = LerpVector( frametime * speed * dist, curpos, target )
		ang = targetang
		curpos = pos
	return pos, ang
end

function SWEP:OnRemove()
	if ( self.GunModel and self.GunModel:IsValid() ) then
		self.GunModel:Remove()
		self.GunModel = nil
	end
end
