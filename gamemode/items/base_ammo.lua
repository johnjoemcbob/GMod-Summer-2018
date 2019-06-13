local scale = 1

PRK_AddItem( "Base_Ammo", "", {
	PrettyName = "Ammo Base",
	KillName = "AMMO",
	UseLabel = "TAKE",
	Cooldown = 0.1,
	ThumbOffset = Vector( 0, 2, 0 ),
	InitShared = function( info, self )
		self.KillName = info.KillName
		self.UseLabel = info.UseLabel
	end,
	InitServer = function( info, self )
		self:SetColor( info.Colour )
		-- self:SetModel( "models/props_c17/oildrum001.mdl" )
		self:SetModel( "models/props_junk/PopCan01a.mdl" )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:PhysicsInit( SOLID_VPHYSICS )
		-- PRK_ResizePhysics( self, scale )
		-- self:SendScale( scale )
		self:PhysWake()

		self:SetPos( self:GetPos() + Vector( 0, 0, 15 ) )
	end,
	InitClient = function( info, self )
		self:DrawShadow( false )
		self.RenderGroup = RENDERGROUP_BOTH
	end,
	Draw = function( info, self, pos, ang )
		if ( !pos ) then pos = self:GetPos() end
		if ( !ang ) then ang = self:GetAngles() end

		local rotang = ang - Angle()
			rotang:RotateAroundAxis( ang:Forward(), 180 )
		PRK_RenderCachedModel(
			-- "models/props_c17/oildrum001.mdl",
			"models/props_junk/PopCan01a.mdl",
			pos,
			rotang,
			Vector( 1, 1, 1 ) * scale * 1,
			"models/shiny",
			Color( 150, 150, 200, 100 ),
			RENDERGROUP_TRANSLUCENT
		)
	end,
	Use = function( info, ply )
		if ( SERVER ) then
			-- Load ammo into next available clip
			ply:GetActiveWeapon():LoadBullet( 0, "Mini Revolver" )
		end

		return true
	end,
	SendData = function( info, self )
		-- To send any info from server to client
	end,
} )
