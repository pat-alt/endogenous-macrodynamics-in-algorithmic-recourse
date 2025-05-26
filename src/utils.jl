using CounterfactualExplanations.DataPreprocessing: CounterfactualData
using CSV
using DataFrames
using ghr_jll
using LazyArtifacts
using LibGit2
using MLUtils
using Serialization
using StatsBase


# Artifacts:
artifact_toml = LazyArtifacts.find_artifacts_toml(".")

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
    _path = joinpath(root_, dir)
    if !isdir(_path)
        mkpath(_path)
    end
    return _path
end
