
-- Materials
PRK_Material_Square = Material( "square.png", "noclamp smooth" )

function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = data:GetNormal()
	local radius = data:GetRadius()
	local segs = data:GetMagnitude()
	local instream = data:GetFlags() == 1

	local up = Vector( 0, 0, 1 )
	local right = up:Cross( dir )

	local speed = 400
	local size = radius * 0.75
	local dietime = 1.5
	local startsize = size
	local endsize = 0
	local close = 1
		if ( instream ) then
			startsize = 0
			endsize = size
			close = -10
			radius = 1
		end
	local particles = segs
	local circ = PRK_GetCirclePoints( 0, 0, radius, particles, math.random( 0, 360 ) )
	local emitter = ParticleEmitter( origin, true )
		for i = 1, particles do
			local pos = right * circ[i].x + up * circ[i].y

			local particle = emitter:Add( PRK_Material_Square, origin + pos * 6 )
			if ( particle ) then
				particle:SetVelocity( -close * pos * math.random( 5, 15 ) / dietime + dir * speed )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( dietime )

				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 255 )

				particle:SetStartSize( startsize )
				particle:SetEndSize( endsize )

				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -2, 2 ) )

				particle:SetAirResistance( 10 )

				local col = PRK_HUD_Colour_Shadow
				particle:SetColor( col.r, col.g, col.b )

				particle:SetAngles( -pos:GetNormalized():Angle() + Angle( 0, 180, 0 ) )
				if ( right:Distance( Vector( 0, 1, 0 ) ) < 0.1 ) or ( right:Distance( Vector( 0, -1, 0 ) ) < 0.1 ) then
					particle:SetAngles( -pos:GetNormalized():Angle() )
				end
			end
		end
		emitter:SetNoDraw( true )
	timer.Simple( dietime, function()
		if ( emitter and emitter:IsValid() ) then
			table.RemoveByValue( PRK_Gateway_Emitters, emitter )
			emitter:Finish()
		end
	end )

	table.insert( PRK_Gateway_Emitters, emitter )
end

function EFFECT:Think()
	-- return false
end

function EFFECT:Render()
	
end
