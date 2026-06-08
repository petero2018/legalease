WITH ranked AS (
    SELECT
        r.edition_year,
        r.edition_id,
        f.country AS firm_country,
        f.city AS firm_city,
        r.ranking_id,
        r.firm_ref,
        f.firm_name,
        r.practice_area_id,
        pa.practice_group,
        pa.practice_area AS practice_area_name,
        pa.sub_practice_area,
        r.ranking_tier,
        r.ranking_type,
        CASE
            WHEN r.ranking_type = 'FIRM RECOMMENDED' AND r.ranking_tier = 0 THEN 'NOT RANKED'
            WHEN r.ranking_type = 'FIRM TO WATCH' AND r.ranking_tier = 0 AND COALESCE(r.post_status, '') != 'PUBLISH' THEN 'NOT RANKED'
            ELSE 'RANKED'
        END AS ranking_decision_status,
        r.post_status,
        r.publication_status,
        r.listing_type,
        r.modified_ts
    FROM {{ ref('stg__rankings') }} r
    LEFT JOIN {{ ref('stg__firms') }} f
        ON r.firm_ref = f.firm_ref
    LEFT JOIN {{ ref('stg__practice_areas') }} pa
        ON r.practice_area_id = pa.practice_area_id
)

SELECT * FROM ranked
