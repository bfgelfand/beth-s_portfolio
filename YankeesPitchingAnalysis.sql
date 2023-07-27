SELECT *
FROM YankeesPitching.dbo.LastPitchYankees

SELECT *
FROM YankeesPitching.dbo.YankeesPitchingStats

--Question 1: AVG Pitches Per At Bat Analysis

--1a AVG Pitches Per At Bat (LastPitchYankees)

SELECT 
	AVG(1.00 * pitch_number) AvgNumofPitchesPerAtBat
FROM 
	YankeesPitching.dbo.LastPitchYankees

--1b AVG Pitches Per At Bat Home Vs Away (LastPitchYankees) -> Union

SELECT 
	'Home' TypeofGame,
	AVG(1.00 * pitch_number) AvgNumofPitchesPerAtBat
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE 
	home_team = 'NYY'
UNION
SELECT 
	'Away' TypeofGame,
	AVG(1.00 * pitch_number) AvgNumofPitchesPerAtBat
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE 
	away_team = 'NYY'


--1c AVG Pitches Per At Bat Lefty Vs Righty  -> Case Statement 

SELECT 
	AVG(Case when Batter_position = 'L' Then 1.00 * pitch_number end) LeftyAtBats,
	AVG(Case when Batter_position = 'R' Then 1.00 * pitch_number end) RightyAtBats
FROM 
	YankeesPitching.dbo.LastPitchYankees


--1d AVG Pitches Per At Bat Lefty Vs Righty Pitcher | Each Away Team -> Partition By

SELECT DISTINCT
	home_team,
	Pitcher_position,
	AVG(1.00 * pitch_number) OVER (Partition by home_team, Pitcher_position)
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE 
	away_team = 'NYY'

--1e Top 3 Most Common Pitch for at bat 1 through 10, and total amounts (LastPitchYankees)

WITH totalpitchsequence AS (
	SELECT DISTINCT 
		pitch_name,
		pitch_number,
		COUNT(pitch_name) OVER (Partition by pitch_name, pitch_number) PitchFrequency
	FROM 
		YankeesPitching.dbo.LastPitchYankees
	WHERE
		pitch_name IS NOT NULL
		AND
		pitch_number < 11
),
pitchfrequencyrankquery AS (
	SELECT 
		pitch_name,
		pitch_number,
		PitchFrequency,
		RANK() OVER(PARTITION BY pitch_number ORDER BY PitchFrequency DESC) PitchFrequencyRanking
	FROM totalpitchsequence
)

SELECT *
FROM 
	pitchfrequencyrankquery
WHERE 
	PitchFrequencyRanking < 4


--1f AVG Pitches Per at Bat Per Pitcher with 20+ Innings | Order in descending (LastPitchYankees + YankeesPitchingStats)

SELECT 
	YPS.Name,
	AVG(1.00 * pitch_number) AVGPitches
FROM 
	YankeesPitching.dbo.LastPitchYankees LPY
JOIN 
	YankeesPitching.dbo.YankeesPitchingStats YPS 
ON YPS.pitcher_id = LPY.pitcher
WHERE IP 
	>= 20
GROUP BY 
	YPS.Name
ORDER BY 
	AVG(1.00 * pitch_number) DESC

-Question 2 Last Pitch Analysis

--2a Count of the Last Pitches Thrown in Desc Order (LastPitchYankees)

SELECT
	pitch_name, 
	COUNT(*) timesthrown
FROM
	YankeesPitching.dbo.LastPitchYankees
WHERE
	pitch_name IS NOT NULL
GROUP BY 
	pitch_name
ORDER BY
	COUNT(*) DESC


--2b Count of the different last pitches Fastball or Offspeed (LastPitchYankees)

