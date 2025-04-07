select * from goals;
select * from matches;
select * from players;
select * from stadiums
select * from teams;

drop table if exists goals;
create table goals (
GOAL_ID varchar(10),
MATCH_ID varchar(10),
PID varchar(10),
DURATION int,
ASSIST varchar(10),
GOAL_DESC varchar(30)
);
Select * from matches;
drop table if exists matches;
create table matches (
MATCH_ID varchar(7),
SEASON varchar(10),
DATE date,
HOME_TEAM varchar(40),	
AWAY_TEAM varchar(40),
STADIUM varchar(60),
HOME_TEAM_SCORE int,
AWAY_TEAM_SCORE int,
PENALTY_SHOOT_OUT int,
ATTENDANCE int
);

drop table if exists players;
create table players (
PLAYER_ID varchar(8),	
FIRST_NAME varchar(30),
LAST_NAME varchar(30),
NATIONALITY	varchar(30),
DOB date,
TEAM varchar(30),
JERSEY_NUMBER int,
POSITION varchar(30),
HEIGHT int,
WEIGHT	int,
FOOT varchar(2)
);
select * from players;
select * from stadiums;

drop table if exists stadiums;
create table stadiums(
NAME varchar(35),
CITY varchar(20),
COUNTRY	varchar(20),
CAPACITY int
);

drop table if exists Teams;
create table Teams (
TEAM_NAME varchar(40),
COUNTRY	varchar(25),
HOME_STADIUM varchar(35)
);
  
COPY goals
FROM 'C:/Users/ROHIT/Desktop/cuvette/Project/Cuvette Proj/proj files/goals.csv' 
DELIMITER ',' 
CSV HEADER;

COPY players
FROM 'C:/Users/ROHIT/Desktop/cuvette/Project/Cuvette Proj/proj files/Players.csv' 
DELIMITER ',' 
CSV HEADER;
--1
select count(distinct team_name) from teams ;
--2
select country , count(team_name) as no_of_teams from teams group by country order by no_of_teams desc ;
--3
select avg (length(team_name)) from teams;
--4
Select country,round(avg(capacity)) as Stadium_capacity from stadiums group by country order by
Stadium_capacity desc;
--5
Select count( goal_id) from goals;
--6*
Select * from teams where team_name like '%City%' ;
--7
Select team_name||','||country as TeamCountry from teams;
--8) What is the highest attendance recorded in the dataset, and which match 
--(including home and away teams, and date) does it correspond to?
select match_id,attendance, date, home_team, away_team from matches 
where attendance = (select max(attendance) from matches);
--9)What is the lowest attendance recorded in the dataset, and which match (including home and
--away teams, and date) does it correspond to set the criteria as greater than 1 as some matches
--had 0 attendance because of covid.
Select match_id,date, home_team, away_team,  attendance FROM matches
WHERE attendance = ( SELECT MIN(attendance) FROM matches WHERE attendance > 1);

--10) Identify the match with the highest total score (sum of home and away team scores) in the 
--dataset. Include the match ID, home and away teams, and the total score.
select  match_id,date, home_team, away_team,home_team_score,away_team_score,(home_team_score+away_team_score)
as total_score from matches where (home_team_score+away_team_score)=
(select  max(home_team_score+away_team_score) from matches)  ;

--11)Find the total goals scored by each team, distinguishing between home and away goals. 
--Use a CASE WHEN statement to differentiate home and away goals within the subquery

select home_team as team , home_team_score as goal, 'home' as goal_type from matches
union
select away_team as team , away_team_score as goal, 'away' as goal_type from matches
--
create table team_performance as(
select team, sum(case when goal_type='home' then goal else 0 end) as home_goals,
           sum(case when goal_type='away' then goal else 0 end)as away_goals,
		   sum(goal) as total_goals from 
		         (select home_team as team , home_team_score as goal, 'home' as goal_type from matches
                  union
                  select away_team as team , away_team_score as goal, 'away' as goal_type from matches)
            as all_goals
			group by team);
			
