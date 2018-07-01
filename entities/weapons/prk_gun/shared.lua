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

SWEP.RequireAmmo			= true
SWEP.MaxClip				= 6
local dist = 3000
SWEP.MaxDistance			= dist
SWEP.MaxDistanceSqr			= dist * dist -- Store extra as sqr
SWEP.RightHanded			= 1
SWEP.TimeFire				= 0.2
SWEP.TimeReload				= 0.2
SWEP.TimeFOVPunch			= 0.1
SWEP.TimeBackFOVPunch		= 0.2
SWEP.TimeHoldFOVPunch		= 0.1
SWEP.DistFOVPunch			= 10
SWEP.LerpSpeedPunch		= 1
SWEP.LerpSpeed				= 10
SWEP.SoundPitchFireBase = 100
SWEP.SoundPitchFireIncrease = -3
SWEP.SoundPitchFireSpeed = 0.2
SWEP.SoundPitchReloadBase = 80
SWEP.SoundPitchReloadIncrease = 10
SWEP.SoundPitchReloadSpeed = 0.4

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

		-- self:EmitSound( "buttons/lever7.wav" )

		self.GunPunch = -0.4
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

	if ( SERVER ) then
		self.Owner:SetNWInt( "PRK_Clip", self.MaxClip )
		self.Owner:SetNWInt( "PRK_ExtraAmmo", 0 )
	end

	if ( CLIENT ) then
		PRK_Initialise_RevolverChambers()
	end
end

function SWEP:Think()
	if ( self.FOVPunch and self.FOVPunch <= CurTime() ) then
		self.Owner:SetFOV( 0, self.TimeBackFOVPunch )
		self.FOVPunch = nil
	end

	self:NextThink( CurTime() + 1 )
	return true
end

function SWEP:PreDrawViewModel( vm, wep, ply )
	vm:SetMaterial( "engine/occlusionproxy" ) -- Hide that view model with hacky material
end

function SWEP:PrimaryAttack( right )
	-- Make sure we can shoot first
	local ammo = self.Owner:GetNWInt( "PRK_Clip" )
	if ( self.RequireAmmo and ammo <= 0 ) then
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
	PRK_EmitPitchedSound(
		self.Owner:Nick() .. "_PRK_Gun_Fire",
		self.Weapon,
		"weapons/grenade_launcher1.wav",
		75,
		1,
		self.SoundPitchFireBase,
		self.SoundPitchFireIncrease,
		self.SoundPitchFireSpeed
	)

	-- Play animation
	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	-- Shoot 1 bullet, 150 damage, 0.01 aimcone
	if ( SERVER ) then
		local bullet = ents.Create( "prk_bullet_heavy" )
		bullet:Spawn()
        bullet.Owner = self.Owner
			-- Appear at hit point and bounce back towards player
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
		
		-- Remove 1 bullet from our clip
		if ( self.RequireAmmo ) then
			self.Owner:SetNWInt( "PRK_Clip", ammo - 1 )
		end

		-- Communicate with client
		self:SendFire()
	end

	-- Punch FOV (if not running backwards - this felt bad, like the player had stopped moving)
	local vel = self.Owner:GetVelocity()
	local bac = -self.Owner:GetForward()
	local movingback = vel:Dot( bac ) > 0
	-- if ( !movingback ) then
		if ( !self.FOVBase ) then
			self.FOVBase = self.Owner:GetFOV()
		end
		local base = self.FOVBase
		local fov = base + self.DistFOVPunch
			if ( movingback ) then
				fov = base - self.DistFOVPunch
			end
		self.Owner:SetFOV( fov, self.TimeFOVPunch )
		self.FOVPunch = CurTime() + self.TimeFOVPunch + self.TimeHoldFOVPunch
	-- end

	-- Punch the player's view
	self.Owner:ViewPunch( Angle( -5, math.random( -1, 1 ), 0 ) )
	local pushback = self.Owner:GetForward() * -20
		if ( self.Owner:IsOnGround() ) then
			pushback = pushback * 2
		end
		pushback.z = 0
	-- self.Owner:SetVelocity( pushback )

	self:SetNextPrimaryFire( CurTime() + self.TimeFire )
	self.NextReload = CurTime() + self.TimeReload
end

function SWEP:SecondaryAttack()
	
end

function SWEP:Reload()
	if ( !self.NextReload or self.NextReload <= CurTime() ) then
		local ammo = self.Owner:GetNWInt( "PRK_Clip" )
		local extraammo = self.Owner:GetNWInt( "PRK_ExtraAmmo" )
		if ( extraammo > 0 and ammo < self.MaxClip ) then
			-- Reload and communicate
			if ( SERVER ) then
				self.Owner:SetNWInt( "PRK_ExtraAmmo", extraammo - 1 )
				self.Owner:SetNWInt( "PRK_Clip", ammo + 1 )
				self:SendReload()
			end

			-- Play sound
			-- self.Weapon:EmitSound( "buttons/lever7.wav" )
			PRK_EmitPitchedSound(
				self.Owner:Nick() .. "_PRK_Gun_Reload",
				self.Weapon,
				"buttons/lever7.wav",
				75,
				1,
				self.SoundPitchReloadBase,
				self.SoundPitchReloadIncrease,
				self.SoundPitchReloadSpeed
			)

			-- Delay next shoot until reload finished
			self:SetNextPrimaryFire( CurTime() + 0.5 )
		elseif ( ammo == 0 ) then
			-- Play sound
			self.Weapon:EmitSound( "weapons/pistol/pistol_empty.wav" )

			-- Communicate warning
			if ( SERVER ) then
				self:SendNoAmmo()
			end
		end

		self.NextReload = CurTime() + self.TimeReload
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

	local curpos = Vector()
	function SWEP:GetViewModelPosition( pos, ang )
		local frametime = PRK_GetFrameTime()
			-- Default pos/ang
			local target = 
				pos +
				ang:Forward() * 20 +
				ang:Right() * 10 * self.RightHanded +
				ang:Up() * -15
			local speedpunch = self.LerpSpeedPunch
			local speed = self.LerpSpeed * PRK_Speed / 400
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
end
