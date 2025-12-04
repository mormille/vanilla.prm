#' Parameter Learning for PRM
#'
#' Fits conditional probability distributions to the learned PRM structure.
#'
#' @param net The PRM structure (bn object) from structure.learn
#' @param mt_mainclass Master table for the main class
#' @param mt_class2 Master table for class 2 (optional, for advanced use)
#' @param mt_class3 Master table for class 3 (optional, for advanced use)
#'
#' @return A bn.fit object with fitted parameters
#' @export
#' @importFrom bnlearn bn.fit
parameters.learn <- function(net, mt_mainclass, mt_class2 = NULL, mt_class3 = NULL) {
  
  # Helper function to prepare master table
  prepare_master_table <- function(mt) {
    if (is.null(mt) || nrow(mt) == 0) return(NULL)
    
    mt <- mt[complete.cases(mt), , drop = FALSE]
    
    # Add "Ghost" level to single-level factors
    for (col in colnames(mt)) {
      if (is.factor(mt[[col]]) && length(levels(mt[[col]])) == 1) {
        levels(mt[[col]]) <- c(levels(mt[[col]]), "Ghost")
      }
    }
    return(mt)
  }
  
  # Prepare main class master table
  mt_mainclass <- prepare_master_table(mt_mainclass)
  
  if (is.null(mt_mainclass) || nrow(mt_mainclass) == 0) {
    stop("mt_mainclass is empty or NULL after preprocessing")
  }
  
  # Fit parameters using the main class master table
  # Note: The original code also prepared mt_class2 and mt_class3 but only used mt_mainclass
  fit_mainclass <- bnlearn::bn.fit(net, mt_mainclass)
  
  return(fit_mainclass)
}
