
WITH source AS (

    SELECT
        TRIM(practice_area_id) AS practice_area_id,
        TRIM(practice_group) AS practice_group,
        TRIM(practice_area) AS practice_area,
        NULLIF(TRIM(sub_practice_area), '') AS sub_practice_area,
        UPPER(TRIM(country)) AS country,
        is_active
    FROM {{ ref('raw_practice_areas') }}

)

SELECT *
FROM source