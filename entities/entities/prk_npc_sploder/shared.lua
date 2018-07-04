AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

list.Set( "NPC", "prk_npc_sploder", {
	Name = "Prickly Sploder",
	Class = "prk_npc_sploder",
	Category = "Prickly"
} )

sound.Add(
	{ 
		name = "prk_sploder_loop",
		channel = CHAN_ITEM,
		level = 85,
		volume = 0.25,
		pitch = { 230, 255 },
		sound = "npc/scanner/scanner_siren2.wav"
	}
)

function ENT:Initialize()
	self:SetModel( "models/headcrab.mdl" )
	self:SetModelScale( 3, 0 )
	self:SetMaterial( "models/debug/debugwhite", true )
	self:SetColor( PRK_Colour_Enemy_Skin )

	-- Extra visual details
	if ( CLIENT ) then
		self.Visuals = {}

		local forw_off = 12
		self:SetAngles( Angle() )
		local baseheight = 40
		local pos = {
			Vector( 1, 10, baseheight ),
			Vector( 1, -10, baseheight ),
			Vector( 10, 1, baseheight ),
			Vector( -10, 1, baseheight ),
			Vector( 0, 0, baseheight + 20 ),
		}
		for k, v in pairs( pos ) do
			local eye_mod = "models/XQM/Rails/gumball_1.mdl"
			local eye_pos = v
			local eye_ang = Angle()
			local eye_sca = 0.8 + math.random( 10, 50 ) / 100
			local eye_mat = "models/debug/debugwhite"
			local eye_col = Color(
				PRK_Colour_Enemy_Eye.r * ( 0.7 + math.random( 10, 100 ) / 100 ),
				PRK_Colour_Enemy_Eye.g,
				PRK_Colour_Enemy_Eye.b,
				PRK_Colour_Enemy_Eye.a
			)

			local vis = PRK_AddModel( eye_mod, eye_pos, eye_ang, eye_sca, eye_mat, eye_col )
				vis:SetParent( self, 2 )
			table.insert( self.Visuals, vis )
		end

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

	self.Speed = 500
	self.Coins = 3
	self.SplodeRange = 200

	local length = 1.5
	local function play()
		if ( self and self:IsValid() ) then
			self:EmitSound( "prk_sploder_loop" )
			timer.Simple( length, function()
				play()
			end )
		end
	end
	play()
end

function ENT:OnKilled( dmginfo )
	self:Remove()
end

function ENT:OnRemove()
	if ( CLIENT ) then
		for k, vis in pairs( self.Visuals ) do
			if ( vis and vis:IsValid() ) then
				vis:Remove()
			end
		end
	end

	if ( SERVER ) then
		local debris = math.random( 3, 5 )
		for i = 1, debris do
			local prop = PRK_CreateEnt(
				"prk_debris", "models/XQM/Rails/gumball_1.mdl",
				self:GetPos() + Vector( 0, 0, 35 ),
				AngleRand(),
				true
			)
				prop:SetMaterial( "models/debug/debugwhite", true )
				prop:SetColor( PRK_Colour_Enemy_Eye )
				local phys = prop:GetPhysicsObject()
				if ( phys and phys:IsValid() ) then
					phys:SetVelocity( ( Vector( 0, 0, 1 ) + VectorRand() ) * 1000 )
				end
			timer.Simple( 5, function() prop:Remove() end )
		end

		-- Only give coins if the player killed it before it exploded
		if ( !self.ToRemove ) then
			GAMEMODE:SpawnCoins( self:GetPos(), self.Coins )
		end
	end

	self:StopSound( "prk_sploder_loop" )
end

if ( CLIENT ) then
	function ENT:Draw()
		-- self:SetAngles( self:GetAngles() + Angle( 0, 180, 0 ) )
		for k, vis in pairs( self.Visuals ) do
			vis:SetPos( self:GetPos() + vis.Pos + Vector( 0, 0, ( ( math.random( 10, 100 ) / 100 ) + math.sin( CurTime() * 1 ) ) * 4 ) )
		end
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
	local possibletargets = {}
	for k, v in pairs( _ents ) do
		if ( v:IsPlayer() ) then
			-- Check if there is line of sight between the enemy and the player
			local posply = v:EyePos() + Vector( 0, 0, -5 )
			local dir = ( posply - self:GetPos() ):GetNormalized()
			local trdata = {
				start = self:GetPos() + dir * 50,
				endpos = posply + dir * 50,
			}
			local tr = util.TraceLine( trdata)
			if ( tr.Entity == v ) then
				table.insert( possibletargets, v )
			end
		end
	end
	if ( #possibletargets > 0 ) then
		-- We found one so lets set it as our enemy and return true
		self:SetEnemy( possibletargets[math.random( 1, #possibletargets ) ] )
		return true
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
			self.loco:SetDesiredSpeed( self.Speed )		-- Set the speed that we will be moving at. Don't worry, the animation will speed up/slow down to match
			self.loco:SetAcceleration( self.Speed )			-- We are going to run at the enemy quickly, so we want to accelerate really fast
			self:ChaseEnemy() 						-- The new function like MoveToPos.
			if ( self.ToRemove ) then
				self:Remove()
				return
			end
		end

		coroutine.wait( 1 )
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

		-- If near any enemy, bite
		for k, v in pairs( player.GetAll() ) do
			local dist = v:GetPos():Distance( self:GetPos() )
			if ( dist <= self.SplodeRange ) then
				self:SetEnemy( v )
				self:Attack( v )
				-- self:StartActivity( ACT_LEAP )
				return "ok"
			end
		end

		coroutine.yield()

	end

	return "ok"

end

function ENT:Attack( victim )
	-- Spawn explosion
	PRK_Explosion( self, self:GetPos() + Vector( 0, 0, 30 ), self.SplodeRange )

	-- Flag for removal
	self.ToRemove = true
end
