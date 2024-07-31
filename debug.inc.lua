--#debug utility
function debug_hitbox(x,y,hb,c) 
	c=c or 11
	rect(x+hb.x,y+hb.y, x+hb.x+hb.w,y+hb.y+hb.h, c)
end	


function debug_grid()
	for c=0,640,8 do
		for r=0,512,8 do
			pset(c,r, 1)
		end
	end
end
