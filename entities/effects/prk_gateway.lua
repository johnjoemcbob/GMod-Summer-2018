
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
		if ( instream ) then
			local mult = PRK_Gateway_TravelTime * 2
			speed = speed / mult
			dietime = dietime * mult
		end
	local particles = segs
	local circ = PRK_GetCirclePoints( 0, 0, radius, particles, math.random( 0, 360 ) )
	local emitter = ParticleEmitter( origin, true )
		for i = 1, particles do
			local pos = right * circ[i].x + up * circ[i].y

			local particle = emitter:Add( PRK_Material_Square, origin + pos * 6 )
			if ( particle ) then
				particle:SetVelocity( -pos * math.random( 5, 15 ) / dietime + dir * speed )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( dietime )

				particle:SetStartAlpha( 0 )
				particle:SetEndAlpha( 255 )

				local Size = size
				particle:SetStartSize( Size )
				particle:SetEndSize( 0 )

				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -2, 2 ) )

				particle:SetAirResistance( 10 )

				particle:SetColor( 255, 255, 255 )

				particle:SetAngles( -pos:GetNormalized():Angle() + Angle( 0, 180, 0 ) )
				if ( right:Distance( Vector( 0, 1, 0 ) ) < 0.1 ) or ( right:Distance( Vector( 0, -1, 0 ) ) < 0.1 ) then
					particle:SetAngles( -pos:GetNormalized():Angle() )
				end
			end
		end
		emitter:SetNoDraw( true )
	timer.Simple( dietime, function()
		emitter:Finish()
	end )

	table.insert( PRK_Gateway_Emitters, emitter )
end

function EFFECT:Think()
	-- return false
end

function EFFECT:Render()
	
end
