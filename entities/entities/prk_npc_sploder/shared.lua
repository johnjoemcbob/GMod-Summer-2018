AddCSLuaFile()

ENT.Base 			= "prk_npc_base"
ENT.Spawnable		= true
ENT.KillName		= "Sploder"

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
	self:SetModelScale( PRK_Enemy_Scale, 0 )
	self:SetMaterial( "models/debug/debugwhite", true )
	self:SetColor( PRK_Colour_Enemy_Skin )
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )

	-- Extra visual details
	if ( CLIENT ) then
		self.Visuals = {}

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
			local berry_mod = "models/XQM/Rails/gumball_1.mdl"
			local berry_pos = v / 3 * self:GetModelScale()
			local berry_ang = Angle()
			local berry_sca = ( 0.8 + math.random( 10, 50 ) / 100 ) / 3 * self:GetModelScale()
			local berry_mat = "models/debug/debugwhite"
			local berry_col = Color(
				PRK_Colour_Enemy_Eye.r * ( 0.7 + math.random( 10, 100 ) / 100 ),
				PRK_Colour_Enemy_Eye.g,
				PRK_Colour_Enemy_Eye.b,
				PRK_Colour_Enemy_Eye.a
			)

			local vis = PRK_AddModel( berry_mod, berry_pos, berry_ang, berry_sca, berry_mat, berry_col )
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

	self.Speed = PRK_Enemy_Speed --* PRK_Enemy_Scale
	self.Coins = 3
	self.SplodeRange = 200 --/ 3 * PRK_Enemy_Scale
	self.Playing = false

	local length = 1.5
	local function play()
		if ( self and self:IsValid() ) then
			if ( self.Playing ) then
				self:EmitSound( "prk_sploder_loop" )
			end
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

function ENT:OnNoEnemy()
	self.Playing = false
	self:StopSound( "prk_sploder_loop" )
end

function ENT:OnNewEnemy()
	self.Playing = true
	self:EmitSound( "prk_sploder_loop" )
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
			prop:SetModelScale( 1 / 3 * PRK_Enemy_Scale, 0 )
			prop:PhysicsInitSphere( 5 * PRK_Enemy_Scale )
			local phys = prop:GetPhysicsObject()
			if ( phys and phys:IsValid() ) then
				phys:SetVelocity( ( Vector( 0, 0, 1 ) + VectorRand() ) * 1000 )
			end
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

function ENT:MoveCallback()
	-- If near any enemy, attack
	for k, v in pairs( player.GetAll() ) do
		local dist = v:GetPos():Distance( self:GetPos() )
		if ( dist <= self.SplodeRange ) then
			self:SetEnemy( v )
			self:Attack( v )
			return "ok"
		end
	end
end

function ENT:Attack( victim )
	-- Spawn explosion
	PRK_Explosion( self, self:GetPos() + Vector( 0, 0, 30 ), self.SplodeRange )

	-- Flag for removal
	self.ToRemove = true
end
