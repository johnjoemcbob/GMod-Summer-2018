
-- Materials
PRK_Material_Square = Material( "square.png", "noclamp smooth" )

function EFFECT:Init( data )
	local origin = data:GetOrigin()
	local dir = data:GetNormal()
		dir = dir + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) ) * 0.1
	local col = data:GetEntity():GetColor()

	local emitter = ParticleEmitter( origin, true )
		local gravity = 3
		local particles = 128 --16
		local startsize = { 2, 3 }
		local endsize = { 4, 8 }
		local existtime = 1
		for i = 0, particles do
			local speed = math.random( 10, 20 ) * 25 --100
			local speed_rnd = math.random( 10, 20 ) * 2
			local pos = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )
			local dir_rnd = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )

			local particle = emitter:Add( PRK_Material_Square, origin + pos * 6 )
			if ( particle ) then
				particle:SetVelocity( pos + dir * speed + dir_rnd * speed_rnd )

				particle:SetLifeTime( 0 )
				particle:SetDieTime( existtime )

				particle:SetStartAlpha( 255 )
				particle:SetEndAlpha( 0 )

				local startsize = math.Rand( startsize[1], startsize[2] )
				local endsize = math.Rand( endsize[1], endsize[2] )
				particle:SetStartSize( startsize )
				particle:SetEndSize( endsize )

				particle:SetRoll( math.Rand( 0, 360 ) )
				particle:SetRollDelta( math.Rand( -2, 2 ) )

				particle:SetGravity( Vector( 0, 0, -speed ) * gravity )

				particle:SetColor( col.r, col.g, col.b )

				particle:SetCollide( true )
				particle:SetCollideCallback( function( part, hitpos, hitnormal )
					-- print( "hi" )
					-- util.Decal( "PaintSplatPink", hitpos + hitnormal, hitpos - hitnormal )
					if ( math.random( 1, 100 ) < 10 ) then
						PRK_Decal( hitpos, col )
					end
				end )

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
