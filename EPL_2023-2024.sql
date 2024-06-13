Create Database EPL_2023_2024;

Use EPL_2023_2024;

#From PL_Table Table

Show Variables Like 'Sql_Safe_Updates';
Set sql_safe_updates=0;
Update Pl_Table 
set Attendance=cast(replace(Attendance,',','')as unsigned);

ALTER TABLE Pl_table
MODIFY COLUMN Attendance INT;

Select * from pl_table;

#1. Which teams have been Qualified for any European Competetions and which competetion they will be playing next seasons.

SELECT Squad AS Team, Notes AS Competition
FROM Pl_table
WHERE Notes IS NOT NULL 
  AND (Notes LIKE '%Champions League%'
  OR Notes LIKE '%Europa%');

ALTER TABLE Pl_table
ADD COLUMN Top_Scorer VARCHAR(255),
ADD COLUMN Goals_Scored_by_Top_Scorer INT;

Select `Top Team scorer`from Pl_Table; # use backticks (`) in case there's a column name that has space in it

Update Pl_Table Set
Top_Scorer= SUBSTRING_INDEX(`Top Team scorer`, '-', 1),
Goals_Scored_by_Top_Scorer  = CAST(SUBSTRING_INDEX(`Top Team scorer`, '-', -1) AS UNSIGNED);

#2. What are top 5 Goal_Scorer of PL 23-24 season ,how many goals they have scored
With ranked AS(
Select Top_Scorer,Goals_Scored_By_Top_Scorer,squad as Team, Dense_Rank() over(order by Goals_Scored_By_Top_Scorer DESC) 
as Rank_No from PL_table)
Select Rank_No,Top_Scorer,Goals_Scored_By_Top_Scorer,Team from ranked where Rank_No<6;
 

With Ranked as 
(Select dense_rank() over(order by Goals_Scored_By_Top_Scorer DESC ) as Rank_No,Top_Scorer,Goals_Scored_By_Top_Scorer,squad as Team 
from PL_table)
select * from ranked where rank_no<=5;

#3. Which Team scored most goals and conceaded fewest goals
WITH MostGoals AS (
    SELECT Squad AS Team, GF
    FROM Pl_table
    ORDER BY GF DESC
    LIMIT 1
),
FewestGoals AS (
    SELECT Squad AS Team, GA
    FROM Pl_table
    ORDER BY GA ASC
    LIMIT 1
)
SELECT 
    MostGoals.Team AS TeamWithMostGoals,
    FewestGoals.Team AS TeamWithFewestGoalsConceded
FROM 
    MostGoals, FewestGoals;
#3 Teams with best GD / which are the most balanced teams in PL
with ranked as(
	Select Squad As Team, GD, dense_rank() over(Order BY GD DESC) as Rank_No
    from Pl_Table
)
Select Team,GD from ranked where Rank_No<5;

#4 Who has the best XG / expected goals in the whole 23-24 season and check if the scored lesser or more
Select squad as Team,
CASE
 when Gf-Cast(Xg as decimal)<0 then 'Scored Lesser than Expected'
 when Gf-Cast(Xg as decimal)>0 then 'Scored More than Expected'
 else 'Scored as Expected' END as Status from Pl_Table order by XG Desc limit 1;

#5 Give me top 5 teams who scored lesser than expected and Top 5 who scored more than expected means Got bit lucky


With `Difference` as
(Select squad as Team, Gf-Cast(Xg as decimal) as `Diff` from Pl_Table),
`StatusT` as 
(Select Team,`Diff`,
CASE
 when `Diff`<0 then 'Less'
 when`Diff`>0 then 'More'
 else 'Equal' END as `Status` from `Difference`),
`Lesser` as 
(Select  Team,Diff, dense_rank()over(order by diff asc) as Less_rank from `StatusT` where `Status`="Less")
Select Less_Rank,Lesser.Team as Teams_With_Lesser_Goals,Abs(Diff) as `Goals_Missed_Out`
From Lesser where Lesser.Less_rank < 6;



With `Difference` as
(Select squad as Team, Gf-Cast(Xg as decimal) as `Diff` from Pl_Table),
`StatusT` as 
(Select Team,`Diff`,
CASE
 when `Diff`<0 then 'Less'
 when`Diff`>0 then 'More'
 else 'Equal' END as `Status` from `Difference`),
