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
    
    output$time_series_vac <-  renderPlotly({
        colnames(vaccines)[1] <- "date"
        if(input$vac_dose == "Partially vaccinated"){
            vaccines <- mutate(vaccines,dose = numtotal_partially)
        }else if(input$vac_dose == "Fully vaccinated"){
            vaccines <- mutate(vaccines,dose = numtotal_fully)
        }else{
            vaccines <- mutate(vaccines,dose = numtotal_additional)
        }
        
        df_vac2 <- vaccines  %>%
            mutate(date = lubridate::ymd(date)) %>%
            select(c(
                "date",
                "prename",
                "dose"
            ))
        
        if(length(input$area)>0){
            df_vac2 <- df_vac2 %>%
            filter(prename %in% input$area)
        
        plot <- df_vac2 %>%
        ggplot(aes(date, dose))  +
            geom_line(aes(group=prename, colour=prename))+ 
            labs(title = paste("Total ", input$vac_dose, " by Province"),
                 x = "Date",
                 y = "Number of doses",
                 color="Province name")
        
        require(scales)
        plot + scale_x_continuous(labels = comma)
        
        our_plotly_plot <- ggplotly(plot)
        return(our_plotly_plot)
        }
    })
    
})


