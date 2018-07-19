
SWEP.PrintName						= "Prickly Gun"

SWEP.Author								= ""
SWEP.Purpose							= ""

SWEP.Spawnable						= true
SWEP.UseHands							= true
SWEP.DrawAmmo						= false

SWEP.ViewModel						= "models/weapons/w_357.mdl"
SWEP.WorldMode						= "models/weapons/w_357.mdl"

SWEP.ViewModelFOV					= 32
SWEP.Slot									= 0
SWEP.SlotPos							= 5

SWEP.Primary.ClipSize				= -1
SWEP.Primary.DefaultClip			= -1
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo					= "none"

SWEP.Secondary.ClipSize			= -1
SWEP.Secondary.DefaultClip		= -1
SWEP.Secondary.Automatic		= true
SWEP.Secondary.Ammo				= "none"

SWEP.RequireAmmo					= true
SWEP.MaxClip							= PRK_BaseClip
local dist = 3000
SWEP.MaxDistance						= dist
SWEP.MaxDistanceSqr				= dist * dist -- Store extra as sqr
SWEP.RightHanded					= 1
SWEP.TimeFire							= 0.2
SWEP.TimeReload						= 0.2
SWEP.TimeFOVPunch					= 0.1
SWEP.TimeBackFOVPunch			= 0.2
SWEP.TimeHoldFOVPunch			= 0.1
SWEP.DistFOVPunch					= 10
SWEP.LerpSpeedPunch				= 1
SWEP.LerpSpeed						= 10
SWEP.SoundPitchFireBase			= 100
SWEP.SoundPitchFireIncrease		= -50 --  -3
SWEP.SoundPitchFireSpeed		= 0.2
SWEP.SoundPitchReloadBase		= 80
SWEP.SoundPitchReloadIncrease	= 10
SWEP.SoundPitchReloadSpeed	= 0.4

