include( "shared.lua" )

local models = {
	{
		"models/props/de_inferno/bushgreensmall.mdl",
		Vector( 0, 0, 0 ),
	},
	{
		"models/props/cs_militia/fern01.mdl",
		Vector( 0, 0, 25 ),
	},
	{
		"models/props/pi_fern.mdl",
		Vector( 0, 0, 0 ),
	}
}

local colours = {
	Color( 65, 4, 90, 255 ),
	Color( 47, 4, 90, 255 ),
	Color( 12, 4, 90, 255 ),
}

function ENT:Initialize()
	local min = self:OBBMins()
	local max = self:OBBMaxs()
	self.Models = {}
	for i = 1, 2 do
		local rnd = models[math.random( 1, #models )]
		local mdl = rnd[1]
		local pos = Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), math.random( min.z, max.z ) ) + rnd[2]
		local ang = Angle( math.random( -10, 10 ), math.random( 0, 360 ), math.random( -10, 10 ) )
		local mat = "models/debug/debugwhite"
		local col = colours[math.random( 1, #colours )]
		self:AddModel( mdl, pos, ang, 1, mat, col )
	end
end

function ENT:Draw()
	self:DrawModel()
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
