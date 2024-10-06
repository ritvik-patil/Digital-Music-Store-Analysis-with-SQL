/* MUSIC STORE DATA ANALYSIS */

-- # QUESTIONS #

-- Q1: Who is the senior most employee based on job title?
SELECT title, first_name,last_name,hire_date
FROM employee
ORDER BY hire_date 
LIMIT 1;

------------------------------------------------------------------------------------------------------------

-- Q2: Which countries have the most Invoices?
SELECT billing_country,COUNT(*) AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;

------------------------------------------------------------------------------------------------------------

-- Q3: What are top 3 values of total invoice?
SELECT DISTINCT total, COUNT(total) AS invoice_count  
FROM invoice
GROUP BY total
ORDER BY total DESC
LIMIT 3;

------------------------------------------------------------------------------------------------------------

--  Q4: Which city has the best customers?
-- We would like to throw a promotional Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of invoice totals. 
-- Return both the city name & sum of all invoice totals

SELECT billing_city, SUM(total) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC
LIMIT 1;

------------------------------------------------------------------------------------------------------------

-- Q5: Who is the best customer? 
-- The customer who has spent the most money will be declared the best customer. 
-- Write a query that returns the person who has spent the most money

SELECT c.customer_id, 
	c.first_name,
	c.last_name, 
	sum(i.total) as toatl_spending
FROM customer c
	JOIN invoice i
		ON c.customer_id = i.customer_id
GROUP BY c.customer_id
ORDER BY toatl_spending DESC
LIMIT 1;

------------------------------------------------------------------------------------------------------------

-- Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
-- Return your list ordered alphabetically by email starting with

-- Method 1 -- using Join with subqueries 

SELECT DISTINCT c.email, c.first_name, c.last_name
FROM customer c
	JOIN invoice i
		ON c.customer_id = i.customer_id
	JOIN invoice_line il
		ON i.invoice_id = il.invoice_id
	WHERE il.track_id 
	IN (
		SELECT t.track_id
		FROM track t
			JOIN genre g
				ON t.genre_id = g.genre_id
		WHERE g.name LIKE '%Rock%'
		)
ORDER BY c.email;

---------------------------------------------------------
-- 2nd method-- Join all related tables for fething data

SELECT DISTINCT email ,first_name , last_name, genre.name AS Genre_name
FROM customer
	JOIN invoice 
		ON invoice.customer_id = customer.customer_id
	JOIN invoice_line 
		ON invoice_line.invoice_id = invoice.invoice_id
	JOIN track 
		ON track.track_id = invoice_line.track_id
	JOIN genre 
		ON genre.genre_id = track.genre_id
WHERE genre.name LIKE '%Rock%'
ORDER BY email;

------------------------------------------------------------------------------------------------------------

-- Q7: Let's invite the artists who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands. 

SELECT 
	ar.artist_id, 
	ar.name AS artist_name, 
	COUNT(*) AS total_track_count
FROM artist ar
	JOIN album ab 
		ON ar.artist_id = ab.artist_id
	JOIN track tk 
		ON ab.album_id = tk.album_id
	JOIN genre gn 
		ON tk.genre_id = gn.genre_id
WHERE gn.name LIKE '%Rock%'
GROUP BY ar.artist_id
ORDER BY total_track_count DESC
LIMIT 10;

------------------------------------------------------------------------------------------------------------

-- Q8: Return all the track names that have a song length longer than the average song length. 
-- Return the Name and Milliseconds for each track. 
-- Order by the song length with the longest songs listed first.

SELECT 
	name AS track_name, 
	milliseconds AS song_length
FROM track
WHERE milliseconds>
	(
	SELECT AVG(milliseconds) AS avg_song_length
					FROM track
	)
ORDER BY song_length DESC;

------------------------------------------------------------------------------------------------------------
					
-- Q9: Find how much amount spent by each customer on artists
-- Write a query to return customer name, artist name and total spent

-- Method:1- Using CTE Function 

WITH BestSellingArtist AS
(
    -- Calculate the total sales for each artist and select the best-selling artist
    SELECT 
        ar.artist_id, 
        ar.name AS artist_name,
        SUM(il.unit_price * il.quantity) AS total_sales
    FROM invoice_line il
    	JOIN track tk 
			ON il.track_id = tk.track_id
    	JOIN album ab 
			ON tk.album_id = ab.album_id
    	JOIN artist ar 
			ON ab.artist_id = ar.artist_id 
    GROUP BY ar.artist_id
    ORDER BY total_sales DESC
    LIMIT 1 -- Limit to the best-selling artist
)

