setup = quote

    using Pkg; Pkg.activate(".")

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
    using StatsBase
    using StatsPlots

    # Setup
    Random.seed!(42)              # global seed to allow for reproducibility
    theme(:wong)

    # Utils
    include("src/utils.jl")

end