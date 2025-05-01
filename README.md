# Customer & Sales segmentation Project
Data warehousing, Exploratory Data Analysis, and Advanced Data Analytics. Based on the databases of the creator 'Data with Baraa'.


## Project Objective

A mid-size internationsl retailer with an extensive product catalog in electronics and home goods is aiming to optimize customer retention and increase sales through data-driven insights. Despite having substantial volumes of transactional, customer, and product-level data, this information has historically been underutilized for strategic decision-making.

This project aims to fully leverage the company's existing data, customer demographics, sale transactions, and product catalog data to deliver actionable insights that inform and analyse **customer behavior**, **sales performance**, and **segmentation strategies** to optimize sales by supporting marketing and retention decisions. Through advanced SQL querying and visuals, the analysis integrates both analytical and business perspectives. We are requested to provide:

- **Customer segmentation**: Classification of customers based on their lifecycle, monetary contribution, and behavior patterns.
- **Sales Performance**: Temporal analysis of historical sales trends, including monthly revenue, average order value (AOV), and purchase frequency by segment and age group.
- **Demographic Profiling**: Breakdown of customer spending and engagement by age group, supported by dynamic age derived from birthdate data.
- **Customer Lifecycle and Retention**: Measurement of customer lifespan, recency, and risk indicators.
- **Dashboarding and Storytelling**: Interactive visuals designed for both exploratory analysis and executive-level reporting, with filters for segment, age, and time.

## Project Breakdown
The project relies on a simplified schema architecture for ease of querying and analysis. The database includes: 'fact_sales' for transactional data; 'dim_customers' contains customer identifiers, demographics, and acquisition data; and 'dim_products' includes product identifiers and descriptive metadata.


Before starting the analysis, a quality control check were conducted using SQL to:
- Asses missing values and null distributions.
- Validate key constraints between dimension and fact tables.
- Standardize date formats and ensure chronological integrity.
- Detect and remove duplicate records where applicable.
- Profile the structure of customer activity, such as number of orders per customer.

The analysis of the project followed a structured multi-phase workflow for clarity, modularity, and scalability:

1. **Data Warehousing**
   - Performed joins across fact and dimension tables using primary keys.
   Built reusable base tables for customer aggregation, profuct performance, and monthly sales.

2. **Exploratory Data Analysis**
   - Used simple aggregations to understand sales distributions
   - Profiled age, quantity, revenue, and frequency metrics.
   - Created temporary tables and subqueries to summarize customer metrics.
   - An order and sections were created to generate the analysis: **change over time**, **cumulative analysis**, **performance analysis**, **part-to-whole**, **data segmentation**.
     
3. **Answering Business Questions** 
   - A customer segment was constructed using CTEs and CASE statements to classify them as: VIP, Regular, and New, based on time and spend.
   - Calculate recency, frequency, and monetary metrics.
   - Analyze customer lifespan, as active months, and total contribution to revenue.
   - Calculate age from birthdate and group into demographic segments.

## Dashboard


## Conclusions
- VIP customers, long-term, high-spenders, represent only 20% of the customer base but contribute over 60% of total revenue.
- A large share of Regular customers have not purchased in the last 6 months, suggesting a potential high risk.
- Customers aged 30-49 make the majority of VIPs, indicating a clear target demographic.
- High-revenue months show strong seasonality, hinting at promotional or holiday-driven sales.
- The average customer lifespan is 14 months, suggesting a healthy but improvable retention window.

## Recommendations
- Implement a VIP Loyalty Program to reward long-term, high-spending customers to improve retention and cross-selling.
- Re-engagement Campaigns for Regulars to target those who have not ordered in the last 3 to 6 months with tailored offers.
- Age-Specific marketing to focus on digital ads and campaigns on the 30-49 age group, especially for premium products.
- Seasonality-Based Promotions to align marketing efforts with high-performing months and replicate successful seasonal strategies.
- Monitor High-Risk Indicators such as to use recency and frequency metrics to create alerts for declining customer activity and act before the risk occurs.
   
