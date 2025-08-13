### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ 6aaec993-ccad-438d-b856-2bf8a4b9bb50
# ╠═╡ disabled = true
#=╠═╡
import Pkg; Pkg.add("OSQP")
  ╠═╡ =#

# ╔═╡ dd845276-a495-4f43-a5ac-75d675603374
#=╠═╡
# use copy of the iris dataset
Pkg.add("RDatasets")
  ╠═╡ =#

# ╔═╡ b167bde5-a021-4ce5-a966-6bdbbe5f2581
# ╠═╡ disabled = true
#=╠═╡
Pkg.add("StatsBase")
  ╠═╡ =#

# ╔═╡ c2a9d6b7-ab9b-4a4d-9449-edcf4f6ac252
begin
	using CSV
	using DataFrames
	using MultivariateStats
	using Plots	
end

# ╔═╡ bc27ce0f-fe22-48a8-8832-75bd010c8c21
using Optim

# ╔═╡ efc92846-f4f3-41bf-98c1-cceb8acb95d5
begin
	using LinearAlgebra
	using RDatasets
	using StatsBase
	using OSQP
	using SparseArrays
	using Statistics
end

# ╔═╡ fbfa9f28-8a9a-4056-82cb-515c97fbd503
md"
# DATA-750: Numerical Project 3

## Skylar Furey
### Email: `stfurey@unc.edu`

> Numerical projects are designed to practice concepts from a collection of concepts covered in the course, while exploring computational aspects of the different mathematical tools for data science that are discussed in the modules, live meetings, and other class activities. Please make sure to contact your instructor if there are any questions.
"

# ╔═╡ a5a0c576-625e-4a81-825b-8887c849c5b1
md"
## Part A (30 points): 

Multidimensional Scaling (MDS) encompasses a collection of data analysis techniques that **represent proximity data by spatial distance models**. MDS is typically applied to a dissimilarity matrix, such as one representing distances between different locations.

Kruskal and Wish (1978) outlined how the method could be used to uncover answers to a variety of questions capturing people's viewpoints on political candidates, reducing the data and issues (say, partisanship and ideology) to a [two-dimensional map](https://en.wikipedia.org/wiki/Multidimensional_scaling). 

Given distances $d_{ij}$ between points $i$ and $j$, an **optimization problem** can be formulated to represent the $N$ data points in a $K$ dimensional space by solving 

$$
\min_{x_1,..., x_N} \sum_{i<j} \left(\Vert x_i - x_j \Vert - d_{ij}\right)^2$$

where $x_i \in \mathbb{R}^ K$ and $\Vert \cdot \Vert$ denote, for example, the Euclidean norm. 


This is known as _least squares_ or _Kruskal-Shepard_ scaling. The idea is to _find a lower-dimensional representation of the data_ that **preserves the pairwise distances** as well as possible. The objective function in the problem above is sometimes called the _stress function_. 

**Notice that here we want to minimize the squared error between Euclidean distances of the coordinates and the entries in a distance matrix.** Given the distances $d_{ij}$ you want to find the optimal location of data point $x_i$ and $x_j$ in the plane.

> - Use an optimization solver of your choice to apply MDS to the distance matrix of cities available at <https://raw.githubusercontent.com/reisanar/datasets/master/cities_distance.csv>. 
>
> - Comment on your approach and your results. Once an optimal solution is found, you should be able to generate a plot with the approximate \"location\" of each of the cities in a 2D map similar to:

