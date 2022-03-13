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
shinyUI(fluidPage(
    # Application title
    titlePanel("Covide-19 data dashboard"),
    
    fluidRow(highchartOutput("canadaMap")),
    
    fluidRow(
        align = "center",
        selectInput(
            inputId = "total_record",
            label = "Select the information you want to know.",
            selected = "Daily Cases",
            choices = c(
                "Total Deaths",
                "Total Tests",
                "Total Cases",
                "Total Partially vaccinated",
                "Total Fully vaccinated",
                "Total Additional vaccinated"
            )
        )
    ),
    
    sidebarLayout(
        sidebarPanel(
            selectInput(
                inputId = "vac_dose",
                label = "which does of vaccine you want to know?",
                selected = "First Doses",
                choices = c("Partially vaccinated", "Fully vaccinated", "Additional vaccinated")
            ),
            checkboxGroupInput(
                inputId = "area",
                label = "show outcome plot",
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
        
        mainPanel(plotlyOutput("time_series_vac"))
    )
    
    
))
