args <- commandArgs(trailingOnly = TRUE)



library(Rcpp)
library(qvalue)
library(glmnet)
library(VirFinder)


setwd(args[1])

infafile <- args[2]

predResult <- VF.pred(infafile)

predResult[order(predResult$pvalue),]

predResult$qvalue <- VF.qvalue(predResult$pvalue)
#predResult$qvalue <- VF.qvalue(predResult$pvalue, pi0=1 )

write.table(predResult, args[3], sep="\t")