`Higher` as 
(Select   Team,Diff, dense_rank()over(order by diff Desc) as High_rank from `StatusT` where `Status`="More")
Select High_Rank as `Rank`, Higher.Team as Teams_With_Higher_Goals ,DIFF AS `Lucky_Goals/Unexpected_Goals`
From Higher where Higher.High_rank < 6;

#teams Scored as Expected
With `Difference` as
(Select squad as Team, Gf-Cast(Xg as decimal) as `Diff` from Pl_Table),
`StatusT` as 
(Select Team,`Diff`,
CASE
 when `Diff`<0 then 'Less'
 when`Diff`>0 then 'More'
 else 'Equal' END as `Status` from `Difference`),
`Same` as 
(Select   Team,Diff, dense_rank()over(order by diff Desc) as Equal_rank from `StatusT` where `Status`="Equal")
Select Equal_Rank as `Rank`, Same.Team as Teams_With_Higher_Goals ,DIFF 
From Same;


/*Stadiums_and_Attendence Table*/


Update Stadiums_and_Attendance
set Capacity=cast(replace(Capacity,',','')as unsigned);

ALTER TABLE Stadiums_and_Attendance
MODIFY COLUMN Capacity INT;

Update Stadiums_and_Attendance
set Average_Attendance=cast(replace(Average_Attendance,',','')as unsigned);

ALTER TABLE Stadiums_and_Attendance
MODIFY COLUMN Average_Attendance INT;

Update Stadiums_and_Attendance
set Filled=cast(replace(Filled,"%","") as unsigned);

Alter TABLE Stadiums_and_Attendance
Modify Column Filled INT;


#1. Top 5 Teams and their respective stadiums with highest Avg_Attendance in 23-24 season
Select Team, Stadium, Average_Attendance from Stadiums_and_Attendance order by Average_Attendance DESC limit 5;

#2. Teams that has filled the stadium above 90% in each game and where the stadium Capacity must be higher than 25,000
Select Team,Stadium,Capacity,Concat(Cast(Filled as Char), "%" )as Percentage_Filled_In_Each_Game  
From Stadiums_and_Attendance where Filled>90 and Capacity>25000;

/* Squad_Advanced_Goalkeeping Table*/
#1. which teams conceded less_number of own goals in 2023-24 season
with ranked AS(
Select Squad as Team,Og, dense_rank() over(Order by OG) as rank_no from Squad_Advanced_Goalkeeping
)
select Rank_No,Team,Og as Own_Goals_Conceded from ranked where rank_No<2;

#2. Which team conceded lowest number of goals from set pieces (Free kicks + Corners combined)
With total as
(Select squad as team,Fk+Ck as Set_Piece_Goals_Conceded from Squad_Advanced_Goalkeeping),
ranked as
(Select Team, Set_Piece_Goals_Conceded,dense_rank()over(order by Set_Piece_Goals_Conceded) as rank_no from total)
select Rank_No,Team,Set_Piece_Goals_Conceded from Ranked where rank_no<2;

#3. which teams has conceded goal more than the post Shot expected goals (Means which team's goalkeeper Underperformed)
Select Squad as Team,Round(Cast(GA as Double)-PSxG) as Number_Of_Excessive_Goals_They_Conceded from Squad_Advanced_Goalkeeping 
where Cast(GA as Double)>PsxG order by Number_Of_Excessive_Goals_They_Conceded Desc limit 5;

#4. which teams has conceded goal less than the post Shot expected goals (Means which team's goalkeeper performed well)
Select Squad as Team,Round(PSxG-Cast(GA as Double)) as Number_Of_Less_Goals_They_Conceded from Squad_Advanced_Goalkeeping 
where Cast(GA as Double)<PsxG order by Number_Of_Less_Goals_They_Conceded Desc limit 5;

#5. Which team's goalkeepers launched the ball less number of times means they prefer to play possetional football
#(Build From the back)
with ranked AS
(Select Squad as Team, Att,`Cmp%`, dense_rank() over(Order By Att ) as rank_no from Squad_Advanced_Goalkeeping)
Select Rank_No,Team,Att as Launch_Attempted,`Cmp%` as Completion_Percentage from ranked where rank_no<6
 order by Completion_Percentage;

