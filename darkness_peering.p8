pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- darkness peering
-- by arjun, brandon, cam, carlo

-- based off a game template by misato 


-- State Machine 

-- game states
-- there are no enum in lua so followed the advice from here: https://www.allegro.cc/forums/thread/605178
game_states = {
	splash = 0,
	room = 1,
	game = 2, 
	gameover = 3,
	victory = 4
}

cam = {
	x=0,
	y=0,
	move = -1
}

flashlight = {
	on = false,
	equipped = false
}

pathfinding = {
	on = false
}

previous_t = t()
dt = 0
sim_speed = 1


state = game_states.splash

function change_state() 
	cls()
	stop_song(400)
	if state == game_states.splash then
 		init_room()
 		state = game_states.room
	elseif state == game_states.room then
 		init_game() 
 		state = game_states.game
	elseif state == game_states.game then
		if player.x == 104 then
			init_victory()
			state = game_states.victory
		else
		init_gameover()
 		state = game_states.gameover 
		end
	elseif state == game_states.gameover then
 		state = game_states.splash
	end
end


-- Entities (aka Player, enemies, etc)

Entity = {}
Entity.__index = Entity

function Entity.create(x,y,spd)
	local new_entity = {}
	setmetatable(new_entity, Entity)

	new_entity.x = x
	new_entity.y = y
	new_entity.lock = 1
	new_entity.speed = spd
	new_entity.face = 0

	return new_entity
end 

function Entity:collide(other_entity) 
	return other_entity.x == self.x and other_entity.y == self.y
end

function Entity:distance_from(other_entity)
	return sqrt(abs(self.x-other_entity.x)^2 + abs(self.y-other_entity.y)^2)
end

-- Add other vars as convenience to this player entity
-- for example, the sprite number or the lives left ;)
-- the following code is to prevent music and sfx repetition
song = 0

function play_song(track)
	if abs(song-track) > 0 then
		music(track)
		song=track
	end
end

function stop_song(timeout)
	if song != 0 then
  		music(-1,timeout)
  		song=0
	end
end


-->8
--game functions and other

function _init()
	cls()
	palt(0, false)
	palt(12,true)
	fram = 0 //amount of frames since start
	////frames to animate thru:
	//player without flashlight
 	respawn_x=53
		respawn_y=20
 	respawn_face=1
 	
	mrespawn = {}
	mrespawn.x=44
	mrespawn.y=20
 	
	pwalk_side = {199,198}
	pidle = {198,198,198,198,198,198,198,197,198}
	pwalk_up = {213,214,215,214}
	pwalk_down = {230,231,232,231}
	//player with flashlight
	fpwalk_side = {3,2,3,2}
	fpidle_side = {2,2,2,2,2,2,2,0,2}
	fpwalk_up = {16,17,18,17}
	fpwalk_down = {33,34,35,34}
	fpidle_down = {34,34,34,34,34,34,34,32,34}
	fpdeath = {48,49,49,50,51,52,53,53,53}
	//monster
	mwalk = {43,44,45}
	mbite =  {12,13,14,15,15,15,14,13,12}
	//lenore
	lwalk_side = {6,7}
	lidle = {6,6,5,6,6,6}
	lwalk_down = {37,38,39,38}
	lwalk_up = {21,22,23,22}
	//random
	mpulse = {201,200,201,202}//note:changed
	shiny = {8,9,10,9}
	
	//items
	set_items()
	
--state = game_states.victory
--init_victory()
	
end

function _update60()
	if state == game_states.splash then   
		update_splash()
	elseif state == game_states.room then
  		update_room()		 
	elseif state == game_states.game then
  		update_game()
	elseif state == game_states.gameover then
  		update_gameover()
	elseif state == game_states.victory then
 			update_victory()
	end
	fram+=1
end

function _draw()
	cls()
	if state == game_states.splash then   
  		draw_splash()
	elseif state == game_states.room then
  		draw_room()
	elseif state == game_states.game then
  		draw_game()
  		write_notes()
 elseif state == game_states.gameover then
  		draw_gameover()
 elseif state == game_states.victory then
 			draw_victory()
	end
end


-- Utils

-- Change this if you use a different resolution like 64x64
SCREEN_SIZE = 128


-- calculate center position in X axis
-- this is asuming the text uses the system font which is 4px wide
function text_x_pos(text)
local letter_width = 4

-- first calculate how wide is the text
local width = #text * letter_width

-- if it's wider than the screen then it's multiple lines so we return 0 
if width > SCREEN_SIZE then 
   return 0 
end 

return SCREEN_SIZE / 2 - flr(width / 2)

end

-- prints black bordered text
function write(text,x,y,color1,color2) 
	for i=0,2 do
  		for j=0,2 do
      		print(text,x+i,y+j, color2)
  		end
	end
	print(text,x+1,y+1,color1)
end 


-- Returns if module of a/b == 0. Equals to a % b == 0 in other languages
function mod_zero(a,b)
	return a - flr(a/b)*b == 0
end

function monster_collide()
	if player:collide(monster) then
		sfx(23)
		change_state()
	end
end 

function monster_proximity(dist)
	if flr(player:distance_from(monster)) == flr(dist/2) then
		sfx(24)
	elseif player:distance_from(monster) < dist then
		play_song(4)
	else
		play_song(8)
	end
end


