structure.learn <- function(mt_mainclass, mt_class2, mt_class3, keys, class1, class2, class3, search_method, score_function){
  #If a search method is not specified, hill-climbing will be set as default
  if(missing(search_method)){
    search_method <- 'hc'
  }
  #If a score function is not specified, bic score will be set as default
  if(missing(score_function)){
    score_function <- 'bic'
  }
  #Only the complete cases of the master_table for the main class will be considered
  #Variables with only one observed level will gain a "Ghost" level, that way the search method can be applied 
  mt_mainclass = mt_mainclass[complete.cases(mt_mainclass), ]
  cols_mt_mainclass <- colnames(mt_mainclass)
  for (i in cols_mt_mainclass){
    if(length(levels(mt_mainclass[,i])) == 1){
      levels(mt_mainclass[,i]) <- c(levels(mt_mainclass[,i]), "Ghost")
      }
  }
  #Only the complete cases of the master_table for class 2 will be considered
  #Variables with only one observed level will gain a "Ghost" level, that way the search method can be applied 
  mt_class2 = mt_class2[complete.cases(mt_class2), ]
  cols_mt_class2 <- colnames(mt_class2)
  for (i in cols_mt_class2){
    if(length(levels(mt_class2[,i])) == 1){
      levels(mt_class2[,i]) <- c(levels(mt_class2[,i]), "Ghost")
    }
  }
  #Only the complete cases of the master_table for class 3 will be considered
  #Variables with only one observed level will gain a "Ghost" level, that way the search method can be applied 
  mt_class3 = mt_class3[complete.cases(mt_class3), ]
  cols_mt_class3 <- colnames(mt_class3)
  for (i in cols_mt_class3){
    if(length(levels(mt_class3[,i])) == 1){
      levels(mt_class3[,i]) <- c(levels(mt_class3[,i]), "Ghost")
    }
  }
  #Listing the variables on each class, to create the PRM blacklist of arrows, according to the assumptions
  colsclass1 <- c()
  colsclass2 <- c()
  colsclass3 <- c()
  if(!is.null(class1)){
    colsclass1 <- colnames(class1)
  }
  if(!is.null(class2)){
    colsclass2 <- colnames(class2)
  }
  if(!is.null(class1)){
    colsclass3 <- colnames(class3)
  }
  #creating the blacklist for the main class
  black_list <- c()
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass3){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if((is.element(j, keys) == FALSE) & (j != i)){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass3){
        if((is.element(j, keys) == FALSE) & (j != i)){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  #main class blacklist
  bl_mt = matrix(black_list, ncol = 2, byrow = TRUE)
  #creating the blacklist for class 2
  black_list <- c()
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass1){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass1){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass3){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  #for(i in colsclass2){
  #  if(is.element(i, keys) == FALSE){
  #    for(j in colsclass3){
  #      if(is.element(j, keys) == FALSE){
  #        black_list[[length(black_list)+1]] <- j
  #        black_list[[length(black_list)+1]] <- i
  #      }
  #    }
  #  }
  #}
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass1){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if((is.element(j, keys) == FALSE) & (j != i)){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass3){
        if((is.element(j, keys) == FALSE) & (j != i)){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  #class 2 blacklist
  bl_class2 = matrix(black_list, ncol = 2, byrow = TRUE)
  #creating the blacklist for class 3
  black_list <- c()
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass1){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass1){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass3){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass3){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass3){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if(is.element(j, keys) == FALSE){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass1){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass1){
        if((is.element(j, keys) == FALSE) & (j != i)){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  for(i in colsclass2){
    if(is.element(i, keys) == FALSE){
      for(j in colsclass2){
        if((is.element(j, keys) == FALSE) & (j != i)){
          black_list[[length(black_list)+1]] <- j
          black_list[[length(black_list)+1]] <- i
        }
      }
    }
  }
  #class 3 blacklist
  bl_class3 = matrix(black_list, ncol = 2, byrow = TRUE)
  #Learning the partial structures
  if(search_method == 'hc'){
    pdag_mainclass = hc(mt_mainclass, blacklist = bl_mt, score = score_function)
    pdag_class2 = hc(mt_class2, blacklist = bl_class2, score = score_function)
    pdag_class3 = hc(mt_class3, blacklist = bl_class3, score = score_function)
  }
  if(search_method == 'tabu'){
    pdag_mainclass = tabu(mt_mainclass, blacklist = bl_mt, score = score_function)
    pdag_class2 = tabu(mt_class2, blacklist = bl_class2, score = score_function)
    pdag_class3 = tabu(mt_class3, blacklist = bl_class3, score = score_function)
  }
  #Defining the arcs on the PRM structure
  arcs_mainclass <- pdag_mainclass$arcs
  arcs_class2 <- pdag_class2$arcs
  arcs_class3 <- pdag_class3$arcs
  prm_arcs <- rbind(arcs_mainclass, arcs_class2, arcs_class3)
  #Assembling the PRM structure
  prm_structure <- empty.graph(cols_mt_mainclass)
  arcs(prm_structure) <- prm_arcs
  #Plotting and returning the PRM structure
  plot(prm_structure)
  return(prm_structure)
}
