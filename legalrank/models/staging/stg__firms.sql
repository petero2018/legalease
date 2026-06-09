WITH source AS (

    SELECT
        TRIM(firm_ref) AS firm_ref,
        TRIM(firm_name) AS firm_name,
        UPPER(TRIM(country)) AS country,
        INITCAP(TRIM(city)) AS city,
        TRY_CAST(established_year AS INTEGER) AS established_year,
        TRY_TO_BOOLEAN(TO_VARCHAR(is_active)) AS is_active,
        CAST(created_at AS TIMESTAMP_NTZ) AS created_at,
        CAST(updated_at AS TIMESTAMP_NTZ) AS updated_at
    FROM {{ ref('raw_firms') }}

)

SELECT *
FROM source