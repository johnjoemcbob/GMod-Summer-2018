
-- Materials
PRK_Material_Square = Material( "square.png", "noclamp smooth" )

function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = data:GetNormal()

	local emitter = ParticleEmitter( origin, true )
		local particles = 16
		for i = 0, particles do
			local pos = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )

			local particle = emitter:Add( PRK_Material_Square, origin + pos * 6 )
			if ( particle ) then
				particle:SetVelocity( pos + dir * 100 )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( 1 )

				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 255 )

				local Size = math.Rand( 1, 2 )
				particle:SetStartSize( Size )
				particle:SetEndSize( 0 )

				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -2, 2 ) )

				particle:SetAirResistance( 100 )
				particle:SetGravity( Vector( 0, 0, -100 ) )

				particle:SetColor( 255, 255, 255, 255 )

				particle:SetCollide( true )

				particle:SetAngleVelocity( Angle( math.Rand( -160, 160 ), math.Rand( -160, 160 ), math.Rand( -160, 160 ) ) )
			end
		end
	emitter:Finish()
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end
