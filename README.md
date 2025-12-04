# vanilla.prm

**A Simplified Framework for Learning Probabilistic Relational Models in R**

[![License](https://img.shields.io/badge/license-R-blue.svg)](LICENSE)

An R package that implements a novel method for learning Probabilistic Relational Models (PRMs) from relational data, as described in:

> Mormille, L. H., & Cozman, F. G. (2017). *Learning Probabilistic Relational Models: A Simplified Framework, a Case Study, and a Package*. Proceedings of KDMILE 2017, Uberlândia, MG, Brazil.

## Overview

While most statistical learning methods work with data stored in a single table, many large datasets are stored in relational database systems with multiple interconnected tables. **vanilla.prm** bridges this gap by extending Bayesian Networks to handle relational data through Probabilistic Relational Models.

### What are Probabilistic Relational Models?

Probabilistic Relational Models (PRMs) extend Bayesian Networks by introducing:
- **Objects and their properties** (entities in different classes)
- **Relations between objects** (foreign key relationships)
- **Probabilistic dependencies** across related objects

This allows a property of an object to depend probabilistically not only on its own properties, but also on properties of other related objects across different tables.

### The Challenge

Learning a PRM from relational data is significantly more complex than learning a Bayesian Network from flat data. Three main difficulties arise:

1. **Legal Dependency Structures**: Ensuring all dependencies are acyclic
2. **Structure Scoring**: Evaluating and comparing possible legal structures
3. **Structure Search**: Navigating an exponentially large space of possible structures

### Our Solution

This package implements a **simplified framework** that restricts the space of possible structures in ways that make sense for practical problems:

1. **No cycles at class level**: Structures like X.A → Y.B → X.C are not allowed
2. **Main class focus**: Attributes of interest belong to a distinguished "main class"
3. **Restricted aggregations**: Only the main class receives edges from aggregation functions
4. **Data flattening**: Creates a "master table" with pre-computed aggregations, enabling the use of standard Bayesian network learning algorithms

This approach makes PRM learning tractable while maintaining model expressiveness for real-world applications.

## Features

- **Automatic relational schema detection** and skeleton generation
- **Smart aggregation** of attributes across related classes using mode function
- **Blacklist generation** to enforce PRM structural constraints
- **Integration with bnlearn** for structure and parameter learning
- **Support for multiple search methods**: Hill Climbing, Tabu Search
- **Flexible scoring functions**: BIC, AIC, BDe, BDj, and more
- **Handles up to three classes** with categorical attributes

## Installation

### Prerequisites

The package requires the `bnlearn` package:

```r
install.packages("bnlearn")
library(bnlearn)
```

### Installing vanilla.prm

```r
# Install devtools if needed
install.packages("devtools")

# Install from GitHub
devtools::install_github("mormille/vanilla.prm")

# Load the package
library(vanilla.prm)
```

## Quick Start

```r
library(bnlearn)
library(vanilla.prm)

# 1. Load your relational data (CSV format recommended)
main_class <- read.csv("table1.csv", sep = ";")
class2 <- read.csv("table2.csv", sep = ";")
class3 <- read.csv("table3.csv", sep = ";")

# 2. Define keys and foreign keys
key.names <- c("key1", "key2", "key3")

# 3. Create the master table with automatic aggregations
master_table <- relational.skeleton(main_class, class2, class3, key.names)

# 4. Learn the PRM structure
dag <- structure.learn(master_table, key.names, main_class, class2, class3)

# 5. Learn parameters
fit <- parameter.learn(dag, master_table)

# 6. Perform inference using bnlearn functions
# Example: query conditional probability
cpquery(fit, event = (target_variable == "A"), evidence = (predictor == "X"))
```

## The Method in Detail

### 1. Relational Schema and Skeleton

The package first analyzes your relational data to identify:
- **Classes**: Distinct tables in your database (e.g., Person, Company, Census_Sector)
- **Attributes**: Variables within each class (probabilistic or fixed)
- **Relations**: How objects are connected through foreign keys (1-to-1, 1-to-N, N-to-1, N-to-N)

### 2. Master Table Construction

Given a **main class** (the class containing your target variable), the package:
1. Starts with a copy of the main class table
2. For each object in the main class, aggregates attributes from related objects in other classes
3. Uses the **mode** (most frequent value) as the aggregation function for many-to-many relationships
4. Directly transfers values for single-valued relationships (1-to-1 or N-to-1 from main class perspective)

### 3. Structure Learning with Constraints

The package generates a **blacklist** of forbidden edges that enforces:
- No arrows from main class attributes to other classes
- No arrows between attributes of different non-main classes
- No arrows between aggregated attributes within the same non-main class

This ensures the learned structure is isomorphic to a legal PRM while allowing standard Bayesian network algorithms to be applied.

### 4. Parameter Learning

Once the structure is learned, conditional probability distributions (CPDs) are estimated from the master table using maximum likelihood or Bayesian parameter estimation.

## Data Requirements

### Format
- **CSV format recommended** (or any format convertible to R data frames)
- **Categorical attributes only** (all variables must be factors)
- **Consistent key naming**: Foreign keys must have identical names across all tables

### Structure
- **Main class**: The table containing your target variable(s) for prediction/inference
- **Related classes**: Up to 2 additional tables (3 classes total)
- **Foreign keys**: Must be present in relevant tables to establish relationships

### Example Data Structure

**table1.csv (Main Class - Person)**
```csv
key1,att1,att2,key2
1,A,A,21
2,B,B,22
3,A,A,22
...
```

**table2.csv (Related Class - Company)**
```csv
key2,att3,att4,key3
21,C,C,1
22,D,C,1
23,D,D,2
...
```

**table3.csv (Related Class - Census_Sector)**
```csv
key3,att5,att6
1,E,G
2,E,H
3,F,H
...
```

## Function Reference

### `relational.skeleton(main.class, class2, class3, key.names)`

Creates the master table by performing automatic aggregations based on the relational structure.

**Arguments:**
- `main.class`: Data frame for the main class (contains target variable)
- `class2`: Data frame for the second class (optional)
- `class3`: Data frame for the third class (optional)
- `key.names`: Character vector with names of all keys and foreign keys

**Returns:** Master table (data frame) with aggregated attributes

**Details:**
- Analyzes cardinality of relationships between classes
- Performs mode aggregation for many-to-many relationships
- Directly transfers values for single-valued relationships
- Prints the relational skeleton showing detected relationships

---

### `structure.learn(master_table, key.names, main.class, class2, class3, search_method, score_function)`

Learns the PRM structure by applying Bayesian network learning with PRM-specific constraints.

**Arguments:**
- `master_table`: Master table from `relational.skeleton()`
- `key.names`: Character vector with key names
- `main.class`, `class2`, `class3`: Original data frames
- `search_method`: Search algorithm for structure learning
  - `'hc'`: Hill Climbing (default)
  - `'tabu'`: Tabu Search
- `score_function`: Scoring function for structure quality
  - `'bic'`: Bayesian Information Criterion (default, recommended)
  - `'aic'`: Akaike Information Criterion
  - `'loglik'`: Multinomial log-likelihood
  - `'bde'`: Bayesian Dirichlet equivalent
  - `'bds'`: Sparse Dirichlet
  - `'bdj'`: Dirichlet with Jeffrey's prior
  - `'bdla'`: Locally averaged BDe
  - `'k2'`: K2 score

**Returns:** A `bn` object (directed acyclic graph) representing the PRM structure

**Details:**
- Automatically generates blacklist to enforce PRM constraints
- Learns partial structures from different class perspectives
- Combines them into a unified PRM structure
- Plots the resulting network

---

### `parameter.learn(net, master_table, mt_class2, mt_class3)`

Fits conditional probability distributions to the learned structure.

**Arguments:**
- `net`: PRM structure (DAG) from `structure.learn()`
- `master_table`: Master table for main class
- `mt_class2`: Master table for class 2 (optional, for advanced use)
- `mt_class3`: Master table for class 3 (optional, for advanced use)

**Returns:** A `bn.fit` object with fitted parameters, ready for inference

**Details:**
- Uses maximum likelihood estimation
- Handles attributes with single observed level by adding a "Ghost" level
- Returns object compatible with bnlearn inference functions

## Case Study: Predicting Social Class in Atibaia

The package was developed and validated on a real large-scale problem: predicting the social class of citizens in Atibaia, a small town in São Paulo, Brazil.

### Domain Description

- **Person class**: 110,816 citizens with 10 attributes (target: Social_class ∈ {A, B, C, D})
- **Company class**: 20,162 businesses with 6 attributes
- **Census_Sector class**: 327 territorial units with 5 attributes

### Relational Structure

- Each person lives in one census sector
- Each company is located in one census sector
- Each census sector contains multiple people and companies

### Results

The PRM learned using vanilla.prm **outperformed a Bayesian Network** learned from Person class attributes alone, achieving:
- **12% lower misclassification rate** on average
- Better utilization of inter-class relationships
- More informative predictions using company and location data

This demonstrates the value of exploiting relational structure for predictive modeling.

## Workflow Example: Classification Task

```r
# Load and prepare data
person <- read.csv("person_data.csv", sep = ";")
company <- read.csv("company_data.csv", sep = ";")
location <- read.csv("location_data.csv", sep = ";")

# Ensure all variables are categorical
person[] <- lapply(person, as.factor)
company[] <- lapply(company, as.factor)
location[] <- lapply(location, as.factor)

# Define keys
keys <- c("person_id", "sector_id", "company_id")

# Build master table
master <- relational.skeleton(person, company, location, keys)

# Split into training and validation sets
set.seed(42)
train_idx <- sample(1:nrow(master), 0.7 * nrow(master))
train_data <- master[train_idx, ]
test_data <- master[-train_idx, ]

# Learn structure on training data
dag <- structure.learn(train_data, keys, 
                       person[train_idx, ], 
                       company, location,
                       search_method = 'hc',
                       score_function = 'bdj')

# Learn parameters
model <- parameter.learn(dag, train_data)

# Make predictions on test set
predictions <- predict(model, node = "target_variable", data = test_data)

# Evaluate accuracy
accuracy <- sum(predictions == test_data$target_variable) / nrow(test_data)
cat("Accuracy:", round(accuracy * 100, 2), "%\n")
```

## Advanced Usage

### Using bnlearn for Inference

Once you have a fitted model, use bnlearn's inference functions:

```r
# Conditional probability queries
cpquery(fit, event = (Social_class == "A"), 
        evidence = (Age_range == "25-35" & House_type == "apartment"))

# Most probable explanation
mpd <- predict(fit, node = "Social_class", data = evidence_data, method = "bayes-lw")

# Sensitivity analysis
sensitivity <- ci.test("Social_class", "Company_age", "Average_income", data = master)
```

### Custom Structure Elicitation

You can also manually specify structures based on domain knowledge, as long as forbidden edges are avoided:

```r
# Create custom structure
custom_dag <- empty.graph(names(master))
arcs(custom_dag) <- matrix(c("att1", "target",
                              "att2", "target",
                              "att3", "att1"), 
                           ncol = 2, byrow = TRUE)

# Fit parameters to custom structure
custom_fit <- parameter.learn(custom_dag, master)
```

## Theoretical Background

### PRM Fundamentals

A PRM consists of:
1. **Dependency Structure S**: Defines parent-child relationships between attributes
2. **Conditional Probability Distributions θ_S**: Specifies P(X.A | Pa(X.A)) for each attribute

### Slot Chains and Aggregation

When an object `x` relates to a set of objects `{y₁, ..., yᵢ}` through a slot chain `τ`, attribute `x.A` can depend on `X.τ.B` using an aggregation function `γ`:

```
Pa(x.A) = γ(X.τ.B)
```

Common aggregation functions:
- **mode**: Most frequent value (categorical)
- **mean**: Average (continuous)
- **median/max/min**: Ordered attributes
- **cardinality**: Count of related objects

### Joint Distribution

The joint distribution factorizes as:

```
P(I|σ, S, θ_S) = ∏∏ P(I_{x.A} | I_{Pa(x.A)})
                 x A∈A(x)
```

where `I` is an instance, `σ` is the relational skeleton, `S` is the structure, and `θ_S` are the parameters.

## Limitations

This is version **0.1.0** with the following constraints:

1. **Maximum 3 classes**: Current implementation supports up to three related tables
2. **Categorical attributes only**: Continuous variables must be discretized beforehand
3. **Mode aggregation only**: Other aggregation functions not yet supported
4. **Main class restriction**: Target variables must be in a single "main" class
5. **No cycles at class level**: Inter-class dependencies form a directed acyclic graph

These limitations enable efficient learning while covering many practical scenarios.

## Future Development

Planned enhancements include:

- Support for more than 3 classes
- Continuous and mixed-type attributes
- Multiple aggregation functions (mean, median, custom)
- More flexible relational schemas
- Improved handling of missing data
- Cross-validation utilities
- Model comparison tools
- Parallel processing for large datasets

## Citation

If you use this package in your research, please cite:

```bibtex
@inproceedings{mormille2017learning,
  title={Learning Probabilistic Relational Models: A Simplified Framework, a Case Study, and a Package},
  author={Mormille, L. H. and Cozman, F. G.},
  booktitle={Proceedings of the 5th Symposium on Knowledge Discovery, Mining and Learning (KDMILE)},
  pages={129--136},
  year={2017},
  address={Uberlândia, MG, Brazil}
}
```

## Authors

**Luiz H. Mormille** – [luiz.mormille@usp.br](mailto:luiz.mormille@usp.br)  
**Fabio G. Cozman** – [fgcozman@usp.br](mailto:fgcozman@usp.br)

Universidade de São Paulo, Brazil

## Acknowledgments

- **Serasa Experian**: For providing the data used in the case study (Latam Experian Datalab and Marketing Services department)
- **Prof. Renato Vicente** (Instituto de Matemática e Estatística, USP)
- **Glauber de Bona** (Escola Politécnica, USP)
- **Marco Scutari**: For the excellent `bnlearn` package

## License

This package is released under the R license.

## References

### Key Papers on PRMs

1. Koller, D. (1999). *Probabilistic relational models*. In International Conference on Inductive Logic Programming (pp. 3-13). Springer.

2. Friedman, N., Getoor, L., Koller, D., & Pfeffer, A. (1999). *Learning probabilistic relational models*. In IJCAI (Vol. 99, pp. 1300-1309).

3. Getoor, L., & Taskar, B. (2007). *Introduction to statistical relational learning*. MIT press.

4. Koller, D., & Friedman, N. (2009). *Probabilistic graphical models: principles and techniques*. MIT press.

### Multi-Relational Data Mining

5. Džeroski, S. (2003). *Multi-relational data mining: an introduction*. ACM SIGKDD Explorations Newsletter, 5(1), 1-16.

### Structure Learning

6. Liu, Z., Malone, B., & Yuan, C. (2012). *Empirical evaluation of scoring functions for Bayesian network model selection*. BMC bioinformatics, 13(15), S14.

## Support

For bug reports, feature requests, or questions:
- Open an issue on [GitHub](https://github.com/mormille/vanilla.prm)
- Contact the authors via email

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for discussion.

---

**vanilla.prm** – Making relational probabilistic modeling accessible in R
