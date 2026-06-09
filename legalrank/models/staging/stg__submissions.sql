WITH source AS (
    SELECT 
        submission_id, 
        CASE
            WHEN firm_ref IS NULL THEN NULL
            WHEN REGEXP_LIKE(TRIM(firm_ref), '^F[0-9]{4}$') THEN TRIM(firm_ref)
            ELSE NULL
        END AS firm_ref,
        practice_area_id, 
        TRY_CAST(edition_year AS INTEGER) AS edition_year,
        CASE
            WHEN submission_type IS NULL THEN NULL
            WHEN LOWER(REGEXP_REPLACE(TRIM(submission_type), '[^A-Za-z0-9]+', '_')) IN ('LAW_FIRM', 'FIRM')
            THEN 'FIRM'
            WHEN LOWER(REGEXP_REPLACE(TRIM(submission_type), '[^A-Za-z0-9]+', '_')) = 'INDIVIDUAL'
            THEN 'INDIVIDUAL'
            ELSE LOWER(REGEXP_REPLACE(TRIM(submission_type), '[^A-Za-z0-9]+', '_'))
        END AS submission_type,
        CASE
            WHEN submitted_by_email IS NULL THEN NULL
            WHEN REGEXP_LIKE(
                LOWER(TRIM(submitted_by_email)),
                '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            )
                THEN LOWER(TRIM(submitted_by_email))
            ELSE NULL
        END AS submitted_by_email,

        CASE
            WHEN submitted_by_email IS NULL THEN FALSE
            WHEN REGEXP_LIKE(
                LOWER(TRIM(submitted_by_email)),
                '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            )
                THEN FALSE
            ELSE TRUE
        END AS is_invalid_submitted_email, 
        submitted_at, 
        TRY_CAST(num_referees AS INTEGER) AS num_referees, 
        LOWER(TRIM(status)) AS status,
        created_ts
    FROM {{ ref('raw_submissions') }}
),

deduped AS (
    SELECT 
        *
    FROM source
    WHERE firm_ref IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
                                PARTITION BY submission_id
                                ORDER BY created_ts DESC
                                ) = 1
)

select *
from deduped