-- Calculate the total amount spent by each customer on the best-selling artist's tracks
SELECT 
    c.customer_id, 
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.unit_price * il.quantity) AS total_amount_spent
FROM customer c
	JOIN invoice iv 
		ON c.customer_id = iv.customer_id
	JOIN invoice_line il 
		ON iv.invoice_id = il.invoice_id
	JOIN track tk 
		ON il.track_id = tk.track_id
	JOIN album ab 
		ON tk.album_id = ab.album_id
	JOIN BestSellingArtist bsa 
		ON ab.artist_id = bsa.artist_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC; -- Order by total amount spent in descending order

---------------------------------------------------------

-- Method:2- Using WINDOW function -RANK() inside CTE -- skipping ORDER BY AND LIMIT inside CTE

WITH BestSellingArtist AS (
    -- Calculate the total sales for each artist and rank them
    SELECT 
        ar.artist_id, 
        ar.name AS artist_name,
        SUM(il.unit_price * il.quantity) AS total_sales,
        RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS artist_rank
    FROM invoice_line il
    	JOIN track tk 
			ON il.track_id = tk.track_id
    	JOIN album ab 
			ON tk.album_id = ab.album_id
    	JOIN artist ar 
			ON ab.artist_id = ar.artist_id 
    GROUP BY ar.artist_id
)

-- Calculate the total amount spent by each customer on the best-selling artist's tracks
SELECT 
    c.customer_id, 
    c.first_name,
    c.last_name,
    bsa.artist_name,
    SUM(il.unit_price * il.quantity) AS total_amount_spent
FROM customer c
	JOIN invoice iv 
		ON c.customer_id = iv.customer_id
	JOIN invoice_line il 
		ON iv.invoice_id = il.invoice_id
	JOIN track tk 
		ON il.track_id = tk.track_id
	JOIN album ab 
		ON tk.album_id = ab.album_id
	JOIN BestSellingArtist bsa 
		ON ab.artist_id = bsa.artist_id
WHERE bsa.artist_rank = 1 -- Filter to only include the best-selling artist
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY total_amount_spent DESC; -- Order by total amount spent in descending order

------------------------------------------------------------------------------------------------------------

-- Q10: We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with the highest amount of purchases. 
-- Write a query that returns each country along with the top Genre. 
-- For countries where the maximum number of purchases is shared return all Genres


-- Method 1: : Using CTE with WINDOW Function- ROW_NUMBER()

WITH PopularGenre AS
(
    -- Calculate purchases per genre per country and rank them
    SELECT 
        c.country, 
        gn.name AS genre_name, 
        gn.genre_id, 
        COUNT(il.quantity) AS purchases,
        ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) as row_no
    FROM customer c
	    JOIN invoice iv 
			ON c.customer_id = iv.customer_id
	    JOIN invoice_line il 
			ON iv.invoice_id = il.invoice_id
	    JOIN track tk 
			ON il.track_id = tk.track_id
	    JOIN genre gn 
			ON tk.genre_id = gn.genre_id
    GROUP BY 1, 2, 3
    ORDER BY 1 ASC, 4 DESC
)

-- Select the most popular genre (highest purchases) for each country
SELECT * FROM PopularGenre
WHERE row_no = 1;

---------------------------------------------------------

-- Method 2: : Using Multiple CTE

WITH sales_per_country AS 
(
    -- Calculate purchases per genre per country
    SELECT 
        COUNT(*) AS purchases_per_genre, 
        c.country, 
        gn.name AS genre_name, 
        gn.genre_id
    FROM customer c
	    JOIN invoice iv 
			ON c.customer_id = iv.customer_id
	    JOIN invoice_line il 
			ON iv.invoice_id = il.invoice_id
	    JOIN track tk 
			ON il.track_id = tk.track_id
	    JOIN genre gn 
			ON tk.genre_id = gn.genre_id
    GROUP BY 2, 3, 4
    ORDER BY 2
),
max_genre_per_country AS (
    -- Determine the maximum purchases per genre in each country
    SELECT 
        MAX(purchases_per_genre) AS max_genre_number, 
        country
    FROM sales_per_country
    GROUP BY 2
    ORDER BY 2
)

-- Select the genres with the highest purchases in each country
SELECT 
    spc.country, 
    spc.purchases_per_genre, 
    spc.genre_name, 
    spc.genre_id
