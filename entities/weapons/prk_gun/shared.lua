AddCSLuaFile( "shared.lua" )

SWEP.PrintName	= "Prickly Gun"

SWEP.Author		= ""
SWEP.Purpose	= ""

SWEP.Spawnable	= true
SWEP.UseHands	= true
SWEP.DrawAmmo	= false

SWEP.ViewModel	= "models/weapons/w_357.mdl"
SWEP.WorldModel	= "models/weapons/w_357.mdl"

SWEP.ViewModelFOV	= 32
SWEP.Slot			= 0
SWEP.SlotPos		= 5

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

local dist = 3000
SWEP.MaxDistance			= dist
SWEP.MaxDistanceSqr			= dist * dist -- Store extra as sqr
SWEP.RightHanded			= 1
SWEP.TimeFire				= 0.2
SWEP.TimeReload				= 0.2

if ( SERVER ) then
	util.AddNetworkString( "PRK_Gun_Fire" )
	util.AddNetworkString( "PRK_Gun_Reload" )
	util.AddNetworkString( "PRK_Gun_NoAmmo" )

	function SWEP:SendFire()
		net.Start( "PRK_Gun_Fire" )
			net.WriteEntity( self )
		net.Send( self.Owner )
	end

	function SWEP:SendReload()
		net.Start( "PRK_Gun_Reload" )
			net.WriteEntity( self )
		net.Send( self.Owner )
	end

	function SWEP:SendNoAmmo()
		net.Start( "PRK_Gun_NoAmmo" )
			net.WriteEntity( self )
		net.Send( self.Owner )
	end
end

if ( CLIENT ) then
	net.Receive( "PRK_Gun_Fire", function( len, ply )
		local self = net.ReadEntity()

		self.GunPunch = 1
		self.GunPunchRnd = math.random( -10, 10 )
		PRK_Gun_UseAmmo() -- In main cl_init.lua

		-- Play shoot effect
		if ( self.GunModel and self.GunModel:IsValid() ) then
			local effectdata = EffectData()
				local pos = self.GunModel:GetPos() +
					self.GunModel:GetForward() * 50 +
					self.GunModel:GetRight() * 20 * self.RightHanded +
					LocalPlayer():GetVelocity() * 0.1
				effectdata:SetOrigin( pos )
				effectdata:SetNormal(
					self.GunModel:GetForward() +
					self.GunModel:GetUp()
				)
			util.Effect( "prk_hit", effectdata )
		end
	end )

	net.Receive( "PRK_Gun_Reload", function( len, ply )
		local self = net.ReadEntity()

		self:EmitSound( "buttons/lever7.wav" )

		self.GunPunch = -0.2
		self.GunPunchRnd = math.random( -10, 10 )
		PRK_Gun_AddAmmo() -- In main cl_init.lua
	end )

	net.Receive( "PRK_Gun_NoAmmo", function( len, ply )
		local self = net.ReadEntity()

		PRK_Gun_NoAmmoWarning()
	end )
end

function SWEP:Initialize()
	self:SetHoldType( "fist" )
	-- self:SetHoldType( "passive" )

	if ( SERVER ) then
		self.Owner:SetNWInt( "PRK_Clip", 6 )
		self.Owner:SetNWInt( "PRK_ExtraAmmo", 0 )
	end

	if ( CLIENT ) then
		PRK_Initialise_RevolverChambers()
	end
end

function SWEP:Think()
	-- self:SetHoldType( "knife" )
	-- self:SetHoldType( "slam" )
	-- self:SetHoldType( "fist" )
end

function SWEP:PreDrawViewModel( vm, wep, ply )
	vm:SetMaterial( "engine/occlusionproxy" ) -- Hide that view model with hacky material
end

-- function SWEP:SetupDataTables()
	-- self:NetworkVar( "Float", 0, "NextIdle" )
-- end

