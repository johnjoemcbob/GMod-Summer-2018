AddCSLuaFile( "shared.lua" )

SWEP.PrintName	= "Prickly Gun"

SWEP.Author		= ""
SWEP.Purpose	= ""

SWEP.Spawnable	= true
SWEP.UseHands	= true
SWEP.DrawAmmo	= false

SWEP.ViewModel	= "models/weapons/v_357.mdl"
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
		PRK_Gun_UseAmmo() -- In main cl_init.lua

		-- Play shoot effect
		local effectdata = EffectData()
			local pos = self.GunModel:GetPos() +
				self.GunModel:GetForward() * 50 +
				self.GunModel:GetRight() * 20
			effectdata:SetOrigin( pos )
			effectdata:SetNormal(
				self.GunModel:GetForward() +
				self.GunModel:GetUp()
			)
		util.Effect( "prk_hit", effectdata )
	end )

	net.Receive( "PRK_Gun_Reload", function( len, ply )
		local self = net.ReadEntity()

		self.GunPunch = -0.2
		PRK_Gun_AddAmmo() -- In main cl_init.lua
	end )

	net.Receive( "PRK_Gun_NoAmmo", function( len, ply )
		local self = net.ReadEntity()

		PRK_Gun_NoAmmoWarning()
	end )
end

function SWEP:Initialize()
	self:SetHoldType( "normal" )
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
		self:SendNoAmmo()

		self:SetNextPrimaryFire( CurTime() + 0.5 )
		return
	end

	-- Play shoot sound
	self.Weapon:EmitSound( "weapons/grenade_launcher1.wav" )
	-- self.Weapon:EmitSound( "weapons/357_fire2.wav" )

	-- Shoot 1 bullet, 150 damage, 0.01 aimcone
	-- self:ShootBullet( 150, 1, 0.01 )
	if ( SERVER ) then
		local bullet = ents.Create( "prk_bullet_heavy" )
		bullet:Spawn()
		bullet:Launch(
			self.Owner:EyePos() +
			self.Owner:GetForward() * 100 +
			self.Owner:GetRight() * 20,
			self.Owner:GetForward() * 1000 +
			self.Owner:GetUp() * 100 +
			self.Owner:GetRight() * -50
		)
		bullet.Owner = self.Owner

		-- Communicate with client
		self:SendFire()
	end

	-- Remove 1 bullet from our clip
	-- self:TakePrimaryAmmo( 1 )
	self.Owner:SetNWInt( "PRK_Clip", ammo - 1 )

	-- Punch the player's view
	self.Owner:ViewPunch( Angle( -5, 0, 0 ) )
	local pushback = self.Owner:GetForward() * -20
		if ( self.Owner:IsOnGround() ) then
			pushback = pushback * 2
		end
		pushback.z = 0
	self.Owner:SetVelocity( pushback )

	-- print( "hi" )
	-- if ( CLIENT ) then -- Only in multiplayer
		-- self.GunPunch = 1

		-- PRK_Gun_UseAmmo() -- In main cl_init.lua
	-- end

	self:SetNextPrimaryFire( CurTime() + 0.5 )
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
			elseif ( ammo == 0 ) then
				-- Play sound
				self.Weapon:EmitSound( "weapons/pistol/pistol_empty.wav" )

				-- Communicate warning
				self:SendNoAmmo()
			end

			self.NextReload = CurTime() + 0.5
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
	local ViewModel_Dest_Up = 0
	function SWEP:GetViewModelPosition( pos, ang )
		local speed = 0.05

		-- local ang = LocalPlayer():GetRenderAngles()

		-- pos = pos + ( ang:Up() * 2 )
		pos = pos + ( ang:Forward() * -100 )
		-- pos = pos + ( ang:Right() * 1 )

		-- ang = ang + Angle( 14, -5, 0 )-- ViewModel_Angle_Roll )

		return pos, ang
	end

	function SWEP:PreDrawViewModel( vm, weapon, ply )
		local scale = Vector( 22221, 44, 4 )

		local mat = Matrix()
		mat:Scale( scale )
		-- LocalPlayer():GetViewModel():EnableMatrix( "RenderMultiply", mat )
	end

	function SWEP:PostDrawViewModel( vm, weapon, ply )
		-- Create if non-existant
		if ( !self.GunModel ) then
			self.GunModel = PRK_AddModel( self.WorldModel, Vector(), Angle(), 1, "models/shiny", Color( 100, 100, 100, 255 ) )

			-- Scale
			local scale = Vector( 1, 3, 3 )

			local mat = Matrix()
				mat:Scale( scale )
			self.GunModel:EnableMatrix( "RenderMultiply", mat )

			-- Draw manually
			self.GunModel:SetNoDraw( true )
		end

		-- Default pos/ang
		local target = 
			vm:GetPos() +
			vm:GetForward() * 115 +
			vm:GetRight() * 10 +
			vm:GetUp() * - 15
		local speedpunch = 10
		local speed = 40
		local curpos = self.GunModel:GetPos()
		local dist = math.min( 1, curpos:Distance( target ) )
		local targetang =
			vm:GetAngles() +
			Angle( 0, 1, 0 ) * 10

		-- Gun punch
		if ( !self.GunPunch ) then
			self.GunPunch = 0
		end
		target =
			target +
			vm:GetUp() * 10 * self.GunPunch +
			vm:GetForward() * -20 * self.GunPunch
		targetang =
			targetang +
			Angle( -1, 0, 0 ) * 150 * self.GunPunch
		self.GunPunch = Lerp( FrameTime() * speedpunch, self.GunPunch, 0 )

		-- Lerp
		self.GunModel:SetPos( LerpVector( FrameTime() * speed * dist, curpos, target ) )
		self.GunModel:SetAngles( targetang )
	end

	function SWEP:OnRemove()
		if ( self.GunModel ) then
			self.GunModel:Remove()
		end
	end
end
