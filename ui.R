# Dan Inglis
# Blue Jays Baseball Systems Developer Project
# ui.R is responsible for defining the user interface for the application

library(shiny)
library(shinydashboard)
library(plotly)
library(shinyWidgets)
library(shinyjs)
library(shinyBS)
library(shinybusy)
library(DT)

ui <- dashboardPage(
    dashboardHeader(title = uiOutput("BlueJaysLogo")),
        dashboardSidebar(
            sidebarMenu(id = "sidebar",
                menuItem("Spray Chart", tabName = "tabSprayChart", icon = icon("baseball-ball")),
                menuItem("Raw Data", tabName = "tabData", icon = icon("database"))
            )
        ),
    dashboardBody(
        shinyjs::useShinyjs(),
        add_busy_spinner(spin = "fingerprint", position = "top-right", margins = c(75, 60)),
        tabItems(
            tabItem(tabName = "tabSprayChart", 
                fluidRow(
                    column(6, align = "left",
                        wellPanel(
                            uiOutput("batterTeamImage"),
                            selectInput(inputId = "sprayBatterTeam", label = "Batter Team", choices = NULL, selected = NULL, multiple = FALSE, selectize = TRUE, width = NULL),
                            uiOutput("batterImage"),
                            selectInput(inputId = "sprayBatter", label = "Batter", choices = NULL, multiple = FALSE, selectize = TRUE, width = NULL)
                        )
                    ),
                    column(6, align = "left",
                        wellPanel(
                            uiOutput("pitcherTeamImage"),
                            selectInput(inputId = "sprayPitcherTeam", label = "Pitcher Team", choices = NULL, selected = NULL, multiple = FALSE, selectize = TRUE, width = NULL),
                            uiOutput("pitcherImage"),
                            selectInput(inputId = "sprayPitcher", label = "Pitcher", choices = NULL, multiple = FALSE, selectize = TRUE, width = NULL)
                        )
                    ) 
                ),
                fluidRow(
                    column(width = 4, offset = 4, align = "center",
                        wellPanel(
                            selectInput(inputId = "stadium", label = "Stadium Overlay", choices = c("Rogers Centre"), selected = "Rogers Centre", multiple = FALSE, selectize = TRUE, width = NULL)
                        )
                    )
                ),
                bsCollapse(id = "filtersPanel",
                    bsCollapsePanel("Additional Filters", style = "default",
                        column(width = 4,
                            wellPanel(
                                selectInput(inputId = "timeframe", label = "Timeframe", c("Today" = "today", "Past Week" = "week", "Past Month" = "month", "3 Months" = "3months", "6 Months" = "6months", "Past Year" = "year", "All Available" = "all", "Custom" = "custom"), selected = "all", multiple = FALSE, selectize = TRUE, width = NULL),
                                dateInput(inputId = "timeframeStartDate", label = "Start Date", value = NULL, format = "yyyy-mm-dd", weekstart = 1, width = NULL, autoclose = TRUE),
                                dateInput(inputId = "timeframeEndDate", label = "End Date", value = NULL, format = "yyyy-mm-dd", weekstart = 1, width = NULL, autoclose = TRUE)
                            )
                        ),
                        column(width = 6,
                            wellPanel(
                                # Ref: https://baseballsavant.mlb.com/statcast_field?ev=74&la=22
                                sliderInput(inputId = "exitVeloSlider", label = "Exit Velocity", min = 0, max = 1, value = 1),
                                sliderInput(inputId = "launchAngleSlider", label = "Launch Angle", min = 0, max = 1, value = 1)
                            )
                        )
                    )
                ),
                bsCollapse(id = "visualsPanel",
                    bsCollapsePanel("Additional Visualizations", style = "default",
                        column(width = 4, align = "center",
                            plotOutput("strikeZoneOutput")
                        ),
                        column(width = 2, align = "center",
                            plotOutput("strikeZoneMapOutput")
                        ),
                        column(width = 6, align = "center",
                            plotOutput("sprayMapOutput", width = "400px", height = "400px")
                        )
                    )
                ),
                fluidRow(
                    column(12, align = "center",
                        wellPanel(
                            uiOutput("sprayChartOutput", width = "400px", height = "400px")
                        )
                    )
                )
            ),
            tabItem(tabName = "tabData",
                fluidRow(
                    column(6, align = "left",
                        wellPanel(
                            uiOutput("dataBatterTeamImage"),
                            selectInput(inputId = "dataBatterTeam", label = "Batter Team", choices = NULL, selected = NULL, multiple = FALSE, selectize = TRUE, width = NULL),
                            uiOutput("dataBatterImage"),
                            selectInput(inputId = "dataBatter", label = "Batter", choices = NULL, multiple = FALSE, selectize = TRUE, width = NULL)
                        )
                    ),
                    column(6, align = "left",
                        wellPanel(
                            uiOutput("dataPitcherTeamImage"),
                            selectInput(inputId = "dataPitcherTeam", label = "Pitcher Team", choices = NULL, selected = NULL, multiple = FALSE, selectize = TRUE, width = NULL),
                            uiOutput("dataPitcherImage"),
                            selectInput(inputId = "dataPitcher", label = "Pitcher", choices = NULL, multiple = FALSE, selectize = TRUE, width = NULL)
                        )
                    ) 
                ),
                fluidRow(
                    column(12, align = "center", 
                        actionButton("dataSubmit", "Submit")
                    )
                ),
                fluidRow(
                    DT::dataTableOutput("playerDataTable")
                )
            )
        )
    )
)