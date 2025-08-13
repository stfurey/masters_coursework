### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ c674e9dc-0bbb-11ef-0719-d5b7ce34a3a8
md"
# DATA-750: HW 01 Introduction to Matrices and Operations

## Skylar Furey
### Email: `stfurey@unc.edu`
"

# ╔═╡ 9b8d9fc8-6658-4c68-9279-2bc3cd61b05c
md"
In this first homework assignment you will be practicing some basic operations using the Julia programming language, and exploring some of the concepts discussed during Week 01 and Week 02 in the DATA 750 course. _Please use this sample template and structure as guidelines of the expected way to organize your work and solutions._

> Make sure to contact your instructor if there are any questions (`reisanar@unc.edu`)
"

# ╔═╡ 3418db22-454b-4cb7-8d79-4e70296ee2e7
md"
# Problem 1 (20 points)

(a) Define a variable `mycourse` with the name of this course as a string (use double quotes). 

(b) Use the `findall()` function, to count how many a's are in the name of the course.

(c) Define a 2x2 matrix $A$ with: 

- the month you were born in position $a_{11}$, 
- the day of the month you were born in position $a_{12}$, 
- the number of classes you are taking this term in position $a_{21}$, and 
- the day of the week this class meets in position $a_{22}$ (Assume the week starts on Sunday)

(d)  Multiply matrix $A$ from part (c) with its transpose. What can you say about the resulting matrix? 
"

# ╔═╡ bb6454b4-71ce-4367-8834-183915283970
md"
## Solutions to Problem 1

Please include as many cells below as needed to provide your solutions to this problem.
"

# ╔═╡ d98d3264-6c05-4f68-a028-87031da3b5c8
# Example: Solutions to part (a) go here
mycourse = "DATA750 Mathematical Tools"

# ╔═╡ a5bfd95f-c382-4f2c-8e83-1f5b57e1d9b9
# Example: Solutions to part (b) go here
findall("a", mycourse)

# ╔═╡ 71600ebd-9fc0-467e-8921-c2cd8ffb6eb3
# Example: Solutions to part (c) go here
A = [8 8;2 5]

# ╔═╡ ea972acb-81f9-4578-bb10-30a0730b08dd
md"
The resulting matrix is 2x2 because A has 2 rows and AT has 2 columns. y12 and y21 will always be equal.
"

# ╔═╡ e1d5bd80-1eeb-47a6-9a24-7b68c44df97b
md"
# Problem 2 (30 points)

(a) Use the `rand()` function to generate a 5x7 matrix $B$ of random numbers. 

(b) Extract the matrix block that contains the entries between rows 2 and 4, and columns 3 and 5. 

(c) Create a random vector $u$ (of appropriate dimensions), and compute the matrix-vector multiplication $Bu$

(d)  Compute the product $(Bu)^T(Bu)$. What does this quantity represent? 
"

# ╔═╡ 78551271-91d4-4afa-ae9e-78c77c34b600
md"
## Solutions to Problem 2

Please include as many cells below as needed to provide your solutions to this problem.
"

# ╔═╡ 310e32b4-17ee-4da5-8a61-d16a05eb517d
# Example: Solutions to part (a) go here
B = rand(5,7)

# ╔═╡ 0a0e1851-05e5-4718-9298-760f44191c20
# Example: Solutions to part (b) go here
B2 = B[2:4, 3:5]

# ╔═╡ b362b56c-c587-43a7-98a4-cbf5a054d570
# Example: Solutions to part (c) go here
begin
	u = rand(3)
	Bu = B2 * u
end

# ╔═╡ 1bed1823-28c7-40f9-80a6-799bdf671742
md"
This is the dot product of the vector Bu. The resulting scalar is the sum of the squares of all the values in the vector Bu.
"

# ╔═╡ a917a00a-1b88-4d21-8e3b-acc339bf3f94
md"
# Problem 3 (30 points)

(a) Define the matrix $A$ and vector $b$ below, and find the solution to the system of linear equations $Ax = b$  

$
A = \begin{bmatrix}
5 & 6 & 7 \\
2 & 3 & 5 \\
3 & 2 & 9
\end{bmatrix}, \quad b = \begin{bmatrix}
-1 \\
0  \\
9
\end{bmatrix}$


(b) Define the matrix $D$ and vector $e$ below, and find the solution to the system of linear equations $Dx = e$  

$
D = \begin{bmatrix}
1 & 2 \\
2 & -3 \\
3 & 2 
\end{bmatrix}, \quad e = \begin{bmatrix}
4 \\
1  \\
8
\end{bmatrix}$

Verify your solution.

(c) Solve part (a) using the $LU$ factorization of $A$.
"

# ╔═╡ 45d64003-7a99-489e-9db7-2fa14bb924dc
md"
## Solutions to Problem 3

Please include as many cells below as needed to provide your solutions to this problem.
"

# ╔═╡ 3190547f-e358-4c9b-8a29-320d354e6ab1
# Example: Solutions to part (a) go here
begin
	A2 = [5 6 7;2 3 5;3 2 9]
    b2 = [-1,0,9]
	x1= A2 \ b2
end

# ╔═╡ 2c53b0e1-d761-4e4e-8412-a5a39a75e9fb
# Example: Solutions to part (c) go here
begin
	using LinearAlgebra
	F = lu(A2)
	x3 = F\b2
end

# ╔═╡ 7cdb5949-b0b6-448b-9e69-cf035930af27
# ╠═╡ skip_as_script = true
#=╠═╡
# Example: Solutions to part (d) go here
y = A * transpose(A)
  ╠═╡ =#

