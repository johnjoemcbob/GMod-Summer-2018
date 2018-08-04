AddCSLuaFile()

ENT.Base 			= "prk_npc_base"
ENT.Spawnable		= true
ENT.KillName		= "Biter"

list.Set( "NPC", "prk_npc_biter", {
	Name = "Prickly Biter",
	Class = "prk_npc_biter",
	Category = "Prickly"
} )

function ENT:Initialize()
	self:SetModel( "models/headcrabclassic.mdl" )
	-- self:SetModelScale( PRK_Enemy_Scale, 0 )
	self:SetModelScale( PRK_Enemy_PhysScale, 0 )
	self:SetMaterial( "models/debug/debugwhite", true )
	-- self:SetColor( PRK_Colour_Enemy_Skin )
	self:SetColor( Color( 255, 255, 255, 255 ) )
	-- local hori = 12
	-- local vert = 32
	-- self:SetCollisionBounds( Vector( -hori, -hori ,0 ), Vector( hori, hori, vert ) ) 

	-- Extra visual details
	if ( CLIENT ) then
		self.Visuals = {}

		local boneparent = 2
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
				vis:SetParent( self, boneparent )
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
				vis:SetParent( self, boneparent )
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
			vis:SetParent( self, boneparent )
		table.insert( self.Visuals, vis )

		-- Scale
		local sca = Vector( 1, 1, 1.5 ) * PRK_Enemy_Scale / PRK_Enemy_PhysScale
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

	self.Speed = PRK_Enemy_Speed
	self.Coins = 3
	self.BiteRange = 100
	self.BiteBetween = 0.5
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
		GAMEMODE:SpawnCoins( self:GetPos(), self.Coins )
	end
end

if ( CLIENT ) then
	function ENT:Draw()
		-- self:SetAngles( self:GetAngles() + Angle( 0, 180, 0 ) )
		for k, vis in pairs( self.Visuals ) do
			-- vis:SetPos( self:GetPos() + vis.Pos + Vector( 0, 0, ( ( math.random( 10, 100 ) / 100 ) + math.sin( CurTime() * 1 ) ) * 4 ) )
			-- vis:SetPos( vis:GetPos() + Vector( 0, 0, math.sin( CurTime() * 50 ) * 1 ) )
			-- vis:SetPos( self:GetPos() + vis.Pos + Vector( 0, 0, ( ( math.random( 10, 100 ) / 100 ) + math.sin( CurTime() * 1 ) ) * 4 ) )
			vis:SetParent( self )
		end
		self:DrawModel()
	end
end

function ENT:MoveCallback()
	if ( self.NextBite and self.NextBite > CurTime() ) then return end

	-- If near any enemy, attack
	for k, v in pairs( player.GetAll() ) do
		local dist = v:GetPos():Distance( self:GetPos() )
		if ( dist <= self.BiteRange ) then
			self:SetEnemy( v )
			self:Attack( v )
			self.NextBite = CurTime() + self.BiteBetween
			-- self:StartActivity( ACT_LEAP )
			return "ok"
		end
	end
end

function ENT:Attack( victim )
	-- victim:TakeDamage( 1, self, self )
end
