pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- project name
-- 7/10/24

#include ../inc_debug.p8
#include ../utilfunc.inc.p8




-- Safe map is UPPER 16 screens; 2 rows of 8 across, zero-base
-- +-----+-----+-----+-----+-----+-----+-----+-----+
-- |  0  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |
-- +-----+-----+-----+-----+-----+-----+-----+-----+
-- |  8  |  9  |  10 |  11 |  12 |  13 |  14 |  15 |
-- +-----+-----+-----+-----+-----+-----+-----+-----+

-- Returns tile x/y for provided map number
-- map_ox,map_oy=get_maptxy(1)
function get_maptxy(id)
    local ty,tx=0,id*16
    if(id>7)ty,tx=16,(id-8)*16
    return tx,ty
end


-- map tile collide
-- x=pixel x,y=pixel y,hb=hitbox,flag=sprite flag to check,maposx=map offset x,maposy=map offset y
-- collide(me.x,me.y, 1, 16) -- this will look at tile starting at map column 16

-- to check if x/y has collided with a tile
-- convert screen x/y into map x/y (0-15)
-- find out which map its within

function screenxy_to_mapxy(x,y)
	local tx,ty=0,0
	local mapid=0

	for k,m in pairs(stream) do
		if (y<=m.y+128 and y>=m.y) then 
			mapid=m.id 
			ty=flr(abs(y-m.y)/8)
			break
		end
	end

	tx=flr(x/8)

	mapx,mapy=get_maptxy(mapid)

	tx+=mapx
	ty+=mapy

	return tx,ty
end


function collide_tile(x,y,hb,flag)
	local tx_tl,ty_tl=screenxy_to_mapxy(x+hb.x,      y+hb.y)
	local tx_tr,ty_tr=screenxy_to_mapxy(x+hb.x+hb.w, y+hb.y)
	local tx_bl,ty_bl=screenxy_to_mapxy(x+hb.x,      y+hb.y+hb.h)
	local tx_br,ty_br=screenxy_to_mapxy(x+hb.x+hb.w, y+hb.y+hb.h)
	local collide=false

	debugtext=tx_tl..","..ty_tl.."\n"..tx_tr..","..ty_tr

    if fget(mget(tx_tl,ty_tl),flag) or --topleft
        fget(mget(tx_tr,ty_tr),flag) or --top right
        fget(mget(tx_bl,ty_bl),flag) or -- bottom left
        fget(mget(tx_br,ty_br),flag) --bottom right
    then
        collide=true
    end

	return collide
end

-- takes screen x/y and returns nearest rounded screen x/y to match 8px tile position
-- for local screen only, NOT active map or absolute coordinates
function get_nearest_tilepx(x,y)
	local winx=ceil((x)/8)*8-8
	local winy=ceil((y)/8)*8-8

	return winx,winy
end

-- bullet hits any map tile
-- see which tile flag it is and respond accordingly
function bullet_hit_tile(x,y)
	local mx,my=screenxy_to_mapxy(x,y)
	local collide=false

	local tile_spr=mget(mx,my)
	local tile_flag=fget(tile_spr)



    if tile_flag>0 then
		 -- 1=blocking tiles
		if tile_flag==1 then

			-- trees; leave stumps
			if tile_spr==2 or tile_spr==5 then
				mset(mx,my,20)
			end
		end


		-- see if tile should reveal anything; pickup or mob
		if tile_has_drop(mx,my,x,y) then

			--local winx=ceil((x)/8)*8-8
			--local winy=ceil((y)/8)*8-8
			--printh(winx..","..winy)
			--add_mob(winx,winy)
			
		end

		return true
	end

	return false
end

function collide_point(x,y,flag)
	local tx_tl,ty_tl=screenxy_to_mapxy(x,y)
	local collide=false



    if fget(mget(tx_tl,ty_tl),flag) then
	--printh("hit tile "..tx_tl..","..ty_tl)
		if check_drop(tx_tl,ty_tl) then

			local winx=ceil((x)/8)*8-8
			local winy=ceil((y)/8)*8-8
			printh(winx..","..winy)
			add_mob(winx,winy)
			
		end
        collide=true
    end

	return collide
end

function collide_top(x,y,hb,flag)
	local tx_tl,ty_tl=screenxy_to_mapxy(x+hb.x,      y+hb.y)
	local tx_tr,ty_tr=screenxy_to_mapxy(x+hb.x+hb.w, y+hb.y)
	local collide=false

    if fget(mget(tx_tl,ty_tl),flag) or --topleft
        fget(mget(tx_tr,ty_tr),flag)
    then
        collide=true
    end

	return collide
