SELECT TOP (1000) [ORDERNUMBER]
      ,[QUANTITYORDERED]
      ,[PRICEEACH]
      ,[ORDERLINENUMBER]
      ,[SALES]
      ,[ORDERDATE]
      ,[STATUS]
      ,[QTR_ID]
      ,[MONTH_ID]
      ,[YEAR_ID]
      ,[PRODUCTLINE]
      ,[MSRP]
      ,[PRODUCTCODE]
      ,[CUSTOMERNAME]
      ,[PHONE]
      ,[ADDRESSLINE1]
      ,[ADDRESSLINE2]
      ,[CITY]
      ,[STATE]
      ,[POSTALCODE]
      ,[COUNTRY]
      ,[TERRITORY]
      ,[CONTACTLASTNAME]
      ,[CONTACTFIRSTNAME]
      ,[DEALSIZE]
  FROM [sales_data].[dbo].[sales_data]
  
--Sales by Productline
SELECT PRODUCTLINE, SUM(SALES) AS total_revenue
FROM sales_data
GROUP BY PRODUCTLINE
ORDER BY 2 DESC;

--Sales by year
SELECT YEAR_ID, SUM(SALES) AS total_revenue
FROM sales_data
GROUP BY YEAR_ID
ORDER BY 2 DESC;

--Sales by dealsize
SELECT DEALSIZE, SUM(SALES) AS total_revenue
FROM sales_data
GROUP BY DEALSIZE
ORDER BY 2 DESC;

--Best month for sales in the specific year? How much was earned that month?
SELECT MONTH_ID,SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data
WHERE YEAR_ID = 2004 --Choose year
GROUP BY MONTH_ID
ORDER BY 2 DESC;

--November seems the best month , what product do they sell?
SELECT MONTH_ID,PRODUCTLINE,SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 --Choose year
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

--RFM Analysis
--WHO IS OUR BEST CUSTOMERS?

DROP TABLE IF EXISTS #rfm
WITH rfm AS (
	SELECT 
		CUSTOMERNAME, SUM(SALES) AS MonetaryValue, COUNT(ORDERNUMBER) AS Frequency, MAX(ORDERDATE) AS last_order_date,
		(SELECT MAX(ORDERDATE) FROM sales_data) AS max_order_date,
		DATEDIFF(day,MAX(ORDERDATE),(SELECT MAX(ORDERDATE) FROM sales_data)) AS Recency
	FROM sales_data
	GROUP BY CUSTOMERNAME
), rfm_calc AS (
	SELECT rfm.*,
		NTILE(4) OVER (ORDER BY Recency) AS rfm_recency, -- Divide into 4 groups
		NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
	FROM rfm
)
	SELECT *,rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell, 
		CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_monetary AS varchar) AS rfm_str
	into #rfm
	FROM rfm_calc;


SELECT CUSTOMERNAME , rfm_recency , rfm_frequency , rfm_monetary, rfm_str,
		CASE WHEN rfm_str LIKE '1%' THEN 'Lost' 
			WHEN rfm_str LIKE  '2%' THEN 'Slipping Away'
			WHEN rfm_str LIKE '[3,4]%1' THEN 'Active - Low Value'
			WHEN rfm_str LIKE '[3,4]%2' THEN 'Active - Medium Value'
			WHEN rfm_str LIKE '[3,4]%[34]' THEN 'Active - High Value'
			END AS rfm_segment 
FROM #rfm
ORDER BY rfm_recency , rfm_frequency , rfm_monetary

--BONUS
--How many products in each order that is shipped?
WITH cte AS (
	SELECT ORDERNUMBER, STRING_AGG(PRODUCTCODE,',') AS Products -- Concatenate the product code into a string
	FROM sales_data
	WHERE STATUS = 'Shipped' 
	GROUP BY ORDERNUMBER
)
	SELECT ORDERNUMBER, Products, LEN(Products) - LEN(REPLACE(Products,',','')) + 1 AS Number_of_products  -- The number of products is the length of the string - the length of the string without a comma + 1
	FROM cte
	WHERE LEN(Products) - LEN(REPLACE(Products,',','')) + 1 >= 2 --Only include the order has more than 2 products
	ORDER BY 3

