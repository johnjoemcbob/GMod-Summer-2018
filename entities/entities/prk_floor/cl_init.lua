include( "shared.lua" )

local models = {
	-- CSS
	{
		"models/props/de_inferno/bushgreensmall.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1, 1, 1 ),
	},
	{
		"models/props/de_inferno/succulant.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1, 1, 0.5 ),
	},
	{
		"models/props/cs_militia/fern01.mdl",
		Vector( 0, 0, 15 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
	},
	{
		"models/props/pi_fern.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
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
}

PRK_Material_Grass = Material( "prk_grass.png", "noclamp smooth" )
PRK_Material_Grass_Multiple = Material( "prk_grass_multiple.png", "noclamp smooth" )

local colours = {
	-- Color( 92, 4, 40, 255 ),
	-- Blue/purple
	Color( 80, 4, 90, 255 ),
	Color( 65, 4, 90, 255 ),
	Color( 47, 4, 90, 255 ),
	Color( 12, 4, 90, 255 ),
	Color( 4, 12, 90, 255 ),
	Color( 4, 47, 90, 255 ),
	-- Green
	-- Color( 12, 90, 4, 255 ),
	-- Color( 47, 90, 4, 255 ),
	-- Color( 65, 90, 4, 255 ),
}

function ENT:Initialize()
	-- Floor scale
	local min, max = self:GetCollisionBounds()
	local sca = Vector( max.x / PRK_Plate_Size * 2, max.y / PRK_Plate_Size * 2, 1 )
	local mat = Matrix()
		mat:Scale( sca )
	self:EnableMatrix( "RenderMultiply", mat )
	self:SetRenderBounds( min * 2, max * 2 )

	self:PhysicsInitConvex( {
		Vector( min.x, min.y, min.z ),
		Vector( min.x, min.y, max.z ),
		Vector( min.x, max.y, min.z ),
		Vector( min.x, max.y, max.z ),
		Vector( max.x, min.y, min.z ),
		Vector( max.x, min.y, max.z ),
		Vector( max.x, max.y, min.z ),
		Vector( max.x, max.y, max.z )
	} )

	-- Set up solidity and movetype
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	-- Enable custom collisions on the entity
	self:EnableCustomCollisions( true )

	-- Delay grass/plant creation until floor is positioned
	self.Models = {}
	timer.Simple( 0.1, function()
		-- Plant models
		local min = self:OBBMins()
		local max = self:OBBMaxs()
		local precision = 10
		local amount = math.floor( math.random( PRK_Grass_Mesh_CountRange[1] * precision, PRK_Grass_Mesh_CountRange[2] * precision ) / precision * ( sca.x + sca.y ) )
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

		local grasscount = PRK_Grass_Billboard_Count * ( sca.x + sca.y )
		local grasses = {}
		for i = 1, grasscount do
			table.insert( grasses,	{
				self:GetPos() + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), 0 ),
				Angle( 0, math.random( 0, 360 ), 0 ):Forward(),
				math.random( 10, 50 ) / 10,
				Entity = self.Entity
			} )
		end
		self.GrassPos = self:GetPos()
		LocalPlayer().Grasses[self.GrassPos] = grasses
	end )
end

function ENT:Draw()
	self:DrawModel()
end

local disruptors = {}
function ENT:Think()
	if ( PRK_Grass_Mesh_Disruption ) then
		-- Disrupt plants if close
		if ( !self.NextRefreshDisruptors or self.NextRefreshDisruptors <= CurTime() ) then
			disruptors = {}
			for k, v in pairs( ents.FindInSphere( self:GetPos(), PRK_Grass_Mesh_DisruptorOuterRange ) ) do
				if ( table.HasValue( PRK_Grass_Mesh_Disruptors, v:GetClass() ) ) then
					table.insert( disruptors, v )
				end
			end
			-- for k, disrupt in pairs( PRK_Grass_Mesh_Disruptors ) do
				-- table.Add( disruptors, ents.FindByClass( disrupt ) )
			-- end
			-- table.Add( disruptors, player.GetAll() )
			-- table.Add( disruptors, ents.FindByClass( "prk_*" ) )
			-- table.Add( disruptors, ents.FindByClass( "prk_*" ) )
			-- table.Add( disruptors, ents.FindByClass( "npc_*" ) ) -- testing/fun
			self.NextRefreshDisruptors = CurTime() + PRK_Grass_Mesh_DisruptTime
		end
		local specialcases = {}
			specialcases["prk_gateway"] = function( ent, moving )
				return true, 300, ent.Scale / 2, -1, false
			end
			specialcases["prk_debris"] = function( ent, moving )
				if ( ent:GetNWBool( "Explosion" ) ) then
					return true, 400, -1, 0, false
				end
				return moving, nil, 1, 0, true
			end
		for _, ent in pairs( disruptors ) do
			if ( ent and ent:IsValid() ) then
				local effects = true
				local overridedist = nil
				local speed = ent:GetVelocity():Length()
				local moving = speed > 100
				local scaleoff = 0
				local magnitude = 1
					-- Special case for gateways
					local spc = specialcases[ent:GetClass()]
					if ( spc ) then
						moving, overridedist, magnitude, scaleoff, effects = spc( ent, moving )
					end
				-- print( speed )
				if ( moving ) then
					for k, v in pairs( self.Models ) do
						if ( !v.NextTouch or v.NextTouch <= CurTime() ) then
							local dist = ent:GetPos():Distance( v:GetPos() )
							local maxdist = PRK_Grass_Mesh_DisruptorInnerRange
								if ( overridedist ) then
									maxdist = overridedist
								end
							local close = dist < maxdist
							if ( close ) then
								local forward = ( ent:GetPos() + ent:GetVelocity() - v:GetPos() ):GetNormal()

								if ( effects ) then
									-- Sound effect
									ent:EmitSound( "npc/combine_soldier/gear" .. math.random( 4, 6 ) .. ".wav", 55, 170 + 30 / PRK_Speed * speed + math.random( -10, 10 ), 0.1 )

									-- Particle burst
									local effectdata = EffectData()
										local pos = ent:GetPos() - forward
										effectdata:SetOrigin( pos )
										effectdata:SetNormal( -forward )
										-- effectdata:SetColor( ent:GetColor() )
									util.Effect( "prk_hit", effectdata )
								end

								-- Lean away from entity
								local up = Vector( 0, 0, 1 )
								local right = up:Cross( forward )
								local ang = Angle( v.Ang.p, v.Ang.y, v.Ang.r )
									ang:RotateAroundAxis( right, magnitude * dist / maxdist * ( 50 + math.random( -10, 30 ) ) )
								v.TargetAngles = ang

								-- Bounce up/down scale
								v.TargetScaleOffset = 3 * magnitude + scaleoff

								-- Delay next
								-- v.NextTouch = CurTime() + 1
							end
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
	end

	return true
