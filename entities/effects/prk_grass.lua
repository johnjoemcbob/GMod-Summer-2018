
-- Materials
PRK_Material_Grass = Material( "prk_grass.png", "noclamp smooth" )

function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = data:GetNormal()

	local emitter = ParticleEmitter( origin, true )
		local particles = math.random( 1, 5 )
		local size = 8
		for i = 0, particles do
			local pos = VectorRand()

			local particle = emitter:Add( PRK_Material_Grass, origin + pos * 20 )
			if ( particle ) then
				local rnd = Vector( math.random( -1, 1 ), math.random( -1, 1 ), 0 ) / 2
				particle:SetVelocity( pos + ( dir + rnd ) * 150 )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( 5 )

				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )

				particle:SetStartSize( size )
				particle:SetEndSize( size )

				particle:SetAngles( Angle( 0, math.random( 0, 360 ), -90 ) )

				particle:SetGravity( Vector( 0, 0, -500 ) )

				particle:SetColor( PRK_Grass_Colour.r, PRK_Grass_Colour.g, PRK_Grass_Colour.b )

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
