-- IMPORT DATA
CREATE TABLE coffee_shop_database (
transaction_id int primary key,
transaction_date varchar,
transaction_time varchar,
transaction_qty int,
store_id int,
store_location varchar,
product_id int,
unit_price numeric,
product_category varchar,
product_type varchar,
product_detail varchar);
copy coffee_shop_database from 'C:\Program Files\PostgreSQL\16\coffee_shop_sales.csv' CSV header ;

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

-- CALCULATION --

-- Total Sales & MoM Decrease or Increase
select date_part('month', transaction_date) as month, 
(round((sum(transaction_qty * unit_price))/1000::numeric,0)||'K')as total_sales,
(sum(transaction_qty * unit_price) - lag(sum(transaction_qty * unit_price),1) over(order by date_part('month',transaction_date))) as mom_sales_difference,
(sum(transaction_qty * unit_price) - lag(sum(transaction_qty * unit_price),1) over(order by date_part('month',transaction_date)))/ 
(lag(sum(transaction_qty * unit_price),1) over(order by date_part('month', transaction_date))) * 100 as mom_increase_percentage
from coffee_transaction
where date_part('month',transaction_date) in (1,2,3,4,5,6)
group by date_part('month',transaction_date)
order by date_part('month',transaction_date);

-- Total order and MoM increase/decrease percentage for each month
with monthly_order as
 	(select date_part('month',transaction_date) as month_num,
 	count(transaction_id) as total_order,
 	lag(count(transaction_id),1) over (order by date_part('month',transaction_date)) as prev_month_order
 	from coffee_transaction
 	group by date_part('month',transaction_date))
select
	month_num, total_order, 
	total_order - prev_month_order as mom_order_difference,
	case
		when prev_month_order <> 0 then 
		((total_order - prev_month_order)/cast(prev_month_order as numeric))*100
		else NULL
		end as mom_order_percentage
from monthly_order
order by month_num;

-- Total quantity sold and mom qty increase/decrease percentage
with monthly_qty_sold as
 	(select date_part('month',transaction_date) as month_num,
 	sum(transaction_qty) as total_qty_sold,
 	lag(sum(transaction_qty),1) over (order by date_part('month',transaction_date)) as prev_month_qty
 	from coffee_transaction
 	group by date_part('month',transaction_date))
select
	month_num, total_qty_sold, 
	total_qty_sold - prev_month_qty as mom_qty_difference,
	case
		when prev_month_qty <> 0 then 
		((total_qty_sold - prev_month_qty)/cast(prev_month_qty as numeric))*100
		else NULL
		end as mom_qty_percentage
from monthly_qty_sold
order by month_num;

-- calendar heatmap (daily sales, order,quantity)
select 
sum(transaction_qty * unit_price) as total_sales,
count(transaction_id) as total_order,
sum(transaction_qty) as total_quantity
from coffee_transaction
where transaction_date = '2023-05-18';

-- sales analysis by weekdays and weekend
select 
date_part('month', transaction_date) as month_num,
sum(unit_price * transaction_qty) as total_sales,
case
	when extract(isodow from transaction_date) in (6,7) then 'weekend'
	else 'weekday'
	end as day_type
from coffee_transaction
where date_part('month', transaction_date) in (1,2,3,4,5,6)
group by 
date_part('month', transaction_date),
case
	when extract(isodow from transaction_date) in (6,7) then 'weekend'
	else 'weekday'
	end;
	
--sales analysis by store location 
with store_total_sales as 
	(select date_part('month',transaction_date) as month_num, b.store_location, sum(transaction_qty * unit_price) as total_sales,
	lag(sum(transaction_qty * unit_price),1) over (partition by store_location order by date_part('month',transaction_date)) as prev_month_sales
	from coffee_transaction as a left join store as b on a.store_id=b.store_id
	group by b.store_location, date_part('month', transaction_date)
	order by month_num, total_sales desc)
select month_num, store_location, total_sales, 
total_sales - prev_month_sales as sales_difference,
case 
	when prev_month_sales <> 0 then 
	((total_sales - prev_month_sales)/cast(prev_month_sales as numeric))*100 
	else NULL 
	end as mom_sales_percentage
from store_total_sales
group by store_location, month_num, total_sales, prev_month_sales
order by month_num, total_sales desc;

-- daily sales analysis with average line
with sales_analysis as 
	(select date_part('month', transaction_date) as month_num, date_part('day', transaction_date) as day_of_month,
	sum(transaction_qty * unit_price) as total_sales
	from coffee_transaction
	group by day_of_month, month_num 
	order by month_num)
select 
	month_num,day_of_month, total_sales, 
	case
	when total_sales > avg(total_sales) over (partition by month_num )
	then 'Above Average'
	else 'Below Average'
	end as sales_status
from sales_analysis
order by month_num ;


--sales analysis by product category
select 
b.product_category, sum(transaction_qty * unit_price) as total_sales 
from coffee_transaction as a left join product as b on a.product_id = b.product_id
where date_part('month',transaction_date) = 5 -- in may
group by product_category
order by total_sales desc;

-- Top 10 product by sales 
select b.product_type, sum(transaction_qty * unit_price) as total_sales 
from coffee_transaction as a left join product as b on a.product_id = b.product_id
where date_part('month',transaction_date) = 5 -- in may
group by product_type
order by total_sales desc
limit 10;

--sales analysis by day and hours
select sum(transaction_qty * unit_price) as total_sales,
count(transaction_id) as total_order,
sum(transaction_qty) as total_quantity
from coffee_transaction
where 
 date_part ('month',transaction_date) =5 -- in may
 and extract(isodow from transaction_date) = 2 --on tuesday
 and extract(hour from transaction_time)= 8; ----at hour number 8 eg. 8am
 
-- sales on monday, tuesday... in may
select to_char(transaction_date,'Day') as day_of_order, 
sum(transaction_qty * unit_price) as total_sales
from coffee_transaction
where date_part('month',transaction_date) = 5
group by day_of_order
order by total_sales desc;

-- sales on hour in may
select extract(hour from transaction_time) as hour_of_order, 
sum(transaction_qty * unit_price) as total_sales
from coffee_transaction
where date_part('month',transaction_date) = 5
group by hour_of_order
order by hour_of_order asc;	