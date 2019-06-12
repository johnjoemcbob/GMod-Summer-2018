include( "shared.lua" )

PRK_Material_Grass = Material( "prk_grass.png", "noclamp smooth" )
PRK_Material_Grass_Multiple = Material( "prk_grass_multiple.png", "noclamp smooth" )

net.Receive( "PRK_Floor_Grass_Clear", function( len, ply )
	LocalPlayer().Grasses = {}
end )

net.Receive( "PRK_Floor_Grass", function( len, ply )
	local zone = net.ReadFloat()
	local pos = net.ReadVector()
	local min = net.ReadVector()
	local max = net.ReadVector()

	local sca = Vector( max.x / PRK_Plate_Size * 2, max.y / PRK_Plate_Size * 2, 1 )

	-- Grass billboards
	local between = 1
	local function creategrass()
		if ( !LocalPlayer().Grasses ) then
			LocalPlayer().Grasses = {}
		end
		if ( zone != nil and LocalPlayer().Grasses ) then
			if ( !LocalPlayer().Grasses[zone] ) then
				LocalPlayer().Grasses[zone] = {}
			end

			-- local pos = VectorRound( pos )
			local grasscount = PRK_Grass_Billboard_Count * ( sca.x + sca.y )
			local grasses = {}
				for i = 1, grasscount do
					table.insert( grasses, {
						pos + Vector( math.random( min.x, max.x ), math.random( min.y, max.y ), 0 ),
						Angle( 0, math.random( 0, 360 ), 0 ):Forward(),
						math.random( 10, 50 ) / 10,
					} )
				end
			LocalPlayer().Grasses[zone][pos] = grasses
		else
			timer.Simple( between, function() creategrass() end )
		end
	end
	creategrass()
end )

net.Receive( "PRK_Floor_Plant", function( len, ply )
	local zone = net.ReadFloat()
	local count = net.ReadFloat()
	local plants = {}
	for i = 1, count do
		table.insert( plants, {
			ind = net.ReadFloat(), -- Index
			pos = net.ReadVector(),
			ang = net.ReadAngle(),
			sca = net.ReadFloat(),
			col = net.ReadFloat(), -- Index
		} )
	end

	local function try()
		if ( !LocalPlayer().Plants ) then
			LocalPlayer().Plants = {}
		end
		-- Couldn't initialise, wait
		if ( !LocalPlayer().Plants ) then
			timer.Simple( 1, function()
				try()
			end )
		else
			LocalPlayer().Plants[zone] = plants

			PRK_Floor_InitializePlantModels()
		end
	end
	try()
end )

function PRK_Floor_InitializePlantModels()
	if ( PRK_Floor_Models[1].Ent and PRK_Floor_Models[1].Ent:IsValid() ) then return end

	-- local mat = PRK_Material_Base
	for k, plant in pairs( PRK_Floor_Models ) do
		-- local ent = PRK_AddModel( plant[1], Vector(), Angle(), 1, mat, Color( 255, 255, 255, 255 ) )
			-- ent:SetNoDraw( true )
		plant.Ent = PRK_GetCachedModel( plant[1] )
	end
end

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
end

