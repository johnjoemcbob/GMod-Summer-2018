AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

list.Set( "NPC", "prk_npc_biter", {
	Name = "Prickly Biter",
	Class = "prk_npc_biter",
	Category = "Prickly"
} )

local reload = true
function ENT:Think()
	-- Autoreload helper
	if ( reload ) then
		self:OnRemove()
		self:Initialize()
		reload = false
	end
end

function ENT:Initialize()

	self:SetModel( "models/headcrabclassic.mdl" )
	self:SetModelScale( 3.2, 0 )
	self:SetMaterial( "models/debug/debugwhite", true )
	self:SetColor( PRK_Colour_Enemy_Skin )

	-- Extra visual details
	if ( CLIENT ) then
		self.Visuals = {}

		local forw_off = 12
		self:SetAngles( Angle() )
		for eye = -1, 1, 2 do
			local eye_mod = "models/XQM/Rails/gumball_1.mdl"
			local eye_pos = self:GetPos() + Vector( 1, 10 * eye, 52 )
			local eye_ang = Angle()
			local eye_sca = 0.3
			local eye_mat = "models/debug/debugwhite"
			local eye_col = PRK_Colour_Enemy_Eye

			local vis = PRK_AddModel( eye_mod, eye_pos, eye_ang, eye_sca, eye_mat, eye_col )
				vis:SetParent( self, 2 )
			table.insert( self.Visuals, vis )
		end

		local teeth = {
			{
				Vector( 9, 10, 30 ),
				Angle( 60, 200, 180 ),
				0.5,
			},
			{
				Vector( 7, -8, 30 ),
				Angle( 60, 160, 90 ),
				0.5,
			},
			{
				Vector( 8, -2, 45 ),
				Angle( -30, 180, 90 ),
				0.4,
			},
			{
				Vector( 9, 6, 45 ),
				Angle( -30, 180, 180 ),
				-- Vector( 7, 6, 46 ),
				-- Angle( -50, 180, -90 ),
				0.4,
			},
		}
		for k, tooth in pairs( teeth ) do
			local too_mod = "models/Gibs/helicopter_brokenpiece_02.mdl"
			local too_pos = self:GetPos() + tooth[1] + Vector( forw_off, 0, 0 )
			local too_ang = tooth[2]
			local too_sca = tooth[3]
			local too_mat = "models/debug/debugwhite"
			local too_col = PRK_Colour_Enemy_Tooth

			local vis = PRK_AddModel( too_mod, too_pos, too_ang, too_sca, too_mat, too_col )
				vis:SetParent( self, 2 )
			table.insert( self.Visuals, vis )
		end

		-- Mouth
		local mou_mod = "models/combine_helicopter/bomb_debris_1.mdl"
		local mou_pos = self:GetPos() + Vector( 10 + forw_off, 0, 37 )
		local mou_ang = Angle( -10, -10, -30 )
		local mou_sca = 1.2
		local mou_mat = "models/debug/debugwhite"
		local mou_col = PRK_Colour_Enemy_Mouth
		local vis = PRK_AddModel( mou_mod, mou_pos, mou_ang, mou_sca, mou_mat, mou_col )
			vis:SetParent( self, 2 )
		table.insert( self.Visuals, vis )

		-- Scale
		local sca = Vector( 1, 1, 1.5 )
		local mat = Matrix()
			mat:Scale( sca )
		self:EnableMatrix( "RenderMultiply", mat )
	end
		-- print( self:GetBoneCount() )
		-- for bone = 0, self:GetBoneCount() do
			-- print( self:GetBoneName( bone ) )
		-- end

	self.LoseTargetDist	= 2000	-- How far the enemy has to be before we lose them
	self.SearchRadius 	= 1000	-- How far to search for enemies

end

function ENT:OnRemove()
	if ( CLIENT ) then
		for k, vis in pairs( self.Visuals ) do
			if ( vis and vis:IsValid() ) then
				vis:Remove()
			end
		end
	end
end

if ( CLIENT ) then
	function ENT:Draw()
		-- self:SetAngles( self:GetAngles() + Angle( 0, 180, 0 ) )
		-- for k, vis in pairs( self.Visuals ) do
			-- vis:SetPos( vis:GetPos() + Vector( 0, 0, math.sin( CurTime() * 50 ) * 1 ) )
		-- end
		self:DrawModel()
	end
end

----------------------------------------------------
-- ENT:Get/SetEnemy()
-- Simple functions used in keeping our enemy saved
----------------------------------------------------
function ENT:SetEnemy( ent )
	self.Enemy = ent
end
function ENT:GetEnemy()
	return self.Enemy
end

