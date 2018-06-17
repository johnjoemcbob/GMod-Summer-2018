--
-- Prickly Summer 2018
-- 03/06/18
--
-- Main Clientside
--

include( "shared.lua" )

local function MyCalcView( ply, pos, angles, fov )
	local view = {}

	view.origin = pos -- ( angles:Forward() * 100 )
	view.angles = angles
	view.fov = fov
	view.drawviewer = false
	view.zfar = 3050

	return view
end
hook.Add( "CalcView", "PRK_CalcView_DrawDistance", MyCalcView )

-- From: http://wiki.garrysmod.com/page/surface/DrawPoly
function draw.Circle( x, y, radius, seg )
	local cir = {}

	table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
	for i = 0, seg do
		local a = math.rad( ( i / seg ) * -360 )
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
	end

	local a = math.rad( 0 ) -- This is need for non absolute segment counts
	table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

	surface.DrawPoly( cir )
end

function draw.StencilBasic( mask, inner )
	render.ClearStencil()
	render.SetStencilEnable(true)
		render.SetStencilWriteMask(255)
		render.SetStencilTestMask(255)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetBlend(0) --makes shit invisible
		render.SetStencilReferenceValue(10)
			mask()
		render.SetBlend(1)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
			inner()
	render.SetStencilEnable(false)
end
