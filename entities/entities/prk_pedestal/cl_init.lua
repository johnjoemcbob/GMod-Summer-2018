include( "shared.lua" )

function ENT:Initialize()
	
end

function ENT:Draw()
	if ( !self:ShouldDraw() ) then return end

	self:DrawModel()
end