local disruptors_temp = {}
function PRK_TempPlantDistruptor( pos, vel, rng, time, prt )
	-- Add
	local disruptor = { cls = "temp", pos = pos, rng = rng, vel = vel, prt = ( prt != false ) }
	table.insert( disruptors_temp, disruptor )

	-- Remove timer
	timer.Simple( time, function()
		table.RemoveByValue( disruptors_temp, disruptor )
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
					table.insert( disruptors, {
						ent = v,
						cls = v:GetClass(),
						pos = v:GetPos(),
						vel = v:GetVelocity(),
						prt = true,
					} )
				end
			end
			table.Add( disruptors, disruptors_temp )
			LocalPlayer().NextRefreshDisruptors = CurTime() + PRK_Grass_Mesh_DisruptTime
		end
		local specialcases = {}
			specialcases["prk_gateway"] = function( dis, moving )
				return true, 300, dis.ent.Scale / 2, -1, false
			end
			specialcases["prk_debris"] = function( dis, moving )
				if ( dis.ent:GetNWBool( "Explosion" ) ) then
					return true, 400, -1, 0, false
				end
				return moving, nil, 1, 0, true
			end
		for _, dis in pairs( disruptors ) do
			if ( !dis.ent or dis.ent:IsValid() ) then
				local effects = dis.prt
				local overridedist = nil
				local speed = dis.vel:Length()
				local moving = speed > 100
				local scaleoff = 0
				local magnitude = 1
					-- Special case for gateways
					local spc = specialcases[dis.cls]
					if ( spc ) then
						moving, overridedist, magnitude, scaleoff, effects = spc( dis, moving )
					end
				-- print( speed )
				if ( moving ) then
					for k, plant in pairs( LocalPlayer().Plants[zone] ) do
						if ( plant and ( !plant.NextTouch or plant.NextTouch <= CurTime() ) ) then
							local dist = dis.pos:Distance( plant.pos )
							local maxdist = dis.rng or PRK_Grass_Mesh_DisruptorInnerRange
								if ( overridedist ) then
									maxdist = overridedist
								end
							local close = dist < maxdist
							if ( close ) then
								local forward = ( dis.pos + dis.vel - plant.pos ):GetNormal()

								if ( effects ) then
									-- Sound effect
									-- ent:EmitSound( "npc/combine_soldier/gear" .. math.random( 4, 6 ) .. ".wav", 55, 170 + 30 / PRK_Speed * speed + math.random( -10, 10 ), 0.1 )

									-- Particle burst
									local effectdata = EffectData()
										local pos = dis.pos - forward
										effectdata:SetOrigin( pos )
										effectdata:SetNormal( -forward )
										-- effectdata:SetColor( ent:GetColor() )
									util.Effect( "prk_hit", effectdata )
								end

								-- Lean away from entity
								local up = Vector( 0, 0, 1 )
								local right = up:Cross( forward )
								local ang = Angle( plant.ang.p, plant.ang.y, plant.ang.r )
									ang:RotateAroundAxis( right, magnitude * dist / maxdist * ( 50 + math.random( -10, 30 ) ) )
								plant.TargetAngles = ang

								-- Bounce up/down scale
								plant.TargetScaleOffset = 3 * magnitude + scaleoff

								-- Delay next
								-- plant.NextTouch = CurTime() + 1
							end
						end
					end
				end
			end
		end

		-- Lerp plants
		for k, plant in pairs( LocalPlayer().Plants[zone] ) do
			-- Lerp angles
			if ( plant.CurrentAng and plant.TargetAngles ) then
				local speed = 5
				local ang = LerpAngle( FrameTime() * speed, plant.CurrentAng, plant.TargetAngles )
				plant.CurrentAng = ang
				plant.TargetAngles = plant.ang
			end

			-- Lerp scale
			if ( plant.TargetScaleOffset ) then
				local speed = 10
				local scalemulthori = 0.1
				local scalemultvert = -0.2
				plant.TargetScaleOffset = math.Approach( plant.TargetScaleOffset, 0, FrameTime() * speed )
				local scaleoffset = plant.TargetScaleOffset - 2
					if ( scaleoffset < -1 ) then
						scaleoffset = ( 1 - scaleoffset ) - 3
					end
				local sca = PRK_Floor_Models[plant.ind][4] + Vector( scaleoffset * scalemulthori, scaleoffset * scalemulthori, scaleoffset * scalemultvert )
				plant.Scale = sca * plant.sca

				-- End scale
				if ( plant.TargetScaleOffset == 0 ) then
					plant.TargetScaleOffset = nil
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
		for k, plant in pairs( LocalPlayer().Plants[zone] ) do
			local ent = PRK_Floor_Models[plant.ind].Ent
				if ( !ent or !ent:IsValid() ) then
					PRK_Floor_InitializePlantModels()
					return
				end
			ent:SetMaterial( PRK_Material_Base )
			local col = PRK_Floor_Colours[plant.col]
			render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
				ent:SetPos( plant.pos )
				if ( !plant.CurrentAng ) then
					plant.CurrentAng = plant.ang
				end
				ent:SetAngles( plant.CurrentAng )
				if ( !plant.Scale ) then
					plant.Scale = PRK_Floor_Models[plant.ind][4] * plant.sca
				end
				local mat = Matrix()
					mat:Scale( plant.Scale )
				ent:EnableMatrix( "RenderMultiply", mat )
				ent:SetupBones()

				ent:DrawModel()
			render.SetColorModulation( 1, 1, 1 )
		end
	end

	-- Render grass
	-- print( "Billboard: " .. tostring( PRK_Grass_Billboard ) )
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
