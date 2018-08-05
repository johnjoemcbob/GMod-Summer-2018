include( "shared.lua" )

net.Receive( "PRK_Potion_Type", function( len, ply )
	local ent = net.ReadEntity()
	local type = net.ReadString()

	local function try()
		if ( ent and ent:IsValid() and ent.Initialize ) then
			ent:Initialize()
		else
			-- Try again after the ent is available to the client
			timer.Simple( 1, function()
				try()
			end )
		end
	end
	try()
end )

function ENT:Initialize()
	-- In case of reinit
	if ( self.Visuals ) then
		for k, vis in pairs( self.Visuals ) do
			if ( vis and vis:IsValid() ) then
				vis:Remove()
			end
		end
	end

	local scale = 1

	-- Add visuals
	-- self.Visuals = {}
	-- local main = PRK_AddModel(
		-- "models/props_wasteland/coolingtank02.mdl",
		-- Vector( 0, 0, scale * 0.2 ),
		-- Angle( 180, 0, 0 ),
		-- scale * 0.2 * 0.3,
		-- "models/shiny",
		-- Color( 150, 150, 200, 100 )
	-- )
		-- main:SetRenderMode( RENDERMODE_TRANSALPHA )
		-- PRK_RenderScale( main, Vector( 1.2, 1.2, 1 ) )
	-- table.insert( self.Visuals, main )

	-- local liquid = PRK_AddModel(
		-- "models/props_wasteland/coolingtank02.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 180, 0, 0 ),
		-- scale * 0.18 * 0.3,
		-- "models/shiny",
		-- self:GetColor() -- Get colour from server
	-- )
		-- PRK_RenderScale( liquid, Vector( 1, 1, 1 ) )
	-- table.insert( self.Visuals, liquid )

	-- local cap = PRK_AddModel(
		-- "models/hunter/blocks/cube025x025x025.mdl",
		-- Vector( 0, 0, scale * 11 ),
		-- Angle( 0, 0, 0 ),
		-- scale * 0.7,
		-- "models/shiny",
		-- Color( self:GetColor().r * 2, self:GetColor().g * 2, self:GetColor().b * 2, 255 )
	-- )
		-- PRK_RenderScale( cap, Vector( 1, 1, 0.6 ) )
	-- table.insert( self.Visuals, cap )

	self.Visuals = {}
	local main = PRK_AddModel(
		"models/XQM/Rails/funnel.mdl",
		Vector( 0, 0, scale * 2 ),
		Angle( 180, 0, 0 ),
		scale * 0.2,
		"models/shiny",
		Color( 150, 150, 200, 100 )
	)
		main:SetRenderMode( RENDERMODE_TRANSALPHA )
		PRK_RenderScale( main, Vector( 1, 1, 1.5 ) )
	table.insert( self.Visuals, main )

	local liquid = PRK_AddModel(
		"models/XQM/Rails/funnel.mdl",
		Vector( 0, 0, 0 ),
		Angle( 180, 0, 0 ),
		scale * 0.18,
		"models/shiny",
		self:GetColor() -- Get colour from server
	)
		PRK_RenderScale( liquid, Vector( 1, 1, 1.5 ) )
	table.insert( self.Visuals, liquid )

	local cap = PRK_AddModel(
		"models/hunter/blocks/cube025x025x025.mdl",
		Vector( 0, 0, scale * 1 ),
		Angle( 0, 0, 0 ),
		scale * 0.9,
		"models/shiny",
		Color( self:GetColor().r * 2, self:GetColor().g * 2, self:GetColor().b * 2, 255 )
	)
		PRK_RenderScale( cap, Vector( 1, 1, 0.4 ) )
	table.insert( self.Visuals, cap )

	local base = PRK_AddModel(
		"models/mechanics/wheels/wheel_speed_72.mdl",
		Vector( 0, 0, scale * -14.5 ),
		Angle( 0, 0, 0 ),
		scale * 0.3,
		"models/shiny",
		Color( 150, 150, 200, 255 )
	)
		PRK_RenderScale( base, Vector( 1, 1, 0.4 ) )
	table.insert( self.Visuals, base )
end

-- Also update pos/ang here in case Draw wouldn't be called (if the entity is already out of view)
function ENT:Think()
	if ( !self.Visuals ) then
		self:Initialize()
	end
	if ( self.Visuals ) then
		for k, vis in pairs( self.Visuals ) do
			if ( vis and vis:IsValid() ) then
				vis:SetPos(
					self:GetPos() +
					self:GetUp() * vis.Pos.z
				)
				local ang = self:GetAngles()
					ang:RotateAroundAxis( self:GetForward(), vis.Ang.p )
				vis:SetAngles( ang )
			end
		end
	end
end

function ENT:Draw()
	
end

function ENT:OnRemove()
	if ( self.Visuals ) then
		for k, vis in pairs( self.Visuals ) do
			if ( vis and vis:IsValid() ) then
				vis:Remove()
			end
		end
	end
end
