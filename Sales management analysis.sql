USE [Superstore_Data]
GO

----------------INSPECTING DATA--------------------------
SELECT *
FROM [dbo].[Sales_Data]

-----------------CLEAN DATA------------------------------
----Delete unnecessary data (row_ID and Postal_code)
ALTER TABLE [dbo].[Sales_Data]
DROP COLUMN ROW_ID, Postal_Code

----Checking null values in non-null attributes (OrderID, CustomerID, ProductID)
SELECT *
FROM [dbo].[Sales_Data]
WHERE Order_ID IS NULL  

SELECT *
FROM [dbo].[Sales_Data]
WHERE Customer_ID IS NULL 

SELECT *
FROM [dbo].[Sales_Data]
WHERE Product_ID IS NULL 

----Adding OrderedYearID and OrderedMonthID columns from existing Order_Date
ALTER TABLE [dbo].[Sales_Data]
ADD OrderedYearID int, 
	OrderedMonthID int

UPDATE [dbo].[Sales_Data]
SET OrderedYearID = YEAR(Order_Date),
	OrderedMonthID = MONTH(Order_Date)
	   	 
-----------------AREA ANALYSIS-----------------------------
----Top 20 States by Sales
SELECT Top 20 State, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	ROUND(SUM(Sales)*100/(SELECT SUM(Sales) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY State
ORDER BY 2 DESC

----Top 20 States by Profits
SELECT Top 20 State, 
	ROUND(SUM(Profit),2) AS Total_Rev,
	ROUND(SUM(Profit)*100/(SELECT SUM(Profit) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY State
ORDER BY 2 DESC

----Top 20 Cities by Sales
SELECT Top 20 City, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	ROUND(SUM(Sales)*100/(SELECT SUM(Sales) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY City
ORDER BY 2 DESC

----Top 20 Cities by Profits
SELECT Top 20 City, 
	ROUND(SUM(Profit),2) AS Total_Rev,
	ROUND(SUM(Profit)*100/(SELECT SUM(Profit) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY City
ORDER BY 2 DESC

----Sales by Regions
SELECT Region, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	ROUND(SUM(Sales)*100/(SELECT SUM(Sales) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Region
ORDER BY 2 DESC

----Profit by Regions
SELECT Region, 
	ROUND(SUM(Profit),2) AS Total_Rev,
	ROUND(SUM(Profit)*100/(SELECT SUM(Profit) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Region
ORDER BY 2 DESC

-----------------PRODUCT ANALYSIS-----------------------------
----Sales by Category
SELECT Category, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	ROUND(SUM(Sales)*100/(SELECT SUM(Sales) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Category
ORDER BY 2 DESC

----Profit by Category
SELECT Category, 
	ROUND(SUM(Profit),2) AS Total_Rev,
	ROUND(SUM(Profit)*100/(SELECT SUM(Profit) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Category
ORDER BY 2 DESC

----Sales by Sub-Category
SELECT Sub_Category, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	ROUND(SUM(Sales)*100/(SELECT SUM(Sales) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Sub_Category
ORDER BY 2 DESC

----Profit by Sub-Category
SELECT Sub_Category, 
	ROUND(SUM(Profit),2) AS Total_Rev,
	ROUND(SUM(Profit)*100/(SELECT SUM(Profit) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Sub_Category
ORDER BY 2 DESC

----What produt'S sub-category are most often sold together?
SELECT DISTINCT Order_Id, STUFF(
	(SELECT ',' + Sub_Category
	FROM [dbo].[Sales_Data] AS s1
	WHERE Order_ID IN
		(
			SELECT Order_ID
			FROM (
				SELECT Order_ID, COUNT(*) AS Num_Of_Products
				FROM [dbo].[Sales_Data]
				GROUP BY Order_ID
				)a
			WHERE a.Num_Of_Products =4
		)
		AND s1.Order_ID = s2.Order_ID
		FOR XML PATH ('')
	)
	,1,1,'')
FROM [dbo].[Sales_Data] AS s2
ORDER BY 2 DESC

-----------------CUSTOMER ANALYSIS-----------------------------
----Sales by Customer's segment
SELECT Segment, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	ROUND(SUM(Sales)*100/(SELECT SUM(Sales) FROM [dbo].[Sales_Data]),2) AS Percent_Rev
FROM [dbo].[Sales_Data]
GROUP BY Segment
ORDER BY 2 DESC

----Defined groups of customers based on the RFM Analysis (recency, frequency, and monetary)
--Create ctes and temp table (rfm) to store ctes outputs
;WITH 
rfm AS
(
	SELECT 
			Customer_Name,
			SUM(Sales) as Moneytary_value,
			AVG(Sales) as Avg_Moneytary_value,
			COUNT(Order_ID) as Frequency,
			DATEDIFF(DD,MAX(Order_Date),(SELECT MAX(Order_Date) FROM [dbo].[Sales_Data])) as Recency 
	FROM [dbo].[Sales_Data]
	GROUP BY Customer_Name
),
rfm_calc AS
(
	SELECT 
			r.*,
			NTILE(4) OVER(ORDER BY Recency DESC) rfm_Recency, --Order DESC to make sure the order range consistence with frequency and moneytary value
			NTILE(4) OVER(ORDER BY Frequency) rfm_Frequency,
			NTILE(4) OVER(ORDER BY Avg_Moneytary_value) rfm_Avg_Moneytary_value
	FROM rfm as r
)
SELECT
		c.*, rfm_Recency + rfm_Frequency +rfm_Avg_Moneytary_value as rfm_cell,
		CAST (rfm_Recency as varchar) + CAST (rfm_Frequency as varchar) +CAST (rfm_Avg_Moneytary_value as varchar) as rfm_cell_string
INTO rfm
FROM rfm_calc as c

--Inspecting data in temp table
SELECT *
FROM rfm
--Customer segmentaion
SELECT 
		Customer_Name,
		rfm_Recency,
		rfm_Frequency,
		rfm_Avg_Moneytary_value,
		CASE 
			WHEN rfm_cell_string in (111,112,113,114,121,122,123,124,211,212,213,214) then 'Lost_Customer'
			WHEN rfm_cell_string in (131,132,133,134,141,142,143,144,221,222) then 'Low_Value_Customer'
			WHEN rfm_cell_string in (223,224,231,232,233,234,241,242,243,244) then 'Potential_Customer'
			WHEN rfm_cell_string in (311,312,313,314,321,411,412,413,414,421) then 'New_Customer'
			WHEN rfm_cell_string in (322,323,324,331,332,341,342,422,423,424,431,432,441,442) then 'Active_Customer'
			WHEN rfm_cell_string in (333,334,344,433,434,443,444) then 'High_Value_Customer'
		END rfm_Segment
FROM rfm 

SELECT DISTINCT rfm_cell_string
FROM rfm


-----------------SALES/PROFITS TIMESERTIES ANALYSIS-----------------------------
----Which year have the highest sale revenue/ profit
SELECT OrderedYearID, 
	ROUND(SUM(Sales),2) AS Total_Rev
FROM [dbo].[Sales_Data]
GROUP BY OrderedYearID
ORDER BY 2 DESC

SELECT OrderedYearID, 
	ROUND(SUM(Profit),2) AS Total_Prof
FROM [dbo].[Sales_Data]
GROUP BY OrderedYearID
ORDER BY 2 DESC

----The best months for sales in specific year? and how much were earned?
SELECT OrderedMonthID, 
	ROUND(SUM(Sales),2) AS Total_Rev,
	COUNT(Order_ID) AS Frequency
FROM [dbo].[Sales_Data]
WHERE OrderedYearID = 2018  --Change the year accordingly
GROUP BY OrderedMonthId
ORDER BY 2 DESC
--9,11,12 seems to be the best months for sale within the data (always in top 3 months of sales for 4 years)

-----What product category do they sell in 9,11,12
SELECT Sub_Category,
	ROUND(SUM(Sales),2) AS Rev,
	COUNT(Order_ID) AS Frequency
FROM [dbo].[Sales_Data]
WHERE OrderedYearID = 2017 --change the year accordingly
	AND OrderedMonthID IN (9,11,12)
GROUP BY Sub_Category
ORDER BY 3 DESC










