#          #################################################                   #
#          #################################################                   #
#          ###                                           ###                   #
#          ###         PREPROCESSING FUNCTIONS           ###                   #         
#          ###                                           ###                   #
#          #################################################                   #
#          #################################################                   #
convert23CToChar <- function(label){
  'Function that converts a gbs to string (if originally numeric)
  NOTE - GBS convention states that all GBS numbers have 3 characters,
  if the number is less that 100, then the missing space will be filled in by 0.
  For example: 10 -> GBS010'
  
  label %<>% as.character() %>% case_when(
    nchar(.) == 1 ~paste0("00", .),
    nchar(.) == 2 ~paste0("0", .),
    .default =.
  )
  return(label)
}

findNACols <- function(df){
  'Return column names of columns that are all NA '
  numNa <- colSums(is.na(df))
  return(colnames(df[numNa==nrow(df)]))
}

## LICOR Functions #############################################################
readSheetWData <- function(filepath, sheet){
  'Function to read in sheet of specified file of LICOR data
  Returns dataframe with appropriate column names'
  
  # Note: data first row is overall grouping, second row is colnames, third row is data units
  df_colnames <- suppressMessages(as.character(
    read_excel(filepath, sheet = sheet, skip = 1, n_max = 1, col_names = FALSE)))
  df <- suppressMessages(read_excel(
    filepath, sheet = sheet, skip = 3, col_names = df_colnames))
  return(df)
}

readLicorData <- function(filepath, location){
  'Function reads in all sheets of LICOR workbook, and combines all into one dataframe
  NOTE - if only 1 sheet, should have all 3 rows, if multiple sheets, each sheet should be different rows'
  
  #Read in sheets and combine
  sheetnames <- excel_sheets(filepath)
  df <- lapply(set_names(sheetnames, sheetnames),
               function(x) readSheetWData(filepath, x)) %>% 
    bind_rows(.id = "row_corrected")  %>% 
    mutate(location = location)
  
  # Convert colnames to snake_case
  colnames(df) <- to_any_case(colnames(df))

  
  return(df %>% data.frame() )
}

## HARVEST #####################################################################
getDfWithoutCols <- function(df, cols_filter_out){
  'Function that gives us the dataframe WITHOUT any columns that contain and strings in the cols_to_pivot list'
  
  selected_indices <- grep(paste(cols_filter_out, collapse = "|"), colnames(df))
  df_filtered <- df[, -selected_indices]
  
  return(df_filtered)
}
                               
pivotLongerColumn <- function(df, name, grouping_cols){
  'Function to pivot longer a specific set of columns'
  
  # Pivot columns longer
  cols_to_condense <- colnames(df[grepl(name,colnames(df))])
  selectedDf <- df %>% select(all_of(grouping_cols), all_of(cols_to_condense)) %>% 
    pivot_longer(!all_of(grouping_cols), names_to = "plant_num_in_rep", values_to = name) 
  
  # Rename plant_num_in_rep to only be numeric (i.e. take away "name" from the beginning)
  selectedDf$plant_num_in_rep <- gsub(paste0(name,"_"), "", selectedDf$plant_num_in_rep)
  
  return(selectedDf)
}

pivotLongerPlantData <- function(df, cols_to_pivot, grouping_cols ){
  'Function to take the columns that take measurements for specific plants as columns, and pivot them
  longer such that we have a column that represents plant number, and another column that represents the trait
  
  i.e. instead of have 5 columns and one row: plant height for plant 1, plant height for plant 2, 
  plant height for plant 3, plant height for plant 4, plant height for plant 5 .... 
  we have 2 columns and 5 rows: plant number, plant height
  
  Input: 
    - df: dataframe with extra columns
    - cols_to_pivot: list of all the columns/traits names that we want to condense from 5 to 2
    - grouping_cols: columns that are needed for merging
  Returns full pivoted longer dataframe '
  
  
  df_without_pivots <- getDfWithoutCols(df, cols_to_pivot )
  
  result_list <- lapply(cols_to_pivot, function(x) pivotLongerColumn(df, x, grouping_cols))
  final_result <- Reduce(function(x, y) merge(x, y, by = c(grouping_cols, "plant_num_in_rep")), result_list) %>% 
    merge(df_without_pivots, by = grouping_cols)
}

checkDates <- function(df){
  'Check for any issues with transplanting and harvest dates. For example, make sure 
  days from transplanting to harvest is positive and within a reasonable range 
  (Im defining this as less or greater than 25 of median days)'
  
  num_warnings <- 0
  median_days <- median(df$days_from_t_to_h, na.rm = T)
  
  days_negative <- df %>% filter(days_from_t_to_h <= 0)
  days_out_of_range <- df %>% 
    filter(days_from_t_to_h < median_days*.75 || days_from_t_to_h > median_days *1.25 ) 
  
  #if any negative days from 
  if(nrow(days_negative) > 0 ){
    num_warnings = num_warnings+1
    warning(paste0("The following label23C have total days < 0:", days_negative$label23C))
  }
  if(nrow(days_out_of_range) > 0 ){
    num_warnings = num_warnings+1
    warning(paste0("The following label23C have total days out of reasonable range:", days_out_of_range$label23C))
  }
  if(num_warnings==0){
    print("Dates are within range! No flags.")
  }
  
}

## COMBINE #####################################################################
grouping_cols <- c("label23C", "rep", "location")

checkReadyToCombine <- function(df, grouping_cols){
  'Function to check all dataframes to make sure they are ready to be combined.
  Checks they have required columns for merging, checks that there is only one row per 
  groued column, and checks that the values in the merging column are correct
  
  Returns boolean - true if ready for merging, false if not ready yet'
  
  # Check required columns are in df
  
  # Check each unique grouping has only 1 row
  notUnique <- df %>% dplyr::group_by(label23C, rep, location) %>% dplyr::summarise(n = n()) %>% filter(n>1)
  
  # Check values in merging column are correct
}










#