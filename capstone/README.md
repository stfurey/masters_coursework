Note: Due to the nature of this project, the main repository is currently private. Once it becomes public, this README will be updated with a link to access it.

# NetApp Image Metadata Generation

## About This Project

This repository contains the work and documentation related to our final capstone project for the UNC Master's of Applied Data Science (MADS) program. The capstone serves as a culminating experience, allowing us to apply the skills and knowledge we've gained throughout the program to a real-world data science problem.

## Collaborators

- Joseph Bevilacqua
- Skylar Furey
- Matthew Ray
- Richard Marks (Instructor)
- Grant Glass (NetApp Stakeholder)
- Noah Hardy (NetApp Stakeholder)

## Problem Statement

NetApp’s search engine struggles to accurately retrieve relevant documents from short user queries (1–4 words) due to high semantic similarity across document content. Additionally, it cannot extract or leverage valuable information embedded in images, leading to reduced retrieval accuracy.
 
## Approach

1. Extract images and surrounding context form NetApp documents
2. Generate extensive contextual metadata across five key facets
3. Embed metadata to separate semantically similar documents

![Process Document](docs/Process_Documentation.jpg)
![Lineage Graph](docs/Lineage%20Gif.gif)

## Pipeline

### Preprocessing

This step extracts documentation and image data from the NetApp GitHub repository and creates a structured matrix of image/document pairings for downstream processing.

