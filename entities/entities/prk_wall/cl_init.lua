include( "shared.lua" )

local reload = true
function ENT:Think()
	-- Autoreload helper
	if ( reload ) then
		self:Initialize()
		reload = false
	end
end

function ENT:Initialize()
	self.Models = {}
	local ent = self:AddModel(
		"models/hunter/plates/plate1x1.mdl",
		Vector(),
		Angle(),
		1,
		"prk_gradient",
		Color( 255, 255, 255, 255 )
	)
		local size = 47.45
		local collision = self:OBBMaxs() - self:OBBMins()
		local scale = Vector( collision.x / size, collision.y / size, 1 )

		local mat = Matrix()
			mat:Scale( scale )
	ent:EnableMatrix( "RenderMultiply", mat )
	ent:SetRenderBounds( self:OBBMins(), self:OBBMaxs() )
end

function ENT:Think()
	-- Fail safe, can be removed if client graphic settings are changed
	if ( self.Models[1] and self.Models[1]:IsValid() ) then
		self.Models[1]:SetPos( self:GetPos() )
		self.Models[1]:SetAngles( self:GetAngles() )
	else
		self:Initialize()
	end
end

function ENT:Draw()
	-- self:DrawModel()
end

function ENT:OnRemove()
	for k, v in pairs( self.Models ) do
		v:Remove()
	end
end

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