FROM 
    sales_per_country spc
JOIN 
    max_genre_per_country mgpc 
    ON spc.country = mgpc.country
WHERE 
    spc.purchases_per_genre = mgpc.max_genre_number
ORDER BY 
    spc.country;

------------------------------------------------------------------------------------------------------------

-- Q11: Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount. 

-- Method 1: Using CTE with WINDOW Function- ROW_NUMBER()

WITH Customter_with_country AS 
(
	SELECT c.customer_id,
		   c.first_name,
		   c.last_name,
		   iv.billing_country,
		   SUM(iv.total) AS total_spending,
		   ROW_NUMBER() OVER(PARTITION BY iv.billing_country 
		   					  ORDER BY SUM(iv.total) DESC) AS row_no 
	FROM invoice iv
		JOIN customer c   
			ON c.customer_id = iv.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4 ASC,5 DESC
)

SELECT * 
FROM Customter_with_country 
WHERE row_no = 1;

---------------------------------------------------------

-- Method 2: using multiple CTE 

WITH customter_with_country AS 
(
    -- Calculate total spending per customer and include their billing country
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        iv.billing_country,
        SUM(iv.total) AS total_spending
    FROM invoice iv
        JOIN customer c
        	ON c.customer_id = iv.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 2,3 DESC
),

country_max_spending AS
(
    -- Determine the maximum spending per country
    SELECT 
        billing_country,
        MAX(total_spending) AS max_spending
    FROM customter_with_country
    GROUP BY billing_country
)

-- Select customers with the highest spending in their respective countries
SELECT 
    cc.billing_country, 
    cc.total_spending, 
    cc.first_name, 
    cc.last_name, 
    cc.customer_id
FROM customter_with_country cc
    JOIN country_max_spending ms
    	ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1; -- Order the final results by billing country

------------------------------------------------------------------------------------------------------------

-- Q.12:Determine cumulative sales trends for music genres over time 
-- using sales data from a digital music store


-- Method 1- Using Recursive 

WITH RECURSIVE GenreSales AS (
    -- Base case: start with the initial month's data
    SELECT 
        g.genre_id,                  -- 1
        g.name AS genre_name,        -- 2
        i.invoice_date,              -- 3
        SUM(il.unit_price * il.quantity) AS monthly_sales, -- 4
        SUM(il.unit_price * il.quantity) AS cumulative_sales -- 5
    FROM invoice_line il
	    JOIN invoice i 
			ON il.invoice_id = i.invoice_id
	    JOIN track t 
			ON il.track_id = t.track_id
	    JOIN genre g 
			ON t.genre_id = g.genre_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 3
    LIMIT 1

    UNION ALL

    -- Recursive case: accumulate the sales month by month
    SELECT 
        gs.genre_id,
        gs.genre_name,
        i.invoice_date,
        SUM(il.unit_price * il.quantity) AS monthly_sales,
        gs.cumulative_sales + SUM(il.unit_price * il.quantity) AS cumulative_sales
    FROM GenreSales gs
    	JOIN invoice_line il 
			ON gs.genre_id = il.track_id
    	JOIN invoice i 
			ON il.invoice_id = i.invoice_id
    WHERE i.invoice_date > gs.invoice_date
    GROUP BY 1, 2, 3, 5
)

SELECT 
    genre_id, 
    genre_name, 
    invoice_date, 
    monthly_sales, 
    cumulative_sales
FROM GenreSales
ORDER BY genre_id, invoice_date;

---------------------------------------------------------

-- Method 2- Using Window function 

SELECT 
    g.genre_id,              -- 1
    g.name AS genre_name,    -- 2
    i.invoice_date,          -- 3
    ROUND(CAST(SUM(il.unit_price * il.quantity) AS numeric), 2) 
		AS monthly_sales,        -- 4
    ROUND(CAST(SUM(SUM(il.unit_price * il.quantity)) 
		OVER (PARTITION BY g.genre_id ORDER BY i.invoice_date) AS numeric), 2) 
		AS cumulative_sales  -- 5
FROM invoice_line il
	JOIN invoice i 
		ON il.invoice_id = i.invoice_id
	JOIN track t 
		ON il.track_id = t.track_id
	JOIN genre g 
		ON t.genre_id = g.genre_id
GROUP BY 1, 2, 3
ORDER BY 1, 3;

------------------------------------------------------------------------------------------------------------
