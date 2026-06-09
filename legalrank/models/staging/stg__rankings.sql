WITH source AS (
    SELECT 
        ranking_id,
        TRY_CAST(edition_year AS INTEGER) AS edition_year,
        edition_id,
         -- Invalid firm_ref values are nulled here, then filtered out below.
        -- Valid firm_ref format is F followed by four digits, e.g. F0001.
        CASE
            WHEN firm_ref IS NULL THEN NULL
            WHEN regexp_like(trim(firm_ref), '^F[0-9]{4}$') THEN trim(firm_ref)
            ELSE NULL
        end as firm_ref,
        practice_area_id,
        COALESCE(
            TRY_CAST(ranking_tier AS INTEGER),
            TRY_CAST(REGEXP_REPLACE(tier_rank, 'TIER_', '') AS INTEGER)
        ) AS ranking_tier,
        REPLACE(REPLACE(LOWER(TRIM(ranking_type)), 'firm reccommended', 'firm_recommended'),'_', ' ') AS ranking_type,
        LOWER(TRIM(post_status)) AS post_status,
        LOWER(TRIM(publication_status)) AS publication_status,
        LOWER(TRIM(listing_type)) AS listing_type,
        commentary,
        CAST(modified_ts AS TIMESTAMP_NTZ) AS modified_ts
    FROM {{ ref('raw_rankings') }}
),

deduped AS (
    SELECT 
        *
    FROM source
     -- Drop invalid firm_ref rows after canonicalising malformed values to NULL.
    WHERE firm_ref IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
                                PARTITION BY ranking_id
                                ORDER BY modified_ts DESC
                                ) = 1
)

SELECT * 
FROM deduped