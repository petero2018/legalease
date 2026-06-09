WITH rankings AS (
    SELECT * FROM {{ ref('int__rankings') }}
),

with_flags AS (
    SELECT
        -- As a palceholder should a composit key needed
        {{ dbt_utils.generate_surrogate_key(['ranking_id']) }} AS ranking_pk, 
        *,

        -- Top Tier Firms widget: only tiered firms qualify
        CASE WHEN ranking_tier BETWEEN 1 AND 5 THEN TRUE ELSE FALSE END AS is_top_tier,

        -- Top Tier Firms widget: only ranked entries are displayed
        CASE WHEN ranking_decision_status = 'ranked' THEN TRUE ELSE FALSE END AS is_ranked,

        -- Premium/vip listings get elevated visibility in the widget
        CASE WHEN COALESCE(listing_type, '') IN ('premium', 'vip') THEN TRUE ELSE FALSE END AS is_premium_listing,

        -- Tier grouping for widget filter controls
        CASE
            WHEN ranking_tier BETWEEN 1 AND 2 THEN 'top'
            WHEN ranking_tier BETWEEN 3 AND 4 THEN 'mid'
            WHEN ranking_tier = 5 THEN 'lower'
            ELSE 'unknown'
        END AS tier_group
    FROM rankings
)

SELECT * FROM with_flags