include( "shared.lua" )

local models = {
	-- CSS
	{
		"models/props/de_inferno/bushgreensmall.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1, 1, 1 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	},
	{
		"models/props/cs_militia/fern01.mdl",
		Vector( 0, 0, 15 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	},
	{
		"models/props/pi_fern.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	},
	{
		"models/props/de_inferno/cactus.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 0.2, 0.2, 1 ),
	},
	{
		"models/props/de_inferno/cactus2.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 0.2, 0.2, 1 ),
	},
	-- HL2
	-- {
		-- "models/Gibs/wood_gib01c.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 90, 0, 0 ),
		-- Vector( 2, 1, 1 ),
	-- },
	-- {
		-- "models/Gibs/wood_gib01c.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 90, 0, 0 ),
		-- Vector( 3, 1, 1 ),
	-- },
	-- {
		-- "models/Gibs/wood_gib01c.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 90, 0, 0 ),
		-- Vector( 4, 1, 1 ),
	-- },
	-- {
		-- "models/props_c17/oildrumchunk01b.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 0.5, 0.1, 2 ),
	-- },
	-- {
		-- "models/props_foliage/bramble001a.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 0.5, 0.5, 0.5 ),
	-- },
	-- {
		-- "models/gibs/scanner_gib02.mdl",
		-- Vector( 0, 0, 5 ),
		-- Angle( 90, 90, 0 ),
		-- Vector( 2, 2, 2 ),
	-- },
	-- {
		-- "models/props_junk/garbage128_composite001b.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 1, 1, 1 ),
	-- },
}

PRK_Material_Grass = Material( "prk_grass.png", "noclamp smooth" )

local colours = {
	Color( 65, 4, 90, 255 ),
	Color( 47, 4, 90, 255 ),
	Color( 12, 4, 90, 255 ),
}

function ENT:Initialize()
	-- Plant models
	local min = self:OBBMins()
	local max = self:OBBMaxs()
	self.Models = {}
	local mult = 10
	local amount = math.floor( math.random( PRK_Grass_Mesh_CountRange[1] * mult, PRK_Grass_Mesh_CountRange[2] * mult ) / mult )
	for i = 1, amount do
		local rnd = models[math.random( 1, #models )]
		local mdl = rnd[1]
		local pos = Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), math.random( min.z, max.z ) ) + rnd[2]
		local ang = rnd[3] + Angle( math.random( -10, 10 ), math.random( 0, 360 ), math.random( -10, 10 ) )
		local mat = "models/debug/debugwhite"
		local col = colours[math.random( 1, #colours )]

		local ent = self:AddModel( mdl, pos, ang, 1, mat, col )
		-- Scale
		local sca = rnd[4]
		local mat = Matrix()
			mat:Scale( sca )
		ent.Scale = sca
		ent:EnableMatrix( "RenderMultiply", mat )
	end

	-- Grass billboards
	if ( !LocalPlayer().Grasses ) then
		LocalPlayer().Grasses = {}
	end

	local grasscount = PRK_Grass_Billboard_Count
	local grasses = {}
	for i = 1, grasscount do
		table.insert( grasses,	{
			self:GetPos() + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), 0 ),
			Angle( 0, math.random( 0, 360 ), 0 ):Forward(),
			math.random( 10, 50 ) / 10,
			Entity = self.Entity
		} )
	end
	LocalPlayer().Grasses[self:GetPos()] = grasses
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()
	-- Disrupt plants if close
	local disruptors = {}
		table.Add( disruptors, player.GetAll() )
		table.Add( disruptors, ents.FindByClass( "prk_*_heavy" ) )
		table.Add( disruptors, ents.FindByClass( "prk_npc_*" ) )
	for _, ent in pairs( disruptors ) do
		local speed = ent:GetVelocity():Length()
		-- print( speed )
		local moving = speed > 100
		if ( moving ) then
			for k, v in pairs( self.Models ) do
				if ( !v.NextTouch or v.NextTouch <= CurTime() ) then
					local dist = ent:GetPos():Distance( v:GetPos() )
					local maxdist = 50
					local close = dist < maxdist
					if ( close ) then
						-- Sound effect
						ent:EmitSound( "npc/combine_soldier/gear" .. math.random( 4, 6 ) .. ".wav", 55, 170 + 30 / PRK_Speed * speed + math.random( -10, 10 ), 0.1 )

						-- Lean away from entity
						local forward = ( ent:GetPos() + ent:GetVelocity() - v:GetPos() ):GetNormal()
						local up = Vector( 0, 0, 1 )
						local right = up:Cross( forward )
						local ang = Angle( v.Ang.p, v.Ang.y, v.Ang.r )
							ang:RotateAroundAxis( right, dist / maxdist * ( 50 + math.random( -10, 30 ) ) )
						v.TargetAngles = ang

						-- Bounce up/down scale
						v.TargetScaleOffset = 3

						-- Particle burst
						local effectdata = EffectData()
							local pos = ent:GetPos() - forward
							effectdata:SetOrigin( pos )
							effectdata:SetNormal( -forward )
							-- effectdata:SetColor( ent:GetColor() )
						util.Effect( "prk_hit", effectdata )

						-- Delay next
						-- v.NextTouch = CurTime() + 1
					end
				end
			end
		end
	end

	-- Lerp plants
	for k, v in pairs( self.Models ) do
		-- Lerp angles
		if ( v.TargetAngles ) then
			local speed = 5
			local ang = LerpAngle( FrameTime() * speed, v:GetAngles(), v.TargetAngles )
			v:SetAngles( ang )
			v.TargetAngles = v.Ang
		end

		-- Lerp scale
		if ( v.TargetScaleOffset ) then
			local speed = 10
			local scalemulthori = 0.1
			local scalemultvert = -0.2
			v.TargetScaleOffset = math.Approach( v.TargetScaleOffset, 0, FrameTime() * speed )
			local scaleoffset = v.TargetScaleOffset - 2
				if ( scaleoffset < -1 ) then
					scaleoffset = ( 1 - scaleoffset ) - 3
				end
			local sca = v.Scale + Vector( scaleoffset * scalemulthori, scaleoffset * scalemulthori, scaleoffset * scalemultvert )
			local mat = Matrix()
				mat:Scale( sca )
			v:EnableMatrix( "RenderMultiply", mat )

			-- End scale
			if ( v.TargetScaleOffset == 0 ) then
				v.TargetScaleOffset = nil
			end
		end
	end

	return true
end

function ENT:OnRemove()
	-- Remove grass
	local toremove = {}
	for k, grass in pairs( LocalPlayer().Grasses ) do
		if ( grass.Entity == self.Entity ) then
			table.insert( toremove, grass )
		end
	end
	for k, remove in pairs( toremove ) do
		table.RemoveByValue( LocalPlayer().Grasses, grass )
	end

	-- Remove visuals
	for k, v in pairs( self.Models ) do
		v:Remove()
	end
end

local nextthink = 0
hook.Add( "Think", "PRK_Think_Grass", function()
	if ( CurTime() < nextthink ) then return end

	for k, grasses in pairs( LocalPlayer().Grasses ) do
		local dist = k:Distance( LocalPlayer():GetPos() )
		grasses.ShouldDraw = ( dist < PRK_Grass_Billboard_DrawRange )
	end

	nextthink = CurTime() + PRK_Grass_Billboard_ShouldDrawTime
end )

local LastSortPos = Vector()
hook.Add( "PreDrawTranslucentRenderables", "PRK_PreDrawTranslucentRenderables_Grass", function()
	if ( !PRK_ShouldDraw() ) then return end

	-- Sort grass by furthest from player first, to avoid depth issues (better way to do this?)
	if ( PRK_Grass_Billboard_MaxSortCount != 0 ) then
		local distply = LocalPlayer():GetPos():Distance( LastSortPos )
		if ( distply >= PRK_Grass_Billboard_SortRange ) then
			table.bubbleSort(
				LocalPlayer().Grasses,
				function( a, b )
					local dista = math.Round( LocalPlayer():GetPos():Distance( a[1] ), 1 )
					local distb = math.Round( LocalPlayer():GetPos():Distance( b[1] ), 1 )
					return dista < distb
				end,
				PRK_Grass_Billboard_MaxSortCount
			)
			LastSortPos = LocalPlayer():GetPos()
		end
	end

	-- Render grass
	render.SetMaterial( PRK_Material_Grass )
	local size = 16
	local rendercount = 0
	for k, grasses in pairs( LocalPlayer().Grasses ) do
		if ( grasses.ShouldDraw ) then
			for _, grass in pairs( grasses ) do
				if ( _ == tonumber( _ ) ) then
					render.DrawQuadEasy(
						grass[1] + Vector( 0, 0, size / 2 ),
						grass[2],
						size, size + grass[3],
						PRK_Grass_Colour,
						180
					)
					rendercount = rendercount + 1
					if ( rendercount >= PRK_Grass_Billboard_MaxRenderCount ) then
						break
					end
				end
			end
		end
	end
end )

function ENT:AddModel( mdl, pos, ang, scale, mat, col )
	local model = ClientsideModel( mdl )
		model:SetPos( self:GetPos() + pos )
		model:SetAngles( ang )
		model:SetModelScale( scale )
		model:SetMaterial( mat )
		model:SetColor( col )
		model.Pos = pos
		model.Ang = ang
		-- model.RenderBoundsMin, model.RenderBoundsMax = model:GetRenderBounds()
	table.insert(
		self.Models,
		model
	)
	return model
end
