AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

ENT.SpeedRotate				= 40

function ENT:DoFire()
	if ( !self:CanSee( self.Target ) ) then
		self:SetNWEntity( "Tether", self )
		self.Target:SetWalkSpeed( PRK_Speed )
		self.Target:SetRunSpeed ( PRK_Speed )
		self.Target:SetMaxSpeed ( PRK_Speed )
		self.Target = nil
		return
	end

	self:SetNWEntity( "Tether", self.Target )
	self.Target:SetWalkSpeed( PRK_TetherSpeed )
	self.Target:SetRunSpeed ( PRK_TetherSpeed )
	self.Target:SetMaxSpeed ( PRK_TetherSpeed )
end

function ENT:ExtraOnRemove()
	if ( self.Target and self.Target:IsValid() ) then
		self.Target:SetWalkSpeed( PRK_Speed )
		self.Target:SetRunSpeed ( PRK_Speed )
		self.Target:SetMaxSpeed ( PRK_Speed )
		self.Target = nil
	end
end