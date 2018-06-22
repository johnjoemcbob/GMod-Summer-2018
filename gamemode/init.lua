--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Serverside
--

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "levelgen.lua" )
include( "shared.lua" )

function GM:PlayerSpawn( ply )
	local wep = ply:Give( "prk_gun", true )
	wep:Initialize()
end

-- Create a physics prop which is frozen by default
-- Model (String), Position (Vector), Angle (Angle), Should Move? (bool)
function PRK_CreateProp( mod, pos, ang, mov )
	local ent = ents.Create( "prop_physics" )
		ent:SetModel( mod )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		if ( !mov ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( false )
			end
		end
	return ent
end

-- Create an ent which is frozen by default
-- Class (String), Model (String), Position (Vector), Angle (Angle), Should Move? (bool)
function PRK_CreateEnt( class, mod, pos, ang, mov )
	local ent = ents.Create( class )
		ent:SetModel( mod )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		if ( !mov ) then
			local phys = ent:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:EnableMotion( false )
			end
		end
	return ent
end
