PRK_AddItem( "Knife", "", {
	PrettyName = "Knife",
	KillName = "KNIFE",
	UseLabel = "TAKE",
	Price = 30,
	Cooldown = 0.5,
	ThumbOffset = Vector( 0, 5, -10 ),
	Colour = Color( 0, 0, 0, 255 ),
	Range = 75,
	Radius = 50,
	InitShared = function( info, self )
		self.KillName = info.KillName
		self.UseLabel = info.UseLabel
	end,
	InitServer = function( info, self )
		self:SetColor( info.Colour )
		self:SetModel( "models/props_phx/construct/wood/wood_boardx1.mdl" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:PhysWake()

		self:SetPos( self:GetPos() + Vector( 0, 0, 15 ) )
	end,
	InitClient = function( info, self )
		self:DrawShadow( false )
	end,
	Draw = function( info, self, pos, ang )
		if ( !pos ) then pos = self:GetPos() end
		if ( !ang ) then ang = self:GetAngles() end

		local scale = 1

		pos = pos + ang:Up() * 2
		ang:RotateAroundAxis( ang:Up(), -90 )
		local rotang = ang - Angle()
		PRK_RenderCachedModel(
			"models/props_c17/TrapPropeller_Lever.mdl",
			pos + ang:Right() * -5,
			rotang,
			Vector( 1.5, 0.75, 0.4 ) * scale * 2,
			"models/shiny",
			Color( 200, 150, 100, 255 )
		)

		local rotang = ang - Angle()
			rotang:RotateAroundAxis( ang:Up(), -20 )
		PRK_RenderCachedModel(
			"models/props_c17/TrapPropeller_Blade.mdl",
			pos + ang:Forward() * 1.4,
			rotang,
			Vector( 1, 1, 0.1 ) * scale * 0.3,
			"models/shiny",
			Color( 150, 150, 200, 255 )
		)
	end,
	Use = function( info, ply )
		if ( CLIENT ) then
			local time = info.Cooldown / 2
			local backward = math.random( 1, 2 ) == 1 and 1 or -1

			-- Plant disruption
			local pos = ply:EyePos() + ply:EyeAngles():Forward() * 50
			PRK_TempPlantDistruptor( pos, ply:EyeAngles():Right() * backward * 1500, 100, time, false )

			-- Show swipe line on HUD
			local start = Vector( ScrW() / 7, ScrH() - ScrH() / 3 ) + VectorRand() * 10
			local finis = Vector( ScrW() - ScrW() / 7, ScrH() / 3 ) + VectorRand() * 10
				-- Randomly other direction
				if ( backward == -1 ) then
					local temp = start.x
					start.x = finis.x
					finis.x = temp
				end
			local starttime = CurTime()
			hook.Add( "HUDPaint", "PRK_HUDPaint_Item_Knife", function()
				-- Get effect time progress
				local prog = math.min( 1, ( CurTime() - starttime ) / time )
				-- A slash across the screen
				local dir = { x = 1, y = 0.95 }
				local points = {}
					local segs = 20
					for seg = 1, segs do
						table.insert( points, {
							x = start.x + ( finis.x - start.x ) * seg / segs,
							y = start.y + ( finis.y - start.y ) * seg / segs,
							width = 2 * math.abs( prog / ( seg - segs * prog ) ),
						} )
					end
				draw.SetDrawColor( PRK_HUD_Colour_Main )
				draw.Line( dir, points )
			end )
			timer.Simple( time, function()
				hook.Remove( "HUDPaint", "PRK_HUDPaint_Item_Knife" )
			end )
		end
		if ( SERVER ) then
			-- local trace = { start = ply:EyePos(), endpos = ply:EyePos() + ply:EyeAngles():Forward() * info.Range, filter = ply }
			-- local tr = util.TraceEntity( trace, ply )
			-- if ( tr.Entity and tr.Entity:IsValid() ) then
				-- tr.Entity:TakeDamage( 1, ply, ply )
			-- end
			for k, ent in pairs( ents.FindInSphere( ply:EyePos() + ply:EyeAngles():Forward() * info.Range, info.Radius ) ) do
				if ( ent != ply ) then
					ent:TakeDamage( 1, ply, ply )
				end
			end
		end
		ply:EmitSound( "weapons/iceaxe/iceaxe_swing1.wav", 75, math.random( 150, 200 ) )

		return false
	end,
	SendData = function( info, self )
		-- To send any info from server to client
	end,
} )
