function dir_calc(a,s) return cos(a)*s,sin(a)*s end
function chance(c) c=c or .555 if rnd()<c then return true else return false end end
function rand_neg(n) if chance() then return n*-1 else return n end end
function co_wait(n) n=flr(n*60) for i=1,n do yield() end end
function draw_loop(t) for o in all(t) do o:_d() end end
function update_loop(t) for o in all(t) do o:_u() end end
function random(m,x) local n=rnd()*(x-m)+m return n end
function play(m,p) if music_on then music_track=m music(m,p) end end
function onscreen(x) return x>=cam_x and x<=cam_x+128 end

function get_distance(ox,oy, px,py)
  local a = ox-px
  local b = oy-py
  return (sqrt(a^2+b^2)/16)*16
end

function newobj(x,y,spr,hb,ang,spd)
	ang=ang or false
	spd=spd or false
	hb=hb or false

	local obj={
		x=x,y=y,spr=spr,ang=ang,spd=spd
	}

	if not hb then hb={x=0,y=0,w=8,h=8} end
	obj.hb=hb

	if ang and spd then
		obj.dx,obj.dy=dir_calc(ang,spd)
	end

	return obj
end

function table_shuffle(t)
  for i = #t, 1, -1 do
    local j = flr(rnd(i)) + 1
    t[i], t[j] = t[j], t[i]
  end
end


--function collide(ax,ay,ahb, bx,by,bhb, rdir)
function collide(aobj, bobj, rdir)
	rdir=rdir or false
	ax=aobj.x
	ay=aobj.y
	ahb=aobj.hb
	bx=bobj.x
	by=bobj.y
	bhb=bobj.hb

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
			return bobj
		end
	end
					
	return false
end


-- map tile collide
-- x=pixel x,y=pixel y,hb=hitbox,flag=sprite flag to check,maposx=map offset x,maposy=map offset y
-- collide(me.x,me.y, 1, 16) -- this will look at tile starting at map column 16
function collide_tile(x,y,hb,flag,maposx,maposy)
    local maposx=maposx or 0
    local maposy=maposy or 0
    local flag=flag or 1
    local collide=false

    if fget(mget(maposx+(x+hb.x)/8,         maposy+(y+hb.y)/8))==flag or --topleft
        fget(mget(maposx+(x+hb.x+hb.w)/8,   maposy+(y+hb.y)/8))==flag or --top right
        fget(mget(maposx+(x+hb.x)/8,        maposy+(y+hb.y+hb.h)/8))==flag or -- bottom left
        fget(mget(maposx+(x+hb.x+hb.w)/8,   maposy+(y+hb.y+hb.h)/8))==flag --bottom right
    then
        collide=true
    end

    return collide
end