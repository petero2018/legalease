WITH source AS (
    SELECT * FROM {{ ref('int__rankings') }}
),

with_flags AS (
    SELECT
        *,

        -- Top Tier Firms widget: only tiered firms qualify
        CASE WHEN ranking_tier BETWEEN 1 AND 5 THEN TRUE ELSE FALSE END AS is_top_tier,

        -- Top Tier Firms widget: only ranked entries are displayed
        CASE WHEN ranking_decision_status = 'RANKED' THEN TRUE ELSE FALSE END AS is_ranked,

        -- Premium/vip listings get elevated visibility in the widget
        CASE WHEN COALESCE(listing_type, '') IN ('PREMIUM', 'VIP') THEN TRUE ELSE FALSE END AS is_premium_listing,

        -- Tier grouping for widget filter controls
        CASE
            WHEN ranking_tier BETWEEN 1 AND 2 THEN 'TOP'
            WHEN ranking_tier BETWEEN 3 AND 4 THEN 'MID'
            WHEN ranking_tier = 5 THEN 'LOWER'
            ELSE 'UNKNOWN'
        END AS tier_group
    FROM source
)

SELECT * FROM with_flags