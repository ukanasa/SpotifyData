--Renaming table '2014'
alter table '2014' rename to spotifyA;

--Checking empty/null values
select count(*), sum(ms_played/60000) as sum_min_played, * from spotifyA
where master_metadata_album_artist_name like '' 
or master_metadata_album_artist_name like 'null'; 
--44 blank artist name entries, 117 minutes played from these entries, no null values just '' entries  

--What were the top 10 most played artists from 2014-2017?
with subset as 
(select master_metadata_album_artist_name as artist_name, 
sum(ms_played/60000) as sum_artist_min_played
from spotifyA 
where artist_name not like ''
group by artist_name
order by sum_artist_min_played desc
limit 10)
select dense_rank() over(order by sum_artist_min_played desc) as Top_10,
* from subset
order by sum_artist_min_played desc, artist_name;

--What about for 2015?
with subset as 
(select master_metadata_album_artist_name as artist_name, 
sum(ms_played/60000) as sum_artist_min_played
from spotifyA
where artist_name not like '' 
AND STRFTIME('%Y',TimeStamp) = '2015'
group by artist_name
order by sum_artist_min_played DESC 
limit 10)
select dense_rank() over(order by sum_artist_min_played desc) as Top_10,
*
from subset
order by sum_artist_min_played desc, artist_name;

--What were the top songs played by the most popular artist in 2015?
with subset as
(select master_metadata_album_artist_name as artist_name,
master_metadata_track_name as song_name,
sum(ms_played/60000) as sum_artist_min_played
from spotifyA
where artist_name not like ''
AND STRFTIME('%Y',TimeStamp) = '2015'
AND artist_name = 'Jay Sean'
group by artist_name, song_name 
order by sum_artist_min_played desc)
select dense_rank() over(order by sum_artist_min_played desc) as Top_10,
* from subset;

--What was average time played for the previous artist's most popular song
select master_metadata_album_artist_name as artist_name,
master_metadata_track_name as song_name,
ROUND(AVG((ms_played/60000.00)),2) as artist_min_played
from spotifyA
where song_name = 'Ride It'
and STRFTIME('%Y',TimeStamp) = '2015'
group by artist_name, song_name 

--What were the top 10 most played songs from 2014-2017?
with subset as 
(select master_metadata_track_name as song_name,
master_metadata_album_artist_name as artist_name,
sum(ms_played/60000) as sum_song_min_played
from spotifyA
where artist_name not like ''
group by song_name, artist_name
order by sum_song_min_played desc
limit 10)
select dense_rank() over (order by sum_song_min_played desc) as Top_10,
* from subset
order by sum_song_min_played desc,artist_name; 

--What about the top 10 most listened to songs from 2016? 
with subset as 
(select master_metadata_track_name as song_name,
master_metadata_album_artist_name as artist_name,
sum(ms_played/60000) as sum_song_min_played
from spotifyA
where artist_name not like ''
AND STRFTIME('%Y',TimeStamp) = '2016'
group by song_name, artist_name
order by sum_song_min_played desc
limit 10)
select dense_rank() over (order by sum_song_min_played desc) as Top_10, 
* from subset
order by sum_song_min_played desc,artist_name;

--What were the ways a track ended and how many times from 2014-2017?
select distinct reason_end as distinct_reason_end, 
count(*) as count_reason_end   
from spotifyA
group by distinct_reason_end 
order by count_reason_end desc; 

--Who was the most skipped artist from 2014-2017?
with subset as 
(select master_metadata_album_artist_name as artist_name,
count(*) as count_skipped
from spotifyA
where skipped = 'TRUE'
group by artist_name
order by count_skipped DESC 
limit 10)
select dense_rank() over(order by count_skipped desc) as Top_10,
* from subset
order by count_skipped desc;

--What were the platforms used to stream music and how many times were they used?
select  case 
		when platform like '%iPhone6%' then 'iPhone6'
		when platform like '%iPhone7%' then 'iPhone7'
		when platform like '%iPhone5%' then 'iPhone5'
		when platform like '%OS%' then 'MacBook'
		else platform 
		end as platform_name, 
count(*) as count_platform
from spotifyA
group by platform_name 
order by count_platform desc;

--What is the shortest time a song was listened to 
with subset as 
(select master_metadata_track_name as song_name,
master_metadata_album_artist_name as artist_name,
ms_played
from spotifyA
where ms_played <> 0)
select * from subset
where ms_played = (select min(ms_played) from subset);

--What is the longest time a song was listened to?
with subset as 
(select master_metadata_track_name as song_name,
master_metadata_album_artist_name as artist_name,
ROUND(ms_played/60000.00,2) as min_played
from spotifyA
where min_played <> 0)
select * from subset
where min_played = (select max(min_played) from subset);
















