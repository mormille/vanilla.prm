parameters.learn <- function(net, mt_mainclass, mt_class2, mt_class3){
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
  fit_mainclass = bn.fit(net, mt_mainclass)
  fit_class2 = bn.fit(net, mt_class2)
  fit_class3 = bn.fit(net, mt_class3)
  return(fit_mainclass)
}