include( "shared.lua" )

local reload = true

local material = CreateMaterial(
	"PRK_Material_Gateway_Destination",
	"UnlitGeneric",
	{
		["$basetexture"] = "color/white",
	}
 )
local texture = GetRenderTarget( "PRK_Gateway_Destination", ScrW(), ScrH() )

net.Receive( "PRK_Gateway_EnterExit", function( len, ply )
	local self = net.ReadEntity()
	local ply = net.ReadEntity()
	local enter = net.ReadBool()
	local dest = net.ReadVector()

	self.Destination = dest
	if ( enter ) then
		self:Enter( ply )
	else
		self:Exit( ply )
	end
end )

function ENT:Initialize()
	self.Scale = 0
	self.Travellers = {}
end

function ENT:Think()
	-- Autoreload helper
	if ( reload ) then
		self:Initialize()
		reload = false
	end

	self.ClosestPlayerDistance = nil
	for k, ply in pairs( player.GetAll() ) do
		local dist = self:GetPos():Distance( ply:GetPos() )
		if ( !self.ClosestPlayerDistance or dist < self.ClosestPlayerDistance ) then
			self.ClosestPlayerDistance = dist
		end
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	
end

local function createparticle_inside( off )
	local pos = LocalPlayer():EyePos()
	local forward = Vector( 1, 0, 0 )
	local right = Vector( 0, 1, 0 )
	local up = Vector( 0, 0, 1 )
	local scale = PRK_Gateway_MaxScale
	local bend = Vector()
		if ( off == 0 ) then
			local r = ( math.cos( CurTime() ) + math.sin( CurTime() / 10 ) ) / 2
			local u = math.cos( CurTime() )
			bend = right * r * 10 + up * u * 30
		end
	LocalPlayer().PRK_GatewayDir = ( -forward - bend / 120 ):GetNormal()
	local effectdata = EffectData()
		effectdata:SetOrigin( pos + forward * scale * 50 + forward * scale * -15 * off + bend )
		effectdata:SetNormal( LocalPlayer().PRK_GatewayDir )
		effectdata:SetRadius( scale * 4 )
		effectdata:SetMagnitude( PRK_Gateway_Segments )
		effectdata:SetFlags( 1 )
	util.Effect( "prk_gateway", effectdata )
end

function ENT:Enter( ply )
	if ( ply == LocalPlayer() ) then
		-- Draw destination to texture
		-- LocalPlayer().PRK_Gateway_DestinationRendering = true
			render.PushRenderTarget( texture )
			render.OverrideAlphaWriteEnable( true, true )
				render.ClearDepth()
				render.Clear( 0, 0, 0, 0 )
				render.RenderView(
					{
						origin = self.Destination,
						drawhud = false,
						-- angles = Angle( 0, 0, 0 ),
					}
				)
			render.OverrideAlphaWriteEnable( false )
			render.PopRenderTarget()
		-- LocalPlayer().PRK_Gateway_DestinationRendering = false
		material:SetTexture( "$basetexture", texture )

		-- Init flash screen
		LocalPlayer().PRK_Gateway_Flash = 1
		LocalPlayer().PRK_Gateway_FlashTime = CurTime() + PRK_Gateway_FlashHoldTime

		-- Init FOV
		LocalPlayer().PRK_Gateway_FOV = 30 -- LocalPlayer():GetFOV()
		LocalPlayer().PRK_Gateway_FOVTarget = 150
		LocalPlayer().PRK_Gateway_FOVSpeed = PRK_Gateway_FOVSpeedEnter

		-- Flag so nothing renders
		LocalPlayer().PRK_Gateway = self

		-- Initial particles (wait for eyepos to be received from server)
		timer.Simple( 0.1, function()
			for i = 1, 20 do
				createparticle_inside( i )
			end
		end )
	end

	self.Travellers[ply] = CurTime() -- PRK_Gateway_TravelTime
end

function ENT:Exit( ply )
	if ( ply == LocalPlayer() ) then
		-- Init flash screen
		LocalPlayer().PRK_Gateway_Flash = 1
		LocalPlayer().PRK_Gateway_FlashTime = CurTime() + PRK_Gateway_FlashHoldTime

		-- Init FOV
		LocalPlayer().PRK_Gateway_FOVTarget = LocalPlayer():GetFOV()
		LocalPlayer().PRK_Gateway_FOVSpeed = PRK_Gateway_FOVSpeedExit

		-- Flag so nothing renders
		LocalPlayer().PRK_Gateway = nil
	end

	self.Travellers[ply] = nil
end

