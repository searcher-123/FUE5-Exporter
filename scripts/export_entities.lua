function entity_direction_to_number(entity_direction)
	local directions = defines.direction
	if entity_direction == directions.northwest then
		return 7
	elseif entity_direction == directions.west then
		return 6
	elseif entity_direction == directions.southwest then
		return 5
	elseif entity_direction == directions.south then
		return 4
	elseif entity_direction == directions.southeast then
		return 3
	elseif entity_direction == directions.east then
		return 2
	elseif entity_direction == directions.northeast then
		return 1
	else
		return 0
	end
end

function entity_size(entity)
	return entity.selection_box.right_bottom.x - entity.selection_box.left_top.x,
		entity.selection_box.right_bottom.y - entity.selection_box.left_top.y
end

function entity_prototype_size(entity)
	return entity_size(entity.prototype)
end

function neighbour_direction(source, neighbour)
	local neighbour_width, neighbour_height = entity_size(neighbour)

	if neighbour.position.y + neighbour_height / 2 < source.position.y then
		return 0
	elseif neighbour.position.x - neighbour_width / 2 > source.position.x then
		return 2
	elseif neighbour.position.y - neighbour_height / 2 > source.position.y then
		return 4
	elseif neighbour.position.x + neighbour_width / 2 < source.position.x then
		return 6
	end
end

function get_neighbour_directions(entity, neighbours)
	local directions = {}
	for _, neighbour in pairs(neighbours) do
		local direction = neighbour_direction(entity, neighbour)
		directions[direction] = true
		directions[direction + 8] = true
	end

	return directions
end


function get_items_inserter(entity)
	local items = {}    
	local pickup_list={}    
--		game.print ("pick "..entity.pickup_target.type)
		if ('furnace'==entity.pickup_target.type or entity.pickup_target.type=='assembling-machine') then
				furnace=entity.pickup_target
				if (furnace.get_recipe()~=nil) then
 	
				for _,product in pairs (furnace.get_recipe().products) do
					table.insert(pickup_list,product.name)
				end
				in_time=furnace.get_recipe().energy
-- 				table.insert (items,"pick_power:"..furnace.power_production)
  				table.insert (items,"intime:"..in_time)
				end
		end
		if ('transport-belt'==entity.pickup_target.type) then				
				table.insert(pickup_list,"transport-belt")
		end
		if ('container'==entity.pickup_target.type) then				
				table.insert(pickup_list,"container")
		end
		
		drop_list={}
		for key,ent in pairs(game.surfaces["nauvis"].find_entities_filtered{position=entity.drop_position}) do
--		game.print ("drop "..ent.type)
		--	table.insert (items,"drop_target:"..ent.name)		
	    	--	table.insert (items,"drop_target_type:"..ent.type)		
			if ('container'==ent.type) then	
				game.print ("Cont")			
				table.insert(drop_list,"container")
			end
			if ('transport-belt'==ent.type) then				
				table.insert(drop_list,"transport-belt")
			end

			if (ent.type=='furnace' or ent.type=='assembling-machine') then
			    if (ent.burner~=nil and ent.burner.currently_burning~=nil) then
			    table.insert(drop_list,ent.burner.currently_burning.name)
			    end
				game.print ("furnace ") 
				if (ent.get_recipe()~=nil) then					
					for key2,ing in ipairs(ent.get_recipe().ingredients) do
					table.insert(drop_list,ing.name)
					end
					out_time=ent.get_recipe().energy
