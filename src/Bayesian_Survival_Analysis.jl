module Bayesian_Survival_Analysis

using DataFrames
using Distributions
using StatsBase

const workertypedict = Dict(:shinsotsu => 1,
                            :tyuto => 2,
                            :chuto => 2,
                            :yakuin => 3)

function generateold(;N::Int, workertype::Int, λ::Union{Float64, Nothing}=nothing)::Vector{Int}
  if workertype == 1
    data = rand(Poisson(isnothing(λ) ? 2.5 : λ), N) .+ 22
  elseif workertype == 2
    data = rand(Poisson(isnothing(λ) ? 8. : λ), N) .+ 22
  elseif workertype == 3
    data = rand(Poisson(isnothing(λ) ? 8. : λ), N) .+ 35
  else
    error("定義されていないworkertype: $workertype")
  end
  data
end
# generateold(;N::Int, workertype::Symbol, λ::Union{Float64, Nothing}=nothing)::Vector{Int} = generateold(;N=N, workertype=get(workertypedict, workertype, -1), λ=λ)

function generategender(;N::Int, workertype::Int, p::Union{Float64, Nothing}=nothing)::Vector{Int}
  if workertype == 1
    data = rand(Bernoulli(isnothing(p) ? 0.65 : p), N)
  elseif workertype == 2
    data = rand(Bernoulli(isnothing(p) ? 0.7 : p), N)
  elseif workertype == 3
    data = rand(Bernoulli(isnothing(p) ? 0.9 : p), N)
  else
    error("定義されていないworkertype: $workertype")
  end
  data
end
# generategender(;N::Int, workertype::Symbol, p::Union{Float64, Nothing}=nothing)::Vector{Int} = generategender(;N=N, workertype=get(workertypedict, workertype, -1), p=p)

function generateyearofjoin(;df::DataFrame, stats::Union{Vector, Nothing}=nothing)::Vector{Int}
  if isnothing(stats)
    stats = [
      Dict(:min_year => 0, :max_year => 15),

      Dict(:min_year => 0, :max_year => 15),

      Dict(:min_year => 10, :max_year => 15)
    ]
  end

  function judgeyearofjoin(record, stats)
    workertype = record[:workertype]
    rand(stats[workertype][:min_year]:stats[workertype][:min_year])
  end

  [judgeyearofjoin(record, stats) for record in eachrow(df)]
end


function generategakui(;df::DataFrame, stats::Union{Vector, Nothing}=nothing)::Vector{Int}
  if isnothing(stats)
    stats = [
      Dict(:young => [0., 1.0, 0.0, 0.0],
           :middle => [0., 0.15, 0.85, 0.0],
           :senior => [0., 0.1, 0.4, 0.5]),

      Dict(:young => [0.4, 0.6, 0.0, 0.0],
           :middle => [0.4, 0.5, 0.1, 0.0],
           :senior => [0.3, 0.3, 0.3, 0.1]),

      Dict(:young => [0.05, 0.7, 0.2, 0.05],
           :middle => [0.05, 0.7, 0.2, 0.05],
           :senior => [0.05, 0.7, 0.2, 0.05])
    ]
  end

  function judgegakui(record, stats)
    old, workertype = record[:old], record[:workertype]
    if workertype == 1
      # 新卒
      if 22 ≤ old ≤ 23
        output = sample([0, 1, 2, 3], Weights(stats[1][:young]))
      elseif 24 ≤ old ≤ 26
        output = sample([0, 1, 2, 3], Weights(stats[1][:middle]))
      elseif 27 ≤ old
        output = sample([0, 1, 2, 3], Weights(stats[1][:senior]))
      end
    elseif workertype == 2
      # 中途
      if 22 ≤ old ≤ 23
        output = sample([0, 1, 2, 3], Weights(stats[2][:young]))
      elseif 24 ≤ old ≤ 26
        output = sample([0, 1, 2, 3], Weights(stats[2][:middle]))
      elseif 27 ≤ old
        output = sample([0, 1, 2, 3], Weights(stats[2][:senior]))
      end
    elseif workertype == 3
      # 役員
      if 22 ≤ old ≤ 23
        output = sample([0, 1, 2, 3], Weights(stats[3][:young]))
      elseif 24 ≤ old ≤ 26
        output = sample([0, 1, 2, 3], Weights(stats[3][:middle]))
      elseif 27 ≤ old
        output = sample([0, 1, 2, 3], Weights(stats[3][:senior]))
      end
    end
    output
  end

  [judgegakui(record, stats) for record in eachrow(df)]
end

end # module
