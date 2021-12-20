-- Dan Inglis
-- SQL Table definitions for Blue Jays Baseball Systems Developer Project

create table battedball (
    battedballpk integer primary key not null auto_increment,   -- The primary key of the batted ball 
    gamedate date,                                              -- The date of the game
    gamepk integer,                                             -- The MLB ID of the game
    hometeamid integer,                                         -- The MLB ID of the home team
    hometeamname varchar (25),                                  -- The name of the home team
    awayteamid integer,                                         -- The MLB ID of the visiting team
    awayteamname varchar (25),                                  -- The name of the visiting team
    parkid integer,                                             -- The MLB ID of the ballpark
    park varchar (35),                                          -- The name of the ballpark
    batterid integer,                                           -- The MLB ID of the batter
    battername varchar (50),                                    -- The name of the batter
    batside varchar(1),                                         -- The handedness/stance of the batter
    batterteamid integer,                                       -- The MLB ID of the batter's team
    pitcherid integer,                                          -- The MLB ID of the pitcher
    pitchername varchar (50),                                   -- The name of the pitcher
    pitcherteamid integer,                                      -- The MLB ID of the pitcher's team
    pitchside varchar(1),                                       -- The handedness/throwing arm of the pitcher
    balls tinyint unsigned,                                     -- The number of balls in the count
    strikes tinyint unsigned,                                   -- The number of strikes in the count
    result_type varchar (30),                                   -- The result of the batted ball
    pitch_type varchar (3),                                     -- The pitch type code of the pitch
    pitch_speed decimal (9,6),                                  -- "The release speed of the pitch, in mph"
    zone_location_x decimal(18,15),                             -- "The horizontal location (across the plate) of the pitch at the front of home plate, in feet. Positive values are towards the 1B side"
    zone_location_z decimal(18,15),                             -- "The height of the pitch at the front of home plate, in feet"
    launch_speed decimal (9,6),                                 -- "The speed of the ball as it left the bat, in mph"
    launch_vert_ang decimal(18,15),                             -- "The vertical launch angle in degrees, where 0 is flat, -90 is directly down and +90 is directly up"
    launch_horiz_ang decimal(18,15),                            -- "The horizontal launch angle in degrees, where 0 is up the middle of the field, the right-field foul line is +45 and the left-field foul line is -45"
    landing_location_x decimal(18,15),                          -- "The x-coordinate, in feet, where the ball first hit the ground. The x-axis runs parallel to the front of home plate at (0,0) with the positive direction being towards the first-base side"
    landing_location_y decimal(18,15),                          -- "The y-coordinate, in feet, where the ball first hit the ground. The y-axis runs out from home plate at (0,0) towards center field"
    hang_time decimal(18,15)                                    -- "How long the ball was in the air between contact with the bat and hitting the ground. If the ball was caught, the projected hang-time if the ball had reached the ground"
);


-- Example Insert Query
-- insert into battedball (battedballpk, gamedate, gamepk, hometeamid, hometeamname, awayteamid, awayteamname, parkid, park, batterid, battername, batside, batterteamid, pitcherid, pitchername, pitcherteamid, pitchside, balls, strikes, result_type, pitch_type, pitch_speed, zone_location_x, zone_location_z, launch_speed, launch_vert_ang, launch_horiz_ang, landing_location_x, landing_location_y, hang_time)
--     values (NULL, '2017-04-03', 490104, 133, "Oakland", 108, "LA Angels", 10, "Oakland Coliseum", 501981, "Davis,  Khris", "R", 133, 445060, "Nolasco,  Ricky", 108, "L", 0, 2, "field_out", "KC", 74.676521, 0.8805747, 1.4989213, 62.371586, 9.4485035, -18.538105, -31.282774, 87.078987, 1.1204376);
