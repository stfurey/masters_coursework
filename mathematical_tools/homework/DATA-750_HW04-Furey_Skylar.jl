### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ fbfa9f28-8a9a-4056-82cb-515c97fbd503
md"
# DATA-750: HW 04 Eigenvalues and Singular Values

## Skylar Furey
### Email: `stfurey@unc.edu`
"

# ╔═╡ a5a0c576-625e-4a81-825b-8887c849c5b1
md"
## Problem 1 (25 points) 

Find the singular value decomposition of the following $5 \times 5$ matrix $A$:

$
A = 
\begin{bmatrix}
-5 & 7 & 3 & 4 & -8 \\
5 & 8 & 3 & 6 & 8 \\
3 & -7 & -3 & -4 & 5 \\
-3 & 0 & 4 & 5 & 3 \\
7 & 4 & 5 & 9 & 5 \\
\end{bmatrix}$


- Show that $A$ is not symmetric.

- Find the singular value decomposition of $A$ by forming $A^TA$ and computing its eigenvalue decomposition.

- Show that the ratio of the largest to the smallest singular value matches the condition number of $A$.


"


# ╔═╡ fa9025f2-2956-4ba7-a177-437a2733d00a
md"
## Solutions to Problem 1
"

# ╔═╡ bbc61ac9-9cc2-4f6f-bab4-413295ec2591
begin
	A = [-5 7 3 4 -8; 5 8 3 6 8; 3 -7 -3 -4 5; -3 0 4 5 3; 7 4 5 9 5]
	At = transpose(A)
end

# ╔═╡ 793fa905-b03a-4dc1-9eb0-09eccdf2f66a
begin
	using LinearAlgebra
	
	eigVals, eigVecs = eigen(At * A)
end

# ╔═╡ 151fe259-aef9-474d-a4c0-a36f80d3e06f
A == At

# ╔═╡ f2d42707-d0b5-40a9-9640-540a70560644
md"
Comments:
A doesn't equal it's transpose and is therefore not symmetric.
"

# ╔═╡ 8f31b917-cffb-4b59-b3f2-cb6ed9d4ae72
begin
	singularVals = sqrt.(eigVals)
	isapprox.(cond(A), maximum(singularVals) / minimum(singularVals))
end

# ╔═╡ 7b74b491-67b9-4d08-918b-6baaae441104
md"
## Problem 2 (25 points)

