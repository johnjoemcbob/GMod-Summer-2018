AddCSLuaFile()

ENT.Base 			= "prk_npc_base"
ENT.Spawnable		= true
ENT.KillName		= {
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Biter",
	"Bob The Biter",
}

list.Set( "NPC", "prk_npc_biter", {
	Name = "Prickly Biter",
	Class = "prk_npc_biter",
	Category = "Prickly"
} )

function ENT:Initialize()
	self:SetModel( "models/headcrabclassic.mdl" )
	self:SetModelScale( PRK_Enemy_Scale, 0 )
	self:SetMaterial( "models/debug/debugwhite", true )
	self:SetColor( PRK_Colour_Enemy_Skin )
	-- local hori = 12
	-- local vert = 32
	-- local min = Vector( -hori, -hori, 0 )
	-- local max = Vector( hori, hori, vert )
	-- self:SetCollisionBounds( min, max )
	-- local height = Vector( 0, 0, 16 )
	-- self:PhysicsInitBox( min, max + height )
	-- self:EnableCustomCollisions( true )

	-- Extra collisions
	-- if ( SERVER ) then
		-- local collide = PRK_CreateEnt( "prk_enemy_collide", nil, self:GetPos(), Angle(), false, false )
			-- collide.Radius = 20
		-- collide:Spawn()
		-- collide:Attach( self )
		-- collide:SetParent( self )
		-- for bone = 1, self:GetBoneCount() do
			-- constraint.NoCollide( self, collide, bone )
		-- end
	-- end

	-- Extra visual details
	if ( CLIENT ) then
		self.Visuals = {}

		local origin = Vector( 25, 7, 0 )
		-- local height = 0
		local scale = 0.75
		self.Visuals = {
			{
				"models/ichthyosaur.mdl",
				origin * scale,
				Angle( 180, 160, 90 ),
				true,
				SpawnFunc = function( ent )
					ent.Bite = 0

					ent:SetModelScale( scale )

					local scale_main = Vector( 1, 1, 1 ) * 0.5
					local scale_ignore = Vector( 1, 1, 1 ) * 0.01
					local ignore = {
						[9] = true,
						[13] = true,
					}
					local pos = {
						Vector( 0, 0, 0 ), -- Root
						Vector( 0, 0, 0 ),
						Vector( -50, 0, 0 ),
						Vector( -20, 0, 0 ),
						Vector( -50, 0, 0 ),
						Vector( -20, 0, 0 ),
						Vector( -20, 0, 0 ),
						Vector( -20, 0, 0 ),
						Vector( 20, 0, 0 ),
						Vector( 20, 0, 0 ),
						Vector( 20, 0, 0 ),
						Vector( 20, 0, 0 ),
						Vector( 20, 0, 0 ),
						Vector( 20, 0, 0 ),
						Vector( -20, 10, 10 ),
						Vector( -10, 0, 10 ),
						Vector( -10, 0, 10 ),
						Vector( -10, 10, -10 ),
						Vector( 0, -20, 0 ),
						Vector( -10, 0, -10 ),
					}
					for i = 1, ent:GetBoneCount() do
						if ( !ignore[i] ) then
							-- ent:ManipulateBonePosition( i, VectorRand() )
							if ( pos[i] ) then
								ent:ManipulateBonePosition( i, pos[i] )
							end
							ent:ManipulateBoneScale( i, scale_ignore )
						else
							ent:ManipulateBoneScale( i, scale_main )
						end
						-- timer.Simple( 0.1, function()
							-- print( i .. " " .. ent:GetBoneName( i ) )
						-- end )
					end
				end,
				Think = function( ent, self )
					ent.Bite = 0
					-- ent.Bite = ( math.sin( CurTime() * 10 ) - 0.7 ) * 10

					local head = 9
					local jaw = 13
					local pos = Vector( 0, 1, 0 ) * ent.Bite
					ent:ManipulateBonePosition( head, pos )
					ent:ManipulateBonePosition( jaw, pos )
				end,
			},
			{
				"models/hunter/misc/sphere025x025.mdl",
				( origin + Vector( 2, 15, 8 ) ) * scale,
				Angle( 0, 0, 0 ),
				PRK_Colour_Enemy_Eye,
				SpawnFunc = function( ent )
					ent.Scale = 0.7
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
			{
				"models/hunter/misc/sphere025x025.mdl",
				( origin + Vector( 2, 15, -8 ) ) * scale,
				Angle( 0, 0, 0 ),
				PRK_Colour_Enemy_Eye,
				SpawnFunc = function( ent )
					ent.Scale = 0.7
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
			{
				"models/hunter/misc/sphere025x025.mdl",
				( origin + Vector( -10, 3, 0 ) ) * scale,
				Angle( 0, 0, 0 ),
				-- PRK_Colour_Enemy_Eye,
				PRK_Colour_Enemy_Mouth,
				SpawnFunc = function( ent )
					ent.Scale = 1.7
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
			{
				"models/gibs/antlion_gib_small_1.mdl",
				( origin + Vector( 3, 6, 3 ) ) * scale,
				Angle( 15, -60, -90 ),
				PRK_Colour_Enemy_Tooth,
				SpawnFunc = function( ent )
					ent.Scale = 1.5
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
			{
				"models/gibs/antlion_gib_small_1.mdl",
				( origin + Vector( 5, 6, -4 ) ) * scale,
				Angle( -15, -60, -90 ),
				PRK_Colour_Enemy_Tooth,
				SpawnFunc = function( ent )
					ent.Scale = 1.5
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
			{
				"models/gibs/antlion_gib_small_1.mdl",
				( origin + Vector( 0, -6, 6 ) ) * scale,
				Angle( -15, 30, 90 ),
				PRK_Colour_Enemy_Tooth,
				SpawnFunc = function( ent )
					ent.Scale = 1.5
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
			{
				"models/gibs/antlion_gib_small_1.mdl",
				( origin + Vector( 0, -6, -6 ) ) * scale,
				Angle( 15, 30, 90 ),
				PRK_Colour_Enemy_Tooth,
				SpawnFunc = function( ent )
					ent.Scale = 1.5
					ent:SetModelScale( scale * ent.Scale )
				end,
			},
		}

		for k, mod in pairs( self.Visuals ) do
			local ent = ClientsideModel( mod[1] )
				ent:SetNoDraw( true )
				if ( mod.SpawnFunc ) then
					mod.SpawnFunc( ent )
				end
			mod.Ent = ent
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
			if ( vis and vis.Ent and vis.Ent:IsValid() ) then
				vis.Ent:Remove()
			end
		end
	end

	if ( SERVER ) then
		if ( !self.Cleanup ) then
			GAMEMODE:SpawnCoins( self, self:GetPos(), self.Coins )
		end
	end
end

if ( CLIENT ) then
	function ENT:Draw()
		-- Draw base model
		local col = self:GetColor()
		render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
			self:DrawModel()
		render.SetColorModulation( 1, 1, 1 )

		-- Draw details
		local boneid = 2

		if not boneid then
			return
		end

		local matrix = self:GetBoneMatrix( boneid )
		if matrix then
			for k, mod in pairs( self.Visuals ) do
				local ent = mod.Ent
				local newpos, newang = LocalToWorld( mod[2], mod[3], matrix:GetTranslation(), matrix:GetAngles() )

				ent:SetPos( newpos )
				ent:SetAngles( newang )
				ent:SetMaterial( "models/debug/debugwhite" )
				local col = mod[4]
					if ( col == true ) then
						col = self:GetColor()
					end
				render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
					if ( mod.Think ) then
						mod.Think( ent, self )
					end
					ent:SetupBones()
					ent:DrawModel()
				render.SetColorModulation( 1, 1, 1 )
			end
		end
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
			return "ok"
		end
	end
end

function ENT:Attack( victim )
	victim:TakeDamage( 1, self, self )
end
