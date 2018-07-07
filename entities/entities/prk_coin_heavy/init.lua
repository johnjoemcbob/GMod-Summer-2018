AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

local function trypickup( ent, colent )
	if ( colent:IsPlayer() and colent:Alive() ) then
        -- Calculate fractional wealth multiplier.
        local wealthstack = PRK_Buff_Get(colent, PRK_BUFFTYPE_PLAYER_WEALTH)
        -- Wealth Multiplier adds 10% extra currency on coin pickup.
        -- It's not applied to the player straight away, instead added to a fractional value.
        -- If the stored fractional value exceeds 1.0, then that additional money is added to the player's
        -- inventory. 
        -- This means that with a PRK_BUFFTYPE_PLAYER_WEALTH stack of 1:
        --    * Each coin is worth 1.1.
        --    * Only 1.0 currency is added on pickup. 0.1 is added to the player's invisible fractional value.
        --    * This goes on: the 2nd coin adds 1.0 currency, and the fractional value is now 0.2. etc.
        --    * At the 10th coin, the player picks it up and gets 1.0 currency. The fractional value rolls over and
        --    * an additional 1.0 is then added to the player's inventory. The fractional value is reduced by 1.0.
        --
        --
        -- The upshot of all this is that we don't need to worry about the player *seeing* their money as a fraction.
        -- But they still receive the bonus wealth multiplier.
        
        local totalmoney = (1.0 + (0.1 * wealthstack)) * 1.0
        local money_fract = math.fmod(totalmoney, 1)
        local money_whole = totalmoney - money_fract
        local money_fract_rollover = 0
    
		colent:SetNWInt( "PRK_Money", colent:GetNWInt( "PRK_Money" ) + money_whole )
        colent:SetNWInt( "PRK_MoneyFract", colent:GetNWInt( "PRK_MoneyFract" ) + money_fract)
        
        while(colent:GetNWInt( "PRK_MoneyFract" ) >= 1.0) do
            colent:SetNWInt( "PRK_MoneyFract", colent:GetNWInt( "PRK_MoneyFract" ) - 1.0)
            money_fract_rollover = money_fract_rollover + 1
        end
        
        -- Uncomment for debug output, and see for yourself!
      --print ("Wealth Value Picked Up: " .. tostring(totalmoney))
      --print ("Fractional Part: " .. tostring(money_fract))
      --print ("Whole Part: " .. tostring(money_whole))
      --print ("Total Fractional Collected: " .. tostring(colent:GetNWInt( "PRK_MoneyFract" )))
      --print ("Money Fract Rollover: " .. tostring(money_fract_rollover))
      
        -- [todo] play some sparkle effect / bonus sound when rollover > 1
        -- Like in Divinity 2 when you have the loot luck bonus 
        -- if (money_fract_rollover > 0) then
        --      confetti burst, party_horn.wav
        -- end
        
        colent:SetNWInt( "PRK_Money", colent:GetNWInt( "PRK_Money" ) + money_fract_rollover )

		local chain = PRK_EmitChainPitchedSound(
			colent:Nick() .. "_PRK_Coin_Pickup",
			colent,
			"friends/friend_join.wav",
			75,
			1,
			170,
			10,
			0.5,
			1,
			function( self )
				colent:EmitSound( "items/medshot4.wav", 75, 255 )
				-- SendKeyValue( colent, "PRK_Money_Add_End", "true" )
				colent:SetNWInt( "PRK_Money_Add", 0 )
			end
		)
		-- SendKeyValue( colent, "PRK_Money_Add", chain )
        -- Don't forget, we want the player to see that extra 1 or 2 currency they picked up with fractional rollover!
		colent:SetNWInt( "PRK_Money_Add", chain + money_fract_rollover )

		ent:Remove()
	end
end

local function tryjump( ent )
	if ( ent and ent:IsValid() ) then
		-- Play sound
		-- ent:EmitSound( "npc/manhack/grind" .. math.random( 1, 5 ) .. ".wav", 75, 255 )
		ent:EmitSound( "npc/turret_floor/ping.wav", 75, math.random( 200, 255 ) )

		-- Jump off ground
		local phys = ent:GetPhysicsObject()
		if ( phys and phys:IsValid() ) then
			local horizontal	= 50
			local vertical		= 200
			local angle			= 5000
			phys:ApplyForceCenter( Vector( math.random( -1, 1 ) * horizontal, math.random( -1, 1 ) * horizontal, vertical ) )
			phys:AddAngleVelocity( VectorRand() * angle )
		end

		timer.Simple( math.random( ent.JumpDelay[1], ent.JumpDelay[2] ), function() tryjump( ent ) end )
	end
end

-- States
local State
State = {
	Pickup = {
		Start = function( self, ent )
			-- print( "pck up" )
			timer.Simple( math.random( ent.JumpDelay[1], ent.JumpDelay[2] ), function() tryjump( ent ) end )
		end,
		Think = function( self, ent )
			for k, colent in pairs( ents.FindInSphere( ent:GetPos(), 50 ) ) do
				trypickup( ent, colent )
			end
		end,
		Collide = function( self, ent, colent )
			trypickup( ent, colent )
		end,
		End = function( self, ent )
			
		end,
	},
}

function ENT:Initialize()
	-- Visuals
	local dia = self.Scale
	self:SetModel( "models/props_c17/clock01.mdl" )
	self:SetMaterial( "models/shiny", true )
	self:SetColor( Color( 50, 50, 70, 255 ) )
	self:SetModelScale( dia, 0 )
	self:DrawShadow( false )

	-- Physics
	self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:PhysWake()

	-- Variables
	self.JumpDelay = { 2, 4 }

	-- Initialise
	self:StartState( State.Pickup )
end

function ENT:Think()
	self:ThinkState()

	self:NextThink( CurTime() )
	return true
end

function ENT:OnTakeDamage( dmg )
	
end

function ENT:PhysicsCollide( colData, collider )
	self:CollideWithEnt( colData.HitEntity )
end

function ENT:CollideWithEnt( ent )
	if ( self.NextCollide and self.NextCollide > CurTime() ) then return end

	-- Don't collide a bunch with one bounce
	self.NextCollide = CurTime() + 0.2

	-- State specific collision logic
	self.State:Collide( self.Entity, ent )

	-- Play sound
	-- self:EmitSound( "physics/concrete/concrete_impact_hard1.wav", 75, math.random( 180, 200 ), 1 )
	-- self:EmitSound( "npc/turret_floor/ping.wav", 75, math.random( 200, 255 ) )
	self:EmitSound( "player/pl_shell" .. math.random( 1, 3 ) .. ".wav", 75, math.random( 200, 255 ) )

	-- Play particle effect
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
		effectdata:SetNormal( self:GetUp() )
	util.Effect( "prk_hit", effectdata )
end

function ENT:StartState( state )
	if ( self.State ) then
		self:EndState()
	end
	self.State = state
	self.State:Start( self )
end

function ENT:ThinkState()
	if ( self.State ) then
		self.State:Think( self )
	end
end

function ENT:EndState()
	self.State:End( self )
	self.State = nil
end
