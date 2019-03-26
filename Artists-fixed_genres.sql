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