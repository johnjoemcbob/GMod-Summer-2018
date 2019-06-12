--
-- Prickly Summer 2018
-- 15/08/18
--
-- Shared Global Variables
--

GM.Name = "Prickly Summer 2018"
GM.Author = "johnjoemcbob & DrMelon"
GM.Email = ""
GM.Website = "https://github.com/johnjoemcbob/GMod-Summer-2018"

-- Base Game
PRK_SANDBOX = true
if PRK_SANDBOX then
DeriveGamemode( "Sandbox" ) -- For testing purposes, nice to have spawn menu etc
else
DeriveGamemode( "base" )
end

-- HUD
PRK_HUD_Shadow_DistX							= -2
PRK_HUD_Shadow_DistY							= 2
PRK_HUD_Shadow_Effect							= 4
PRK_HUD_Punch_Amount							= 5
PRK_HUD_Punch_Speed								= 10
PRK_HUD_DieEffect_MaxAlpha						= 230

-- Colours
PRK_HUD_Colour_Main								= Color( 255, 255, 255, 255 )
PRK_HUD_Colour_Dark								= Color( 0, 0, 0, 255 )
PRK_HUD_Colour_Money							= Color( 255, 255, 50, 255 )
PRK_HUD_Colour_Shadow							= Color( 255, 100, 150, 255 )
PRK_HUD_Colour_Highlight						= Color( 100, 190, 190, 255 )
PRK_HUD_Colour_Use								= Color( 205, 50, 100, 255 )
PRK_HUD_Colour_Heart_Dark						= Color( 70, 20, 30, 255 )
PRK_HUD_Colour_Heart_Light						= Color( 150, 20, 70, 255 )

PRK_Colour_Player								= {
													Color( 255, 100, 150, 255 ),
													Color( 253, 203, 110, 255 ),
													Color( 0, 206, 201, 255 ),
													Color( 85, 239, 196, 255 ),
													Color( 162, 155, 254, 255 ),
													Color( 255, 118, 117, 255 ),
													Color( 89, 98, 117, 255 ),
}

-- PRK_Colour_Enemy_Skin							= Color( 0, 0, 5, 255 )
PRK_Colour_Enemy_Skin							= Color( 22, 22, 22, 255 )
PRK_Colour_Enemy_Eye							= PRK_HUD_Colour_Shadow
PRK_Colour_Enemy_Tooth							= PRK_HUD_Colour_Main
PRK_Colour_Enemy_Mouth							= Color( 100, 100, 100, 255 )
PRK_Colour_Enemy_Blood							= Color( 255, 50, 200, 255 )
PRK_Colour_Explosion							= Color( 255, 150, 0, 255 )

-- Grass
PRK_Grass_Colour								= Color( 40, 40, 40, 255 )
PRK_Grass_Mesh									= true
PRK_Grass_Mesh_CountRange						= { 0.1, 0.2 }
PRK_Grass_Mesh_Disruption						= true
PRK_Grass_Mesh_DisruptTime						= 0.2
PRK_Grass_Mesh_DisruptorInnerRange				= 50
PRK_Grass_Mesh_DisruptorOuterRange				= 4000
PRK_Grass_Mesh_Disruptors						= {
													"player",
													"prk_bullet_heavy",
													"prk_laser_heavy",
													"prk_coin_heavy",
													"prk_npc_biter",
													"prk_npc_sploder",
													"prk_debris",
													"prk_gateway",
													"prk_potion",
}
PRK_Grass_Billboard								= true
PRK_Grass_Billboard_Count						= 3
PRK_Grass_Billboard_DrawRange					= 5000
PRK_Grass_Billboard_Forward						= 200 --400
PRK_Grass_Billboard_ShouldDrawTime				= 0.1
PRK_Grass_Billboard_MaxRenderCount				= 1000
PRK_Grass_Billboard_MultipleSprite				= false

PRK_Wall_Detail_Mesh_Count						= function()
													return math.max( 0, math.random( -10, 1 ) )
													-- return 0
												end

PRK_Decal										= true
PRK_Decal_NonDamage								= true
PRK_Decal_Max									= 200
PRK_Decal_CombineDist							= 10

