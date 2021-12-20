# Blue Jays Systems Developer Project
# Dan Inglis
# Python script reads batted ball data from ALWestBattedBalls2017.csv and uploads data to RDS MySQL database

import pandas as pd
import mysql.connector
from mysql.connector import errorcode

databaseConfig = {
    'user': 'admin',
    'password': '*****',
    'host': 'blue-jays-baseball-systems-developer.*****.us-east-1.rds.amazonaws.com',
    'database': 'bluejays',
    'raise_on_warnings': True
}

# Connects to RDS Database
def connectToDB():
    try:
        mydb = mysql.connector.connect(**databaseConfig)
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Error. Incorrect username or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Error. Database does not exist.")
            print("Please create 'bluejays' schema and try again.")
        else:
            print(err)

    return(mydb)

# Takes batted ball data and inserts into database
def addDataToDB(df, mydb):

    # For each batted ball entry in the dataframe, create a query and execute it
    for i in range(df.shape[0]):
        query = """
                INSERT INTO battedball
                (battedballpk, gamedate, gamepk, hometeamid, hometeamname, awayteamid, awayteamname, parkid, park, batterid, battername, batside, batterteamid, pitcherid, pitchername, pitcherteamid, pitchside, balls, strikes, result_type, pitch_type, pitch_speed, zone_location_x, zone_location_z, launch_speed, launch_vert_ang, launch_horiz_ang, landing_location_x, landing_location_y, hang_time)
                values (NULL, '{}', {}, {}, '{}', {}, '{}', {}, '{}', {}, '{}', '{}', {}, {}, '{}', {}, '{}',  {}, {}, '{}', '{}', {}, {}, {}, {}, {}, {}, {}, {}, {});
                """.format(df['date'][i], df['gamepk'][i], df['hometeamid'][i], df['hometeamname'][i], df['awayteamid'][i], df['awayteamname'][i], df['parkid'][i], df['park'][i], df['batterid'][i], df['battername'][i], df['batside'][i], df['batterteamid'][i], df['pitcherid'][i], df['pitchername'][i], df['pitcherteamid'][i], df['pitchside'][i], df['balls'][i], df['strikes'][i], df['result_type'][i], df['pitch_type'][i], df['pitch_speed'][i], df['zone_location_x'][i], df['zone_location_z'][i], df['launch_speed'][i], df['launch_vert_ang'][i], df['launch_horiz_ang'][i], df['landing_location_x'][i], df['landing_location_y'][i], df['hang_time'][i])
        
        try:
            mycursor = mydb.cursor()
            mycursor.execute(query)
        except Exception as e:
            print(e)
            print(query)
            return
    
    # Save DB Changes
    mydb.commit()
    print("Upload Complete.")
    print(str(df.shape[0]) + " batted balls uploaded.")


# Reads data from csv
def readFile():
    file = 'BattedBallData\ALWestBattedBalls2017.csv'
    df = pd.read_csv(file)
    #print(df)              #prints whole spreadsheet
    #print(df['date'])      #prints date column
    #print(df['date'][0])   #prints first entry in date column

    #return dataframe
    return(df)


if __name__ == "__main__":

    df = readFile()

    mydb = connectToDB()

    addDataToDB(df, mydb)
