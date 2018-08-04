AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

util.AddNetworkString( "PRK_Gateway_EnterExit" )

-- Send to all clients for showing player body in the stream
function ENT:SendEnterExit( ply, enter )
	net.Start( "PRK_Gateway_EnterExit" )
		net.WriteEntity( self )
		net.WriteEntity( ply )
		net.WriteBool( enter )
		net.WriteVector( self.Destination )
	net.Broadcast()
end

function ENT:Initialize()
	self:SetModel( "models/props_c17/fence01a.mdl" )
	self:SetNoDraw( true )

	self:SetSolid( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:PhysicsInit( SOLID_VPHYSICS )
	-- Position correctly
	-- To wall
	local pos = self:GetPos()
	local tr = util.TraceLine( {
		start = pos,
		endpos = pos - self:GetForward() * 10000,
		filter = self,
	} )
	self:SetPos( tr.HitPos + tr.HitNormal * 0.04 )
	self:SetAngles( tr.HitNormal:Angle() )

	-- Freeze initial body
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	self.Destination = Vector( 0, 0, -12200 )
	self.DestinationZone = 0
end

function ENT:Think()
	for k, ply in pairs( player.GetAll() ) do
		if ( ply.PRK_Gateway == self ) then
			ply:SetPos( ply:GetPos() + Vector( 1, 0, 0 ) * 1.5 )
			if ( ply.PRK_GatewayTime + PRK_Gateway_TravelTime <= CurTime() ) then
				self:Exit( ply )
			end
		elseif ( ply:Alive() ) then
			local dist = self:GetPos():Distance( ply:GetPos() )
			if ( dist <= PRK_Gateway_EnterRange ) then
				self:Enter( ply )
			elseif ( dist <= PRK_Gateway_PullRange ) then
				local dir = ( self:GetPos() - ply:GetPos() ):GetNormal()
				local pulldist = 1 - ( dist / PRK_Gateway_PullRange )
				ply:SetVelocity( dir * PRK_Gateway_PullForce * pulldist )
			end
		end
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:OnRemove()
	
end

function ENT:SetDestination( pos, zone )
	self.Destination = pos
	self.DestinationZone = zone
end

function ENT:Enter( ply )
	-- Move the player elsewhere
	ply:SetMoveType( MOVETYPE_NOCLIP )
	ply:SetPos( PRK_Position_Nowhere )
	GAMEMODE:MoveToZone( ply, -100 )
	ply:Freeze( true )

	-- Request client effects
	self:SendEnterExit( ply, true )

	-- Set timer for reaching destination
	ply.PRK_Gateway = self
	ply.PRK_GatewayTime = CurTime()
end

function ENT:Exit( ply )
	-- Move the player to destination
	ply:SetPos( self.Destination + Vector( 0, 0, 200 ) )
	ply:SetMoveType( MOVETYPE_WALK )
	GAMEMODE:MoveToZone( ply, self.DestinationZone )
	ply:Freeze( false )

	-- Request client effects
	self:SendEnterExit( ply, false )

	-- Flag exit
	ply.PRK_Gateway = nil
	ply.PRK_GatewayTime = nil
end
