function get_wire_connections(global_offset, electric_poles, print)
	local connections = {}
	local position = {}
	local entity_to_network = {}
	local network_to_entities = {}

	for network_index, entity in ipairs(electric_poles) do
		if position[entity.x] == nil then
			position[entity.x] = {}
		end
		position[entity.x][entity.y] = entity
		entity_to_network[entity] = network_index
		network_to_entities[network_index] = { entity }
	end

	function merge(entity_1, entity_2, distance_squared)
		if entity_1 and entity_2 then
			local network_1 = entity_to_network[entity_1]
			local network_2 = entity_to_network[entity_2]
			if network_1 ~= network_2 and distance_squared < entity_2.wire_reach * entity_2.wire_reach then
				table.insert(connections, {
					start = {
						x = entity_1.position.x + pole_offsets[entity_1.name].x - global_offset.x,
						y = entity_1.position.y + pole_offsets[entity_1.name].y - global_offset.y,
						z = pole_offsets[entity_1.name].z
					},
					target = {
						x = entity_2.position.x + pole_offsets[entity_2.name].x - global_offset.x,
						y = entity_2.position.y + pole_offsets[entity_2.name].y - global_offset.y,
						z = pole_offsets[entity_2.name].z
					}
				})

				for _, network_2_entity in ipairs(network_to_entities[network_2]) do
					entity_to_network[network_2_entity] = network_1
					table.insert(network_to_entities[network_1], network_2_entity)
				end
				network_to_entities[network_2] = nil
				return true
			end
		end

		return false
	end

	-- initial 90 degrees connections
	for _, entity in ipairs(electric_poles) do
		for i = 1, entity.wire_reach do
			local neighbour = position[entity.x + i] and position[entity.x + i][entity.y]
			if merge(entity, neighbour, i * i) then
				break
			end
		end
		for i = 1, entity.wire_reach do
			local neighbour = position[entity.x - i] and position[entity.x - i][entity.y]
			if merge(entity, neighbour, i * i) then
				break
			end
		end
		for i = 1, entity.wire_reach do
			local neighbour = position[entity.x] and position[entity.x][entity.y + i]
			if merge(entity, neighbour, i * i) then
				break
			end
		end
		for i = 1, entity.wire_reach do
			local neighbour = position[entity.x] and position[entity.x][entity.y - i]
			if merge(entity, neighbour, i * i) then
				break
			end
		end
	end

	local merged = true
	while merged do
		merged = false
		for network, entities in pairs(network_to_entities) do
			for _, entity in ipairs(entities) do
				for x = -entity.wire_reach, entity.wire_reach, 0.5 do
					for y = -entity.wire_reach, entity.wire_reach, 0.5 do
						local distance_squared = x * x + y * y
						if x ~= 0 and y ~= 0 and distance_squared <= entity.wire_reach * entity.wire_reach then
							local neighbour = position[entity.x + x] and position[entity.x + x][entity.y + y]
							if merge(entity, neighbour, distance_squared) then
								merged = true
							end
						end
					end
				end
			end
		end
	end

	return connections
end

function stringify(schema, data)
	if schema.type == 'object' then
		return stringify_object(schema, data)
	elseif schema.type == 'array' then
		return '[' .. stringify_array(schema, data) .. ']'
	elseif schema.type == 'string' then
		return '"' .. data .. '"'
	else
		return '' .. data
	end
end

function stringify_object(schema, object)
	local stringified_fields = {}
	for key, value in pairs(object) do
		local value_schema = schema.properties[key] or schema.additionalProperties
		if value_schema == true or value_schema == false then
			-- raise exception
		else
			table.insert(stringified_fields, '"' .. key .. '":' .. stringify(value_schema, value))
		end
	end

	return '{' .. table.concat(stringified_fields, ',') .. '}'
end

function stringify_array(schema, array)
	local stringified_items = {}
	for _, item in ipairs(array) do
		table.insert(stringified_items, stringify(schema.items, item))
	end

	return '[' .. table.concat(stringified_items, ',') .. ']'
end

-- old 'II IINIINNINIIINNININNNNNININNNNINIINININININIININININNIIIII'
-- old 'NN NNNIININININNINININININNINIIIININIIIIININIINNNINIINNINNNN'
local forwards = 'IINIINNINIIINNININNNNNININNNNINIINININININIININININNIIIII'
local backwards = 'NNNIININININNINININININNINIIIININIIIIININIINNNINIINNINNNN'

