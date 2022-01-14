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

	local item = PRK_Items[self:GetItem()]
	-- Shared
	if ( item.InitShared ) then
		item:InitShared( self )
	end

	if ( CLIENT ) then
		if ( item.InitClient ) then
			item:InitClient( self )
		end
	end

	if ( SERVER ) then
		if ( item.InitServer ) then
			item:InitServer( self )
		end
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
