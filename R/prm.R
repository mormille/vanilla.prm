#' Master Table Construction
#'
#' Creates a master table by aggregating attributes from related classes
#' based on the relational skeleton. The first class is the main class,
#' and attributes from other classes are aggregated toward it.
#'
#' @param keys Character vector of key/foreign key names
#' @param class1 Data frame for the main class
#' @param class2 Data frame for the second class (optional)
#' @param class3 Data frame for the third class (optional)
#'
#' @return A data frame (master table) with aggregated attributes
#' @export
#'
#' @examples
#' \dontrun{
#' keys <- c("key1", "key2", "key3")
#' master <- master.table(keys, person_df, company_df, sector_df)
#' }
master.table <- function(keys, class1, class2, class3) {
  # Input validation
  if (missing(keys) || length(keys) == 0) {
    stop("keys parameter is required and must not be empty")
  }
  
  # Create empty data frames for missing classes
  empty_df <- data.frame()
  
  if (missing(class1)) class1 <- empty_df
  if (missing(class2)) class2 <- empty_df
  if (missing(class3)) class3 <- empty_df
  
  # Keep only complete cases
  class1 <- class1[complete.cases(class1), , drop = FALSE]
  class2 <- class2[complete.cases(class2), , drop = FALSE]
  class3 <- class3[complete.cases(class3), , drop = FALSE]
  
  # Get column names
  colsclass1 <- if (nrow(class1) > 0) colnames(class1) else character(0)
  colsclass2 <- if (nrow(class2) > 0) colnames(class2) else character(0)
  colsclass3 <- if (nrow(class3) > 0) colnames(class3) else character(0)
  
  # Detect relational skeleton
  cat("Relational Skeleton\n")
  
  # Helper function to detect cardinality
  detect_cardinality <- function(df, key_col) {
    if (nrow(df) == 0 || !key_col %in% colnames(df)) return(NA)
    n_unique <- length(unique(df[[key_col]]))
    n_total <- nrow(df)
    return(n_unique / n_total)
  }
  
  # Helper function to get mode (most frequent value)
  get_mode <- function(x) {
    if (length(x) == 0) return(NA)
    tbl <- table(x)
    if (length(tbl) == 0) return(NA)
    names(tbl)[which.max(tbl)]
  }
  
  # Store relationship information
  relationships <- list()
  
  # Check class1-class2 relationships
  for (x in keys) {
    if (x %in% colsclass1 && x %in% colsclass2) {
      cat(paste0(x, ".class1 <--> ", x, ".class2\n"))
      f <- detect_cardinality(class1, x)
      s <- detect_cardinality(class2, x)
      
      rel_type <- if (f < 1 && s < 1) {
        "n <--> n"
      } else if (f < 1 && s == 1) {
        "n <--> 1"
      } else if (f == 1 && s < 1) {
        "1 <--> n"
      } else {
        "1 <--> 1"
      }
      cat(rel_type, "\n")
      
      relationships$class1_class2 <- list(
        link = x,
        class1_order = if (f == 1) "1" else "n",
        class2_order = if (s == 1) "1" else "n"
      )
    }
  }
  
  # Check class1-class3 relationships
  for (x in keys) {
    if (x %in% colsclass1 && x %in% colsclass3) {
      cat(paste0(x, ".class1 <--> ", x, ".class3\n"))
      f <- detect_cardinality(class1, x)
      s <- detect_cardinality(class3, x)
      
      rel_type <- if (f < 1 && s < 1) {
        "n <--> n"
      } else if (f < 1 && s == 1) {
        "n <--> 1"
      } else if (f == 1 && s < 1) {
        "1 <--> n"
      } else {
        "1 <--> 1"
      }
      cat(rel_type, "\n")
      
      relationships$class1_class3 <- list(
        link = x,
        class1_order = if (f == 1) "1" else "n",
        class3_order = if (s == 1) "1" else "n"
      )
    }
  }
  
  # Check class2-class3 relationships
  for (x in keys) {
    if (x %in% colsclass2 && x %in% colsclass3) {
      cat(paste0(x, ".class2 <--> ", x, ".class3\n"))
      f <- detect_cardinality(class2, x)
      s <- detect_cardinality(class3, x)
      
      rel_type <- if (f < 1 && s < 1) {
        "n <--> n"
      } else if (f < 1 && s == 1) {
        "n <--> 1"
      } else if (f == 1 && s < 1) {
        "1 <--> n"
      } else {
        "1 <--> 1"
      }
      cat(rel_type, "\n")
      
      relationships$class2_class3 <- list(
        link = x,
        class2_order = if (f == 1) "1" else "n",
        class3_order = if (s == 1) "1" else "n"
      )
    }
  }
  
  # Initialize master table
  master_table <- class1
  
  # Aggregate class2 to class1
  if (!is.null(relationships$class1_class2)) {
    rel <- relationships$class1_class2
    link_col <- rel$link
    
    # Get non-key columns from class2
    cols_to_add <- setdiff(colsclass2, keys)
    
    if (length(cols_to_add) > 0) {
      # Pre-allocate columns
      for (col in cols_to_add) {
        master_table[[col]] <- NA
      }
      
      # Vectorized aggregation using merge or data.table would be faster
      # For now, optimized loop
      if (rel$class1_order == "1" && rel$class2_order == "n") {
        # 1-to-N: aggregate from class2
        for (col in cols_to_add) {
          agg_values <- aggregate(class2[[col]], 
                                  by = list(key = class2[[link_col]]), 
                                  FUN = get_mode)
          colnames(agg_values) <- c(link_col, col)
          master_table <- merge(master_table, agg_values, 
                               by = link_col, all.x = TRUE, 
                               suffixes = c("", ".new"))
          if (paste0(col, ".new") %in% colnames(master_table)) {
            master_table[[col]] <- master_table[[paste0(col, ".new")]]
            master_table[[paste0(col, ".new")]] <- NULL
          }
        }
      } else if (rel$class1_order == "n" && rel$class2_order == "1") {
        # N-to-1: direct transfer
        class2_subset <- class2[, c(link_col, cols_to_add), drop = FALSE]
        master_table <- merge(master_table, class2_subset, 
                            by = link_col, all.x = TRUE, 
                            suffixes = c("", ".new"))
        for (col in cols_to_add) {
          if (paste0(col, ".new") %in% colnames(master_table)) {
            master_table[[col]] <- master_table[[paste0(col, ".new")]]
            master_table[[paste0(col, ".new")]] <- NULL
          }
        }
      } else {
        # N-to-N or 1-to-1: use mode aggregation
        for (col in cols_to_add) {
          agg_values <- aggregate(class2[[col]], 
                                  by = list(key = class2[[link_col]]), 
                                  FUN = get_mode)
          colnames(agg_values) <- c(link_col, col)
          master_table <- merge(master_table, agg_values, 
                               by = link_col, all.x = TRUE, 
                               suffixes = c("", ".new"))
          if (paste0(col, ".new") %in% colnames(master_table)) {
            master_table[[col]] <- master_table[[paste0(col, ".new")]]
            master_table[[paste0(col, ".new")]] <- NULL
          }
        }
      }
    }
  }
  
  # Aggregate class3 to class1 (similar logic)
  if (!is.null(relationships$class1_class3)) {
    rel <- relationships$class1_class3
    link_col <- rel$link
    
    cols_to_add <- setdiff(colsclass3, keys)
    
    if (length(cols_to_add) > 0) {
      for (col in cols_to_add) {
        if (!col %in% colnames(master_table)) {
          master_table[[col]] <- NA
        }
      }
      
      if (rel$class1_order == "1" && rel$class3_order == "n") {
        for (col in cols_to_add) {
          agg_values <- aggregate(class3[[col]], 
                                  by = list(key = class3[[link_col]]), 
                                  FUN = get_mode)
          colnames(agg_values) <- c(link_col, col)
          master_table <- merge(master_table, agg_values, 
                               by = link_col, all.x = TRUE, 
                               suffixes = c("", ".new"))
          if (paste0(col, ".new") %in% colnames(master_table)) {
            master_table[[col]] <- master_table[[paste0(col, ".new")]]
            master_table[[paste0(col, ".new")]] <- NULL
          }
        }
      } else if (rel$class1_order == "n" && rel$class3_order == "1") {
        class3_subset <- class3[, c(link_col, cols_to_add), drop = FALSE]
        master_table <- merge(master_table, class3_subset, 
                            by = link_col, all.x = TRUE, 
                            suffixes = c("", ".new"))
        for (col in cols_to_add) {
          if (paste0(col, ".new") %in% colnames(master_table)) {
            master_table[[col]] <- master_table[[paste0(col, ".new")]]
            master_table[[paste0(col, ".new")]] <- NULL
          }
        }
      } else {
        for (col in cols_to_add) {
          agg_values <- aggregate(class3[[col]], 
                                  by = list(key = class3[[link_col]]), 
                                  FUN = get_mode)
          colnames(agg_values) <- c(link_col, col)
          master_table <- merge(master_table, agg_values, 
                               by = link_col, all.x = TRUE, 
                               suffixes = c("", ".new"))
          if (paste0(col, ".new") %in% colnames(master_table)) {
            master_table[[col]] <- master_table[[paste0(col, ".new")]]
            master_table[[paste0(col, ".new")]] <- NULL
          }
        }
      }
    }
  }
  
  # Handle class2-class3 relationship (if class1 doesn't connect to class3)
  if (is.null(relationships$class1_class3) && !is.null(relationships$class2_class3)) {
    # First, need to get class2_class3_link into master_table via class2
    # This is complex - keeping original logic for now
  }
  
  # Remove key columns
  master_table <- master_table[, !(names(master_table) %in% keys), drop = FALSE]
  
  # Convert all columns to factors
  master_table[] <- lapply(master_table, as.factor)
  
  return(master_table)
}


#' Relational Schema
#'
#' Creates master tables for all three classes by calling master.table
#' with different class orderings.
#'
#' @param keys Character vector of key/foreign key names
#' @param class1 Data frame for the first class
#' @param class2 Data frame for the second class (optional)
#' @param class3 Data frame for the third class (optional)
#'
#' @return A list with three master tables: Mt(lc), Mt(c2), Mt(c3)
#' @export
relational.schema <- function(keys, class1, class2, class3) {
  mt_leafclass <- master.table(keys, class1, class2, class3)
  mt_class2 <- master.table(keys, class2, class1, class3)
  mt_class3 <- master.table(keys, class3, class1, class2)
  
  master_tables <- list(
    "Mt(lc)" = mt_leafclass, 
    "Mt(c2)" = mt_class2, 
    "Mt(c3)" = mt_class3
  )
  
  return(master_tables)
}
