pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- project name
-- 7/10/24

#include ../inc_debug.p8
#include utilfunc.inc.p8

pal(11,139,1) -- green11 to green139


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


function in_table(t,f)
	for v in all(t) do
		if v==f then return true end
	end

	return false
end

-- returns list of x/y tiles that are colli
function ___collide_with_tiles(x,y,hb,flag)
	local tx_tl,ty_tl=screenxy_to_mapxy(x+hb.x,      y+hb.y)
	local tx_tr,ty_tr=screenxy_to_mapxy(x+hb.x+hb.w, y+hb.y)
	local tx_bl,ty_bl=screenxy_to_mapxy(x+hb.x,      y+hb.y+hb.h)
	local tx_br,ty_br=screenxy_to_mapxy(x+hb.x+hb.w, y+hb.y+hb.h)

	--debugtext=tx_tl..","..ty_tl.."\n"..tx_tr..","..ty_tr
	matches={}
    if fget(mget(tx_tl,ty_tl),flag) then 
		local set={x=tx_tl,y=ty_tl}
		if not in_table(matches,set) then
			add(matches,set) 
		end
	end
	if fget(mget(tx_tr,ty_tr),flag) then 
		local set={x=tx_tr,y=ty_tr}
		if not in_table(matches,set) then
			add(matches,set) 
		end
	end
	if fget(mget(tx_bl,ty_bl),flag) then
		local set={x=tx_bl,y=ty_bl}
		if not in_table(matches,set) then
			add(matches,set) 
		end
	end
	if fget(mget(tx_br,ty_br),flag) then
		local set={x=tx_br,y=ty_br}
		if not in_table(matches,set) then
			add(matches,set) 
		end
	end
	
	--[[if #matches>0 then
		return matches,true
	end]]

	return matches
end

function ___collide_tile(x,y,hb,flag)
	local hits=collide_with_tiles(x,y,hb,flag)
	if #hits>0 then return true end
	return false
end

-- takes screen x/y and returns nearest rounded screen x/y to match 8px tile position
-- for local screen only, NOT active map or absolute coordinates
function get_nearest_tilepx(x,y)
	y=y-cam_y

	local winx=flr((x)/8)*8
	local winy=flr(((y)/8)*8+cam_y)

	while winy%8>0 do winy+=1 end -- accounts for any off-pixel math

	return winx,winy
end

-- tile hit for chain out
function ___chain_hit_tile(x,y)
	local mx,my=screenxy_to_mapxy(x,y)
	local tile_spr=mget(mx,my)

	-- if tile is flag1 blocker
    if fget(tile_spr,0) then
		flip_tile(mx,my)
		tile_has_drop(mx,my,x,y)
		chainspr=tile_spr
		return true
	end

	return false
end

-- bullet hits any map tile
-- see which tile flag it is and respond accordingly
function ___bullet_hit_tile(x,y)
	local mx,my=screenxy_to_mapxy(x,y)
	local tile_spr=mget(mx,my)

	-- if tile is flag1 blocker
    if fget(tile_spr,0) then
		flip_tile(mx,my)
		tile_has_drop(mx,my,x,y)

		return true
	end

	return false
end

function ___collide_top(x,y,hb,flag)
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


-- Looks at provided tile and changes it to corresponding destruction sprite
-- For landscape hits with bullets/chains
function ___flip_tile(mx,my)
	local curid,flipto=mget(mx,my),0

	if curid==2 or curid==5 then flipto=20 end
	if curid==7 then flipto=23 end
	if curid==33 then
		flipto=0
		mset(mx-1,my,flipto)
		mset(mx-1,my-1,flipto)
		mset(mx,my-1,flipto)
	end

	mset(mx,my,flipto)

	return flipto
end

-- Finds sprite location on the spritesheet
-- Returns sx,sy,sw,sh
function sheet_lookup(spr)
	if spr==2 then return 16,0,7,8 end --green tree
	if spr==5 then return 40,0,7,8 end --orange tree
	if spr==7 then return 56,0,7,8 end --fence
	if spr==33 then return 0,8,16,16 end --2x2 mountain
	if spr==10 then return 80,8,8,8 end --2x2 mountain
	if spr==11 then return 88,8,8,8 end --2x2 mountain
end

