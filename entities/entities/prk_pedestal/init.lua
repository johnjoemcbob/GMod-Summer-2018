AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

function ENT:Initialize()
	self.Scale = Vector( 0.75, 3, 3 )

	-- Visuals
	self:SetModel( "models/mechanics/solid_steel/type_b_2_4.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 171, 171, 171, 255 ) )
	timer.Simple( 0.1, function() self:SendScale( self.Scale, true ) end )

	-- Physics
	self:PhysicsInit( SOLID_VPHYSICS )
	PRK_ResizePhysics( self, self.Scale )

	-- Rotate and position correctly with new scale
	local baseheight = 50
	self:SetPos( self:GetPos() + Vector( 0, 0, 300 ) )
	timer.Simple(
		0.1,
		function()
			-- Rotate
			self:SetAngles( Angle( 90, 0, 0 ) )

			-- To ground
			local pos = self:GetPos() + self:GetForward() * PRK_Plate_Size
			local tr = util.TraceLine( {
				start = pos,
				endpos = pos - Vector( 0, 0, 10000 ),
			} )
			self:SetPos( tr.HitPos + Vector( 0, 0, baseheight / 2 * self.Scale.x ) )

			-- Spawn item atop it
			local spawnpos = self:GetPos() + Vector( 0, 0, baseheight / 2 * self.Scale.x )
			local ent = PRK_SpawnItem( nil, spawnpos )
			ent:SetZone( self.Zone )
		end
	)
end
