include( "shared.lua" )

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
local Instance

net.Receive( "PRK_Wall_Combined", function( len, ply )
	local self = net.ReadEntity()
	local wall = net.ReadTable()

	Walls = wall
	-- PrintTable( Walls )
end )

function ENT:Think()
	if ( Instance == nil or !Instance:IsValid() ) then
		Instance = self
	end

	if ( Walls != nil ) then
		self.Walls = Walls
		-- Combine all wall physics meshes
		local collisions = {}
			for k, room in pairs( self.Walls ) do
				for v, wall in pairs( room ) do
					local min = ( wall.Min )
					local max = ( wall.Max )
					table.insert( collisions, {
						Vector( min.x, min.y, min.z ),
						Vector( min.x, min.y, max.z ),
						Vector( min.x, max.y, min.z ),
						Vector( min.x, max.y, max.z ),
						Vector( max.x, min.y, min.z ),
						Vector( max.x, min.y, max.z ),
						Vector( max.x, max.y, min.z ),
						Vector( max.x, max.y, max.z ),
					} )
				end
			end
		self:PhysicsInitMultiConvex( collisions )

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
		local collision = self:OBBMaxs() - self:OBBMins()
		local border = 0.004
		local scale = Vector( collision.x / size, collision.y / size + border, collision.z / size + border )
		local min = -scale * size
		local max = scale * size
		-- print( min )
		-- print( max )
		self:SetRenderBounds( min, max )
		
		Walls = nil
	end
end

function ENT:Draw()
	if ( !PlayerInZone( self, self.Zone ) ) then return end
	if ( !self.Walls ) then return end

	-- Render
	if ( PRK_Wall_Render and LocalPlayer().PRK_Room and PRK_RoomConnections ) then
		local rooms = PRK_GetShouldDrawRooms( self.Zone, LocalPlayer().PRK_Room )
		for room, v in pairs( rooms ) do
			if ( self.Walls[room] ) then
				for k, wall in pairs( self.Walls[room] ) do
					local min = ( wall.Min )
					local max = ( wall.Max )
					-- print( min )
					local col = Color( 255, 0, 0, 255 )
					-- render.DrawWireframeBox( self:GetPos(), self:GetAngles(), min, max, col )

					-- Wall model
					local size = PRK_Editor_Square_Size
					wallent:SetPos( self:GetPos() + ( wall.Max + wall.Min ) / 2 )
					local ang = self:GetAngles()
						ang:RotateAroundAxis( self:GetAngles():Right(), 90 )
					local collision = wall.Min - wall.Max
					local border = 0.004
					local scale = Vector()
						scale = scale + VectorAbs( ang:Up() * collision.y / size + ang:Forward() * border )
						scale = scale + VectorAbs( ang:Right()   * collision.x / size )
						scale = scale + VectorAbs( ang:Forward()      * collision.z / size )
							ang:RotateAroundAxis( self:GetAngles():Forward(), 90 )
							ang:RotateAroundAxis( self:GetAngles():Right(), 90 )
					local mat = Matrix()
						mat:Scale( scale )
					wallent:EnableMatrix( "RenderMultiply", mat )
					wallent:SetAngles( ang )
					wallent:SetupBones()
					wallent:DrawModel()
				end
			end
		end
	end
end

