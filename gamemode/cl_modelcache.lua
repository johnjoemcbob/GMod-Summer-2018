--
-- Prickly Summer 2018
-- 17/08/18
--
-- Clientside Model Caching
--

PRK_CachedModels = {}

-- Return cached model, create if non-existent
function PRK_GetCachedModel( model, ren )
	if ( !ren ) then ren = RENDERGROUP_OTHER end

	if ( !PRK_CachedModels[ren] ) then
		PRK_CachedModels[ren] = {}
	end
	if ( !PRK_CachedModels[ren][model] ) then
		PRK_CachedModels[ren][model] = PRK_AddModel( model, Vector(), Angle(), 1, nil, Color( 255, 255, 255, 255 ), ren )
		PRK_CachedModels[ren][model]:SetNoDraw( true )
		PRK_CachedModels[ren][model]:SetRenderMode( RENDERMODE_TRANSALPHA )
	end

	return PRK_CachedModels[ren][model]
end

function PRK_RenderCachedModel( model, pos, ang, sca, mat, col, ren )
	local ent = PRK_GetCachedModel( model, ren )
	render.SetColorModulation( col.r / 255, col.g / 255, col.b / 255 )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		PRK_RenderScale( ent, sca )
		ent:SetupBones()

		ent:SetMaterial( mat )
		ent:DrawModel()
	render.SetColorModulation( 1, 1, 1 )
end
