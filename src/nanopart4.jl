# Configure plotting system for headless 
ENV["GKSwstype"] = "100"

using CSV
using TOML
# Imported modules
using DataFrames
using Plots
using Printf
using Distributions
#using CUDA

# Internal modules
include("src/Config.jl")
using .Config


#############
# Functions #
#############

# Check and get command arguments
function get_args()

    # Check parameters, and print a message if not valid
    if length(ARGS) !== 3 then
        println("nanopart4 - Driver to build ultrasonic anemometer flow displays")
        println("")
        println("Usage:")
        println("")
        println("  julia nanopart4.jl <cfg_file> <met_file> <out_file>")
        println("")
        println("For best results the <out_file> should be an .mp4")
        println("")
        println("Copyright 2026 by Patrizia Favaron")
        println("This is open-source software, covered by MIT license")
        println("")
        exit(1)
    end
    
    # Get parameters and yield them
    cfg_file = ARGS[1]
    met_file = ARGS[2]
    out_file = ARGS[3]
    (cfg_file, met_file, out_file)
    
end


# Show particles

function Take_Snap(
    xmin::Float32, xmax::Float32, ymin::Float32, ymax::Float32,
    i::Int64, path::String,
    x::Vector{Float32}, y::Vector{Float32}, num_parts::Int64
)
    
    # Generate the scatter plot of current particles
    p = plot(
        x[1:num_parts],
        y[1:num_parts],
        seriestype = :scatter,
        ms = 1, mc = :black, ma = 0.25,
        legend = false,
        dpi = 200.0,
        xlims = (xmin,xmax),
        ylims = (ymin,ymax),
        xlabel = "X (m)",
        ylabel = "Y (m)",
        aspect_ratio = :equal,
        size = (1000,1000)
    )
    
    # Generate file name and save plot
    file_name = @sprintf "%s/%06d" path i
    
end

# Particle movement and generation

function update_particles!(
    i::Int64,
    vx::Float64, vy::Float64, uu::Float64, uv::Float64, vv::Float64,
    x::Vector{Float32}, y::Vector{Float32},
    num_parts::Int64, next_part::Int64
)

    # Set distribution
    m = [vx, vy]
    C = [uu uv; uv vv]
    distr = MvNormal(m, C)
    # -1- Generate the actual shifts
    delta = rand(distr, num_parts)
    # -1- Apply the shifts
    for k in 1:num_parts
        x[k] += delta[1,k]
        y[k] += delta[2,k]
    end
    
    # Emit new particles
    for p_idx in 1:ne
        x[next_part] = 0.0
        y[next_part] = 0.0
        next_part += 1
        if next_part > np
            next_part = 1
        end
        num_parts += 1
        if num_parts > np
            num_parts = np
        end
    end
    
    # Generate current snapshot
    Take_Snap(
        cfg.x_min, cfg.x_max, cfg.y_min, cfg.y_max,
        i, out,
        x, y, num_parts
    )
    
    # Send back modified counters
    return (num_parts, next_part)
    
end


###############
# Main logics #
###############

# Get parameters and configuration data
(cfg_file, met, out) = get_args()
cfg = get_config(cfg_file)

# Set particle pool by pre-allocating it
ne::Int64 = cfg.n_parts_per_second
np::Int64 = ne * cfg.n_seconds
x::Vector{Float32} = zeros(np)
y::Vector{Float32} = zeros(np)

# Read meteo data
met_data = CSV.read(met, DataFrames.DataFrame; delim = ',', header = true)
n = nrow(met_data)

# Initialize particle pool (actually, assume the prescribed number of particles have
# beel released on second 0)
next_part::Int64 = cfg.n_parts_per_second + 1
num_parts::Int64 = cfg.n_parts_per_second

# Take initial snapshot with all first particles at origin
i::Int64 = 0
Take_Snap(
    cfg.x_min, cfg.x_max, cfg.y_min, cfg.y_max,
    i, out,
    x, y, num_parts
)

# Iterate over meteo data
a = @animate for i in 1:n

    global num_parts
    global next_part

    # Move existing particles
    vx = met_data.u[i]
    vy = met_data.v[i]
    uu = met_data.uu[i]
    vv = met_data.vv[i]
    uv = met_data.uv[i]
    (num_parts, next_part) = update_particles!(i, vx, vy, uu, uv, vv, x, y, num_parts, next_part)
    
    println("Iteration no. ", i, " out of ", n)
    
end
println("Writing video file to ", out)
gif(a, out)
