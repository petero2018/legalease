WITH source AS (
    SELECT * FROM {{ ref('stg__rankings') }}
),

firms AS (
    SELECT firm_ref, firm_name, country, city
    FROM {{ ref('raw_firms') }}
),

practice_areas AS (
    SELECT practice_area_id, practice_group, practice_area, sub_practice_area
    FROM {{ ref('raw_practice_areas') }}
),

joined AS (
    SELECT
        -- edition identifiers
        r.edition_year,
        r.edition_id,

        -- geography
        f.country AS firm_country,
        f.city AS firm_city,

        -- entity identifiers
        r.ranking_id,
        r.firm_ref,
        f.firm_name,
        r.practice_area_id,
        pa.practice_group,
        pa.practice_area AS practice_area_name,
        pa.sub_practice_area,

        -- ranking attributes
        r.ranking_tier,
        r.ranking_type,

        -- status fields
        CASE
            WHEN r.ranking_type = 'firm recommended' AND r.ranking_tier = 0
                THEN 'not ranked'
            WHEN r.ranking_type = 'firm to watch' AND r.ranking_tier = 0
                AND COALESCE(r.post_status, '') != 'publish'
                THEN 'not ranked'
            ELSE 'ranked'
        END AS ranking_decision_status,

        r.post_status,
        r.publication_status,
        r.listing_type,

        -- timestamps
        r.modified_ts
    FROM source r
    LEFT JOIN firms f
        ON r.firm_ref = f.firm_ref
    LEFT JOIN practice_areas pa
        ON r.practice_area_id = pa.practice_area_id
)

SELECT * FROM joined
