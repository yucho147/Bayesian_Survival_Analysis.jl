import YAML
import Bayesian_Survival_Analysis
import Random
using DataFrames

data = YAML.load_file("test.yaml"; dicttype=Dict{Symbol,Any})
Random.seed!(data[:seed])

df = DataFrame(
  old = cat([src.generateold(;data[:generateold][i]...) for i in 1:3]..., dims=1),
  gender = cat([src.generategender(;data[:generategender][i]...) for i in 1:3]..., dims=1),
  workertype = cat(ones(Int, data[:proper_num]), ones(Int, data[:mid_career_num]) * 2, ones(Int, data[:high_career_num]) * 3, dims=1)
)
insertcols!(df, 1, :gakui => src.generategakui(;df=df, stats=data[:generategakui][:stats]))