Go to page 125 of the textbook [\"Mathematics for Machine Learning\"](https://mml-book.github.io/book/mml-book.pdf), and recreate the SVD factorization of the matrix in Example 4.13 using tools from Julia. That is: 

- Find the **SVD factorization** of the matrix: 

$
A = \begin{bmatrix}
1 & 0 & 1\\
-2 & 1 & 0
\end{bmatrix}$

- Do you get the same **singular values**? 

- What about the entries of the matrices of right and left singular values? Do you get the same entries? Explain your results.
"

# ╔═╡ d7ee859b-bf0a-46ca-aba0-c890233f9b5e
md"
## Solutions to Problem 2
"

# ╔═╡ 81c0d02d-07d0-4d43-98be-f08be471498b
begin
	A2 = [1 0 1;-2 1 0]
	svd(A2)
	# 
end

# ╔═╡ c9f199cf-0c71-43b5-8e8a-4cee2f55fc5a
md"
Comments:
I got the same singular values of 1 and sqrt(6). But I didn't get the same right or left singular values, in the textbook the right singular values matrix isn't even the same shape (3x3 vs 2x3).
"

# ╔═╡ f51aa32f-08bd-4277-a605-fd1791b527fc
md"
## Problem 3 (25 points): 

Consider the matrix: 

$
B = 
\begin{bmatrix}
4 & -3 & -2 & -1 \\
-2 & 4 & -2 & -1 \\
-1 & -2 & 4 & -1 \\
-1 & -2 & -1 & 4 \\
\end{bmatrix}$

- Use `eigvals()` to find the **eigenvalues** of the matrix $B$.

- For each eigenvalue, use `rank()` to verify that $\lambda I$ minus the given matrix is **singular**. Comments on your results.
"

# ╔═╡ 17bf2373-3a5f-47be-9d89-626a51682623
md"
## Solutions to Problem 3
"

# ╔═╡ e92aa67e-12af-4c40-bbc7-224d5290080d
begin
	B = [4 -3 -2 -1; -2 4 -2 -1; -1 -2 4 -1; -1 -2 -1 4]
	eigVals2 = eigvals(B)
end

# ╔═╡ 3773755b-b166-4e83-b9b7-5b664c02008a
for i in eigVals2
	value = i * I - B
	valRank = rank(value)
	singular = valRank < rank(B)
	println(singular)
end

# ╔═╡ c46345a5-c178-46cc-b7fe-73b9ce54c9f3
md"
Comments:
Since the ranks of the eigenvalues*I - B were all less then the rank of B then the matrix B must be singular.
"

# ╔═╡ 8b675580-2570-4e5e-91af-4d8934fa0eb5
md"
## Problem 4 (25 points)

A [Hilbert matrix](https://en.wikipedia.org/wiki/Hilbert_matrix), introduced by Hilbert (1894), is a square matrix with entries being the unit fractions

$H_{ij}={\frac {1}{i+j-1}}$

- Create a function to compute a general Hilbert matrix of size $n$. Test your function by building matrices of size $k \times k$ with $k = 4, 8, 10, 16.$


- Build a Hilbert matrix of size 7, and call it `hil_seven`. 

- Select columns 1 through 4, and call it `X`

- Compute the **singular value decomposition** of `X`.

- Print the singular values of `X`

- Verify that the product $U^T U$ where $U$ is the matrix of left singular values, returns the _identity matrix_ (a square matrix with ones in the main diagonal, and zeros everywhere else). 

"

# ╔═╡ dc4e60a1-a8a1-4e94-bb5e-181a3cca26f0
md"
## Solutions to Problem 4
"

# ╔═╡ 850c52c8-f631-4d60-b277-f8e01e108425
function hilbertMatrix(k)
    H = zeros(Float64, k, k)
    for i in 1:k
        for j in 1:k
            H[i, j] = 1 / (i + j - 1)
        end
    end
    return H
end

# ╔═╡ 532ac6d9-828a-4159-882a-bd11c864ed5b
begin
	# hilbertMatrix(4)
	hilbertMatrix(8)
	# hilbertMatrix(10)
	# hilbertMatrix(16)
end

# ╔═╡ 819e56cf-8bd6-483b-9f71-d2aff7c91945
begin
	hillSeven = hilbertMatrix(7)
	X = hillSeven[:,1:4]
	print(svd(X).S)
end

# ╔═╡ 5bb91b66-c209-4fc6-8d15-98c00a0c2f15
round.(transpose(svd(X).U) * svd(X).U)

# ╔═╡ c84d72d5-08d2-4396-abc1-e77091f484eb
md"
Comments:
Pretty cool that this works for all hilbert matrices and any subset of the columns of any of the matrices as well!
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
# ╟─fbfa9f28-8a9a-4056-82cb-515c97fbd503
# ╟─a5a0c576-625e-4a81-825b-8887c849c5b1
# ╟─fa9025f2-2956-4ba7-a177-437a2733d00a
# ╠═bbc61ac9-9cc2-4f6f-bab4-413295ec2591
# ╠═151fe259-aef9-474d-a4c0-a36f80d3e06f
# ╟─f2d42707-d0b5-40a9-9640-540a70560644
# ╠═793fa905-b03a-4dc1-9eb0-09eccdf2f66a
# ╠═8f31b917-cffb-4b59-b3f2-cb6ed9d4ae72
# ╟─7b74b491-67b9-4d08-918b-6baaae441104
# ╟─d7ee859b-bf0a-46ca-aba0-c890233f9b5e
# ╠═81c0d02d-07d0-4d43-98be-f08be471498b
# ╟─c9f199cf-0c71-43b5-8e8a-4cee2f55fc5a
# ╟─f51aa32f-08bd-4277-a605-fd1791b527fc
# ╟─17bf2373-3a5f-47be-9d89-626a51682623
# ╠═e92aa67e-12af-4c40-bbc7-224d5290080d
# ╠═3773755b-b166-4e83-b9b7-5b664c02008a
# ╟─c46345a5-c178-46cc-b7fe-73b9ce54c9f3
# ╟─8b675580-2570-4e5e-91af-4d8934fa0eb5
# ╟─dc4e60a1-a8a1-4e94-bb5e-181a3cca26f0
# ╠═850c52c8-f631-4d60-b277-f8e01e108425
# ╠═532ac6d9-828a-4159-882a-bd11c864ed5b
# ╠═819e56cf-8bd6-483b-9f71-d2aff7c91945
# ╠═5bb91b66-c209-4fc6-8d15-98c00a0c2f15
# ╟─c84d72d5-08d2-4396-abc1-e77091f484eb
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
