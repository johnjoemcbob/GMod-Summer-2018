include( "shared.lua" )

function ENT:Initialize()
	-- Add visual
	self.Visual = ClientsideModel( "models/props_junk/PopCan01a.mdl" )
	self.Visual:SetMaterial( "models/shiny", true )
	self.Visual:SetRenderMode( RENDERMODE_TRANSALPHA )
	self.Visual:SetColor( Color( 255, 250, 0, 255 ) )
	self.Visual:SetModelScale( self.Scale, 0 )

	-- Set Visual scale
	local scale = Vector( 2, 2, 0.4 )

	local mat = Matrix()
		mat:Scale( scale )
	self.Visual:EnableMatrix( "RenderMultiply", mat )
end

-- Also update pos/ang here in case Draw wouldn't be called (if the entity is already out of view)
function ENT:Think()
	if ( !self.Visual or !self.Visual:IsValid() ) then
		self:Initialize()
	end
	self.Visual:SetPos( self:GetPos() )
	self.Visual:SetAngles( self:GetAngles() + Angle( 0, 0, 0 ) )
end

function ENT:Draw()
	if ( !self.Visual or !self.Visual:IsValid() ) then
		self:Initialize()
	end
	self.Visual:SetPos( self:GetPos() + self:GetUp() * 3.5 )
	self.Visual:SetAngles( self:GetAngles() + Angle( 0, 0, 0 ) )
end

function ENT:OnRemove()
	if ( self.Visual and self.Visual:IsValid() ) then
		self.Visual:Remove()
	end
end
