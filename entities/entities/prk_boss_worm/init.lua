AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

local State
State = {
	Intro = {
		Start = function( self, ent )
			print( "INTRO" )
			timer.Simple( 1, function() ent:StartState( State.FindTarget ) end )
		end,
		Think = function( self, ent )
			
		end,
		End = function( self, ent )
			
		end,
	},
	Burrow = {
		Start = function( self, ent )
			print( "Burrow" )
		end,
		Think = function( self, ent )
			-- Straighten body
			

			-- Retract into surface
			

		end,
		End = function( self, ent )
			
		end,
	},
	FindTarget = {
		Start = function( self, ent )
			print( "FindTarget" )
			-- Closest?
			-- Weakest?
			-- Strongest?
			-- Random?
			for k, v in pairs( player.GetAll() ) do
				ent.Target = v
			end
			-- Choose a new attack pattern
			-- local attacks = math.random( 1, 3 )
			-- if ( attacks == 1 ) then
				-- ent:StartState( State.PierceGround )
			-- elseif ( attacks == 2 ) then
				ent:StartState( State.MouthCannon )
			-- else
				-- ent:StartState( State.MinionSpawn )
			-- end
		end,
		Think = function( self, ent )
			
		end,
		End = function( self, ent )
			
		end,
	},
	PierceGround = {
		Start = function( self, ent )
			print( "PierceGround" )

			-- Show attack position
			

		end,
		Think = function( self, ent )
			
		end,
		End = function( self, ent )
			
		end,
	},
	MouthCannon = {
		Start = function( self, ent )
			print( "MouthCannon" )
		end,
		Think = function( self, ent )
			ent:LookAt( ent.Target )
		end,
		End = function( self, ent )
			
		end,
	},
	MinionSpawn = {
		Start = function( self, ent )
			print( "MinionSpawn" )
		end,
		Think = function( self, ent )
			
		end,
		End = function( self, ent )
			
		end,
	},
	Outro_Die = {
		Start = function( self, ent )
			print( "Outro_Die" )
		end,
		Think = function( self, ent )
			
		end,
		End = function( self, ent )
			
		end,
	},
	Outro_Win = {
		Start = function( self, ent )
			print( "Outro_Win" )
		end,
		Think = function( self, ent )
			
		end,
		End = function( self, ent )
			
		end,
	},
}

function ENT:Initialize()
	self:SetModel( "models/props_phx/construct/metal_plate_pipe.mdl" )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()

	-- Freeze initial body
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Build body
	local off = Vector( 0, 0, 60 )
	local segs = 20
	local lastseg = self.Entity
	self.Segments = { lastseg }
	for i = 1, segs - 1 do -- segs - 1 for initial ent model
		local seg = PRK_CreateProp(
			"models/props_phx/construct/metal_plate_pipe.mdl",
			lastseg:GetPos() + off,
			lastseg:GetAngles()
		)
			-- constraint.Ballsocket(
				-- lastseg,
				-- seg,
				-- 0,
				-- 0,
				-- Vector( 0, 0, -10 ),
				-- 0,
				-- 0,
				-- 0
			-- )--number xmin, number ymin, number zmin, number xmax, number ymax, number zmax, number xfric, number yfric, number zfric, number onlyrotation, number nocollide )
		table.insert( self.Segments, seg )
		lastseg = seg
	end
	-- Add head
	local seg = PRK_CreateProp(
		"models/props_phx/construct/windows/window_dome360.mdl",
		lastseg:GetPos() + off,
		lastseg:GetAngles()
	)
	table.insert( self.Segments, seg )

	-- Initialise
	self:StartState( State.Intro )
end

function ENT:OnTakeDamage( dmg )
	
end

function ENT:PhysicsCollide( colData, collider )
	self.has_collided = true
end

function ENT:Think()
	self:ThinkState()
	self:ThinkBody()

	self:NextThink( CurTime() )
	return true
end

function ENT:ThinkBody()
	local speed = 5
	local change = FrameTime() * speed
	for k, v in pairs( self.Segments ) do
		if ( v.TargetPos ) then
			v:SetPos( LerpVector( change, v:GetPos(), v.TargetPos ) )
			v:SetAngles( LerpAngle( change, v:GetAngles(), v.TargetAngles ) )
		end
	end

	-- Root should have the same yaw as head
	local segs = #self.Segments
	local head = self.Segments[segs]
	self:SetAngles( Angle( self:GetAngles().x, head:GetAngles().y, self:GetAngles().z ) )
end

function ENT:OnRemove()
	for k, v in pairs( self.Segments ) do
		v:Remove()
	end
