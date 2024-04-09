library(shiny)
library(shinyWidgets)
library(shinythemes)

# Define UI for application
shinyUI(fluidPage(theme = shinytheme("cerulean"),
  titlePanel("Impact of Stress on Scoville Heat Unit in NM Chile Peppers"),
  tabsetPanel(
    ############################
    ## TAB 1 
    ############################
    tabPanel("SHU  Data",
             
             sidebarLayout(
               sidebarPanel( # Sidebar for selection
                 pickerInput(
                   "label_filter",
                   "Select Labels",
                   choices = unique(hplc_df$label23C),
                   options = list(`actions-box` = TRUE),
                   multiple = TRUE
                 ),
               ),
               # Output
               mainPanel(
                 fluidRow(column(width = 6,
                                 plotOutput("plot_count_shu")),
                          column(width = 6,
                                 plotOutput("plot_box_hplc"))),
                          
                          
                          
                 fluidRow(tableOutput("filtered_table"))
                 
                 
                 )
               )
    ),
    ############################
    ## TAB 2
    ############################
    tabPanel("LICOR Data"),
    
    ############################
    ## TAB 3
    ############################
    tabPanel("Combined Data")
    
  )
  
  
  
  
  
  
))
