include( "shared.lua" )

local models = {
	"models/props_foliage/ferns01.mdl",
	"models/props_foliage/ferns02.mdl",
	"models/props_foliage/ferns03.mdl",
}

local colours = {
	-- Green
	Color( 12, 90, 4, 255 ),
	Color( 47, 90, 4, 255 ),
	Color( 65, 90, 4, 255 ),
}

function ENT:Initialize()
	self.Models = {}

	local up = 700
	local rand = 300
	local scale = 4
	local origin = Vector( 0, 0, up )
	local col = colours[math.random( 1, #colours )]
	local count = math.random( 1, 3 ) * 10
	for i = 1, count do
		local ent = self:AddModel(
			models[math.random( 1, #models )],
			origin + VectorRand() * rand,
			AngleRand(),
			1,
			PRK_Material_Base,
			col
		)
		-- Scale
		local sca = Vector( 1, 1, 1 ) * ( ( math.random( 0, 100 ) / 100 ) + scale )
		local mat = Matrix()
			mat:Scale( sca )
		ent.Scale = sca
		ent:EnableMatrix( "RenderMultiply", mat )
		ent:SetNoDraw( true )
		PRK_BasicDebugSphere( ent:GetPos() )
	end
	PRK_BasicDebugSphere( self:GetPos() )
end

function ENT:Draw()
	if ( !PlayerInZone( self, self.Zone ) ) then return end

	self:DrawModel()

	-- Details
	for k, v in pairs( self.Models ) do
		local col = v:GetColor()
		render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
			v:DrawModel()
		render.SetColorModulation( 1, 1, 1 )
	end
end

function ENT:OnRemove()
	for k, v in pairs( self.Models ) do
		v:Remove()
	end
end
