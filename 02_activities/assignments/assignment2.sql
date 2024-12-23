/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
product_name || ', ' 
|| coalesce(product_size,'')
|| ' (' 
|| coalesce(product_qty_type, 'unit')
 || ')'
FROM product;


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT DISTINCT customer_id
 , market_date
 , DENSE_RANK() OVER (PARTITION by customer_id ORDER BY market_date ) AS visit_number
	FROM customer_purchases;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT * FROM (
SELECT DISTINCT customer_id, market_date, DENSE_RANK() OVER (PARTITION by customer_id ORDER BY market_date DESC) AS visit_number 
FROM customer_purchases
) x
WHERE x.visit_number = 1



/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

	SELECT
    customer_id,
    product_id,
    market_date,
    COUNT(*) OVER (
        PARTITION BY
            customer_id,
            product_id
    ) AS purchase_count
FROM customer_purchases;

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name,
    TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 2)) as description
   FROM product
  WHERE INSTR(product_name, '-') > 0;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_id, product_name AS `product name`,
                 product_size  AS `product size` FROM product
WHERE product_size REGEXP '[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */


WITH sales_grouped_date AS (

    SELECT market_date,
     SUM(quantity * cost_to_customer_per_qty) AS sales
    FROM customer_purchases
    GROUP BY market_date
),


rank_sales AS (
    SELECT 
        market_date,
        sales,
        ROW_NUMBER() OVER (ORDER BY sales DESC) AS row_max,
        ROW_NUMBER() OVER (ORDER BY sales ASC) AS row_min
    FROM sales_grouped_date
)


SELECT market_date, sales AS `combined sales`, 
    'Largest Sales' AS `Sales Category`
FROM rank_sales
WHERE  row_max = 1

UNION

SELECT market_date, sales AS `combined sales`,
    'Lowest Sales' AS `Sales Category`
FROM rank_sales
WHERE  row_min = 1;





/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT
    v.vendor_name,
    p.product_name,
    SUM(5 * vi.original_price * c.customer_count) AS `combined revenue`
FROM
    vendor v
JOIN
    vendor_inventory vi ON v.vendor_id = vi.vendor_id
JOIN
    product p ON vi.product_id = p.product_id
CROSS JOIN
    (SELECT COUNT(DISTINCT customer_id) AS customer_count FROM customer) AS c
GROUP BY p.product_id, v.vendor_id;


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS temp.product_units;
CREATE TEMP TABLE temp.product_units AS
SELECT *, CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO temp.product_units (product_id, product_name, product_size,
                                                                         product_category_id, product_qty_type, snapshot_timestamp)
VALUES (103, 'Apple Pie',  '1010', 10,  'unit', CURRENT_TIMESTAMP);

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/

DELETE FROM temp.product_units 
WHERE product_id = 103;



-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


ALTER TABLE temp.product_units
ADD current_amount INT;

UPDATE temp.product_units
SET current_amount = COALESCE((
    SELECT quantity
    FROM vendor_inventory vi
    WHERE vi.product_id = product_units.product_id
    ORDER BY vi.market_date DESC
    LIMIT 1
), 0);