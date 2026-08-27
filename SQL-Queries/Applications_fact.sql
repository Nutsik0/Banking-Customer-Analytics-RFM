
WITH application_base AS 
(
    SELECT
         a.application_id,
         a.client_id,
         a.application_date,
         a.application_amount,
         a.application_interest_rate,
         a.application_duration,
         a.application_type_id,
         at.application_type_description,
         a.application_status_id,
         ast.application_status_description,
         a.application_object_id,
         o.object_description,
         o.object_type_id,
         ot.object_type_description

   FROM Applications AS a
    INNER JOIN Application_type AS at
        ON a.application_type_id = at.application_type_id

    INNER JOIN Application_status AS ast 
        ON ast.application_status_id = a.application_status_id

    INNER JOIN Object AS o 
        ON o.object_id = a.application_object_id

    LEFT JOIN Object_type AS ot
        ON ot.object_type_id = o.object_type_id
),

application_wf AS 
( 
    SELECT 
         ab.*,

         ROW_NUMBER() OVER (
                  PARTITION BY client_id
                  ORDER BY application_date DESC, application_id DESC )
                  AS application_rank,

         COUNT(*) OVER (
                  PARTITION BY client_id)
                  AS customer_application_count,
         
         SUM ( application_amount) OVER (
                  PARTITION BY client_id)
                  AS customer_total_requested_amount,

         AVG (application_amount) OVER (
                  PARTITION BY client_id)
                  AS customer_average_application_amount
    FROM application_base AS ab
),

application_fact AS 
( 
     SELECT 
         application_id,
         client_id,
         application_date,
         application_amount
         application_interest_rate,
         application_duration,
         application_type_id,
         application_type_description,
         application_status_id,
         application_status_description,
         application_object_id,
         object_type_id,
         object_type_description,
         object_description,
         application_rank,
         customer_application_count,
         customer_total_requested_amount,
         customer_average_application_amount,

         CASE WHEN application_status_description = 'Approved'
              THEN 1
              ELSE 0
              END AS is_approved,
         CASE WHEN application_status_description = 'Rejected'
              THEN 1
              ELSE 0
              END AS is_rejected,
         CASE WHEN application_status_description IN ('Approved','Pre_Approved')
              THEN 1 
              ELSE 0
              END AS is_positive_decision,
         CASE WHEN application_amount < 5000
              THEN 'Small'
              WHEN application_amount < 20000
              THEN 'Medium'
              WHEN application_amount < 50000
              THEN 'Large'
              ELSE 'Very Large'
         END AS application_amount_category

     FROM application_wf 
)

SELECT *
FROM application_fact

