# Dan Inglis
# Blue Jays Baseball Systems Developer Project
# server.R is responsible for implementing all functions used in the application

library(shiny)
library(RMariaDB)
library(ggplot2)
library(grid)
library(plotly)
library(shinyBS)
library(shinyjs)
library(lubridate)
library(magick)
library(cowplot)
library(gtools)
library(rsvg)
library(DT)

# Options for connecting to AWS Database
options(mysql = list(
    "host" = "blue-jays-baseball-systems-developer.*****.us-east-1.rds.amazonaws.com",
    "port" = 3306,
    "user" = "admin",
    "password" = "*****"
))
databaseName <- "bluejays"

# Definining Global DB Variable
DB <- dbConnect(RMariaDB::MariaDB(), dbname = databaseName, host = options()$mysql$host, 
    port = options()$mysql$port, user = options()$mysql$user, 
    password = options()$mysql$password)

# Global Variable for Result Types
RESULT_TYPES <- c("balk", "catcher_interf", "double", "double_play", "field_error", "field_out", "fielders_choice", "fielders_choice_out", "force_out", "grounded_into_double_play", "hit_by_pitch", "home_run", "sac_bunt", "sac_fly", "sac_fly_double_play", "single", "triple", "walk")

# Global Variable for Pitch Types
PITCH_TYPES <- c("CH", "CU", "FC", "FF", "FS", "FT", "IN", "KC", "nan", "SI", "SL")

# reactiveValues object to store spray chart data
battedballData <- reactiveValues()
battedballData$DT <- data.frame(x = numeric(), y = numeric(), color = factor())

# reactiveValues object to store pitch location data
pitchLocationData <- reactiveValues()
pitchLocationData$DT <- data.frame(x = numeric(), y = numeric(), color = factor())

# Dataframes to cache data
cachedSprayData <- reactiveValues()
cachedSprayData$DT <- data.frame(x = numeric(), y = numeric(), color = factor())
cachedPitchData <- reactiveValues()
cachedPitchData$DT <- data.frame(x = numeric(), y = numeric(), color = factor())

# Global Variables to save Exit Velocity and Launch Angle ranges
# Will get updated once, then never changed again
MIN_EXIT_VELO <- 0
MAX_EXIT_VELO <- 0
MIN_LAUNCH_ANGLE <-0
MAX_LAUNCH_ANGLE <-0

# Gets teams that exist in the database
# Note: would contain all teams with a large enough dataset
getTeamList <- function(){
    # get list of home team names and IDs
    query <- paste0("SELECT DISTINCT hometeamid AS teamid, hometeamname AS teamname FROM battedball")
    hometeams <- dbGetQuery(DB, query)

    # get list of away team names and IDs
    query <- paste0("SELECT DISTINCT awayteamid AS teamid, awayteamname AS teamname FROM battedball")
    awayteams <- dbGetQuery(DB, query)

    # merge lists to create teams list
    teams <- merge(hometeams, awayteams)

    return(teams)
}


# Given a team name, returns the team's ID
getTeamID <- function(team){
    # If no team is selected, do not try to get ID
    if (is.na(team) || team == ""){ return() }

    # First get team's ID using hometeam
    query <- paste0("SELECT DISTINCT hometeamid AS teamid FROM battedball WHERE hometeamname = '", team, "'")
    teamid <- dbGetQuery(DB, query)

    # If team ID was found, return ID
    if (nrow(teamid) != 0){ return(teamid) }

    # If no team ID was found using hometeam, query again using awayteam
    query <- paste0("SELECT DISTINCT awayteamid AS teamid FROM battedball WHERE awayteamname = '", team, "'")
    teamid <- dbGetQuery(DB, query)

    # If team ID was found, return ID
    if (nrow(teamid) != 0){ return(teamid) }

    # No team ID was found, return nothing
    return()
}


# Given a batter's name, returns their ID
getBatterID <- function(batter){
    query <- paste0("SELECT DISTINCT batterid FROM battedball WHERE battername = '", batter, "'")
    bID <- dbGetQuery(DB, query)
    return(bID)   
}


