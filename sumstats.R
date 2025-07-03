sumstats = function(y) {
  nums <- sapply(y, is.numeric)
  sumst = sapply(y[, nums], function(x) {
    x <- x[!is.na(x)]
    sumstat = c(
      mean(x),
      median(x),
      sd(x),
      min(x),
      max(x),
      sum((x-mean(x))^3/sd(x)^3)/length(x),
      sum((x-mean(x))^4/sd(x)^4)/(length(x)) - 3,
      length(x)
    )
    names(sumstat) = c("Mean", "Median", "SD", 
                       "Min", "Max","Skew","Kurt","n")
    round(sumstat,3)
  })
  t(sumst)
}

