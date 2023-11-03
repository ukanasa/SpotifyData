--Null or empty values?
select *
from streaming_history_23_13  
where 
master_metadata_album_artist_name is NULL 
or master_metadata_album_artist_name = ''
or master_metadata_track_name is NULL 
or master_metadata_track_name = ''
or ms_played is null; 

select count(*)
from streaming_history_23_13 sh 
where 
master_metadata_album_artist_name is NULL 
or master_metadata_album_artist_name = ''
or master_metadata_track_name is NULL 
or master_metadata_track_name = ''
or ms_played is null;

select round(avg(ms_played/60000.00),2) as avg_min_played
from streaming_history_23_13 sh 
where 
master_metadata_album_artist_name is NULL 
or master_metadata_album_artist_name = ''
or master_metadata_track_name is NULL 
or master_metadata_track_name = ''
or ms_played is null;
--These values appear to be podcasts (average minutes played is 19.21) so we will remove all 881 records from the dataset 

--Create temp table without podcasts 
create temp table clean_data as
select * from streaming_history_23_13 
where 
master_metadata_album_artist_name is not NULL 
and master_metadata_album_artist_name <> ''
and
master_metadata_track_name is not NULL 
and master_metadata_track_name <> ''
and ms_played is not null;

--Rename some columns names for easier references later on 
alter table clean_data
rename column master_metadata_album_artist_name to artist_name;
alter table clean_data
rename column master_metadata_track_name to song_name;
alter table clean_data
rename column master_metadata_album_album_name to album_name;

--Changing the datatype of the ts column to timestamp from varchar 
select pg_typeof(ts) from clean_data;
alter table clean_data
add timestamp_column TIMESTAMP; 
update clean_data
set timestamp_column = cast(ts as TIMESTAMP);
alter table clean_data
drop column ts; 

--What is the time range of this dataset?
with subset as 
(select min(timestamp_column) as start_date, max(timestamp_column) as end_date from clean_data)
select start_date,
end_date,
extract(month from end_date - start_date) + 
extract(day from end_date - start_date) / 
        case 
            when date_trunc('month', end_date) = date_trunc('month', start_date) then 30
            else date_part('day', end_date - date_trunc('month', end_date - interval '1 day'))
        end as months_and_days_difference
from subset;

--Adding a month column and a day column for each record in the temp table 
alter table clean_data
add month_column integer;
update clean_data
set month_column = extract(month from timestamp_column);
alter table clean_data
add day_column integer;
update clean_data
set day_column = extract(day from timestamp_column);

--Adding a column converting milliseconds to minutes 
select pg_typeof(ms_played) from clean_data;
alter table clean_data
add min_played float;
update clean_data
set min_played = round(ms_played/60000.00,2);
--We will keep the ms_played column

--Who were the top 10 most listened to artists from within the time range of this dataset? 
with subset as 
(select artist_name,
sum(min_played) as total_min_played 
from clean_data 
group by artist_name 
order by total_min_played desc
limit 10)
select dense_rank() over(order by total_min_played desc) as Top_10,
* from subset; 

--What were the top 10 most listened to songs from within the time range of this dataset? 
with subset as 
(select song_name,
artist_name,
sum(min_played) as total_min_played 
from clean_data 
group by song_name,artist_name 
order by total_min_played desc
limit 10)
select dense_rank() over(order by total_min_played desc) as Top_10,
* from subset; 

--Exploring the ways a track can start and end 
select distinct reason_start, count(*) from clean_data
group by reason_start
order by count(*) desc; 
select distinct reason_end, count(*) from clean_data
group by reason_end
order by count(*) desc;
--For both queries, the fwdbtn or forward button was by far the most common reason. The track was finished only 1,656 times out of all records!

--What were the top songs listened to the end?
with subset as 
(select song_name,
artist_name,
count(*) as total_times_finished 
from clean_data 
where reason_start not in ('appload','remote','trackerror')
and reason_end = 'trackdone'
group by song_name,artist_name 
order by total_times_finished desc
limit 10)
select dense_rank() over(order by total_times_finished desc) as Top_10,
* from subset;

--Top 10 songs by month over the dataset? 
with subset as
(select to_char(to_date(month_column::varchar, 'MM'), 'Month') as month_name,
song_name,
artist_name,
sum(min_played) as total_min_played,
dense_rank() over(partition by month_column order by sum(min_played) desc)
from clean_data  
group by month_column, song_name,artist_name 
order by month_column asc)
select * from subset 
where dense_rank <= 10; 

--Can you check the rank of one song for each month? 
with subset as
(select to_char(to_date(month_column::varchar, 'MM'), 'Month') as month_name,
song_name,
artist_name,
sum(min_played) as total_min_played,
dense_rank() over(partition by month_column order by sum(min_played) desc)
from clean_data  
group by month_column, song_name,artist_name 
order by month_column asc)
select * from subset 
where song_name = 'WARNING';
--This is useful as it shows a decrease in interest in the song over 5 months

--How about an artist? 
with subset as
(select to_char(to_date(month_column::varchar, 'MM'), 'Month') as month_name,
artist_name,
sum(min_played) as total_min_played,
dense_rank() over(partition by month_column order by sum(min_played) desc)
from clean_data  
group by month_column, artist_name 
order by month_column asc)
select * from subset 
where artist_name = 'Cannons';

with subset as
(select to_char(to_date(month_column::varchar, 'MM'), 'Month') as month_name,
song_name,
artist_name,
sum(min_played) as total_min_played,
dense_rank() over(partition by month_column order by sum(min_played) desc)
from clean_data  
group by month_column, song_name,artist_name 
order by month_column asc)
select * from subset 
where artist_name = 'Cannons';
--The increase in rank for this group is probably due to the release of a new song in August! 





 













