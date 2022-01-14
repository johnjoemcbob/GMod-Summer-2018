ENT.Type = "anim"
ENT.Base = "prk_base"
ENT.PrintName = "Prickly Gateway"
ENT.Author = "johnjoemcbob"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.Spawnable = true
ENT.AdminSpawnable = true

function ENT:CheckInFront( ent )
	local entdir = ( self:GetPos() - ent:GetPos() ):GetNormalized()
	local dot = -self:GetForward():Dot( entdir )
	return ( dot > 0 )
end