SELECT 
	SUM(CASE WHEN pitch_name IN ('4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) Fastball,
	SUM(CASE WHEN pitch_name NOT IN ('4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) Offspeed
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE 
	pitch_name IS NOT NULL

--2c Percentage of the different last pitches Fastball or Offspeed (LastPitchYankees)

SELECT 
	100 * SUM(case when pitch_name IN ('4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) / COUNT(*) FastballPercent,
	100 * SUM(case when pitch_name NOT IN ('4-Seam Fastball', 'Cutter') THEN 1 ELSE 0 END) / COUNT(*) OffspeedPercent
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE
	pitch_name IS NOT NULL

--2d Top 5 Most common last pitch for a Relief Pitcher vs Starting Pitcher (LastPitchYankees + YankeesPitchingStats)

SELECT *
FROM (
	SELECT 
		a.POS, 
		a.pitch_name,
		a.timesthrown,
		RANK() OVER (PARTITION BY a.POS ORDER BY a.timesthrown DESC) PitchRank
	FROM (
		SELECT 
			YPS.POS, 
			LPY.pitch_name, 
			COUNT(*) timesthrown
		FROM 
			YankeesPitching.dbo.LastPitchYankees LPY
		JOIN 
			YankeesPitching.dbo.YankeesPitchingStats YPS 
		ON YPS.pitcher_id = LPY.pitcher
		WHERE 
			pitch_name IS NOT NULL
		GROUP BY 
			YPS.POS, 
			LPY.pitch_name
	) a
)b
WHERE b.PitchRank < 6

--Question 3 Homerun analysis

--3a What pitches have given up the most HRs (LastPitchYankees) 

--Doesn't work due to bad data
--SELECT *
--FROM YankeesPitching.dbo.LastPitchYankees
--WHERE hit_location IS NULL and bb_type = 'fly_ball'

--actual way to do it
SELECT 
	pitch_name, 
	COUNT(*) HRs
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE 
	events = 'home_run'
GROUP BY
	pitch_name
ORDER BY
	COUNT(*) DESC

--3b Show HRs given up by zone and pitch, show top 5 most common

SELECT 
	TOP 5 ZONE, 
	pitch_name, 
	COUNT(*) HRs
FROM 
	YankeesPitching.dbo.LastPitchYankees
WHERE 
	events = 'home_run'
GROUP BY 
	ZONE, 
	pitch_name
ORDER BY 
	COUNT(*) DESC


--3c Show HRs for each count type -> Balls/Strikes + Type of Pitcher

SELECT 
	YPS.POS, 
	LPY.balls, 
	LPY.strikes, 
	COUNT(*) HRs
FROM 
	YankeesPitching.dbo.LastPitchYankees LPY
JOIN 
	YankeesPitching.dbo.YankeesPitchingStats YPS 
ON YPS.pitcher_id = LPY.pitcher
WHERE 
	events = 'home_run'
GROUP BY 
	YPS.POS, 
	LPY.balls, 
	LPY.strikes
ORDER BY 
	COUNT(*) DESC
		
--3d Show Each Pitchers Most Common count to give up a HR (Min 30 IP)

WITH hrcountpitchers AS (

	SELECT 
		YPS.Name, 
		LPY.balls, 
		LPY.strikes, 
		COUNT(*) HRs
FROM 
	YankeesPitching.dbo.LastPitchYankees LPY
JOIN 
	YankeesPitching.dbo.YankeesPitchingStats YPS 
ON YPS.pitcher_id = LPY.pitcher
WHERE 
	events = 'home_run' AND IP >= 30
GROUP BY 
	YPS.Name, 
	LPY.balls, 
	LPY.strikes
),
hrcountrankings AS (
	SELECT 
		hcp.Name, 
		hcp.balls, 
		hcp.strikes, 
		hcp.HRs,
		RANK() OVER (PARTITION BY Name ORDER BY HRs DESC) hrrank
	FROM 
		hrcountpitchers hcp
)
SELECT 
	ht.Name, 
	ht.balls, 
	ht.strikes, 
	ht.HRs
FROM 
	hrcountrankings ht
WHERE 
	hrrank = 1

--Question 4 Gerrit Cole
--SELECT *
--FROM YankeesPitching.dbo.LastPitchYankees LPY
--JOIN YankeesPitching.dbo.YankeesPitchingStats YPS ON YPS.pitcher_id = LPY.pitcher

--4a AVG Release speed, spin rate,  strikeouts, most popular zone ONLY USING LastPitchYankees

SELECT 
	AVG(release_speed) AvgReleaseSpeed,
	AVG(release_spin_rate) AvgSpinRate,
	SUM(CASE WHEN events = 'strikeout' THEN 1 ELSE 0 END) strikeouts,
	MAX(zones.zone) AS Zone
FROM 
	YankeesPitching.dbo.LastPitchYankees LPY
JOIN(

	SELECT 
		TOP 1 pitcher, 
		zone, 
		COUNT(*) zonenum
	FROM 
		YankeesPitching.dbo.LastPitchYankees LPY
	WHERE 
		player_name = 'Cole, Gerrit'
	GROUP BY 
		pitcher, 
		zone
	ORDER BY 
		COUNT(*) DESC

) zones ON zones.pitcher = LPY.pitcher
WHERE player_name = 'Cole, Gerrit'


--4b top pitches for each infield position where total pitches are over 5, rank them

SELECT *
FROM (
	SELECT 
		pitch_name, 
		COUNT(*) timeshit, 
		'Third' Position
	FROM 
		YankeesPitching.dbo.LastPitchYankees LPY
	WHERE 
		hit_location = 5 AND player_name = 'Cole, Gerrit'
	GROUP BY 
		pitch_name
	UNION
	SELECT 
		pitch_name, 
		COUNT(*) timeshit, 
		'Short' Position
	FROM 
		YankeesPitching.dbo.LastPitchYankees LPY
	WHERE 
		hit_location = 6 AND player_name = 'Cole, Gerrit'
	GROUP BY 
		pitch_name
	UNION
	SELECT 
		pitch_name, 
		COUNT(*) timeshit, 
		'Second' Position
	FROM 
		YankeesPitching.dbo.LastPitchYankees LPY
	WHERE 
		hit_location = 4 AND player_name = 'Cole, Gerrit'
	GROUP BY 
		pitch_name
	UNION
	SELECT 
		pitch_name, 
		COUNT(*) timeshit, 
		'First' Position
	FROM 
		YankeesPitching.dbo.LastPitchYankees LPY
	WHERE 
		hit_location = 3 AND player_name = 'Cole, Gerrit'
	GROUP BY 
		pitch_name
) a
WHERE 
	timeshit > 4
ORDER BY 
	timeshit DESC



--4c Show different balls/strikes as well as frequency when someone is on base 

SELECT 
	balls, 
	strikes, 
	COUNT(*) frequency
FROM 
	YankeesPitching.dbo.LastPitchYankees LPY
WHERE 
	(on_3b is NOT NULL OR on_2b IS NOT NULL OR on_1b IS NOT NULL)
AND 
	player_name = 'Cole, Gerrit'
GROUP BY 
	balls, 
	strikes
ORDER BY 
	COUNT(*) DESC


--4d What pitch causes the lowest launch speed

SELECT 
	TOP 1 pitch_name, 
	AVG(launch_speed * 1.00) LaunchSpeed
FROM 
	YankeesPitching.dbo.LastPitchYankees LPY
WHERE 
	player_name = 'Cole, Gerrit'
GROUP BY 
	pitch_name
ORDER BY 
	AVG(launch_speed)
