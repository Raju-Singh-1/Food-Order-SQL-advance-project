-- Top 3 outlet by cuisine type without using limit and top function

with top_3 as(
select Cuisine,restaurant_id,count(*) as total_count,
row_number() over (partition by cuisine order by count(*) desc)  as ranking
from orders 
group by Cuisine,Restaurant_id)
select cuisine,restaurant_id,total_count,ranking
from top_3
where ranking<=3;


-- find the daily new customer count from launch date( every day how many customer aqcuiring
with cte as( 
select customer_code,date(min(placed_at) ) as first_order
from orders
group by customer_code)
select first_order,count(*)
from cte
group by first_order
order by first_order;

-- count of all the rows who were acquire in jan 2025 and only one order palced in jan and did not place any order 
select customer_code,count(*) order_count
from orders
where month(placed_at)=1 and year(placed_at)=2025
and Customer_code not in (select distinct Customer_code from orders 
where not  (month(placed_at)=1 and year(Placed_at)=2025))
group by customer_code
having order_count=1;

-- list all the customer with no order in the last 7 days but were acquire one month ago thier first order on promo
with cte as (
select customer_code,max(placed_at) latest_order,min(Placed_at) as first_order
from orders
group by Customer_code)
select c.*, promo_code_name as first_promo_code
from orders o join cte as c on c.Customer_code=o.Customer_code and o.Placed_at=c.first_order
where latest_order < curdate()- interval 7 day and
first_order < curdate() - interval 30 day
and promo_code_name is not null;

select customer_code,max(placed_at) latest_order,min(Placed_at) as first_order,promo_code_name
from orders
where max(placed_at) < curdate() - interval 7 day and min(Placed_at) < curdate() - interval 30 day
and Promo_code_Name is not null
group by Customer_code,Promo_code_Name;

-- growth team is plnning for to create a trigger to target a customer after their ecery third order with personized communication
-- they have asked to create a query for this 

with cte as (
select * ,
row_number() over(partition by customer_code order by Placed_at) as ranking
from orders)
select * from cte
where ranking%3=0;

-- list customer who placed more than one order and all the order promo only
select customer_code,count(promo_code_name) promo_order,count(*) total_order
from orders
group by Customer_code
having count(*)>1 and total_order=promo_order;

-- what percent of customer were organically aquired in jan 2025.(placed their first without promo code)
with cte as (
select *,
row_number() over (partition by customer_code order by placed_at) ranking
from orders
where month(date(placed_at))=1)
select count(case when ranking=1 and promo_code_name is null then 1 end)*100/count(distinct customer_code) as percent
from cte;