library(shiny)

# Define server logic
shinyServer(function(input, output) {
  #################################
  #################################
  ### GEN DF BASED ON SELECTION ###
  #################################
  #################################
  
  ######## TAB 1 ########################
  # Filter dataframe based on selected values SHU
  filtered_df <- reactive({
    hplc_df %<>% mutate(shuLabel = factor(shuLabel, levels = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot"))) 
    
    if (is.null(input$label_filter_shu)) {
      return(hplc_df)
    } else {
      hplc_df %>%  filter(label23C %in% input$label_filter_shu)  
    }
  })
  
  ######## TAB 2 ########################
  # FILTERED DF BASED ON SELECTION
  filtered_df_licor <- reactive({
    dont_pivot <- c("rep", "label23C", "location", "shu", "shuLabel", "date")
    
    data %<>% mutate(shuLabel = factor(shuLabel, levels = c("Mild", "Hot", "Very Hot", "Extremely Hot", "Superhot"))) 

    # SCALE
    if(input$checkbox_scale){
      data %<>% select(dont_pivot) %>% cbind(map(data %>% select(!any_of(dont_pivot)), scale, center = TRUE, scale = TRUE))
    }

    
    # FILTER DF ON SELECTIONS
    if (is.null(input$label_filter_licor)) {
      return(data)
    } else {
      data %>%  filter(label23C %in% input$label_filter_licor)
    }

  })

  # PIVOT LONGER ON FEATURES FOR GRAPHING
  filtered_df_licor_features <- reactive(({
    filtered_df_licor() %>% pivot_longer(cols = !any_of(dont_pivot), names_to = "features", values_to = "feature_val")
  }))
  
  
  
  #################################
  #################################
  ## GEN ALL PLOTS ###
  #################################
  #################################
  
  ######## TAB 1 ########################
  
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
      geom_boxplot(aes(x = label23C, y = shu, group = label23C)) +
      geom_hline(yintercept=2000, linetype="dashed", color = "red")+
      geom_hline(yintercept=5000, linetype="dashed", color = "red")+
      facet_wrap(.~location)
  })

  
  ######## TAB 2 ########################
  
  # Create scatter plot based on selection
  output$plot_scatter_licor <- renderPlot({
    req(input$facet_column) # Wait until a column is selected
    
    
    ggplot(filtered_df_licor_features()) +
      geom_point(aes(x = features, y = feature_val, color = shuLabel)) +
      facet_wrap(as.formula(paste(".~", input$facet_column))) +
      ggtitle("Stress Factors") +
      xlab("Value") +
      ylab("Factors") +
      scale_color_manual(values = c("deepskyblue", "darkorange", "brown1"))+
      theme(axis.title.x=element_blank(),
            axis.text.x=element_blank(),
            axis.ticks.x=element_blank())
    
  })
  
})