using Pkg.Artifacts
using Serialization

"""
    load_synthetic(max_obs::Union{Nothing,Int}=nothing; artifact_name::Union{Nothing,String}=nothing, root=".", tag="camera-ready")

Downloads artifacts for the synthetic data for the given `tag`.
"""
function load_synthetic(max_obs::Union{Nothing,Int}=nothing; artifact_name::Union{Nothing,String}=nothing, root=".", tag="camera-ready")
    artifact_name = create_artifact_name_from_path(data_dir("synthetic"), artifact_name)
    _hash = artifact_hash(artifact_name, artifact_toml(root))
    origin_url = get_git_remote_url(root)
    deploy_repo = "$(basename(dirname(origin_url)))/$(splitext(basename(origin_url))[1])"
    download_artifact(_hash, "https://github.com/$(deploy_repo)/releases/download/$(tag)/$(artifact_name).tar.gz")
    _path = joinpath(artifact_path(_hash), artifact_name)
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

function load_results(cat::String="synthetic", mitigation::Bool=false, latent::Bool=false)

    # Determine output path based on inputs:
    if mitigation
        output_path = output_dir("mitigation_strategies")
        if latent
            output_path = joinpath(output_path, "results_$(cat)_latent.jls")
        else
            output_path = joinpath(output_path, "results_$(cat).jls")
        end
    else
        output_path = joinpath(output_dir(cat), "results.jls")
    end

    # Load from correct folder:
    results = try
        Serialization.deserialize(output_path)
    catch
        output_path = replace(output_path, "upload" => "download")
        Serialization.deserialize(output_path)
    end

    return results
end

load_synthetic_results() = load_results("synthetic")
load_real_world_results() = load_results("real_world")
load_synthetic_mitigation() = load_results("synthetic", true)
load_synthetic_mitigation_latent() = load_results("synthetic", true, true)
load_real_world_mitigation() = load_results("real_world", true)

"""
    load_real_world(max_obs::Union{Nothing,Int}=nothing; artifact_name::Union{Nothing,String}=nothing, root=".", tag="camera-ready")

Downloads artifacts for real world data for the given `tag`.
"""
function load_real_world(max_obs::Union{Nothing,Int}=nothing; artifact_name::Union{Nothing,String}=nothing, root=".", tag="camera-ready")
    artifact_name = create_artifact_name_from_path(data_dir("real_world"), artifact_name)
    _hash = artifact_hash(artifact_name, artifact_toml(root))
    origin_url = get_git_remote_url(root)
    deploy_repo = "$(basename(dirname(origin_url)))/$(splitext(basename(origin_url))[1])"
    download_artifact(_hash, "https://github.com/$(deploy_repo)/releases/download/$(tag)/$(artifact_name).tar.gz")
    _path = joinpath(artifact_path(_hash), artifact_name)
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
    tag="thesis"
)

    if deploy && !haskey(ENV, "GITHUB_TOKEN")
        @warn "For automatic github deployment, need GITHUB_TOKEN. Not found in ENV, attemptimg global git config."
    end

    if deploy
        # Where we will put our tarballs
        tempdir = mktempdir()

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
    artifact_name = isnothing(artifact_name) ? replace(datafiles, ("/" => "-")) : artifact_name
    return artifact_name
end

function get_git_remote_url(repo_path::String)
    repo = LibGit2.GitRepo(repo_path)
    origin = LibGit2.get(LibGit2.GitRemote, repo, "origin")
    return LibGit2.url(origin)
end

"""
    artifacts_to_local_dev(
        ;
        tag::String="jan-2023",
        root="."
    )

Downloads all artifacts from Github to local `dev/artifacts/download` folder.
"""
function artifacts_to_local_dev(
    ;
    tag::String="jan-2023",
    root="."
)
    artifact_toml = joinpath(root, "Artifacts.toml")
    artifact_names = keys(LazyArtifacts.select_downloadable_artifacts(artifact_toml, include_lazy=true))
    origin_url = get_git_remote_url(root)
    deploy_repo = "$(basename(dirname(origin_url)))/$(splitext(basename(origin_url))[1])"
    for _name in artifact_names
        _hash = artifact_hash(_name, artifact_toml)
        download_artifact(_hash, "https://github.com/$(deploy_repo)/releases/download/$(tag)/$(_name).tar.gz")
        old_path = joinpath(artifact_path(_hash), _name)
        up_path = replace(_name, ("-" => "/"))
        new_path = replace(up_path, ("upload" => "download"))
        if !isdir(new_path)
            mkpath(joinpath(root, new_path))
        end
        cp(old_path, new_path, force=true)
    end
end

using CSV
using DataFrames

function load_bootstrap(cat::String="synthetic", mitigation::Bool=false, latent::Bool=false)
    # Determine output path based on inputs:
    if mitigation
        output_path = output_dir("mitigation_strategies")
        if latent
            output_path = joinpath(output_path, "bootstrap_latent.csv")
        else
            output_path = joinpath(output_path, "bootstrap_$(cat).csv")
        end
    else
        output_path = joinpath(output_dir(cat), "bootstrap.csv")
    end
    output_path = output_dir(cat)
    _file = readdir(output_path)[contains.(readdir(output_path),"bootstrap")]
    _file = joinpath.(output_path, _file)
    df = CSV.File(_file) |> DataFrame
    return df
end

load_bootstrap_synthetic() = load_bootstrap("synthetic")
load_bootstrap_real_world() = load_bootstrap("real_world")
load_bs_mitigation_synthetic() = load_bootstrap("synthetic", true)
load_bs_mitigation_latent() = load_bootstrap("synthetic", true, true)
load_bs_mitigation_real_world() = load_bootstrap("real_world", true)

