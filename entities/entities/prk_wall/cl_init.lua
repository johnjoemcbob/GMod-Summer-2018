include( "shared.lua" )

local cols = {
	Color( 80, 4, 90, 255 ),
	Color( 65, 4, 90, 255 ),
	Color( 47, 4, 90, 255 ),
	Color( 12, 4, 90, 255 ),
	Color( 4, 12, 90, 255 ),
	Color( 4, 47, 90, 255 ),
}

local models = {
	{
		"models/props_junk/vent001.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 90 ),
		Vector( 2, 1, 0.5 ),
		{
			Color( 255, 255, 255, 255 ),
		},
		0.1,
	},
	-- {
		-- "models/props_foliage/fern01.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 90 ),
		-- Vector( 1.7, 1.7, 1.7 ),
		-- cols,
		-- 0.9,
	-- },
	{
		"models/props_foliage/ferns01.mdl",
		Vector( 0, 0, 0 ),
		Angle( -90, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
		cols,
		0.9,
	},
	-- { -- Shows through ceiling (because no ceiling now)
		-- "models/props_foliage/tree_poplar_01.mdl",
		-- Vector( 0, -8, -25 ),
		-- Angle( 0, 0, -90 ),
		-- Vector( 1, 1.5, 2 ),
		-- cols,
		-- 0,
	-- },
	-- { -- Ep2
		-- "models/props_foliage/driftwood_03a.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 1, 1, 1 ),
		-- cols,
		-- 1,
	-- },
}

local wallmod = "models/hunter/blocks/cube1x1x1.mdl"
local wallent = PRK_AddModel(
	wallmod,
	Vector(),
	Angle(),
	1,
	"prk_gradient",
	Color( 255, 255, 255, 255 )
)
wallent:SetNoDraw( true )

local reload = true
function ENT:Think()
	-- Autoreload helper
	if ( reload ) then
		self:Initialize()
		reload = false
	end
end

function ENT:Initialize()
	local min, max = self:GetCollisionBounds()
	self:PhysicsInitConvex( {
		Vector( min.x, min.y, min.z ),
		Vector( min.x, min.y, max.z ),
		Vector( min.x, max.y, min.z ),
		Vector( min.x, max.y, max.z ),
		Vector( max.x, min.y, min.z ),
		Vector( max.x, min.y, max.z ),
		Vector( max.x, max.y, min.z ),
		Vector( max.x, max.y, max.z )
	} )

	-- Set up solidity and movetype
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()
	if ( phys and phys:IsValid() ) then
		phys:EnableMotion( false )
	end

	-- Enable custom collisions on the entity
	self:EnableCustomCollisions( true )

	local size = PRK_Editor_Square_Size
	self.Models = {}
	-- local ent = self:AddModel(
		-- "models/hunter/plates/plate1x1.mdl",
		-- Vector(),
		-- Angle(),
		-- 1,
		-- "prk_gradient",
		-- Color( 255, 255, 255, 255 )
	-- )
		-- local collision = self:OBBMaxs() - self:OBBMins()
		-- local border = 0.004
		-- local scale = Vector( collision.x / size, collision.y / size + border, collision.z / size + border )
		-- local mat = Matrix()
			-- mat:Scale( scale )
		-- ent:EnableMatrix( "RenderMultiply", mat )
	-- ent:SetNoDraw( true )

	-- Delay detail creation until wall is positioned
	timer.Simple( PRK_Gen_DetailWaitTime, function()
		if ( !self or !self:IsValid() ) then return end

		-- Detail models
		local min = self:OBBMins()
		local max = self:OBBMaxs()
		local precision = 10
		local amount = PRK_Wall_Detail_Mesh_Count()
		for i = 1, amount do
			local rnd = models[math.random( 1, #models )]
			local mdl = rnd[1]
			local pos = Vector( 0, 0, 8 * size * ( -0.5 + rnd[6] ) )
				pos = pos + self:GetAngles():Forward() * rnd[2].x
				pos = pos + self:GetAngles():Right() * rnd[2].y
				pos = pos + self:GetAngles():Up() * rnd[2].z
			local ang = self:GetAngles()
				ang:RotateAroundAxis( self:GetAngles():Forward(), rnd[3].p )
				ang:RotateAroundAxis( self:GetAngles():Up(), rnd[3].y )
				ang:RotateAroundAxis( self:GetAngles():Right(), rnd[3].r )
			local mat = PRK_Material_Base
			local col = rnd[5][math.random( 1, #rnd[5] )]

			local ent = self:AddModel( mdl, pos, ang, 1, mat, col )
			-- Scale
			local sca = rnd[4]
			local mat = Matrix()
				mat:Scale( sca )
			ent.Scale = sca
			ent:EnableMatrix( "RenderMultiply", mat )
			ent:SetNoDraw( true )
		end
	end )

	local collision = self:OBBMaxs() - self:OBBMins()
	local border = 0.004
	local scale = Vector( collision.x / size, collision.y / size + border, collision.z / size + border )
	local min = -scale * size
	local max = scale * size
	-- ent:SetRenderBounds( min, max )
	self:SetRenderBounds( min, max )
end

function ENT:Draw()
	if ( !self:ShouldDraw() ) then return end

	-- test sphere
	if ( true ) then
		-- mesh.GenerateSphere( self:GetPos(), 400, 8, 8 )
		-- return
	end

	-- Wall model
	local size = PRK_Editor_Square_Size
	wallent:SetPos( self:GetPos() )
	local ang = self:GetAngles()
		ang:RotateAroundAxis( self:GetAngles():Right(), 90 )
	local collision = self:OBBMaxs() - self:OBBMins()
	local border = -0.004
	local scale = Vector()
		scale = scale + VectorAbs( ang:Up() * collision.y / size + ang:Up() * border )
		scale = scale + VectorAbs( ang:Right()   * collision.x / size + ang:Right() * border )
		scale = scale + VectorAbs( ang:Forward()      * collision.z / size )
			ang:RotateAroundAxis( self:GetAngles():Forward(), 90 )
			ang:RotateAroundAxis( self:GetAngles():Right(), 90 )
	local mat = Matrix()
		mat:Scale( scale )
	wallent:EnableMatrix( "RenderMultiply", mat )
	wallent:SetAngles( ang )
	wallent:SetupBones()

	wallent:DrawModel()

	-- Details
	for k, v in pairs( self.Models ) do
		local col = v:GetColor()
		render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
		v:DrawModel()
	end
	
	-- self:DrawModel()
	-- local col = Color( 0, 0, 255, 255 )
	-- local pos, ang = self:GetPos(), self:GetAngles()
	-- local min, max = self:OBBMins(), self:OBBMaxs()
	-- render.DrawWireframeBox( pos, ang, min, max, col )
end

function ENT:OnRemove()
	for k, v in pairs( self.Models ) do
		v:Remove()
	end
end