end

function tile_hit(ax,ay,mapid)
	local thismap=stream[mapid]

	rel_map_y=flr((ay/8)-(thismap.y/8))

	local tx=flr(thismap.mapx+ax/8)
	local ty=flr(thismap.mapy+rel_map_y)

	tilespr=mget(tx,ty)

	return fget(tilespr),tilespr,tx,ty
end

function chg_tile(ax,ay,mapid,newtile)
	local thismap=stream[mapid]

	rel_map_y=flr((ay/8)-(thismap.y/8))
	mset(thismap.mapx+ax/8,thismap.mapy+rel_map_y,newtile)

	return (thismap.mapx+ax/8)*8,(thismap.mapy+rel_map_y)*8
end


--[[function get_mapid(x,y)
	local mapid=0
	for id,o in pairs(stream) do
		if o.y<128 and y>=o.y and y<=o.y+128 then
			mapid=id
		end
	end

	return mapid
end]]

function add_orbit(spr)
	-- #todo: map sprID to sprCoordinates for rotation func
	add(pickups,{
		x=p_cx,y=p_cy,st=0,rad=12,spd=3,dir=0,dx=0,dy=0,
		spr=spr,
		_u=function(me)
			if p_orbit then
				corad=me.rad/10

				me.x=p_cx+cos(me.dir/corad)*me.rad
				me.y=p_cy-sin(me.dir / corad) * me.rad
				me.dir-=me.spd/100

				me.ang=atan2(me.x-p_cx, me.y-p_cy)+.75
			else
				if me.dx==0 and me.dy==0 then
					printh("dir ball")
					me.dir=atan2(me.x-p_cx, me.y-p_cy)+.25
					printh("ang="..me.dir)
					me.ang=me.dir+.75
					me.dx,me.dy=dir_calc(me.dir,me.spd-1)
				else
					--printh("go ball!")
					me.x+=me.dx
					me.y+=me.dy

					if me.x<=0 or me.x>128 or me.y<0 or me.y>128 then
						del(pickups,me)
					end
				end
			end
		end,
		_d=function(me)
			--spr(2,me.x,me.y)
			if p_orbit then
				line(me.x,me.y,p_cx,p_cy,6)
			end
			draw_rotated(16,0,7,8,me.x,me.y,me.ang,.99)
		end
	})

	return #pickups
end


function tile_has_drop(tx,ty,sx,sy)
	local match=false
	for o in all(drops) do
		if o.x==tx and o.y==ty then
			printh("tile "..tx..","..ty.." has a drop")

			local posx,posy=get_nearest_tilepx(sx,sy)

			o.func(posx,posy)

			--mset(tx,ty,o.spr)
			match=true
			break
		end
	end

	return match
end


function add_mob(x,y)
	printh("I AM A SNAKE "..x..","..y)
	local obj={
		x=x,y=y,hb={x=0,y=0,w=7,h=7},
		_u=function(me)
			me.y+=1

			--[[for b in all(bullets) do
				if collide(me.x,me.y,me.hb,b.x,b.y,b.hb) then
					del(mobs,me)
					del(bullets,b)
				end

			end]]

			if me.y>window_bot then del(mobs,me) end
		end,
		_d=function(me)
			spr(3,me.x,me.y)
		end
	}

	add(mobs,obj)
end

function drop_heart(x,y)
	printh("I AM A HEART "..x..","..y)
	local obj={
		x=x,y=y,hb={x=0,y=0,w=7,h=7},
		_u=function(me)
			--me.y+=1

			--[[for b in all(bullets) do
				if collide(me.x,me.y,me.hb,b.x,b.y,b.hb) then
					del(mobs,me)
					del(bullets,b)
				end

			end]]

			if me.y>window_bot then del(mobs,me) end
		end,
		_d=function(me)
			spr(19,me.x,me.y)
		end
	}

	add(mobs,obj)
end


function offscreen(x,y) return (x<0 or x>130 or y<cam_y or y>cam_y+127) end

function mob_snake(x,y)
	add_mob(x,y)
end

