include( "shared.lua" )

net.Receive( "PRK_EntZone", function( len, ply )
	local self = net.ReadEntity()
	local zone = net.ReadFloat()

	self.Zone = zone
end )

net.Receive( "PRK_EntScale", function( len, ply )
	local self = net.ReadEntity()
	local scale = net.ReadVector()
	local phys = net.ReadBool()

	local function try()
		if ( self and self:IsValid() ) then
			self.Scale = scale
			local mat = Matrix()
				mat:Scale( scale )
			self:EnableMatrix( "RenderMultiply", mat )

			if ( phys ) then
				self:PhysicsInit( SOLID_VPHYSICS )
				PRK_ResizePhysics( self, self.Scale )
			end
		else
			timer.Simple( 1, function() try() end )
		end
	end
	try()
end )

function ENT:AddModel( mdl, pos, ang, scale, mat, col )
	local model = ClientsideModel( mdl )
		model:SetPos( self:GetPos() + pos )
		model:SetAngles( ang )
		model:SetModelScale( scale )
		model:SetMaterial( mat )
		model:SetColor( col )
		model.Pos = pos
		model.Ang = ang
		-- model.RenderBoundsMin, model.RenderBoundsMax = model:GetRenderBounds()
	table.insert(
		self.Models,
		model
	)
	return model
end
