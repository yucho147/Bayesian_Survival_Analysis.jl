# `practice_survival_jl` の実行例
```bash
Bayesian_Survival_Analysis/ % julia --project=@. practice_survival.jl --conf configs/survival_jl_config.yaml
parsed_args = Dict{Symbol, Any}(:conf => "configs/survival_jl_config.yaml")
first(df, conf[:nrow]) = 5×7 DataFrame
 Row │ censored  seniority  yearofjoin  gakui  old    gender  workertype
     │ Int64     Int64      Int64       Int64  Int64  Int64   Int64
─────┼───────────────────────────────────────────────────────────────────
   1 │        0          8           9      2     27       1           1
   2 │        1          1           1      1     25       1           1
   3 │        1          4           4      2     27       1           1
   4 │        1          1           1      3     28       1           1
   5 │        1          3           3      1     25       0           1
first(X_df, conf[:nrow]) = 5×10 DataFrame
 Row │ gender  gakui_2  gakui_1  gakui_3  gakui_0  workertype_1  workertype_2  workertype_3  yearofjoin  old
     │ Int64   Bool     Bool     Bool     Bool     Bool          Bool          Bool          Float64     Float64
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │      1     true    false    false    false          true         false         false   0.6        0.178571
   2 │      1    false     true    false    false          true         false         false   0.0666667  0.107143
   3 │      1     true    false    false    false          true         false         false   0.266667   0.178571
   4 │      1    false    false     true    false          true         false         false   0.0666667  0.214286
   5 │      0    false     true    false    false          true         false         false   0.2        0.107143
X[1:5, :] = 
5×10 Matrix{Float64}:
 1.0  1.0  0.0  0.0  0.0  1.0  0.0  0.0  0.6        0.178571
 1.0  0.0  1.0  0.0  0.0  1.0  0.0  0.0  0.0666667  0.107143
 1.0  1.0  0.0  0.0  0.0  1.0  0.0  0.0  0.266667   0.178571
 1.0  0.0  0.0  1.0  0.0  1.0  0.0  0.0  0.0666667  0.214286
 0.0  0.0  1.0  0.0  0.0  1.0  0.0  0.0  0.2        0.107143
y[1:5] = 
5-element Vector{EventTime{Int64}}:
 8
 1+
 4+
 1+
 3+
coxmodel = CoxModel{Float64}

Coefficients:
─────────────────────────────────────────────────
        Estimate  Std.Error     z value  Pr(>|z|)
─────────────────────────────────────────────────
x1    0.00182463  0.0821003   0.0222244    0.9823
x2   -0.381031    0.360504   -1.05694      0.2905
x3    0.295451    0.36017     0.82031      0.4120
x4   -1.28829     0.371271   -3.46995      0.0005
x5    1.37387     0.365342    3.76051      0.0002
x6    0.0222342   0.446363    0.049812     0.9603
x7    2.48793     0.441356    5.63702      <1e-07
x8   -2.51017     0.519498   -4.8319       <1e-05
x9    4.69004     0.209301   22.4081       <1e-99
x10  -2.98273     0.405289   -7.35952      <1e-12
─────────────────────────────────────────────────
```

![Kaplanmeierの結果](https://raw.githubusercontent.com/yucho147/Bayesian_Survival_Analysis.jl/dev_survival_jl/outputs/figs/Survival_jl/KaplanMeier_fig.png)
