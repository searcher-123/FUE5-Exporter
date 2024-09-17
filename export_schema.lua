return {
    ["$schema"] = "http://json-schema.org/draft-04/schema",
    type = "object",
    description = "Format of json exported from FUE5Exporter and imported in FUE5.",
    properties = {
      bounds = {
        type = "object",
        properties = {
          ["x"] = {
            type = "number"
          },
          ["y"] = {
            type = "number"
          },
          width = {
            type = "number"
          },
          height = {
            type = "number"
          },
	  tick ={
            type = "number"
	  },
        },
        required = { "x", "y", "width", "height" }
      },
      entities = {
        type = "array",
        items = {
          type = "object",
          properties = {
            name = {
              type = "string",
              description = "Name of the entity from Factorio"
            },
            ["x"] = {
              type = "number",
              description = "X coordinate in Factorio grid"
            },
            ["y"] = {
              type = "number",
              description = "Y coordinate in Factorio grid"
            },
            direction = {
              type = "integer",
              description = "0 = north, 1 = northeast, 2 = north, ...",
              minimum = 0,
              maximum = 7
            },
	    unit_number ={
	      type="uint",
              description= "A unique number identifying this entity for the lifetime of the save."
	    },
            width = {
              type = "number",
              description = "Width of the entity"
            },
            height = {
              type = "number",
              description = "Height of the entity"
            },
            back_mover = {
              type = "boolean",
              description = "Is this carriage a back mover?"
            },
            operation = {
              type = "string",
              description = "Operation of combinators"
            },
             inserter_rotation_speed= {
                       type= "string",
                        description= "Rotation speed of inserter."
                    },
             inserter_items= {
                   	type = "array",
			items={
				type="string",
	                        description= "item for move by this inserter"
				}			
                    },
            variant = {
              type = "string",
              description = "Variant of this entity. For example \"I\", \"R\" or \"L\" for belts."
            },
            type = {
              type = "string",
              description = "Type of this entity. Craft, minign etc."
            },
	    mining_progress  = {
              type = "number",
              description = "mining progress Is a number in range [0, mining_target.prototype.mineable_properties.mining_time]" 
            },
	    mining_target={
		 type = "object",
                 properties = {
			["x"] = { type = "number"                	},
	                ["y"] = { type = "number"                	},
                        ["name"]={type = "string"		},
		required = {"x", "y","name"}
	        },
	    },
	    crafting_progress  = {
              type = "number",
              description = "Creafting progress Is a number in range [0, 1]" 
            },
	    is_crafting = {
              type = "boolean",
              description = "Is crafting or not" 
            },
           items_count = {
              type = "number",
              description = "total items inside entity" 
            },


  	    drop_position= {
                 type = "object",
                 properties = {
			["x"] = { type = "number"                 	},
	                ["y"] = { type = "number"                	},
		required = {"x", "y"}
	        },
	    },

          },
          required = { "name", "x", "y", "direction" }
        }
      },
      wire_connections = {
        type = "array",
        items = {
          type = "object",
          properties = {
            start = {
              type = "object",
              properties = {
                ["x"] = {
                  type = "number"
                },
                ["y"] = {
                  type = "number"
                },
                ["z"] = {
                  type = "number"
                }
              },
              required = { "x", "y", "z" }
            },
            target = {
              type = "object",
              properties = {
                ["x"] = {
                  type = "number"
                },
                ["y"] = {
                  type = "number"
                },
                ["z"] = {
                  type = "number"
                }
              },
              required = { "x", "y", "z" }
            }
          },
          required = { "start", "target" }
        }
      },
      train_paths = {
        type = "array",
        items = {
          type = "object",
          properties = {
            carriages = {
              type = "array",
              items = {
                type = "integer",
                description = "Index in \"$.entities\" array"
              }
            },
            path = {
              type = "array",
              items = {
                type = "object",
                properties = {
                  index = {
                    type = "integer",
                    description = "Index in \"$.entities\" array"
                  },
                  invert_spline = {
                    type = "boolean"
                  }
                },
                required = { "index", "invert_spline" }
              }
            }
          },
          required = { "carriages", "path" }
        }
      },
      belt_paths = {
        type = "array",
        items = {
          type = "object",
          properties = {
            path = {
              type = "array",
              items = {
                type = "integer",
                description = "Index in \"$.entities\" array"
              }
            },
            items_lane_r = {
              type = "array",
              items = {
                type = "string"
              },
              description = "List of item names which can appear on right belt lane"
            },
            items_lane_l = {
              type = "array",
              items = {
                type = "string"
              },
              description = "List of item names which can appear on left belt lane"
            }
          },
          required = { "path" }
        }
      },
      logistic_systems = {
        type = "array",
        items = {
          type = "object",
          properties = {
            roboports = {
              type = "array",
              items = {
                type = "integer",
                description = "Index in \"$.entities\" array"
              }
            },
            chests = {
              type = "array",
              items = {
                type = "integer",
                description = "Index in \"$.entities\" array"
              }
            }
          },
          required = { "roboports", "chests" }
        }
      }
    },
    required = { "bounds", "entities", "wire_connections", "train_paths", "belt_paths", "logistic_systems" }
  }