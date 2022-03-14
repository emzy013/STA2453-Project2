# STA2453-Project2
You can access the realtime COVID-19 dashboard here: https://emzy.shinyapps.io/STA2453-Project2-main/
Note that the graphs may take a few seconds to load initially.

## Data Source
The data comes from three files from Government of Canada's Public Health Infobase (https://health-infobase.canada.ca/). The data is pulled and accessed in the server.R file, where filtering/cleaning is also performed for each dashboard visual.

## Dashboard
The dashboard is created on R Shiny and hosted through shinyapps.io. It contains four main parts: 
1. An up-to-date summary of COVID-19 statistics by province, shown in a map of Canada.
2. A weekly time-series graph of vaccination status counts with sidebar options to show by vaccination status and area.
3. A weekly time-series graph of vaccination status in percentages, with sidebar options to show by area and population group.
4. Pie charts showing cases, hospitalizations, and deaths by vaccination status.

## Data Flow
The data is automatically pulled from the originating site, and is repulled each time the website is refreshed/reconnected. This means the dashboard updates at the same rate as the Government of Canada's Public Health Infobase.
