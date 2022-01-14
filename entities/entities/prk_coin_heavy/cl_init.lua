include( "shared.lua" )

function ENT:Initialize()
	-- Add visual
	self.Visual = ClientsideModel( "models/props_junk/PopCan01a.mdl" )
	self.Visual:SetMaterial( "models/shiny", true )
	self.Visual:SetRenderMode( RENDERMODE_TRANSALPHA )
	self.Visual:SetColor( Color( 255, 250, 0, 255 ) )
	self.Visual:SetModelScale( self.Scale, 0 )
	self.Visual:SetNoDraw( true )

	-- Set Visual scale
	local scale = Vector( 2, 2, 0.4 )

	local mat = Matrix()
		mat:Scale( scale )
	self.Visual:EnableMatrix( "RenderMultiply", mat )
end

function ENT:Draw()
	if ( !self:ShouldDraw() ) then return end

	if ( !self.Visual or !self.Visual:IsValid() ) then
		self:Initialize()
	end
	self.Visual:SetPos( self:GetPos() + self:GetUp() * 3.5 )
	self.Visual:SetAngles( self:GetAngles() + Angle( 0, 0, 0 ) )
	render.SetColorModulation( 1, 1, 0 )
		self.Visual:DrawModel()
	render.SetColorModulation( 0, 0, 0 )
end

function ENT:OnRemove()
	if ( self.Visual and self.Visual:IsValid() ) then
		self.Visual:Remove()
	end
end