-- #loop
function _init()
	printh("--- cam version")
	p_x,p_y=10,100
	p_tx,p_ty=0,0
	p_hb={x=2,y=2,w=4,h=4}
	p_map=99
	p_orbit=false
	chainx,chainy=0,0
	chain=0
	chainspr=0
	map_spd=.05

	--map_layers={}

	map_y=0
	cam_y=0
	stream={}
	bullets={}
	pickups={}

	-- tiles that reveal pickups after being destroyed
	drops={
		{x=40,y=6,func=mob_snake},
		{x=8,y=28,func=drop_heart},
		--{x=25,y=6,spr=3,name="snake2"},
		--{x=4,y=7,spr=19,name="heart"}
	}

	mobs={}



	-- index of where powerups are behind tiles

	stream={
		{x=0,y=-256,bg=4,mapx=0,mapy=0,last=true,id=0,inview=false},
		{x=0,y=-128,bg=5,mapx=16,mapy=0,id=1,inview=false},
		{x=0,y=0,bg=2,mapx=0,mapy=16,id=8,inview=false},
		{x=0,y=0,bg=13,mapx=32,mapy=0,id=2,inview=false},
	}

	for i=1,#stream do
		stream[i].y=i*128-128
		stream[i].mapx,stream[i].mapy=get_maptxy(stream[i].id)
		printh("y="..stream[i].y)
	end
	

	cam_y=#stream*128-128
	p_y=cam_y+64
	printh("camy="..p_y)

	map_i=0
	
end


