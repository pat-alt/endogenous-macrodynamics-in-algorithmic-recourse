using LazyArtifacts
using CounterfactualExplanations.DataPreprocessing: CounterfactualData
using CSV
using DataFrames
using Serialization
using StatsBase

"""
    output_dir(dir="")

Sets up the directory to save computational outputs and returns the path.
"""
function output_dir(dir="")
    root_ = "dev/artifacts/upload/output"
    output_dir = joinpath(root_, dir)
    if !isdir(output_dir)
        mkpath(output_dir)
    end
    return output_dir
end

"""
    www_dir(dir="")

Sets up the directory to save images and returns the path.
"""
function www_dir(dir="")
    root_ = "dev/artifacts/upload/www"
    www_dir = joinpath(root_, dir)
    if !isdir(www_dir)
        mkpath(www_dir)
    end
    return www_dir
end

"""
    data_dir(dir="")

Sets up the directory to save images and returns the path.
"""
function data_dir(dir="")
    root_ = "dev/artifacts/upload/data"
    data_dir = joinpath(root_, dir)
    if !isdir(data_dir)
        mkpath(data_dir)
    end
    return data_dir
end

function load_synthetic(max_obs::Union{Nothing,Int}=nothing; data_dir::Union{Nothing, String}=nothing)
    if isnothing(data_dir)
        data_dir = joinpath(artifact"data", "data/synthetic")
    end
    files = readdir(data_dir)
    files = files[contains.(files, ".csv")]
    data = map(files) do file
        df = CSV.read(joinpath(data_dir, file), DataFrame)
        X = convert(Matrix, hcat(df.x1, df.x2)')
        y = convert(Matrix, df.target')
        data = CounterfactualData(X, y)
        if !isnothing(max_obs)
            n_classes = length(unique(y))
            data = undersample(data, Int(round(max_obs / n_classes)))
        end
        (Symbol(replace(file, ".csv" => "")) => data)
    end
    data = Dict(data...)
    return data
end

function load_real_world(max_obs::Union{Nothing,Int}=nothing; data_dir::Union{Nothing, String}=nothing)
    if isnothing(data_dir)
        data_dir = joinpath(artifact"data", "data/real_world")
    end
    files = readdir(data_dir)
    files = files[contains.(files, ".jls")]
    data = map(files) do file
        counterfactual_data = Serialization.deserialize(joinpath(data_dir, file))
        if !isnothing(max_obs)
            n_classes = length(unique(counterfactual_data.y))
            counterfactual_data = undersample(counterfactual_data, Int(round(max_obs / n_classes)))
        end
        (Symbol(replace(file, ".jls" => "")) => counterfactual_data)
    end
    data = Dict(data...)
    return data
end


function scale(X, dim)
    dt = fit(ZScoreTransform, X, dim=dim)
    X_scaled = StatsBase.transform(dt, X)
    return X_scaled, dt
end

function rescale(X, dt)
    X_rescaled = StatsBase.reconstruct(dt, X)
    return X_rescaled
end