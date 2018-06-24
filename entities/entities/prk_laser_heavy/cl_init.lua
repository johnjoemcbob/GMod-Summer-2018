include( "shared.lua" )

function ENT:Initialize()
	-- Add visual bullet
	self.Bullet = ClientsideModel( "models/hunter/blocks/cube025x1x025.mdl" )
	-- self.Bullet:SetNoDraw( true )
	self.Bullet:SetMaterial( "models/shiny", true )
	self.Bullet:SetColor( Color( 255, 255, 255, 255 ) )
	self.Bullet:SetModelScale( 1, 0 )

	-- Set bullet scale
	local scale = Vector( 0.1, 1, 0.1 )

	local mat = Matrix()
		mat:Scale( scale )
	self.Bullet:EnableMatrix( "RenderMultiply", mat )
end

function ENT:Draw()
	if ( !self.Bullet ) then
		self:Initialize()
	end
	self.Bullet:SetPos( self:GetPos() )
	-- if ( self:GetVelocity() != Vector() ) then
		-- self.Bullet:SetAngles( self:GetVelocity():Angle() )
	-- else
		self.Bullet:SetAngles( self:GetAngles() + Angle( 0, 90, 0 ) )
	-- end
	-- self.Bullet:DrawModel()

	-- self:DrawModel()
end

function ENT:OnRemove()
	if ( self.Bullet and self.Bullet:IsValid() ) then
		self.Bullet:Remove()
	end
end
