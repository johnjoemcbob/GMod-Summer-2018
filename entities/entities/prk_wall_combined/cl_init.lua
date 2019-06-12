include( "shared.lua" )

local Walls = {}
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

net.Receive( "PRK_Wall_Combined", function( len, ply )
	local self = net.ReadEntity()
	local wall = net.ReadTable()

	Walls = wall
	PrintTable( Walls )
end )

function ENT:Initialize()
	
end

function ENT:Draw()
	if ( !PlayerInZone( self, self.Zone ) ) then return end

	for k, wall in pairs( Walls ) do
		local min = wall.Ent:GetPos() + self:GetRotated( wall, wall.Min ) - self:GetPos()
		local max = wall.Ent:GetPos() + self:GetRotated( wall, wall.Max ) - self:GetPos()
		local col = Color( 0, 0, 255, 255 )
		render.DrawWireframeBox( self:GetPos(), self:GetAngles(), min, max, col )
	end

	-- Wall model
	-- local size = PRK_Editor_Square_Size
	-- wallent:SetPos( self:GetPos() )
	-- local ang = self:GetAngles()
		-- ang:RotateAroundAxis( self:GetAngles():Right(), 90 )
	-- local collision = self:OBBMaxs() - self:OBBMins()
	-- local border = 0.004
	-- local scale = Vector()
		-- scale = scale + VectorAbs( ang:Forward() * collision.y / size + ang:Forward() * border )
		-- scale = scale + VectorAbs( ang:Right()   * collision.z / size * 0.15 )
		-- scale = scale + VectorAbs( ang:Up()      * collision.x / size )
		-- if ( math.approx( math.abs( ang.y ), 180 ) or math.approx( math.abs( ang.y ), 0 ) ) then
			-- ang:RotateAroundAxis( self:GetAngles():Forward(), 90 )
		-- end
	-- local mat = Matrix()
		-- mat:Scale( scale )
	-- wallent:EnableMatrix( "RenderMultiply", mat )
	-- wallent:SetAngles( ang )
	-- wallent:SetupBones()
	-- wallent:DrawModel()
	
	
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

function ENT:GetRotated( wall, point )
	local ret = point
		if ( wall.Ent:GetAngles().y == 0 ) then
			local temp = ret.z
			ret.z = ret.y
			ret.y = temp
		else
			local temp = ret.x
			ret.x = ret.y
			ret.y = temp
		end
	return ret
end
