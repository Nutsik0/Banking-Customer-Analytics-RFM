WITH cutomer_application_activity AS
(
    SELECT
          client_id,
          MAX  (a.application_date)   AS last_application_date,
          COUNT(a.application_id)     AS application_frequency,
          SUM  (a.application_amount) AS total_requested_amount,
          AVG  (a.application_amount) AS average_application_amount,
          AVG  (a.application_interest_rate) AS average_interest_rate,
          AVG  (a.application_duration) AS average_application_duration,
          SUM  (CASE WHEN ast.application_status_description = 'Approved'
                     THEN 1
                     ELSE 0
                     END) AS approved_applications
    FROM Applications AS a
    INNER JOIN  Application_status AS ast 
          ON ast.application_status_id = a.application_status_id
    GROUP BY client_id
),

customer_rfm_base AS 
(   
    SELECT 
          caa.client_id,
          caa.last_application_date,
          DATEDIFF(DAY,caa.last_application_date,
                      (SELECT MAX(application_date) 
                       FROM Applications)) AS recency_days,
          caa.application_frequency,
          caa.total_requested_amount,
          caa.average_application_amount,
          caa.average_interest_rate,
          caa.average_application_duration,
          caa.approved_applications
    FROM cutomer_application_activity AS caa
),

rfm_score_calculation AS 
(
    SELECT
          a.*,
          NTILE(5) OVER ( ORDER BY recency_days DESC) 
                          AS recency_score,
          NTILE(5) OVER ( ORDER BY application_frequency ASC)
                          AS frequency_score,
          NTILE(5) OVER ( ORDER BY total_requested_amount ASC)
                          AS monetary_score

    FROM customer_rfm_base AS a
),

rfm_final AS 
(
    SELECT 
          a.*,
          CONCAT(recency_score,
                 frequency_score,
                 monetary_score)
                 AS rfm_score,
          CASE WHEN recency_score >= 4 AND 
                    frequency_score >= 4 AND 
                    monetary_score >= 4
               THEN 'Champion'

               WHEN recency_score >= 4 AND
                    frequency_score >= 3 
               THEN 'Loyal Customer'

               WHEN recency_score >= 4 AND
                    frequency_score <=2 
               THEN 'New / Potential Customers'

               WHEN recency_score <= 2 AND 
                    frequency_score >= 3 
               THEN 'At Risk'

               WHEN recency_score <= 2 AND 
                    frequency_score <= 2 AND
                    monetary_score <= 2 
               THEN 'Inactive'
               ELSE 'Regular Customer'
               END AS rfm_segment
          
    FROM rfm_score_calculation AS a
)

SELECT *
FROM rfm_final