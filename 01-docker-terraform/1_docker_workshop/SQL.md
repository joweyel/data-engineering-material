Lets refresh our SQL-knowledge:

Showing the `zones`-table:
```sql
SELECT
  * 
FROM 
	zones;
```

Showing the first 100 rows of the `yellow_taxi_trips_2021_1`-table:
```sql
SELECT
	* 
FROM 
	yellow_taxi_trips_2021_1
LIMIT
	100;
```

Next step is to join the `yellow_taxi_trips_2021_1` and `zones` in order to map the numerical values of `PULocationID` and `DOLocationID` to the Zone-names.

- Reference: https://www.w3schools.com/sql/sql_ref_join.asp

On way of doing this is the following:
```sql
-- Inner JOIN "by hand"
SELECT
	tpep_pickup_datetime,
	tpep_dropoff_datetime,
	total_amount,
	CONCAT(zpu."Borough", ' / ', zpu."Zone") AS "pickup_loc",
	CONCAT(zdo."Borough", ' / ', zdo."Zone") AS "dropoff_loc"
		
FROM 
	yellow_taxi_trips_2021_1 AS t,
	zones AS zpu,
	zones AS zdo
WHERE
	t."PULocationID" = zpu."LocationID" AND
	t."DOLocationID" = zdo."LocationID"
LIMIT
	100;
```

Another way is:
```sql
-- Using JOIN explicitely
SELECT
	tpep_pickup_datetime,
	tpep_dropoff_datetime,
	total_amount,
	CONCAT(zpu."Borough", ' / ', zpu."Zone") AS "pickup_loc",
	CONCAT(zdo."Borough", ' / ', zdo."Zone") AS "dropoff_loc"
FROM 
	yellow_taxi_trips_2021_1 AS t 
	JOIN zones AS zpu
		ON t."PULocationID" = zpu."LocationID"
	JOIN zones AS zdo
		ON t."DOLocationID" = zdo."LocationID"
LIMIT
	100;
```

Checking if some location ID's are missing:
```sql
--- Check Pickup-Location ID
SELECT
	tpep_pickup_datetime,
	tpep_dropoff_datetime,
	total_amount,
	"PULocationID",
	"DOLocationID"
FROM 
	yellow_taxi_trips_2021_1 AS t 
WHERE
	"PULocationID" NOT IN (SELECT "LocationID" FROM zones)
LIMIT
	100;
```

```sql
--- Check Dropoff-Location ID
SELECT
	tpep_pickup_datetime,
	tpep_dropoff_datetime,
	total_amount,
	"PULocationID",
	"DOLocationID"
FROM 
	yellow_taxi_trips_2021_1 AS t 
WHERE
	"DOLocationID" NOT IN (SELECT "LocationID" FROM zones)
LIMIT
	100;
```
Results from bot querys show that nothing is missing.

### Using Left, Right and Outer Joins when some Location IDs in either table

When using the regular `JOIN`-Keyword, it defaults to a `INNER JOIN`, which joins tables where keys of both tables match. To also retain unmatched columns in the `LEFT` or the `RIGHT` table, the usage of `LEFT JOIN` or `RIGHT JOIN` is required.

`LEFT JOIN Example`: Retains all records in the left table, even if there is no matching record in the right table

```sql
SELECT
	tpep_pickup_datetime,
	tpep_dropoff_datetime,
	total_amount,
	"PULocationID",
	"DOLocationID"
FROM 
	yellow_taxi_trips_2021_1 AS t 
	LEFT JOIN zones AS zpu
		ON t."PULocationID" = zpu."LocationID"
	LEFT JOIN zones AS zdo
		ON t."DOLocationID" = zdo."LocationID"
LIMIT 
	100;
```

First joins the `zpu` to `yellow_taxi_trips_2021_1` on `PULocationID`, then joins `zdo` to the previous `LEFT JOIN`. This retains all records from the leftmost table. The `yellow_taxi_trips_2021_1` is therefore fully preserved.

`RIGHT JOIN Example:` Joining tables together from right to left, where entries in the right table are retained when joined.

```sql
SELECT
	tpep_pickup_datetime,
	tpep_dropoff_datetime,
	total_amount,
	"PULocationID",
	"DOLocationID"
FROM 
	yellow_taxi_trips_2021_1 AS t 
	RIGHT JOIN zones AS zpu
		ON t."PULocationID" = zpu."LocationID"
	RIGHT JOIN zones AS zdo
		ON t."DOLocationID" = zdo."LocationID"
LIMIT 
	100;
```

`(FULL) OUTER JOIN Example`: A Combination of `LEFT JOIN` and `RIGHT JOIN`, where every entry is retained from both tables and missing values in entries are filled in with NULL-values.

### Using `GROUP_BY` to calclulate number of trips per day + ordering them with `ORDER BY`

```sql
SELECT
  -- casting to sql-date format
	CAST(tpep_dropoff_datetime AS DATE) AS "day",
  -- counting the number of trips
	COUNT(1) 
FROM 
	yellow_taxi_trips_2021_1 AS t 
GROUP BY -- result is grouped by the day
	CAST(tpep_dropoff_datetime AS DATE)   -- Or use just "day"
ORDER BY -- Ascending order
	"day" ASC;
```

### `GROUP BY` and `ORDER BY` with multiple columns

```sql
SELECT
	CAST(tpep_dropoff_datetime AS DATE) AS "day",
	"DOLocationID",
	COUNT(1) AS "count",
	MAX(total_amount),
	MAX(passenger_count)
FROM 
	yellow_taxi_trips_2021_1 AS t 
GROUP BY
	1, 2 -- groupin by row 1 and 2 ("day", "DOLocationID")
ORDER BY
	"day" ASC, -- day from lowest to highest
	"DOLocationID" ASC;  -- dropoff location id from low to high 
```