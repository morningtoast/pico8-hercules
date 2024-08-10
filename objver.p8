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


-- takes screen x/y and returns nearest rounded screen x/y to match 8px tile position
-- for local screen only, NOT active map or absolute coordinates
function get_nearest_tilepx(x,y)
	y=y-cam_y

	local winx=flr((x)/8)*8
	local winy=flr(((y)/8)*8+cam_y)

	while winy%8>0 do winy+=1 end -- accounts for any off-pixel math

	return winx,winy
end


-- Finds sprite location on the spritesheet
-- Returns sx,sy,sw,sh
function sheet_lookup(spr)
	if spr==2 then return 16,0,7,8 end --green tree
	if spr==5 then return 40,0,7,8 end --orange tree
	if spr==7 then return 56,0,7,8 end --fence
	if spr==33 then return 0,8,16,16 end --2x2 mountain
	if spr==10 then return 80,8,7,8 end --2x2 mountain
	if spr==11 then return 88,8,7,8 end --2x2 mountain
end


orbit={}
function add_orbit(spr)
	
	local obj={
		x=p_cx,y=p_cy,st=0,rad=12,spd=3,dir=0,dx=0,dy=0,
		hb={x=-3,y=-3,w=6,h=6},hp=1,
		spr=spr.spr,clash=0,
		_u=function(me)
			if p_orbit then
				me.x=p_cx+cos(me.dir/1.2)*me.rad
				me.y=p_cy-sin(me.dir/1.2)*me.rad
				me.dir-=.03

				me.ang=atan2(me.x-p_cx, me.y-p_cy)+.75
				spin_meter=min(100,spin_meter+.75) --charge increase

				me.hp=1+flr(9*(spin_meter/100)) --set strength of released item (max 20)
				
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

					if out_of_bounds(me.x,me.y) then del(orbit,me) end
				end
			end

			--printh("hp="..me.hp.." vs clash="..me.clash)

			

			-- drop item if it takes too much damage
			if me.hp<=0 or me.clash>=3 then 
				p_orbit=false
				del(orbit,me) 
			end
		end,
		_d=function(me)
			if p_orbit then
				fillp(0B101101001011010.1)
				line(me.x,me.y,p_cx,p_cy,5)
				fillp()
			end
			draw_rotated(me.sx,me.sy,me.sw,me.sh,me.x,me.y,me.ang,.99)
			--debug_hitbox(me.x,me.y,me.hb)
		end
	}

	-- Find spritesheet location of provided sprite
	-- This is needed for the rotation draw
	
	obj.sx,obj.sy,obj.sw,obj.sh = spr.sx,spr.sy,spr.w*7,spr.h*8--sheet_lookup(spr)

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
	
	local obj=newobj(x,y,3,{x=0,y=0,w=7,h=7},.75,1)
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
	printh("--- object version ---")
	p_x,p_y,p_tx,p_ty=64,100,0,0
	p_hb={x=2,y=0,w=5,h=7}
	p_orbit=false
	chain,chainspr,chainx,chainy=0,false,0,0
	scroll_spd=.05

	--map_layers={}

	cam_y=0
	stream={}
	bullets={}
	pickups={}

	-- tiles that reveal pickups after being destroyed
	drops={
	}

	mobs={}

	land={}


	-- index of where powerups are behind tiles
	-- order of map screens; last entry is first map
	stream={
		{id=1},
		{id=0}, --first map
	}

	land_blocks={
		{
			-- tree
			map_spr=5, --sprite that's used on the map
			kill_spr=20, --sprite used in object, use top sprite if 2h tall (after map is hit)
			sx=40, --spritesheet x for rotation
			sy=0, --spritesheet y for rotation
		},
		{
			-- house
			map_spr=6, --sprite that's used on the map
			kill_spr=37, --sprite used in object, use top sprite if 2h tall (after map is hit)
			sx=48, --spritesheet x for rotation
			sy=0, --spritesheet y for rotation
		},
		{
			-- 1x2 mountain
			map_spr=11, --sprite that's used on the map
			kill_spr=37, --sprite used in object, use top sprite if 2h tall (after map is hit)
			spr_w=1,
			spr_h=2,
			sx=88, --spritesheet x for rotation
			sy=8, --spritesheet y for rotation
		}
	}


	for i=1,#stream do
		local thismap=stream[i]
		thismap.y=i*128-128
		thismap.mapx,thismap.mapy=get_maptxy(thismap.id)

		for c=0,15 do
			for r=0,15 do
				local tspr=mget(thismap.mapx+c,thismap.mapy+r)
				--printh("col="..thismap.mapx+c..","..thismap.mapy+r.."="..tspr)

				ox=8*c
				oy=r*8+thismap.y

				local drop_spr=mget(c,r+16)
				--printh("ow "..c..","..r.." == "..drop_type)

				local land_item=false
				for b in all(land_blocks) do
					local sw=b.spr_w or 1
					local sh=b.spr_h or 1

					if b.map_spr==tspr then
						land_item=true
						local obj={
							mapid=thismap.id,
							x=ox,y=oy,
							spr=b.map_spr,
							kill=b.kill_spr,
							blocker=fget(b.map_spr,0),
							shootable=fget(b.map_spr,1),
							drop=drop_spr,
							hb={x=0,y=0,w=8,h=8},
							w=sw,
							h=sh,
							sx=b.sx,
							sy=b.sy,
							offset=-8*sh+8,
							cx=ox+4,
							cy=oy+4,
							_kill=function(me)
								local tx,ty=screenxy_to_mapxy(me.x,me.y)

								if me.drop>0 and me.drop!=me.spr then
									printh("dropped "..me.drop)
									if me.drop==3 then
										add_mob(me.x,me.y)
									end

									if me.drop==19 then
										drop_heart(me.x,me.y)
									end
								end
								
								mset(tx,ty,me.kill) --turn map into stump
								del(land,me)
							end
							
						}

						-- 1x2 hitbox for tall/cover sprites
						if sh==2 then
							obj.hb={x=0,y=-8,w=8,h=16}
						end

						add(land,obj)

						break
					end
				end -- END: land loop


				-- pre-placed mobs that do not exist within a land item
				if not land_item then

					-- skeleton
					if drop_spr==35 then
						add(mobs,{
							x=ox,y=oy,
							hb={x=0,y=0,w=7,h=7},
							spr=35,
							_u=function(me)

							end,
							_d=function(me)
								spr(me.spr,me.x,me.y)
							end
						})
					end
				end

			end

		end

		--sprinth(thismap.id.."=="..thismap.y)
	end

	printh("land="..#land)
	

	cam_y=#stream*128-128
	p_y=cam_y+110
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
		if o.y>window_top-4 then
			-- stop if collide with player
			-- flag: 0=blocker
			if o.blocker and collide({x=p_aheadx,y=p_aheady,hb=p_hb}, o) then
				p_dx,p_dy=0,0
			end

			-- land collides with bullets
			for b in all(bullets) do
				if collide(b, o) then
					if o.shootable then o:_kill() end
					del(bullets,b)
				end
			end

			-- chain collision
			if chain==1 then
				if collide({x=chainx,y=chainy,hb={x=-1,y=0,w=2,h=1}}, o) then
					
					o:_kill()
					chain=2
					chainspr=o
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
					o:_kill()
				end
			end

			-- collisions when item is spinning and flying
			
		end
	end
	

	p_x+=p_dx
	p_y+=p_dy

	-- limits for player movement
	if p_y<window_top then p_y=window_top end
	if p_y>window_bot-10 then 
		p_y=window_bot-10 
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

			if chainspr then
				p_orbit=true
				add_orbit(chainspr)
			end

			chainspr=false
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
	cls(15)
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
		line(p_cx,p_cy,chainx,chainy,5)
		fillp()
		circfill(chainx,chainy,1,5)

		--debug_hitbox(chainx,chainy,{x=-1,y=0,w=2,h=1})

		if chainspr then
			--[[if chainspr==33 then
				spr(16,chainx-8,chainy, 2,2)
			else
				spr(chainspr,chainx-4,chainy)
			end]]

			spr(chainspr.spr,chainx-4,chainy)
			
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
00000000000444000bb0b3b0003330000000000000bb3b0007777770000000000000000000000000000000000660066000000000000000000000000000000000
00000000000444000040420307373300444444440bb3331007dddd700000000000000000000000000000000066d6666600000000000000000000000000000000
0000000000914990302440000333013044444444b3bb33310777777044004400000000000000000000000000666d666600000000000000000000000000000000
0000000009091909b30420b00000130099999999bbb3333106666660421242120000000000000000000000006d66666600000000000000000000000000000000
0000000009022109340433200333313044499444bb33333106116160210021000000000000000000000b3b0066666d6d00000000000000000000000000000000
000000000002120000443403333111304444444400bb1110061161604212421200000000000000000bbb3330666666d600000000000000000000000000000000
00000000000909000004200033333300444444440004200006116660420042000000000000000000bb33b3336666666600000000000000000000000000000000
00000000000909000404200900000000555555550044220006116660400040000000000000000000bbb333336666666600000000000000000000000000000000
00000000000000000000000007700770000000000006600000060000000000000000000000000000b3b333336666666606600660000000000000000000000000
00000000dd000000000000007007700700000000000dd000000d6000000000000000000000000000bb33b33366d6666666d66666000000000000000000000000
0000000dddd00000006d600070e00e0700000000066dd660066dd6000000000000000000000000000bbb33306dd661666dd66166000000000000000000000000
000000dddddd0000000d6600708ee807000000000dddddd00ddddd0000000000000000000000000000b3330016ddd16616ddd166000000000000000000000000
00000dddddddd00000dd5d000208802000000000000dd000000dd000000000000000000000000000000220001d66d11d1d66d11d000000000000000000000000
0000dddddd1ddd00005050000020020000090000000dd000000dd0000f0000000000000000000000000420001dd1dd1d1dd1dd1d000000000000000000000000
000ddddddd11dd10000000000002200000044000000dd000000dd0004420f00000000000000000000004200011d11d1d11d11d1d000000000000000000000000
00ddddddddd11dd100000000000000000000000000000000000000003302330000000000000000000000000001d00d1001d00d10000000000000000000000000
00dddddddddd11dd0000000000077000000000000000000000033b00000000000000000000000000000000000000000000000000000000000000000000000000
00ddddddddddd11d000022500007d00000000000000000000bb33310000000000000000000000000000000000000000000000000000000000000000000000000
00d1dddddd1ddd1100005550007d57000000000000000000b3bb3331000000000000000000000000000000000000000000000000000000000000000000000000
0011dd1ddd11d1d1025000000707707000000000000000000bb33310000000000000000000000000000000000000000000000000000000000000000000000000
00001111dd11111000000000070dd07060006000005000500b333330000000000000000000000000000000000000000000000000000000000000000000000000
00001011111101000002250000d77500066000060000d60000bb1100000000000000000000000000000000000000000000000000000000000000000000000000
00000001001100000005550000700700055006600d60000000042000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000700700000005500000000000442200000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000010002030101000000010000000001010002000101000000010100000000010100000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000002200000000000000000000002200000000000000000000000000220000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000220000000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000b00000000000000000022060006000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005050500002200000b0b0000000b0000000000000000000000000000000505050505050505050505050500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000505050505000005000b0b0b00000b000b00000007070707070b000000000000000006060000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005050505050505000505050b0b0b00000b0b0b00000000000000000b0b0000000000000000060022000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000505050000000005050b0b0b00000b0b0b002200050500000b0b0b0000000000070700000000220b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000005000000000000050b0b0000000b0b0b000000050500000b0b0b0000000000000000070700000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000b000000000b0b002200050505000b0b000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000b0505220000050500000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000505050000050505000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000505000000000505000000000000000000000000002200002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000505002200000005000000000000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000005050000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000005050000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000230000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000505050000220000130b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000503050505000005000b0b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005130505050313000503050b030b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000030503000000000305030b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000013000000000000050b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
