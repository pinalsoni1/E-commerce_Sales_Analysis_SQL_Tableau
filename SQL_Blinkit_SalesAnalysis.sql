-- To check if the table is imported
select * from "Blinkit_Data"

select count(*) from "Blinkit_Data"

---------------------------------- DATA CLEANING ------------------------------
update "Blinkit_Data"
set "Item Fat Content" = 
	case when "Item Fat Content" in ('LF', 'low fat') then 'Low Fat'
		 when "Item Fat Content" in ('reg') then 'Regular'
		 else "Item Fat Content"
	end

-- To check if it was really changed
select distinct "Item Fat Content", count("Item Fat Content")
from "Blinkit_Data"
group by "Item Fat Content"

----------------------------------- DATA ANALYSIS -----------------------------

------------ Total revenue generated from all items sold in Millions:
select round(sum("Sales")/1000000, 2) as "Total_Sales_in_Millions"
from "Blinkit_Data"

-- Another way to do it by casting the column to Decimal:
select cast(sum("Sales")/1000000 as decimal(10, 2)) as "Total_Sales_Millions"
from "Blinkit_Data"

------------- Average Sales:
select round(avg("Sales"), 2) as "Average_Sales"
from "Blinkit_Data"

-- Average Rating:
select round(avg("Rating"),2) as "Average_Rating"
from "Blinkit_Data"


--Total Sales by Fat Content
select "Item Fat Content",
	   concat(round(sum("Sales")/1000, 2), ' k') as "Total Sales_in_Thousands",
	   round(avg("Sales"), 2) as "Average_Sales",
	   count(*) as "No_of_Items"
from "Blinkit_Data"
group by "Item Fat Content"
order by "Total Sales_in_Thousands" Desc


--Total Sales by Item Type
select "Item Type",
	   round(sum("Sales"), 2) as "Total Sales",
	   round(avg("Sales"), 2) as "Average_Sales",
	   round(avg("Rating"),2) as "Average_Rating",
	   count(*) as "No_of_Items"
from "Blinkit_Data"
group by "Item Type"
order by "Total Sales" Desc
limit 5


-- Fat Content by Outlet type for Total Sales
select "Outlet Location Type",
	   "Item Fat Content",
	   round(sum("Sales"), 2) as "Total Sales",
	   round(avg("Sales"), 2) as "Average_Sales",
	   round(avg("Rating"),2) as "Average_Rating",
	   count(*) as "No_of_Items"
from "Blinkit_Data"
group by "Outlet Location Type", "Item Fat Content"
order by "Total Sales" Desc



-- Total Sales for Outlet Type and Fat content as columns
select "Outlet Location Type",
	round(sum(case when "Item Fat Content" = 'Low Fat' then "Sales" else 0 end),2) as "Low Fat sales",
	round(sum(case when "Item Fat Content" = 'Regular' then "Sales" else 0 end),2) as "Regular sales",

	round(avg(case when "Item Fat Content" = 'Low Fat' then "Sales" else 0 end), 2) as "Low fat avg sales",
	round(avg(case when "Item Fat Content" = 'Regular' then "Sales" else 0 end),2) as "Regular avg sales",

	round(avg(case when "Item Fat Content" = 'Low Fat' then "Rating" else 0 end), 2) as "Low fat avg rating",
	round(avg(case when "Item Fat Content" = 'Regular' then "Rating" else 0 end),2) as "Regular avg rating"
from "Blinkit_Data"
group by "Outlet Location Type"
order by "Outlet Location Type" asc



-- Total sales by Outlet Establishment year
select "Outlet Establishment Year",
		round(sum("Sales"), 2) as "Total Sales",
	   	round(avg("Sales"), 2) as "Average_Sales",
	   	round(avg("Rating"),2) as "Average_Rating",
	   	count(*) as "No_of_Items"	
from "Blinkit_Data"
group by "Outlet Establishment Year"
order by "Outlet Establishment Year"


------------- Percentage of sales by outlet size
select "Outlet Size",
		sum("Sales") as "Total Sales",
		concat(round(sum("Sales")*100/ sum(sum("Sales")) over(), 2), '%') as "Percent sales"
from "Blinkit_Data"
group by "Outlet Size"



-- Sales by Outlet Location:

