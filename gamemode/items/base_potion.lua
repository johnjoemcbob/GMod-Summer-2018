PRK_AddItem( "Base_Potion", "", {
	PrettyName = "Potion Base",
	KillName = "POTION",
	UseLabel = "TAKE",
	Colour = Color( 0, 0, 0, 255 ),
	InitShared = function( info, self )
		self.KillName = info.KillName
		self.UseLabel = info.UseLabel
	end,
	InitServer = function( info, self )
		self:SetColor( info.Colour )
		self:SetModel( "models/props_junk/TrafficCone001a.mdl" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:PhysWake()

		self:SetPos( self:GetPos() + Vector( 0, 0, 15 ) )
	end,
	InitClient = function( info, self )
		self:DrawShadow( false )
		self.RenderGroup = RENDERGROUP_BOTH
	end,
	Draw = function( info, self, pos, ang )
		if ( !pos ) then pos = self:GetPos() end
		if ( !ang ) then ang = self:GetAngles() end

		local scale = 1

		local dir = ( LocalPlayer():EyePos() - pos ):GetNormal()
		-- print( dir )
		-- print( ang:Up() )
		local rotang = ang - Angle()
			rotang:RotateAroundAxis( ang:Forward(), 180 )
		PRK_RenderCachedModel(
			"models/XQM/Rails/funnel.mdl",
			pos + ang:Up() * scale * 2 - dir * 3,
			rotang,
			Vector( 1, 1, 1.5 ) * scale * 0.2,
			"models/shiny",
			Color( 150, 150, 200, 100 ),
			RENDERGROUP_TRANSLUCENT
		)

		local rotang = ang - Angle()
			rotang:RotateAroundAxis( ang:Forward(), 180 )
		PRK_RenderCachedModel(
			"models/XQM/Rails/funnel.mdl",
			pos,
			rotang,
			Vector( 1, 1, 1.5 ) * scale * 0.18,
			"models/shiny",
			info.Colour
		)

		local rotang = ang - Angle()
		PRK_RenderCachedModel(
			"models/hunter/blocks/cube025x025x025.mdl",
			pos + ang:Up() * scale * 1,
			rotang,
			Vector( 1, 1, 0.4 ) * scale * 0.9,
			"models/shiny",
			Color( info.Colour.r * 2, info.Colour.g * 2, info.Colour.b * 2, 255 )
		)

		local rotang = ang - Angle()
		PRK_RenderCachedModel(
			"models/mechanics/wheels/wheel_speed_72.mdl",
			pos + ang:Up() * scale * -14.5,
			rotang,
			Vector( 1, 1, 0.4 ) * scale * 0.3,
			"models/shiny",
			Color( 150, 150, 200, 255 )
		)
	end,
	Use = function( info, ply )
		-- Drink sound
		ply:EmitSound( "npc/barnacle/barnacle_gulp1.wav", 75, math.random( 150, 200 ) )

		-- Debris effect/sound (slightly delayed so drink can be heard)
		timer.Simple( 0.3, function()
			ply:EmitSound( "physics/glass/glass_pottery_break" .. math.random( 1, 4 ) .. ".wav", 75, math.random( 120, 140 ), 0.2 )

			if ( SERVER ) then
				local models = {
					"models/props_junk/glassjug01_chunk01.mdl",
					"models/props_junk/glassjug01_chunk02.mdl",
					"models/props_junk/glassjug01_chunk03.mdl",
				}
				local dir = ply:EyeAngles():Forward()
				local pos = ply:EyePos() + dir * 20 + ply:EyeAngles():Up() * -10
				for i = 1, 3 do
					local debris = PRK_CreateEnt(
						"prk_debris",
						models[i],
						pos,
						AngleRand(),
						true
					)
					-- debris:SetMaterial( PRK_Material_Base, true )
					debris:SetColor( Color( 150, 150, 200, 10 ) )
					debris:SetRenderMode( RENDERMODE_TRANSALPHA )
					local phys = debris:GetPhysicsObject()
					if ( phys and phys:IsValid() ) then
						phys:AddVelocity( dir * 200 + VectorRand() * 100 )
					end
				end
			end
		end )

		return true
	end,
	SendData = function( info, self )
		-- To send any info from server to client
	end,
} )