function destroy_land(obj)
	local tx,ty=screenxy_to_mapxy(obj.x,obj.y)

	for o in all(drops) do
		if o.x==tx and o.y==ty then
			printh("tile "..tx..","..ty.." has a drop")
			

			local sx,sy=get_nearest_tilepx(obj.x,obj.y)

			printh("dropping at "..sx..","..sy)

			o.func(sx,sy)
			

			match=true
			break
		end
	end	

	del(land,obj)
end

orbit={}
function add_orbit(spr)
	
	local obj={
		x=p_cx,y=p_cy,st=0,rad=12,spd=3,dir=0,dx=0,dy=0,
		hb={x=-3,y=-3,w=6,h=6},hp=1,
		spr=spr,clash=0,
		_u=function(me)
			if p_orbit then
				--corad=me.rad/10

				me.x=p_cx+cos(me.dir/1.2)*me.rad
				me.y=p_cy-sin(me.dir/1.2)*me.rad
				me.dir-=.03--me.spd/100

				me.ang=atan2(me.x-p_cx, me.y-p_cy)+.75
				spin_meter=min(100,spin_meter+.75) --charge increase

				me.hp=1+flr(12*(spin_meter/100)) --set strength of released item (max 20)
				
			else
				me.str=1
				if me.dx==0 and me.dy==0 then
					me.dir=atan2(me.x-p_cx, me.y-p_cy)+.25
					me.ang=me.dir+.75
					me.dx,me.dy=dir_calc(me.dir,me.spd-1)
					
				else
					-- item is flying; check for collisions
					me.x+=me.dx
					me.y+=me.dy

					if offscreen(me.x,me.y) then del(orbit,me) end
				end
			end

			printh("hp="..me.hp.." vs clash="..me.clash)

			

			-- drop item if it takes too much damage
			if me.hp<=0 or me.clash>=5 then 
				p_orbit=false
				del(orbit,me) 
			end
		end,
		_d=function(me)
			if p_orbit then
				fillp(0B101101001011010.1)
				line(me.x,me.y,p_cx,p_cy,6)
				fillp()
			end
			draw_rotated(me.sx,me.sy,me.sw,me.sh,me.x,me.y,me.ang,.99)
			--debug_hitbox(me.x,me.y,me.hb)
		end
	}

	-- Find spritesheet location of provided sprite
	-- This is needed for the rotation draw
	
	obj.sx,obj.sy,obj.sw,obj.sh=sheet_lookup(spr)

	-- make hitbox bigger for 16x16 sprites
	if obj.sw>8 then
		obj.hb={x=-4,y=-4,w=10,h=10}
	end

	add(orbit,obj)

	return obj
end


function tile_has_drop(tx,ty,sx,sy)
	local match=false
	for o in all(drops) do
		if o.x==tx and o.y==ty then
			--printh("tile "..tx..","..ty.." has a drop")

			local posx,posy=get_nearest_tilepx(sx,sy)

			o.func(posx,posy)

			match=true
			break
		end
	end

	return match
end


function add_mob(x,y)
	printh("I AM A SNAKE "..x..","..y)
	
	local obj=newobj(x,y,35,{x=0,y=0,w=7,h=7},.75,1)
	obj.hp=1
	obj._u=function(me)
		me.x+=me.dx
		me.y+=me.dy

		if me.hp<=0 then
			del(mobs,me)
		end
	end
	obj._d=function(me)
		spr(me.spr,me.x,me.y)
	end

	add(mobs,obj)
end

function drop_heart(x,y)
	printh("I AM A HEART "..x..","..y)
	local obj={
		x=x,y=y,hb={x=0,y=0,w=7,h=7},
		_u=function(me)
			--me.y+=1

			if collide(me,p_obj) then
				del(pickups,me)
			end

			if me.y>window_bot then del(pickups,me) end
		end,
		_d=function(me)
			spr(19,me.x,me.y)
		end
	}

	add(pickups,obj)
end

