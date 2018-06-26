include( "shared.lua" )

local models = {
	-- CSS
	{
		"models/props/de_inferno/bushgreensmall.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1, 1, 1 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	},
	{
		"models/props/cs_militia/fern01.mdl",
		Vector( 0, 0, 15 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	},
	{
		"models/props/pi_fern.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	},
	{
		"models/props/de_inferno/cactus.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 0.2, 0.2, 1 ),
	},
	{
		"models/props/de_inferno/cactus2.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 0.2, 0.2, 1 ),
	},
	-- HL2
	-- {
		-- "models/Gibs/wood_gib01c.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 90, 0, 0 ),
		-- Vector( 2, 1, 1 ),
	-- },
	-- {
		-- "models/Gibs/wood_gib01c.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 90, 0, 0 ),
		-- Vector( 3, 1, 1 ),
	-- },
	-- {
		-- "models/Gibs/wood_gib01c.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 90, 0, 0 ),
		-- Vector( 4, 1, 1 ),
	-- },
	-- {
		-- "models/props_c17/oildrumchunk01b.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 0.5, 0.1, 2 ),
	-- },
	-- {
		-- "models/props_foliage/bramble001a.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	-- },
	-- {
		-- "models/gibs/scanner_gib02.mdl",
		-- Vector( 0, 0, 5 ),
		-- Angle( 90, 90, 0 ),
		-- Vector( 2, 2, 2 ),
	-- },
	-- {
		-- "models/props_junk/garbage128_composite001b.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 1, 1, 1 ),
	-- },
}

local material_grass = Material( "prk_grass.png", "noclamp smooth" )

local colours = {
	Color( 65, 4, 90, 255 ),
	Color( 47, 4, 90, 255 ),
	Color( 12, 4, 90, 255 ),
}

local reload = true
function ENT:Think()
	-- Autoreload helper
	if ( reload ) then
		self:OnRemove()
		self:Initialize()
		reload = false
	end
end

function ENT:Initialize()
	local min = self:OBBMins()
	local max = self:OBBMaxs()
	self.Models = {}
	local amount = math.floor( math.random( 10, 100 ) / 10 )
	for i = 1, amount do
		local rnd = models[math.random( 1, #models )]
		local mdl = rnd[1]
		local pos = Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), math.random( min.z, max.z ) ) + rnd[2]
		local ang = rnd[3] + Angle( math.random( -10, 10 ), math.random( 0, 360 ), math.random( -10, 10 ) )
		local mat = "models/debug/debugwhite"
		local col = colours[math.random( 1, #colours )]

		local ent = self:AddModel( mdl, pos, ang, 1, mat, col )
		-- Scale
		local sca = rnd[4]
		local mat = Matrix()
			mat:Scale( sca )
		ent:EnableMatrix( "RenderMultiply", mat )
	end

	local grasses = 150
	self.Grasses = {}
	for i = 1, grasses do
		table.insert( self.Grasses,	{
			self:GetPos() + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), 0 ),
			Angle( 0, math.random( 0, 360 ), 0 ):Forward(),
			math.random( 10, 50 ) / 10
		} )
	end
end

function ENT:Draw()
	self:DrawModel()
end

hook.Add( "PreDrawTranslucentRenderables", "PRK_PreDrawTranslucentRenderables_Grass", function()
	for _, self in pairs( ents.FindByClass( "prk_floor" ) ) do
		for k, grass in pairs( self.Grasses ) do
			render.SetMaterial( material_grass )
			local size = 16
			render.DrawQuadEasy( grass[1] + Vector( 0, 0, size / 2 ), grass[2], size, size + grass[3], Color( 20, 20, 20, 255 ), 180 )
		end
	end
end )

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
