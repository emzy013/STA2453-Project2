#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(highcharter)
library(plotly)
library(ggplot2)
library(tidyverse)


#Download dataset of covid-19
cases_link_1 <-
    "https://health-infobase.canada.ca/src/data/covidLive/covid19-download.csv"
full_cases <- read.csv(url(cases_link_1))

vaccines_link_1 <-
    "https://health-infobase.canada.ca/src/data/covidLive/vaccination-coverage-map.csv"
vaccines <- read.csv(url(vaccines_link_1))



# Define server logic
shinyServer(function(input, output) {
    
    output$canadaMap <- renderHighchart({
        df_cases <- full_cases %>%
            select(c("prname", "numdeathstoday", "numtests", "numtoday")) %>%
            group_by(prname) %>%
            mutate(prname = replace(prname, prname == "Quebec", "Québec")) %>%
            summarise(
                "Total Deaths" = sum(numdeathstoday),
                "Total Tests" = sum(numtests),
                "Total Cases" = sum(numtoday)
            )  %>%
            dplyr::filter(prname != "Repatriated travellers" &&
                              prname != "Canada")
        
        df_vac <- vaccines  %>%
            tail(., n = 13) %>%
            select(
                c(
                    "prename",
                    "numtotal_partially",
                    "numtotal_fully",
                    "numtotal_additional"
                )
            ) %>%
            group_by(prename) %>%
            mutate(prename = replace(prename, prename == "Quebec", "Québec")) %>%
            summarise(
                "Total Partially vaccinated" = numtotal_partially,
                "Total Fully vaccinated" = numtotal_fully,
                "Total Additional vaccinated" = numtotal_additional
            )
        
        if (input$total_record %in% c("Total Deaths", "Total Tests", "Total Cases")) {
            df_map <- df_cases
            join_name <- c('woe-name', 'prname')
        } else{
            df_map <- df_vac
            join_name <- c('woe-name', 'prename')
        }
        
        hcmap(
            'countries/ca/ca-all',
            data = df_map,
            value = input$total_record,
            name =  input$total_record,
            joinBy = join_name,
            dataLabels = list(enabled = TRUE, format = "{point.name}"),
            showInLegend = F
        ) %>%
            hc_title(text = paste(input$total_record, " by Province"))
    })
    
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)
        
        # draw the histogram with the specified number of bins
        hist(x,
             breaks = bins,
             col = 'darkgray',
             border = 'white')
        
    })
    
})

# shinyApp(ui = ui, server = server)