//get next frame in anim loop
function getframe(anim,fastness)
	return anim[flr(fram/fastness)%#anim+1]
end 

//directional player anims
function animplayer()
	if flashlight.equipped then
			if player.face == 0 then
				if player.lock == 0 then
				spr(getframe(fpwalk_side,10),player.px,player.py,1,1,true)
				else
				spr(getframe(fpidle_side,20),player.px,player.py,1,1,true)
				end
			elseif player.face == 1 then
				if player.lock == 0 then
				spr(getframe(fpwalk_side,10),player.px,player.py)
				else
				spr(getframe(fpidle_side,20),player.px,player.py)
				end
			elseif player.face == 2 then
				if player.lock == 0 then	
					spr(getframe(fpwalk_up,10),player.px,player.py)
				else
					spr(17,player.px,player.py)
				end
			elseif player.face == 3 then
				if player.lock == 0 then
				spr(getframe(fpwalk_down,10),player.px,player.py)
				else
				spr(getframe(fpidle_down,20),player.px,player.py)
				end
			end
	elseif flashlight.equipped == false then
			if player.face == 0 then
				if player.lock == 0 then
				spr(getframe(pwalk_side,10),player.px,player.py,1,1,true)
				else
				spr(getframe(pidle,20),player.px,player.py,1,1,true)
				end
			elseif player.face == 1 then
				if player.lock == 0 then
				spr(getframe(pwalk_side,10),player.px,player.py)
				else
				spr(getframe(pidle,20),player.px,player.py)
				end
			elseif player.face == 2 then
				if player.lock == 0 then	
					spr(getframe(pwalk_up,10),player.px,player.py)
				else
					spr(214,player.px,player.py)
				end
			elseif player.face == 3 then
				if player.lock == 0 then
				spr(getframe(pwalk_down,10),player.px,player.py)
				else
				spr(getframe(pidle,20),player.px,player.py)
				end
			end
	end
end

-->8
--splash

function update_splash()
	play_song(3)
 -- usually we want the player to press one button
 if btnp(4) then
   change_state()
 end
end


function draw_splash() 
	cls()
	spr(109,58,30)
	write("darkness peering",29,45,0,1)
	write("main menu", 43,60,0,1)
	write("press z to begin",30,70,0,1)
end

-->8
--room

function init_room() 
 cam.x = 0
 cam.y = 0
 player = Entity.create(116,3,2)
 monster = Entity.create(116,43,1)
 player.px = 88
 player.py = 24
 monster.px = 88
 monster.py = 336
 
 flashlight.on = false
 pathfinding.on = false
 flashlight.equipped = false
end

function update_room()
	
 	play_song(11)
		handle_input()
 	move()
 	move_monster()
 	//monster_proximity(3)

	if player.x == 111 and (player.y == 43 or player.y == 44 or player.y == 42) then
		pathfinding.on = true
		pathfind()
	end

end


function draw_room()
	cls()
	map(105,0,0,0,16,46)
	if (player.y > 41) spr(getframe(mwalk,15),monster.px,monster.py,1,2)
	
 draw_lenore()
	if flashlight.on then
		draw_light()
		--write("press z to go to game state", 20, 350, 0,1)
		write("the breaker box should",35,100,0,5)
		write("be this way",55,108,0,5) 
	else 
		rectfill(cam.x,cam.y,cam.x+128,cam.y+128,0)
   if not flashlight.equipped then
	   if player.x>=113 and player.y<=3 then
			  write("the power's out", 20, 90, 0,5)
	   end
	   if (player.x<113 and player.x>110 and player.y<5) or (player.x>110 and player.y>=4 and player.y<=5) then 
	    write("where's my flashlight?",20,90,0,5)
	   end
	   if (player.x<110) and not flashlight.equipped then 
	    write("grab flashlight with x",20,90,0,5)
	   	write("turn on/off with z",20,98,0,5)
	   end
	  	spr(109,16,32)
  	end
 end
 
	update_cam()
	
	animplayer()
	camera(cam.x,cam.y)
		
	-- credits:
	write("lead programmer:", 50, 128, 0,1)
 write("arjun kahlon", 60, 138, 0,1)
 write("art and animation:", 50, 148, 0,1)
	write("brandon fields", 60, 158, 0,1)
	write("story and notes:", 18, 203, 0,1)
	write("cam tangalakis", 28, 213, 0,1)
	write("music and level design:", 10, 223, 0,1)
	write("carlo safra", 28, 233, 0,1)
	write("special thanks:", 18,268,0,1)
	write("joshua mccoy", 28, 278, 0,1)
end

function draw_light()
	if flashlight.on then
  if player.face == 0 then
   rectfill(cam.x, cam.y, player.px-40, cam.y+128, 0)
   rectfill(player.px+9, cam.y, cam.x+128, cam.y+128, 0)
   rectfill(player.px, cam.y, player.px+8, player.py-2)
   rectfill(player.px, player.py+9, player.px+8, cam.y+128)
   pset(player.px+8,player.py-1,0)
   pset(player.px+8, player.py+8,0)
   for i=0,128 do
    line(player.px-1,player.py-2-i,player.px-40,player.py-17-i)
    line(player.px-1,player.py+9+i,player.px-40,player.py+24+i)
 		end
  elseif player.face == 1 then
   rectfill(cam.x, cam.y, player.px-2, cam.y+128, 0)
   rectfill(player.px+48, cam.y, cam.x+128, cam.y+128, 0)
   rectfill(player.px-1, cam.y, player.px+7, player.py-2)
   rectfill(player.px-1, player.py+9, player.px+7, cam.y+128)
   pset(player.px-1, player.py-1, 0)
   pset(player.px-1, player.py+8, 0)
   for i=0,128 do
	   line(player.px+8,player.py-2-i,player.px+48,player.py-17-i)
	   line(player.px+8,player.py+9+i,player.px+48,player.py+24+i)
   end
  elseif player.face == 2 then
   rectfill(cam.x, cam.y, cam.x+128, player.py-40, 0)
   rectfill(cam.x, player.py+9, cam.x+128, cam.y+128, 0)
   rectfill(cam.x, player.py-1, player.px-2, player.py+9, 0)
   rectfill(player.px+9, player.py-1, cam.x+128, player.py+9, 0)
   pset(player.px-1, player.py+8,0)
   pset(player.px+8, player.py+8,0)
   for i=0,128 do
	   line(player.px-2-i,player.py-2,player.px-17-i,player.py-48)
	   line(player.px+9+i,player.py-2,player.px+24+i,player.py-48)
			end
  elseif player.face == 3 then
   rectfill(cam.x, cam.y, cam.x+128, player.py-2, 0)
   rectfill(cam.x, player.py+48, cam.x+128, cam.y+128, 0)
   rectfill(cam.x, player.py-1, player.px-2, player.py+9, 0)
   rectfill(player.px+9, player.py-1, cam.x+128, player.py+9, 0)
   pset(player.px-1, player.py-1,0)
   pset(player.px+8, player.py-1,0)
   for i=0,128 do
    line(player.px-2-i,player.py+9,player.px-17-i,player.py+48)
    line(player.px+9+i,player.py+9,player.px+24+i,player.py+48)
 		end
  end
	end
end


-->8
--game

function init_game()
	player.x = respawn_x
	player.y = respawn_y
	player.face=respawn_face
	recenter_map()
	monster.x = mrespawn.x
	monster.y = mrespawn.y
	player.px = player.x*8
	player.py = player.y*8
	monster.px = monster.x*8
	monster.py = monster.y*8
	flashlight.on = true
	flashlight.equipped = true
	pathfinding.on = true
	monster.speed = 3
	pathfind()
	mreset()
end

function update_game()

	if player.x == 104 then
		change_state()
	end

	dt = t() - previous_t
	dt *= sim_speed
	handle_input()
	move()
	move_monster()
	previous_t = t()

	monster_proximity(12)

	if fget(mget(player.x,player.y),7) then 
	 	pathfinding.on = false
	else 
		pathfinding.on = true
	end
end

function draw_game()
cls()
map(0,0,0,0,106,46)
	
spr(getframe(mwalk,15),monster.px,monster.py-8,1,2) //monster	
draw_lenore()

if flashlight.on then
	draw_light()
else 
	rectfill(cam.x,cam.y,cam.x+128,cam.y+128,0)
end
update_cam()
animplayer()

camera(cam.x,cam.y)
if #path < 15 then
	monster.speed = 3
elseif #path < 30 then
	monster.speed = 2
else
	monster.speed = 1
end

	if flashlight.on == false then
	   for point in all(path) do
			spr(getframe(mpulse,10),point[1]*8, point[2]*8)
	   end
	end
end

function pathfind()
	if pathfinding.on then 
		printh("---------------")
		printh("starting a star")
	
		wallFlag = 0
		start = {monster.x, monster.y}
		goal = {player.x, player.y}

		printh("start...")

		frontier = {}
		insert(frontier, start, 0)
		came_from = {}
		came_from[vectoindex(start)] = nil
		printh("start inserted")
		cost_so_far = {}
		cost_so_far[vectoindex(start)] = 0
		found_goal=false
		while (#frontier > 0 and #frontier < 10000) do
			current = popEnd(frontier)
	
			if vectoindex(current) == vectoindex(goal) then
				found_goal=true
				break
			end
	
			local neighbours = getNeighbours(current)
			for next in all(neighbours) do
				local nextIndex = vectoindex(next)

				local new_cost = cost_so_far[vectoindex(current)]  + 1 -- add extra costs here

				if (cost_so_far[nextIndex] == nil) or (new_cost < cost_so_far[nextIndex]) then
					cost_so_far[nextIndex] = new_cost
					local priority = new_cost + heuristic(goal, next)
					insert(frontier, next, priority)
		
					came_from[nextIndex] = current

				end 
			end
		end
		printh(goal)
		printh(vectoindex(goal))
		printh(#came_from)
		printh(came_from[vectoindex(goal)])
		if found_goal then
			current = came_from[vectoindex(goal)]
			if (not current) return
			printh("find goal..")
			path = {}
			local cindex = vectoindex(current)
			printh("cindex")
			local sindex = vectoindex(start)
			printh("sindex")
			while cindex != sindex do
				add(path, current)
				current = came_from[cindex]
				cindex = vectoindex(current)
			end
			reverse(path) 
			printh("..done")
		end
	end
end

   
   -- manhattan distance on a square grid
   function heuristic(a, b)
	return abs(a[1] - b[1]) + abs(a[2] - b[2])
   end
   
   -- find all existing neighbours of a position that are not walls
   function getNeighbours(pos)
	local neighbours={}
	local x = pos[1]
	local y = pos[2]
	if x > 0 and not fget(mget(x-1,y), wallFlag) then
	 add(neighbours,{x-1,y})
	end
	if x < 105 and not fget(mget(x+1,y), wallFlag) then
	 add(neighbours,{x+1,y})
	end
	if y > 0 and not fget(mget(x,y-1), wallFlag) then
	 add(neighbours,{x,y-1})
	end
	if y < 45 and not fget(mget(x,y+1), wallFlag) then
	 add(neighbours,{x,y+1})
	end
   
	-- for making diagonals
	if (x+y) % 2 == 0 then
	 reverse(neighbours)
	end
	return neighbours
   end
   
   -- find the first location of a specific tile type
   

   
   -- insert into table and sort by priority
   function insert(t, val, p)
	if #t >= 1 then
	 add(t, {})
	 for i=(#t),2,-1 do
	  
	  local next = t[i-1]
	  if p < next[2] then
	   t[i] = {val, p}
	   return
	  else
	   t[i] = next
	  end
	 end
	 t[1] = {val, p}
	else
	 add(t, {val, p}) 
	end
   end
   
   -- pop the last element off a table
   function popEnd(t)
	local top = t[#t]
	del(t,t[#t])
	return top[1]
   end

   function popFront(t)
	local top = t[1]
	del(t,t[1])
	return top[1]
   end
   
   function reverse(t)
	for i=1,(#t/2) do
	 local temp = t[i]
	 local oppindex = #t-(i-1)
	 t[i] = t[oppindex]
	 t[oppindex] = temp
	end
   end
   
   -- translate a 2d x,y coordinate to a 1d index and back again
   function vectoindex(vec)
	return maptoindex(vec[1],vec[2])
   end
   function maptoindex(x, y)
	return ((x+1) * 16) + y
   end
   function indextomap(index)
	local x = (index-1)/16
	local y = index - (x*w)
	return {x,y}
   end
   
   
   -- pop the first element off a table (unused
   function pop(t)
	local top = t[1]
	for i=1,(#t) do
	 if i == (#t) then
	  del(t,t[i])
	 else
	  t[i] = t[i+1]
	 end
	end
	return top
   end


-- Player input
counter = 0
function handle_input()
-- button 1
  if btnp(4) and flashlight.equipped then
  	if flashlight.on then
  			flashlight.on = false
  			sfx(29)
  	else
  			flashlight.on = true
  			sfx(28)
  	end
		end
	if player.lock == 1 then
		if btn(0) then
  		player.face = 0
    if (fget(mget(player.x-1,player.y), 1)) player.lock = 0
  elseif btn(1) then
				player.face = 1
				if (fget(mget(player.x+1,player.y), 1)) player.lock = 0
		elseif btn(2) then
				player.face = 2
				if (fget(mget(player.x,player.y-1), 1)) player.lock = 0
		elseif btn(3) then
				player.face = 3
				if (fget(mget(player.x,player.y+1), 1)) player.lock = 0
		end
		if btnp(4) and btn(5) then
			change_state()
		end
  -- button 2
  if btnp(5) then
  	interact()
  end
 end
end

mcount = 0;

function move()
if player.lock == 0 then
		if player.face == 0 then
  		mcount += 1
				if (mcount%player.speed == 0) player.px -= 1
				if (mcount == player.speed*8) then
  				player.x-=1
  				sfx(26)
    		if (player.x%15 == 0) cam.move = 0
						mreset()
				end
		end
		if player.face == 1 then
				mcount+=1
				if (mcount%player.speed == 0) player.px+=1
				if (mcount == player.speed*8) then
	   		player.x+=1
  				sfx(26)
	     if (player.x%15 == 0) cam.move = 1
						mreset()
				end
		end
		if player.face == 2 then
				mcount+=1
    if (mcount%player.speed == 0) player.py-=1
				if (mcount == player.speed*8) then
    		player.y-=1
  				sfx(26)
      if (player.y%15 == 0 and not cam.center) cam.move = 2
						mreset()
				end
		end
 	if player.face == 3 then
				mcount+=1
    if (mcount%player.speed == 0)  player.py+=1
				if (mcount == player.speed*8) then
    		player.y+=1
  				sfx(26)
      if (player.y%15 == 0 and not cam.center) cam.move = 3
						mreset()
				end
		end
end
end

function mreset()
player.lock = 1
mcount=0
mmreset()
end

mmcount = 0
function move_monster()
	if cam.move == -1 and pathfinding.on then
		mmcount += 1
		if (mmcount == monster.speed*8) mmcount = 0
		if path[1] then
			if (mmcount%monster.speed == 0) then
				if path[1][1] > monster.x then
					monster.px+=1
					if monster.px%8 == 0 then
						monster.x+=1
						popFront(path)
					end
				elseif path[1][1] < monster.x then
					monster.px-=1
					if monster.px%8 == 0 then
						monster.x-=1
						popFront(path)
				 	end
				elseif path[1][2] > monster.y then
					monster.py+=1
					if monster.py%8 == 0 then
						monster.y+=1
						popFront(path)
					end
				elseif path[1][2] < monster.y then
					monster.py-=1
					if monster.py%8 == 0 then
						monster.y-=1
						popFront(path)
					end
				end
			end
				else
			if (mmcount%monster.speed == 0) then
				if player.x > monster.x then
					monster.px+=1
					if monster.px%8 == 0 then
						monster.x+=1
						mmreset()
					end
				elseif player.x < monster.x then
					monster.px-=1
					if monster.px%8 == 0 then
						monster.x-=1
						mmreset()
					end
				elseif player.y > monster.y then
					monster.py+=1
					if monster.py%8 == 0 then
						monster.y+=1
						mmreset()
					end
				elseif player.y < monster.y then
					monster.py-=1
					if monster.py%8 == 0 then
						monster.y-=1
						mmreset()
					end
				end
			end
		end
	end
end

function mmreset()
	if monster.x == player.x and monster.y == player.y then
		sfx(23)
		change_state()
		return
	else
		pathfind()
	end
end


function update_cam()
if (cam.move != -1) player.lock = 3
if cam.move == 0 then
  cam.x-=2
  if (cam.x%120 == 0) creset()
elseif cam.move == 1 then
  cam.x+=2
  if (cam.x%120 == 0) creset()
elseif cam.move == 2 then
  cam.y-=2
  if (cam.y%120 == 0) creset()
elseif cam.move == 3 then
  cam.y+=2
  if (cam.y%120 == 0) creset()
end
end

function creset()
player.lock = 0
cam.move = -1
end


-->8
-- game over/victory

function init_gameover() 
	camera(0,0)
end

function update_gameover()
	play_song(1)
	if btnp(4) then
		 init_game() 
 		state = game_states.game
	end
end

function draw_gameover()
	write("gameover", 45,60, 0,1)
	write("press z to respawn", 24, 70, 0,1)
 spr(getframe(mbite,11),50,90,1,2)
	spr(getframe(fpdeath,11),53,98)
end

function recenter_map()

cam.x = flr(player.x/15)*120
cam.y = flr(player.y/15)*120

end

-----------------------------

--victory screen stuff

function init_victory()
 			sfx(32)
    camera(0,0)
end

function draw_victory()
    cls(6)
    write("'deep into that",3,14,13,0)
 write("  darkness peering,",42,22,13,0)

    write("long i stood there",7,30,13,0)
 write("  wondering, fearing,",42,38,13,0)

 write("doubting, dreaming",7,46,13,0)
 write("  dreams no mortal",42,54,13,0)

 write("ever dared to",7,62,13,0)
 write("  dream before.'",42,70,13,0)

 write(" -edgar allen poe",23,84,13,0)
 spr(getframe(fpwalk_side,11),59,97)
    spr(getframe(lwalk_side,11),67,97)

 write("press z to play again",23,112,6,0)
end

function update_victory()
 if btnp(4) then
        run()
    end
end
-->8
--items and lenore

--locations
--switch 1: (055,03) -> gate 6
--switch 2: (100,03) -> gate 5
--switch 3: (026,06) -> gate 2
--switch 4: (063,22) -> gate 1
--switch 5: (051,36) -> gate 4
--switch 6: (017,42) -> gate 3

--lenore locations:

--l1: (107,11) -> goes down (in room)
--l2: (68,9) -> goes left
--l3: (101, 9) -> goes up
--l4: (25, 11) -> goes up
--l5: (095,21) -> goes right
--l6: (72, 36) -> goes left
--l7: (16, 40) -> goes right or down


 function interact()
	if player.face == 0 then
		check_items(-1,0)
	elseif player.face == 1 then
		check_items(1,0)	
	elseif player.face == 2 then
		check_items(0,-1)	
	elseif player.face == 3 then
		check_items(0,1)	
	end
end

function check_items(face_x,face_y)
	local location = mget(player.x+face_x,player.y+face_y)
	if fget(location,3) then //flashlight
		flashlight.equipped = true
  flashlight.on = true
  sfx(25)
  mset(107,4,110)	
  mset(116,7,75)
  mset(117,7,75)
	end
	if fget(location,4) then //lever
		switch_on(player.x+face_x,player.y+face_y)	
	end
end

switch_list={}
gate_list={}
lenore_list={}
mrespawn_list={}

switch = {}
switch.__index = switch

function switch.create(x,y,gate)
	local new_switch = {}
	setmetatable(new_switch, switch_list)
	
	new_switch.x = x
	new_switch.y = y
	new_switch.on = false
	new_switch.gate = gate
	return new_switch
end

function set_items()
	local gate_num = {6,5,2,1,4,3}
	lenore_list[1] = Entity.create(107,11,1)
	lenore_list[#lenore_list].px = 16
	lenore_list[#lenore_list].py = 88
	for y=0,45 do
		for x=0,121 do
			local sprite = mget(x,y)
			if fget(sprite,6) then
				mrespawn_list[#mrespawn_list+1] = switch.create(x,y)
				mset(x,y,65)
			end
			if fget(sprite,2) then
			
				lenore_list[#lenore_list+1] = Entity.create(x,y,1)
				lenore_list[#lenore_list].px = 8*lenore_list[#lenore_list].x
				lenore_list[#lenore_list].py = 8*lenore_list[#lenore_list].y
				mset(x,y,86)
			end
			if fget(sprite,4) then
				switch_list[#switch_list+1] = switch.create(x,y,gate_num[#switch_list+1])
			end
			if fget(sprite,5) then
				gate_list[#gate_list+1]=switch.create(x,y)
			end
		end
	end
end

function switch_on(x,y)
	for v in all(switch_list) do
		if v.x==x and v.y==y and v.on==false then
			v.on = true
			sfx(31)
			mset(x,y,255)
			respawn_x = player.x
			respawn_y = player.y
			mrespawn = m_respawn()
			respawn_face = player.face
			open_gate(v.gate)
		end
	end
end

function open_gate(num)
	gate_list[num].on = true
	mset(gate_list[num].x,gate_list[num].y,223)
end

function draw_lenore()
	if #lenore_list > 0 then
		if state == game_states.room then
	  lenore_prox(lenore_list[1])
		elseif state == game_states.game then	
			local closest = lenore_list[2]
			for v in all(lenore_list) do
				if min(player:distance_from(closest),player:distance_from(v)) < player:distance_from(closest) then
					closest = v
				end
			end
			lenore_prox(closest)
		end
	end
end

function lenore_prox(i)

	spr(getframe(lidle,20),i.px,i.py)
	if cam.move != 0 and flashlight.on == true and flr(i:distance_from(player)) <= 4 then
		lenore_seen(i)
	end
end

function lenore_seen(i)
	if i.x==107 and i.y==11 then
		lenore_move(i,0,1)
	elseif i.x==68 and i.y==9 then
		lenore_move(i,-1,0)
	elseif i.x==101 and i.y==9 then
		lenore_move(i,0,-1)
	elseif i.x==25 and i.y==11 then
		lenore_move(i,0,-1)
	elseif i.x==95 and i.y==21 then
		lenore_move(i,1,0)
	elseif i.x==72 and i.y==36 then
		lenore_move(i,-1,0)
	elseif i.x==16 and i.y==40 then
		if player.face==0 then
			lenore_move(i,0,1)	
		else
			lenore_move(i,1,0)
		end	
	end
end

lmcount = 0
function lenore_move(i,dx,dy)
	lmcount += 1
	if lmcount%i.speed == 0 then 
		i.px += dx
		i.py += dy
	end
	if (lmcount ==i.speed*8) and lmcount < i.speed*40 then
		sfx(26)
	end
	if (lmcount == 5* i.speed*8) then
		lmcount=0
		del(lenore_list, i)
	end
end

function m_respawn()
	local closest = mrespawn_list[1]
	for i in all(mrespawn_list) do
		if min(player:distance_from(closest),player:distance_from(i)) < player:distance_from(closest) then
			closest = i
		end
	end
	return closest
end
-->8
--ui and notes
--[[note coordinates:
5,13
4,18
2,43
29,26
37,9
51,41
56,28
54,14
83,32
93,2
]]

read = false
function write_notes()
  if player.x == 54 and player.y == 14 then 
    printbox(0,1,21,40,"sometimes darkness",'says more than light.','press x to finish reading','','','','','','')
  elseif player.x == 4 and player.y == 18 then 
    printbox(0,1,53,0,"   go this way",'turn back','                 no this way','   keep going',"          you're almost there",'','press x to finish reading','','')
  elseif player.x == 5 and player.y == 13 then 
    printbox(0,1,53,8,"it chases me, but i've been",'clever. i found places to','hide where it cannot smell me','it cannot taste me','   i am almost free','','press x to finish reading','','')
  elseif player.x == 37 and player.y == 9 then 
    printbox(0,1,37,24,"it chases us. it eats us.",'it will find you.','       it is free','','press x to finish reading','','','','')
  elseif player.x == 2 and player.y == 43 then 
    printbox(0,1,61,0,"here in the dark, it reeks of",'death. shine a light at it','and it will sizzle, crumble,','and fade away. it keeps the','light out. it hates the light.','the light is your only hope.','','press x to finish reading','')
  elseif player.x == 29 and player.y == 26 then 
    printbox(0,1,37,24,"don't trust anyone.",'',"       don't trust yourself",'','press x to finish reading','','','','')
  elseif player.x == 51 and player.y == 41 then 
    printbox(0,1,21,40,"it's coming for us",'','press x to finish reading','','','','','','')
  elseif player.x == 56 and player.y == 28 then 
    printbox(0,1,61,0,"all around the mullberry bush",'the monkey chased the weasel','the monkey thought it all in','  good fun. ','    pop!','goes the weasel!','','press x to finish reading','')
  elseif player.x == 83 and player.y == 32 then 
    printbox(0,1,69,0,"to my dearest eleanor,",'i write to you from the end','of my life. you have meant all','the world to me, and i wish','you to find some happiness now','that i have gone. do not mourn','for me, i am always with you.','','press x to finish reading')
  elseif player.x == 93 and player.y == 2 then 
    printbox(0,1,21,40,"you can't run. you can't hide.",'','press x to finish reading','','','','','','')
  elseif player.x == 62 and player.y == 20 then 
    printbox(0,5,29,24,"     there's a gate ahead",'find the switch, open the path','','press x to finish reading','','','','','')
  else
  	read = false
  end
end 


function printbox(c1,c2,boxy,ybuff,
                  txt1, txt2, 
                  txt3, txt4,
                  txt5, txt6,
                  txt7,txt8,
                  txt9)
 if fget(mget(player.x,player.y),7) and not read then 
  
  player.lock=3
  if btnp(5) then
  	player.lock=1
  	read = true
  end	
  
  pathfinding.on = false

  if player.y%16>8 then 
   rectfill(cam.x+1,
            cam.y+1,
            cam.x+127,
            cam.y+6+boxy,
            c1)
   rect(cam.x+2,
        cam.y+2,
        cam.x+126,
        cam.y+5+boxy,
        c2)

    local txty = 0 
    print(txt1,cam.x+4,cam.y+4,c2)
    print(txt2,cam.x+4,cam.y+12,c2)
    print(txt3,cam.x+4,cam.y+20,c2)
    print(txt4,cam.x+4,cam.y+28,c2)
    print(txt5,cam.x+4,cam.y+36,c2)
    print(txt6,cam.x+4,cam.y+44,c2)
    print(txt7,cam.x+4,cam.y+52,c2)
				print(txt8,cam.x+4,cam.y+60,c2)
				print(txt9,cam.x+4,cam.y+68,c2)
  
  else 
   rectfill(cam.x+1,
            cam.y+68+ybuff,
            cam.x+127,
            cam.y+72+boxy+ybuff,
            c1)
   rect(cam.x+2,
        cam.y+69+ybuff,
        cam.x+126,
        cam.y+72+boxy+ybuff,
        c2)

    local txty = 0 
    print(txt1,cam.x+4,cam.y+71+ybuff,c2)
    print(txt2,cam.x+4,cam.y+79+ybuff,c2)
    print(txt3,cam.x+4,cam.y+87+ybuff,c2)
    print(txt4,cam.x+4,cam.y+95+ybuff,c2)
    print(txt5,cam.x+4,cam.y+103+ybuff,c2)
    print(txt6,cam.x+4,cam.y+111+ybuff,c2)
    print(txt7,cam.x+4,cam.y+119+ybuff,c2)
  end
 else 
  pathfinding.on = true
 end
end
-->8
--juice effects
--glitch, shake, particles

function juice_init()
  glit = {}
  glit.height=128 
  glit.width=128
  parts={} 
  partgen = true
  x=63 
  y=63
  shake = 0 
end


-------------------------------
--shake 

function shake_draw()
  shakes(4, 4, 0.6)
end 

function shakes(volx, voly, dur)
  local shakex = volx-rnd(volx*2)
  local shakey = voly-rnd(voly*2) 
  
  shakex *= shake
  shakey *= shake 
  camera(shakex, shakey)
  shake *= 0.9
  
  if shake < dur then
    shake = 0
  end 
end




------------------------------
--parts 

function part_update()  
print("fck yeah",cam.x,cam.y+30,8)
  part_gen(player.x,
           player.y+4,
           rnd(8)-4,
           rnd(2)-1,
           3,
           rnd(1),
           0.3) 
   
  for d in all(parts) do 
    d:update() 
  end 
end 

function part_draw() 
  for d in all(parts) do 
    d:draw() 
  end 
end 

function part_gen (_x,_y,_dx,_dy,_l,_s,_g,_f)
  add(parts, 
      {fade=_f, 
       x=_x, 
       y=_y, 
       dx=_dx, 
       dy=_dy, 
       len=_l, 
       orig_len=_l, 
       siz=_s, 
       col=8, 
       grav=_g,   
draw=function(self) 
  pal() 
  palt() 
  circfill(self.x, self.y,self.siz,self.col) end, 

update=function(self) 
  self.x+=self.dx self.y+=self.dy 
  self.dy+=self.grav 
  self.siz*=0.9 
  self.len-=1 
  
  if self.len<0then 
   del(parts,self) 
  end 
 end}) 
end





---------------------------------
--glitch

function glitch()
   if g_on == true then 
     local t={7,2,5}
     local c=rnd(3) 
     c=flr(c) 
     
     for i=0, 5, 4 do 
       local gl_height = rnd(glit.height)
       
       for h=0, 100, 2 do 
         pset(rnd(glit.width), gl_height, t[c]) -- write rand pixels to screen/rand colors from previously gen rand against color array
       end 
     end 
   end

 if glit.t>30 and glit.t < 50 then
   g_on=true
 elseif glit.t>70 and glit.t < 80 then
   g_on=true
 elseif glit.t>120 then
   glit.t = 0
 else 
   g_on=false
 end
 
 glit.t+=1
end

-->8
--music/sfx notes
//mus:1-2 sfx:8-11 death theme
//mus:3 sfx:12-13 menu theme
//sfx 14 heartbeat regular
//sfx 15 heartbeat fast
//mus:4-7 sfx:16-18 chase music
//mus:8 sfx 19-21 ambience 
//sfx:22 monster run
//sfx:23 player death sound
//sfx:24 monster growl
//sfx:25 pickup
//sfx:26 player walk
//sfx:27 put down
//sfx:28 flash on
//sfx:29 flash off
//sfx:30 teleport
//sfx:31 flipping switches

__gfx__
cccccccccc444ccccccccccccc444cccccccccccc00000ccc00000ccc00000cccccccccccccccccccccccccccccccccccc1151ccccc157ccc15751ccc10075cc
cc444cccc44444cccc444cccc44444ccccccccccc0ffffccc0f3f3ccc0f3f3ccccccccccccccccccccccccccccccccccc155071ccc1570ccc170051cc500001c
c44444ccc41ff1ccc44444ccc41ff1ccccccccccc0ffffccc0ffffccc0ffffcccccccccccccccccccccccccccccccccc1570051ccc5500cc1550751c1000075c
c4ffffccc4ffffccc41ff1ccc4ffffccccccccccc0262cccc0262cccc0262cccccaccccccccccccccacacccccccccccc1507511cc17007075700051157000051
c4ffffccc43335acc4ffffccc43335acccccccccc0222cccc0222cccc0222ccccaaaccccccacccccccaccccccccccccc107511cc1500715c5000755150000075
c43335accc111cccc43335accc111ccccccccccccc222ccccc222ccccc222cccccaccccccccccccccacacccccccccccc150751cc1107511c1700075117000005
cc111cccc1ccc1cccc111cccc1ccc1cccccccccccc222ccccc222ccccc222cccccccccccccccccccccccccccccccccccc570511cc550711cc500005110000075
cc1c1ccccccccccccc1c1cccccccccccccccccccccdcdcccccdcdccccdcccdccccccccccccccccccccccccccccccccccc150751cc17005ccc570075170000005
cc444ccccccccccccc444cccccccccccccccccccc00000ccc00000ccc00000ccccccccccccccccccd00066d5cccccccccc7051cccc5071cc1150751c10000751
c44444cccc444cccc44444ccccccccccccccccccc00000ccc00000ccc00000cccccccccccc0ccccc60000065ccccccccc15071ccc117551c157001cc17000075
c44444ccc44444ccc44444ccccccccccccccccccc0000fccc00000cccf0000cccccccccccc0cccccd5550066cc0cc0ccc15051ccc150075c5000751c70000005
c44444ccc44444ccc44444ccccccccccccccccccc0000cccc00000cccc0000cccccccccccc0ccccc660655d2ccccccccc15705cc115700715700005150000075
cc444accc44444cccc444accccccccccccccccccc0000cccc00000cccc0000cccccccccccc0cccccd600052dcc0cc0ccc115751c115000057000075170000051
ccd115cccc444acccc11d5cccccccccccccccccccc222ccccc222ccccc222ccccccccccccc000ccc56006506cc0000cc1115051c170700750000000510000075
cccccccccc1115cccccccccccccccccccccccccccc522ccccc222ccccc225ccccccccccccccccccc6d86550dcccccccc11507511700007057000007570000000
cccccccccc1c1cccccccccccccccccccccccccccccccccccccdcdcccccccccccccccccccccccccccd6585656cccccccc15075111007515515700000510000007
cccccccccc444ccccccccccccc444cccccccccccc00000ccc00000ccc00000cc052222255520d5d566555056cc5115cccc1157ccc557cccccccccccccccccccc
cc444cccc44444cccc444cccc44444ccccccccccc0f3f3ccc0f3f3ccc0f3f3cc2505502025d002d2d2565856c51111cccc517cccc7557ccccccccccccccccccc
c44444ccc41ff1ccc44444ccc41ff1ccccccccccc0ffffccc0ffffccc0ffffcc0255552552d00d20625058d6c11155cccc7557cccc7551cccccccccccccccccc
c4ffffccc4ffffccc41ff1ccc4ffffccccccccccc0262cccc0262cccc0262ccc020ddd20022000d52d606565c11507cccc005507cc0511cccccccccccccccccc
c4ffffccca333cccc4ffffccca333cccccccccccc0222cccc0222cccc0222ccc065ddd500d0000d5d50006d611170ccccc00515cc575111ccccccccccccccccc
ca333ccccc11dcccca333cccccd11ccccccccccccc222ccccc222ccccc222ccc0020005020020200500000061150cccccc07511c1151111ccccccccccccccccc
cc111ccccccccccccc111ccccccccccccccccccccc225ccccc222ccccc522cccd26d2d666266d226d68866d85557cccccc00511c1111115ccccccccccccccccc
cc1c1ccccccccccccc1c1cccccccccccccccccccccccccccccdcdccccccccccc52226655d5225d22588d8d66075507cccc7511cc1111150ccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccdd66d6ddcc88888c525255225d25252dc05155cccc5111cc1111157ccccccccccccccccc
ccccccccccccccccccccccccccccccccc0cccccccccccccccccccccc5d777756c8c8ccc85200555d6d252222c07511ccc111751c11111500cccccccccccccccc
ccccccccccccccccccccccccccc0ccccccccccccccccccccccccccccd607705d8cc88cc8d77770d505250520c005111cc110075c11111570cccccccccccccccc
cccccccccccccccccccccccccccc0ccc0c4ccccccccccccccccccccc66777756888888885707060522250520c751711c11170005c5511150cccccccccccccccc
cccc404ccccc444ccccc040cc0ccc40cccccccccccccccccccccccccd7d7756d8c888cc8007760000505052dc517051111500075c0751155cccccccccccccccc
cc040400cc444444cc040444cc3c0040cc040ccccccccccccccccccc75755dd78c8cc8c8707607772222252dc1507511115700051005115ccccccccccccccccc
c4031f01c4131ff1c4101ff1c4c010c1cc0cc0cccccccccccccccccc5d5d7775c8cccc8c6d2266566505256615700051571500751707511ccccccccccccccccc
c01000ffc113ffffc013fffac000c05ac0c00c5acccccc5acccccccc6d665556cc8888cc5662225ddd5d66dd1500075c00751551c0005111cccccccccccccccc
00000000dd5d66dd6d22dd52656d2256266622d6d266d52dcccccccc656d225654444445665d66dddd65566666d56666d666dd63b33bbbbb6d22222222222255
000000005dd5dd5d5552225d6d26d2d5d6622552d5dd5d55cccccccc6d26d88541111114d665dd5d666d6dd6d6666d66d666ddd63bb3bbbbd22dddddddddd226
000000006566556d66d66d2552266d6652dd5d62d65566d6cccccccc52886d66410011146d66556d6d566665666666d6d666dddd63bbbbbb22dd66666666dd22
0000000065666d66d66252666656d5656625266d662666d6cccccccc685888854108011466666d66666666d666665666d666dddd63bbbbbb2dd6dddddddd6dd2
00000000d5dddd565d6d56d6625d22526d25d6d565d2225dcccccccc8288285240100014665ddd56666566666d666666d666dddd633bbbbb2d6dddddddddd6d2
0000000066d5556d2525d62ddd25dd25225d2d5256555d56ccccccccd8258d25411000045d65556ddd666656566665d6d666dddd63b3bbbb2d6dddddddddd6d2
000000006656656d6d5d65d2255d66d22d52d5d626566566cccccccc255866824ddd0dd4666dd56d66d6666d66d65666d666ddd63bbb3bbb2d6dddddddddd6d2
000000006d56dd666d5656d565d666655d6265d6d6d26526cccccccc65d666655444444566d6dd6666665d666666666dd666ddd63bbbbbbb2d6dddddddddd6d2
dd520dd5525e20222200255025dd5022220ee522cccccccc86662886d266d8885555557554444445d56d65ddd56d65ddddd6dd63bbbbbbbb2d6dddddddddd6d2
050ee555520e220dd02ee200d0d5522dd00e2020ccccccccd6822588d8888d556666667640000004dd5ddd5ddd5ddd5d22222233333333332d6dddddddddd6d2
2202e5200edd0dd0ddde25055e22dddd0d222deecccccccc58885d68d65588d65555557540070004ddd5d56dddd5d56d22222223333333332d6dddddddddd6d2
d022002d5205225005d220d002e5dd5005dd50e2cccccccc8828888d668666d666000676400d70045d65d55ddd65d56d22222223333333332d6dddddddddd6d2
0d000de005000505000d0d050252050550552005cccccccc6d28d6d56588888d000000d0400d000405505550dd5dd5dd20000000000000022dd6dddddddd6dd2
0002502000050020050020000500500000020500cccccccc228d2d5256885d56000000004044440450050505d56ddd5d566665d6565565d622dd66666666dd22
d26d666d6d2266566d666656666d66d656d6d6ddcccccccc2d8885868658856800000000411111146d66d666dd6dd65d6dd6d6666dd6d666622dddddddddd225
6dd6dd6d5662225d66525d6556d5d565dd656256cccccccc5d6285d6d6d265266666666654444445665666d6d5ddd5dd666556d6666556dd5622222222222266
cccccccc00000000000000000000000002500000000000e2d5022002544444455444444522222222222225223223222244444444ccccccccdd5ddddd54444445
cccccccc0000000000000000000000002500000000000e2052e55d204d10d2d44110011452222222222225222333ddd264554554ccccccccdddddd5d40000004
cccccccc000000000000000000000000d200000000000ed52200220042112d24411ff014225222222252222224343dd265454545ccccddccdddddd5d4000dd04
cccccccc00000000000000000e0000000e000000000000d5000000004201d2d44442251422522222522222252444ddd245454545c55daadcdd5ddddd455daad4
cccccccc0000000000000e20e22000e0e5e00000000000e2000000004d0102d44ff2255422222225252522502dddddd245454545c55daadcdddddddd455daad4
cccccccc000022e00000e2de22250ed22d20000000000e2000000000461016644332255422222222005055055222222545454545ccccddccdddddddd4000dd04
cccccccc20ee2e5ee202ed22d2dd5d2e0d00000000000d5d0000000041001664411dd5542222522266d656665110011545454545ccccccccd5ddddd540000004
cccccccc0d2005202dd000dd5250052002500000000000d2000000005444444554444445222222226666666d5111111544554554ccccccccd5dd5ddd54444445
cccccccc00000e20de000000ee5d00ee025e25de02d5d022d00020d00500000220222e000dd20dd02220ee52e20000054444400454444445dddd5ddd52244245
cccccccc00000e2002000000e2222e25ed25d022e20052ee0d222d200d0000220dd02e5055002e5d00555220e2000002444440044dddddd45ddddddd40200224
cccccccc000000d020000000e2ddd00022000005d000000000000025d20000200d000dd20d0000d00000000020000052455444554d0dd1d4dddddd5d20070202
cccccccc0000002d2e00000005d000000000002d0200000000000050520000502d0000dd0d0000200000000025000050654545454dd3d7b4dddddd5d420d7204
cccccccc00ee0e50e2500000e22000000000eedd0500000000000020000000050d0000200200005200000000050000056545454546626334dd5ddddd222d2002
cccccccce222e2d002e5000e0e0000000000e2255ee00000000000e2200000e02000005d5200002000000000520000024555455545666664dddddddd40442424
ccccccccdd2d522d022d25e20500000000000d252d2050ed52250e25d25055e00d0000202e22505522500050e200002e666dd6d645a666645555555541111212
cccccccc05500d505005d025ed00000000000d50005d2d0200d05200500de005200000d2020052d0ee225225500000256dd66665544444455000000554444445
561434654444441544444444444444b7344444444454444434444454143535353544444454545444b7ce14ceceb71424141414141414242535452535de053525
0514141446045614141435254514465614656573141414ce14ceb7141414142414241414276714444600000000000000000000000000a4b40000000000000000
562414144444443414441444341444b7442454144414443457a74744445414544444142414544444b7a144cea1b7141437666666471465141414141414141414
1414141446045614141414141414465614ce651414651444141427a7a7a7a7a747141414353514244600000000000000000000000000a4b40000000000000000
561475148744441444341444a42444b754142444448744442535b754444424548744445444444444b7a2ce24a2b724144604263636a7a7a7a7a7a7a766a7a7a7
a7a7a7a7263626a7a767141414144656ce14741444ce24751414352535053535b7142414141414144600000000000000000000000000a4b40000000000000000
56142414b74444441424a414444444b74454445444b7445414144666666666660447445424a34414b714e6e6ceb7141446569292de92de92de92dede77052545
05253525353535354535141444144656142414ce1414146514144424ce142414b7141414658714144600000000000000000000000000b4a40000000000000000
5614441446a74744444444344457a756441437666604666666660404040404042626474454445454b7a1e7e7a1b74414465634ef141424441444ce1405141414
1414141414141414911414141414270466671457a7a74714144444141414141477141414ceb714144600009696c69696849696c69696a4a40000000000000000
56444414b70527a7a7a74744443525b7544446b5b5b5b585b5b5b586b5b504173525274744445444b7a21414a2b7241446561414341414141414141414141414
34141487141414341414141414140527170544ee05ee27a747144414144474144514241437171424460000a6a6c7a6b6a6a6a6c7a6a6a4b40000000000000000
56446514b74435053505b744a4144446a7a736a5a5a5a5a5a5a5a5a5a5a556251444252747444444b7ce141414b7141446046666a76714376666666647144424
14145704671414344434141414141405054414142414253527a747141414ce1414141414b7351414460000a4b4a4a4a4a4a4a4b4b4a4a4a40000000000000000
56141414b74444444444b7a44444a435353535a4a4a4a4b6b4a4c4d4a4a456941494443527a7666617b144ce24b7441446043617353514460404040456144414
144405770514141414141414144414141414141414144414253527a7471414441414143717141414460000b4b400000000000000000000000000000000000000
5614141477141424144477441444444491b4a4a4a4a4a4b4b4b4c5d5a49435544454444435ee2717351414141477141446562535143766040404040456141414
143414ee14141414376666471414143414376647141414241414353527a74714ce14371715144414460000b4a400360000000000000000000000000000000000
5614751435144414144435441444a4a454a437e6a4a4a4b4e4f4a4a4a4b4b4a4a414142444543535141424441425142446566573142716263626261617141414
44241414141414370404045614141434144604044714141414144424351527666666172524142414460000a4b496961600163616361636160000000000000000
561414744414444414144444144454a414ef46e7a4a4a4a4e5f5b4a4a4b4a4a444944454944444442414a4141414141446561475752525eeee45ee3535141414
141414142457a7263616361667143414144604040466664714144414141435272617351414141414460000a494a6a6a625254535454535454600000000000000
5665731487444487442424242444448714a446a4a4a4a4b4a4b4a4b4b4b43747a444a444a49444a4141424241414343704566534651414143414141414751434
1414141414053545053535ee3514141437040404040404046666471424141415ee35141414444444460000a4b4a4a49414141424141424144600000000000000
56746514b74444b744444444874444b744444604040404040404040404040456541444144494444414141414376666040456b114141475141465141414241444
14141424141414141414141414141437040404040404040404045614141414141414141414241414460000a4a4a4941414241414145414144600000000000000
04666666046666046666666604666604666604040404040404040404040404046666666666666666666666660404040404046666666666666666666666666666
66666666666666666666666666666604040404040404040404040466666666666666666666666666000000006600666666660066006666660000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111188888888222222225555555599999999cccccccccccccccccc444ccc00000000ccccccccccccccccccccccccdd5d86dddd5d86dd00068600066d8dd0
1111111188888888222222225555555599999999cc444ccccc444cccc44444cc00000000ccccccccccccccccc111cccc5dd5dd5d5dd5dd5d7770007770d88807
1111111188888888222222225555555599999999c44444ccc44444ccc41ff1cc00000000cccccc1ccccccccc11c11ccc6567776d6568556d6687778d6685868d
1111111188888888222222225555555599999999c4ffffccc41ff1ccc4ffffcc00000000cccc21c1ccc12ccc2c121ccc7770007760686d0600068d00065d8d60
1111111188888888222222225555555599999999c4ffffccc4ffffccc4333ccc00000000cccc11c2ccc21cccc21ccccc000d8d0007dd8d70777000777058d607
1111111188888888222222225555555599999999c4333cccc4333ccccc111ccc00000000cccc1c1ccccccccccccccccc6687778d6685858d555777555568d655
1111111188888888222222225555555599999999cc111ccccc111cccc1ccc1cc00000000ccccc1cccccccccccccccccc777000776058880d6666566dd66d5d6d
1111111188888888222222225555555599999999cc1c1ccccc1c1ccccccccccc00000000cccccccccccccccccccccccc00068d0007568d705d6685665d668566
cccccccc77777777000000000000000000000000cc444ccccccccccccc444ccc00000000000000000000000000000000d070750dd070750dd557070dd557070d
cccccccc77777777000000000000000000000000c44444cccc444cccc44444cc00000000000000000000000000000000507075d55d0d05d5d557070dd550505d
ccccddcc77777777000000000000000000000000c44444ccc44444ccc44444cc00000000000000000000000000000000080707d008ddd0d05d7070855dd55d85
c55daadc77777777000000000000000000000000c44444ccc44444ccc44444cc0000000000000000000000000000000088070780888858500870708808858888
c55daadc77777777000000000000000000000000cc444cccc44444cccc444ccc000000000000000000000000000000000807075008d0505050707080500dd580
ccccddcc77777777000000000000000000000000ccd11ccccc444ccccc11dccc0000000000000000000000000000000005070705050000050070700000500000
cccccccc77777777000000000000000000000000cccccccccc111ccccccccccc000000000000000000000000000000006070766d6606066d6d6707066d606066
cccccccc77777777000000000000000000000000cccccccccc1c1ccccccccccc0000000000000000000000000000000050707d5650707d5656d7070556d70705
00000000000000002eeee6ee2eeeeeee00000000cccccccccc444ccccccccccccc444ccc000000000000000000000000dd5eee0ddd2e250ddd5dd50d2d555505
0000000000000000eeeee6ee6eeeeeee00000000cc444cccc44444cccc444cccc44444cc0000000000000000000000005de2202d5d0002e25d0d55d5deedeed2
00000000000000002e6eeeee2e6eeeee00000000c44444ccc41ff1ccc44444ccc41ff1cc0000000000000000000000006500220d52e2000005ddd0d0e222e22d
00000000000000006eeeeee6ee6eeeee00000000c4ffffccc4ffffccc41ff1ccc4ffffcc0000000000000000000000006e666d66000002e2d5005d50e22de222
000000000000000026e6ee602eeeeee600000000c4ffffcccc333cccc4ffffcccc333ccc000000000000000000000000e22ddee6502e200000d050502222e220
000000000000000000606606eeeeeeee00000000cc333ccccc11dccccc333cccccd11ccc000000000000000000000000e2225e220000000005000005e2202220
0000000000000000d77777772eee6eee00000000cc111ccccccccccccc111ccccccccccc00000000000000000000000000225220622626626666d66d2226222d
000000000000000077777777eeeeeeee00000000cc1c1ccccccccccccc1c1ccccccccccc0000000000000000000000000200d020256d5252556d5d56556d5d56
d777777777777777eeeee6eeeeeeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000000dd5d66dddd5d66d7
7777777777777777eeeee6ee6eeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000057d5dd5d5dd5dd57
6777777777777777ee6eeeeeee6eeeee000000000000000000000000000000000000000000000000000000000000000000000000000000006076556d65665570
77777777777777776eeeeee6ee6eeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000065077d6665666770
6777777777777777e6e6ee60eeeeeee600000000000000000000000000000000000000000000000000000000000000000000000000000000d5d07bb6d5d22706
777777777777777700606606eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000006b3307bb62227011
677777777777777777777777eeee6eee00000000000000000000000000000000000000000000000000000000000000000000000000000000665333bd6662112d
777777777777777777777777eeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000006d56dd666d56dd66
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000055daad000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000055daad000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000dd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000111111111111111111111111111111111000111111111111111111111111011110000000000000000000000000000000000
00000000000000000000000000000100110001000101010011000110011001000100010001000100010001001110010000000000000000000000000000000000
00000000000000000000000000000101010101010101010101011101110111000101010111011101011011010101110000000000000000000000000000000000
00000000000000000000000000000101010001001100110101001100010001000100010011001100111011010101110000000000000000000000000000000000
00000000000000000000000000000101010101010101010101011111011101000101110111011101011011010101010000000000000000000000000000000000
00000000000000000000000000000100010101010101010101000100110011000101010001000101010001010100010000000000000000000000000000000000
00000000000000000000000000000111111111111111111111111111111110000111011111111111111111111111110000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001111111111111111000011111111111111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001000100010001001100010001000100110101000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001000101011011010100010001011101010101000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001010100011011010100010101001101010101000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001010101011011010100010101011101010101000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001010101010001010100010101000101011001000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001111111111111111100011111111111111111000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000011111111111111111111100011111000111111111000111111111111111111110000000000000000000000000000000000
00000000000000000000000000000010001000100011001100100010001000100011001000100010001100100010011000000000000000000000000000000000
00000000000000000000000000000010101010101110111011100011101000110110101000101010111011110110101000000000000000000000000000000000
00000000000000000000000000000010001001100110001000100011011000010110101000100110011011110110101000000000000000000000000000000000
00000000000000000000000000000010111010101111101110100010111000010110101000101010111010110110101000000000000000000000000000000000
00000000000000000000000000000010101010100010011001100010001000010110011000100010001000100010101000000000000000000000000000000000
00000000000000000000000000000011101111111111111111000011111000011111110000111111111111111111111000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000000000000000000000000000000000000000000000000006004200000000000000000000000002020200000000000000000000000082000202000200000001020202020202020102020201010202020202020200020201010201020202020001010101010101010102010108010100010101010101010101010102010101
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000000000021222122080000000000000000000000212121220000020100000000000000000102020202020201000000000000000000001101
__map__
656f69697d697240636263626261624061636340404062626362626340624061626362636263616263636362614040404062717f696772636161624040406240636240626140636140626140626261626261626261626261624040406261634040404040616140400000005b5b5b5b585b5b5b685b5b00000000000000000000
656a6b6a6a51547b545353ee5453537b53525264406553545352535377547b52525352515351535251535353536440406552526a6a6a6a516a5253644065537752537753537753517751537b5254ee52ed52535252eeee52536400655151516400000071eded72000000005a5a5a5a5a5a5a5a5a5a5a00000000000000000000
654b4a4a4b49417b414143414141756176414164406541414341414151417b41454141434141414141414444416440406541494a494a4941414241644071415341415041415141415441427b4141ec4141414141414141414164006541374164000065ee4141ee640000004a4a4a4a6b4b4a4c4d4a4a00000000000000000000
654b4b4b4941417b43414241444153eeee414164406541414141424141417b4141434141415741414141414444644040407441434a4141fe414141646552424144444141414241414141447b41424141ec4141ec41757a7641526463765757640000651afe411a640000004a4a4a4a4b4b4b5c5d4a4a00000000000000000000
65414b494542417b414142424545424141414172637141417366667443417b414141414144564141737a7a76446440404065414141414241414141646544447941417941417941417942447b41ec4442444141417852515141447b53514157640000652a41412a640000006d4a4a4a4b4e4f4a4a4a4b00000000000000000000
65454b49414241727a7441424241756676424151ee5241417b51537b41417b41434141737641757a65525353416461626363667441414173667644726541415441415141425141415341447b41414141444141785041414241447b414141416400006541414141720000007e4a4a4a4a5e5f4b4a4a4b00000000000000000000
407a7a764442415152727a744541547b514241411b4141417b41fe7b41417b414144417b534152537b414141417b41414152646544414164655441527b41414141414141414241414241417b414141ec414178514141414141447b5741757a620000711a41411a546400004a4a4a4a4b4a4b4a4b4b4b00000000000000000000
655354544241444141ee547b414141647a7a7a7a744143427b41737141417b414441417b574141577b41757a7a6541414141646541414164651b4141774141794141794141794141794141727a7a764141417b414141444141447741415329537271532a41442a41640000000000000000000000000000000000000000000000
65414141414141414141417b4144417b5454ee517b4141417b417b5342417b414444417b575756417b415354517b4141424164654141416465414141524141534241544141504141544141545354534141417b41414141414144504142414141ee534141414441416400000000000000000000004a4b00000000000000000000
65454145417366745742417b4144447b414141417b4144417b41774141417b414141417b413756417b414144417b4144414164654141447271414141444141414141414119414144424141444141414241417b414241414441414441415641414141414141194241640000696c696959696c69694a4a00000000000000000000
654445737a626171444241774144417b41414241774141417b41514141756176414141727a7a7a7a71414141417b41414141646541414453544141417842417841417941447941417844414241414141414177414141444141414441757a7a7a7a7a7a74414141416400006a7c6a6a6a6a7c6a6a4a4b00000000000000000000
6544457b53535253414242534141447b42444141514141417b19414241545454414141515151542853414142417741414141646541414141414141417b41417b41425344445441417b41414141784141414153414144444241417376545152515429527274414141640000194a4a4a4a4a4a4a4b4b4a00000000000000000000
6541447b41574141414441414441417b41414141414244417b4141444141414141424141414141414141434141544141414272627a7a7a7a7a7a7a7a637a7a6541414444414173666541414141727a74414142414444414141417b521b41414141414154774141426400004a4a00000000000000000000000000000000000000
6544417b57374242415641414141417b41414341414141417b4143414175667641414141414143414141414142414141414153ee54ee29525353ee525228527b4241414141416440654144414153547b4141414141414141737a71414141414241414141544141416400004a4a00000000000000000000000000000000000000
6544437b41574144414141424241417b41414141784141736541414141547b52414178414142414178414141414141414144454441443745564757424141417b4141414141416440654141414141417b41414141414141417b5353414141414142444444444141416400004a4a00000000000000000000000000000000000000
654343647a7a7a7a7a7a7a7a7a7a66406666666665414164637a7a7a7a7a407a7a7a654144414141647a7a7a7a666666666666666666666666667441414241727a7a7a7a7a7a626162666674414441727a7a7a7a7a7a7a7a714141417366666666666666666666660000004a4a00000000000000000000000000000000000000
6543447b5353ee5152515353ee536465505051507b41417b5354515052537b5452547b41414444417752525252644040404040404040404040406541415741ed5351ed53eeee53ed5264406541414153545329ee535328ee534141416400000000000000000000000000004a4a00000000000019000000000000000000000000
6541417b57424141574157444141726276424141774141774143414241437b414141774141414141544141414164404040406261626162624040406674414141414141414141414441724065414241444141444141414141414141416400000000000000000000000000004a4b00000000000000000000000000000000000000
6541437b37564242427856424444505350414144534142534141414141417b414341544141434141414141414164404040655353525153536440404040667a7a666666667a764142415264407441414141413a4141414142414141416400610000000000000000000000004b4a00000000000000000000000000000000000000
654243727a7a7a7a7a7141444242414141414343414141414141737441417b414141414141414141414241444172636363714141414142417262627151545354726363715353444141417261617a7a7a7a7a7a7a76414441757a7a7a63716969694869e3f3f3f3f3f300004b4a00000000000000000000000000000000000000
654241515154ee53515141424244736676414441434173764141726541417b41414144417841417841414141415353ee535342411b4141415453535441413756de545454414241414141dede535353515253295352414141dedede5353536a6a6a6a6ae2f2f2f2f2f200004a4a00000000000000000000000000000000000000
654145414141414141414141414164655341424441417b534141537b42417b41414441417b41417b4141424141736666667441424441444173666666744141417366744141414244736666667441414141414141414144427366666674414119414a4af0f1f1f1f1f100004a4a69696c69696c69696c69690000000000000000
65414445444141757a7a7a7a7a7a40654141444141417b414141417b41417b41414241417b42417b4142414141644040406541414241414164404040407444fe6440407a7a76414164404040406666744144414141414141644040404000660066000000000000000000004a4a6a6a7c6b6a7c6a6b7c6a6a0000000000000000
6541414441444154535153535454537b4141414141417b414343417b41417b414444414177414177414141424164404040654141414141416440404040406666404065512951414164404040404040406666666666667441644040404040000000000000000000000000004a4b4a4a4a4a4a4b4b4b4a4a4b0000000000000000
654141414143414141414341414141647a7a7a7a7a7a71414141417b41417b4141414141544142544141414141644040404066666666666640404040404040404063714141736666404040404040404040404040404065417240404040404040404040404000000000000000000000000000000000004a4a0000000000000000
407a7a7a7a7a667a7a7641414341417b5353535353535341434141647a7a654141757441414141414173764141644040404040404040404040404040404040406551534141644040404040404040404040404040404065415364404040404000000000000000000040000000000000000000000000004a4b0000000000000000
6552515253517b53515341434344417b41414141414241414141417b57377b4141527274414141417371524141644040404040404040406362614040404040406541414173404040404040404040404040404040404065414172404040404040404040404040404040000000000000000000000000004b4a0000000000000000
6541414141417741414141414444417b414341757a7a7a7a7a7a7a7157756376414152727a7a7a7a71524142416440404040404040407152525272404040404065414141644040636163404040404040404040616363714144ee644040400000404040404063636300000000000000000000000000004a4a0000000000000000
6541434343415241414141444441417b4144415453545054535453545754505041474152525252525241414441644040404040404071524137575272404040406541414164406552525264404061636261627150ee53524142416400000000000063636165eeedee64000000000000000000000000004a4a0000000000000000
6541414141414141414141414141417b4141424141414141414156414156414141414141414141414141414141644040404040406552415741574152644040406541414164406541444164406550525328525241414141414141640000000062715053537b41414164000000000000000000000000004a4a0000000000000000
407a764141757a667a7a7a7a7a7a7a65414141757a7a7a7a7a7a7a7a7a666666667a7a7641444175667a7a7a7a40626362626162714444736666666640404040654444446440654141416440654173667a7a7a7a7a7a7a7a7a7a006162617150504445447b41414164000000000000000000000000004a4a0000000000000000
6551534141eeee775150285150ee517b4144415252535252525353525372616171535353414141537b295353297b525253535252524156726162616261626162714141416440654142447261714464655052ee525052505252537b5354535042424141457b41414464000000000000000000000000004a4b0000000000000000
__sfx__
010100200002001020000200131000020010200002001020003100102000020010200002001310000200102000020010200002001020000200102000020010200002001310000200102000020010200041001020
01021d200017000110011710017000110011710016000110011610016000110011610015000110011510015000110011510014000110011410014000110011410013000110011310013000110011310012000110
01050000107712574123711217510c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c7010c701
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
013c0000097500c7501075011750107500c750097500c7501075011750107500c750097500c7501075011750107500c75004750087500b7500e7500b7500875004750087500b7500e7500b750087500475008750
013c00000b7500e7500b7500875004750087500b7500e7500b75008750097500c7501075011750107500c750097500c7501075011750107500c75004750087500b7500e7500b7500875009750097500975000700
013c000009060000000000000005000050000509060000050000500005000050000509060100651006510065000000c0600b0600000500005000050000500005000050b0600c0600e060000000c0601006000000
013c000000005000050000500005000050b0600c0600e060000050c06009060000050000500005000050000500005090650b0650c0650b0650906508065000050000500005000050806009060090600906000005
01220020275202751033520335102752027510335203351022520225102e5202e51022520225102e5202e510215202151029520295102152021510295202951023530235102f5302f51023530235102f5302f510
012200200304003040030400304003040030400304003040060400604006040060400604006040060400604005040050400504005040050400504005040050400204002040020400204002040020400204002040
012700080077300763000000000000700007000000000000007000070000000000000070000700000000000000700007000070000700007000070000000000000070000700007000070000000000000000000000
011a00040077300763000000000000000000000000000000007000070000000000000070000700000000000001700017000000000000017000170000000000000000000000000000000000000000000000000000
011a00100012500125001050010500125001250010500105011250112500105001050112501125001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
011a001000415004150040500405004150041500405004050141501415004050040501415014150c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050c4050040500405
011a00100041507415034150741500415074150341507415014150841504415084150141508415044150841500405004050040500405004050040500205002050020500205002050020500205002050020500205
011000200087000870008750087000870008700087400870008700087000870008700087500870008700087000870008700087000870008700087400870008700087000874008700087000870008700087500870
015600000e9500e9510000000000119501195100000109501095000000000000000013950139510000012950129510000000000119540000000000000000e9540000013950109500000000000109540000000000
01220020009000c9340090000900009000090010935009000090000900119340090000900139341393100900009000090000900109350090000900009000e9350090000900009000090000900119301193100900
000c000010620076602161007660006701e61015640036700e6400865015620196301a6301165011650000000000000000000001a6201f63026670276002a670286002a6402c6302c62003620000000000000000
000600001c36311000103331031310303107031070513005306041070310705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000c00000f8601b870108701987011860048400e8200080000800008000080000800218701c8501d84015830008000080000800008001580000800128501687012870158701b8600d840118300e8200080000800
000700000065300600006000060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603006030060300603000000000000000
010100000c11500600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000000000000000000000
0002000019045000001e0450000023045000000000000000000001b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000266200c300193000c3001c3000c3001c3000c3001e3000c300213000c300213000c300233000c3000c300253000c300283000c3000c3000c300133000c300133000c300133000c300133000c30000000
010200000c6500c300253000c300253000c300233000c300233000c300213000c300213000c3001e3000c3001c3000c3001c3000c30019300123000c300123000030000300003000030000300003000030000300
0108000019653196231965319623196030c6031963319613196331961307603066031961319603196131960318603016030460303603016030760306603066030560304603046030360302603016030160301603
000800000b6551b6552d6052d60501605016050160501605016050160501605016050160501605016050160501605016050160501605016050160501605016050160501605016050160501605016050160501000
012a00200c5600c5650c5600c5650f5600f5650e5600c5600a5600a5650a5600a5650c5600c5650a5600a5650856008565075600656007560075650256002565025600256507560075650e5600e5600e5600e565
013800000000000000000000000000000000000000000000000000000000000000001550015500185001c5001c5001d5001c5001c500185001550015500000001550015500185001c5001c5001d5001c5001c500
0138000010500115000c5001050017000005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000000000000000000000000000000000000000000
003800001c5000000000000175001a5001a5001c5001d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 484a4344
01 080a4344
02 090b4344
03 0d0c4344
01 10130f4f
01 10110f13
00 10120f13
02 10120f13
03 140e1315
01 20214344
02 22234344
03 0e424344
00 5f424344
04 5e424344

