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
colnames(vaccines)[1] <- "date"
vaccines$prop18plus_atleast1dose[vaccines$prop18plus_atleast1dose == ">=99"] <-
    "99"

vaccines_link_2 <-
    "https://health-infobase.canada.ca/src/data/covidLive/covid19-epiSummary-casesAfterVaccination.csv"
vaccines2 <- read.csv(url(vaccines_link_2)) %>%
    select("label.en",
           "prop_cases",
           "prop_hospitalizations",
           "prop_deaths")


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
                "Total Partially Vaccinated" = numtotal_partially,
                "Total Fully Vaccinated" = numtotal_fully,
                "Total Additional Vaccinated" = numtotal_additional
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
    
    output$time_series_vac <-  renderHighchart({
        colnames(vaccines)[1] <- "date"
        if (input$vac_dose == "Partially Vaccinated") {
            vaccines <- mutate(vaccines, dose = numtotal_partially)
        } else if (input$vac_dose == "At Least 1-Dose Vaccinated") {
            vaccines <- mutate(vaccines, dose = proptotal_atleast1dose)
        } else if (input$vac_dose == "Fully Vaccinated") {
            vaccines <- mutate(vaccines, dose = numtotal_fully)
        } else{
            vaccines <- mutate(vaccines, dose = numtotal_additional)
        }
        
        df_vac2 <- vaccines  %>%
            mutate(date = lubridate::ymd(date)) %>%
            select(c("date",
                     "prename",
                     "dose"))
        
        if (length(input$area) > 0) {
            df_vac2 <- df_vac2 %>%
                filter(prename %in% input$area)
            
            
            plot <- df_vac2 %>%
                hchart(., "line",
                       hcaes(
                           x = date,
                           y = dose,
                           group = prename
                       )) %>%
                hc_title(text = paste("Total ", input$vac_dose, " by Province"))
            
            return(plot)
        }
    })
    
    output$vac_percentage <-  renderHighchart({
        # colnames(vaccines)[1] <- "date"
        # vaccines$prop18plus_atleast1dose[vaccines$prop18plus_atleast1dose ==">=99"] <- "99"
        if (input$age_group == "Total Population") {
            temp <- vaccines
        } else if (input$age_group == "Population 18 and older") {
            temp <- vaccines  %>%
                mutate(
                    proptotal_atleast1dose = as.numeric(prop18plus_atleast1dose),
                    proptotal_partially = prop18plus_partially,
                    proptotal_fully = prop5plus_fully,
                    proptotal_additional = prop5plus_additional
                )
        } else if (input$age_group == "Population 5 and older") {
            temp <- vaccines  %>%
                mutate(
                    proptotal_atleast1dose = prop5plus_atleast1dose,
                    proptotal_partially = prop5plus_partially,
                    proptotal_fully = prop5plus_fully,
                    proptotal_additional = prop5plus_additional
                )
        }
        
        df_vac3 <- temp  %>%
            mutate(date = lubridate::ymd(date)) %>%
            select(
                c(
                    "date",
                    "prename",
                    "proptotal_atleast1dose",
                    "proptotal_partially",
                    "proptotal_fully",
                    "proptotal_additional"
                )
            )
        
        df_vac3 <- df_vac3 %>%
            filter(prename == input$area_percentage)
        
        plot <- df_vac3 %>%
            hchart(.,
                   "line",
                   hcaes(
                       x = date,
                       y = proptotal_atleast1dose,
                       group = prename
                   ),
                   name  = "At Least 1 Dose") %>%
            hc_add_series(df_vac3,
                          "line",
                          hcaes(
                              x = date,
                              y = proptotal_partially,
                              group = prename
                          ),
                          name  = "Partially Vaccinated") %>%
            hc_add_series(df_vac3,
                          "line",
                          hcaes(
                              x = date,
                              y = proptotal_fully,
                              group = prename
                          ),
                          name  = "Fully Vaccinated") %>%
            hc_add_series(
                df_vac3,
                "line",
                hcaes(
                    x = date,
                    y = proptotal_additional,
                    group = prename
                ),
                name  = "Fully Vaccinated with an Additional Dose"
            ) %>%
            hc_yAxis(
                title = list(text = "Percentage"),
                tickInterval = 25,
                min = 0,
                max = 100
            ) %>%
            hc_title(
                text = paste(
                    "Vaccinated Percentage of ",
                    input$age_group,
                    " in ",
                    input$area_percentage
                )
            )
        return(plot)
    })
    
    
    output$case_after_vac <-  renderHighchart({
        plot <- vaccines2 %>%
            hchart("pie", hcaes(x = "label.en", y = "prop_cases"),
                   name = "Number of Cases") %>%
            hc_title(text = "Cases")
        
        return(plot)
    })
    
    output$case_after_vac2 <-  renderHighchart({
        plot <- vaccines2 %>%
            hchart("pie",
                   hcaes(x = "label.en", y = "prop_hospitalizations"),
                   name = "Number of Cases") %>%
            hc_title(text = "Hospitalizations")
        
        return(plot)
    })
    
    output$case_after_vac3 <-  renderHighchart({
        plot <- vaccines2 %>%
            hchart("pie", hcaes(x = "label.en", y = "prop_deaths"),
                   name = "Number of Cases") %>%
            hc_title(text = "Deaths")
        
        return(plot)
    })
    
    
    
})
