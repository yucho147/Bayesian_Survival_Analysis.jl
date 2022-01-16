import YAML
import Random
using ArgParse
using Bayesian_Survival_Analysis
using CSV
using DataFrames
# using Revise

load_config(path::String) = YAML.load_file(path; dicttype=Dict{Symbol, Any})
set_seed(conf::Dict) = Random.seed!(conf[:seed])

function generate_dummy_df(conf::Dict)
  set_seed(conf)

  df = DataFrame(
    # 入社した時の年齢
    old = cat([generateold(;conf[:generateold][i]...) for i in 1:3]..., dims=1),
    # 性別
    gender = cat([generategender(;conf[:generategender][i]...) for i in 1:3]..., dims=1),
    # 役職(1: 新卒, 2: 中途, 3: 役員)
    workertype = cat(ones(Int, conf[:proper_num]), ones(Int, conf[:mid_career_num]) * 2, ones(Int, conf[:high_career_num]) * 3, dims=1)
  )
  # 学位(0: 高卒, 1: 学士, 2: 修士, 3: 博士)
  insertcols!(df, 1, :gakui => generategakui(;df=df, stats=conf[:generategakui][:stats]))

  # 入社年(何年前に入社したか?)
  insertcols!(df, 1, :yearofjoin => generateyearofjoin(;df=df, stats=conf[:generateyearofjoin][:stats]))

  # 勤続年数
  insertcols!(df, 1, :seniority => generateseniority(;df=df))

  # 打ち切りフラグ
  insertcols!(df, 1, :censored => generatecensored(;df=df))
end

output_csv(df::DataFrame, conf::Dict) = CSV.write(conf[:output_path], df, delim=',', writeheader=true)

function parse_commandline()
  s = ArgParseSettings()

  @add_arg_table s begin
    "--conf", "-c"
      help = "config path"
      arg_type = String
      default = "./configs/generate_data_config.yaml"
  end

  return parse_args(s; as_symbols=true)
end

function main()
  parsed_args = parse_commandline()
  @show parsed_args
  conf = load_config(parsed_args[:conf])
  df = generate_dummy_df(conf)
  show(df)
  output_csv(df, conf)
end

main()