#6. Which teams goal_keeper has the highest average passing range
Select Squad,AvgLen as "Average_Passing_Range_(in Yard)" from Squad_Advanced_Goalkeeping order by AvgLen Desc Limit 5;

#7. which teams Goalkeeper stopped the crosses most of the time (Showcases his Aerial Ability and Awarness)
Select Squad,Stp as "Number_of_Crosses_Stopped_By_GK",`Stp%`as "Percentage_of_Shots_Stopped" 
from Squad_Advanced_Goalkeeping order by Stp Desc limit 5;
#8. which teams Goalkeeper has the best Percentage_of_Shots_Stopped (Showcases his Aerial Ability and Awarness)
Select Squad,`Stp%`as "Percentage_of_Shots_Stopped" 
from Squad_Advanced_Goalkeeping order by `Stp%` Desc limit 1;
#9. Which Teams GK is the best Sweeper means has the most number of desfensive Attempts outside penalty area 
#also show the average distances they cover
select Squad as Team,`#opa`as "Number of Desfensive actions outside Penalty Area",
AvgDist as "Average Distance they Cover outside penalty area(Yards)" from Squad_Advanced_Goalkeeping
 order by AvgDist Desc Limit 5;
 
 /*Squad Shooting Table*/
 #1. Top 3 teams with best shooting acuuracy (Means Percentage of successful shots on target)
 with ranked As(
 Select Squad as Team,Sh as Total_Shots,`Sot%` as Shooting_Accuracy, dense_rank() over(Order by `Sot%` DESC)as Rank_No
 from Squad_Shooting)
Select Rank_No,Team,Total_Shots,Shooting_Accuracy from ranked where Rank_No<4;
 
 #2.Top 3 Teams with best shot on Target per 90 minutes/per match
  with ranked As(
 Select Squad as Team,Sh as Total_Shots,`SoT/90` as Shot_on_Target_per90, dense_rank() over(Order by `SoT/90` DESC)as Rank_No
 from Squad_Shooting)
Select Rank_No,Team,Shot_on_Target_per90 from ranked where Rank_No<4;

#3.Top 3 Teams that has longest Average shooting distance(in Yards)
  with ranked As(
 Select Squad as Team,Sh as Total_Shots,`Dist` as Average_Shooting_Distance, dense_rank() over(Order by `Dist` DESC)as Rank_No
 from Squad_Shooting)
Select Rank_No,Team, Average_Shooting_Distance from ranked where Rank_No<4;

/*Squad_Passing Table*/
#1. Top 3 teams with best passing accuracy they must be in top 10 teams with most pass completion
WITH RankedTeams AS (
    SELECT 
        Squad AS Team,
        Cmp,
        `Cmp%`,
        dense_rank() OVER (ORDER BY Cmp DESC) AS Rank_no,
        dense_rank() OVER (ORDER BY `Cmp%` DESC) AS Rank_noo
    FROM 
        Squad_Passing
),
Top10 AS (
    SELECT 
        Team,`Cmp%`
    FROM 
        RankedTeams
    WHERE 
        Rank_no < 6
),
Top3 AS (
    SELECT 
        Team,`Cmp%`
    FROM 
        RankedTeams
    WHERE 
        Rank_noo < 4
)
-- Main query to check if top 3 teams are in top 10
SELECT 
    Top3.Team,top3.`Cmp%` as Passing_Accuracy
FROM 
    Top3
Join Top10 on Top3.team=top10.team;

#2. Top 3 Team with most short passes (5-15 yards) attempted and thier accuracy must be more than 90%
with Ranked as
(Select Squad,`Att_[0]`,`Cmp%_[0]`, dense_rank() over(order by `Cmp_[0]` Desc) as rank_no from Squad_Passing where `Cmp%_[0]`>85
)
Select Rank_No,Squad as Team ,`Att_[0]` as Short_Passes_Attempted,`Cmp%_[0]` as Accuracy from ranked where rank_no<4;

