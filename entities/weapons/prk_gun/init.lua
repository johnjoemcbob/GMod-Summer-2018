
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

-- Add functionality for moving forwards through chambers without firing
-- hook.Add( "OnSpawnMenuOpen", "PRK_OnSpawnMenuOpen_Gun", function() -- Clientside only
if ( !PRK_SANDBOX ) then
	concommand.Add( "+menu", function( ply, cmd, args )
		local self = ply:GetActiveWeapon()
		if ( self and self:IsValid() and self:GetClass() == "prk_gun" ) then
			self:Reload( -1 )
		end
	end )
end
