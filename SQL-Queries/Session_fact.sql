WITH session_base AS 
(
     SELECT 
           us.session_id,
           us.user_id,
           u.client_id,
           us.session_date,
           us.session_type_id,
           st.session_type_name,
           us.network_type_id,
           nt.network_type_description,
           us.app_version,
           us.session_duration,
           us.session_error_exists,
           us.session_error_type
     FROM user_sessions AS us
     INNER JOIN users AS u 
           ON us.user_id = u.user_id

     INNER JOIN Session_type AS st 
           ON us.session_type_id = st.session_type_id
     
     INNER JOIN Network_type AS nt
           ON us.network_type_id = nt.network_type_id
),

session_wf as 
(   SELECT sb.*,
           
           ROW_NUMBER () OVER (
                   PARTITION BY client_id
                   ORDER BY session_date DESC,
                            session_id DESC)
                   AS session_rank,
           COUNT(*) OVER (
                   PARTITION BY client_id)
                   AS customer_session_count,
           SUM(session_duration) OVER (
                   PARTITION BY client_id)
                   AS customer_total_session_duration,
           AVG(CAST(session_duration AS DECIMAL(18,2))) OVER (
                   PARTITION BY client_id)
                   AS customer_average_session_duration
           
    FROM session_base AS sb
),

session_fact AS 
(   SELECT 
          session_id,
          user_id,
          client_id,
          session_date,
          session_type_id,
          session_type_name,
          network_type_id,
          network_type_description,
          app_version,
          session_duration,
          session_error_exists,
          session_error_type,
          session_rank,
          customer_session_count,
          customer_total_session_duration,
          customer_average_session_duration,

          CASE WHEN session_error_exists = 1 
               THEN 1
               ELSE 0
               END AS has_error,
          CASE WHEN session_duration >= 4 
               THEN 'Long'
               WHEN session_duration >= 2
               THEN 'Medium'
               ELSE 'Short'
               END AS session_duration_category
    FROM session_wf
)

SELECT *
FROM session_fact
