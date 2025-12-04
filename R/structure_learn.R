#' Structure Learning for PRM
#'
#' Learns the structure of a Probabilistic Relational Model by applying
#' Bayesian network structure learning with PRM-specific constraints.
#'
#' @param mt_mainclass Master table for the main class
#' @param mt_class2 Master table for class 2
#' @param mt_class3 Master table for class 3
#' @param keys Character vector of key names
#' @param class1 Original data frame for main class
#' @param class2 Original data frame for class 2
#' @param class3 Original data frame for class 3
#' @param search_method Search algorithm: 'hc' (default) or 'tabu'
#' @param score_function Scoring function: 'bic' (default), 'aic', 'bdj', etc.
#'
#' @return A bn object (directed acyclic graph) representing the PRM structure
#' @export
#' @importFrom bnlearn hc tabu empty.graph arcs arcs<-
structure.learn <- function(mt_mainclass, mt_class2, mt_class3, 
                           keys, class1, class2, class3, 
                           search_method = 'hc', 
                           score_function = 'bic') {
  
  # Helper function to prepare master table
  prepare_master_table <- function(mt) {
    mt <- mt[complete.cases(mt), , drop = FALSE]
    
    # Add "Ghost" level to single-level factors
    for (col in colnames(mt)) {
      if (is.factor(mt[[col]]) && length(levels(mt[[col]])) == 1) {
        levels(mt[[col]]) <- c(levels(mt[[col]]), "Ghost")
      }
    }
    return(mt)
  }
  
  # Prepare all master tables
  mt_mainclass <- prepare_master_table(mt_mainclass)
  mt_class2 <- prepare_master_table(mt_class2)
  mt_class3 <- prepare_master_table(mt_class3)
  
  # Get column names for each class
  colsclass1 <- if (!is.null(class1) && nrow(class1) > 0) colnames(class1) else character(0)
  colsclass2 <- if (!is.null(class2) && nrow(class2) > 0) colnames(class2) else character(0)
  colsclass3 <- if (!is.null(class3) && nrow(class3) > 0) colnames(class3) else character(0)
  
  # Helper function to create blacklist efficiently
  create_blacklist <- function(from_cols, to_cols, keys) {
    from_non_keys <- setdiff(from_cols, keys)
    to_non_keys <- setdiff(to_cols, keys)
    
    if (length(from_non_keys) == 0 || length(to_non_keys) == 0) {
      return(matrix(character(0), ncol = 2))
    }
    
    # Use expand.grid for efficient combination
    edges <- expand.grid(from = from_non_keys, to = to_non_keys, 
                        stringsAsFactors = FALSE)
    return(as.matrix(edges))
  }
  
  # Helper function to create self-class blacklist (no inter-attribute edges)
  create_self_blacklist <- function(cols, keys) {
    non_keys <- setdiff(cols, keys)
    
    if (length(non_keys) <= 1) {
      return(matrix(character(0), ncol = 2))
    }
    
    # Create all pairs
    pairs <- combn(non_keys, 2)
    # Both directions
    edges <- rbind(
      t(pairs),
      t(pairs[c(2, 1), , drop = FALSE])
    )
    return(edges)
  }
  
  ## Blacklist for main class perspective
  bl_parts <- list()
  
  # Main class cannot parent other classes
  bl_parts[[1]] <- create_blacklist(colsclass1, colsclass2, keys)
  bl_parts[[2]] <- create_blacklist(colsclass1, colsclass3, keys)
  
  # Other classes cannot inter-parent
  bl_parts[[3]] <- create_blacklist(colsclass3, colsclass2, keys)
  bl_parts[[4]] <- create_blacklist(colsclass2, colsclass3, keys)
  
  # Same-class aggregated attributes cannot parent each other
  bl_parts[[5]] <- create_self_blacklist(colsclass2, keys)
  bl_parts[[6]] <- create_self_blacklist(colsclass3, keys)
  
  bl_mt <- do.call(rbind, bl_parts)
  
  ## Blacklist for class 2 perspective
  bl_parts2 <- list()
  bl_parts2[[1]] <- create_blacklist(colsclass2, colsclass1, keys)
  bl_parts2[[2]] <- create_blacklist(colsclass2, colsclass3, keys)
  bl_parts2[[3]] <- create_blacklist(colsclass1, colsclass2, keys)
  bl_parts2[[4]] <- create_blacklist(colsclass3, colsclass1, keys)
  bl_parts2[[5]] <- create_blacklist(colsclass3, colsclass2, keys)
  bl_parts2[[6]] <- create_self_blacklist(colsclass1, keys)
  bl_parts2[[7]] <- create_self_blacklist(colsclass3, keys)
  
  bl_class2 <- do.call(rbind, bl_parts2)
  
  ## Blacklist for class 3 perspective
  bl_parts3 <- list()
  bl_parts3[[1]] <- create_blacklist(colsclass3, colsclass1, keys)
  bl_parts3[[2]] <- create_blacklist(colsclass3, colsclass2, keys)
  bl_parts3[[3]] <- create_blacklist(colsclass1, colsclass3, keys)
  bl_parts3[[4]] <- create_blacklist(colsclass2, colsclass1, keys)
  bl_parts3[[5]] <- create_blacklist(colsclass2, colsclass3, keys)
  bl_parts3[[6]] <- create_self_blacklist(colsclass1, keys)
  bl_parts3[[7]] <- create_self_blacklist(colsclass2, keys)
  
  bl_class3 <- do.call(rbind, bl_parts3)
  
  # Learn partial structures
  learn_structure <- function(data, blacklist, method, score) {
    if (method == 'hc') {
      return(bnlearn::hc(data, blacklist = blacklist, score = score))
    } else if (method == 'tabu') {
      return(bnlearn::tabu(data, blacklist = blacklist, score = score))
    } else {
      stop(paste("Unsupported search method:", method))
    }
  }
  
  pdag_mainclass <- learn_structure(mt_mainclass, bl_mt, search_method, score_function)
  pdag_class2 <- learn_structure(mt_class2, bl_class2, search_method, score_function)
  pdag_class3 <- learn_structure(mt_class3, bl_class3, search_method, score_function)
  
  # Combine arcs from all perspectives
  arcs_mainclass <- pdag_mainclass$arcs
  arcs_class2 <- pdag_class2$arcs
  arcs_class3 <- pdag_class3$arcs
  
  prm_arcs <- unique(rbind(arcs_mainclass, arcs_class2, arcs_class3))
  
  # Assemble final PRM structure
  prm_structure <- bnlearn::empty.graph(colnames(mt_mainclass))
  bnlearn::arcs(prm_structure) <- prm_arcs
  
  # Plot the structure
  plot(prm_structure)
  
  return(prm_structure)
}
