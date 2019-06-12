
SWEP.PrintName					= "Prickly Gun"

SWEP.Author						= ""
SWEP.Purpose					= ""

SWEP.Spawnable					= true
SWEP.UseHands					= true
SWEP.DrawAmmo					= false

SWEP.ViewModel					= "models/weapons/w_357.mdl"
SWEP.WorldMode					= "models/weapons/w_357.mdl"

SWEP.ViewModelFOV				= 32
SWEP.Slot						= 0
SWEP.SlotPos					= 5

SWEP.Primary.ClipSize			= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Automatic			= true
SWEP.Primary.Ammo				= "none"

SWEP.Secondary.ClipSize			= -1
SWEP.Secondary.DefaultClip		= -1
SWEP.Secondary.Automatic		= true
SWEP.Secondary.Ammo				= "none"

SWEP.RequireAmmo				= true
SWEP.MaxClip					= PRK_BaseClip
local dist = 3000
SWEP.MaxDistance				= dist
SWEP.MaxDistanceSqr				= dist * dist -- Store extra as sqr
SWEP.RightHanded				= 1
SWEP.TimeFire					= 0.2
SWEP.TimeReload					= 0.2
SWEP.TimeFOVPunch				= 0.1
SWEP.TimeBackFOVPunch			= 0.2
SWEP.TimeHoldFOVPunch			= 0.1
SWEP.DistFOVPunch				= 10
-- SWEP.LerpSpeedPunch				= 1
-- SWEP.LerpSpeed					= 40 --10
SWEP.SoundPitchFireBase			= 100
SWEP.SoundPitchFireIncrease		= -50 --  -3
SWEP.SoundPitchFireSpeed		= 0.2
SWEP.SoundPitchReloadBase		= 80
SWEP.SoundPitchReloadIncrease	= 10
SWEP.SoundPitchReloadSpeed		= 0.4

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
    util.AddNetworkString( "PRK_Gun_BulletUpdate" )
    util.AddNetworkString( "PRK_Gun_ChamberWarning" )

	function SWEP:SendFire( bullettype, spin )
		net.Start( "PRK_Gun_Fire" )
			net.WriteEntity( self )
			net.WriteTable( self.ChamberBullets )
			net.WriteString( bullettype )
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

	function SWEP:SendBulletUpdate()
        net.Start( "PRK_Gun_BulletUpdate" )
            net.WriteEntity( self )
			net.WriteTable( self.ChamberBullets )
        net.Send( self.Owner )
	end

	function SWEP:SendChamberWarning( chamber )
        net.Start( "PRK_Gun_ChamberWarning" )
            net.WriteEntity( self )
            net.WriteFloat( chamber )
        net.Send( self.Owner )
	end
end

