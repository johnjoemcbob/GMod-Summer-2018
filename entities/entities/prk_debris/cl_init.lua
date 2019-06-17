include( "shared.lua" )

function ENT:Draw()
	if ( !self:ShouldDraw() ) then return end

	self:DrawModel()
end
