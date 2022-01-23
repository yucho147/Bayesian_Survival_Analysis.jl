import Random
import YAML
using ArgParse
using CSV
using DataFrames
using Plots
using StatsBase
using StatsModels
using Survival

load_config(path::String) = YAML.load_file(path; dicttype=Dict{Symbol, Any})
set_seed(conf::Dict) = Random.seed!(conf[:seed])

# https://stackoverflow.com/questions/64565276/julia-dataframes-how-to-do-one-hot-encoding
function getdummies!(df::DataFrame, key::String; prefix_sep::String="_", drop_col::Bool=true)
  key = Symbol(key)
  ux = unique(df[:, key])
  transform!(df, @. key => ByRow(isequal(ux)) => Symbol(String(key) * prefix_sep, ux))
  if drop_col
    select!(df, Not(key))
  end
  return df
end
function getdummies!(df::DataFrame, key::Symbol; prefix_sep::String="_", drop_col::Bool=true)
  ux = unique(df[:, key])
  transform!(df, @. key => ByRow(isequal(ux)) => Symbol(String(key) * prefix_sep, ux))
  if drop_col
    select!(df, Not(key))
  end
  return df
end
getdummies(df::DataFrame, key::String; prefix_sep::String="_", drop_col::Bool=true) = getdummies!(deepcopy(df), key; prefix_sep=prefix_sep, drop_col=drop_col)
getdummies(df::DataFrame, key::Symbol; prefix_sep::String="_", drop_col::Bool=true) = getdummies!(deepcopy(df), key; prefix_sep=prefix_sep, drop_col=drop_col)

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table s begin
    "--conf", "-c"
      help = "config path"
      arg_type = String
      default = "./configs/survival_jl_config.yaml"
  end

  return parse_args(s; as_symbols=true)
end

function main()
  parsed_args = parse_commandline()
  @show parsed_args
  conf = load_config(parsed_args[:conf])
  @show conf

  df = CSV.read(conf[:input_data], DataFrame)
  @show first(df, conf[:nrow])

  X_df = df[:, [:gender, :gakui, :workertype]]

  # ダミー変数化
  getdummies!(X_df, "gakui")
  getdummies!(X_df, "workertype")

  # 標準化
  dt = fit(UnitRangeTransform, Float64.(Matrix(df[:, [:yearofjoin, :old]])), dims=1)
  normalizedX = StatsBase.transform(dt, Float64.(Matrix(df[:, [:yearofjoin, :old]])))
  X_df = hcat(X_df, DataFrame(normalizedX, [:yearofjoin, :old]))

  @show first(X_df, conf[:nrow])

  X = Matrix(X_df)
  println("X[1:$(conf[:nrow]), :] = ")
  display(X[1:conf[:nrow], :])
  println()

  y = EventTime.(df.seniority, [~i for i in Bool.(df.censored)])
  println("y[1:$(conf[:nrow])] = ")
  display(y[1:conf[:nrow]])
  println()

  coxmodel = fit(CoxModel, X, y; conf[:models][:coxph][:params]...)
  @show coxmodel

  # KaplanMeier
  kmmodel = fit(KaplanMeier, map(x -> x.time, y), map(x -> x.status, y))
  @show kmmodel

  (ϵ⁻, ϵ⁺) = (
    [s for s in kmmodel.survival] .- [i[1] for i in confint(kmmodel)],
    [i[2] for i in confint(kmmodel)] .- [s for s in kmmodel.survival]
  )
  plot(
    [(t, s) for (s, t) in zip(kmmodel.survival, kmmodel.times)],
    seriestype = :stepmid, title="KaplanMeier", xlabel="year"
  )
  scatter!(
    [(t, s) for (s, t) in zip(kmmodel.survival, kmmodel.times)]
    , yerror=(ϵ⁻, ϵ⁺), legend=false
  )
  png(conf[:outputs][:kmmodel_fig])

  # NelsonAalen
  namodel = fit(NelsonAalen, map(x -> x.time, y), map(x -> x.status, y))
  @show namodel

  # # cumulative hazard functionなので KaplanMeier とは異なる
  # # survivalと言う要素は存在しない
  # (ϵ⁻, ϵ⁺) = (
  #   [s for s in namodel.survival] .- [i[1] for i in confint(namodel)],
  #   [i[2] for i in confint(namodel)] .- [s for s in namodel.survival]
  # )
  # plot(
  #   [(t, s) for (s, t) in zip(namodel.survival, namodel.times)],
  #   seriestype = :stepmid, title="NelsonAalen", xlabel="year"
  # )
  # scatter!(
  #   [(t, s) for (s, t) in zip(namodel.survival, namodel.times)]
  #   , yerror=(ϵ⁻, ϵ⁺), legend=false
  # )
  # png(conf[:outputs][:namodel_fig])
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
