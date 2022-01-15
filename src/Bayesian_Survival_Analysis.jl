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
    rand(stats[workertype][:min_year]:stats[workertype][:max_year])
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
    if 22 ≤ old ≤ 23
      output = sample([0, 1, 2, 3], Weights(stats[workertype][:young]))
    elseif 24 ≤ old ≤ 26
      output = sample([0, 1, 2, 3], Weights(stats[workertype][:middle]))
    elseif 27 ≤ old
      output = sample([0, 1, 2, 3], Weights(stats[workertype][:senior]))
    end
    output
  end

  [judgegakui(record, stats) for record in eachrow(df)]
end

"""
scoreを算出し、scoreが高いほど勤続年数を伸ばす設定とする
昔ブラックだったが、近年ホワイトになる会社を想定
学位を積めば積むほど勤続年数が伸びる設定
入社時の年齢が若いほど勤続年数が短くなる設定
性別は勤続年数に依らない設定
勤続年数は「役員->新卒->中途」の順で短くなる設定
"""
function generateseniority(;df::DataFrame)::Vector{Int}
  function judgeseniority(record)
    yearofjoin, gakui, old, gender, workertype = record[:yearofjoin], record[:gakui], record[:old], record[:gender], record[:workertype]
    score = - yearofjoin / 10.0 + gakui / 3. + old / 20.
    if workertype == 3
      score += 5.
    elseif workertype == 1
      score += 2.
    else
      score += 1.
    end
    score
  end

  N = nrow(df)
  X = [judgeseniority(record) for record in eachrow(df)]

  dt = fit(UnitRangeTransform, X, dims=1)
  normalizedX = StatsBase.transform(dt, X)

  noisedX = normalizedX .+ rand(Uniform(-0.1, 0.1), N)
  dt = fit(UnitRangeTransform, noisedX, dims=1)
  normalizedX = StatsBase.transform(dt, noisedX)

  seniority = round.(Int, normalizedX .* 20)
  [s > y ? y : s for (s, y) in zip(seniority, df.yearofjoin)]
end

function generatecensored(;df::DataFrame)::Vector{Int}
  function judgecensored(record)
    seniority, yearofjoin = record[:seniority], record[:yearofjoin]
    seniority == yearofjoin ? 1 : 0
  end

  [judgecensored(record) for record in eachrow(df)]
end


end # module
