{# Singular test: oferta nie może być "stworzona" po dacie swojej pierwszej recenzji - łapie niespójne created_at #}
SELECT * FROM {{ ref('dim_listings_cleansed') }} l
INNER JOIN {{ ref('fct_reviews') }} r
USING (listing_id)
WHERE l.created_at >= r.review_date