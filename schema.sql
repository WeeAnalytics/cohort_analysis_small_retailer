-- create a table for the invoice records
CREATE TABLE invoice (
 
    invoice         	NUMERIC,
    stock_code       	VARCHAR,
    description	        VARCHAR,
    quantity         	NUMERIC,
    price    	        NUMERIC,
    customer_id   	    VARCHAR,
    country         	VARCHAR,
    invoice_dt      	TIMESTAMP,
    invoice_time	    TIMESTAMP

 );

 
-- checking table after dataload

SELECT *
FROM invoice
LIMIT 10;

-- create a table for the stock_code and description
CREATE TABLE stock (
 
    stock_code       	VARCHAR,
    description	        VARCHAR


 );

 -- checking table after dataload

SELECT *
FROM stock;