function _update60()
    btnl,btnr,btnu,btnd,btnz,btnx=btn(0),btn(1),btn(2),btn(3),btn(4),btn(5)
	btnlp,btnrp,btnzp,btnxp,btnup,btndp=btnp(0),btnp(1),btnp(4),btnp(5),btnp(2),btnp(3)

	cam_y-=.1
	window_top=cam_y
	window_bot=window_top+127

	--printh(window_bot)

	debugtext=""
	flags={}
	p_dx,p_dy=0,0

	if chain<=0 then
		if btnl then p_dx=-1 end
		if btnr then p_dx=1 end
		if btnu then p_dy=-1 end
		if btnd then p_dy=1 end
	end

	is_blocked=false
	top_blocked=false

	--[[p_next_tlx=p_x+p_hb.x+p_dx
	p_next_trx=p_x+p_hb.x+p_hb.w+p_dx

	p_next_tly=p_y+p_hb.y+p_dy
	p_next_try=p_y+p_hb.y+p_hb.y+p_dy

	p_next_blx=p_next_tlx
	p_next_brx=p_next_trx

	p_next_bly=p_next_tly+p_hb.h
	p_next_bry=p_next_try+p_hb.h]]
	

	-- loop through each screen map; move down the screen
	--[[for mapid,o in pairs(stream) do
		

		

		if p_y>=o.y and p_y<=o.y+128 then 
			tl_hit=tile_hit(p_next_tlx,p_next_tly,mapid)
			tr_hit=tile_hit(p_next_trx,p_next_try,mapid)

			if tl_hit==1 or tr_hit==1 then
				is_blocked=true
				top_blocked=true
				p_dy=1
				p_dx=0
			end

			if tl_hit==2 or tr_hit==2 then
				chg_tile(p_next_tlx,p_next_tly,mapid,0)
			end

			
		end

		if p_y+8>=o.y and p_y+8<=o.y+128 then 
			bl_hit=tile_hit(p_next_blx,p_next_bly,mapid)
			br_hit=tile_hit(p_next_brx,p_next_bry,mapid)
			if bl_hit==1 or br_hit==1 then
				is_blocked=true
				p_dx=0
				p_dy=0
			end
		end

		-- check outgoing chain tile hit
		if chain==1 then
			hitflag,hitspr,hittx,hitty=tile_hit(chainx,chainy,mapid)
			
			if hitflag==1 then
				chain=2
				chainspr=hitspr
				
				if check_drop(hittx,hitty) then
					local sx=flr(chainx/8)
					local sy=flr(chainy/8)

					printh("screen tile="..sx..","..sy)

					add(bullets,{
						x=sx*8,y=sy*8,
						_u=function(me)
							me.y+=map_spd
						end,
						_d=function(me)
							spr(4,me.x,me.y)
						end
					})
					chg_tile(chainx,chainy,mapid,4)
				else
					chg_tile(chainx,chainy,mapid,0)
					
				end

				
			end
			
		end

		if not o.last or (o.last and o.y<=0) then
			o.y+=map_spd
		end
	end
	]]
	-- END: Stream loop; normal loop below


	--if not collide_tile(p_x+p_dx,p_y+p_dy,p_hb,1,0,map_y) then

	-- update_loop(array)
	--if not is_blocked then

	p_aheadx=p_x+p_dx
	p_aheady=p_y+p_dy

	

	-- collide with map tile; halt player
	if collide_tile(p_aheadx,p_aheady, p_hb, 0) then
		p_dx,p_dy=0,0
	end
	

	p_x+=p_dx
	p_y+=p_dy

	-- limits for player movement
	if p_y<window_top then p_y=window_top end
	if p_y>window_bot-8 then 
		p_y=window_bot-8 
		if collide_top(p_x,p_y,p_hb,0) then 
			-- player dies
			printh("squish death!") 
		end
	end
	if p_x<0 then p_x=0 end
	if p_x>120 then p_x=120 end

	p_cx=p_x+4
	p_cy=p_y+3

	--[[
	rel_map_y=flr((p_y/8)-(map_y/8))
	rel_map_flag=fget(mget(p_x/8,rel_map_y))
	printh(rel_map_flag)
	]]

	if not p_orbit and btnzp then
		-- new bullet
		local obj=newobj(p_cx-2,p_cy,18,{x=2,y=3,w=3,h=3},.25,1,
			function(me)
				me.y+=me.dy
				me.cx=me.x+3
				me.cy=me.y+3

				--if collide_point(me.cx,me.y,0) then
				if bullet_hit_tile(me.cx,me.y) then
					

					del(bullets,me)
				end

				if offscreen(me.x,me.y) then del(bullets,me) end
			end,
			function(me)
				spr(me.spr,me.x,me.y)
				debug_hitbox(me.x,me.y,me.hb)
			end)

	

		--[[add(bullets,{
			x=p_x,y=p_y,hb={x=2,y=3,w=3,h=3},dy=-1,
			_u=function(me)
				me.y+=me.dy

				next_tlx=me.x+me.hb.x
				next_trx=me.x+me.hb.x+me.hb.w

				next_tly=me.y+me.hb.y
				next_try=me.y+me.hb.y+me.hb.y

				onmap=get_mapid(me.x,me.y)

				local hit_flag,hit_spr,hit_tx,hit_ty=tile_hit(next_tlx,next_tly,onmap)

				if hit_flag==1 then
					add_mob(next_tlx,next_tly)
					-- need to convert screen_xy into tile_xy
					-- use tile_xy in loop to compare with pickup_coords
					if not check_drop(hit_tx,hit_ty) then
						mset(hit_tx,hit_ty,0)
					end
					
					--local tx,ty=chg_tile(next_tlx,next_tly,onmap,19)
					--printh(tx..","..ty)

					add(pickups,{
						x=next_tlx,y=next_tly,
						_u=function(me)
							me.y+=.1
						end,
						_d=function(me)
							spr(19,me.x,me.y)
						end
					})
					

					del(bullets,me)
				end

				

				if me.y<=0 then del(bullets,me) end
			end,
			_d=function(me)
				spr(18,me.x,me.y)
				debug_hitbox(me.x,me.y,me.hb)
			end
		})
		]]
		add(bullets,obj)
	end

	-- extend chain
	-- pull back chain w/ tile
	-- spin
	-- let go

	if not p_orbit and chain==0 and btnxp then
		chain=1 --outgoing chain
		chainx=p_cx
		chainy=p_cy
	end

	if chain==1 then --outgoing chain to hit tiles
		chainy-=3

		if chainy<=2 then --max out at top and then come back
			chain=2
		end
	end

	if chain==2 then --incoming chain with spr
		chainy+=3

		if chainy>=p_cy-12 then
			chain=0

			if chainspr>0 then
				p_orbit=true
				add_orbit(chainspr)
			end

			chainspr=0
		end
	end

	


	if p_orbit and btnxp then
		p_orbit=false
	end


	--[[if p_y>=122 then p_y=121 end
	if p_y<=0 then p_y=1 end]]
	

	

	--if top_blocked and p_y>=121 then printh("squish die!") end

	
	
	for k,m in pairs(stream) do
		--[[if (p_y>=m.y and p_y<=m.y+128) then 
			map_i=k
			p_map=m.id 

			
			p_ty=flr(abs(p_y-m.y)/8)
			break
		end]]

		if m.y>window_bot then del(stream,m) end
	end

	

	--p_tx=flr(p_x/8)
	p_tx,p_ty=screenxy_to_mapxy(p_x,p_y)

	

	--debugtext=p_tx..","..p_ty

	--map_y+=.1

	update_loop(bullets)
	update_loop(pickups)
	update_loop(mobs)
end