PRK_BulletTypeInfo = {
	-- Empty
	[0] = {
		Paint = function( info, self, x, y, r )
			
		end,
		CanFire = function( info )
			return false
		end,
	},
	-- Default
	[1] = {
		Paint = function( info, self, x, y, r )
			local r = r * 3
			draw.Rect( x - r / 2, y - r / 2, r, r, Color( 100, 190, 190, 255 ) )
		end,
		CanFire = function( info )
			return true
		end,
		Fire = function( info, self )
			-- Play shoot sound
			self:EmitSound(
				"weapons/grenade_launcher1.wav",
				75,
				self.SoundPitchFireBase + ( self.SoundPitchFireIncrease * ( 1 - ( self:GetFilledChamberCount() / self.MaxClip ) ) )
			)

			-- Play first impact effect at spawn point
			local tr = self.Owner:GetEyeTrace()
			local effectdata = EffectData()
				local pos = tr.HitPos
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "prk_hit", effectdata )

			-- Spawn bullet
			if ( SERVER ) then
				local bullet = ents.Create( "prk_bullet_heavy" )
				bullet:Spawn()
				bullet.Owner = self.Owner
				-- Appear at hit point and bounce back towards player
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
			end

			-- return takeammo, spin, shootparticles, punch
			return true, true, true, true
		end,
	},
	-- Default
	[1] = {
		Paint = function( info, self, x, y, r )
			local r = r * 3
			draw.Rect( x - r / 2, y - r / 2, r, r, Color( 100, 190, 190, 255 ) )
		end,
		CanFire = function( info )
			return true
		end,
		Fire = function( info, self )
			-- Play shoot sound
			self:EmitSound(
				"weapons/grenade_launcher1.wav",
				75,
				self.SoundPitchFireBase + ( self.SoundPitchFireIncrease * ( 1 - ( self:GetFilledChamberCount() / self.MaxClip ) ) )
			)

			-- Play first impact effect at spawn point
			local tr = self.Owner:GetEyeTrace()
			local effectdata = EffectData()
				local pos = tr.HitPos
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "prk_hit", effectdata )

			-- Spawn bullet
			if ( SERVER ) then
				local bullet = ents.Create( "prk_bullet_heavy" )
				bullet:Spawn()
				bullet.Owner = self.Owner
				-- Appear at hit point and bounce back towards player
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
			end

			-- return takeammo, spin, shootparticles, punch
			return true, true, true, true
		end,
	},
	-- Test
	[2] = {
		Paint = function( info, self, x, y, r )
			-- Initialise
			if ( !self.Fires ) then
				self.Fires = 6
			end

			local r = r * 3
			draw.Rect( x - r / 2, y - r / 2, r, r, Color( 210, 210, 220, 255 ) )

			local ang = 0
			local chambers = 6
			local cham_rad = r / 16
			local points = PRK_GetCirclePoints( x, y, r - cham_rad * 13, chambers, ang )
				-- Remove middle point
				table.remove( points, 1 )
			for chamber, point in pairs( points ) do
				if ( chamber <= self.Fires ) then
					surface.SetDrawColor( 100, 190, 190, 255 )
				else
					surface.SetDrawColor( 10, 10, 20, 255 )
				end
				draw.Circle( point.x, point.y, math.min( 18, cham_rad ), 32, 0 )
			end
		end,
		CanFire = function( info )
			return true
		end,
		Fire = function( info, self )
			-- Initialise
			if ( !self.Fires ) then
				self.Fires = 6
			end

			-- Play shoot sound
			self:EmitSound(
				"weapons/grenade_launcher1.wav",
				75,
				50 + self.SoundPitchFireBase + ( self.SoundPitchFireIncrease * ( 1 - ( self.Fires / 6 ) ) )
			)

			-- Play first impact effect at spawn point
			local tr = self.Owner:GetEyeTrace()
			local effectdata = EffectData()
				local pos = tr.HitPos
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "prk_hit", effectdata )

			-- Spawn bullet
			if ( SERVER ) then
				local bullet = ents.Create( "prk_bullet_heavy" )
				bullet:Spawn()
				bullet.Owner = self.Owner
				-- Appear at hit point and bounce back towards player
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
			end

			self.Fires = self.Fires - 1
			if ( self.Fires <= 0 ) then
				return true, true, true, true
			end
			-- return takeammo, spin, shootparticles, punch
			return false, false, true, true
		end,
	},
	-- Test
	[3] = {
		Paint = function( info, self, x, y, r )
			local r = r * 3
			draw.Rect( x - r / 2, y - r / 2, r, r, Color( 210, 100, 220, 255 ) )
		end,
		CanFire = function( info )
			return true
		end,
		Fire = function( info, self )
			-- Play shoot sound
			self:EmitSound(
				"weapons/grenade_launcher1.wav",
				75,
				self.SoundPitchFireBase + ( self.SoundPitchFireIncrease * ( 1 - ( self:GetFilledChamberCount() / self.MaxClip ) ) )
			)

			-- Play first impact effect at spawn point
			local tr = self.Owner:GetEyeTrace()
			local effectdata = EffectData()
				local pos = tr.HitPos
				effectdata:SetOrigin( pos )
				effectdata:SetNormal( tr.HitNormal )
			util.Effect( "prk_hit", effectdata )

			-- Spawn spider
			if ( SERVER ) then
				local spider = ents.Create( "prk_npc_sploder" )
				spider:SetNWFloat( "Scale", 0.5 )
				spider:Spawn()
				spider:SetNoDraw( true )
				timer.Simple( 0.04, function()
					spider:SetNoDraw( false )
					spider:BroadcastScale( 0.5 )
				end )
				spider.Owner = self.Owner
				-- Appear at hit point and bounce back towards player
				local pos = tr.HitPos + tr.HitNormal * 10
					-- Clamp pos to max distance
					local dir = pos - self.Owner:EyePos()
					if ( dir:LengthSqr() > self.MaxDistanceSqr ) then
						pos = self.Owner:GetPos() + dir:GetNormalized() * self.MaxDistance
					end
				spider:SetPos( pos )
			end

			-- return takeammo, spin, shootparticles, punch
			return true, true, true, true
		end,
	},
}
PRK_BulletType = {
	["Empty"] = 0,
	["Default"] = 1,
	["Test1"] = 2,
	["Test2"] = 3,
}

sound.Add(
	{ 
		name = "prk_gun_spin",
		channel = CHAN_ITEM,
		level = 75,
		volume = 0.25,
		pitch = { 40, 51 },
		sound = "weapons/357/357_spin1.wav"
	}
)