-- Debug combination
hook.Add( "HUDPaint", "PRK_HUDPaint_WallCombined", function()
	-- if ( Instance ) then
		-- local self = Instance
		-- for k, wall in pairs( self.Walls ) do
			-- local size = PRK_Editor_Square_Size
			-- local mid = wall.Min / size
			-- local dim = ( wall.Max - wall.Min ) / size
			-- local x = ScrW() / 14 + mid.x
			-- local y = ScrH() / 8 + mid.y
			-- local scale = 4
			-- surface.SetDrawColor( 0, 255, 0, 10 )
			-- surface.DrawRect( x * scale, y * scale, ( dim.x + 1 ) * scale, ( dim.y + 1 ) * scale )
		-- end
		-- print( #self.Walls )

		-- self:SplitWallsToGrid()
		-- for k, wall in pairs( self.GridPoints ) do
			-- local size = PRK_Editor_Square_Size
			-- local mid = wall
			-- local x = ScrW() / 14 + mid.x
			-- local y = ScrH() / 8 + mid.y
			-- local scale = 2
			-- surface.SetDrawColor( 255, 0, 0, 255 )
			-- surface.DrawRect( ( x * 2 ) * scale, ( y * 2 ) * scale, 1 * scale, 1 * scale )
		-- end

		-- self:CombineGridToWalls()
		-- for k, wall in pairs( self.CombinedWalls ) do
			-- local size = PRK_Editor_Square_Size
			-- local mid = wall.Min
			-- local dim = ( wall.Max - wall.Min )
			-- local x = ScrW() / 14 + mid.x
			-- local y = ScrH() / 8 + mid.y
			-- local scale = 4
			-- surface.SetDrawColor( 0, 0, 255, 255 )
			-- surface.DrawRect( x * scale, y * scale, ( dim.x + 1 ) * scale, ( dim.y + 1 ) * scale )
		-- end
		-- print( #self.CombinedWalls )
	-- end
end )

function ENT:SplitWallsToGrid()
	self.GridPoints = {}
	self.Grid = {}
	for k, wall in pairs( self.Walls ) do
		local size = PRK_Editor_Square_Size
		local mid = wall.Min / size
		local dim = ( wall.Max - wall.Min ) / size
		for x = 0, dim.x do
			table.insert( self.GridPoints, mid + Vector( x, 0, 0 ) )
			self.Grid[math.ceil(mid.x+x)] = self.Grid[math.ceil(mid.x+x)] or {}
			self.Grid[math.ceil(mid.x+x)][math.ceil(mid.y)] = true
		end
		for y = 0, dim.y do
			table.insert( self.GridPoints, mid + Vector( 0, y, 0 ) )
			self.Grid[math.ceil(mid.x)] = self.Grid[math.ceil(mid.x)] or {}
			self.Grid[math.ceil(mid.x)][math.ceil(mid.y+y)] = true
		end
	end
end

function ENT:CombineGridToWalls()
	self.CombinedWalls = {}
	-- print( "1---" )
	-- PrintTable( self.Grid )
	-- print( "0---" )
	local function insert( startx, finishx, starty, finishy )
		table.insert( self.CombinedWalls, {
			Min = Vector( startx, starty ),
			Max = Vector( finishx, finishy ),
		} )
	end

	-- Find max x/y for self.Grid
	local minx, miny = 0, 0
	local maxx, maxy = 0, 0
	for x, v in pairs( self.Grid ) do
		minx = math.ceil( math.min( minx, x ) )
		maxx = math.ceil( math.max( maxx, x ) )
		for y, k in pairs( v ) do
			miny = math.ceil( math.min( miny, y ) )
			maxy = math.ceil( math.max( maxy, y ) )
		end
	end
	-- print( maxx )
	-- print( maxy )

	-- Start looping x/y self.Grid at 0,0 to max
	-- First for rows
	local lastx = -1
	for y = miny, maxy do
		for x = minx, maxx do
			-- Ensure this cell is populated first
			self.Grid[x] = self.Grid[x] or {}

			if ( self.Grid[x][y] ) then
				-- Start or Continue wall segment
				if ( lastx == -1 ) then
					lastx = x
				end
				-- Finish if it's the end of the row
				if ( x == maxx ) then
					insert( lastx, x, y, y )
					lastx = -1
				end
			elseif ( lastx != -1 ) then
				-- Finish the wall segment
				insert( lastx, x - 1, y, y )
				lastx = -1
			end
		end
	end

	-- Later to combine columns of matching sized rows
	print( "try" )
	local todelete = {}
	for k, wall in pairs( self.CombinedWalls ) do
		for v, other in pairs( self.CombinedWalls ) do
			if ( k != v ) then
				-- Has to be the same position and width
				if ( wall.Min.x == other.Min.x and wall.Max.x == other.Max.x ) then
					-- Then also within height range on either side
					-- print( math.abs( wall.Min.y - other.Max.y ) )
					if ( math.abs( wall.Min.y - other.Max.y ) == 1 or math.abs( wall.Max.y - other.Min.y ) == 1 ) then
						-- Take the minimum miny and maximum maxy and remove the other
						wall.Min.y = math.min( wall.Min.y, other.Min.y )
						wall.Max.y = math.max( wall.Max.y, other.Max.y )

						-- other.Min = Vector()
						-- other.Max = Vector()
						-- table.insert( todelete, v )
						-- print( "match " .. k .. " with " .. v )
					end
				end
			end
		end
	end
	for k, v in pairs( todelete ) do
		table.remove( self.CombinedWalls, v )
	end

	-- PrintTable( self.CombinedWalls )
end

function ENT:OnRemove()
	if ( self.Models != nil ) then
		for k, v in pairs( self.Models ) do
			v:Remove()
		end
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