#4. Top 3 Teams with most medium passes (15-30 yards) attempted and thier accuracy must be more than 85%
with Ranked as
(Select Squad,`Att_[1]`,`Cmp%_[1]`, dense_rank() over(order by `Cmp_[1]` Desc) as rank_no from Squad_Passing where `Cmp%_[1]`>85
)
Select Rank_No,Squad as Team ,`Att_[1]` as Medium_Passes_Attempted,`Cmp%_[1]` as Accuracy from ranked where rank_no<4;

#4. Top 5 Teams with most long passes (15-30 yards) attempted and thier accuracy must be more than 50%
with Ranked as
(Select Squad,`Att_[2]`,`Cmp%_[2]`, dense_rank() over(order by `Cmp_[2]` Desc) as rank_no from Squad_Passing where `Cmp%_[2]`>50
)
Select Rank_No,Squad as Team ,`Att_[2]` as Long_Passes_Attempted,`Cmp%_[2]` as Accuracy from ranked where rank_no<6;

#5. Top 3 teams with Most Number of Key Passes (Passes that direcly leads to a shot towards Goal)
WITH RankedTeams AS (
    SELECT 
        Squad AS Team,
        Kp,
        dense_rank() OVER (ORDER BY Kp DESC) AS Rank_No
    FROM 
        Squad_Passing
)
SELECT 
    Rank_No,
    Team,
    Kp
FROM 
    RankedTeams
WHERE 
    Rank_No < 4;

#6. Top 3 teams that completed most number of passes in Final Third
WITH RankedTeams AS (
    SELECT 
        Squad AS Team,
		`01-Mar` as Final_Third_Passes,
        dense_rank() OVER (ORDER BY `01-Mar` DESC) AS Rank_No
    FROM 
        Squad_Passing
)
SELECT 
    Rank_No,
    Team,
    Final_Third_Passes
FROM 
    RankedTeams
WHERE 
    Rank_No < 4;
#top 5 Teams that deliverd most number of crosses into the opponents box

WITH RankedTeams AS (
    SELECT 
        Squad AS Team,
		`CrsPA` as Number_Of_Crosses_in_Penalty_Area,
        dense_rank() OVER (ORDER BY `CrsPA` DESC) AS Rank_No
    FROM 
        Squad_Passing
)
SELECT 
    Rank_No,
    Team,
    Number_Of_Crosses_in_Penalty_Area
FROM 
    RankedTeams
WHERE 
    Rank_No < 6;

/*Squad_defensive_actions Table*/

