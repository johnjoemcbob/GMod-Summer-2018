ENT.Type = "anim"
ENT.Base = "prk_base"
ENT.PrintName = "Prickly Use Item"
ENT.Author = "johnjoemcbob"
ENT.Purpose = ""
ENT.Instructions = ""

ENT.Spawnable = false
ENT.AdminSpawnable = false

-- ENT.MaxUseRange = 80

function ENT:Initialize()
	if ( !self:GetItem() or !PRK_Items[self:GetItem()] ) then return end

	-- Shared
	PRK_Items[self:GetItem()]:InitShared( self )

	if ( CLIENT ) then
		PRK_Items[self:GetItem()]:InitClient( self )
	end

	if ( SERVER ) then
		PRK_Items[self:GetItem()]:InitServer( self )
	end
end

function ENT:Think()
	-- Shared
	

	if ( CLIENT ) then
		
	end

	if ( SERVER ) then
		
	end
end

function ENT:GetItem()
	local item = self:GetNWString( "PRK_Item" )
		if ( item == "" ) then
			item = nil
		end
	return item
end
