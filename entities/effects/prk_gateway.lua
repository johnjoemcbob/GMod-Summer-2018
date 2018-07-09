
-- Materials
PRK_Material_Square = Material( "square.png", "noclamp smooth" )

function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = data:GetNormal()
	local radius = data:GetRadius()
	local segs = data:GetFlags()

	local speed = 400
	local size = radius * 0.75
	local dietime = 1.5
	local particles = segs
	local circ = PRK_GetCirclePoints( 0, 0, radius, particles, math.random( 0, 360 ) )
	local emitter = ParticleEmitter( origin, true )
		for i = 1, particles do
			local pos = Vector( circ[i].x, 0, circ[i].y )

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

				particle:SetAngles( -pos:GetNormalized():Angle() ) -- Woah
				particle:SetAngles( -pos:GetNormalized():Angle() + Angle( 0, 180, 0 ) ) -- WOAH
				-- particle:SetAngleVelocity( Angle( math.Rand( -160, 160 ), math.Rand( -160, 160 ), math.Rand( -160, 160 ) ) )
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
