
local size = 10
local NumParticles = 400

function EFFECT:Init( data )
	local vOffset = data:GetOrigin()
	self:SetPos( vOffset )

	self.Emitter = ParticleEmitter( vOffset )
		self:AddParticles()
	-- self.Emitter:Finish()
end

function EFFECT:Think()
	self:SetPos( LocalPlayer():GetPos() )
	if ( self.Emitter and IsValid( self.Emitter ) and self.Emitter:GetNumActiveParticles() < NumParticles ) then
		self:AddParticles()
	end
	return true
end

function EFFECT:Render()
end

function EFFECT:AddParticles()
	-- Set seed to be position of player
	math.randomseed( LocalPlayer():GetPos().x )

	local vOffset = self:GetPos()
	for i = 0, NumParticles - self.Emitter:GetNumActiveParticles() do
		local x = math.random( -1000, 1000 )
		local y = math.random( -1000, 1000 )
		local pos = vOffset + Vector( x, y, 0 )
			local tr = util.TraceLine( {
				start = pos + Vector( 0, 0, 10 ),
				endpos = pos - Vector( 0, 0, 1000 ),
				collisiongroup = COLLISION_GROUP_WORLD,
			} )
			pos = tr.HitPos + Vector( 0, 0, 2 )
		local particle = self.Emitter:Add( "prk_grass", pos )
		if ( particle ) then
			local dist = LocalPlayer():GetPos():Distance( pos )
			-- particle:SetVelocity( ( LocalPlayer():GetPos() - pos ) * math.random( 10, 20 ) / 10 )

			local live = 2 + math.random( 0.5, 2 )
			particle:SetLifeTime( 0 )
			particle:SetDieTime( live )

			particle:SetStartAlpha( 0 )
			particle:SetEndAlpha( 255 )

			particle:SetStartSize( size )
			particle:SetEndSize( size )
		end
	end

	-- Reset seed to be more random
	math.randomseed( CurTime() )
end
