Update tracks
Join 
(
Select * from (
SELECT
    tracks.Valid,
    tracks.title,
    tracks.Artist,
    album_track.*, 
    Cast (albums.Info ->> '$.fixed_genres' as json) as fixed_genres ,
    ROW_NUMBER () over (PARTITION BY album_track.TrackId ORDER BY album_track.AlbumPriority DESC
    ) AS `RankOverTrack`

FROM
    tracks
JOIN album_track ON album_track.TrackId = tracks.Id and tracks.valid > 0
JOIN albums ON albums.uuid = album_track.AlbumId
AND albums.valid > 0
AND albums.Info ->> '$.fixed_genres' IS NOT NULL
) as t1
where t1.RankOverTrack = 1
) as t2
on t2.trackid = tracks.id
Set
tracks.info = JSON_SET(IFNULL(tracks.info, JSON_OBJECT()),'$.fixed_genres',t2.fixed_genres),
tracks.ext = JSON_SET(IFNULL(tracks.ext, JSON_OBJECT()),'$.fixed_genres_albumuuid',t2.albumid)