select * from team_performance
			
--12) windows function - Rank teams based on their total scored goals (home and away combined)
 --using a window function.In the stadium Old Trafford.
   select *, rank()  over ( order by total_goals desc) as rank from team_performance ;

--13)Write a query to list all players along with the total number of goals they have scored.Order the
--results by the number of goals scored in descending order to easily identify the top 6 scorers.

select a.player_id,a.first_name,a.last_name,count(b.goal_id)as goals from players as a left join goals as b on
a.player_id=b.pid group by 1,2,3 order by 4 desc;
--top 6
select a.player_id,a.first_name,a.last_name,count(b.goal_id)as goals from players as a left join goals as b on
a.player_id=b.pid group by 1,2,3 order by 4 desc limit 6 ;

/* 14)Identify the Top Scorer for Each Team - Find the player from each team who has scored the most
  goals in all matches combined. This question requires joining the Players, Goals, and possibly the
  Matches tables, and then using a subquery to aggregate goals by players and teams.*/
  
--no of goals by player
Select pid, COUNT(goal_id) AS total_goals FROM goals  GROUP BY pid order by 2 desc;

create table ply_goals as (SELECT  pid, COUNT(goal_id) AS total_goals FROM goals  GROUP BY pid order by 2 desc);
select * from ply_goals
delete  from goals where pid is null;

select a.pid,a.total_goals,b.team from ply_goals as a left join players as b on a.pid=b.player_id group by 1,2,3 ;
--
SELECT  p.player_id,p.first_name,p.last_name,p.team,COUNT(g.goal_id) AS total_goals FROM players as p
JOIN goals g ON p.player_id = g.pid 
GROUP BY 1,2,3,4 order by 5 desc;
--
with player_goals as (SELECT  p.player_id,p.first_name,p.last_name,p.team,COUNT(g.goal_id) AS total_goals FROM 
players as p JOIN goals g ON p.player_id = g.pid  GROUP BY 1,2,3,4 order by 5 desc),
top_scorer as (select *, rank() over (partition by team order by total_goals desc) as rank 
     from player_goals)
	 select * from top_scorer where rank=1;

/*15)Find the Total Number of Goals Scored in the Latest Season - Calculate the total number of goals
scored in the latest season available in the dataset. This question involves using a subquery 
to first identify the latest season from the Matches table, then summing the goals from 
the Goals table that occurred in matches from that season.	*/
--latest season
   select max(season)as latest_season from matches ;
   
   select * from matches where season=(select max(season) from matches);
--goals per match in latest season   
   select a.match_id,count(a.goal_id)as total_goals,b.season from goals as a right join 
   (select * from matches where season=(select max(season) from matches)) as b on a.match_id=b.match_id
    group by 1,3;
--total no of goals in latest season
with latest_season as ( select a.match_id,count(a.goal_id)as total_goals,b.season from goals as a right join 
   (select * from matches where season=(select max(season) from matches)) as b on a.match_id=b.match_id
    group by 1,3), tot_ses_goal as ( select sum(total_goals)as total_goals from latest_season)
	select * from tot_ses_goal;
/*16)Find Matches with Above Average Attendance - Retrieve a list of matches that had an attendance
     higher than the average attendance across all matches. This question requires a subquery to
	 calculate the average attendance first, then use it to filter matches.*/
  ---Avg Attendance
	select avg(attendance) from matches;
	select match_id,attendance from matches where attendance>=(select avg(attendance) from matches);

/*17)Find the Number of Matches Played Each Month - Count how many matches were played in each month
     across all seasons. This question requires extracting the month from the match dates and grouping
	 the results by this value. as January Feb march*/
	--extracting month_no from date 
	 select  extract (month from date) as month_no from matches
	
	select month_no, count(match_id) as Total_matches from (select *, extract 
	(month from date) as month_no from matches) 
    group by 1 order by 1;
 --note  :No matches played in month 1 & 7....verified below
   select date from matches where extract(month from date) =1 ;
   select date from matches where extract(month from date) =7 ;
   