# Given a pitchers's name, returns their ID
getPitcherID <- function(pitcher){
    query <- paste0("SELECT DISTINCT pitcherid FROM battedball WHERE pitchername = '", pitcher, "'")
    pID <- dbGetQuery(DB, query)
    return(pID)    
}


# Given team gets batters that exist in the database
# Note: could use https://statsapi.mlb.com/api/v1/teams/ID/roster to retrieve rosters
# as data set is small, chose to only include batters that have batted ball data
getBatterList <- function(team){
    # If 'All' is selected, return all batters
    if (team == "All"){
        query <- paste0("SELECT DISTINCT battername FROM battedball")
        batters <- dbGetQuery(DB, query)
        return(sort(batters$battername))
    }

    # Get team's ID
    teamid <- getTeamID(team)
    
    # Check a valid ID was found
    if (is.null(teamid)){ return() } 

    # Get list of batters for this team
    query <- paste0("SELECT DISTINCT battername FROM battedball WHERE batterteamid = '", teamid, "'")
    batters <- dbGetQuery(DB, query)

    return(sort(batters$battername))
}


# Given team gets pitchers that exist in the database
# Note: could use https://statsapi.mlb.com/api/v1/teams/ID/roster to retrieve rosters
# as data set is small, chose to only include pitchers that have batted ball data
getPitcherList <- function(team){
    # If 'All' is selected, return all pitchers
    if (team == "All"){
        query <- paste0("SELECT DISTINCT pitchername FROM battedball")
        pitchers <- dbGetQuery(DB, query)
        return(sort(pitchers$pitchername))
    }

    # Get team's ID
    teamid <- getTeamID(team)
    
    # Check a valid ID was found
    if (is.null(teamid)){ return() } 

    # Get list of pitchers for this team
    query <- paste0("SELECT DISTINCT pitchername FROM battedball WHERE pitcherteamid = '", teamid, "'")
    pitchers <- dbGetQuery(DB, query)

    return(sort(pitchers$pitchername))
}


# Gets stadiums that exist in the database
# Note: would contain all stadiums with a large enough dataset
# Could also use the 'venues' endpoint (/api/v1/venues)
getStadiumList <- function(){
    query <- paste0("SELECT DISTINCT park FROM battedball")
    stadiums <- dbGetQuery(DB, query)
    return(sort(stadiums$park))    
}

# Given a stadium's name, find ID for image
getStadiumID <- function(stadium){
    query <- paste0("SELECT DISTINCT parkid FROM battedball WHERE park = '", stadium, "'")
    park <- dbGetQuery(DB, query)
    return(park$parkid)
}


