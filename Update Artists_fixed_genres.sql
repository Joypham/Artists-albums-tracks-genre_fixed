-- Step 1: Remove old fixed_genres

Update artists
JOIN
(
SELECT
	uuid,
	info ->> '$.fixed_genres',
	info,
	Json_remove (info,'$.fixed_genres')
FROM
	artists
where 
info ->> '$.fixed_genres' is not null
) as t1
on t1.uuid = artists.uuid
set artists.info = 	Json_remove (t1.info,'$.fixed_genres')

-- Step 2: Update  artists.fixed_genres `159375 records`

Update artists
JOIN
(
SELECT
    artists.uuid,
    artists.Valid,
    artists. NAME,
Cast(
if
(
artists.Info -> '$.allmusic.genres' not like 'null' and artists.Info -> '$.allmusic.genres' is not null, 
CONCAT('[',Replace(info -> '$.allmusic.genres',',','", "'),']')
,null)
as Json) 
as genres,
artists.info

FROM
    artists
WHERE
    valid > 0
having genres is not null
) as t1
on t1 .uuid = artists.uuid
Set
artists.info = JSON_SET(IFNULL(artists.info, JSON_OBJECT()),'$.fixed_genres',t1.genres)
			
-- Ngày 23.04.2019: Fixed_genres > 2 subgenre trong đó có ít nhất 1 subgenre = pop/rock => remove pop/rock 
Step 1: Câu lệnh select 
Select 
name,
uuid,
Info ->> '$.allmusic.styles',
info ->> '$.fixed_genres',
genrematch.GenreName,
Json_remove(info,Json_unquote(Json_search(info,'all','Pop/Rock','$'))),
ROW_NUMBER () over (PARTITION BY artists.uuid ) as `Rankovertrack`,
LENGTH(info ->> '$.fixed_genres')
from artists

left Join genrematch on 
(SUBSTRING_INDEX(Info ->> '$.allmusic.styles',',',1) = genrematch.GenreName
or
SUBSTRING_INDEX(Info ->> '$.allmusic.styles',',',-1) = genrematch.GenreName
or
Info ->> '$.allmusic.styles' like CONCAT('%',',',genrematch.GenreName,',','%'))
and genrematch.GenreName <> 'Pop/Rock'
where 
info ->> '$.fixed_genres' like '%Pop/Rock%'
and 
Info ->> '$.allmusic.styles' is not null 
and 
Info ->> '$.allmusic.styles' not like '%null%'
and
LENGTH(info ->> '$.fixed_genres') > 12
-- Step 2: câu lệnh update: 
UPDATE artists 
Join (
Select 
name,
uuid,
Info ->> '$.allmusic.styles',
info ->> '$.fixed_genres',
genrematch.GenreName,
Json_remove(info,Json_unquote(Json_search(info,'all','Pop/Rock','$'))) as remove_poprock,
info,
ROW_NUMBER () over (PARTITION BY artists.uuid ) as `Rankovertrack`,
LENGTH(info ->> '$.fixed_genres')
from artists
left Join genrematch on 
(SUBSTRING_INDEX(Info ->> '$.allmusic.styles',',',1) = genrematch.GenreName
or
SUBSTRING_INDEX(Info ->> '$.allmusic.styles',',',-1) = genrematch.GenreName
or
Info ->> '$.allmusic.styles' like CONCAT('%',',',genrematch.GenreName,',','%'))
and genrematch.GenreName <> 'Pop/Rock'
where 
info ->> '$.fixed_genres' like '%Pop/Rock%'
and 
Info ->> '$.allmusic.styles' is not null 
and 
Info ->> '$.allmusic.styles' not like '%null%'
and
LENGTH(info ->> '$.fixed_genres') <> 12
-- and 
-- artists.uuid = '00139C420D124EBDBCD86C92F7A89094'
) as t1
 on artists.uuid = t1.uuid
Set artists.info = t1.remove_poprock


-- Fix genre album: truong hop chi co 1 subgenre = pop/rock
UPDATE albums
JOIN (
	SELECT
		albums.uuid,
		albums.info ->> '$.fixed_genres' as album_genre,
		artist_album.ArtistId,
		cast(artists.Info ->> '$.fixed_genres' as Json) as artist_genre
		
	FROM
		albums
	JOIN artist_album ON artist_album.AlbumId = albums.Id
	JOIN artists ON artists.Id = artist_album.artistid
	AND artists.valid > 0
	AND albums.info ->> '$.fixed_genres' <> artists.Info ->> '$.fixed_genres'
	WHERE
		albums.info ->> '$.fixed_genres' LIKE '%Pop/Rock%'
	AND (
		albums.valid > 0
		OR albums.valid = - 91
	)
	-- AND albums.uuid = '0000DFFA23DF48DB81651F616A55BBB8'
	GROUP BY
		albums.UUID,
		artists.Id
) AS t1 
ON t1.uuid = albums.uuid
SET albums.info = JSON_SET (IFNULL(albums.info, JSON_OBJECT()),'$.fixed_genres',t1.artist_genre) -- 145.067