function SWEP:Initialize()
	self:SetHoldType( "fist" )

	-- Initialise networked variables
	self.Owner:SetNWInt( "PRK_CurrentChamber", 1 )
	self.Owner:SetNWInt( "PRK_ExtraAmmo", 0 )

	-- Initialise chambers to filled with normal bullets on client and server
	if ( SERVER ) then
		self.ChamberBullets = {}
		local bultype = "Default"
			-- if ( self.Owner:GetNWInt( "PRK_Zone", 0 ) == 0 ) then
				-- bultype = "Lobby"
			-- end
		for i = 1, self.MaxClip do
			self.ChamberBullets[i] = bultype
		end
		-- Wait a bit and communicate to client once it probably exists
		timer.Simple( 0.1, function()
			if ( self and self:IsValid() ) then
				-- self:SendBulletUpdate()
				self:SendReload( 0 )
			end
		end )
	end
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

		-- Chamber warning effect
		local speed = 3
		if ( LocalPlayer().ChamberWarning ) then
			for chamber, warn in pairs( LocalPlayer().ChamberWarning ) do
				LocalPlayer().ChamberWarning[chamber] = Lerp( FrameTime() * speed, warn, 0 )
			end
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
	if ( self.NextEmptySpin and self.NextEmptySpin > CurTime() ) then return end

	-- Communicate warning
	if ( SERVER ) then
		local ammo = self:GetFilledChamberCount()
		if ( ammo == 0 ) then
			self:SendNoAmmo()
		end
	end

	-- Make sure we can shoot first
	local cham = self.Owner:GetNWInt( "PRK_CurrentChamber" )
	if ( !PRK_BulletTypeInfo[self.ChamberBullets[cham]]:CanFire( self ) ) then
		return
	end

	-- Shoot logic + take ammo
	local takeammo, spin, shootparticles, punch
	if ( SERVER ) then
		takeammo, spin, shootparticles, punch = PRK_BulletTypeInfo[self.ChamberBullets[cham]]:Fire( self )
		if ( spin ) then
			self.Owner:SetNWInt( "PRK_CurrentChamber", math.Wrap( self.Owner:GetNWInt( "PRK_CurrentChamber" ) - 1, 1, self.MaxClip ) )
			self:SpinSound()
		end

		-- Communicate with client
		self:SendFire( self.ChamberBullets[cham], spin )

		-- Don't take ammo until client gets here, so that client can have sound/particle effects play
		if ( takeammo ) then
			self.ChamberBullets[cham] = "Empty"
		end
		self:SendBulletUpdate()
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
	if ( PRK_InEditor( self.Owner ) ) then return end
	if ( self.Owner:JustSpawned() ) then return end

	-- Shoot coin
	if ( self.Owner:GetNWInt( "PRK_Money" ) > 0 ) then
		-- Play first impact effect at spawn point
		local tr = self.Owner:GetEyeTrace()
		local effectdata = EffectData()
			local pos = tr.HitPos
			effectdata:SetOrigin( pos )
			effectdata:SetNormal( tr.HitNormal )
		util.Effect( "prk_hit", effectdata )

		if ( SERVER ) then
			self.Owner:SetNWInt( "PRK_Money", self.Owner:GetNWInt( "PRK_Money" ) - 1 )
			-- self.Owner:SetNWInt( "PRK_Money_Add", self.Owner:GetNWInt( "PRK_Money_Add" ) - 1 )

			-- Play shoot sound
			PRK_ChainPitchedSounds[self.Owner:Nick() .. "_PRK_Coin_Pickup"] = nil
			local chain = PRK_EmitChainPitchedSound(
				self.Owner:Nick() .. "_PRK_Coin_Shoot",
				self.Owner,
				"garrysmod/balloon_pop_cute.wav",
				75,
				1,
				170,
				-10,
				0.5,
				1,
				function()
					if ( self and self:IsValid() and self.Owner and self.Owner:GetNWInt( "PRK_Money_Add" ) != 0 ) then
						self.Owner:EmitSound( "items/medshot4.wav", 75, 255 )
						self.Owner:SetNWInt( "PRK_Money_Add", 0 )
					end
				end,
				1
			)
			self.Owner:SetNWInt( "PRK_Money_Add", -chain )

			local coin = ents.Create( "prk_coin_heavy" )
			coin:Spawn()
			coin.Owner = self.Owner
			-- Appear at hit point and bounce back towards player
			local out = 10
			local pos = tr.HitPos + tr.HitNormal * out
				-- Clamp pos to max distance
				local dir = pos - self.Owner:EyePos()
				if ( dir:LengthSqr() > self.MaxDistanceSqr ) then
					pos = self.Owner:GetPos() + dir:GetNormalized() * self.MaxDistance
				end
			local mult = 200
			local dir = ( self.Owner:EyePos() + Vector( 0, 0, 100 ) - tr.HitPos ):GetNormalized() * mult * 3
			-- coin:Launch( pos, dir )
			coin:SetPos( pos )
			local phys = coin:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:AddVelocity( dir )
				phys:AddAngleVelocity( VectorRand() * 1000 )
			end
			coin:CollideWithEnt( tr.Entity )
			coin:SetZone( self.Owner:GetNWInt( "PRK_Zone", 0 ) )

			-- Communicate with client
			self:SendFire( "Gold", false )
		end

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

	self:SetNextSecondaryFire( CurTime() + self.TimeFire )
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
		if ( ammo < self.MaxClip and extraammo > 0 and self.ChamberBullets[self.Owner:GetNWInt( "PRK_CurrentChamber" )] == "Empty" ) then
			-- Reload and communicate
			if ( SERVER ) then
				self.Owner:SetNWInt( "PRK_ExtraAmmo", extraammo - 1 )
				local extraammo_add = self.Owner:GetNWInt( "PRK_ExtraAmmo_Add" )
				self.Owner:SetNWInt( "PRK_ExtraAmmo_Add", extraammo_add - 1 )

				self.ChamberBullets[self.Owner:GetNWInt( "PRK_CurrentChamber" )] = "Default"
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

function SWEP:LoadBullet( chamber, bultype )
	-- Flag to find first empty
	if ( chamber == 0 ) then
		chamber = 1 -- If none empty, default to overwrite first slot
		for k, cham in pairs( self.ChamberBullets ) do
			if ( cham == "Empty" ) then
				chamber = k
				break
			end
		end
	end

	self.ChamberBullets[chamber] = bultype
	PrintTable( self.ChamberBullets )
	self:SendBulletUpdate()
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
			self.ChamberBullets[i] = "Empty"
		end
	end
	self:SetNWInt( "PRK_CurrentChamber", 1 )

	-- Send to client
	self:SendNumChambers( chambers )
end

function SWEP:GetFilledChamberCount()
	local count = 0
		if ( self.ChamberBullets ) then
			for k, cham in pairs( self.ChamberBullets ) do
				if ( cham != "Empty" ) then
					count = count + 1
				end
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
