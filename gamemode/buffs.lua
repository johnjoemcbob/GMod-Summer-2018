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

-- Any buff-specific values
PRK_BUFF_BULLET_DMG_ADD_MULTIPLIER = 0.05
PRK_BUFF_PLAYER_SPEED_ADD_MULTIPLIER = 0.05

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
end

-- Register a player in the buffs table and set up their data.
function PRK_Buff_Register(ply)
    PRK_PLY_BUFFS_TABLE[ply] = {}
    
    PRK_PLY_BUFFS_TABLE[ply][PRK_BUFFTYPE_BULLET_DMG] = 0
    PRK_PLY_BUFFS_TABLE[ply][PRK_BUFFTYPE_PLAYER_SPEED] = 0
    -- etc
    
    ply.BuffCallback = BuffCallback
end

-- Add X stacks of a buff to a player.
function PRK_Buff_Add( ply, bufftype, stack_num )
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
    PRK_PLY_BUFFS_TABLE[ply][bufftype] = 0
    
    -- Call callback.
    ply.BuffCallback(ply, bufftype, PRK_PLY_BUFFS_TABLE[ply][bufftype])
end

-- Get the stack level of a particular buff.
function PRK_Buff_Get(ply, bufftype)
	if ( !PRK_PLY_BUFFS_TABLE[ply] ) then
		PRK_Buff_Register( ply )
	end
    return PRK_PLY_BUFFS_TABLE[ply][bufftype]
end

-- Get entire buff table for player
function PRK_Buff_Get_All(ply)
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