#1. Top 3 teams that made most of the tackles in defensive third/on thier own half
With Ranked as(
select squad as team, `Def 3rd`as No_of_Tackles_Def3rd,dense_rank()over(order by `Def 3rd` desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Tackles_Def3rd from ranked where Rank_No<4;

#2. Top 3 teams that made most of the tackles in midfield
With Ranked as(
select squad as team, `Mid 3rd`as No_of_Tackles_Mid,dense_rank()over(order by `Mid 3rd` desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Tackles_Mid from ranked where Rank_No<4;
#3. Top 3 teams that made most of the tackles in Attacking third/on opponent's half
With Ranked as(
select squad as team, `Att 3rd`as No_of_Tackles_Att3rd,dense_rank()over(order by `Att 3rd` desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Tackles_Att3rd from ranked where Rank_No<4;

#3. Team with most lost challanges against a dribbler
With Ranked as(
select squad as team, `Lost`as No_of_Challanges_Lost,dense_rank()over(order by `Lost` ) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Challanges_Lost from ranked where Rank_No<4;

#4. Top 3 teams with best successful Tackle  rate
With Ranked as(
select squad as team, Concat(Cast(`Tkl%` as Char), '%' )as Tackle_Rate,dense_rank()over(order by `Tkl%` Desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, Tackle_Rate from ranked where Rank_No<4;

#5. Top 3 teams with most blocked shots
With Ranked as(
select squad as team,`Sh`as No_of_Shots_Blocked,dense_rank()over(order by `Sh` Desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Shots_Blocked from ranked where Rank_No<4;

#6. Top 3 teams with most interceptions
With Ranked as(
select squad as team,`Int`as No_of_Interceptions,dense_rank()over(order by `Int` Desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Interceptions from ranked where Rank_No<4;
#7. Top 3 Teams with most errors that lead to a opponent's shot 
With Ranked as(
select squad as team,`Err`as No_of_Errors_Led_to_Shots,dense_rank()over(order by `Err` Desc) as Rank_No from Squad_defensive_actions
)
Select Rank_no,Team, No_of_Errors_Led_to_Shots from ranked where Rank_No<4;



#Creating Players Table
CREATE TABLE Players (
    Rk INT,
    Player VARCHAR(100),
    Nation VARCHAR(50),
    Pos VARCHAR(50),
    Squad VARCHAR(100),
    Age INT,
    Born INT,
    MP INT,
    Starts INT,
    Min INT,
    90s FLOAT,
    Gls INT,
    Ast INT,
    `G+A` INT,
    `G-PK` INT,
    PK INT,
    PKatt INT,
    CrdY INT,
    CrdR INT,
    xG FLOAT,
    npxG FLOAT,
    xAG FLOAT,
    `npxG+xAG` FLOAT,
    PrgC INT,
    PrgP INT,
    PrgR INT,
    Gls_90 FLOAT,
    Ast_90 FLOAT,
    `G+A_90` FLOAT,
    `G-PK_90` FLOAT,
    `G+A-PK_90` FLOAT,
    xG_90 FLOAT,
    npxG_90 FLOAT,
    `xG+xAG_90` FLOAT,
    `npxG+xAG_90` FLOAT,
    Matches Varchar(50)
)CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

/*Players*/


#1. Youngest team 

with Average_Age as
( Select Squad as Team, Round(avg(age),2) as Average_Age, dense_rank()  over( Order by Avg(Age))as Rank_No
from Players group by Squad
)
Select Rank_No,Team,Average_Age from Average_age where Rank_No<2;

#2. Top 3 Highest Goal Scorer from each club
WITH Ranked_Players AS (
    SELECT 
        Squad,Player,Gls,dense_rank() OVER (PARTITION BY Squad ORDER BY Gls DESC) AS Rank_No FROM Players
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;


#3. Players that played all of the 38 league matches except goalkeepers
Select Player,Squad,Pos as Team from Players where Mp=38 and Pos<>"GK" order by Squad;


#4. Top 3 Players with most Non-Penalty Goals
WITH Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY `G-Pk` DESC) AS Rank_No ,Squad,Player,`G-Pk` as Non_Penalty_Goals FROM Players
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;

#4. Top 3 Players with most Penalty Goals
WITH Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY `Pk` DESC) AS Rank_No ,Squad,Player,`Pk` as Penalty_Goals FROM Players
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;

#5. Top 3 Forward Players who scored less than expected Goals  and at least the played more than 20 matches 
WITH Expected As(
Select Squad as Team, Player,Mp, Cast((XG*MP )as Signed) as Expected_Goals ,Gls ,pos from Players
),
Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY Expected_Goals) AS Rank_No ,Team,Player,Expected_Goals ,Gls as Goals FROM Expected
        where Gls<Expected_Goals and MP>20 and Pos like"%FW%"
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;

#6. Top 3 players that created most of the chances means their pass lead to a shot
WITH Expected As(
Select Squad as Team, Player, Cast((XAG*MP )as Signed) as Chances_Created from Players
),
Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY Chances_Created DESC) AS Rank_No ,Team,Player,Chances_Created FROM Expected
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;

#7. Top 3 best carrier of the ball (No of times they carries the ball towards opponents Goal)
With Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY Prgc DESC)as Rank_No,Player,Prgc AS No_of_Carries  ,Squad as Team FROM Players
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;
1	Jeremy Doku	218	Manchester City
2	Alejandro Garnacho	178	Manchester Utd
3	Bukayo Saka	155	Arsenal
table just

#8. Top 3 Players with the most Progressive passes (at least 10 yards)
With Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY PrgP DESC)as Rank_No,Player,PrgP AS No_of_Progressive_Passes  ,Squad as Team FROM Players
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3;



#9. Top 3 Players with Most no of assists per 90 minutes at least played more than 20 matches
With Ranked_Players AS (
    SELECT 
        dense_rank() OVER ( ORDER BY Ast_90 DESC)as Rank_No,Player,Ast_90  AS Assist_Per_90  ,Squad as Team FROM Players where Mp>20
)
SELECT * FROM Ranked_Players WHERE  Rank_No <= 3 ;