function get_train_paths(global_offset, entities, exported_entities, exported_entities_map, print)
	local rails = {}
	local trains = {}
	for _, entity in ipairs(entities) do
		if entity.type == 'straight-rail' or entity.type == 'curved-rail' then
			rails[entity.unit_number] = true
		elseif entity.type == 'locomotive' and entity.train.has_path then
			trains[entity.train.id] = entity.train
		end
	end

	local train_paths = {}
	for _, train in pairs(trains) do
		local first = 0
		local last = 0
		for i, path_rail in pairs(train.path.rails) do
			if first == 0 then
				if rails[path_rail.unit_number] then
					first = i
				end
			else
				last = i - 1
				if not rails[path_rail.unit_number] then
					break
				end
			end
		end

		local path = {}
		for i = first, last do
			rail = {
				--index = entities_map[train.path.rails[i].unit_number]
				name = train.path.rails[i].name,
				x = train.path.rails[i].position.x - global_offset.x,
				y = train.path.rails[i].position.y - global_offset.y,
				direction = entity_direction_to_number(train.path.rails[i].direction),
			}

			if rail.name == 'straight-rail' and rail.direction % 2 == 1 then
				rail.name = 'skewed-rail'
				rail.x = rail.x + 0.5 - math.floor(rail.direction / 4)
				rail.y = rail.y - 0.5 + math.floor(((rail.direction + 2) % 8) / 4)
				rail.direction = math.floor(rail.direction / 2) * 2
			end

			if rail.name == 'curved-rail' then
				if rail.direction % 2 == 1 then
					rail.name = 'curved-rail-R'
					rail.direction = math.floor(rail.direction / 2) * 2
				else
					rail.name = 'curved-rail-L'
					rail.direction = math.floor(rail.direction / 2) * 2
				end
			end

			table.insert(path, rail)
		end

		local sequence = ''
		for i = 2, table_size(path) do
			local from = path[i - 1]
			local to = path[i]
			if rail_transitions[from.name] and rail_transitions[from.name][to.name] then
				path[i].variant = rail_transitions[from.name][to.name](from, to)

				sequence = sequence .. path[i].variant
			else
				sequence = sequence .. '?'
			end
			path[i - 1] = path[i] -- move indexes to remove first rail
		end

		table.remove(path, table_size(path)) -- remove the last rail (it was moved one index down)

		print('sequence: ' .. sequence)
		local forwards_result = ''
		for i = 1, string.len(forwards) do
			if string.sub(sequence, i, i) == string.sub(forwards, i, i) then
				forwards_result = forwards_result .. 'O'
			elseif string.sub(sequence, i, i) == '?' then
				forwards_result = forwards_result .. '?'
			else
				forwards_result = forwards_result .. 'X'
			end
		end
		local backwards_result = ''
		for i = 1, string.len(backwards) do
			if string.sub(sequence, i, i) == string.sub(backwards, i, i) then
				backwards_result = backwards_result .. 'O'
			elseif string.sub(sequence, i, i) == '?' then
				backwards_result = backwards_result .. '?'
			else
				backwards_result = backwards_result .. 'X'
			end
		end
		local forward_nok = string.match(forwards_result, 'X')
		local backward_nok = string.match(backwards_result, 'X')
		if backward_nok then
			print('forwards_result:  ' .. forwards_result)
		end
		if forward_nok then
			print('backwards_result:  ' .. backwards_result)
		end

		local back = {}
		for _, locomotive in ipairs(train.locomotives.back_movers) do
			back[locomotive.unit_number] = true
		end

		local carriages = {}
		for _, carriage in ipairs(train.carriages) do
			table.insert(carriages, {
				name = carriage.name,
				direction = back[carriage.unit_number] ~= nil and 0 or 4
			})
		end

		rev = {}
		for i = #carriages, 1, -1 do
			rev[#rev + 1] = carriages[i]
		end
		carriages = rev

		table.insert(train_paths, {
			carriages = carriages,
			paths = path
		})
	end

	return train_paths
end

function get_train_paths_2(event, exported_entities, exported_entities_map, print)
	local train_paths = {}
	for _, entity in ipairs(event.entities) do
		if entity.type == 'locomotive' and entity.train.has_path then
			local path = {}
			local started = false
			for i, path_rail in pairs(entity.train.path.rails) do
				if not started then
					if exported_entities_map[path_rail.unit_number] ~= nil then
						started = true
					end
				else
					if exported_entities_map[path_rail.unit_number] == nil then
						break
					end
				end

				if started then
					table.insert(path, {
						index = exported_entities_map[entity.train.path.rails[i].unit_number] - 1
					})
				end
			end

			for i = 2, table_size(path) do
				local from = exported_entities[path[i - 1].index + 1]
				local to = exported_entities[path[i].index + 1]

				path[i].invert_spline = rail_transitions[from.name][to.name]({
					x = from.x,
					y = from.y,
					invert_spline = path[i - 1].invert_spline
				}, to)

				path[i - 1] = path[i]            -- move indexes to remove first rail
			end
			table.remove(path, table_size(path)) -- remove the last rail (it was moved one index down)

			table.insert(train_paths, {
				paths = path
			})
		end
	end

	return train_paths
end
