using CSV
using DataFrames
using Survival
using StatsModels

df = CSV.read("./data/dummy_data.csv", DataFrame)
# TODO: 標準化とダミー変数化
X = Matrix(df[:, [:yearofjoin, :gakui, :old, :gender, :workertype]])
y = EventTime.(df.seniority, [~i for i in Bool.(df.censored)])
model = fit(CoxModel, X, y)
