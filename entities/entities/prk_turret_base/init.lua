AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

-- Variables
ENT.TimeAutoRemoveProj		= 2
ENT.TimeFire				= 3 --1.5
ENT.SpeedRotate				= 13--15 --10
ENT.SpeedDeploy				= 3--15 --10
ENT.SpeedFire				= 250 --300--000
ENT.LookAtApprox			= 0.1 --0.05
ENT.Deployed				= false

function ENT:Initialize()
	-- Visuals
	self:SetModel( "models/hunter/blocks/cube1x1x05.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 181, 181, 200, 255 ) )

	-- Physics
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_NONE )
	self:PhysicsInit( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Parts
	local size = PRK_Plate_Size
	local hsize = size / 2
	local oldang = self:GetAngles()
	self:SetAngles( Angle() )
	self.Ents = {}
		self.Weakpoint = self:CreateEnt(
			"prk_enemy_weakpoint",
			"",
			self:GetPos() + Vector( 50, 0, 0 ),
			Angle()
		)
		self.Weakpoint:Attach( self )
		self.Rotator = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube025x025x025.mdl",
			self:GetPos() + Vector( 0, 0, 0 ),
			Angle( 0, 0, 0 )
		)
			self.Rotator:SetNoDraw( true )
		self.Neck = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube025x150x025.mdl",
			self:GetPos() + Vector( hsize * 0.25, hsize * 0.25, hsize ),
			Angle( 0, 0, 90 ),
			"models/shiny"
		)
		self.Neck:SetParent( self.Rotator )
		self.Head = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube1x1x025.mdl",
			self:GetPos() + Vector( 0, 0, size ),
			Angle( 0, 0, 0 ),
			"phoenix_storms/metalfloor_2-3"
		)
		self.Head:SetParent( self.Neck )
		self.Barrel = self:CreateEnt(
			"prop_physics",
			"models/hunter/blocks/cube025x025x025.mdl",
			self:GetPos() + Vector( hsize, 0, size ),
			Angle( 45, 90, 0 ),
			"phoenix_storms/metalset_1-2"
		)
		self.Barrel:SetParent( self.Head )
	self:SetAngles( oldang )
	-- Unparent neck
	self.Rotator:SetParent( nil )
	self.Weakpoint:SetParent( nil )
	-- Holster before first deploy
	self.Rotator.TargetPos = self.Rotator:GetPos()
	self.Rotator:SetPos( self.Rotator:GetPos() + Vector( 0, 0, -30 ) )

	-- Sounds
	self.Sound_Deploy = CreateSound( self, "vehicles/tank_turret_start1.wav" )
	self.Sound_Rotate = CreateSound( self, "vehicles/tank_turret_loop1.wav" )
		self.Sound_Rotate:SetSoundLevel( 85 )
	self.Sound_StopRotate = "vehicles/tank_turret_stop1.wav"
	self.Sound_Fire = "weapons/physcannon/superphys_launch1.wav"

	self:ExtraInitialize()
end

function ENT:ExtraInitialize()
end

function ENT:Think()
	-- Find target
	-- print( self.Target )
	self:SetNWEntity( "Target", self.Target )
	if ( !self.Target or !self.Target:IsValid() ) then
		self.Target = nil

		local possible = player.GetAll()
			for k, v in pairs( ents.FindByClass( "npc_*" ) ) do
				table.insert( possible, v )
			end
		while ( !self.Target and #possible > 0 ) do
			self.Target = possible[math.random( 1, #possible )]
			if ( self.Target and self.Target:IsValid() ) then
				-- Check that it can see this target
				if ( !self:CanSee( self.Target ) ) then
					table.RemoveByValue( possible, self.Target )
					self.Target = nil
				end
			else
				table.RemoveByValue( possible, self.Target )
			end
		end

		-- Wait for target
		if ( !self.Target or !self.Target:IsValid() ) then
			return
		end
	end

	-- If first then deploy upwards
	local speed = FrameTime() * self.SpeedDeploy
	if ( !self.Deployed ) then
		self.Rotator:SetPos( LerpVector( speed, self.Rotator:GetPos(), self.Rotator.TargetPos ) )
		local dist = self.Rotator:GetPos():Distance( self.Rotator.TargetPos )
		if ( dist < 1 ) then
			self.Deployed = true
		end

		self:NextThink( CurTime() )
		return true
	end

	-- Rotate towards target
	local speed = FrameTime() * self.SpeedRotate
	local targetang = self:GetLookAt( self.Target )
	self.Rotator:SetAngles( LerpAngle( speed, self.Rotator:GetAngles(), targetang ) )

	-- Fire if facing
	local dif = self.Rotator:GetAngles():Forward():Distance( targetang:Forward() )
	-- local dif = 100000
	-- print( dif )
	if ( self.Barrel and self.Barrel:IsValid() and dif < self.LookAtApprox ) then
		self:DoFire()
	else
		if ( !self.Sound_Rotate:IsPlaying() ) then
			self.Sound_Rotate:Play()
		end
		self.Sound_Rotate:ChangePitch( 100 + 20 * dif, 0 )
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:DoFire()
	print( "Bang!" )
end

function ENT:OnRemove()
	-- Stop looping sound
	self.Sound_Rotate:Stop()

	-- Remove visuals
	for k, v in pairs( self.Ents ) do
		if ( v and v:IsValid() ) then
			v:Remove()
		end
	end

	if ( !self.Cleanup ) then
		-- Spawn money
		local coins = 4
		GAMEMODE:SpawnCoins( self, self:GetPos(), coins )
	end

	self:ExtraOnRemove()
end

function ENT:ExtraOnRemove()

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

function ENT:LookAt( ent )
	local dir = ( ent:GetPos() - self:GetPos() ):GetNormalized()
		self.Rotator:SetAngles( Angle( 0, dir:Angle().y, 0 ) )
	return dir
end

function ENT:GetLookAt( ent )
	local dir = ( ent:GetPos() - self:GetPos() ):GetNormalized()
	return Angle( 0, dir:Angle().y, 0 )
end

function ENT:CanSee( ent )
	local oldang = self.Rotator:GetAngles()
		local dir = self:LookAt( ent )
		local trdata = {
			start = self.Barrel:GetPos() + dir * 50,
			endpos = ent:GetPos() + Vector( 0, 0, 50 ) + dir * 50,
		}
		local tr = util.TraceLine( trdata )
	self.Rotator:SetAngles( oldang )

	return ( tr.Entity == ent )
end