if ( SERVER ) then
	util.AddNetworkString( "PRK_Gun_Fire" )
	util.AddNetworkString( "PRK_Gun_Reload" )
	util.AddNetworkString( "PRK_Gun_NoAmmo" )
    util.AddNetworkString( "PRK_Gun_SetNumChambers" )

	function SWEP:SendFire( spin )
		net.Start( "PRK_Gun_Fire" )
			net.WriteEntity( self )
			net.WriteTable( self.ChamberBullets )
			net.WriteBool( spin )
		net.Send( self.Owner )
	end

	function SWEP:SendReload( dir )
		net.Start( "PRK_Gun_Reload" )
			net.WriteEntity( self )
			net.WriteTable( self.ChamberBullets )
			net.WriteFloat( dir )
		net.Send( self.Owner )
	end

	function SWEP:SendNoAmmo()
		net.Start( "PRK_Gun_NoAmmo" )
			net.WriteEntity( self )
		net.Send( self.Owner )
	end
    
    function SWEP:SendNumChambers( chambers )
        net.Start( "PRK_Gun_SetNumChambers" )
            net.WriteEntity( self )
			net.WriteTable( self.ChamberBullets )
            net.WriteFloat( chambers )
        net.Send( self.Owner )
    end
end

function SWEP:Initialize()
	self:SetHoldType( "fist" )

	-- Initialise networked variables
	self.Owner:SetNWInt( "PRK_CurrentChamber", 1 )
	self.Owner:SetNWInt( "PRK_ExtraAmmo", 0 )

	-- Initialise chambers to filled with normal bullets on client and server
	self.ChamberBullets = {}
	for i = 1, self.MaxClip do
		self.ChamberBullets[i] = PRK_BulletType.Default
	end
	self.ChamberBullets[1] = PRK_BulletType.Test1
	self.ChamberBullets[2] = PRK_BulletType.Test2
end

function SWEP:Think()
	if ( PRK_InEditor( self.Owner ) ) then return end

	if ( self.FOVPunch and self.FOVPunch <= CurTime() ) then
		self.Owner:SetFOV( 0, self.TimeBackFOVPunch )
		self.FOVPunch = nil
	end

	if ( self.TargetMaxClip ) then
		local speed = 5
		self.MaxClip = math.Approach( self.MaxClip, self.TargetMaxClip, FrameTime() * speed )
	end

	if ( CLIENT ) then
		if ( self.GunModel and self.GunModel:IsValid() ) then
			self.GunModel:SetNoDraw( !PRK_ShouldDraw() )
		end
	end

	self:NextThink( CurTime() + 1 )
	return true
end

function SWEP:PreDrawViewModel( vm, wep, ply )
	vm:SetMaterial( "engine/occlusionproxy" ) -- Hide that view model with hacky material
end

function SWEP:PrimaryAttack( right )
	if ( PRK_InEditor( self.Owner ) ) then return end
	if ( self.Owner:JustSpawned() ) then return end

	-- Communicate warning
	if ( SERVER ) then
		local ammo = self:GetFilledChamberCount()
		if ( ammo == 0 ) then
			self:SendNoAmmo()
		end
	end

	-- Make sure we can shoot first
	local cham = self.Owner:GetNWInt( "PRK_CurrentChamber" )
	if ( !PRK_BulletTypeInfo[self.ChamberBullets[cham]]:CanFire() ) then return end

	-- Shoot logic + take ammo
	local takeammo, spin, shootparticles, punch = PRK_BulletTypeInfo[self.ChamberBullets[cham]]:Fire( self )
	if ( SERVER ) then
		if ( spin ) then
			self.Owner:SetNWInt( "PRK_CurrentChamber", math.Wrap( self.Owner:GetNWInt( "PRK_CurrentChamber" ) - 1, 1, self.MaxClip ) )
			self:SpinSound()
		end

		-- Communicate with client
		self:SendFire( spin )
	end

	-- Don't update until client gets here
	if ( takeammo ) then
		self.ChamberBullets[cham] = PRK_BulletType.Empty
	end

	-- Play animation
	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	-- Play shoot effect
	if ( shootparticles ) then
		local vm = self.Owner:GetViewModel()
		local effectdata = EffectData()
			local pos = vm:GetPos() +
				self.Owner:GetForward() * 60 +
				self.Owner:GetRight() * 20 * self.RightHanded +
				self.Owner:GetVelocity() * 0.1
			effectdata:SetOrigin( pos )
			effectdata:SetNormal(
				self.Owner:GetForward() +
				self.Owner:GetUp()
			)
		util.Effect( "prk_hit", effectdata )
	end

	if ( punch ) then
		-- Punch FOV
		local vel = self.Owner:GetVelocity()
		local bac = -self.Owner:GetForward()
		local movingback = vel:Dot( bac ) > 0
		if ( !self.FOVBase ) then
			self.FOVBase = self.Owner:GetFOV()
		end
		local base = self.FOVBase
		local fov = base + self.DistFOVPunch
			-- Punch in reverse if running backwards (otherwise feels like the player is not moving)
			if ( movingback ) then
				fov = base - self.DistFOVPunch
			end
		self.Owner:SetFOV( fov, self.TimeFOVPunch )
		self.FOVPunch = CurTime() + self.TimeFOVPunch + self.TimeHoldFOVPunch

		-- Punch the player's view
		self.Owner:ViewPunch( Angle( -5, math.random( -1, 1 ), 0 ) )
	end

	self:SetNextPrimaryFire( CurTime() + self.TimeFire )
	self.NextReload = CurTime() + self.TimeReload
