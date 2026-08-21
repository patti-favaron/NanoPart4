module Config

    using TOML

    export Config, get_config

    # This is configuration: change as needed
    mutable struct Config
        valid::Bool
        x_min::Float32
        x_max::Float32
        y_min::Float32
        y_max::Float32
        n_seconds::Int64
        n_parts_per_second::Int64
        n_pixel::Int64
        dpi::Int64
        opacity::Float64
    end

    # Get configuration
    function get_float32(d, key::String, default::Float32)::Float32
        if haskey(d, key)
            value = d[key]
            if typeof(value) === :Float64
                return convert(Float32, value)
            else
                return default
            end
        else
            return default
        end
    end
    
    function get_float64(d, key::String, default::Float64)::Float64
        if haskey(d, key)
            value = d[key]
            if typeof(value) === :Float64
                return value
            else
                return default
            end
        else
            return default
        end
    end
    
    function get_int64(d, key::String, default::Int64)::Int64
        if haskey(d, key)
            value = d[key]
            if typeof(value) === :Int64
                return value
            else
                return default
            end
        else
            return default
        end
    end
    
    function get_config(cfg_name)
    
        # Assign empties (not surviving validation)
        cfg = Config(false,0.0f0,0.0f0,0.0f0,0.0f0,0,0,0,0,0.0)
        
        # Get configuration data from file; in case they are missing
        # the configuration keys do not fulfil validity criteria, preventing
        # a costly improper run to start
        d = TOML.parsefile(cfg_name)
        if haskey(d, "Particle_Pool")
            dg = d["Particle_Pool"]
            cfg.n_seconds = get_int64(dg, "length_second", 3600)
            cfg.n_parts_per_second = get_int64(dg, "parts_per_step", 10)
        end
        if haskey(d, "Movie_Frames")
            dg = d["Movie_Frames"]
            delta::Float32 = get_float32(dg, "edge_length_meters", 700.0f0)
            edge_inch::Int64 = get_int64(dg, "edge_inch", 5)
            cfg.dpi = get_int64(dg, "dpi", 200)
            cfg.n_pixel = cfg.dpi * edge_inch
            cfg.opacity = get_float64(dg, "opacity", 0.25)
            cfg.x_min = -delta / 2.0f0
            cfg.x_max =  delta / 2.0f0
            cfg.y_min = -delta / 2.0f0
            cfg.y_max =  delta / 2.0f0
        end
            
        # Perform validation
        cfg.valid = true
        if cfg.x_max - cfg.x_min <= 0.0
            cfg.valid = false
            println("Invalid 'edge_length_meter': cannot be negative or zero")
        end
        if cfg.n_pixel <= 0
            cfg.valid = false
            println("Invalid combination of 'edge_inch' and 'dpi': their combination cannot be zero or negative")
        end
        if cfg.n_pixel > 2000
            cfg.valid = false
            println("Invalid combination of 'edge_inch' and 'dpi': their combination cannot be larger than 2000")
        end
        if cfg.n_parts_per_second <= 0
            cfg.valid = false
            println("Invalid 'parts_per_step': cannot be zero or negative")
        end
        if cfg.n_parts_per_second > 100
            cfg.valid = false
            println("Invalid 'parts_per_step': cannot be larger than 100")
        end
        
        # Yield result
        return cfg
        
    end
    
end