# Given a stadium, render spray chart
renderPlots <- function(output, stadium){
    # Get ID
    stadiumID <- getStadiumID(stadium)

    # Hard coding Roger Centre ID
    if (stadium == "Rogers Centre") stadiumID <- 14

    # Render Spray Chart
    output$urlimage <- renderPlot({
        p <- ggplot(battedballData$DT, aes(x = x, y = y)) +
                geom_point(aes(color = color), size = 3) +
                scale_x_continuous(limits = c(-350, 350), expand = c(0,0)) +
                scale_y_continuous(limits = c(-120, 500), expand = c(0,0)) +
                coord_fixed() + 
                theme_void() +
                theme(legend.position = "none")

        # Creating another plot with the same data to copy the legend
        # This is done to avoid the legend changing the alignment with the field image
        pCopy <- ggplot(battedballData$DT, aes(x = x, y = y)) +
                geom_point(aes(color = color), size = 3)
        legend <- get_legend(pCopy) 

        # Draw selected field, batted ball data & legend
        ggdraw() + draw_image(image_read_svg(paste0("https://prod-gameday.mlbstatic.com/responsive-gameday-assets/1.2.0/images/fields/",stadiumID,".svg"))) + draw_plot(p) + draw_plot(plot_grid(NULL, legend, ncol=2, align='v', rel_widths=c(1, 0.2)))
    })

    # Render Heat Map
    output$sprayMapOutput <- renderPlot({
        p <- ggplot(battedballData$DT, aes(x = x, y = y)) +
                stat_density_2d(aes(fill = ..level.., alpha = ..level..), geom = "polygon", bins = 50) + 
                #geom_point(aes(color = color), size = 3) +
                scale_x_continuous(limits = c(-350, 350), expand = c(0,0)) +
                scale_y_continuous(limits = c(-120, 500), expand = c(0,0)) +
                coord_fixed() +
                theme_void() +
                theme(legend.position = "none")

        ggdraw() + draw_image(image_read_svg(paste0("https://prod-gameday.mlbstatic.com/responsive-gameday-assets/1.2.0/images/fields/",stadiumID,".svg"))) + draw_plot(p)
    })

    # Render Strike Zone
    output$strikeZoneOutput <- renderPlot({

        # Not Completed: 
        # If a specific batter is selected, get strike zone height from API
        # https://statsapi.mlb.com/api/v1/people/ID
        # bID <- getBatterID(input$sprayBatter)

        # Default to George Springer's zone
        strikeZoneTop <- 3.49
        strikeZoneBottom <- 1.601

        # Assuming strike zone width of 1
        strikeZoneLeft <- -0.5
        strikeZoneRight <- 0.5 

        p <- ggplot(pitchLocationData$DT, aes(x = x, y = y)) +
            geom_point(aes(color = color), size = 3) + 
            scale_x_continuous(limits = c(-2, 2), expand = c(0,0)) +
            scale_y_continuous(limits = c(-1, 6), expand = c(0,0)) +
            coord_fixed() +
            theme_void() +
            theme(legend.position = "none") +

            # Drawing Strikezone
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneLeft, y=strikeZoneBottom, xend=strikeZoneRight, yend=strikeZoneBottom), color = "black") +  # Bottom Line
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneLeft, y=strikeZoneTop, xend=strikeZoneRight, yend=strikeZoneTop), color = "black") +        # Top Line
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneLeft, y=strikeZoneBottom, xend=strikeZoneLeft, yend=strikeZoneTop), color = "black") +      # Left Line
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneRight, y=strikeZoneBottom, xend=strikeZoneRight, yend=strikeZoneTop), color = "black")      # Right Line

        
        # Creating another plot with the same data to copy the legend
        # This is done to avoid the legend changing the alignment with the field image
        pCopy <- ggplot(pitchLocationData$DT, aes(x = x, y = y)) +
                geom_point(aes(color = color), size = 3)
        legend <- get_legend(pCopy) 

        # Draw selected field, batted ball data & legend
        ggdraw() + draw_plot(p) + draw_plot(plot_grid(NULL, legend, ncol=2, align='v', rel_widths=c(1, 0.1)))
    })

    # Render Strike Zone Heat Map
    output$strikeZoneMapOutput <- renderPlot({

        # Default to George Springer's zone
        strikeZoneTop <- 3.49
        strikeZoneBottom <- 1.601

        # Assuming strike zone width of 1
        strikeZoneLeft <- -0.5
        strikeZoneRight <- 0.5 

        p <- ggplot(pitchLocationData$DT, aes(x = x, y = y)) +
            stat_density_2d(aes(fill = ..level.., alpha = ..level..), geom = "polygon", bins = 10) + 
            #geom_point(aes(color = color), size = 3) + 
            scale_x_continuous(limits = c(-2, 2), expand = c(0,0)) +
            scale_y_continuous(limits = c(-1, 6), expand = c(0,0)) +
            coord_fixed() +
            theme_void() +
            theme(legend.position = "none") +

            # Drawing Strikezone
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneLeft, y=strikeZoneBottom, xend=strikeZoneRight, yend=strikeZoneBottom), color = "black") +  # Bottom Line
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneLeft, y=strikeZoneTop, xend=strikeZoneRight, yend=strikeZoneTop), color = "black") +        # Top Line
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneLeft, y=strikeZoneBottom, xend=strikeZoneLeft, yend=strikeZoneTop), color = "black") +      # Left Line
            geom_segment(data=pitchLocationData$DT, mapping=aes(x=strikeZoneRight, y=strikeZoneBottom, xend=strikeZoneRight, yend=strikeZoneTop), color = "black")      # Right Line

        ggdraw() + draw_plot(p)
    })
}

