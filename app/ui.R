library(shiny)
library(shinyWidgets)
library(shinythemes)

# Define UI for application
shinyUI(fluidPage(
  theme = shinytheme("cerulean"),
  titlePanel("Impact of Stress on Scoville Heat Unit in NM Chile Peppers"),
  tabsetPanel(
    ############################
    ## TAB 1
    ############################
    tabPanel("SHU  Data",
             
             sidebarLayout(
               sidebarPanel(
                 # Sidebar for selection
                 pickerInput(
                   "label_filter_shu",
                   "Select Plant Label(s)",
                   choices = unique(hplc_df$label23C),
                   options = list(`actions-box` = TRUE),
                   multiple = TRUE
                 ),
                 
               ),
               # Output
               mainPanel(fluidRow(
                 column(width = 6,
                        plotOutput("plot_count_shu")),
                 column(width = 6,
                        plotOutput("plot_box_hplc"))
               ),
               fluidRow(tableOutput("filtered_table")))
             )),
    ############################
    ## TAB 2
    ############################
    tabPanel(
      "LICOR Data",
             sidebarLayout(
               sidebarPanel(
                 #Sidebar panel for selection
                 h2("Data Selection Options"),
                 pickerInput(
                   "label_filter_licor",
                   "Select Plant Label(s)",
                   choices = unique(data$label23C),
                   options = list(`actions-box` = TRUE),
                   multiple = TRUE
                 ),
                 checkboxInput(
                   "checkbox_scale",
                   "Scale Data",
                   value = FALSE,
                   width = NULL
                 ),
                h2("Graphing Options"),
                selectInput("facet_column", "Select a feature to split graphs:", 
                            choices = c('rep', 'location', 'label23C', 'date')),
                

               ),
               # Output
               mainPanel(plotOutput("plot_scatter_licor"))
             )
      )
    
    
    
    
    
    
  )
))