![](https://github.com/reisanar/figs/raw/master/mds-solution.png)



"


# ╔═╡ fa9025f2-2956-4ba7-a177-437a2733d00a
md"
## Solutions to Part A

Please include as many cells below (both code and markdown) as needed to provide your solutions to this problem.
"

# ╔═╡ 2c44af87-d1dd-4a1b-9ef8-265a602cd122
begin
	url = "https://raw.githubusercontent.com/reisanar/datasets/master/cities_distance.csv"
	df = CSV.read(download(url), DataFrame)
	
	dist_matrix = Array{Float64}(df[:, 2:end])
end

# ╔═╡ 2e1a5320-eaa4-485c-ae18-6abe5ae62884
begin
	mds =fit(MDS, dist_matrix; maxoutdim=2, distances=false)

	coordinates = projection(mds)
end

# ╔═╡ a2baca03-bfe3-4521-8fdd-c482b12c2d2e
begin
	scatter(coordinates[:, 1], coordinates[:, 2], color=:red, legend=false, grid=false, xticks=[], yticks=[], size= (800,600))
	for i in 1:size(coordinates, 1)
    	annotate!(coordinates[i, 1], coordinates[i, 2], text(string(df[i, 1]), :left))
	end
	title!("MDS Map")
end

# ╔═╡ 60552284-996f-4a49-8d3a-6d6de6657295
md"
Commentary on Part A:

I downloaded the csv from the website; then extracted the numerical matrix representing the distances between each of the cities. I used the MultvariateStats package to implement an MDS fit on the matrix making sure to set the maxoutdim to 2 in order to get x and y coordinates. I then used the projection function to pull the exact coordinates from the fit. I then plotted the coordinates based on there x,y projections on a blank graph. I made sure to add the city names next to each of there coordinates.

Once I found the right package and function to complete the MDS and project the coordinates this problem was straight forward. I tweaked the plot a couple times to make it as blank as I could. I was having trouble getting the plot to show without putting the title arguement outside of the scatter function call, not sure if this was due to the annotation being outside or not.

"

# ╔═╡ f51aa32f-08bd-4277-a605-fd1791b527fc
md"
## Part B (35 points): 


Suppose we have observations $(x_1, y_1), \ldots, (x_n, y_n)$ and we want to find a function $f$ such that $y_i \approx f(x_i)$ for $i = 1, \ldots, n$.
Further suppose that $f$ can be **parameterized** by some vector of parameters $\mathbf{\theta} = (\theta_1, \ldots, \theta_d)^T$.

We write $f(\mathbf{x}; \mathbf{\theta})$ for $f(\mathbf{x})$ to emphasize the dependence on $\mathbf{\theta}$. The problem of finding the parameter $\mathbf{\theta}^*$, such that the fitted points $\hat{y}_i = f(x_i; \mathbf{\theta}^*)$ are _closest_ to the observations $y_i$, is called **curve fitting**.

To measure how close the fitted points are to the observed points, we use a **loss function**. Two popular choices are:

- the **sum of squares**
$$
L_2(\mathbf{\theta}) = \sum_{i=1}^n (y_i - \hat{y}_i)^2$$

- and the **sum of absolute differences**
$$
L_1(\mathbf{\theta}) = \sum_{i=1}^n |y_i - \hat{y}_i|.$$


_Note that we consider a loss function to be a function of $\mathbf{\theta}$, rather than a function of $\mathbf{y}$, because we are interested in how the loss changes as we change $\mathbf{\theta}$_

Given a loss function $L$, we choose $\mathbf{\theta}^\star$ to be that $\mathbf{\theta}$ that minimizes $L(\mathbf{\theta})$.

In this problem you will consider some data on the growth of trees (data available at <https://raw.githubusercontent.com/reisanar/datasets/master/trees.csv>)


"

# ╔═╡ c54118c4-da57-4584-9c09-4003cd4ebc4b
begin
	# Read the CSV file from the provided URL
	url2 = "https://raw.githubusercontent.com/reisanar/datasets/master/trees.csv"
	df2 = CSV.read(download(url2), DataFrame)
	
	# Filter the DataFrame for rows where ID matches "1.3.11"
	filtered_df = filter(row -> row.ID == "1.3.11", df2)
	
	# Create a plot of Volume versus Age
	plot(filtered_df.Age, filtered_df.Vol, xlabel="Age", ylabel="Volume", title="Volume vs Age for ID 1.3.11", seriestype=:scatter, legend =false)
	
end

# ╔═╡ 8bd3b728-e3af-4a8d-9e0d-fe692982dfd7
md"
The figure shows the volume of a [spruce tree](https://en.wikipedia.org/wiki/Spruce) at different ages. Volume refers to the volume of the trunk and is measured in $\text{m}^3$. Age is measured by counting growth rings from a core taken at height 1.3 $\text{m}$, and thus is measured in years since the trunk reached a height of 1.3 $\text{m}$.

A popular ecological model for the plant size (measured by volume) as a function of age is the [Richards curve](https://en.wikipedia.org/wiki/Generalised_logistic_function):

$$
f(x) = a(1-e^{-bx})^c$$

Here the parameters are $\mathbf{\theta} = (a,b,c)^T$. Parameter $a$ gives the maximum size of the plant and parameter $b$ describes the speed of growth. For biological reasons parameter $c$ is often expected to be close to 3. (For a reference see: Zeide, Boris. \"Analysis of growth equations.\" Forest science 39.3 (1993): 594-616.)

> - You are asked to to fit the Richards curve to the observations, trying both the **sum of squares loss function** and the **sum of absolute differences**.
>
> -  Use an optimization method of your choice, test different initial points, and comment on your results. Create a plot that compares the fit using both approaches. A sample plot is included below for your reference.

![](https://github.com/reisanar/figs/raw/master/tree-growth.png)

"

# ╔═╡ 136c08a3-cd25-44f9-8951-a3348023bc07
md"
## Solutions to Part B

Please include as many cells below (both code and markdown) as needed to provide your solutions to this problem.
"

# ╔═╡ 26b32d92-bde0-483d-8521-70d7262c28d9
function richards_curve(x, params)
    a, b, c = params
    a .* (1 .- exp.(-b .* x)).^c
end

# ╔═╡ cf473984-364f-4621-85f2-1104b41be6bf
function sum_of_squares(params, x, y)
    predictions = richards_curve(x, params)
    sum((y .- predictions).^2)
end

# ╔═╡ 265e717f-bc8c-406e-b58b-0b0e6dcb9bcb
function sum_of_absolute_differences(params, x, y)
    predictions = richards_curve(x, params)
    sum(abs.(y .- predictions))
end

# ╔═╡ 1276958c-e68f-4cdf-975f-77bc93d4675d
begin
	x2 = filtered_df[:, :Age]
	y2 = filtered_df[:, :Vol]
	initial_params = [2106.0, 0.1, 3.0]
end

# ╔═╡ 399d7fdd-da31-4ebd-bc96-4eb5f3e8ab6b
begin
	obj_funSAD(params) = sum_of_absolute_differences(params, x2, y2)
	resultSAD = optimize(obj_funSAD, initial_params)
end

# ╔═╡ 364329fe-4cef-4733-97b7-6e636a2b3c04
params_sad = resultSAD.minimizer

# ╔═╡ db6ffb48-d591-4af3-a7bd-1f18d1ec733e
begin
	obj_funSS(params) = sum_of_squares(params, x2, y2)
    resultSS = optimize(obj_funSS, initial_params)
end

# ╔═╡ f9264bee-8ae1-4d48-82e5-a80f3c8dd272
params_ss = resultSS.minimizer

# ╔═╡ 53c768b2-b89e-4251-b156-897180f38196
begin
	fit_ss = richards_curve(x2, params_ss)
	fit_sad = richards_curve(x2, params_sad)
	
	plot(x2, y2, seriestype=:scatter, label="Data", xlabel="Age (in years)", ylabel="Volume (in cubic meters)", title="Richards Curve Fitting", legend=:topright)
	plot!(x2, fit_ss, label="Fit (Sum of Squares)", color=:red)
	plot!(x2, fit_sad, label="Fit (Sum of Absolute Differences)", color=:blue)
end

# ╔═╡ 185d45e3-6e59-450e-983c-2968a2479f13
md"
Commentary on Part B:

I defined Richards curve, the sum of squares and sum of absolute differences functions. Then created functions to optimize the results of each function and apply the minimizer function to said results.

I originally choose to use the initial params 1,1,3 making sure that c is 3 because of biological reasons. The results were shockingly dissimilar with the sum of squares parameters being double those of the absolute differences. When I plotted the curves based on the parameters they were nowhere near the true curve.

I then thought about what each of the parameters meant and decided to choose the max volume in the dataset to be my intial guess for a. I tried b=1 and got an error so I tried 0.1 and got parameters that seemed to be optimal for each method as the fit lines matched the dataset. This time the parameters were much closer to eachother causing the fit lines to almost the same for each method.
"

# ╔═╡ 7b74b491-67b9-4d08-918b-6baaae441104
md"
## Part C (35 points)

In this problem you will explore the use of an optimization solver to find the _separating hyperplane_ that can be used as a **classifier** to distinguish between observations with different _labels_. This falls under the category of _supervised learning_ methods, and here we introduce a linear support vector machine (SVM) that serves as _classifier_. Details on the mathematical approach are discussed in the live session and included at the end of this document. (See section: _\"Support Vector Machines (SVM): optimization formulation\"_ at the end of the document)

Follow the step-by-step example below using the famous [`iris` dataset](https://en.wikipedia.org/wiki/Iris_flower_data_set). After successful exploration, you are asked to: 


> - Test the same approach using a different combination of two of the other numerical attributes available in the dataset (e.g., using the sepal width and the sepal length instead). 
>
> - Comment on your results. What could you modify to improve the _misclassification rate_ in this case. 
>
> - Explore at least 2 properties of the matrices involve in the formulation of the optimizatio problem. Comment on your results. 
>
> - Can you solve the same problem using a different optimization approach? You could check other available libraries in Julia for optimization or a different formulation of the optimization problem. 

"

# ╔═╡ d7ee859b-bf0a-46ca-aba0-c890233f9b5e
md"
## Solutions to Part C

Please include as many cells below (both code and markdown) as needed to provide your solutions to this problem.
"

# ╔═╡ 83c8cd81-23a6-4cff-b744-d910ceca8c0d
md"
Commentary on Part C

The line that is initially commented out adding lambda multiplied by the identity matrix corrects the hyperplane such that there is no misclassification.

There are 2 eigenvalues, one being much larger than the other. The large eigenvalue shows that the matrix transformation was significantly stretched or compressed by one of the eigenvectors. WHile the other eigenvector did not affect the transformation nearly as much.

The semi-high condition number for the input matrix means that it is not decently sensitive to changes in the data.

You can definitely use other optimizers such as the SCS and GLPK package models or you could use Gradient Descent if you want to code more from scratch.
"

# ╔═╡ 3d7e1810-3461-49fd-8196-d939e5d60cf1
md"
> ------------ Step-by-step exploration of a linear SVM classifier ------------

Below we provide step-by-step instructions to explore the use of quadrartic programming (QP) as the optimization formulation of the linear classifier using the SVM approach. 

"

# ╔═╡ b0bbb0a9-60a1-4e92-a942-c8003b8d59b7
#=╠═╡
begin
	X2 = Matrix(iris[:, [:SepalLength, :PetalWidth]])
	y3 = iris[:, :y]
	n2 = size(X2, 1)
end
  ╠═╡ =#

# ╔═╡ 2fe814dc-0952-4709-95b7-f4c80e4d06d2
#=╠═╡
begin
	K = X2' * X2
	eigvals = eigen(K).values
	println("Eigenvalues: ", eigvals)
	
	println("Condition number: ", cond(K))
end
  ╠═╡ =#

# ╔═╡ a48f12c5-dbbf-4c05-9387-37c0551ef54c
#=╠═╡
begin
	# Set the problem data and parameters
	X = Matrix(iris[:, [:PetalLength, :PetalWidth]])
	y = iris[:, :y]
	n = size(X, 1)
end
  ╠═╡ =#

# ╔═╡ 6dc565df-33e3-4e92-b589-26305b35ee62
#=╠═╡
# confirm unique "labels"
unique(y)
  ╠═╡ =#

# ╔═╡ 69982de0-99ed-4743-bbf3-65f8ac174fbc
# ╠═╡ disabled = true
#=╠═╡
# count number of observations in each class
countmap(y)
  ╠═╡ =#

# ╔═╡ 86481cf8-dfe7-4700-b50e-cbc56667218b
md" 
Now that we have the dataset, we proceed to set up the optimization problem (quadratic optimization problem) that we need to solve for this classification problem
"

# ╔═╡ 493b2074-e085-482d-a929-928be154ce69
md"
> The OSQP solver requires the matrices to be in the SparseMatrixCSC format from the SparseArrays module. Documentation here <https://osqp.org/docs/solver/index.html>

It solves a problem of the form 

$
\begin{split}\begin{array}{ll}
  \mbox{minimize} & \frac{1}{2} x^T P x + q^T x \\
  \mbox{subject to} & l \leq A x \leq u
\end{array}\end{split}$
"

# ╔═╡ 93663782-5bd7-42f7-9659-9bd78da28568
md"
A custom function to identify the slope and intercept of the _separating plane_ is included below. This will be used to create a final plot dividing the observations in two groups.
"

# ╔═╡ 1ef161c3-88e7-4b4a-a9fd-46d1f43abc66
#=╠═╡
begin
	# Plot the results
	scatter(X2[:, 1], X2[:, 2], group=y3, 
		legend=false, title="SVM Solution using QP approach")
	plot!(x -> qpline[2] * x + qpline[1], 
		color=:green, label="quadprog", linewidth=3)
end
  ╠═╡ =#

# ╔═╡ 3cb27098-bb31-4e85-a48e-4ba4e0b0abbb
#=╠═╡
println("Separating hyperplane using QP formulation: \nIntercept: ", qpline[1], " Slope: ", qpline[2])
  ╠═╡ =#

# ╔═╡ e1459a91-e30a-4d6b-898e-fbed80457f06
# ╠═╡ disabled = true
#=╠═╡
begin
	# Plot the results
	scatter(X[:, 1], X[:, 2], group=iris[:, :y], 
		legend=false, title="SVM Solution using QP approach")
	plot!(x -> qpline[2] * x + qpline[1], 
		color=:green, label="quadprog", ylim = (-0.3, 4), linewidth=3)
end
  ╠═╡ =#

# ╔═╡ 3bf63f98-e9d5-426f-ad1e-332d17e561b7
# ╠═╡ disabled = true
#=╠═╡
# Print the results
println("Separating hyperplane using QP formulation: \nIntercept: ", qpline[1], " Slope: ", qpline[2])
  ╠═╡ =#

# ╔═╡ 2e7ae758-b2cf-45b4-87ee-3ea5caa52c8a
md"

## Support Vector Machines (SVM): optimization formulation 

In this section we present the mathematical formulation of the SVM
method for classification problems.

The basic idea in this method is to find a hyperplane which separates
the $d$-dimensional data perfectly into its two classes. 


Suppose we are given $l$ training samples $\left\{ \mathbf{x}_{i},\, y_{i}\right\} ,$
$i=1,...,\, l,$ where each sample belongs to $\mathbb{R}^{d}$ and
a class label with one of two values $y_{i}$ is given for each training
sample. For simplicity assume, $y_{i}\in\{-1,1\}.$ Notice that all
hyperplanes $\mathcal{H}$ in $\mathbb{R}^{d}$ are parameterized
by a vector $w$ and a constant $b$ in the following way:

$
\begin{align}
w^{T}x+b & =0,
\end{align}$

where $w$ is a vector orthogonal to the hyperplane $\mathcal{H}.$
Given such hyperplane, that we denote by $\left\langle w,b\right\rangle ,$
that separates the data, the function 

$\begin{align}
f(x) & =\text{sgn}(w^{T}x+b),
\end{align}$

correctly classifies the data. Notice though that a given hyperplane
represented by $\left\langle w,b\right\rangle ,$ is equally expressed
by all pairs $\{\lambda w,\lambda b\}$ for any $\lambda>0.$ Therefore,
let us define the canonical hyperplane to be the one that separates
the data from the hyperplane by a distance of at least $1.$ This
means, the following relations must be satisfied:

$
\begin{align}
\mathbf{x}_{i}^{T}w+b\geq1 & \quad\text{when }y_{i}=+1,\\
\mathbf{x}_{i}^{T}w+b\geq-1 & \quad\text{when }y_{i}=-1.
\end{align}$

These two relations can be compacted in the inequality

$
\begin{align}
y_{i}\left(\mathbf{x}_{i}^{T}w+b\right) & \geq1,\quad\forall i=1,..\: l.
\end{align}$

To obtain the geometric distance from the hyperplane $\mathcal{H}$
to a data point, we normalize by the magnitude of $w,$ and get

$
\begin{align}
d\left(\mathcal{H},\mathbf{x}_{i}\right) & =\frac{y_{i}\left(\mathbf{x}_{i}^{T}w+b\right)}{\Vert w\Vert}\geq\frac{1}{\Vert w\Vert}.
\end{align}$


![](https://github.com/reisanar/figs/raw/master/hyperplaneSVM.png)


In the process of classifying objects, intuitively we look for the
hyperplane $\mathcal{H}$ that maximizes the geometric distance to
the closest data points. From the relations shown above, w can see
that this is accomplished by minimizing $\Vert w\Vert,$ subject to
the distance constraints. We are now in position to formulate the
optimization problem, whose primal formulation is given by 

$
\begin{align}
\min & \ \frac{1}{2}\Vert w\Vert^{2}\nonumber \\
\text{subject to } & \ y_{i}\left(\mathbf{x}_{i}^{T}w+b\right)\ \geq1,\quad\forall i=1,...,l.
\end{align}$

This problem can be solved using techniques from
constrained optimization. The Lagrangian function associated to this
problem is given by 

$
\begin{align*}
\mathcal{L}(w,b) & =\frac{1}{2}w^{T}w+\sum_{i=1}^{l}\alpha_{i}\left(1-y_{i}\left(\mathbf{x}_{i}^{T}w+b\right)\right),
\end{align*}$

and setting the gradient of $\mathcal{L}$ with respect to $w$ an
$b$ to zero, we have the equations 

$
\begin{align}
w & =\sum_{i=1}^{l}\alpha_{i}y_{i}\mathbf{x}_{i},\\
\sum_{i=1}^{l}\alpha_{i}y_{i} & =0.
\end{align}$

If we substitute $w=\sum\alpha_{i}y_{i}\mathbf{x}_{i}$ in the expression
for $\mathcal{L}$ we get

$
\begin{align}
\mathcal{L}(w,b) & =-\frac{1}{2}\sum_{i=1}^{l}\sum_{j=1}^{l}\alpha_{i}\alpha_{j}y_{i}y_{j}\mathbf{x}_{i}^{T}\mathbf{x}_{j}+\sum_{i=1}^{l}\alpha_{i},
\end{align}$

which means we have expressed the Lagrangian function in terms of
$\alpha_{i}$ only. If we know $w$ we know all $\alpha_{i},$ and
if we know $\alpha_{i}$ we know $w$ for all $i=1,...,\, l.$ 

Thus, we can formulate the dual problem as 

$
\begin{align}
\max & \ W(\alpha)=\sum_{i=1}^{l}\alpha_{i}-\frac{1}{2}\sum_{i=1}^{l}\sum_{j=1}^{l}\alpha_{i}\alpha_{j}y_{i}y_{j}\mathbf{x}_{i}^{T}\mathbf{x}_{j}\nonumber \\
\text{subject to } & \ \alpha_{i}\geq0,\ \sum_{i=1}^{l}\alpha_{i}y_{i}=0.
\end{align}$

Notice that this problem i a quadratic programming
(QP) problem, and the global maximum of $\alpha_{i}$ can always be
found using one of the different QP solvers developed in the latest
years (sequential quadratic programming, sequential minimal optimization,
etc) 

Some of the characteristics of the solution of this QP problem 
are that many of the $\alpha_{i}$ are zero, which means that $w$
is a linear combination of a small number of data points. Those data points $\mathbf{x}_{i}$
where the corresponding $\alpha_{i}$ are called _support vectors_. 

Once a solution has been found, any new data point $\mathbf{u}$ is
classified using the following two steps:


1. Compute $w^{T}\mathbf{u}+b =\sum_{j=1}^{s}\alpha_{t_{j}}y_{t_{j}}(\mathbf{x}_{t_{j}}^{T}\mathbf{u})+b,$

1. Classify $\mathbf{u}$ as class $1$ if the sum is positive, and class 2 otherwise.


As a note, the QP optimization problem described above could be formualed as a minimization problem of the form:

$
\begin{align}
\min & \ \frac{1}{2} \mathbf{\alpha}^T \mathbf{P} \mathbf{\alpha} - \mathbf{1}^T \mathbf{\alpha}\\
\text{subject to } & \ \mathbf{\alpha}\geq 0,\ \mathbf{y}^T \mathbf{\alpha}=0.
\end{align}$

where $\mathbf{1}$ is a vector of $1$'s, $\mathbf{y} = (y_1, ..., y_l)^T$ is the vector of labels, $\mathbf{\alpha} = (\alpha_1 , ..., \alpha _l)^T$ is the unknown vector, and $\mathbf{P}$ is a matrix with entry $p_{i,j} = y_{i}y_{j}\mathbf{x}_{i}^{T}\mathbf{x}_{j}$

"

# ╔═╡ 78093f6f-0ca1-412e-b0be-0c9b0f235c39
md"
## Some References

1. \"OSQP: an operator splitting solver for quadratic programs\" by Bartolomeo Stellato, Goran Banjac, Paul Goulart, Alberto Bemporad, and Stephen Boyd. Link to paper <https://web.stanford.edu/~boyd/papers/pdf/osqp.pdf>

1. \"Mathematics for Machine Learning\" by Marc Peter Deisenroth, A. Aldo Faisal, and Cheng Soon Ong. Published by Cambridge University Press. Link to online version of the book: <https://mml-book.github.io/>

1. `NLsolve.jl`: Solving non-linear systems of equations in Julia. Source: <https://github.com/JuliaNLSolvers/NLsolve.jl>

1. `Optim.jl`: Univariate and multivariate optimization in Julia. Source: <https://github.com/JuliaNLSolvers/Optim.jl>



"

# ╔═╡ d9caeb41-c2b1-44c7-b74a-280dded6b647
# ╠═╡ disabled = true
#=╠═╡
begin
	# Set up the OSQP problem
	model = OSQP.Model()
	OSQP.setup!(
	    model, 
	    P = P, 
	    q = q, 
	    A = A, 
	    l = l, 
	    u = u
	)
	result = OSQP.solve!(model)
end
  ╠═╡ =#

# ╔═╡ 9f184b1f-09c8-4602-b7dc-184100953bdb
#=╠═╡
begin
	# Load the Fisher iris data and binarize one of the species
	iris = dataset("datasets", "iris")
	iris[!, :y] = ifelse.(iris[:, :Species] .== "setosa", 1, -1)
	
	# Order the training data 
	iris = iris[sortperm(iris[:, :y], rev=true), :]
	
end
  ╠═╡ =#

# ╔═╡ 7e83ad01-0e5f-4e8d-9644-0fcae4baccc6
# ╠═╡ disabled = true
#=╠═╡
begin
	# Load the Fisher iris data and binarize one of the species
	iris = dataset("datasets", "iris")
	iris[!, :y] = ifelse.(iris[:, :Species] .== "setosa", 1, -1)
	
	# Order the training data 
	iris = iris[sortperm(iris[:, :y], rev=true), :]
	
end
  ╠═╡ =#

# ╔═╡ 14c7783a-b84c-4bdc-908a-3dcd97dd55fb
# ╠═╡ disabled = true
#=╠═╡
# get results (all of the alpha_i in problem formulation)
qpsol = result.x
  ╠═╡ =#

# ╔═╡ 26f20bfb-c659-42f2-97a7-97f416f84ed4
#=╠═╡
begin
	# Function to find the decision boundary line
	function findLine(a, y, X)
	    # Compute the weight vector W
	    W = zeros(2)
	    for i in 1:length(a)
	        W .+= a[i] * y[i] * X[i, :]
	    end
	    
	    # Compute the intercept b
	    b = mean([X[i, :] ⋅ W - y[i] for i in 1:size(X, 1) if abs(a[i]) > 5e-3])
	    
	    # Compute the slope and intercept for the decision boundary line
	    slope = -W[1] / W[2]
	    intercept = b / W[2]
	    return (intercept, slope)
	end
end
  ╠═╡ =#

# ╔═╡ 9cfc21d7-3603-4e44-9f7f-6f02bda2993b
#=╠═╡
begin
	qpsol = result.x
	qpline = findLine(qpsol, y3, X2)
end
  ╠═╡ =#

# ╔═╡ 56a4b93c-8ecd-4b4d-a1b6-8f044013d8c5
# ╠═╡ disabled = true
#=╠═╡
begin
	# Build the system matrices
	Q = Matrix{Float64}(I, n, n)  # Initialize Q as an identity matrix of size n x n
	for i in 1:n
	    for j in 1:n
	        Q[i, j] = y[i] * y[j] * (X[i, :] ⋅ X[j, :])  # Constructing Q matrix
	    end
	end
end
  ╠═╡ =#

# ╔═╡ 2cd5148a-02cb-4416-a527-96350fd7e887
# ╠═╡ disabled = true
#=╠═╡
begin
	# define a small perturbation
	lambda = 5e-4
	P = Q #+ lambda*I(n)
	P = sparse(P)  # implementation expects sparse matrices
end
  ╠═╡ =#

# ╔═╡ 86261d0b-cc02-4adb-893f-19c5f3b1f2ad
#=╠═╡
begin
	# Set up the OSQP problem
	model = OSQP.Model()
	OSQP.setup!(
	    model, 
	    P = P, 
	    q = q, 
	    A = A, 
	    l = l, 
	    u = u
	)
	result = OSQP.solve!(model)
end
  ╠═╡ =#

# ╔═╡ 97c0aef1-0f7b-4f13-bb8f-afc36a23ad47
# ╠═╡ disabled = true
#=╠═╡
begin
	# Function to find the decision boundary line
	function findLine(a, y, X)
	    # Compute the weight vector W
	    W = zeros(2)
	    for i in 1:length(a)
	        W .+= a[i] * y[i] * X[i, :]
	    end
	    
	    # Compute the intercept b
	    b = mean([X[i, :] ⋅ W - y[i] for i in 1:size(X, 1) if abs(a[i]) > 5e-3])
	    
	    # Compute the slope and intercept for the decision boundary line
	    slope = -W[1] / W[2]
	    intercept = b / W[2]
	    return (intercept, slope)
	end
end
  ╠═╡ =#

# ╔═╡ 0a48e6b4-1aef-4867-a8a3-e5ed199a44e4
# ╠═╡ disabled = true
#=╠═╡
qpline = findLine(qpsol, y, X)
  ╠═╡ =#

# ╔═╡ bc873de5-15a0-4cf2-9e34-0c85198e78d3
#=╠═╡
begin
	# define a small perturbation
	lambda = 5e-4
	P = Q + lambda*I(n)
	P = sparse(P)  # implementation expects sparse matrices
end
  ╠═╡ =#

# ╔═╡ 41bbb07e-ab65-430e-98e8-feaaddea8693
#=╠═╡
begin
	# Build the system matrices
	Q = Matrix{Float64}(I, n2, n2)  # Initialize Q as an identity matrix of size n x n
	for i in 1:n2
	    for j in 1:n2
	        Q[i, j] = y3[i] * y3[j] * (X2[i, :] ⋅ X2[j, :])  # Constructing Q matrix
	    end
	end
end
  ╠═╡ =#

# ╔═╡ 5c10effd-dc7e-4e7e-8158-c397f7475b2a
#=╠═╡
begin
	# set up the matrices and vectors needed for optimization problem
	q = -ones(n)
	A = vcat(y3', Matrix{Float64}(I, n, n))
	# A = Matrix{Float64}(A) 
	A = sparse(A)
	l = vcat(0.0, zeros(n))			# lower bound
	u = vcat(0.0, fill(Inf, n))		# upper bound
end
  ╠═╡ =#

# ╔═╡ a329831a-4b9e-4ac7-8c73-3cd83bd32330
# ╠═╡ disabled = true
#=╠═╡
begin
	# set up the matrices and vectors needed for optimization problem
	q = -ones(n)
	A = vcat(y', Matrix{Float64}(I, n, n))
	# A = Matrix{Float64}(A) 
	A = sparse(A)
	l = vcat(0.0, zeros(n))			# lower bound
	u = vcat(0.0, fill(Inf, n))		# upper bound
end
  ╠═╡ =#

# ╔═╡ Cell order:
# ╟─fbfa9f28-8a9a-4056-82cb-515c97fbd503
# ╟─a5a0c576-625e-4a81-825b-8887c849c5b1
# ╟─fa9025f2-2956-4ba7-a177-437a2733d00a
# ╠═c2a9d6b7-ab9b-4a4d-9449-edcf4f6ac252
# ╠═2c44af87-d1dd-4a1b-9ef8-265a602cd122
# ╠═2e1a5320-eaa4-485c-ae18-6abe5ae62884
# ╠═a2baca03-bfe3-4521-8fdd-c482b12c2d2e
# ╟─60552284-996f-4a49-8d3a-6d6de6657295
# ╟─f51aa32f-08bd-4277-a605-fd1791b527fc
# ╠═c54118c4-da57-4584-9c09-4003cd4ebc4b
# ╟─8bd3b728-e3af-4a8d-9e0d-fe692982dfd7
# ╟─136c08a3-cd25-44f9-8951-a3348023bc07
# ╠═26b32d92-bde0-483d-8521-70d7262c28d9
# ╠═cf473984-364f-4621-85f2-1104b41be6bf
# ╠═265e717f-bc8c-406e-b58b-0b0e6dcb9bcb
# ╠═bc27ce0f-fe22-48a8-8832-75bd010c8c21
# ╠═1276958c-e68f-4cdf-975f-77bc93d4675d
# ╠═399d7fdd-da31-4ebd-bc96-4eb5f3e8ab6b
# ╠═364329fe-4cef-4733-97b7-6e636a2b3c04
# ╠═db6ffb48-d591-4af3-a7bd-1f18d1ec733e
# ╠═f9264bee-8ae1-4d48-82e5-a80f3c8dd272
# ╠═53c768b2-b89e-4251-b156-897180f38196
# ╟─185d45e3-6e59-450e-983c-2968a2479f13
# ╟─7b74b491-67b9-4d08-918b-6baaae441104
# ╟─d7ee859b-bf0a-46ca-aba0-c890233f9b5e
# ╠═26f20bfb-c659-42f2-97a7-97f416f84ed4
# ╠═efc92846-f4f3-41bf-98c1-cceb8acb95d5
# ╠═9f184b1f-09c8-4602-b7dc-184100953bdb
# ╠═b0bbb0a9-60a1-4e92-a942-c8003b8d59b7
# ╠═41bbb07e-ab65-430e-98e8-feaaddea8693
# ╠═bc873de5-15a0-4cf2-9e34-0c85198e78d3
# ╠═5c10effd-dc7e-4e7e-8158-c397f7475b2a
# ╠═86261d0b-cc02-4adb-893f-19c5f3b1f2ad
# ╠═9cfc21d7-3603-4e44-9f7f-6f02bda2993b
# ╠═1ef161c3-88e7-4b4a-a9fd-46d1f43abc66
# ╠═3cb27098-bb31-4e85-a48e-4ba4e0b0abbb
# ╠═2fe814dc-0952-4709-95b7-f4c80e4d06d2
# ╟─83c8cd81-23a6-4cff-b744-d910ceca8c0d
# ╟─3d7e1810-3461-49fd-8196-d939e5d60cf1
# ╠═dd845276-a495-4f43-a5ac-75d675603374
# ╠═7e83ad01-0e5f-4e8d-9644-0fcae4baccc6
# ╠═a48f12c5-dbbf-4c05-9387-37c0551ef54c
# ╠═6dc565df-33e3-4e92-b589-26305b35ee62
# ╠═b167bde5-a021-4ce5-a966-6bdbbe5f2581
# ╠═69982de0-99ed-4743-bbf3-65f8ac174fbc
# ╟─86481cf8-dfe7-4700-b50e-cbc56667218b
# ╠═6aaec993-ccad-438d-b856-2bf8a4b9bb50
# ╟─493b2074-e085-482d-a929-928be154ce69
# ╠═56a4b93c-8ecd-4b4d-a1b6-8f044013d8c5
# ╠═2cd5148a-02cb-4416-a527-96350fd7e887
# ╠═a329831a-4b9e-4ac7-8c73-3cd83bd32330
# ╠═d9caeb41-c2b1-44c7-b74a-280dded6b647
# ╟─93663782-5bd7-42f7-9659-9bd78da28568
# ╠═97c0aef1-0f7b-4f13-bb8f-afc36a23ad47
# ╠═14c7783a-b84c-4bdc-908a-3dcd97dd55fb
# ╠═0a48e6b4-1aef-4867-a8a3-e5ed199a44e4
# ╠═e1459a91-e30a-4d6b-898e-fbed80457f06
# ╠═3bf63f98-e9d5-426f-ad1e-332d17e561b7
# ╟─2e7ae758-b2cf-45b4-87ee-3ea5caa52c8a
# ╟─78093f6f-0ca1-412e-b0be-0c9b0f235c39
