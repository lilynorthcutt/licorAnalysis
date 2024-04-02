outlierCheck <- function(zscores, threshold = 3){
  return(ifelse(abs(zscores) > threshold, TRUE, FALSE))
}