# Given query restrictions, find range of Exit Velo and Launch Angle and update choices
updateEVandLA <- function(session){ 
    # Get the min & max for each based on batted ball data in the database
    query <- paste0("SELECT MIN(launch_speed), MAX(launch_speed), MIN(launch_vert_ang), MAX(launch_vert_ang) FROM battedball")

    # Execute SQL Query
    print(paste("updateEVandLA:", query))
    result <- dbGetQuery(DB, query)

    # Checking that results were found
    if(nrow(result) != 0){
        MIN_EXIT_VELO <<- result[1][[1]]
        MAX_EXIT_VELO <<- result[2][[1]]
        MIN_LAUNCH_ANGLE <<- result[3][[1]]
        MAX_LAUNCH_ANGLE <<- result[4][[1]]

        # Update input sliders
        updateSliderInput(session, "exitVeloSlider", label = "Exit Velocity", min = MIN_EXIT_VELO, max = MAX_EXIT_VELO, value = MAX_EXIT_VELO)
        updateSliderInput(session, "launchAngleSlider", label = "Launch Angle", min = MIN_LAUNCH_ANGLE, max = MAX_LAUNCH_ANGLE, value = MAX_LAUNCH_ANGLE)
    }
}


# Given a partial query, retrieve from DB and update batted ball dataframe
processSprayChartQuery <- function(queryFilters){

    # Combine base query with the restrictions from the UI elements
    baseQuery <- paste0("SELECT landing_location_x, landing_location_y, result_type, launch_speed, launch_vert_ang, pitch_type, zone_location_x, zone_location_z FROM battedball")
    query <- paste(baseQuery, queryFilters)

    # Execute SQL Query
    print(paste("processSprayChartQuery:", query))
    result <- dbGetQuery(DB, query)

    print(paste("processSprayChartQuery: Rows Returned:", nrow(result)))

    # Checking that results were found
    if(nrow(result) != 0){
        # Iterate through each row of results and add data to batted ball dataframe
        for (i in 1:nrow(result)){
            landing_location_x <- result[i,][[1]]
            landing_location_y <- result[i,][[2]]
            result_type <- result[i,][[3]]
            launch_speed <- result[i,][[4]]
            launch_vert_ang <- result[i,][[5]]
            pitch_type <- result[i,][[6]]
            zone_location_x <- result[i,][[7]]
            zone_location_z <- result[i,][[8]]

            add_point <- data.frame(x = landing_location_x, y = landing_location_y, color = factor(result_type, levels = c(RESULT_TYPES)))
            battedballData$DT <- rbind(battedballData$DT, add_point)

            add_point <- data.frame(x = zone_location_x, y = zone_location_z, color = factor(pitch_type, levels = c(PITCH_TYPES)))
            pitchLocationData$DT <- rbind(pitchLocationData$DT, add_point)
        }
    }
    else{
        # Add empty point to prevent rendering error
        add_point <- data.frame(x = 0, y = -500, color = factor("Empty", levels = "Empty"))
        battedballData$DT <- rbind(battedballData$DT, add_point)

        add_point <- data.frame(x = 0, y = 0, color = factor("Empty", levels = "Empty"))
        pitchLocationData$DT <- rbind(pitchLocationData$DT, add_point)
    }

    return()
}