--					table.insert (items,"drop_power"..ent.power_production)
	  				table.insert (items,"out_time:"..out_time)
				end
			end
		end
		game.print ("#ing->"..#pickup_list)
		game.print ("#ing2->"..#drop_list)
		for key,ing in ipairs(pickup_list) do
			game.print ("ing->"..ing) 							
			for key2,ing2 in ipairs(drop_list) do				
				game.print ("ing2->"..ing) 							
				if (ing=='transport-belt' or ing=='container') then
				--game.print (game.tick.." k-"..key2.."ing2->"..ing2) 								
					table.insert (items,ing2)
				end
				if (ing2=='transport-belt' or ing2=='container') then
				--game.print (game.tick.." k2-"..key2.."ing2->"..ing2) 								
					table.insert (items,ing)
				end
				if ((ing.name~=nil and ing.name==ing2.name) or (ing~=nil and ing==ing2)) then -- same item as product of drop and ingridient of pickup
--				game.print (game.tick.." k3-"..key2.."ing2->"..ing.name) 								
					table.insert (items,ing)
				end
			end
		end
		--game.print("found target"..target_ent[1].name)
		
	return items
end




function get_pipe_type(directions)
	local count = table_size(directions)
	if count <= 2 then
		return 'I', next(directions) or 0
	elseif count == 4 then
		for i = 0, 2, 2 do
			if directions[i] and directions[i + 4] then
				return 'I', i
			end
		end
		for i = 0, 6, 2 do
			if directions[i] and directions[i + 2] then
				return 'L', i
			end
		end
	elseif count == 6 then
		for i = 0, 6, 2 do
			if not directions[i] then
				return 'T', i
			end
		end
	else
		return 'X', 0
	end
end

function export_entities(event, print)
	local exported_entities = {}
	local exported_entities_map = {}

	for _, entity in ipairs(event.entities) do
		local width, height = entity_prototype_size(entity)
		local export = {
			name = entity.name,
			x = entity.position.x - event.area.left_top.x,
			y = entity.position.y - event.area.left_top.y,
			direction = entity_direction_to_number(entity.direction),
			width = width,
			height = height
		}

		if entity.type == 'pipe' then
			local name_suffix, direction = get_pipe_type(get_neighbour_directions(entity, entity.neighbours[1]))
			export.variant = name_suffix
			export.direction = direction
		end

		if entity.type == 'arithmetic-combinator' then
			export.operation = entity.get_control_behavior().parameters.operation
		end

		if entity.type == 'decider-combinator' then
			export.operation = entity.get_control_behavior().parameters.comparator
		end

		if entity.type == 'transport-belt' then
			local neighbour_directions = get_neighbour_directions(entity, entity.belt_neighbours.inputs)
			local has_right = neighbour_directions[export.direction + 2]
			local has_bottom = neighbour_directions[export.direction + 4]
			local has_left = neighbour_directions[export.direction + 6]

			if (has_right == has_left) or has_bottom then
				export.variant = 'I'
			elseif has_right then
				export.variant = 'R'
			else
				export.variant = 'L'
			end
		end

		if entity.type == 'underground-belt' and entity.belt_to_ground_type == 'input' then
			export.direction = (export.direction + 4) % 8
		end
		if entity.type == 'inserter' then
			export.inserter_rotation_speed=string.format("%.3f", entity.prototype.inserter_rotation_speed)
			export.items=get_items_inserter (entity)
		end

		if export.name == 'straight-rail' then
			if export.direction % 2 == 1 then
				export.variant = '/'
				export.x = export.x + 0.5 - math.floor(export.direction / 4)
				export.y = export.y - 0.5 + math.floor(((export.direction + 2) % 8) / 4)
				export.direction = math.floor(export.direction / 2) * 2
			else
				export.variant = 'I'
			end
		end

		if export.name == 'curved-rail' then
			if export.direction % 2 == 1 then
				export.variant = 'R'
				export.direction = math.floor(export.direction / 2) * 2
			else
				export.variant = 'L'
				export.direction = math.floor(export.direction / 2) * 2
			end
		end

		if entity.type == 'tree' then
			export.name = 'tree'
		end

		print(entity.type .. ' ' .. export.name .. ' ' .. export.direction)

		table.insert(exported_entities, export)
		if entity.unit_number ~= nil then
			exported_entities_map[entity.unit_number] = #exported_entities
		end
	end

	return exported_entities, exported_entities_map
end

return {
	export_entities = export_entities
}
