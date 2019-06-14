include( "shared.lua" )

ENT.TimeToHurt	= PRK_Enemy_TetherHurtTime

function ENT:Think()
	if ( self.TimeToHurt <= 0 ) then
		self.TimeToHurt = PRK_Enemy_TetherHurtTime
	end
	self.TimeToHurt = self.TimeToHurt - FrameTime()
end

local mat = Material( "cable/rope" )
function ENT:Draw()
	if ( !PlayerInZone( self, self.Zone ) ) then return end

	self:DrawModel()

	local target = self:GetNWEntity( "Tether" )
	-- print( target )
	if ( target and target:IsValid() and target != self ) then
		local progress = 1 - ( self.TimeToHurt / PRK_Enemy_TetherHurtTime )

		if ( !self.Points ) then
			self.Points = {}
			self.PointTargets = {}
		end

		local speed = 50
		local slow = 1
		local points = 15
		local start = self:GetPos() + Vector( 0, 0, 45 )
		local finish = target:GetPos() + Vector( 0, 0, 55 )
		local next = start
		local dist = ( finish - start )
		local border = 1
		for point = 1, points do
			self.PointTargets[point] = start + ( dist / ( points - 1 ) ) * point

			local off = ( dist / ( points - 1 ) )
			local pos = next + off
			local middist = math.min( point, points - point )
			pos = self.PointTargets[point]
			-- print( point .. " " .. middist )
			self.Points[point] = self.Points[point] or pos
			self.Points[point] = LerpVector( FrameTime() * speed / ( middist * slow ), self.Points[point], pos )
			-- draw.NoTexture()
			render.SetMaterial( mat )
			local col = Color( 255, Lerp( progress, 255, 0 ), 0, 255 )
			render.DrawBeam( next, self.Points[point], 2, 0, 0, col )
			next = self.Points[point] - dist:GetNormalized() * border
		end
	else
		self.Points = {}
		self.PointTargets = {}
		self.TimeToHurt	= PRK_Enemy_TetherHurtTime
	end
end
