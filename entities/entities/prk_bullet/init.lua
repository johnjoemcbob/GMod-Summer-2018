AddCSLuaFile('shared.lua')
AddCSLuaFile('cl_init.lua')

include('shared.lua')

-- TODO: [ ] SEEMS WEIRD THAT THIS WON'T SPAWN IF GAMEMODE ISN'T SANDBOX DERIVED
--		 [ ] MOVETYPE_FLY AND ENT:PHYSICSCOLLIDE DON'T PLAY NICELY TOGETHER - NEED TO DO SOME SMALL TRACES TO DO WORLD COLLISION MAYBE?
--				* could actually just store a maximum travel distance based on bullet speed and trace from cannon, blow up after distance travelled/time expired?

function ENT:Initialize()
	-- Variables
	self.model = "models/Items/AR2_Grenade.mdl"
	self.blast_radius = 10
	self.blast_force = 0
	self.blast_damage = 5
	self.bullet_scale = 10
	self.bullet_speed = 300
	self.has_exploded = false
	self.has_collided = false

	-- Physical Stuff
	self:SetModel(self.model)
	self:SetSolid(SOLID_OBB)
	self:SetMoveType(MOVETYPE_FLY)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self.RenderGroup = RENDERGROUP_TRANSLUCENT
	self:SetColor( Color(0,0,0,255) )
	self:SetModelScale(self.bullet_scale, 0)
	self:PhysWake()
	self:SetGravity(0)

	
	-- Precache missile noises
	--util.PrecacheSound("weapons/crossbow/fire1.wav") -- turret fire sound?
	util.PrecacheSound("weapons/physcannon/hold_loop.wav") -- flyby sound

	-- call me from cannon/turret
	self:Launch(Vector(0,0,0), Vector(0,self.bullet_speed,0))
	
	
	
end

function ENT:Launch(startpos, velocity)
	self:SetPos(startpos)
	self:SetVelocity(velocity)
	self:SetAngles(velocity:Angle())
end

function ENT:OnTakeDamage(dmg)
	
	-- What hit us?
	attacker = dmg:GetAttacker():GetClass()
	
	if(string.find(attacker,"prk_bullet") == nil) then
		-- If it wasn't another bullet that bumped us...
		self.Entity:BulletAction()
		-- ... perform this bullet's action!
	end
	
end

function ENT:PhysicsCollide( colData, collider )

	self.has_collided = true

end

function ENT:Think()

	if(self.has_collided == true) then
		self.Entity:BulletAction()
	end

end

function ENT:Touch(activator)

	-- What's touching me?
	toucher = activator:GetClass()
	
	if(string.find(toucher,"prk_bullet") == nil and IsValid(activator)) then
		-- If it wasn't a bullet that bumped us...
		self.Entity:BulletAction()
		-- ... perform this bullet's action!	
	end
	
end

-- Bullet Functionality
---- BulletAction: This dictates what happens when this bullet hits something.
---- Can be overridden to produce different kinds of bullets!

function ENT:BulletAction()
	-- If we haven't exploded yet...
	if(self.has_exploded == false) then
		-- Where are we?
		pos = self.Entity:GetPos()
		-- EXPLODE!
		local explosion = EffectData()
		explosion:SetOrigin(pos)
		explosion:SetStart(pos)
		explosion:SetMagnitude(self.blast_damage)
		explosion:SetScale(self.blast_radius)
		explosion:SetRadius(self.blast_radius)
		
		util.Effect("Explosion",explosion)
		util.BlastDamage(self.Entity, self.Entity, pos, self.blast_radius, self.blast_damage)
		
		
		
	end
	
	self.has_exploded = true
	self.Entity:Remove()
	
end
