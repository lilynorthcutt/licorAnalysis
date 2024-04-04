#################################################
#################################################
###                                           ###
###         PREPROCESSING FUNCTIONS           ###         
###                                           ###
#################################################
#################################################

## LICOR Functions
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

readLicorData <- function(filepath){
  'Function reads in all sheets of LICOR workbook, and combines all into one dataframe
  NOTE - if only 1 sheet, should have all 3 rows, if multiple sheets, each sheet should be different rows'
  
  #Read in sheets and combine
  sheetnames <- excel_sheets(filepath)
  df <- lapply(set_names(sheetnames, sheetnames),
               function(x) readSheetWData(filepath, x)) %>% 
    bind_rows(.id = "row_corrected")  
  
  # Convert colnames to snake_case
  colnames(df) <- to_any_case(colnames(df))

  
  return(df %>% data.frame() )
}

convert23CToChar <- function(gbs){
  'Function that converts a gbs to string (if originally numeric)
  NOTE - GBS convention states that all GBS numbers have 3 characters,
  if the number is less that 100, then the missing space will be filled in by 0.
  For example: 10 -> GBS010'
  
  gbs %<>% as.character() %>% case_when(
    nchar(.) == 1 ~paste0("00", .),
    nchar(.) == 2 ~paste0("0", .),
    .default =.
  )
  return(gbs)
}