select "Outlet Location Type",
		round(sum("Sales"), 2) as "Total Sales",
	   	round(avg("Sales"), 2) as "Average_Sales",
	   	round(avg("Rating"),2) as "Average_Rating",
		concat(round(sum("Sales")*100/ sum(sum("Sales")) over(), 2), '%') as "Percent sales",
	   	count(*) as "No_of_Items"	
from "Blinkit_Data"
group by "Outlet Location Type"
order by "Outlet Location Type" DEsc



--------------- Performance metrics by Outlet Type:

select "Outlet Type",
		round(sum("Sales"), 2) as "Total Sales",
	   	round(avg("Sales"), 2) as "Average_Sales",
	   	round(avg("Rating"),2) as "Average_Rating",
		concat(round(sum("Sales")*100/ sum(sum("Sales")) over(), 2), '%') as "Percent sales",
	   	count(*) as "No_of_Items"	
from "Blinkit_Data"
group by "Outlet Type"
order by "Total Sales" Desc




---------------------------------- ADVANCED DATA ANALYSIS ------------------------------------

-------------- 1. Which are the top 3 selling products for each Outlet Type?

with cte as (
	SELECT 
	    "Outlet Type",
	    "Item Identifier",
		"Item Type",
	    SUM("Sales") AS total_sales,
	    RANK() OVER (PARTITION BY "Outlet Type" ORDER BY SUM("Sales") DESC) AS sales_rank
	FROM "Blinkit_Data"
	GROUP BY "Outlet Type", "Item Identifier", "Item Type"
	ORDER BY "Outlet Type", sales_rank
	)
SELECT * FROM CTE
WHERE SALES_RANK <= 3
;


-- 2. Find duplicate item entries for the same outlet (if you expect duplicates):

WITH CTE AS(
	SELECT "Outlet Identifier",
			"Item Identifier",
			ROW_NUMBER() OVER (PARTITION BY "Outlet Identifier", "Item Identifier" ORDER BY "Sales" DESC) AS row_num
	FROM "Blinkit_Data"
)
SELECT * 
FROM CTE
WHERE row_num > 1
ORDER BY "Outlet Identifier", "Item Identifier", row_num


-- 3. Distribute products into quartiles based on total sales.

SELECT "Item Identifier",
		"Item Type",
		sum("Sales") as "Total Sales",
		NTILE(4) OVER (PARTITION BY "Item Type" ORDER BY sum("Sales") DESC) as Sales_Quartiles
FROM "Blinkit_Data"
GROUP BY  "Item Identifier", "Item Type"



-- 4. For each item type, calculate total sales per item, and what % that item contributes to its type.

select "Item Type",
		"Item Identifier",
		sum("Sales") as Total_Sales,
		sum("Sales") * 100 /sum(sum("Sales")) over (partition by "Item Type" ) as Percent_Contribution
from "Blinkit_Data"
where "Item Type" = 'Baking Goods'
group by "Item Type", "Item Identifier"
order by "Item Type"




-- 5. For each outlet type (e.g., Supermarket Type1, Grocery Store), rank the items based on their total sales.

select "Outlet Type",
		"Item Identifier",
		sum("Sales") as Total_sales,
		rank() over (partition by "Outlet Type" order by sum("Sales") desc) as Sales_rank
from "Blinkit_Data"
group by "Outlet Type", "Item Identifier"
order by "Outlet Type", Total_sales desc




------------------- 6. Calculate the average sales per item in each outlet, and rank the outlets within their location tier by average sales.

select "Outlet Location Type",
		"Outlet Identifier",
		avg("Sales") as avg_sales,
		rank() over (partition by "Outlet Location Type" order by avg("Sales") desc) as avg_sales_rank
from "Blinkit_Data"
group by "Outlet Location Type", "Outlet Identifier"




---------------- 7. Item Type Contribution per Outlet Type (To support category mix strategy)

SELECT "Outlet Type",
       "Item Type",
       SUM("Sales") AS total_sales,
       ROUND(SUM("Sales") * 100.0 / SUM(SUM("Sales")) OVER (PARTITION BY "Outlet Type"), 2) AS contribution_percent
FROM "Blinkit_Data"
GROUP BY "Outlet Type", "Item Type"
ORDER BY "Outlet Type", contribution_percent DESC






select "Outlet Type",
		"Item Identifier",
		sum("Sales") as totalsales
from "Blinkit_Data"

group by "Outlet Type", "Item Identifier"
order by "Outlet Type", totalsales desc







