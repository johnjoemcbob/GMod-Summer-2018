include( "shared.lua" )

local models = {
	-- CSS
	{ -- Small
		"models/props/de_inferno/bushgreensmall.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1, 1, 1 ),
		{ 0.75, 1 },
	},
	{ -- Good
		"models/props/pi_fern.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 1.7, 1.7, 1.7 ),
		{ 0.75, 1 },
	},
	{ -- Grass
		"models/props/de_inferno/cactus.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 0.2, 0.2, 1 ),
		{ 0.75, 1 },
	},
	{ -- Grass
		"models/props/de_inferno/cactus2.mdl",
		Vector( 0, 0, 0 ),
		Angle( 0, 0, 0 ),
		Vector( 0.2, 0.2, 1 ),
		{ 0.75, 1 },
	},
	-- { -- Large
		-- "models/props/cs_militia/fern01.mdl",
		-- Vector( 0, 0, 15 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 1.7, 1.7, 1.7 ),
	-- },
	-- { -- Fancy
		-- "models/props/de_inferno/succulant.mdl",
		-- Vector( 0, 0, 0 ),
		-- Angle( 0, 0, 0 ),
		-- Vector( 1, 1, 0.5 ),
	-- },
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
	timer.Simple( PRK_Gen_DetailWaitTime, function()
		if ( !self or !self:IsValid() ) then return end

		-- Plant models
		local between = 1
		local function createplants()
			if ( self.Zone != nil ) then
				if ( !LocalPlayer().Plants ) then
					LocalPlayer().Plants = {}
				end
				if ( !LocalPlayer().Plants[self.Zone] ) then
					LocalPlayer().Plants[self.Zone] = {}
				end

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

					local ent = PRK_AddModel( mdl, self:GetPos() + pos, ang, 1, mat, col )
						-- Scale
						local mult = math.random( rnd[5][1] * 100, rnd[5][2] * 100 ) / 100
						local sca = rnd[4] * mult
						local mat = Matrix()
							mat:Scale( sca )
						ent.Scale = sca
						ent:EnableMatrix( "RenderMultiply", mat )
						ent:SetNoDraw( true )
					table.insert( LocalPlayer().Plants[self.Zone], ent )
				end
			else
				timer.Simple( between, function() createplants() end )
			end
		end
		createplants()

		-- Grass billboards
		local between = 1
		local function creategrass()
			if ( self.Zone != nil ) then
				if ( !LocalPlayer().Grasses ) then
					LocalPlayer().Grasses = {}
				end
				if ( !LocalPlayer().Grasses[self.Zone] ) then
					LocalPlayer().Grasses[self.Zone] = {}
				end

				local grasscount = PRK_Grass_Billboard_Count * ( sca.x + sca.y )
				local grasses = {}
				for i = 1, grasscount do
					table.insert( grasses, {
						self:GetPos() + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), 0 ),
						Angle( 0, math.random( 0, 360 ), 0 ):Forward(),
						math.random( 10, 50 ) / 10,
						Entity = self.Entity
					} )
				end
				self.GrassPos = self:GetPos()
				LocalPlayer().Grasses[self.Zone][self.GrassPos] = grasses
			else
				timer.Simple( between, function() creategrass() end )
			end
		end
		creategrass()
	end )
end

-- Hooked to main GAMEMODE:Think to avoid calling whole thing for each entity each frame
local disruptors = {}
local nextthink = 0
hook.Add( "Think", "PRK_Think_Grass", function()
	local zone = LocalPlayer():GetNWInt( "PRK_Zone" )

	-- Plants
	if ( PRK_Grass_Mesh and PRK_Grass_Mesh_Disruption and LocalPlayer().Plants and LocalPlayer().Plants[zone] ) then
		-- Disrupt plants if close
		if ( !LocalPlayer().NextRefreshDisruptors or LocalPlayer().NextRefreshDisruptors <= CurTime() ) then
			disruptors = {}
			for k, v in pairs( ents.FindInSphere( LocalPlayer():GetPos(), PRK_Grass_Mesh_DisruptorOuterRange ) ) do
				if ( table.HasValue( PRK_Grass_Mesh_Disruptors, v:GetClass() ) ) then
					table.insert( disruptors, v )
				end
			end
			LocalPlayer().NextRefreshDisruptors = CurTime() + PRK_Grass_Mesh_DisruptTime
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
					for k, v in pairs( LocalPlayer().Plants[zone] ) do
						if ( v and v:IsValid() and ( !v.NextTouch or v.NextTouch <= CurTime() ) ) then
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
		for k, v in pairs( LocalPlayer().Plants[zone] ) do
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

	if ( CurTime() >= nextthink ) then
		-- Grass
		if ( PRK_Grass_Billboard and LocalPlayer().Grasses and LocalPlayer().Grasses[zone] ) then
			-- Decide if whole floor clumps of grass should be drawn
			LocalPlayer().GrassesRenderOrder = {}
			-- local testpos = LocalPlayer():GetPos()
			local testpos = LocalPlayer():EyePos() + LocalPlayer():EyeAngles():Forward() * PRK_Grass_Billboard_Forward
			for k, grasses in pairs( LocalPlayer().Grasses[zone] ) do
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
		end

		nextthink = CurTime() + PRK_Grass_Billboard_ShouldDrawTime
	end
end )

hook.Add( "PreDrawTranslucentRenderables", "PRK_PreDrawTranslucentRenderables_Grass", function( depth, skybox )
	if ( !PRK_ShouldDraw() ) then return end
	if ( depth or skybox ) then return end

	local zone = LocalPlayer():GetNWInt( "PRK_Zone" )

	-- Render plants
	if ( PRK_Grass_Mesh and LocalPlayer().Plants and LocalPlayer().Plants[zone] ) then
		for k, v in pairs( LocalPlayer().Plants[zone] ) do
			local col = v:GetColor()
			render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
			v:DrawModel()
		end
	end

	-- Render grass
	if ( PRK_Grass_Billboard and LocalPlayer().Grasses and LocalPlayer().Grasses[zone] ) then
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
				local grasses = LocalPlayer().Grasses[zone][key.Key]
				if ( grasses ) then
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
	end
end )
