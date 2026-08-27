WITH customer_base AS 
(
	 SELECT 
	       c.id,
		   c.gender,
		   c.birth_date,
		   c.residency_id,
		   c.city_id,
		   c.customer_income,
		   ci.city_name,
		   co.country_name,
		   co.country_code
	 FROM Customer AS c

	 LEFT JOIN City AS ci 
	      ON c.city_id = ci.city_id
	 LEFT JOIN Countries AS co
	      ON c.residency_id = co.country_id
)

SELECT 
		id,
		gender,
		birth_date,
		residency_id,
		city_id,
		customer_income,
		city_name,
		country_name,
		country_code
FROM customer_base