include( "shared.lua" )

net.Receive( "PRK_EntZone", function( len, ply )
	local self = net.ReadEntity()
	local zone = net.ReadFloat()

	self.Zone = zone
end )

net.Receive( "PRK_EntScale", function( len, ply )
	local self = net.ReadEntity()
	local scale = net.ReadVector()
	local phys = net.ReadBool()

	local function try()
		if ( self and self:IsValid() ) then
			self.Scale = scale
			local mat = Matrix()
				mat:Scale( scale )
			self:EnableMatrix( "RenderMultiply", mat )

			if ( phys ) then
				self:PhysicsInit( SOLID_VPHYSICS )
				PRK_ResizePhysics( self, self.Scale )
			end
		else
			timer.Simple( 1, function() try() end )
		end
	end
	try()
end )

function ENT:GetRoom()
	self.PRK_Room = 0

	local zone = self.Zone
	if ( zone and zone != 0 ) then
		local size = PRK_Plate_Size
		local gridpos = self:GetPos() - PRK_Zones[zone].pos
			gridpos = gridpos / size
			gridpos.x = math.Round( gridpos.x )
			gridpos.y = math.Round( gridpos.y )
		local roomid = nil
			if ( PRK_Floor_Grid[zone][gridpos.x] ) then
				roomid = PRK_Floor_Grid[zone][gridpos.x][gridpos.y]
			end
		if ( roomid != nil ) then
			self.PRK_Room = roomid
		end
	end
	return self.PRK_Room
end

function ENT:ShouldDraw()
	return PlayerInZone( self, self.Zone ) and ( self.Zone == 0 or self:GetShouldDrawRooms()[LocalPlayer().PRK_Room] )
end

function PRK_GetShouldDrawRooms( zone, roomid )
	local rooms = {}
		rooms[roomid] = true
		if ( zone and PRK_RoomConnections and PRK_RoomConnections[zone] and PRK_RoomConnections[zone][roomid] ) then
			for k, room in pairs( PRK_RoomConnections[zone][roomid] ) do
				rooms[room] = true
			end
		end
	return rooms
end

function ENT:GetShouldDrawRooms()
	return PRK_GetShouldDrawRooms( self.Zone, self:GetRoom() )
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