hook.Add( "Think", "PRK_Think_Gateway", function()
	-- Flash screen
	if ( LocalPlayer().PRK_Gateway_FlashTime and LocalPlayer().PRK_Gateway_FlashTime <= CurTime() ) then
		LocalPlayer().PRK_Gateway_Flash = Lerp( FrameTime() * PRK_Gateway_FlashSpeed, LocalPlayer().PRK_Gateway_Flash, 0 )
	end

	-- FOV
	if ( LocalPlayer().PRK_Gateway_FOV ) then
		LocalPlayer().PRK_Gateway_FOV = Lerp( FrameTime() * LocalPlayer().PRK_Gateway_FOVSpeed, LocalPlayer().PRK_Gateway_FOV, LocalPlayer().PRK_Gateway_FOVTarget )
	end

	-- Inside Particles
	if ( LocalPlayer().PRK_Gateway ) then
		-- Show tunnel particles at player's new position
		local self = LocalPlayer().PRK_Gateway
		if ( !self.NextParticle or self.NextParticle <= CurTime() ) then
			createparticle_inside( 0 )
			self.NextParticle = CurTime() + PRK_Gateway_ParticleDelayTravel
		end
	end
end )

function PRK_CalcView_Gateway( ply, origin, angles, fov )
	if (
		LocalPlayer().PRK_Gateway or
		( LocalPlayer().PRK_Gateway_FOV and ( math.abs( LocalPlayer().PRK_Gateway_FOV - LocalPlayer().PRK_Gateway_FOVTarget ) > 10 ) )
	) then
		local view = {}
			-- view.angles = ( -LocalPlayer().PRK_GatewayDir ):Angle()
			view.angles = Vector( 1, 0, 0 ):Angle()
			view.origin = LocalPlayer():EyePos()
			view.fov = LocalPlayer().PRK_Gateway_FOV
		return view
	end
	return false
end

hook.Add( "PostDrawHUD", "PRK_PostDrawHUD_Gateway", function()
	if ( LocalPlayer().PRK_Gateway ) then
		local self = LocalPlayer().PRK_Gateway
		cam.Start3D()
			-- Draw texture
			local pos = LocalPlayer():EyePos() + Vector( 1, 0, 0 ) * ( 1000 - ( CurTime() - self.Travellers[LocalPlayer()] ) * 200 )
			-- PRK_BasicDebugSphere( pos )
			local angle = Vector( 1, 0, 0 ):Angle()
				angle:RotateAroundAxis( Vector( 0, 1, 0 ), -90 )
				angle:RotateAroundAxis( Vector( 1, 0, 0 ), 90 )
			cam.Start3D2D( pos, angle, 0.2 )
				surface.SetDrawColor( Color( 255, 255, 255, 255 ) )
				surface.SetMaterial( material )
					-- surface.DrawTexturedRect( -ScrW() / 2, -ScrH() / 2, ScrW(), ScrH() )
				draw.NoTexture()
			cam.End3D2D()

			-- Draw particles
			for k, v in pairs( PRK_Gateway_Emitters ) do
				if ( v:IsValid() ) then
					v:Draw()
				end
			end
		cam.End3D()

		-- Draw overlay effect
		DrawMaterialOverlay( "effects/tp_eyefx/tpeye3", -0.06 )
	end

	-- Draw flash
	if ( LocalPlayer().PRK_Gateway_Flash ) then
		surface.SetDrawColor( Color( 255, 255, 255, 255 * LocalPlayer().PRK_Gateway_Flash ) )
		surface.DrawRect(
			0,
			0,
			ScrW(),
			ScrH()
		)
	end
end )

-- Mesh tests
-- local mat = Material( "editor/wireframe" ) -- The material ( a wireframe )
local mat = Material( "prk_gradient.png" ) -- The material ( a wireframe )

-- local pos = Vector( 267, -757.5, -12200 )
local x = 0
local y = 0
local angle = 0
local a = 2
local b = 2
local maxPoints = 200
local angleadd = 0.1
local width = 10
local maxdepth = 500
local depth = 0

local verts = {}
	-- Generate a thick spiral
		for i = 0, maxPoints do
			-- Calculate this inner point
			angle = angleadd * i
			local size = angle
			x = ( a + b * size ) * math.cos( angle )
			y = ( a + b * size ) * math.sin( angle )
			local firstpoint = { pos = Vector( x, 0, y ), u = i % 3, v = i % 3 }

			-- First connect with the last triangle
			if ( i != 0 ) then
				local i = #verts
				table.insert( verts, verts[i - 2] )
				table.insert( verts, verts[i] )
				table.insert( verts, firstpoint )
			end

			-- Add the inner point after adding the joiner
			table.insert( verts, firstpoint )

			-- Add first outer triangle
			local size = size + width
			x = ( a + b * size ) * math.cos( angle )
			y = ( a + b * size ) * math.sin( angle )

			table.insert( verts, { pos = Vector( x, 0, y ), u = i % 3, v = i % 3 } )

			local angle = angle + angleadd
			size = size + angleadd
			x = ( a + b * size ) * math.cos( angle )
			y = ( a + b * size ) * math.sin( angle )

			table.insert( verts, { pos = Vector( x, 0, y ), u = i % 3, v = i % 3 } )
		end
