import YAML
import Bayesian_Survival_Analysis
import Random
using CSV
using DataFrames

data = YAML.load_file("test.yaml"; dicttype=Dict{Symbol,Any})
Random.seed!(data[:seed])

df = DataFrame(
  # 入社した時の年齢
  old = cat([Bayesian_Survival_Analysis.generateold(;data[:generateold][i]...) for i in 1:3]..., dims=1),
  # 性別
  gender = cat([Bayesian_Survival_Analysis.generategender(;data[:generategender][i]...) for i in 1:3]..., dims=1),
  # 役職(1: 新卒, 2: 中途, 3: 役員)
  workertype = cat(ones(Int, data[:proper_num]), ones(Int, data[:mid_career_num]) * 2, ones(Int, data[:high_career_num]) * 3, dims=1)
)
# 学位(0: 高卒, 1: 学士, 2: 修士, 3: 博士)
insertcols!(df, 1, :gakui => Bayesian_Survival_Analysis.generategakui(;df=df, stats=data[:generategakui][:stats]))

# 入社年(何年前に入社したか?)
insertcols!(df, 1, :yearofjoin => Bayesian_Survival_Analysis.generateyearofjoin(;df=df, stats=data[:generateyearofjoin][:stats]))

# 勤続年数
insertcols!(df, 1, :seniority => Bayesian_Survival_Analysis.generateseniority(;df=df))

# 打ち切りフラグ
insertcols!(df, 1, :censored => Bayesian_Survival_Analysis.generatecensored(;df=df))

show(df)

df |> CSV.write("./data/dummy_data.csv", delim=',', writeheader=true)
