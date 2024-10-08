function get_bounds(exported_entities)
    local min_x = nil
    local min_y = nil
    local max_x = nil
    local max_y = nil
    for _, entity in ipairs(exported_entities) do
		width=0
                height=0
		if (entity.width) then width=entity.width 
		end
                if (entity.height) then height=entity.height
		end
		if min_x == nil or min_x > entity.x - width / 2 then
			min_x = entity.x - width / 2
		end
		if min_y == nil or min_y > entity.y - height / 2 then
			min_y = entity.y - height / 2
		end
		if max_x == nil or max_x < entity.x + width / 2 then
			max_x = entity.x + width / 2
		end
		if max_y == nil or max_y < entity.y + height / 2 then
			max_y = entity.y + height / 2
		end
    end

    return {
        x = min_x or 0,
        y = min_y or 0,
        width = (max_x or 0) - (min_x or 0),
        height = (max_y or 0) - (min_y or 0),
	tick=game.tick
    }
end

return {
	get_bounds = get_bounds
}
