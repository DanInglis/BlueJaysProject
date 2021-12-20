# Blue Jays Project
Hello Blue Jays team, thank you for taking the time to review my project. 

I chose to do Project 3 – Batted Ball Data Visualizations.

I utilized R and an R package, [Shiny](https://shiny.rstudio.com/), to create a web application to explore batted ball data.

The application is hosted on an AWS EC2 server and is using RDS to run a MySQL database.


<br>

## Usage

Application is accessible at:
https://bluejays.daninglis.com/

Code is accessible at:
https://github.com/DanInglis/BlueJaysProject


### Spray Chart Tab
This is the main function of the application.

![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/SprayChart.JPG)


#### Player Selection
These menus enable batter & pitcher selection. Specific players/teams can be selected or selecting "All" will update the visualizations with all data available.

![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/PlayerSelect.JPG)

Note: these image URLs currently return a placeholder image due to ongoing MLB labor negotiations


#### Stadium Overlay
This option only updates the plot, it will not filter the data.

![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/StadiumOverlay.JPG)
![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/RogersCentre.JPG)


#### Additional Filters
These filters will restrict data to a timeframe or to specific launch conditions.
- As sample data is from 2017, many of the preset timeframe options will return no data
- Use the "Custom" option to edit the start and end dates

![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/AdditionalFilters.JPG)


#### Additional Visualizations
This dropdown menu contains 3 addition data visualizations
1. Pitch Location
	- Shows the exact location and pitch type
2. Pitch Location Heat Map
	- Renders a heat map of the pitch data
3. Spray Chart Heat Map
	- Renders a heat map of the batted ball location data

![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/AdditionalVisualizations.JPG)


### Raw Data Tab
This tab provides access to the raw data stored in the database.

![](https://raw.githubusercontent.com/DanInglis/BlueJaysProject/main/img/RawData.JPG)


<br>

## Set Up
While the application is accessible via https://bluejays.daninglis.com/, if you wish to run the application locally there are a few requirements.


### Database
A database to store the batted ball data is needed. While I utilized a MySQL database hosted on AWS RDS this is not required.

Database table definitions are accessible in [BuildDB.sql](https://github.com/DanInglis/BlueJaysProject/blob/main/BuildDB.sql)

Note: In this repository my RDS connection settings have been redacted in the code for privacy


### Python Script
[uploadBattedBalls.py](https://github.com/DanInglis/BlueJaysProject/blob/main/uploadBattedBalls.py) contians a script to read the batted ball data from ALWestBattedBalls2017.csv and uploads it to the database (assumes a database has already been created)

Usage: `python uploadBattedBalls.py`
Tested with Python version 3.8.7
Requirements:
1. pandas
2. mysql


### R Application
Requirements:
1. R
2. R Studio
3. Additional R Libraries: `cowplot, DT, ggplot2, grid, gtools, lubridate, magick, plotly, RMariaDB, rsvg, shiny, shinyBS, shinybusy, shinydashboard, shinyjs, shinyWidgets`
