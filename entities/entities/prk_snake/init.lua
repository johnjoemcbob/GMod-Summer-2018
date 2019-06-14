AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

-- Variables
ENT.BetweenAttack	= 1
ENT.Range			= 50
ENT.Scale			= 6
ENT.Damage			= 1

function ENT:Initialize()
	-- Visuals
	self:SetModel( "models/Gibs/HGIBS_spine.mdl" )
	self:SetMaterial( "models/debug/debugwhite", true )
	self:SetColor( Color( 181, 181, 200, 255 ) )
	timer.Simple( 0.1, function() self:SendScale( self.Scale, true ) end )

	-- Physics
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	PRK_ResizePhysics( self, self.Scale )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end
	self:SetAngles( Angle( 90, 0, 0 ) )
	self:SetPos( self:GetPos() + Vector( 0, 0, 10 ) )

	-- Sounds
	-- self.Sound_Deploy = CreateSound( self, "vehicles/tank_turret_start1.wav" )
	-- self.Sound_Rotate = CreateSound( self, "vehicles/tank_turret_loop1.wav" )
		-- self.Sound_Rotate:SetSoundLevel( 85 )
	-- self.Sound_StopRotate = "vehicles/tank_turret_stop1.wav"
	-- self.Sound_Fire = "weapons/physcannon/superphys_launch1.wav"

	-- Spawn a plant here
	timer.Simple( 0.1, function()
		table.insert( PRK_Floor_Plants[self.Zone], PRK_GetPlantTable( 2, self:GetPos() ) )
	end )

	-- Variables
	self.NextAttack = 0
end

function ENT:Think()
	if ( !self.NextAttack or self.NextAttack <= CurTime() ) then
		for k, ply in pairs( ents.FindInSphere( self:GetPos(), self.Range ) ) do
			if ( ply:IsPlayer() ) then
				ply:TakeDamage( self.Damage, self, self )
				self.NextAttack = CurTime() + self.BetweenAttack
				break
			end
		end
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:OnTakeDamage( dmg )
	-- Destroy this
	self:Remove()
end

function ENT:OnRemove()
	-- Stop looping sound
	-- self.Sound_Rotate:Stop()

	if ( !self.Cleanup ) then
		-- Spawn money
		local coins = 4
		GAMEMODE:SpawnCoins( self, self:GetPos(), coins )
	end
end

function ENT:CreateEnt( class, mod, pos, ang, mat, col, mov )
	local ent = PRK_CreateEnt( class, mod, pos, ang, mov )
		ent:SetParent( self )
		if ( mat ) then
			ent:SetMaterial( mat )
		end
		if ( col ) then
			ent:SetColor( col )
		end
		table.insert( self.Ents, ent )
	return ent
end

-- function ENT:CanSee( ent )
	-- local dir = ( ent:GetPos() - self:GetPos() ):GetNormalized()
	-- local trdata = {
		-- start = self:GetPos() + dir * 50,
		-- endpos = ent:GetPos() + Vector( 0, 0, 50 ) + dir * 50,
	-- }
	-- local tr = util.TraceLine( trdata )

	-- return ( tr.Entity == ent )
-- end
