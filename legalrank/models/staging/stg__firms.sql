WITH source AS (

    SELECT
        TRIM(firm_ref) AS firm_ref,
        TRIM(firm_name) AS firm_name,
        UPPER(TRIM(country)) AS country,
        INITCAP(TRIM(city)) AS city,
        established_year,
        is_active,
        created_at,
        updated_at
    FROM {{ ref('raw_firms') }}

)

SELECT *
FROM source