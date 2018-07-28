include( "shared.lua" )

net.Receive( "PRK_EntZone", function( len, ply )
	local self = net.ReadEntity()
	local zone = net.ReadFloat()

	self.Zone = zone
end )