# Query Database and Refresh the spray chart
refreshPlots <- function(session, input){
    # Clear Data from previous query
    battedballData$DT <- NULL
    pitchLocationData$DT <- NULL

    # If all data is being requested; query db for all data then cache the dataframes
    if(input$sprayBatterTeam == "All" && input$sprayBatter == "All" && input$sprayPitcherTeam == "All" && input$sprayPitcher == "All" && input$timeframe == "all" && input$exitVeloSlider == MAX_EXIT_VELO && input$launchAngleSlider == MAX_LAUNCH_ANGLE){
        # If data has been cached; load cached data and return
        if (nrow(cachedSprayData$DT) != 0){
            battedballData$DT <- cachedSprayData$DT
            pitchLocationData$DT <- cachedPitchData$DT
            return()
        }

        # Data has not been cached; make query for all data and saved the dataframes
        queryFilters <- ""
        processSprayChartQuery(queryFilters)

        # Global Variables have been updated; Cache data
        cachedSprayData$DT <- battedballData$DT
        cachedPitchData$DT <- pitchLocationData$DT
        return()
    }

    # Generate query based on input
    queryFilters <- paste0("WHERE gamedate BETWEEN '", input$timeframeStartDate, "' AND '", input$timeframeEndDate, "'")

    # If batter is specified, no need to use batter's team
    if(input$sprayBatter != "All"){ queryFilters <- paste0(queryFilters, " AND batterid = ", getBatterID(input$sprayBatter)) }
    else if(input$sprayBatterTeam != "All"){ queryFilters <- paste0(queryFilters, " AND batterteamid = ", getTeamID(input$sprayBatterTeam)) }
    
    # If pitcher is specified, no need to use pitcher's team
    if(input$sprayPitcher != "All"){ queryFilters <- paste0(queryFilters, " AND pitcherid = ", getPitcherID(input$sprayPitcher)) }
    else if(input$sprayPitcherTeam != "All"){ queryFilters <- paste0(queryFilters, " AND pitcherteamid = ", getTeamID(input$sprayPitcherTeam)) }

    # Exit Velocity & Launch Angle Filters
    if(!is.null(input$exitVeloSlider)){  queryFilters <- paste0(queryFilters, " AND launch_speed <= ", toString(input$exitVeloSlider)) }
    if(!is.null(input$launchAngleSlider)){  queryFilters <- paste0(queryFilters, " AND launch_vert_ang <= ", toString(input$launchAngleSlider)) }

    print(paste("refreshPlots:", queryFilters))
    processSprayChartQuery(queryFilters)
}


# Get all data for player data tab and update table
playerDataQuery <- function(input, output){
    # Generate query based on input
    queryFilters <- ""
    
    # If batter is specified, no need to use batter's team
    if(input$dataBatter != "All"){ queryFilters <- paste0(queryFilters, " WHERE batterid = ", getBatterID(input$dataBatter)) }
    else if(input$dataBatterTeam != "All"){ queryFilters <- paste0(queryFilters, " WHERE batterteamid = ", getTeamID(input$dataBatterTeam)) }
    
    # Determine if "WHERE" or "AND" in query is needed
    if((input$dataBatter != "All" || input$dataBatterTeam != "All") && (input$dataPitcher != "All" || input$dataPitcherTeam != "All") ) { queryFilters <- paste0(queryFilters, " AND") }
    else if(input$dataPitcher != "All" || input$dataPitcherTeam != "All") { queryFilters <- paste0(queryFilters, " WHERE") }

    # If pitcher is specified, no need to use pitcher's team
    if(input$dataPitcher != "All"){ queryFilters <- paste0(queryFilters, " pitcherid = ", getPitcherID(input$dataPitcher)) }
    else if(input$dataPitcherTeam != "All"){ queryFilters <- paste0(queryFilters, " pitcherteamid = ", getTeamID(input$dataPitcherTeam)) }

    baseQuery <- paste0("SELECT * FROM battedball")
    query <- paste0(baseQuery, queryFilters)
    print(query)
    result <- dbGetQuery(DB, query)

    # Checking that results were found
    if(nrow(result) != 0){
        output$playerDataTable = DT::renderDataTable({
            DT::datatable({result},
                extensions = c('Scroller'),
                options = list(scroller = TRUE, scrollY = 400),
                fillContainer = TRUE
            )
        })
    }
}