end

function ENT:OnRemove()
	-- Remove grass
	if ( LocalPlayer().Grasses ) then
		local toremove = {}
		local pos = self.GrassPos
		if ( LocalPlayer().Grasses[pos] ) then
			for k, grass in pairs( LocalPlayer().Grasses[pos] ) do
				if ( k == tonumber( k ) and grass.Entity == self.Entity ) then
					table.insert( toremove, grass )
				end
			end
			for k, remove in pairs( toremove ) do
				table.RemoveByValue( LocalPlayer().Grasses[pos], remove )
			end
		end
	end

	-- Remove visuals
	for k, v in pairs( self.Models ) do
		v:Remove()
	end
end

-- Hooked to main GAMEMODE:Think to avoid calling whole thing for each entity each frame
local nextthink = 0
hook.Add( "Think", "PRK_Think_Grass", function()
	if ( CurTime() < nextthink ) then return end

	if ( PRK_Grass_Billboard ) then
		if ( LocalPlayer().Grasses ) then
			-- Decide if whole floor clumps of grass should be drawn
			LocalPlayer().GrassesRenderOrder = {}
			-- local testpos = LocalPlayer():GetPos()
			local testpos = LocalPlayer():EyePos() + LocalPlayer():EyeAngles():Forward() * PRK_Grass_Billboard_SortRange
			for k, grasses in pairs( LocalPlayer().Grasses ) do
				local dist = k:Distance( testpos )
				grasses.ShouldDraw = ( dist < PRK_Grass_Billboard_DrawRange )
				if ( grasses.ShouldDraw ) then
					table.insert( LocalPlayer().GrassesRenderOrder, {
						Key = k,
						Dist = dist,
					} )
				end
			end
			-- Sort these entries so the closest will be drawn first
			table.sort( LocalPlayer().GrassesRenderOrder, function( a, b ) return a.Dist < b.Dist end )
			-- PrintTable( LocalPlayer().GrassesRenderOrder )
		end
	end

	nextthink = CurTime() + PRK_Grass_Billboard_ShouldDrawTime
end )

local LastSortPos = Vector()
hook.Add( "PreDrawTranslucentRenderables", "PRK_PreDrawTranslucentRenderables_Grass", function( depth, skybox )
	if ( !PRK_ShouldDraw() ) then return end
	if ( depth or skybox ) then return end

	-- Render grass
	if ( PRK_Grass_Billboard ) then
		local width = 1
		render.SetMaterial( PRK_Material_Grass )
			if ( PRK_Grass_Billboard_MultipleSprite ) then
				width = 8
				render.SetMaterial( PRK_Material_Grass_Multiple )
			end
		local size = 16
		local rendercount = 0
		if ( LocalPlayer().GrassesRenderOrder ) then
			for q, key in pairs( LocalPlayer().GrassesRenderOrder ) do
				local grasses = LocalPlayer().Grasses[key.Key]
				for _, grass in pairs( grasses ) do
					if ( _ == tonumber( _ ) ) then
						render.DrawQuadEasy(
							grass[1] + Vector( 0, 0, size / 2 ),
							grass[2],
							size * width, size + grass[3],
							PRK_Grass_Colour,
							180
						)
						rendercount = rendercount + 1
						if ( rendercount >= PRK_Grass_Billboard_MaxRenderCount ) then
							break
						end
					end
				end
				if ( rendercount >= PRK_Grass_Billboard_MaxRenderCount ) then
					break
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
