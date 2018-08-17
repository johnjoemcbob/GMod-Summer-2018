PRK_AddItem( "Potion_Mystery", "Base_Potion", {
	PrettyName = "Mystery Potion",
	Price = 5,
	Colour = Color( 255, 255, 255, 255 ), -- Randomised in Draw
	Draw = function( info, self, pos, ang )
		if ( !pos ) then pos = self:GetPos() end
		if ( !ang ) then ang = self:GetAngles() end

		-- Randomise and lerp colour (note that this is globally for all mystery potions)
		if ( !info.TargetColour or math.Round( CurTime() * 10 ) % 10 == 0 ) then
			info.TargetColour = ColorRand()
		end
		info.Colour = LerpColour( FrameTime() * 0.2, info.Colour, info.TargetColour )

		-- Default draw with new colour
		info.base.Draw( info, self, pos, ang )

		-- Draw question marks
		local dir = ( LocalPlayer():EyePos() - pos ):GetNormal() * 13
		local newang = ang - Angle()
			newang:RotateAroundAxis( newang:Up(), 90 )
			newang:RotateAroundAxis( newang:Forward(), 90 )
			if ( self:IsPlayer() ) then
				-- newang:RotateAroundAxis( newang:Right(), -ang.y )
			else
				newang:RotateAroundAxis( newang:Right(), -dir:Angle().y )
			end
		cam.Start3D2D( pos + dir, newang, 0.1 )
			local poses = {
				Vector( 0, 100, 48 ),
				Vector( -24, 65, 24 ),
				Vector( 24, 70, 36 ),
				Vector( 50, 55, 20 ),
				Vector( 50, 120, 48 ),
				Vector( -40, 120, 30 ),
			}
			for k, pos in pairs( poses ) do
				PRK_DrawText(
					"?",
					pos.x,
					pos.y,
					Color( 0, 0, 50, 255 ),
					TEXT_ALIGN_CENTER,
					TEXT_ALIGN_CENTER,
					pos.z,
					false
				)
			end
		cam.End3D2D()
	end,
	Use = function( info, ply )
		-- Lookup all other potions and pick a random effect
		-- excluding this and base
		if ( SERVER ) then
			local possible = {}
				for name, item in pairs( PRK_Items ) do
					if (
						string.find( string.lower( name ), "potion" ) and
						name != "Potion_Mystery" and
						name != "Base_Potion"
					) then
						table.insert( possible, name )
					end
				end
			local name = possible[math.random( 1, #possible )]
			PRK_Items[name]:Use( ply )
		end

		return true
	end,
} )