function add_debris(x,y)
	for i=0,2 do
		local obj={
			st=0, --0=flight;1=idle;2=sucking in
			x=x,y=y,hb={x=2,y=3,w=3,h=3},
			spr=18,g=.35,floor=y+4,_f=180,
			_u=function(me)
				if me.st==0 then
					me.dy+=me.g
					if me.y>me.floor then 
						me.dx,me.dy=0,0
						me.st=1 
					end
				end

				if me.st==1 then
					local dist=get_distance(me.x,me.y, p_cx,p_cy)
					if dist<20 then
						me.dx,me.dy=dir_calc(atan2(p_cx-me.x, p_cy-me.y),4)
					end

					if dist<5 then del(pickups,me) end
				end
				
				me.y+=me.dy
				me.x+=me.dx

				me._f-=1
				
				
				
				--bullet_hit_tile(me.cx,me.y,)
				if out_of_bounds(me.x,me.y) or me._f<=0 then del(pickups,me) end
			end,
			_d=function(me)
				if me._f<=60 then 
					if me._f%5==0 then
						spr(me.spr,me.x,me.y)
					end
				else
					spr(me.spr,me.x,me.y)
				end
				--debug_hitbox(me.x,me.y,me.hb)
			end
		}

		obj.dx,obj.dy=dir_calc(.21875+.03125*i+rand_neg(rnd(.015)),4)

		add(pickups,obj)
	end

	
end


function offscreen(x,y) return (x<0 or x>130 or y<cam_y or y>cam_y+127) end
function out_of_bounds(x,y) return (x<-16 or x>145 or y<cam_y-16 or y>cam_y+175) end

function mob_snake(x,y)
	add_mob(x,y)
end

