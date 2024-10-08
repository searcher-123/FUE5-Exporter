function serialize(schema, data)
    if schema.type == 'object' then
        return serialize_object(schema, data)
    elseif schema.type == 'array' then
        return serialize_array(schema, data)
    elseif schema.type == 'string' then
        return '"' .. data .. '"'
    else
        return tostring(data)
    end
end

function serialize_object(schema, object)
	local stringified_fields = {}
	for key, value in pairs(object) do
		local value_schema = schema.properties[key] or schema.additionalProperties
	log ("value_schema "..key)
        table.insert(stringified_fields, '"' .. key .. '":' .. serialize(value_schema, value))
	end

	return '{' .. table.concat(stringified_fields, ',') .. '}\n'
end

function serialize_array(schema, array)
	log ("array_schema ")
	local stringified_items = {}
	for _, item in ipairs(array) do
		table.insert(stringified_items, serialize(schema.items, item))
	end

	return '\n[' .. table.concat(stringified_items, ',') .. ']\n'
end

return {
    serialize = serialize
}