function SWEP:PrimaryAttack( right )
	-- Make sure we can shoot first
	-- if ( !self:CanPrimaryAttack() ) then return end
	local ammo = self.Owner:GetNWInt( "PRK_Clip" )
	if ( ammo <= 0 ) then
		-- Play sound
		self.Weapon:EmitSound( "buttons/lightswitch2.wav" )

		-- Show warning
		if ( SERVER ) then
			self:SendNoAmmo()
		end

		self:SetNextPrimaryFire( CurTime() + self.TimeFire )
		return
	end

	-- Play shoot sound
	self.Weapon:EmitSound( "weapons/grenade_launcher1.wav" )
	-- self.Weapon:EmitSound( "weapons/357_fire2.wav" )

	-- Play animation
	-- self.Weapon:SendWeaponAnim( ACT_VM_FIREMODE )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	-- Shoot 1 bullet, 150 damage, 0.01 aimcone
	-- self:ShootBullet( 150, 1, 0.01 )
	if ( SERVER ) then
		local bullet = ents.Create( "prk_bullet_heavy" )
		bullet:Spawn()
			-- Old code to launch from barrel
			-- bullet:Launch(
				-- self.Owner:EyePos() +
				-- self.Owner:GetForward() * 100 +
				-- self.Owner:GetRight() * 20,
				-- self.Owner:GetForward() * 1000 +
				-- self.Owner:GetUp() * 100 +
				-- self.Owner:GetRight() * -50
			-- )
			-- New code to appear at hit point and bounce back towards player
			local tr = self.Owner:GetEyeTrace()
			local pos = tr.HitPos + tr.HitNormal * 10
				-- Clamp pos to max distance
				local dir = pos - self.Owner:EyePos()
				if ( dir:LengthSqr() > self.MaxDistanceSqr ) then
					pos = self.Owner:GetPos() + dir:GetNormalized() * self.MaxDistance
				end
			local dir = ( self.Owner:EyePos() + Vector( 0, 0, 100 ) - tr.HitPos ):GetNormalized() * 8000 * 3
			bullet:Launch( pos, dir )
			local phys = bullet:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:AddAngleVelocity( VectorRand() * 1000 )
			end
			bullet:CollideWithEnt( tr.Entity )
		bullet.Owner = self.Owner

		-- Communicate with client
		self:SendFire()
	end

	-- Remove 1 bullet from our clip
	-- self:TakePrimaryAmmo( 1 )
	self.Owner:SetNWInt( "PRK_Clip", ammo - 1 )

	-- Punch the player's view
	self.Owner:ViewPunch( Angle( -5, math.random( -1, 1 ), 0 ) )
	local pushback = self.Owner:GetForward() * -20
		if ( self.Owner:IsOnGround() ) then
			pushback = pushback * 2
		end
		pushback.z = 0
	self.Owner:SetVelocity( pushback )

	self:SetNextPrimaryFire( CurTime() + self.TimeFire )
	self.NextReload = CurTime() + self.TimeReload
end

function SWEP:SecondaryAttack()
	
end

function SWEP:Reload()
	if ( SERVER ) then
		if ( !self.NextReload or self.NextReload <= CurTime() ) then
			local ammo = self.Owner:GetNWInt( "PRK_Clip" )
			local extraammo = self.Owner:GetNWInt( "PRK_ExtraAmmo" )
			if ( extraammo > 0 and ammo < 6 ) then
				-- Reload and communicate
				self.Owner:SetNWInt( "PRK_ExtraAmmo", extraammo - 1 )
				self.Owner:SetNWInt( "PRK_Clip", ammo + 1 )
				self:SendReload()

				-- Play sound
				self.Weapon:EmitSound( "buttons/lever7.wav" )

				-- Delay next shoot until reload finished
				self:SetNextPrimaryFire( CurTime() + 0.5 )
			elseif ( ammo == 0 ) then
				-- Play sound
				self.Weapon:EmitSound( "weapons/pistol/pistol_empty.wav" )

				-- Communicate warning
				self:SendNoAmmo()
			end

			self.NextReload = CurTime() + self.TimeReload
		end
	end
end

function SWEP:Holster( wep )
	self:OnRemove()

	return true
end

function SWEP:Deploy()
	return true
end

function SWEP:OnRemove()
	if ( IsValid( self.Owner ) ) then
		local vm = self.Owner:GetViewModel()
		if ( IsValid( vm ) ) then vm:SetMaterial( "" ) end
	end
end

