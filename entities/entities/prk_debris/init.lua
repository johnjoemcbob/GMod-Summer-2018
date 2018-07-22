AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

function ENT:Initialize()
	-- Visuals
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 255, 200, 20, 255 ) )

	-- Physics
	self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()

	-- Variables
	self.WaitDestroying = false
	self.Destroying = false
	self.LifeTime = 2
end

function ENT:Think()
	local movingdown = math.abs( self:GetVelocity().z ) < 1
	if ( movingdown ) then
		if ( !self.WaitDestroying ) then
			self.WaitDestroying = CurTime() + 1
		elseif ( self.WaitDestroying > CurTime() ) then
			-- Wait
		elseif ( !self.Destroying ) then
			self:StartDestroy()
		else
			local progress = ( CurTime() - self.Destroying ) / self.LifeTime

			-- Fade out
			local col = self:GetColor()
				col.r = Lerp( progress, self.StartColour.r, 0 )
				col.g = Lerp( progress, self.StartColour.g, 0 )
				col.b = Lerp( progress, self.StartColour.b, 0 )
			self:SetColor( col )

			-- Move through floor
			local pos = LerpVector( progress, self.StartPos, self.StartPos + Vector( 0, 0, -0.3 * self.StartSize ) )
			self:SetPos( pos )
		end
	end

	self:NextThink( CurTime() )
	return true
end

function ENT:StartDestroy()
	self.Destroying = CurTime()

	-- Store start pos for lerping position down into ground
	self.StartPos = self:GetPos()
	self.StartSize = self:OBBMaxs().x + self:OBBMaxs().y + self:OBBMaxs().z
	self.StartColour = self:GetColor()

	-- Stop any movement now
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Scale down
	self:SetModelScale( 0, self.LifeTime )

	-- Setup for destruction
	timer.Simple( self.LifeTime, function()
		if ( self and self:IsValid() ) then
			self:Remove()
		end
	end )
end
