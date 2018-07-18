
-- Materials
PRK_Material_Square = Material( "square.png", "noclamp smooth" )

function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = data:GetNormal()

	local emitter = ParticleEmitter( origin, true )
		local particles = 24 --16
		local startsize = { 1, 4 }
		local endsize = { 0, 0 }
		local speed = math.random( 1, 2 ) * 50 --100
		local existtime = 0.5 --1
		for i = 0, particles do
			local pos = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )

			local particle = emitter:Add( PRK_Material_Square, origin + pos * 6 )
			if ( particle ) then
				particle:SetVelocity( pos + dir * speed )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( existtime )

				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 255 )

				local startsize = math.Rand( startsize[1], startsize[2] )
				local endsize = math.Rand( endsize[1], endsize[2] )
				particle:SetStartSize( startsize )
				particle:SetEndSize( endsize )

				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -2, 2 ) )

				particle:SetAirResistance( speed / 2 )
				particle:SetGravity( Vector( 0, 0, -speed ) )

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
