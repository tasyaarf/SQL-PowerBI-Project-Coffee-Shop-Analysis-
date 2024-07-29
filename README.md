# Coffee Shop Sales Analysis ( SQL & Power BI Project)

### Table Of Content
- [Business Request](#business-request)
- [Data Source](#data-source)
- [Data Cleansing and Transformation](#data-cleansing-and-transformation)
- [Data Analysis](#data-analysis)
- [Data Model](#data-model)
- [Coffee Sales Dashboard](#coffee-sales-dashboard)
### Business Request
According to the business request, the following user stories were established to meet  goals and ensure that acceptance criteria were consistently met throughout the project.

|As a (role)| I want (request/demand) | So that (user value) | Acceptance Criteria |
|-----------|-------------------------|----------------------|---------------------|
|Sales Manager| To get a dashboard overview of coffee sales, amount of order, and quantity sold|Can oversee the month-on-monthincrease or decrease of sales, order,and qty sold |A Power BI dashboard with graphs and comparing the MoM pattern against previous month, Implement calendar heatmap that can be adjust based on selected month, Implement color code in calendar, darker color represent the lowest sales |
|Sales Manager| To get insight whether sales differs significantly between weekday and weekend|Can analyze performance variations|A power BI dashboard which compare sales performance between weekend and weekday|
|Sales Manager|To get insight of daily sales for the selected month, compare to the average daily sales| Can analyze which under the average performance |A Power BI dashboard which visualize daily sales and incorporate it with average line|
|Sales Manager|To get overview of coffee sales base on day and hours |Can track sales performance for each day and specific hour| A power BI dashboard that utilize heatmap to visualize sales by day day and hour|
|Sales Representative|To get detail overview of coffee shop sales per store location |Can track store which has large number of sales and identify opportunities to increase sales for store whose sales still small |A Power BI dashboard which allows me to know sales data for each store location|
|Sales Representative| To get detail overview of coffee shop sales per product category |Can track which one sold the most|A Power BI dashboard which allows me to know sales data foreach product category|
|Sales Representative|To get top 10 product based on sales volume | I can quickly know the bestperforming product |A Power BI dashboard which visualize the top 10 product|

### Data Source
The primary dataset used for this analysis is the "coffee_shop_sales.csv" file, containing detailed information about each sale made by the coffee shop.

### Data Cleansing and Transformation 
The process includes:
   1. Data loading and inspection regarding missing values, and the appropriate data type in each column 
   2. Develop clean data by eliminating redundant and unstructured data


by means of that process the dataset divided into three follwing tables :
   1. "coffee_transaction.csv" file
   2. "store.csv" file
   3. "product.csv" file 

below are the PosrgreSQL code for cleansing and transforming necessary data 

```sql
-- CLEAN AND TRANSFORM

--1.Store Table
create table store as select distinct store_id, store_location from coffee_shop_database;
alter table store add primary key (store_id);
alter table store alter column store_id set not null;
select * from store;

-- 2.Product Table
create table product as select distinct product_id, product_category, product_type, product_detail 
from coffee_shop_database order by product_id asc;
alter table product add primary key (product_id);
alter table product alter column product_id set not null;
select * from product;

---3.Transaction Table & change the date and time style
create table coffee_transaction as select 
transaction_id, transaction_date, to_date(transaction_date, 'MM/DD/YYYY'),
transaction_time, to_timestamp(transaction_time, 'HH24:MI:SS'), 
transaction_qty, unit_price, store_id, product_id from coffee_shop_database;
alter table coffee_transaction add primary key (transaction_id) ;
alter table coffee_transaction alter column transaction_id set not null;
select * from coffee_transaction;

alter table coffee_transaction
drop transaction_date,
drop transaction_time;

alter table coffee_transaction
rename column to_date to transaction_date;

alter table coffee_transaction
rename column to_timestamp to transaction_time;
alter table coffee_transaction
alter column transaction_time type time;
```
### Data Analysis 
To fulfill the business request and user needs the file of SQL script can be seen on ["Coffee_Shop_Analysis_SQL_Script"](https://github.com/tasyaarf/SQL-PowerBI-Project-Coffee-Shop-Analysis-/blob/8c1061b5976be06e4e6eea79e04714ede5192233/Coffe_Shop_Analysis_SQL_Script.sql) files

### Data Model 
Here is a data model after importing the cleaned and prepared tables into Power BI
![image](https://github.com/user-attachments/assets/d5de4078-1515-4c94-bbdc-68baaf6e95be)

the date table are created in Power BI to implement the calendar heatmap and day/hours analysis


### Coffee Sales Dashboard

The coffee sales dashboard contain the overview sales performance which can be track based on hours, day, hours and equipped with Tooltip.
the dashbord can be downloaded on ["coffee_sales_report"](https://github.com/tasyaarf/SQL-PowerBI-Project-Coffee-Shop-Analysis-/blob/084dc6180bfadbd8a20ba100be5b6ae81cfaf704/coffee_sales_report.pbix) files 

![image](https://github.com/user-attachments/assets/921ea239-f27d-4afb-a05a-b524111fe813)

## References
- http://www.youtube.com/@datatutorials1
- http://www.youtube.com/@iamaliahmad




