#This is a package for quickly assembling a PRM with up to three classes with categorical attributesand
#The PRM can be used to perform inference using information of different classes in the same domain
#On this first version, the framework is limited to particular cases
#However, it is going to be continuously improved by it's authors

#This package have some dependencies:

install.packages("bnlearn")
library("bnlearn")


#The first step to create a PRM in R is to import your data
#On this first version csv format is recomended
#If you wish to import you data in some other format, please, search for the corret means to do it
#Import one table for each class in you domain (up to three classes)

#It is very important that all foreing keys have the same identification on all tables on which they appears
#The first step, is to create a vector with all the key names, as the code bellow:
#keys <- c("key1", "key2", "key3")

#The first function will read only the rows on your dataset with all variables observed
#It is recommended to do all previous data treatment before feeding the data to the function
#After all you tables are loaded, it is possible to define a relational skeleton and you relational schema
#The first class (denoted class1), will be the center of your PRModel,
#and all the other classes will be aggregated towards "class1"
#At the end, this function will provide a table, with all the attributes of all classes
#If an aggregation function is necessary, the mode will be used

relational.schema <- function(keys, class1, class2, class3){
  if(missing(class1)){
    class1 <- data.frame(Doubles=double(),
                         Ints=integer(),
                         Factors=factor(),
                         Logicals=logical(),
                         Characters=character(),
                         stringsAsFactors=FALSE)
  }
  if(missing(class2)){
    class2 <- data.frame(Doubles=double(),
                         Ints=integer(),
                         Factors=factor(),
                         Logicals=logical(),
                         Characters=character(),
                         stringsAsFactors=FALSE)
  }
  if(missing(class3)){
    class3 <- data.frame(Doubles=double(),
                         Ints=integer(),
                         Factors=factor(),
                         Logicals=logical(),
                         Characters=character(),
                         stringsAsFactors=FALSE)
  }
  class1 = class1[complete.cases(class1), ]
  class2 = class2[complete.cases(class2), ]
  class3 = class3[complete.cases(class3), ]
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
  print("Relational Skeleton")
  for(x in keys){
    if((is.element(x, colsclass1) == TRUE) && (is.element(x, colsclass2) == TRUE)){
      print(paste0(x, ".class1", " <--> ", x, ".class2"))
      f = rapply(class1[x],function(x)length(unique(x)))/rapply(class1[x],function(x)length(x))
      s = rapply(class2[x],function(x)length(unique(x)))/rapply(class2[x],function(x)length(x))
      if((f<1) && (s<1)){
        print("n <--> n")
        class1_class2_link = x
        class1_class2_order = "n"
        class2_class1_order = "n"
      } else if((f<1) && (s==1)){
        print("n <--> 1")
        class1_class2_link = x
        class1_class2_order = "n"
        class2_class1_order = "1"
      } else if((f==1) && (s<1)){
        print("1 <--> n")
        class1_class2_link = x
        class1_class2_order = "1"
        class2_class1_order = "n"
      } else if((f==1) && (s==1)){
        print("1 <--> 1")
        class1_class2_link = x
        class1_class2_order = "1"
        class2_class1_order = "1"
      }
    }
  }
  for(x in keys){
    if((is.element(x, colsclass1) == TRUE) && (is.element(x, colsclass3) == TRUE)){
      print(paste0(x, ".class1", " <--> ", x, ".class3"))
      f = rapply(class1[x],function(x)length(unique(x)))/rapply(class1[x],function(x)length(x))
      s = rapply(class3[x],function(x)length(unique(x)))/rapply(class3[x],function(x)length(x))
      if((f<1) && (s<1)){
        print("n <--> n")
        class1_class3_link = x
        class1_class3_order = "n"
        class3_class1_order = "n"
      } else if((f<1) && (s==1)){
        print("n <--> 1")
        class1_class3_link = x
        class1_class3_order = "n"
        class3_class1_order = "1"
      } else if((f==1) && (s<1)){
        print("1 <--> n")
        class1_class3_link = x
        class1_class3_order = "1"
        class3_class1_order = "n"
      } else if((f==1) && (s==1)){
        print("1 <--> 1")
        class1_class3_link = x
        class1_class3_order = "1"
        class3_class1_order = "1"
      }
    }
  }
  for(x in keys){
    if((is.element(x, colsclass2) == TRUE) && (is.element(x, colsclass3) == TRUE)){
      print(paste0(x, ".class2", " <--> ", x, ".class3"))
      f = rapply(class2[x],function(x)length(unique(x)))/rapply(class2[x],function(x)length(x))
      s = rapply(class3[x],function(x)length(unique(x)))/rapply(class3[x],function(x)length(x))
      if((f<1) && (s<1)){
        print("n <--> n")
        class2_class3_link = x
        class2_class3_order = "n"
        class3_class2_order = "n"
      } else if((f<1) && (s==1)){
        print("n <--> 1")
        class2_class3_link = x
        class2_class3_order = "n"
        class3_class2_order = "1"
      } else if((f==1) && (s<1)){
        print("1 <--> n")
        class2_class3_link = x
        class2_class3_order = "1"
        class3_class2_order = "n"
      } else if((f==1) && (s==1)){
        print("1 <--> 1")
        class2_class3_link = x
        class2_class3_order = "1"
        class3_class2_order = "1"
      }
    }
  }

  master_table = class1
  #class1 TO class2
  if(exists("class1_class2_link") == TRUE){
    #1 TO 1 RELATION
    if((class1_class2_order == "1") && (class2_class1_order =="1")){
      cols.class2 = colnames(class2)
      for(x in cols.class2){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
        }
      }
      unique.class1 = unique(class1[,class1_class2_link])
      for(x in unique.class1){
        partial = class2[which(class2[,class1_class2_link] == x), ]
        cols.class2 = colnames(class2)
        for(y in cols.class2){
          if(is.element(y, keys) == FALSE){
            f = names(sort(-table(partial[y])))[1]
            master_table[y][which(class2[,class1_class2_link] == x), ] = f
          }
        }
      }
    }
    #1 to N RELATIONS
    if((class1_class2_order == "1") && (class2_class1_order =="n")){
      cols.class2 = colnames(class2)
      for(x in cols.class2){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class2[which(class2[,class1_class2_link] == master_table[i, class1_class2_link]),]
            f = names(sort(-table(partial[x])))[1]
            if(is.null(f) == TRUE) next # skip and go to next iteration
            master_table[i, x] = f
          }
        }
      }
    }
    #N TO 1 RELATIONS -
    if((class1_class2_order == "n") && (class2_class1_order =="1")){
      cols.class2 = colnames(class2)
      for(x in cols.class2){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class2[which(class2[,class1_class2_link] == master_table[i, class1_class2_link]),]
            if(nrow(partial) == 0) next # skip and go to next iteration
            master_table[i, x] = as.character(partial[,x])
          }
        }
      }
    }
    #N TO N RELATIONS
    if((class1_class2_order == "n") && (class2_class1_order =="n")){
      cols.class2 = colnames(class2)
      for(x in cols.class2){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class2[which(class2[,class1_class2_link] == master_table[i, class1_class2_link]),]
            f = names(sort(-table(partial[x])))[1]
            if(is.null(f) == TRUE) next # skip and go to next iteration
            master_table[i, x] = f
          }
        }
      }
    }
  }
  #class1 TO class3
  if(exists("class1_class3_link") == TRUE){
    if((class1_class3_order == "1") && (class3_class1_order =="1")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
        }
      }
      unique.class1 = unique(class1[,class1_class3_link])
      for(x in unique.class1){
        partial = class3[which(class3[,class1_class3_link] == x), ]
        cols.class3 = colnames(class3)
        for(y in cols.class3){
          if(is.element(y, keys) == FALSE){
            f = names(sort(-table(partial[y])))[1]
            master_table[y][which(class3[,class1_class3_link] == x), ] = f
          }
        }
      }
    }
    if((class1_class3_order == "1") && (class3_class1_order =="n")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class3[which(class3[,class1_class3_link] == master_table[i, class1_class3_link]),]
            f = names(sort(-table(partial[x])))[1]
            if(is.null(f) == TRUE) next # skip and go to next iteration
            master_table[i, x] = f
          }
        }
      }
    }
    #N TO 1 RELATIONS -
    if((class1_class3_order == "n") && (class3_class1_order =="1")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class3[which(class3[,class1_class3_link] == master_table[i, class1_class3_link]),]
            if(nrow(partial) == 0) next # skip and go to next iteration
            master_table[i, x] = as.character(partial[,x])
          }
        }
      }
    }
    #N TO N RELATIONS
    if((class1_class3_order == "n") && (class3_class1_order =="n")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class3[which(class3[,class1_class3_link] == master_table[i, class1_class3_link]),]
            f = names(sort(-table(partial[x])))[1]
            if(is.null(f) == TRUE) next # skip and go to next iteration
            master_table[i, x] = f
          }
        }
      }
    }
  }
  #class2 TO class3
  if((exists("class1_class3_link") == FALSE) && (exists("class2_class3_link") == TRUE)){
    master_table[class2_class3_link] <- NA
    for (i in 1:nrow(master_table)) {
      key_gen = class2[which(class2[,class1_class2_link] == master_table[i, class1_class2_link]),]
      k = names(sort(-table(key_gen[class2_class3_link])))[1]
      if(is.null(k) == TRUE) next # skip and go to next iteration
      master_table[i, class2_class3_link] = k
    }
    if((class2_class3_order == "1") && (class3_class2_order =="1")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
        }
      }
      unique.class2 = unique(class2[,class2_class3_link])
      for(x in unique.class2){
        partial = class3[which(class3[,class2_class3_link] == x), ]
        cols.class3 = colnames(class3)
        for(y in cols.class3){
          if(is.element(y, keys) == FALSE){
            f = names(sort(-table(partial[y])))[1]
            master_table[y][which(class3[,class2_class3_link] == x), ] = f
          }
        }
      }
    }
    #1 TO N RELATIONS
    if((class2_class3_order == "1") && (class3_class2_order =="n")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class3[which(class3[,class2_class3_link] == master_table[i, class2_class3_link]),]
            f = names(sort(-table(partial[x])))[1]
            if(is.null(f) == TRUE) next # skip and go to next iteration
            master_table[i, x] = f
          }
        }
      }
    }
    #N TO 1 RELATIONS -
    if((class2_class3_order == "n") && (class3_class2_order =="1")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class3[which(class3[,class2_class3_link] == master_table[i, class2_class3_link]),]
            if(nrow(partial) == 0) next # skip and go to next iteration
            master_table[i, x] = as.character(partial[,x])
          }
        }
      }
    }
    #N TO N RELATIONS
    if((class2_class3_order == "n") && (class3_class2_order =="n")){
      cols.class3 = colnames(class3)
      for(x in cols.class3){
        if(is.element(x, keys) == FALSE){
          master_table[x] <- NA
          for (i in 1:nrow(master_table)) {
            partial = class3[which(class3[,class2_class3_link] == master_table[i, class2_class3_link]),]
            f = names(sort(-table(partial[x])))[1]
            if(is.null(f) == TRUE) next # skip and go to next iteration
            master_table[i, x] = f
          }
        }
      }
    }
  }
  drops <- keys
  master_table = master_table[ , !(names(master_table) %in% drops)]
  for(n in names(master_table)){
    master_table[, n] <- as.factor(master_table[, n])
  }
  return(master_table)
}

structure.learn <- function(relational_schema, keys, class1, class2, class3, search_method, score_function){
  if(missing(search_method)){
    search_method <- 'hc'
  }
  if(missing(score_function)){
    score_function <- 'bic'
  }
  relational_schema = relational_schema[complete.cases(relational_schema), ]
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
  bl = matrix(black_list, ncol = 2, byrow = TRUE)
  if(search_method == 'hc'){
    pdag = hc(relational_schema, blacklist = bl, score = score_function)
  }
  if(search_method == 'tabu'){
    pdag = tabu(relational_schema, blacklist = bl, score = score_function)
  }
  plot(pdag)
  return(pdag)
}

parameters.learn <- function(net, database){
  fit = bn.fit(net, database)
  return(fit)
}
