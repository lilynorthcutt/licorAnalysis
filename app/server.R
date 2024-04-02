library(shiny)

# Define server logic
shinyServer(function(input, output) {
  
  # Filter dataframe based on selected values
  filtered_df <- reactive({
    if (is.null(input$label_filter)) {
      return(hplcDf)
    } else {
      hplcDf %>%  filter(label23C %in% input$label_filter)  
    }
  })
  
  ######################
  ## Plots and Graphs ##
  ######################
  
  # Render the filtered dataframe as a table
  output$filtered_table <- renderTable({
    filtered_df() %>% select(-sampleCount)
  })
  
  # Plot of count of shu label by location for selected
  output$plot_count_shu <- renderPlot( {
    ggplot(filtered_df())+
      geom_bar(aes(x = shuLabel, color = location, fill = location), position = position_dodge())
    
  })
  
  # Boxplot of hplc by location
  output$plot_box_hplc <- renderPlot({
    ggplot(filtered_df()) +
      geom_boxplot(aes(x = label23C, y = hplc, group = label23C)) +
      geom_hline(yintercept=2000, linetype="dashed", color = "red")+
      geom_hline(yintercept=5000, linetype="dashed", color = "red")+
      facet_wrap(.~location)
  })

  
  
  
})