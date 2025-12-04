# vanilla.prm

An R package for constructing and learning Probabilistic Relational Models (PRMs) from relational data with up to three classes and categorical attributes.

## Overview

**vanilla.prm** provides a streamlined framework for building Probabilistic Relational Models (PRMs) in R. PRMs extend Bayesian Networks to relational domains, allowing probabilistic inference across multiple related classes. This package automates the construction of PRMs from relational data by:

1. Analyzing the relational schema and identifying relationships between classes
2. Performing automatic aggregation to create master tables
3. Learning the PRM structure using constraint-based approaches
4. Fitting parameters to the learned structure

## Features

- **Automatic Relational Schema Detection**: Identifies 1-to-1, 1-to-N, N-to-1, and N-to-N relationships between classes
- **Smart Aggregation**: Automatically aggregates data across classes using mode-based aggregation for many-to-many relationships
- **Structure Learning**: Leverages `bnlearn` package for Bayesian network structure learning with PRM-specific constraints
- **Multiple Search Methods**: Supports Hill Climbing and Tabu Search algorithms
- **Flexible Scoring Functions**: Compatible with various scoring metrics (BIC, AIC, BDe, etc.)
- **Multi-Class Support**: Handles up to three related classes in a single domain

## Installation

### Prerequisites

This package requires the `bnlearn` package:

```r
install.packages("bnlearn")
library("bnlearn")
```

### Installing vanilla.prm

```r
# From source
install.packages("path/to/vanilla.prm", repos = NULL, type = "source")

# Load the package
library(vanilla.prm)
```

## Usage

### Data Requirements

- Data should be in CSV format (or convertible to data frames)
- All classes must have **categorical attributes only**
- Foreign keys must have **consistent naming** across all tables
- It is recommended to use complete cases (rows with all variables observed)

### Basic Workflow

#### 1. Load Your Data

```r
# Import your relational tables
class1 <- read.csv("table1.csv", sep = ";")
class2 <- read.csv("table2.csv", sep = ";")
class3 <- read.csv("table3.csv", sep = ";")
```

#### 2. Define Foreign Keys

Create a vector containing all foreign key names:

```r
keys <- c("key1", "key2", "key3")
```

#### 3. Generate Relational Schema

The `relational.schema()` function analyzes relationships and creates master tables for each class:

```r
master_tables <- relational.schema(keys, class1, class2, class3)

# Access individual master tables
mt_mainclass <- master_tables$`Mt(lc)`  # Main class (leaf class)
mt_class2 <- master_tables$`Mt(c2)`      # Class 2
mt_class3 <- master_tables$`Mt(c3)`      # Class 3
```

**What it does:**
- Detects the cardinality of relationships (1-to-1, 1-to-N, N-to-1, N-to-N)
- Aggregates attributes from related classes
- Creates a master table for each class perspective
- Uses mode aggregation for many-to-many relationships

#### 4. Learn PRM Structure

The `structure.learn()` function learns the dependency structure:

```r
prm_structure <- structure.learn(
  mt_mainclass = mt_mainclass,
  mt_class2 = mt_class2,
  mt_class3 = mt_class3,
  keys = keys,
  class1 = class1,
  class2 = class2,
  class3 = class3,
  search_method = 'hc',      # 'hc' or 'tabu'
  score_function = 'bic'     # See scoring options below
)
```

**Parameters:**
- `mt_mainclass`, `mt_class2`, `mt_class3`: Master tables from `relational.schema()`
- `keys`: Vector of foreign key names
- `class1`, `class2`, `class3`: Original data tables
- `search_method`: Structure learning algorithm
  - `'hc'`: Hill Climbing (default)
  - `'tabu'`: Tabu Search