-- Visuals
PRK_Material_Base								= "models/debug/debugwhite"
PRK_Epsilon										= 0.001
PRK_Plate_Size									= 47.45
PRK_DrawMap										= false
PRK_DrawDistance								= 4000
PRK_MaxAverageFrameTimes						= 10
PRK_CurrencyBefore								= "€"
PRK_CurrencyAfter								= ""
PRK_CursorSize									= 6
PRK_MouthDefault								= -15
PRK_MouthVoice									= 75

-- Gateway
PRK_Gateway_StartOpenRange						= 500
PRK_Gateway_MaxScale							= 5
PRK_Gateway_PullRange							= 300
PRK_Gateway_PullForce							= 100
PRK_Gateway_EnterRange							= 100
PRK_Gateway_OpenSpeed							= 5
PRK_Gateway_TravelTime							= 2 -- 5
PRK_Gateway_FlashHoldTime						= 0.2
PRK_Gateway_FlashSpeed							= 10
PRK_Gateway_FOVSpeedEnter						= 0.5
PRK_Gateway_FOVSpeedExit						= 5
PRK_Gateway_ParticleDelay						= 0.05
PRK_Gateway_ParticleDelayTravel					= 0.1 --0.05
PRK_Gateway_Segments							= 48

-- Editor
PRK_Editor_MoveSpeed							= 2
PRK_Editor_Zoom_Step							= 30
PRK_Editor_Zoom_Speed							= 10
PRK_Editor_Zoom_Min								= 50
PRK_Editor_Zoom_Default							= 500
PRK_Editor_Zoom_Max								= 2000
PRK_Editor_Grid_Scale							= 0.5
PRK_Editor_Grid_Size							= 1024
PRK_Editor_Square_Size							= PRK_Plate_Size
PRK_Editor_Square_Border_Min					= 8
PRK_Editor_Square_Border_Add					= 4

-- Level Generation
PRK_Gen_Seed									= nil --2
PRK_Gen_SizeModifier							= 2 -- 6 -- 7 -- 5 --0.01 -- 10
PRK_Gen_DetailWaitTime							= 1
PRK_Gen_StepBetweenTime							= 0 --0.1 --0--5
PRK_Gen_FloorDeleteTime							= ( PRK_Gen_StepBetweenTime * 4 ) + 1 -- Gotta wait around long enough to collide
PRK_Gen_IgnoreEnts								= { false, false, true, false }
PRK_Gen_WallCollide								= false

-- Damage/Death
PRK_Hurt_Material								= "pp/texturize/pattern1.png"
PRK_Hurt_ShowTime								= 0.2
PRK_Death_Material								= "pp/texturize/plain.png"
PRK_Death_Sound									= "music/stingers/hl1_stinger_song27.mp3"

-- Enemy
PRK_Enemy_PhysScale								= 2.75
PRK_Enemy_Scale									= 2 -- 3
PRK_Enemy_Speed									= 300 -- 500
PRK_Enemy_Types									= {
													["Biter"] = "prk_npc_biter",
													["Sploder"] = "prk_npc_sploder",
													["Turret"] = "prk_turret_heavy",
}
PRK_Enemy_CoinDropMult							= 0.2 -- 0.1

-- Player
PRK_UseRange									= 150
PRK_UseBetween									= 0.5
PRK_BaseClip									= 3 --6
PRK_Health										= 6
PRK_Speed										= 600
PRK_Jump										= 0

-- Gun
PRK_Gun_PunchLerpSpeed							= 1
PRK_Gun_MoveLerpSpeed							= 30
PRK_Gun_HUDLerpSpeed							= 5
PRK_Gun_HUDScaleMultiplier						= 4

-- Misc
PRK_ContextMenu									= false
PRK_Height_OutOfWorld							= -10000000000 -- -12735
PRK_Position_Nowhere							= Vector( 0, 0, -20000 )
PRK_GamemodePath								= "gamemodes/heavygullets/"
PRK_DataPath									= "heavygullets/"

-- FPS testing
PRK_Grass_Mesh									= false -- FPS test
PRK_Grass_Mesh_CountRange						= { 0, 0 } -- FPS test
PRK_Grass_Mesh_Disruption						= false -- FPS test
PRK_Grass_Billboard								= false -- FPS test
-- PRK_Decal										= false -- FPS test
PRK_NoWalls										= false
PRK_NoEnemies									= false
PRK_NoEnts										= {
													["prk_coin_heavy"]	= true,
													-- ["prk_debris"]		= true,
												}
