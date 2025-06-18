module EMAR

export load_synthetic, load_synthetic_results, load_real_world, load_real_world_results, create_artifact_name_from_path, artifact_hash, artifact_toml, artifact_path
export www_dir, output_dir, data_dir 
export plot_res

# Deps:
using AlgorithmicRecourseDynamics
using AlgorithmicRecourseDynamics: run_bootstrap
using AlgorithmicRecourseDynamics.Models
using AlgorithmicRecourseDynamics.Models: model_evaluation
using CounterfactualExplanations
using CounterfactualExplanations: counterfactual, counterfactual_label
using CSV
using DataFrames
using Flux
using Images
using LaplaceRedux
using Markdown
using MLJBase
using MLJModels: ContinuousEncoder, OneHotEncoder, Standardizer
using MLUtils
using MLUtils: undersample
using Plots
using PrettyTables
using Random
using RCall
using Serialization
using Statistics
using StatsBase
using StatsPlots

# Setup
Random.seed!(42)              # global seed to allow for reproducibility
theme(:wong)

# Utils
include("utils.jl")
include("load_results.jl")
include("post_processing.jl")

end