----------------------------------------------------
-- ENT:HaveEnemy()
-- Returns true if we have a enemy
----------------------------------------------------
function ENT:HaveEnemy()
	-- If our current enemy is valid
	if ( self:GetEnemy() and IsValid( self:GetEnemy() ) ) then
		-- If the enemy is too far
		if ( self:GetRangeTo( self:GetEnemy():GetPos() ) > self.LoseTargetDist ) then
			-- If the enemy is lost then call FindEnemy() to look for a new one
			-- FindEnemy() will return true if an enemy is found, making this function return true
			return self:FindEnemy()
		-- If the enemy is dead( we have to check if its a player before we use Alive() )
		elseif ( self:GetEnemy():IsPlayer() and !self:GetEnemy():Alive() ) then
			return self:FindEnemy()		-- Return false if the search finds nothing
		end
		-- The enemy is neither too far nor too dead so we can return true
		return true
	else
		-- The enemy isn't valid so lets look for a new one
		return self:FindEnemy()
	end
end

----------------------------------------------------
-- ENT:FindEnemy()
-- Returns true and sets our enemy if we find one
----------------------------------------------------
function ENT:FindEnemy()
	-- Search around us for entities
	-- This can be done any way you want eg. ents.FindInCone() to replicate eyesight
	local _ents = ents.FindInSphere( self:GetPos(), self.SearchRadius )
	-- Here we loop through every entity the above search finds and see if it's the one we want
	for k, v in pairs( _ents ) do
		if ( v:IsPlayer() ) then
			-- We found one so lets set it as our enemy and return true
			self:SetEnemy( v )
			return true
		end
	end
	-- We found nothing so we will set our enemy as nil ( nothing ) and return false
	self:SetEnemy( nil )
	return false
end

----------------------------------------------------
-- ENT:RunBehaviour()
-- This is where the meat of our AI is
----------------------------------------------------
function ENT:RunBehaviour()
	-- This function is called when the entity is first spawned. It acts as a giant loop that will run as long as the NPC exists
	while ( true ) do
		-- Lets use the above mentioned functions to see if we have/can find a enemy
		if ( self:HaveEnemy() ) then
			-- Now that we have an enemy, the code in this block will run
			self.loco:FaceTowards( self:GetEnemy():GetPos() )	-- Face our enemy
			self:StartActivity( ACT_RUN )			-- Set the animation
			self.loco:SetDesiredSpeed( 300 )		-- Set the speed that we will be moving at. Don't worry, the animation will speed up/slow down to match
			self.loco:SetAcceleration( 900 )			-- We are going to run at the enemy quickly, so we want to accelerate really fast
			self:ChaseEnemy() 						-- The new function like MoveToPos.
			self.loco:SetAcceleration( 400 )			-- Set this back to its default since we are done chasing the enemy
			self:PlaySequenceAndWait( "charge_miss_slide" )	-- Lets play a fancy animation when we stop moving
			self:StartActivity( ACT_IDLE )			--We are done so go back to idle
			-- Now once the above function is finished doing what it needs to do, the code will loop back to the start
			-- unless you put stuff after the if statement. Then that will be run before it loops
		else
			-- Since we can't find an enemy, lets wander
			-- Its the same code used in Garry's test bot
			-- self:StartActivity( ACT_WALK )			-- Walk anmimation
			-- self.loco:SetDesiredSpeed( 200 )		-- Walk speed
			-- self:MoveToPos( self:GetPos() + Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), 0 ) * 400 ) -- Walk to a random place within about 400 units ( yielding )
			-- self:StartActivity( ACT_IDLE )
		end
		-- At this point in the code the bot has stopped chasing the player or finished walking to a random spot
		-- Using this next function we are going to wait 2 seconds until we go ahead and repeat it
		coroutine.wait( 2 )

	end

end

----------------------------------------------------
-- ENT:ChaseEnemy()
-- Works similarly to Garry's MoveToPos function
-- except it will constantly follow the
-- position of the enemy until there no longer
-- is one.
----------------------------------------------------
function ENT:ChaseEnemy( options )

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tolerance or 20 )
	path:Compute( self, self:GetEnemy():GetPos() )		-- Compute the path towards the enemies position

	if ( !path:IsValid() ) then return "failed" end

	while ( path:IsValid() and self:HaveEnemy() ) do

		if ( path:GetAge() > 0.1 ) then					-- Since we are following the player we have to constantly remake the path
			path:Compute( self, self:GetEnemy():GetPos() )-- Compute the path towards the enemy's position again
		end
		path:Update( self )								-- This function moves the bot along the path

		if ( options.draw ) then path:Draw() end
		-- If we're stuck, then call the HandleStuck function and abandon
		if ( self.loco:IsStuck() ) then
			self:HandleStuck()
			return "stuck"
		end

		coroutine.yield()

	end

	return "ok"

end