local obj = Mesh()
-- mesh.Begin( obj, MATERIAL_TRIANGLES, maxPoints ) -- Begin writing to the dynamic mesh
	-- for i = 1, #verts do
		-- mesh.Position( pos + verts[i].pos ) -- Set the position
		-- mesh.TexCoord( 0, verts[i].u, verts[i].v ) -- Set the texture UV coordinates
		-- mesh.AdvanceVertex() -- Write the vertex
	-- end
-- mesh.End() -- Finish writing the mesh and draw it

local tunnel
hook.Add( "PostDrawOpaqueRenderables", "PRK_PostDrawOpaqueRenderables_Gateway", function()
	for k, self in pairs( ents.FindByClass( "prk_gateway" ) ) do
		local pos = self:GetPos()
		local forward = -self:GetAngles():Forward()
		if ( !tunnel ) then
			tunnel = PRK_AddModel(
				"models/props_phx/construct/metal_plate_curve360x2.mdl",
				pos + forward * PRK_Plate_Size * 4,
				Angle( 90, 90, 0 ),
				1,
				"models/debug/debugwhite",
				Color( 0, 200, 0, 255 )
			)
			tunnel:SetNoDraw( true )
		end

		render.SetMaterial( mat ) -- Apply the material

		local targetscale = math.Clamp( 1 - ( self.ClosestPlayerDistance / PRK_Gateway_StartOpenRange ), 0, 1 ) * PRK_Gateway_MaxScale
		self.Scale = Lerp( FrameTime() * PRK_Gateway_OpenSpeed, self.Scale, targetscale )
		local length = self.Scale * 100
		local segs = PRK_Gateway_Segments --24

		-- Particles
		if ( !PRK_Gateway_Emitters ) then
			PRK_Gateway_Emitters = {}
		end
		if ( !self.NextParticle or self.NextParticle <= CurTime() ) then
			local effectdata = EffectData()
				effectdata:SetOrigin( pos + forward * self.Scale * 5 )
				effectdata:SetNormal( forward )
				effectdata:SetRadius( self.Scale * 4 )
				effectdata:SetMagnitude( segs )
				effectdata:SetFlags( 0 )
			util.Effect( "prk_gateway", effectdata )
			self.NextParticle = CurTime() + PRK_Gateway_ParticleDelay
		end

		local tunnelscalemult = 1
		PRK_RenderScale( tunnel, Vector( self.Scale * tunnelscalemult, self.Scale * tunnelscalemult, length ) )
		tunnel:SetPos( pos + forward * PRK_Plate_Size * length )
		tunnel:SetAngles( self:GetAngles() + Angle( 90, 0, 0 ) )
		local function inner()
			-- Center
			cam.Start3D2D( pos + forward * 0, tunnel:GetAngles(), self.Scale )
				surface.SetDrawColor( 0, 0, 0, 255 )
				draw.NoTexture()
				draw.Circle( 0, 0, 24, segs, 0 )
			cam.End3D2D()

			local function inner_mask()
				-- Center
				cam.Start3D2D( pos + forward * 0, tunnel:GetAngles(), self.Scale )
					surface.SetDrawColor( PRK_HUD_Colour_Shadow )
					draw.Circle( 0, 0, 24, segs, 0 )
				cam.End3D2D()
			end
			local function inner_inner()
				-- tunnel:DrawModel()
				for k, v in pairs( PRK_Gateway_Emitters ) do
					if ( v:IsValid() ) then
						v:Draw()
					end
				end

				for ply, time in pairs( self.Travellers ) do
					if ply and ply:IsValid() and ( time + PRK_Gateway_TravelTime >= CurTime() ) then
						local oldpos = ply:GetPos()
						local oldang = ply:GetAngles()
						local move = ( CurTime() - time ) / PRK_Gateway_TravelTime
						local maxdist = 10000
						local dist = maxdist * move
						local scale = 1 - move

						ply:SetPos( pos + forward * dist + Vector( 0, 0, 1 ) * -50 * scale )
						ply:SetModelScale( scale )
						ply:SetAngles( AngleRand() )
						ply:SetupBones()
							ply:DrawModel()
						ply:SetModelScale( 1 )
						ply:SetPos( oldpos )
						ply:SetAngles( oldang )
						ply:SetupBones()
					end
				end
			end
			draw.StencilBasic( inner_inner, inner_mask )
		end
		local function mask()
			tunnel:DrawModel()

			-- Back wall
			cam.Start3D2D( pos + forward * 100, tunnel:GetAngles(), 1000 )
				surface.SetDrawColor( Color( 0, 0, 0, 1 ) )
				surface.DrawRect( -8, -8, 16, 16 )
			cam.End3D2D()
		end
		draw.StencilBasic( mask, inner )
	end
end )