# ╔═╡ 70a0319f-3091-4217-8383-2bdc7b21874b
# Example: Solutions to part (d) go here
y2 = transpose(Bu) * Bu

# ╔═╡ dc7e0b04-0e7c-4ac6-b897-494008a6e02e
(A2 * x1)

# ╔═╡ 90a030ac-a388-4d4a-851e-09b74a02874e
md"
You can verify the solution by multiply A by x, the resulting vector should be b.
"

# ╔═╡ 033673f7-e2a2-4dd4-adc0-ded01d720251
# Example: Solutions to part (b) go here
begin
	D = [1 2;2 -3;3 2]
	e = [4,1,8]
	x2= D \ e
end

# ╔═╡ 76b55284-5c21-4173-a5f3-653b6c717686
D * x2

# ╔═╡ 1374f0fa-b40b-46c2-8bd9-5da45ca98145
md"
You can verify the solution by multiply D by x, the resulting vector should be e.
"

# ╔═╡ f22b089a-4c77-465b-aeb9-243b54f50554
md"
# Problem 4 (20 points)

(a) Consider the 2D rotation matrix below:

$
R = \begin{bmatrix}
\cos \theta & -\sin \theta \\  
\sin \theta & \cos \theta 
\end{bmatrix}$

Define a value of $\theta$ and a sample vector $w$. Compute $Rw$. 



(b) How can you confirm that the result obtained in part (a) is correct? 
"

# ╔═╡ 5c14b6ea-e93e-4a1a-9d6a-21bfb66dbbd9
md"
## Solutions to Problem 4

Please include as many cells below as needed to provide your solutions to this problem.
"

# ╔═╡ 2913e0b9-a33a-4a49-90a4-0aa63d8a8455
# Example: Solutions to part (a) go here
begin
	theta = pi / 8
	R = [cos(theta) -sin(theta); sin(theta) cos(theta)]
	w = [1.0;0.0]
	h = R*w
end	

# ╔═╡ 6376a593-d752-4143-8abb-c67a8e067eab
# Example: Solutions to part (b) start here
begin
	norm(h)
	norm(w)
	
	println("Magnitude of h: ", norm(h), "\nMagnitude of w: ", norm(w))
end

# ╔═╡ 277f5c46-bf76-4a2d-bca9-eb7e73565034
begin
	cost = cos(theta)
	wh = dot(w,h)
	normwh = norm(w)* norm(h)

	println("Cosine of theta: ", cost, "\nDot product of vectors divided by the product of magnitudes: ", wh/normwh)
end

# ╔═╡ e3926f4f-ee74-45d3-b3c0-50691072bfe7
md"
We can check the length of both vectors and they are the same since rotating a vector does not change the length.

We also know that the dot product of two vectors always equals the product of their magnitudes multiplied by the cosine of the theta they are rotated by.

"

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.3"
manifest_format = "2.0"
project_hash = "ac1187e548c6ab173ac57d4e72da1620216bce54"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+1"
"""

# ╔═╡ Cell order:
# ╟─c674e9dc-0bbb-11ef-0719-d5b7ce34a3a8
# ╟─9b8d9fc8-6658-4c68-9279-2bc3cd61b05c
# ╟─3418db22-454b-4cb7-8d79-4e70296ee2e7
# ╟─bb6454b4-71ce-4367-8834-183915283970
# ╠═d98d3264-6c05-4f68-a028-87031da3b5c8
# ╠═a5bfd95f-c382-4f2c-8e83-1f5b57e1d9b9
# ╠═71600ebd-9fc0-467e-8921-c2cd8ffb6eb3
# ╠═7cdb5949-b0b6-448b-9e69-cf035930af27
# ╟─ea972acb-81f9-4578-bb10-30a0730b08dd
# ╟─e1d5bd80-1eeb-47a6-9a24-7b68c44df97b
# ╟─78551271-91d4-4afa-ae9e-78c77c34b600
# ╠═310e32b4-17ee-4da5-8a61-d16a05eb517d
# ╠═0a0e1851-05e5-4718-9298-760f44191c20
# ╠═b362b56c-c587-43a7-98a4-cbf5a054d570
# ╠═70a0319f-3091-4217-8383-2bdc7b21874b
# ╟─1bed1823-28c7-40f9-80a6-799bdf671742
# ╟─a917a00a-1b88-4d21-8e3b-acc339bf3f94
# ╟─45d64003-7a99-489e-9db7-2fa14bb924dc
# ╠═3190547f-e358-4c9b-8a29-320d354e6ab1
# ╠═dc7e0b04-0e7c-4ac6-b897-494008a6e02e
# ╟─90a030ac-a388-4d4a-851e-09b74a02874e
# ╠═033673f7-e2a2-4dd4-adc0-ded01d720251
# ╠═76b55284-5c21-4173-a5f3-653b6c717686
# ╟─1374f0fa-b40b-46c2-8bd9-5da45ca98145
# ╠═2c53b0e1-d761-4e4e-8412-a5a39a75e9fb
# ╟─f22b089a-4c77-465b-aeb9-243b54f50554
# ╟─5c14b6ea-e93e-4a1a-9d6a-21bfb66dbbd9
# ╠═2913e0b9-a33a-4a49-90a4-0aa63d8a8455
# ╠═6376a593-d752-4143-8abb-c67a8e067eab
# ╠═277f5c46-bf76-4a2d-bca9-eb7e73565034
# ╟─e3926f4f-ee74-45d3-b3c0-50691072bfe7
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
