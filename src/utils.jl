using CounterfactualExplanations.DataPreprocessing: CounterfactualData
using ghr_jll
using LazyArtifacts
using LibGit2
using CSV
using DataFrames
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

function load_synthetic(max_obs::Union{Nothing,Int}=nothing; artifact_name::Union{Nothing,String}=nothing)
    artifact_name = create_artifact_name_from_path(data_dir("synthetic"), artifact_name)
    _hash = artifact_hash(artifact_name, artifact_toml)
    _path = joinpath(artifact_path(_hash),artifact_name)
    files = readdir(_path)
    files = files[contains.(files, ".csv")]
    data = map(files) do file
        df = CSV.read(joinpath(_path, file), DataFrame)
        X = convert(Matrix, hcat(df.x1, df.x2)')
        y = convert(Matrix, df.target')
        data = CounterfactualData(X, y)
        if !isnothing(max_obs)
            n_classes = length(unique(y))
            data = AlgorithmicRecourseDynamics.Data.undersample(data, Int(round(max_obs / n_classes)))
        end
        (Symbol(replace(file, ".csv" => "")) => data)
    end
    data = Dict(data...)
    return data
end

function load_real_world(max_obs::Union{Nothing,Int}=nothing; artifact_name::Union{Nothing,String}=nothing)
    artifact_name = create_artifact_name_from_path(data_dir("real_world"), artifact_name)
    _hash = artifact_hash(artifact_name, artifact_toml)
    _path = joinpath(artifact_path(_hash),artifact_name)
    files = readdir(_path)
    files = files[contains.(files, ".jls")]
    data = map(files) do file
        counterfactual_data = Serialization.deserialize(joinpath(_path, file))
        if !isnothing(max_obs)
            n_classes = length(unique(counterfactual_data.y))
            counterfactual_data = AlgorithmicRecourseDynamics.Data.undersample(counterfactual_data, Int(round(max_obs / n_classes)))
        end
        (Symbol(replace(file, ".jls" => "")) => counterfactual_data)
    end
    data = Dict(data...)
    return data
end

function generate_artifacts(
    datafiles;
    artifact_name=nothing,
    root=".",
    artifact_toml=joinpath(root, "Artifacts.toml"),
    deploy=true,
    tag="camera-ready"
)

    if deploy && !haskey(ENV, "GITHUB_TOKEN")
        @warn "For automatic github deployment, need GITHUB_TOKEN. Not found in ENV, attemptimg global git config."
    end

    if deploy
        # Where we will put our tarballs
        tempdir = mktempdir()

        function get_git_remote_url(repo_path::String)
            repo = LibGit2.GitRepo(repo_path)
            origin = LibGit2.get(LibGit2.GitRemote, repo, "origin")
            return LibGit2.url(origin)
        end

        # Try to detect where we should upload these weights to (or just override
        # as shown in the commented-out line)
        origin_url = get_git_remote_url(root)
        deploy_repo = "$(basename(dirname(origin_url)))/$(splitext(basename(origin_url))[1])"

    end

    # Name for hash/artifact:
    artifact_name = create_artifact_name_from_path(datafiles, artifact_name)

    # create_artifact() returns the content-hash of the artifact directory once we're finished creating it
    hash = create_artifact() do artifact_dir
        cp(datafiles, joinpath(artifact_dir, artifact_name))
    end

    # Spit tarballs to be hosted out to local temporary directory:
    if deploy

        tarball_hash = archive_artifact(hash, joinpath(tempdir, "$(artifact_name).tar.gz"))

        # Calculate tarball url
        tarball_url = "https://github.com/$(deploy_repo)/releases/download/$(tag)/$(artifact_name).tar.gz"

        # Bind this to an Artifacts.toml file
        @info("Binding $(artifact_name) in Artifacts.toml...")
        bind_artifact!(
            artifact_toml, artifact_name, hash;
            download_info=[(tarball_url, tarball_hash)], lazy=true, force=true
        )
    end

    if deploy
        # Upload tarballs to a special github release
        @info("Uploading tarballs to $(deploy_repo) tag `$(tag)`")

        ghr() do ghr_exe
            println(readchomp(`$ghr_exe -replace -u $(dirname(deploy_repo)) -r $(basename(deploy_repo)) $(tag) $(tempdir)`))
        end

        @info("Artifacts.toml file now contains all bound artifact names")
    end

end

function create_artifact_name_from_path(datafiles::String, artifact_name::Union{Nothing,String})
    # Name for hash/artifact:
    artifact_name = isnothing(artifact_name) ? replace(datafiles, ("/" => "-")) : artifact_
    return artifact_name
end