function _draw()
	cls()
	--map(0,0,0,0,16,16)
	camera(0,cam_y)
	
	for k,o in pairs(stream) do
		rectfill(0,o.y,128,o.y+128,o.bg)
		map(o.mapx,o.mapy,0,o.y,16,16)

		local top=flr(o.y-cam_y)
		local bot=top+128

		local foo="m"..o.id--.." in:"..tostr(o.inview).." t="..top.." b="..bot --..flr((o.y-cam_y)/(128*k))

		print(foo,10,o.y+120,7)
		print(foo,10,o.y+2,7)

		--debug_grid(0,o.y,10)
		
	end

	draw_loop(bullets)
	draw_loop(pickups)
	draw_loop(mobs)

	if chain>0 then
		fillp(0B101101001011010.1)
		line(p_cx,p_cy,chainx,chainy,6)
		fillp()
		circfill(chainx,chainy,1,6)

		if chainspr>0 then
			spr(chainspr,chainx,chainy)
		end
	end

--camera()
	spr(1,p_x,p_y)
	print(p_tx..","..p_ty,p_x,p_y-5,7)
	
	--print(p_map,p_x,p_y-5,7)
	debug_hitbox(p_x,p_y,p_hb)
	--circfill(p_cx,p_cy,1,1)

	
camera()
	--rectfill(0,0,8,128,1)
	--rectfill(119,0,127,128,1)
	
	print(debugtext,1,100,7)
	-- draw_loop(array)
end




--[[
	// quick and dirty way of rotating a sprite
	sx = spritecheet x-coord
	sy = spritecheet y-coord
	sw = pixel width of source sprite
	sh = pixel height of source sprite
	px = x-coord of where to draw rotated sprite on screen
	py = x-coord of where to draw rotated sprite on screen
	r = amount to rotate (radians)
	s = 1.0 for normal scale, 0.5 for half, etc
]]
function draw_rotated(sx,sy,sw,sh,px,py,r,s)
	-- loop through all the pixels
	for y=sy,sy+sh,1 do
		for x=sx,sx+sw,1 do
			-- get source pixel color
			col = sget(x,y)
			-- skip transparent pixel (zero in this case)
			if (col != 0) then
				-- rotate pixel around center
				local xx = (x-sx)-sw/2
				local yy = (y-sy)-sh/2
				local x2 = (xx*cos(r) - yy*sin(r))*s
				local y2 = (yy*cos(r) + xx*sin(r))*s
				-- translate rotated pixel to where we want to draw it on screen
				local x3 = flr(x2+px)
				local y3 = flr(y2+py)
				-- use rectfill if scale is > 1, otherwise just pixel it
				if (s >= 1) then
					local w = flr(x2+px+s)
					local h = flr(y2+py+s)
					rectfill(x3,y3,w,h,col)
				else
					pset(x3,y3,col)
				end
			end
		end
	end
end


__gfx__
00000000000444000003300000333000000000000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000f4000033330007373300444444440099990000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000008ff800033330003330130444444440099990000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000f1878800333331000001300999999990999992000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000878800333311003333130444994440999922000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000011f000033110033311130444444440099220000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000101000002200033333300444444440005500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000101000004200000000000555555550004500000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007700770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dd0000000000000070077007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000dddd000000007000070e00e07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000dddddd0000000dd700708ee807000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000dddddddd000007dd00002088020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000dddddd1ddd000000700000200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ddddddd11dd100000000000022000000f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddddddddd11dd10000000000000000000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddddddddd11dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddddddddddd11d0000225000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d1dddddd1ddd110000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011dd1ddd11d1d10250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111dd1111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001011111101000002250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001001100000005550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010002010000000000000000000001010002000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0002020202020202222202020202020211111111111100000000001111111111000000220000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002200000000000000000000000000000022000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000020202020200000000000000000022220000000000000000000022000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1011101120210202220000020202020200000000000000000200000000020000000000000000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002200020202020200000000000002020000002202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020200222200020202020200000000000202020202220002020000000000000000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002202020202020200000000000000020202000002020000000000000000000002220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002020202020200000000000202020200000000020202020000220002000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000022000200000200020000000000000202020200000002000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000002200020200000200020000000000000000000200000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000002020200000000000000000002020202020200002202000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000220002020000000000000000000002020202020000220002000000000000000000002200002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022000002020000000000000000000202020202022200220002000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000220000020000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000220000000000000000000011111111111111112222111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050000000000000000000000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050000000000000000000000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
