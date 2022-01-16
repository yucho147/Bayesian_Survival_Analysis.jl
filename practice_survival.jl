import Random
import YAML
using ArgParse
using CSV
using DataFrames
# using Distributions
using StatsBase
using StatsModels
using Survival

load_config(path::String) = YAML.load_file(path; dicttype=Dict{Symbol, Any})
set_seed(conf::Dict) = Random.seed!(conf[:seed])

# https://github.com/JuliaData/DataFrames.jl/issues/355#issuecomment-24754896
function getdummies(dfcol::Vector; prefix= " ", prefix_sep= '_')
  #Don't use prefix_sep if prefix is " ", otherwise leave as underscore as default
  if prefix == " "
    prefix_sep = ' '
  end

  #Create container to hold dummies
  resultdf = DataFrame()

  #Calculate unique levels, create column for each level, do comparison and convert bool to int
  for value in unique(dfcol)
    insertcols!(resultdf, Symbol(strip("$prefix$prefix_sep$value")) => map(x-> Int(x == value), dfcol))
  end
  return resultdf
end

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

  df = CSV.read(conf[:input_data], DataFrame)
  @show first(df, conf[:nrow])

  X_df = DataFrame(gender = df.gender)

  # ダミー変数化
  X_df = hcat(X_df, getdummies(df.gakui, prefix="gakui"))
  X_df = hcat(X_df, getdummies(df.workertype, prefix="workertype"))

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

  model = fit(CoxModel, X, y)
  @show model
end

main()
