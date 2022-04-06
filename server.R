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
library(tidyverse)


#Download dataset of covid-19
cases_link_1 <-
    "https://health-infobase.canada.ca/src/data/covidLive/covid19-download.csv"
full_cases <- read.csv(url(cases_link_1))

vaccines_link_1 <-
    "https://health-infobase.canada.ca/src/data/covidLive/vaccination-coverage-map.csv"
vaccines <- read.csv(url(vaccines_link_1))
colnames(vaccines)[1] <- "Date"
vaccines$prop18plus_atleast1dose[vaccines$prop18plus_atleast1dose == ">=99"] <-
    "99"
vaccines[vaccines == 0] <- 0.000001
vaccines$proptotal_fully[vaccines$proptotal_fully == "<0.01"] <- "0.000001"

total_vac <- vaccines %>%
    tail(., n = 14) %>%
    filter(prename == "Canada")


vaccines_link_2 <-
    "https://health-infobase.canada.ca/src/data/covidLive/covid19-epiSummary-casesAfterVaccination.csv"
vaccines2 <- read.csv(url(vaccines_link_2)) %>%
    select("label.en",
           "prop_cases",
           "prop_hospitalizations",
           "prop_deaths")


# Define server logic
shinyServer(function(session, input, output) {
    
    #Provincial Summary Map
    output$canadaMap <- renderHighchart({
        df_cases <- full_cases %>%
            select(c("prname", "numdeathstoday", "numtests", "numtoday")) %>%
            group_by(prname) %>%
            mutate(prname = replace(prname, prname == "Quebec", "Québec")) %>%
            dplyr::filter(prname != "Repatriated travellers" &&
                              prname != "Canada") %>%
            summarise(
                "Total Deaths" = sum(numdeathstoday),
                "Total Tests" = sum(numtests),
                "Total Cases" = sum(numtoday)
            )
        
        df_vac <- vaccines  %>%
            tail(., n = 14) %>%
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
                "Total Third-Dose Vaccinated" = numtotal_additional
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
            showInLegend = F,
            dataLabels = list(enabled = TRUE, format = "{point.name}")
        ) %>%
            hc_title(text = paste(input$total_record, " by Province"))
    })
    
    #Provincial Comparison Time Series Chart
    output$time_series_vac <-  renderHighchart({
        colnames(vaccines)[1] <- "Date"
        if (input$vac_option == "Population Count") {
            if (input$vac_dose == "Partially Vaccinated") {
                vaccines <- mutate(vaccines, dose = numtotal_partially)
            } else if (input$vac_dose == "At Least 1-Dose Vaccinated") {
                vaccines <- mutate(vaccines, dose = numtotal_atleast1dose)
            } else if (input$vac_dose == "Fully Vaccinated") {
                vaccines <- mutate(vaccines, dose = numtotal_fully)
            } else{
                vaccines <- mutate(vaccines, dose = numtotal_additional)
            }
        } else{
            if (input$vac_dose == "Partially Vaccinated") {
                vaccines <- mutate(vaccines, dose = proptotal_partially)
            } else if (input$vac_dose == "At Least 1-Dose Vaccinated") {
                vaccines <- mutate(vaccines, dose = proptotal_atleast1dose)
            } else if (input$vac_dose == "Fully Vaccinated") {
                vaccines <- mutate(vaccines, dose = proptotal_fully)
            } else{
                vaccines <- mutate(vaccines, dose = proptotal_additional)
            }
        }
        
        
        df_vac2 <- vaccines  %>%
            mutate(Date = lubridate::ymd(Date)) %>%
            select(c("Date",
                     "prename",
                     "dose"))
        
        if (length(input$area) > 0) {
            df_vac2 <- df_vac2 %>%
                filter(prename %in% input$area)
            
            
            plot <- df_vac2 %>%
                hchart(., "line",
                       hcaes(
                           x = Date,
                           y = dose,
                           group = prename
                       )) %>%
                hc_yAxis(title = list(text = input$vac_option)) %>%
                hc_title(text = paste("Total ", input$vac_dose, " by Province"))
            
            return(plot)
        }
    })
    
    #Vaccination Percentages Time Series Chart
    output$vac_percentage <-  renderHighchart({
        if (input$age_group == "Total Population") {
            temp <- vaccines  %>%
                mutate(
                    proptotal_atleast1dose = as.numeric(proptotal_atleast1dose),
                    proptotal_partially = as.numeric(proptotal_partially),
                    proptotal_fully = as.numeric(proptotal_fully),
                    proptotal_additional = as.numeric(proptotal_additional)
                )
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
            mutate(Date = lubridate::ymd(Date)) %>%
            select(
                c(
                    "Date",
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
                       x = Date,
                       y = proptotal_atleast1dose,
                       group = prename
                   ),
                   name  = "At Least 1 Dose") %>%
            hc_add_series(df_vac3,
                          "line",
                          hcaes(
                              x = Date,
                              y = proptotal_partially,
                              group = prename
                          ),
                          name  = "Partially Vaccinated") %>%
            hc_add_series(df_vac3,
                          "line",
                          hcaes(
                              x = Date,
                              y = proptotal_fully,
                              group = prename
                          ),
                          name  = "Fully Vaccinated") %>%
            hc_add_series(
                df_vac3,
                "line",
                hcaes(
                    x = Date,
                    y = proptotal_additional,
                    group = prename
                ),
                name  = "Third-Dose Vaccinated"
            ) %>%
            hc_yAxis(
                title = list(text = "Percentage"),
                tickInterval = 25,
                min = 0,
                max = 100
            ) %>%
            hc_title(
                text = paste(
                    "Vaccination Percentages of ",
                    input$age_group,
                    " in ",
                    input$area_percentage
                )
            )
        return(plot)
    })
    
    #Pie Charts by Vaccination Status
    output$case_after_vac <-  renderHighchart({
        plot <- vaccines2 %>%
            hchart("pie", hcaes(x = "label.en", y = "prop_cases"),
                   name = "Cases Percentage") %>%
            hc_title(text = "Cases")
        
        return(plot)
    })
    
    output$case_after_vac2 <-  renderHighchart({
        plot <- vaccines2 %>%
            hchart("pie",
                   hcaes(x = "label.en", y = "prop_hospitalizations"),
                   name = "Hospitalizations Percentage") %>%
            hc_title(text = "Hospitalizations")
        
        return(plot)
    })
    
    output$case_after_vac3 <-  renderHighchart({
        plot <- vaccines2 %>%
            hchart("pie", hcaes(x = "label.en", y = "prop_deaths"),
                   name = "Deaths Percentage") %>%
            hc_title(text = "Deaths")
        
        return(plot)
    })
    
    
    #Summary of Vaccination status in Canada
    output$at_least_one_dose <- renderValueBox({
        valueBox(total_vac$numtotal_atleast1dose[1],
                 "At Least 1-Dose Vaccinated",
        )
    })
    
    output$total_partially <- renderValueBox({
        valueBox(total_vac$numtotal_partially[1],
                 "Partially Vaccinated",
        )
    })
    
    output$total_fully <- renderValueBox({
        valueBox(total_vac$numtotal_fully[1],
                 "Fully Vaccinated", )
    })
    
    output$total_additional <- renderValueBox({
        valueBox(total_vac$numtotal_additional[1],
                 "Third-Dose Vaccinated",
        )
    })
    
})
