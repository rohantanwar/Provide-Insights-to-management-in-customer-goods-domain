use gdb023;
-- Q1
SELECT distinct market FROM gdb023.dim_customer where customer = 'Atliq Exclusive' and region = 'APAC';


-- Q2
with Unique_product_2020 as
(SELECT  count(distinct product_code) as Unique_products_2020 FROM gdb023.fact_gross_price where fiscal_year = 2020),
unique_product_2021 as
(SELECT  count(distinct product_code) as Unique_products_2021 FROM gdb023.fact_gross_price where fiscal_year = 2021)
select a.unique_products_2020, 
	   b.unique_products_2021,
       round((((b.unique_products_2021-a.unique_products_2020)/a.unique_products_2020)*100),2) as percent_chg
from unique_product_2020 a
join unique_product_2021 b;

-- Q3
SELECT segment, count(distinct product_code) as product_count FROM gdb023.dim_product
group by segment
order by product_count desc;

-- Q4
with unique_2020 as 
(select p.segment, count(distinct p.product_code) as product_count_2020
from dim_product p
inner join fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = 2020
group by p.segment
order by product_count_2020 desc),
 unique_2021 as 
(select p.segment, count(distinct p.product_code) as product_count_2021
from dim_product p
inner join fact_sales_monthly s
on p.product_code = s.product_code
where s.fiscal_year = 2021
group by p.segment
order by product_count_2021 desc)
select a.segment, a.product_count_2020, b.product_count_2021,
(b.product_count_2021-a.product_count_2020)as diff
from unique_2020 a
join unique_2021 b
on a.segment = b.segment;

-- Q5
select m.product_code, p.product, m.manufacturing_cost 
from fact_manufacturing_cost m
inner join dim_product p
on m.product_code = p.product_code
where m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
union 
select m.product_code, p.product, min(m.manufacturing_cost) as manufacturing_cost
from fact_manufacturing_cost m
inner join dim_product p
on m.product_code = p.product_code
where m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);

-- Q6
select c.customer_code, c.customer, p.pre_invoice_discount_pct
from dim_customer c
inner join fact_pre_invoice_deductions  p
on c.customer_code = p.customer_code
where p.pre_invoice_discount_pct > (SELECT avg(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions) and c.market = 'india' and p.fiscal_year = 2021
order by p.pre_invoice_discount_pct desc
limit 5; 

-- Q7
select month(s.date) as month,
year(s.date) as year,
sum(round((s.sold_quantity * g.gross_price),2)) as gross_sales_amount
from fact_sales_monthly s
inner join fact_gross_price g
on s.product_code = g.product_code
inner join dim_customer c
on s.customer_code = c.customer_code
where c.customer = 'atliq exclusive'
group by month, year
order by year;

-- Q8
select
case
	when month(date) in (9, 10, 11) then 'Qtr 1'
    when month(date) in (12, 1, 2) then 'Qtr 2'
    when month(date) in (3, 4, 5) then 'Qtr 3'
    when month(date) in (6, 7, 8) then 'Qtr 4'
    end as Quarter,
    sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by Quarter
order by total_sold_quantity desc;    

-- Q9
with gross_sales_cte as 
(select c.channel,
round(sum((s.sold_quantity * g.gross_price)/1000000),2) as gross_sales_mlm
from fact_sales_monthly s
inner join fact_gross_price g
on  s.product_code = g.product_code
inner join dim_customer c
on s.customer_code = c.customer_code
where s.fiscal_year = 2021
group by c.channel
order by gross_sales_mlm desc)
select *, gross_sales_mlm*100/sum(gross_sales_mlm) over() as percent
from gross_sales_cte;


-- Q10
with division_sales_cte as 
(select p.division, s.product_code,p.product, sum(s.sold_quantity) as 'total_sold_qty', 
row_number() over (partition by p.division order by sum(s.sold_quantity) desc) as rank_order
from fact_sales_monthly s 
inner join dim_product p
on s.product_code = p.product_code
where s.fiscal_year = 2021
group by p.division, s.product_code, p.product)
select division, product_code, product, total_sold_qty, rank_order
from division_sales_cte
where rank_order <= 3;
