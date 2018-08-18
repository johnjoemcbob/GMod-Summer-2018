AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

util.AddNetworkString( "PRK_EntZone" )
util.AddNetworkString( "PRK_EntScale" )

function ENT:SendZone( zone )
	if ( !zone ) then return end

	net.Start( "PRK_EntZone" )
		net.WriteEntity( self )
		net.WriteFloat( zone )
	net.Broadcast()
end

function ENT:SendScale( scale, phys )
	net.Start( "PRK_EntScale" )
		net.WriteEntity( self )
		net.WriteVector( scale )
		net.WriteBool( phys )
	net.Broadcast()
end

function ENT:SetZone( zone )
	self.Zone = zone
	self:SendZone( zone )
end

function ENT:InitializeNewClient()
	self:SendZone( self.Zone )
	if ( self.Scale and isvector( self.Scale ) ) then
		self:SendScale( self.Scale )
	end
end

function ENT:CreateEnt( class, mod, pos, ang, mat, col, mov )
	local ent = PRK_CreateEnt( class, mod, pos, ang, mov )
		ent:SetParent( self )
		if ( mat ) then
			ent:SetMaterial( mat )
		end
		if ( col ) then
			ent:SetColor( col )
		end
		table.insert( self.Ents, ent )
	return ent
end