end

function ENT:LookAt( target )
	-- Use head segment to look at target player
	local segs = #self.Segments
	local head = self.Segments[segs]
	local off = Angle( -90, 0, 0 )
	local dir = ( target:GetPos() - self:GetPos() ):GetNormalized()
	local dist = math.min( target:GetPos():Distance( self:GetPos() ) - 50, 250 )
	head.TargetAngles = dir:Angle() + off
	head.TargetPos =
		self:GetPos() +
		Vector( 0, 0, dist ) +
		dir * dist +
		head.TargetAngles:Right() * math.sin( CurTime() ) * 50 +
		head.TargetAngles:Up() * math.cos( CurTime() / 10 ) * 50
	dir = ( target:GetPos() - head.TargetPos ):GetNormalized()
	head.TargetAngles = dir:Angle() + off

	-- Neck segment should be positioned above head for interesting movement
	--
	-- TODO: This should be the opposite way around.
	--		For each element of poses, make a neck joint
	--
	local neckfactor = 0.3
	local poses = {
		[0.3] = Vector( -10, 0, 650 - dist * 2 ),
		[0.6] = Vector( -5, 0, 750 - dist * 2 ),
		-- [0.9] = Vector( 0, 0, 850 - dist * 2 ),
		-- [0.4] = Vector( 100, math.sin( -5, 5 ), 720 - dist * 2 ),
		-- [0.6] = Vector( 0, 0, 750 - dist * 2 ),
		-- [0.8] = Vector( 0, 0, 750 - dist * 2 ),
	}
	local neckids = {}
		local curneckfactor = neckfactor
		while ( curneckfactor < 1 ) do
			local neckid = math.ceil( segs * curneckfactor )
			local neck = self.Segments[neckid]

			local posid = math.floor( curneckfactor * 10 ) / 10
			local pos = Vector()
			if ( poses[posid] ) then
				table.insert( neckids, neckid )
				neck.TargetAngles = dir:Angle() + off
				pos = 
					Vector( 0, 0, poses[posid].z ) +
					neck.TargetAngles:Forward() * poses[posid].x +
					neck.TargetAngles:Right() * poses[posid].y
				neck.TargetPos =
					self:GetPos() +
					pos +
					dir * -dist +
					neck.TargetAngles:Right() * math.sin( -CurTime() / 10 + curneckfactor ) * 100 +
					neck.TargetAngles:Up() * math.cos( -CurTime() + curneckfactor ) * 100
			end
			curneckfactor = curneckfactor + neckfactor
		end
	-- End neck setup

	-- Each segment affected by root/head by distance along chain from it
	local neckid = neckids[1]
	local pos_org = self:GetPos()
	local rot_org = self:GetAngles()
	local pos_tar = self.Segments[neckid].TargetPos
	local rot_tar = self.Segments[neckid].TargetAngles
	local segs_off = 0
	local segs_part = neckid
	for k, v in pairs( self.Segments ) do
		-- print( k )
		if ( k != 1 and k != neckid and v != head ) then
			-- print( k .. " part" )
			local fac = ( k - segs_off ) / segs_part
			local pos = pos_org + ( pos_tar - pos_org ) * fac
			-- v:SetPos( pos )
			v.TargetPos = pos

			local rot = LerpAngle( fac, rot_org - rot_tar / 10, rot_tar )
			-- v:SetAngles( rot )
			v.TargetAngles = rot
			if ( k > 17 ) then
				-- PRK_BasicDebugSphere( pos_org )
				-- PRK_BasicDebugSphere( pos_tar )
				-- print( fac )
				-- print( pos )
				-- print( rot )
			end
		elseif ( k == neckid and v != head ) then
			-- print( k .. " neck" )
			segs_off = neckid
			segs_part = segs - neckid

			pos_org = self.Segments[neckid].TargetPos
			rot_org = self.Segments[neckid].TargetAngles
			neckid = neckids[2]
			-- In case last neckid would be head
			if ( !neckid ) then
				neckid = #self.Segments
			end
			-- print( neckid )
			pos_tar = self.Segments[neckid].TargetPos
			rot_tar = self.Segments[neckid].TargetAngles
			-- print( pos_org )
			-- print( pos_tar )

			table.remove( neckids, 1 )
		end
	end
end

function ENT:StartState( state )
	if ( self.State ) then
		self:EndState()
	end
	self.State = state
	self.State:Start( self )
end

function ENT:ThinkState()
	if ( self.State ) then
		self.State:Think( self )
	end
end

function ENT:EndState()
	self.State:End( self )
	self.State = nil
end
