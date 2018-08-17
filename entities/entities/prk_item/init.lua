AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

-- Net send data table
-- util.AddNetworkString( "PRK_Item_Data" )

function ENT:InitializeNewClient()
	self:SendZone( self.Zone )
	-- PRK_Items[self:GetItem()]:SendData( self )
end

function ENT:TraceUse( ply )
	PRK_PickupItem( ply, self:GetItem(), self )
	-- PRK_Items[self:GetItem()]:Use( self, ply )
end

function ENT:SetItem( name )
	self:SetNWString( "PRK_Item", name )
end
