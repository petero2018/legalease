/*
  stg__rankings
  ------------
  Grain: one row per ranking_id (deduplicated by latest modified_ts)

  Handles dual-schema ingestion:
    - Pre-migration rows:   ranking_tier IS NOT NULL (integer)
    - Post-migration rows:  tier_rank IS NOT NULL (varchar, including legacy 'TIER_N' values)

  Invalid firm_ref: NULL, empty string, or whitespace-only values.
  These rows are filtered out as they cannot be linked to a known firm and
  would cause silent failures in downstream joins/dashboards.
*/

WITH source AS (
    SELECT 
        ranking_id,
        TRY_CAST(edition_year AS INTEGER) AS edition_year,
        edition_id,
        CASE
            WHEN firm_ref IS NULL THEN NULL
            WHEN regexp_like(trim(firm_ref), '^F[0-9]{4}$') THEN trim(firm_ref)
            ELSE NULL
        end as firm_ref,
        practice_area_id,
        COALESCE(
            ranking_tier,
            TRY_CAST(REGEXP_REPLACE(tier_rank, 'TIER_', '') AS INTEGER)
        ) AS ranking_tier,
        UPPER(TRIM(ranking_type)) AS ranking_type,
        UPPER(TRIM(post_status)) AS post_status,
        UPPER(TRIM(publication_status)) AS publication_status,
        UPPER(TRIM(listing_type)) AS listing_type,
        commentary,
        modified_ts AS modified_ts
    FROM {{ ref('raw_rankings') }}
),

deduped AS (
    SELECT 
        *
    FROM source
    WHERE firm_ref IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
                                PARTITION BY ranking_id
                                ORDER BY modified_ts DESC
                                ) = 1
),

casted AS (
    SELECT
        ranking_id,
        edition_year,
        edition_id,
        firm_ref,
        practice_area_id,
        ranking_tier,
        ranking_type,
        post_status,
        publication_status,
        listing_type,
        commentary,
        modified_ts
    FROM deduped
)

SELECT * FROM casted