- `score_function`: Scoring metric for structure quality
  - `'bic'`: Bayesian Information Criterion (default)
  - `'aic'`: Akaike Information Criterion
  - `'loglik'`: Multinomial log-likelihood
  - `'bde'`: Bayesian Dirichlet equivalent
  - `'bds'`: Sparse Dirichlet posterior density
  - `'bdj'`: Dirichlet posterior (Jeffrey's prior)
  - `'bdla'`: Locally averaged BDe score
  - `'k2'`: K2 score

**What it does:**
- Creates blacklists to enforce PRM assumptions (no dependencies between attributes of different classes except through aggregation)
- Learns partial structures for each class perspective
- Combines them into a unified PRM structure
- Automatically plots the resulting network

#### 5. Learn Parameters

Fit the conditional probability tables to the learned structure:

```r
prm_model <- parameters.learn(
  net = prm_structure,
  mt_mainclass = mt_mainclass,
  mt_class2 = mt_class2,
  mt_class3 = mt_class3
)
```

**Returns:** A fitted Bayesian network model (bn.fit object) that can be used for probabilistic inference.

### Complete Example

```r
# Load dependencies
library(bnlearn)
library(vanilla.prm)

# Load data
class1 <- read.csv("table1.csv", sep = ";")
class2 <- read.csv("table2.csv", sep = ";")
class3 <- read.csv("table3.csv", sep = ";")

# Define keys
keys <- c("key1", "key2", "key3")

# Build relational schema
master_tables <- relational.schema(keys, class1, class2, class3)

# Learn structure
prm_structure <- structure.learn(
  mt_mainclass = master_tables$`Mt(lc)`,
  mt_class2 = master_tables$`Mt(c2)`,
  mt_class3 = master_tables$`Mt(c3)`,
  keys = keys,
  class1 = class1,
  class2 = class2,
  class3 = class3,
  search_method = 'hc',
  score_function = 'bic'
)

# Learn parameters
prm_model <- parameters.learn(
  net = prm_structure,
  mt_mainclass = master_tables$`Mt(lc)`,
  mt_class2 = master_tables$`Mt(c2)`,
  mt_class3 = master_tables$`Mt(c3)`
)

# Perform inference (using bnlearn functions)
# Example: Query probability of an attribute given evidence
library(bnlearn)
cpquery(prm_model, event = (att1 == "A"), evidence = (att3 == "C"))
```

## Data Format Example

The package includes sample data demonstrating the expected format:

**table1.csv** (Main Class):
```
key1,att1,att2,key2
1,A,A,21
2,B,B,22
3,A,A,22
...
```

**table2.csv** (Related Class):
```
key2,att3,att4,key3
21,C,C,1
22,D,C,1
23,D,D,2
...
```

**table3.csv** (Related Class):
```
key3,att5,att6
1,E,G
2,E,H
3,E,H
...
```

## Relational Schema Types

The package automatically detects and handles:

### 1-to-1 Relationships
- Each entity in Class A relates to exactly one entity in Class B
- Direct attribute transfer

### 1-to-N Relationships
- One entity in Class A relates to multiple entities in Class B
- Mode aggregation used for Class B attributes

### N-to-1 Relationships
- Multiple entities in Class A relate to one entity in Class B
- Direct attribute transfer from Class B

### N-to-N Relationships
- Multiple entities in both classes can be related
- Mode aggregation used for attribute values

## Implementation Details

### PRM Constraints

The structure learning enforces PRM-specific constraints through blacklists:

1. **No direct dependencies** between attributes of different classes
2. **No cycles** between attributes of the same class when aggregated
3. **Slot chains** are respected (dependencies flow through foreign key relationships)

### Handling Missing Values

- Only complete cases are used for structure and parameter learning
- Attributes with only one observed level gain a "Ghost" level to enable learning

### Aggregation Strategy

When multiple values exist for an attribute due to many-to-many relationships:
- **Mode aggregation** is applied (most frequent value is selected)
- This ensures deterministic aggregation while preserving the most common relationship

## Limitations

This is version 0.1.0 with the following limitations:

- **Maximum 3 classes**: The current implementation supports up to three related classes
- **Categorical attributes only**: Continuous variables are not supported
- **Star schema assumed**: Class 1 is treated as the main class with other classes aggregated toward it
- **Complete cases preferred**: Incomplete data may affect learning quality

## Future Development

Planned improvements include:

- Support for more than three classes
- Handling of continuous and mixed-type attributes
- Advanced aggregation functions (mean, median, custom)
- Support for more complex relational schemas
- Improved missing data handling
- Cross-validation and model evaluation tools

## Dependencies

- **R** >= 3.1.0
- **bnlearn**: For Bayesian network structure and parameter learning

## Author

**Luiz H. Mormille**  
Email: luiz.mormille@usp.br

## License

This package is released under the R license.

## References

For theoretical background on Probabilistic Relational Models:

1. Koller, D., & Pfeffer, A. (1998). Probabilistic frame-based systems. *AAAI/IAAI*, 1998, 580-587.
2. Getoor, L., Taskar, B., & Koller, D. (2001). Selectivity estimation using probabilistic models. *ACM SIGMOD Record*, 30(2), 461-472.
3. Friedman, N., Getoor, L., Koller, D., & Pfeffer, A. (1999). Learning probabilistic relational models. *IJCAI*, 99, 1300-1309.

## Citation

If you use this package in your research, please cite:

```
Mormille, L. H. (2024). vanilla.prm: Probabilistic Relational Models in R. 
R package version 0.1.0.
```

## Contributing

This package is under active development. Feedback, bug reports, and contributions are welcome!

## Acknowledgments

This package builds upon the excellent `bnlearn` package by Marco Scutari for Bayesian network learning and inference.
