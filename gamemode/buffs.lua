--
-- Prickly Summer 2018
-- 01/07/18
--
-- Buff / Debuff / Upgrade System
--

-- Globals
PRK_PLY_BUFFS_TABLE = {}

-- Structure of buffs table:
-- TABLE[PLAYER] = {{BUFFTYPE_A, STACK}, {BUFFTYPE_B, STACK}}

-- Buff Types
PRK_BUFFTYPE_BULLET_DMG = "Bullet Damage"
PRK_BUFFTYPE_PLAYER_SPEED = "Run Speed"
PRK_BUFFTYPE_PLAYER_CHAMBERS = "Additional Revolver Chambers"

-- Any buff-specific values
PRK_BUFF_BULLET_DMG_ADD_MULTIPLIER = 0.05
PRK_BUFF_PLAYER_SPEED_ADD_MULTIPLIER = 0.05
PRK_BUFF_PLAYER_CHAMBERS_ADD = 1

-- This callback fires whenever a player's buffs change. Use this to do single-shot buff effects like player speed.
function BuffCallback( ply, buff, stack )
    -- Player Speed Buff
    if(buff == PRK_BUFFTYPE_PLAYER_SPEED) then
        -- Calculate additive buff speed (e.g, 1 stack = 105% speed)
        local buff_mult = 1.00 + (stack * PRK_BUFF_PLAYER_SPEED_ADD_MULTIPLIER)
        
        ply:SetWalkSpeed( PRK_Speed * buff_mult )
        ply:SetRunSpeed( PRK_Speed * buff_mult )
        ply:SetMaxSpeed( PRK_Speed * buff_mult )
    end
    
    -- Additional Revolver Chambers Buff
    if(buff == PRK_BUFFTYPE_PLAYER_CHAMBERS) then
        -- Get Amt of Chambers 
        local chambers_amt = 6 + (stack * PRK_BUFF_PLAYER_CHAMBERS_ADD)
        
        local gun = ply:GetActiveWeapon()
        gun:SendNumChambers(chambers_amt)
    end
end

-- Register a player in the buffs table and set up their data.
function PRK_Buff_Register(ply)
    PRK_PLY_BUFFS_TABLE[ply] = {}
    
    PRK_PLY_BUFFS_TABLE[ply][PRK_BUFFTYPE_BULLET_DMG] = 0
    PRK_PLY_BUFFS_TABLE[ply][PRK_BUFFTYPE_PLAYER_SPEED] = 0
    PRK_PLY_BUFFS_TABLE[ply][PRK_BUFFTYPE_PLAYER_CHAMBERS] = 0
    -- etc
    
    ply.BuffCallback = BuffCallback
end

function PRK_Buff_SafetyRegister(ply)
    if(PRK_PLY_BUFFS_TABLE[ply] == nil) then
        PRK_Buff_Register(ply)
    end
end

-- Add X stacks of a buff to a player.
function PRK_Buff_Add( ply, bufftype, stack_num )
    PRK_Buff_SafetyRegister(ply)
    -- Sanity check input.
    if(stack_num <= 0 ) then
        print("PRK_ERROR: stack_num must be > 0")
        return
    end
    
    PRK_PLY_BUFFS_TABLE[ply][bufftype] = PRK_PLY_BUFFS_TABLE[ply][bufftype] + stack_num
    
    -- Call callback.
    ply.BuffCallback(ply, bufftype, PRK_PLY_BUFFS_TABLE[ply][bufftype])
end

-- Remove X stacks of a buff from a player.
function PRK_Buff_Remove(ply, bufftype, stack_num )
    PRK_Buff_SafetyRegister(ply)
    if(stack_num <= 0) then
        print("PRK_ERROR: stack_num must be > 0")
        return
    end
    
    PRK_PLY_BUFFS_TABLE[ply][bufftype] = PRK_PLY_BUFFS_TABLE[ply][bufftype] - stack_num
    
    -- Minimum is 0
    if(PRK_PLY_BUFFS_TABLE[ply][bufftype] < 0) then
        PRK_PLY_BUFFS_TABLE[ply][bufftype] = 0
    end
    
    -- Call callback.
    ply.BuffCallback(ply, bufftype, PRK_PLY_BUFFS_TABLE[ply][bufftype])
end

-- Clear all stacks of a buff from a player.
function PRK_Buff_Clear(ply, bufftype)
    PRK_Buff_SafetyRegister(ply)
    PRK_PLY_BUFFS_TABLE[ply][bufftype] = 0
    
    -- Call callback.
    ply.BuffCallback(ply, bufftype, PRK_PLY_BUFFS_TABLE[ply][bufftype])
end

-- Get the stack level of a particular buff.
function PRK_Buff_Get(ply, bufftype)
    PRK_Buff_SafetyRegister(ply)
	if ( !PRK_PLY_BUFFS_TABLE[ply] ) then
		PRK_Buff_Register( ply )
	end
    return PRK_PLY_BUFFS_TABLE[ply][bufftype]
end

-- Get entire buff table for player
function PRK_Buff_Get_All(ply)
    PRK_Buff_SafetyRegister(ply)
    return PRK_PLY_BUFFS_TABLE[ply]
end

function PRK_Buff_Debug_Print()
    for ply,bufftab in pairs(PRK_PLY_BUFFS_TABLE) do
        print("PLAYER: " .. tostring(ply) .. " Buffs: ")
        for bufftype,stack in pairs(bufftab) do
            print("##### " .. bufftype .. ": " .. tostring(stack))
        end
    end
end



hook.Add("PlayerInitialSpawn", "prk_buff_spawn", PRK_Buff_Register)