#### `api_to_media.py`
**Purpose**: Extract image files and associated document content from the [NetApp GitHub repository](https://github.com/NetAppDocs/netapp-solutions) using the GitHub API.  

**Inputs**:  
- NetApp GitHub repository (via API)  

**Outputs**:  
- `netapp_repo_non_png.parquet` 
- `png_base64_content.parquet`
- `transactional_media.parquet`

#### `media_integrated_with_adoc.py`
**Purpose**: Generate a matrix aligning each image with its surrounding document content.  

**Inputs**:  
- `transactional_media.parquet`  
- `netapp_repo_non_png.parquet`  

**Outputs**:  
- `doc_to_png_matrix.parquet`
- `media_with_adoc.parquet`

### Facet Grids Generation

This step generates five facet grids — **Alias**, **Context**, **Keyword**, **Retrieval**, and **Semantic** — for each image/document pair using outputs from **GPT-4.1** and **Gemini 2.0 Flash** models. It is part of a larger pipeline to enrich document metadata for multimodal retrieval.

**Shared Inputs**:  
- GPT-4.1 Model  
- Gemini 2.0 Flash Model  
- `transactional_media.parquet`  
- `doc_to_png_matrix.parquet`  

#### `media_ocr_pipe_alias_grid.py`
**Purpose**: Generate the alias grid.  
**Output**: `llm_transformation_alias_grid.parquet`

#### `media_ocr_pipe_context_grid.py`
**Purpose**: Generate the context grid.  
**Output**: `llm_transformation_context_grid.parquet`

#### `media_ocr_pipe_keyword_grid.py`
**Purpose**: Generate the keyword grid.  
**Output**: `llm_transformation_key_word_grid.parquet`

#### `media_ocr_pipe_retrieval_grid.py`
**Purpose**: Generate the retrieval grid.  
**Output**: `llm_transformation_retrieval_grid.parquet`

#### `media_ocr_pipe_semantic_grid.py`
**Purpose**: Generate the semantic grid.  
**Output**: `llm_transformation_semantic_grid.parquet`

### Embedding Generation

This step embeds the five facet grids — **Alias**, **Context**, **Keyword**, **Retrieval**, and **Semantic** — for each image/document pair using **Qwen3 embedding models** (0.6B and 4B parameters). It also embeds a set of sample short-form user queries. Finally, all facet embeddings are merged into a single combined dataset for each image/document pair.

#### `combine_grids_small_model.py`
**Purpose**: Embed all facet grids using the **Qwen3 0.6B** embedding model and combine the outputs into a single dataset.  

**Inputs**:  
- `llm_transformation_alias_grid.parquet`  
- `llm_transformation_context_grid.parquet`  
- `llm_transformation_key_word_grid.parquet`  
- `llm_transformation_retrieval_grid.parquet`  
- `llm_transformation_semantic_grid.parquet`  
- `Qwen3-Embedding-0.6B` model  

**Output**:  
- `embeddings_qwen3_0p6b.parquet`

#### `combine_grids_medium_model.py`
**Purpose**: Embed all facet grids using the **Qwen3 4B** embedding model and combine the outputs into a single dataset.  

**Inputs**:  
- `llm_transformation_alias_grid.parquet`  
- `llm_transformation_context_grid.parquet`  
- `llm_transformation_key_word_grid.parquet`  
- `llm_transformation_retrieval_grid.parquet`  
- `llm_transformation_semantic_grid.parquet`  
- `Qwen3-Embedding-4B` model  

**Output**:  
- `embeddings_qwen3_4b.parquet`

#### `join_combined_grids.py`
**Purpose**: Embed sample user questions using both Qwen3 models and combine the facet embeddings from each model.  

**Inputs**:  
- `embeddings_qwen3_0p6b.parquet`  
- `embeddings_qwen3_4b.parquet`  
- `questions.py` (sample query list)  
- `Qwen3-Embedding-0.6B` model  
- `Qwen3-Embedding-4B` model  

**Outputs**:  
- `combined_embeddings.parquet`  
- `question_embeddings.parquet`

### Visualization

This step generates **t-SNE visualizations** for the embeddings of each facet grid. Short-form query embeddings are overlaid on the plots to assess alignment and semantic grouping.

#### `embeddings_visualization.py`
**Purpose**: Visualize the embeddings of each grid and associated queries using t-SNE, grouped by model type and embedding dimensionality.

**Inputs**:  
- `combined_embeddings.parquet`  
- `question_embeddings.parquet`

**Output**:  
- `tsne_gridfacets_dim_*.png`
- `tsne_gridfacets_dim_*_model_*.png`
- `tsne_newimgcontext_dim_*_model_*.png`

### Deprecated

#### `media_ocr_reasoning_o3.py`
**Purpose**: Generate a list of possible user search queries using the OpenAI o3 model.

**Inputs**:  
- `llm_transformation_semantic_grid.parquet`  
- OpenAI o3 model
- `reasoning_output.parquet`

**Output**:  
- `prompt_v1_semantic_grid.parquet`

## Results

![Alt Text](t-SNE_visualizations/tsne_gridfacets_dim_512.png)

Each point in this plot represents an image-document pair. 334 images appeared in multiple documents, with one image found in 12 documents. Conversely, 254 documents contained multiple images—one document included as many as 93. In cases where documents had numerous images or minimal surrounding text, contextual overlap between images was more pronounced.
The t-SNE plots illustrate how each facet of metadata we generated provides a more effective separation of directories compared to the image context alone, which is currently used by NetApp’s search engine for document retrieval. Across each metadata facet, we observe:
- **Reduced overlap** between directories,
- **Greater semantic separation**, and
- **More distinct clustering** of image-document pairs.
This indicates that our approach yields more discriminative and unique contextual "signatures" for each pair, improving the potential for accurate and meaningful retrieval.

## Resources

- OpenAI. GPT-4.1. 2024. OpenAI, https://platform.openai.com/.
 
- Palantir Technologies. *Palantir Foundry*. Palantir Technologies, 2025. https://www.palantir.com/palantir-foundry/.
 
- Alibaba Cloud. *Qwen3-Embedding-0.6B Model*. Alibaba Cloud, 2024. https://github.com/QwenLM/Qwen.

- Alibaba Cloud. *Qwen3-Embedding-4B Model*. Alibaba Cloud, 2024. https://github.com/QwenLM/Qwen.

OpenAI Platform
Explore developer resources, tutorials, API docs, and dynamic examples to get the most out of OpenAI's platform.
 
