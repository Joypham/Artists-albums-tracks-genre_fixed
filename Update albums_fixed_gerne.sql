-- Step 1: 2888 records

Update albums
Join (
SELECT
	uuid,
	info ->> '$.all_music.genres',
	info ->> '$.genres',
	info ->> '$.wiki.genres',
	info ->> '$.fixed_genres',
	Json_remove (info,'$.fixed_genres'),
	info
FROM
	albums
where 
info ->> '$.fixed_genres' is not null
and
info ->> '$.all_music.genres' is null 
and 
(info ->> '$.genres' is null or info ->> '$.genres' like 'null')
) as t1
on t1.uuid = albums.uuid
set 
albums.info = 	Json_remove (t1.info,'$.fixed_genres')