if ( CLIENT ) then
	function SWEP:Initialize()
		-- Create if non-existant
		-- if ( !self.GunModel or !self.GunModel:IsValid() ) then
			local pos = LocalPlayer():GetViewModel():GetPos()
			local ang = LocalPlayer():GetViewModel():GetAngles()
			self.GunModel = PRK_AddModel( self.WorldModel, pos, ang, 1, "models/shiny", Color( 100, 100, 100, 255 ) )

			-- Scale
			local scale = Vector( 1, 3, 3 )

			local mat = Matrix()
				mat:Scale( scale )
			self.GunModel:EnableMatrix( "RenderMultiply", mat )

			-- Draw manually
			self.GunModel:SetNoDraw( true )

			-- self.GunModel:SetPos( pos )
			-- self.GunModel:SetAngles( ang )
			self.GunModel:SetParent( LocalPlayer():GetViewModel() )
			print( "create " )
		-- end
	end

	local ViewModel_Dest_Up = 0
	local targetpos = Vector()
	function SWEP:GetViewModelPosition( pos, ang )
		-- if ( IsFirstTimePredicted() ) then
			-- Default pos/ang
			local target = 
				pos +
				ang:Forward() * 20 +
				ang:Right() * 10 * self.RightHanded +
				ang:Up() * -15
			local speedpunch = 3
			local speed = 15 * PRK_Speed / 400
			local curpos = LocalPlayer():GetViewModel():GetPos() -- old targetpos?
			local dist = math.min( 1, curpos:Distance( target ) )
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
			self.GunPunch = Lerp( FrameTime() * speedpunch, self.GunPunch, 0 )
			self.GunPunchRnd = Lerp( FrameTime() * speedpunch, self.GunPunchRnd, 0 )

			-- Lerp
			pos = LerpVector( 0.016 * speed * dist, curpos, target )
			-- Check for NAN and correct (NAN should not be equal to anything)
			if ( pos.x != pos.x and pos.y != pos.y and pos.z != pos.z ) then
				pos = curpos
			end
			ang = targetang
			targetpos = target
		-- end

		-- local ang = LocalPlayer():GetRenderAngles()

		-- pos = pos + ( ang:Up() * 2 )
		-- pos = pos + ( ang:Forward() * -100 )
		-- pos = pos + ( ang:Right() * 1 )

		-- ang = ang + Angle( 14, -5, 0 )-- ViewModel_Angle_Roll )

		return pos, ang
	end
--
--	function SWEP:PostDrawViewModel( vm, weapon, ply )
--		-- Create if non-existant
--		if ( !self.GunModel or !self.GunModel:IsValid() ) then
--			self.GunModel = PRK_AddModel( self.WorldModel, Vector(), Angle(), 1, "models/shiny", Color( 100, 100, 100, 255 ) )
--
--			-- Scale
--			local scale = Vector( 1, 3, 3 )
--
--			local mat = Matrix()
--				mat:Scale( scale )
--			self.GunModel:EnableMatrix( "RenderMultiply", mat )
--
--			-- Draw manually
--			self.GunModel:SetNoDraw( true )
--		end
--
--		-- Default pos/ang
--		local target = 
--			vm:GetPos() +
--			vm:GetForward() * 115 +
--			vm:GetRight() * 10 * self.RightHanded +
--			vm:GetUp() * - 15
--		local speedpunch = 10
--		local speed = 40 * PRK_Speed / 400
--		local curpos = self.GunModel:GetPos()
--		local dist = math.min( 1, curpos:Distance( target ) )
--		local targetang =
--			vm:GetAngles() +
--			Angle( 0, 1, 0 ) * 10 * self.RightHanded
--
--		-- Gun punch
--		if ( !self.GunPunch ) then
--			self.GunPunch = 0
--			self.GunPunchRnd = 0
--		end
--		target =
--			target +
--			vm:GetUp() * 10 * self.GunPunch +
--			vm:GetForward() * -20 * self.GunPunch +
--			vm:GetRight() * self.GunPunchRnd / 10
--		targetang =
--			targetang +
--			Angle( -1, 0, 0 ) * 150 * self.GunPunch
--		self.GunPunch = Lerp( FrameTime() * speedpunch, self.GunPunch, 0 )
--		self.GunPunchRnd = Lerp( FrameTime() * speedpunch, self.GunPunchRnd, 0 )
--
--		-- Lerp
--		self.GunModel:SetPos( LerpVector( FrameTime() * speed * dist, curpos, target ) )
--		self.GunModel:SetAngles( targetang )
--	end

	function SWEP:OnRemove()
		if ( self.GunModel and self.GunModel:IsValid() ) then
			self.GunModel:Remove()
			self.GunModel = nil
		end
	end
end
