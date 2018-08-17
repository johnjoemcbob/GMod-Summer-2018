include( "shared.lua" )

function ENT:Draw()
	if ( self:GetItem() ) then
		PRK_Items[self:GetItem()]:Draw( self )
	end
end

function ENT:OnRemove()
	if ( self.Visuals ) then
		for k, vis in pairs( self.Visuals ) do
			if ( vis and vis:IsValid() ) then
				vis:Remove()
			end
		end
	end
end