end

function SWEP:SecondaryAttack()
	
end

function SWEP:Reload( dir )
	if ( dir == nil ) then dir = 1 end
	if ( PRK_InEditor( self.Owner ) ) then return end

	if ( !self.NextReload or self.NextReload <= CurTime() ) then
		-- Always spin chambers, and do it before any loading
		self:SpinSound()
		if ( SERVER ) then
			self.Owner:SetNWInt( "PRK_CurrentChamber", math.Wrap( self.Owner:GetNWInt( "PRK_CurrentChamber" ) + dir, 1, self.MaxClip ) )
		end

		local ammo = self:GetFilledChamberCount()
		local extraammo = self.Owner:GetNWInt( "PRK_ExtraAmmo" )
		if ( ammo < self.MaxClip and extraammo > 0 and self.ChamberBullets[self.Owner:GetNWInt( "PRK_CurrentChamber" )] == PRK_BulletType.Empty ) then
			-- Reload and communicate
			if ( SERVER ) then
				self.Owner:SetNWInt( "PRK_ExtraAmmo", extraammo - 1 )
				local extraammo_add = self.Owner:GetNWInt( "PRK_ExtraAmmo_Add" )
				self.Owner:SetNWInt( "PRK_ExtraAmmo_Add", extraammo_add - 1 )

				self.ChamberBullets[self.Owner:GetNWInt( "PRK_CurrentChamber" )] = PRK_BulletType.Default
				-- self.ChamberBullets[self.Owner:GetNWInt( "PRK_CurrentChamber" )] = PRK_BulletType.Test2
			end

			-- Play sound
			PRK_EmitChainPitchedSound(
				self.Owner:Nick() .. "_PRK_Gun_Reload",
				self.Weapon,
				"buttons/lever7.wav",
				75,
				1,
				self.SoundPitchReloadBase,
				self.SoundPitchReloadIncrease,
				self.SoundPitchReloadSpeed,
				0.5,
				function()
					if ( self and self:IsValid() ) then
						-- End chain effect
						self.Owner:EmitSound( "buttons/blip1.wav", 75, 50, 0.15 )
						self.Owner:SetNWInt( "PRK_ExtraAmmo_Add", 0 )
					end
				end
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

		-- Send the reload message to client last
		if ( SERVER ) then
			self:SendReload( dir )
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

function SWEP:SetChambers( chambers )
	-- Change size and add any new empty chambers
	self.MaxClip = chambers
	for i = 1, self.MaxClip do
		if ( !self.ChamberBullets[i] ) then
			self.ChamberBullets[i] = PRK_BulletType.Empty
		end
	end
	self:SetNWInt( "PRK_CurrentChamber", 1 )

	-- Send to client
	self:SendNumChambers( chambers )
end

function SWEP:GetFilledChamberCount()
	local count = 0
		for k, cham in pairs( self.ChamberBullets ) do
			if ( cham != PRK_BulletType.Empty ) then
				count = count + 1
			end
		end
	return count
end

function SWEP:PlaySound( sound, soundlevel, pitch, volume )
	timer.Simple( 0.001, function()
		if ( self and self:IsValid() ) then
			self:EmitSound( sound, soundlevel, pitch, volume )
		end
	end )
end

function SWEP:SpinSound()
	timer.Simple( 0.01, function()
		if ( self and self:IsValid() ) then
			self:EmitSound( "prk_gun_spin" )
			timer.Simple( 0.2, function()
				if ( self and self:IsValid() ) then
					self:StopSound( "prk_gun_spin" )
				end
			end )
		end
	end )
end
