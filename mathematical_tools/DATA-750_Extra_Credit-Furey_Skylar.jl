### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ 8936a9f5-835a-4919-a0d7-d307a50759ef
md"
# DATA-750: Extra-credit problem 

## Least-Squares Problem Exploration
### Name: Skylar Furey (stfurey@unc.edu)
"

# ╔═╡ 642f5b8e-0128-4e18-a721-63a854066c25
md"
> In this extra-credit problem, you will explore some of the concepts discussed in the _least-squares_ module. You can complete and submit solutions to this extra-credit assignment to `reisanar@unc.edu` for up to 20 extra-credit points in HW03. Please make sure to submit any solutions before the start of our live-session meeting for this week.
"

# ╔═╡ 5931a372-4852-4f67-b796-ff18339e10c4
md"
## Advertising Dataset

You are asked to read the data available in the link <https://raw.githubusercontent.com/reisanar/datasets/master/Advertising.csv>. 

The `Advertising` dataset consists of the sales of a particular product in 200 different markets, along with advertising budgets for the product in each of those
markets for three different media: `TV`, `Radio`, and `Newspaper`. (This dataset comes from the \"Introduction to Statistical Learning\" book by G. James et al.)
"

# ╔═╡ c7b7c313-fa7f-49e1-be82-f2d73b466342
md"
### Tasks


(1) Read the data and use the `Sales` column as your right-hand side vector $b$. 

(2) Decide which other column you will use to _model_ TV sales as a linear function of the budget in `Newspaper`, `TV` or `Radio` (you can select any column as your predictor)

(3) Set up a least-squares problem (with a _linear fit_) for this exercise. Make sure to properly define your design matrix $A$. 

(4) Solve the least-squares problem using: 

	(a) The normal equations approach (build the normal equations and solve)

    (b) Julia notation that uses the `\` operator to solve `c = A\b`

    (c) The function `pinv()`.

(5) Compare all solutions and comment on your results. 

(6) If $\hat{c}$ is the solution to the least-squares problem, compute $A^T (A\hat{c} - b)$. Comment on your results. 

(7) Explore if the Gram matrix $A^TA$ is invertible (you can choose any approach you wish to investigate this)
"

# ╔═╡ Cell order:
# ╟─8936a9f5-835a-4919-a0d7-d307a50759ef
# ╟─642f5b8e-0128-4e18-a721-63a854066c25
# ╟─5931a372-4852-4f67-b796-ff18339e10c4
# ╟─c7b7c313-fa7f-49e1-be82-f2d73b466342
