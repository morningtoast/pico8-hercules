function draw_loop(t)
	for _,o in pairs(t) do o:_draw() end
end

function update_loop(t)
	for _,o in pairs(t) do o:_update() end
end

function ef() end
function _scene(name)
	scene_st=1
	scene_t=0
	
	printh("> scene load")
	
	if not name._init then name._init=ef end
	if not name._update then name._update=ef end
	if not name._draw then name._draw=ef end
	
	name._init()
	cart_update=name._update
	cart_draw=name._draw
end



-- Returns number of frames for provided seconds
-- local frames=sec(3)
function sec(s) return flr(s*60) end


-- Returns array of text sections as split by provided delimiter. Default delimiter is ;
-- local text=split(textString, delimiterChar)
function split(s,dc)
	local a={}
	local ns=""
	local dc=dc or ";"

	while #s>0 do
		local d=sub(s,1,1)
		if d==dc then
			add(a,ns)
			ns=""
		else
			ns=ns..d
		end

		s=sub(s,2)
	end

	if #s<=0 then add(a,ns) end

	return a
end


-- returns true if hitbox collision 
-- hitbox table structure: {x=0,y=0,w=0,h=0}
function collide(ax,ay,ahb, bx,by,bhb)
	  local l = max(ax+ahb.x,        bx+bhb.x)
	  local r = min(ax+ahb.x+ahb.w,  bx+bhb.x+bhb.w)
	  local t = max(ay+ahb.y,        by+bhb.y)
	  local b = min(ay+ahb.y+ahb.h,  by+bhb.y+bhb.h)

	  -- they overlapped if the area of intersection is greater than 0
	  if l < r and t < b then
		return true
	  end
					
	return false
end	



-- returns true if x/y coordinate is outside the screen with optional extended distance
-- !! assumes no camera screen
-- offscreen(coordX,coordY, extraDist)
function offscreen(x,y,e)
	local e=e or 0
	
	if (x<0-e or x>127+e or y<0-e or y>127+e) then 
		return true
	else
		return false
	end
end


-- returns true if hitbox collision 
-- hitbox table structure: {x=0,y=0,w=0,h=0}
function collide(ax,ay,ahb, bx,by,bhb, rdir)
	rdir=rdir or false
	local l = max(ax+ahb.x,        bx+bhb.x)
	local r = min(ax+ahb.x+ahb.w,  bx+bhb.x+bhb.w)
	local t = max(ay+ahb.y,        by+bhb.y)
	local b = min(ay+ahb.y+ahb.h,  by+bhb.y+bhb.h)

	-- they overlapped if the area of intersection is greater than 0
	if l < r and t < b then
		if rdir then
			local reldir = atan2(ax-bx, ay-by)

			if (reldir>=0 and reldir<.125) or (reldir<1 and reldir>=.875) then return 1 end
			if reldir>=.125 and reldir<.375 then return .25 end
			if reldir>=.625 and reldir<.625 then return .5 end
			if reldir>=.375 and reldir<.875 then return .75 end
		else
			return true
		end
	end
					
	return false
end


-- Utility: Math helpers

-- Returns a random number between min and max, inclusive
-- local num=random(minimum,maximum)
function random(m,x)
	local n=round(rnd(m-x))+m
	return n
end

-- Returns number rounded to the nearest whole
function round(n, i)
	local i=i or 0
	local m = 10^i
	return flr(n*m + 0.5) / m
end

-- Returns number as either positive or negative randomly
function rand_neg(n)
    if rnd()<.5 then n*=-1 end
    return n
end



-- Returns the angle from one x/y point to another. Alias for atan2()
-- local ang=get_angle(fromX,fromY, toX,toY)
function get_angle(fx,fy, tx,ty)
	return atan2(tx-fx, ty-fy)
end

-- Returns delta x/y values of a certain speed at specific angle. Use to move objects.
-- local dx,dy=dir_calc(angle, speed)
function dir_calc(a,s)
	local dx=cos(a)*s
	local dy=sin(a)*s
	
	return dx,dy
end