# Main server function
server <- function(input, output, session){

    output$BlueJaysLogo <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/141.svg", height = '50px', width = '50px') })
    output$batterTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })
    output$pitcherTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })

    # Update list of teams
    teams <- getTeamList()
    updateSelectInput(session, "sprayBatterTeam", label = "Batter Team", choices = c("All", teams$teamname))
    updateSelectInput(session, "sprayPitcherTeam", label = "Pitcher Team", choices = c("All", teams$teamname))

    # Update list of stadiums
    updateSelectInput(session, "stadium", label = "Stadium Overlay", choices = c("Rogers Centre", getStadiumList()), selected = "Rogers Centre")

    # Update Exit Velo and Launch Angle sliders
    updateEVandLA(session)

    # Setting up Spray Chart output
    output$sprayChartOutput = renderUI({
        plotOutput("urlimage", click=clickOpts(id="sprayClick"))
    })   

    observeEvent(input$sprayClick, {
        print(input$sprayClick)
    })



    # Create a reactive expression to update plot when input is changed
    updateSprayChart <- reactive({ list(input$sprayBatterTeam, input$sprayBatter, input$sprayPitcherTeam, input$sprayPitcher, input$timeframeStartDate, input$timeframeEndDate, input$exitVeloSlider, input$launchAngleSlider) }) # potentially add input$stadium

    # Triggered when an input is changed; update spray chart with new data
    observeEvent(updateSprayChart(), {
        # If no values selected, skip query (occurs during startup)
        if(input$sprayBatterTeam == "" && input$sprayBatter == "" && input$sprayPitcherTeam == "" && input$sprayPitcher == ""){ return() }

        # Not all data has been selected. Query Database & refresh
        refreshPlots(session, input)
    })


    #########Observers#########

    # Triggered when a new team is selected
    observeEvent(input$sprayBatterTeam, {        
        batters <- getBatterList(input$sprayBatterTeam)
        updateSelectInput(session, "sprayBatter", label = "Batter", choices = c("All", batters))

        # Update Team Picture
        if (input$sprayBatterTeam == "All") output$batterTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })
        else output$batterTeamImage <- renderUI({ tags$img(src = paste0("https://www.mlbstatic.com/team-logos/",getTeamID(input$sprayBatterTeam),".svg"), height = '50px') })
    })

    # Triggered when a new team is selected
    observeEvent(input$sprayPitcherTeam, {
        pitchers <- getPitcherList(input$sprayPitcherTeam)
        updateSelectInput(session, "sprayPitcher", label = "Pitcher", choices = c("All", pitchers))

        # Update Team Picture
        if (input$sprayPitcherTeam == "All") output$pitcherTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })
        else output$pitcherTeamImage <- renderUI({ tags$img(src = paste0("https://www.mlbstatic.com/team-logos/",getTeamID(input$sprayPitcherTeam),".svg"), height = '50px') })
    })

    # Triggered when a new batter is selected
    observeEvent(input$sprayBatter, {
        bID <- getBatterID(input$sprayBatter)

        # Update Batter Headshot
        if (input$sprayBatter != "All") output$batterImage <- renderUI({ tags$img(src = paste0("https://img.mlbstatic.com/mlb-photos/image/upload/w_60,q_100/v1/people/",bID,"/headshot/silo/current"), height = '50px') })
        else output$batterImage <- NULL
    })

    # Triggered when a new pitcher is selected
    observeEvent(input$sprayPitcher, {
        pID <- getPitcherID(input$sprayPitcher)

        # Update Pitcher Headshot
        if (input$sprayPitcher != "All") output$pitcherImage <- renderUI({ tags$img(src = paste0("https://img.mlbstatic.com/mlb-photos/image/upload/w_60,q_100/v1/people/",pID,"/headshot/silo/current"), height = '50px') })
        else output$pitcherImage <- NULL
    })

    # Triggered when a new stadium is selected
    observeEvent(input$stadium, {
        renderPlots(output, input$stadium)
    })

    # Triggered when timeframe is changed
    observeEvent(input$timeframe, {
        # Only allow editing of timeframe if custom is selected
        if (input$timeframe == "custom"){
            shinyjs::enable("timeframeStartDate")
            shinyjs::enable("timeframeEndDate")
        }
        else {
            shinyjs::disable("timeframeStartDate")
            shinyjs::disable("timeframeEndDate")
        }

        Sys.setenv(TZ='EST')    # Force timezone to eastern
        curDate <- Sys.Date()
        # Updating start and end date according to timeframe selected
        if (input$timeframe == "today"){
            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = curDate, min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = curDate, min = NULL, max = NULL)
        }
        else if (input$timeframe == "week"){
            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = curDate - 7, min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = curDate, min = NULL, max = NULL)
        }
        else if (input$timeframe == "month"){
            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = curDate %m-% months(1), min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = curDate, min = NULL, max = NULL)
        }
        else if (input$timeframe == "3months"){
            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = curDate %m-% months(3), min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = curDate, min = NULL, max = NULL)
        }
        else if (input$timeframe == "6months"){
            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = curDate %m-% months(6), min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = curDate, min = NULL, max = NULL)
        }
        else if (input$timeframe == "year"){
            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = curDate %m-% months(12), min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = curDate, min = NULL, max = NULL)
        }
        else if (input$timeframe == "all"){
            # Query for earliest and latest games
            query <- paste0("SELECT MIN(gamedate), MAX(gamedate) FROM battedball")
            dateRange <- dbGetQuery(DB, query)

            # Extract dates from query response
            minDate = as_date(dateRange[1][[1]])
            maxDate = as_date(dateRange[2][[1]])

            updateDateInput(session, "timeframeStartDate", label = "Start Date", value = minDate, min = NULL, max = NULL)
            updateDateInput(session, "timeframeEndDate", label = "End Date", value = maxDate, min = NULL, max = NULL)
        }
    })


    ### Below here is for Player Data Tab ###

    output$dataBatterTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })
    output$dataPitcherTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })

    # Update list of teams
    updateSelectInput(session, "dataBatterTeam", label = "Batter Team", choices = c("All", teams$teamname))
    updateSelectInput(session, "dataPitcherTeam", label = "Pitcher Team", choices = c("All", teams$teamname))

    # Triggered when a new team is selected
    observeEvent(input$dataBatterTeam, {        
        batters <- getBatterList(input$dataBatterTeam)
        updateSelectInput(session, "dataBatter", label = "Batter", choices = c("All", batters))

        # Update Team Picture
        if (input$dataBatterTeam == "All") output$dataBatterTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })
        else output$dataBatterTeamImage <- renderUI({ tags$img(src = paste0("https://www.mlbstatic.com/team-logos/",getTeamID(input$dataBatterTeam),".svg"), height = '50px') })
    })

    # Triggered when a new team is selected
    observeEvent(input$dataPitcherTeam, {
        pitchers <- getPitcherList(input$dataPitcherTeam)
        updateSelectInput(session, "dataPitcher", label = "Pitcher", choices = c("All", pitchers))

        # Update Team Picture
        if (input$dataPitcherTeam == "All") output$dataPitcherTeamImage <- renderUI({ tags$img(src = "https://www.mlbstatic.com/team-logos/league-on-dark/1.svg", height = '50px') })
        else output$dataPitcherTeamImage <- renderUI({ tags$img(src = paste0("https://www.mlbstatic.com/team-logos/",getTeamID(input$dataPitcherTeam),".svg"), height = '50px') })
    })


    # Triggered when a new batter is selected
    observeEvent(input$dataBatter, {
        bID <- getBatterID(input$dataBatter)

        # Update Batter Headshot
        if (input$dataBatter != "All") output$dataBatterImage <- renderUI({ tags$img(src = paste0("https://img.mlbstatic.com/mlb-photos/image/upload/w_60,q_100/v1/people/",bID,"/headshot/silo/current"), height = '50px') })
        else output$dataBatterImage <- NULL
    })

    # Triggered when a new pitcher is selected
    observeEvent(input$dataPitcher, {
        pID <- getPitcherID(input$dataPitcher)

        # Update Pitcher Headshot
        if (input$dataPitcher != "All") output$dataPitcherImage <- renderUI({ tags$img(src = paste0("https://img.mlbstatic.com/mlb-photos/image/upload/w_60,q_100/v1/people/",pID,"/headshot/silo/current"), height = '50px') })
        else output$dataPitcherImage <- NULL
    })

    # Triggered when Submit is clicked
    observeEvent(input$dataSubmit, {
        playerDataQuery(input, output)
    })


    # Close Database connections when program is finished
    # Causing issues when deployed on EC2 Server
    # session$onSessionEnded(function(){
    #     dbDisconnect(DB)
    # })
}