-- #loop
function _init()
	printh("--- cam version")
	p_x,p_y,p_tx,p_ty=10,100,0,0
	p_hb={x=2,y=2,w=4,h=4}
	p_orbit=false
	chain,chainspr,chainx,chainy=0,0,0,0
	scroll_spd=.05

	--map_layers={}

	cam_y=0
	stream={}
	bullets={}
	pickups={}

	-- tiles that reveal pickups after being destroyed
	drops={
		{x=40,y=6,func=drop_heart},
		{x=8,y=31,func=mob_snake},
		{x=2,y=31,func=mob_snake},
		{x=6,y=28,func=mob_snake},
		{x=9,y=27,func=drop_heart},
		--{x=25,y=6,spr=3,name="snake2"},
		--{x=4,y=7,spr=19,name="heart"}
	}

	mobs={}

	land={}


	-- index of where powerups are behind tiles

	stream={
		--{x=0,y=-256,bg=4,mapx=0,mapy=0,last=true,id=0,inview=false},
		--{x=0,y=-128,bg=5,mapx=16,mapy=0,id=1,inview=false},
		{id=8},
		{id=2},
	}

	for i=1,#stream do
		local thismap=stream[i]
		thismap.y=i*128-128
		thismap.mapx,thismap.mapy=get_maptxy(thismap.id)

		for c=0,15 do
			for r=0,15 do
				local tspr=mget(thismap.mapx+c,thismap.mapy+r)
				printh("col="..thismap.mapx+c..","..thismap.mapy+r.."="..tspr)

				ox=8*c
				oy=r*8+thismap.y

				if tspr==20 then
					local obj={
						x=ox,y=oy,spr=10,hb={x=0,y=0,w=8,h=8},
						w=1,h=2,offset=-8,
						f=fget(tspr)
					}

					obj.cx=ox+4
					obj.cy=oy+4
					add(land,obj)
				end

				if tspr==37 then
					local obj={
						x=ox,y=oy,spr=11,hb={x=0,y=0,w=8,h=8},
						w=1,h=2,offset=-8,
						f=fget(tspr)
					}

					obj.cx=ox+4
					obj.cy=oy+4
					add(land,obj)
				end
			end

		end

		--sprinth(thismap.id.."=="..thismap.y)
	end

	printh("land="..#land)
	

	cam_y=#stream*128-128
	p_y=cam_y+64
	--printh("camy="..p_y)

	spin_meter=0	
end


function _update60()
    btnl,btnr,btnu,btnd,btnz,btnx=btn(0),btn(1),btn(2),btn(3),btn(4),btn(5)
	btnlp,btnrp,btnzp,btnxp,btnup,btndp=btnp(0),btnp(1),btnp(4),btnp(5),btnp(2),btnp(3)

	cam_y-=scroll_spd

	-- spin power meter
	spin_meter_y=max(1,40-40*(spin_meter/100))
	if not p_orbit then spin_meter=max(0,spin_meter-1) end --cooldown spin meter

	-- camera and map positions
	
	window_top=cam_y
	window_bot=window_top+130

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

	p_aheadx=p_x+p_dx
	p_aheady=p_y+p_dy

	-- loop through land objects
	for o in all(land) do
		if o.y>window_top-4 and o.f==0 then
			-- stop if collide with player
			-- flag: 0=blocker
			if collide({x=p_aheadx,y=p_aheady,hb=p_hb}, o) then
				p_dx,p_dy=0,0
			end

			-- land collides with bullets
			for b in all(bullets) do
				if collide(b, o) then
					destroy_land(o)
					del(bullets,b)
				end
			end

			-- chain collision
			if chain==1 then
				if collide({x=chainx,y=chainy,hb={x=-1,y=0,w=2,h=1}}, o) then
					
					destroy_land(o)
					chain=2
					chainspr=o.spr
				end
			end

			for ob in all(orbit) do

				--local hit = 
				if collide(o,ob) then
					
					if p_orbit then
						ob.clash+=1
						--printh("hit----spin")
					else
						ob.hp-=1
						--printh("hit----fly")
					end

					add_debris(o.cx,o.cy)
					destroy_land(o)
				end
			end

			-- collisions when item is spinning and flying
			
		end
	end
	

	p_x+=p_dx
	p_y+=p_dy

	-- limits for player movement
	if p_y<window_top then p_y=window_top end
	if p_y>window_bot-8 then 
		p_y=window_bot-8 
		--if collide_top(p_x,p_y,p_hb,0) then 
			-- player dies
		--	printh("squish death!") 
		--end
	end
	if p_x<0 then p_x=0 end
	if p_x>120 then p_x=120 end

	p_cx=p_x+4
	p_cy=p_y+3

	p_obj={x=p_x,y=p_y,hb=p_hb}

	if not p_orbit and btnzp then
		-- new bullet only when not chaining
		local obj=newobj(p_cx-3,p_cy,18,{x=2,y=3,w=3,h=3},.25,1.5)
		obj._u=function(me)
				me.y+=me.dy
				me.cx=me.x+3
				me.cy=me.y+3

				--bullet_hit_tile(me.cx,me.y,)

				if offscreen(me.x,me.y) then del(bullets,me) end
			end
		obj._d=function(me)
				spr(me.spr,me.x,me.y)
				--debug_hitbox(me.x,me.y,me.hb)
			end
		add(bullets,obj)
	end

	-- extend chain
	-- pull back chain w/ tile
	-- spin
	-- let go

	--shoot out chain from player
	if not p_orbit and chain==0 and spin_meter<=0 and btnxp then
		chain=1 
		chainx=p_cx
		chainy=p_cy
	end

	 --outgoing chain; check tile collisions
	if chain==1 then
		chainy-=3

		if chainy<=window_top then
			chain=2
		end
	end

	--returning chain
	if chain==2 then 
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

	--printh(p_y-cam_y)

	-- release spinning item
	if p_orbit and btnxp then
		
		p_orbit=false
	end



	for b in all(bullets) do
		for m in all(mobs) do
			if collide(b, m) then
				m.hp-=1
				del(bullets,b)
			end
		end
	end
	
	for k,m in pairs(stream) do
		if m.y>window_bot then del(stream,m) end
	end

	update_loop(orbit)
	update_loop(bullets)
	update_loop(pickups)
	update_loop(mobs)
end


function _draw()
	cls(11)
	camera(0,cam_y)
	
	-- draw maps
	for k,o in pairs(stream) do
		--rectfill(0,o.y,128,o.y+128,o.bg)
		map(o.mapx,o.mapy,0,o.y,16,16)
	end

	

	draw_loop(bullets)
	draw_loop(pickups)
	draw_loop(orbit)
	draw_loop(mobs)

	-- draw chain
	if chain>0 then
		fillp(0B101101001011010.1)
		line(p_cx,p_cy,chainx,chainy,6)
		fillp()
		circfill(chainx,chainy,1,6)

		--debug_hitbox(chainx,chainy,{x=-1,y=0,w=2,h=1})

		if chainspr>0 then
			if chainspr==33 then
				spr(16,chainx-8,chainy, 2,2)
			else
				spr(chainspr,chainx-4,chainy)
			end
			
		end
	end

	-- player
	spr(1,p_x,p_y)
	--debug_hitbox(p_x,p_y,p_hb)

	for k,o in pairs(land) do
		--rectfill(0,o.y,128,o.y+128,o.bg)
		spr(o.spr,o.x,o.y+o.offset,o.w,o.h)
		--debug_hitbox(o.x,o.y,o.hb)
	end
	
	-- fixed UI
	camera()
	-- left side
	rectfill(0,0,7,128,1)
	
	rectfill(1,40,6,spin_meter_y,8) --meter fill
	rect(1,1,6,40,7) --meter border


	-- right side
	rectfill(120,0,127,127,1)
	rect(121,1,126,40,7)

	print(debugtext,1,100,7)
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
00000000000444000003300000333000000000000009900007777770000000000000000000000000000000004444444400000000000000000000000000000000
000000000000f4000033330007373300444444440099990007666670000000000000000000000000000000004444424400000000000000000000000000000000
000000000008ff800033330003330130444444440099990007666670f900f9000000000000000000003030304444444400000000000000000000000000000000
000000000f1878800333331000001300999999990999992007666670941294120000000000000000030303304444444400000000000000000000000000000000
00000000000878800333311003333130444994440999922007777770210021000000000000000000033330334444444400000000000000000000000000000000
0000000000011f000033110033311130444444440099220006666660421242120000000000000000330303304424442400000000000000000000000000000000
00000000000101000002200033333300444444440005500006116160420042000000000000000000033030334444444400000000000000000000000000000000
00000000000101000004200000000000555555550004500006116660330033000000000000000000033333004444444400000000000000000000000000000000
00000000000000000000000007700770000000000006600000060000000000000000000000000000303303034444444400000000000000000000000000000000
00000000dd000000000000007007700700000000000dd000000d6000000000000000000000000000033033304424444400000000000000000000000000000000
0000000dddd00000006d600070e00e0700000000066dd660066dd600000000000000000000000000003333004444444400000000000000000000000000000000
000000dddddd0000000d6600708ee807000000000dddddd00ddddd00000000000000000000000000000220004444424400000000000000000000000000000000
00000dddddddd00000dd5d000208802000000000000dd000000dd000000000000000000000000000000490004444444400000000000000000000000000000000
0000dddddd1ddd00005050000020020000000000000dd000000dd0000f0000000000000000000000000490009444444900000000000000000000000000000000
000ddddddd11dd100000000000022000000f9000000dd000000dd0004420f0000000000000000000000490009999999900000000000000000000000000000000
00ddddddddd11dd10000000000000000000440000000000000000000330233000000000000000000000000000990099000000000000000000000000000000000
00dddddddddd11dd0000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddddddddddd11d000022500007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d1dddddd1ddd1100005550007d5700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0011dd1ddd11d1d10250000007077070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111dd11111000000000070dd0706000600000f0009000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001011111101000002250000d775000660000600009a0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000001001100000005550000700700055006600f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700700000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010002010101000000000000000001010002000101000000010000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0002020202020202222202020202020211111111111100000000001111111111000000221400220000000000140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002200000000000000000000000000000022000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000020202020200000000000000000022220000000000000000141422000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1011101120210202220000020202020200000000000000000200000000020000000000000000222200001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002200020202020200000000000002020000002202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020200222200020202020200000000000202020202220002020000000000000000002204000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002202020202020200000000000000020202000002020000000000000000000014220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002020202020200000000000202020200000000020202020000220002000000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000022000200000200020000000000000202020200000002000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000002200020200000200020000000000000000000200000002020000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0016001500000002020200000000000000000002020202020200002202000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000151600220002020000000000000000000002020202020000220002000000000000000000002200002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000022000002020000000000000000000202020202022200220002000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000220000020000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000220000000000000000000011111111111111112222111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505050000000202020202020000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006060202020000141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000070707070707070214141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001414000000000014141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001414141400000014140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000141414000000000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000141414000000001414001400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400141400001011001414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1400001414002021001414141414140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414000000000000000000000000140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414142525140000001414140000140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414142525140000001414140000140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414002525140000141414141414000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414002525000014141414141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000014141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414140000000014140000000000141400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
