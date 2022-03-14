#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
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

# Define UI for application that draws a histogram
shinyUI(
    fluidPage(
        # Application title
        titlePanel("Realtime COVID-19 Vaccine Dashboard"),
        
        fluidRow(
          align = "center",
          selectInput(
            inputId = "total_record",
            label = "Provincial summaries:",
            selected = "Daily Cases",
            choices = c(
              "Total Deaths",
              "Total Tests",
              "Total Cases",
              "Total Partially Vaccinated",
              "Total Fully Vaccinated",
              "Total Third-Dose Vaccinated"
            )
          )
        ),
        
        fluidRow(highchartOutput("canadaMap")),

        sidebarLayout(
            sidebarPanel(
                selectInput(
                    inputId = "vac_dose",
                    label = "Which vaccination status do you want to see?",
                    selected = "Partially vaccinated",
                    choices = c(
                        "Partially Vaccinated",
                        "At Least 1-Dose Vaccinated",
                        "Fully Vaccinated",
                        "Third-Dose Vaccinated"
                    )
                ),
                checkboxGroupInput(
                    inputId = "area",
                    label = "Show for area(s)",
                    selected = "Canada",
                    choices = c(
                        "Canada",
                        "British Columbia",
                        "Alberta",
                        "Saskatchewan",
                        "Manitoba",
                        "Ontario",
                        "Quebec",
                        "New Brunswick",
                        "Nova Scotia",
                        "Newfoundland and Labrador",
                        "Prince Edward Island",
                        "Yukon",
                        "Northwest Territories",
                        "Nunavut"
                    )
                )
            ),
            
            mainPanel(highchartOutput("time_series_vac"))
        ),
        
        sidebarLayout(
            sidebarPanel(
                selectInput(
                    inputId = "area_percentage",
                    label = "Select area",
                    selected = "Canada",
                    choices = c(
                        "Canada",
                        "British Columbia",
                        "Alberta",
                        "Saskatchewan",
                        "Manitoba",
                        "Ontario",
                        "Quebec",
                        "New Brunswick",
                        "Nova Scotia",
                        "Newfoundland and Labrador",
                        "Prince Edward Island",
                        "Yukon",
                        "Northwest Territories",
                        "Nunavut"
                    )
                ),
                selectInput(
                    inputId = "age_group",
                    label = "Select age group",
                    selected = "People",
                    choices = c("Total Population",
                                "Population 18 and older",
                                "Population 5 and older")
                )
            ),
            
            mainPanel(highchartOutput("vac_percentage"))
        ),
        
        br(),
        
        fluidRow(
            splitLayout(
                cellWidths = c("33%", "33%", "33%"),
                highchartOutput("case_after_vac"),
                highchartOutput("case_after_vac2"),
                highchartOutput("case_after_vac3")
            )
            
        )
        
    )
)
