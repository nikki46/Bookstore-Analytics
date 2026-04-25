-- Bookstore Analytics: SELECT queries for data analytics
-- Each query stands alone. Run individually to inspect results.

-- ============================================================================
-- 1. BOOK POPULARITY: top 10 best-sellers by units sold
-- ============================================================================
SELECT
    b.book_id,
    b.title,
    a.full_name                       AS author,
    g.name                            AS genre,
    SUM(oi.quantity)                  AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM books b
JOIN order_items oi ON oi.book_id = b.book_id
JOIN authors a      ON a.author_id = b.author_id
JOIN genres g       ON g.genre_id  = b.genre_id
GROUP BY b.book_id, b.title, a.full_name, g.name
ORDER BY units_sold DESC, revenue DESC
LIMIT 10;

-- ============================================================================
-- 2. BOOK POPULARITY: top books by revenue (different from units)
-- ============================================================================
SELECT
    b.title,
    SUM(oi.quantity)                              AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)    AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - b.cost)), 2) AS gross_profit
FROM books b
JOIN order_items oi ON oi.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY revenue DESC
LIMIT 10;

-- ============================================================================
-- 3. POPULARITY SCORE: combine sales volume + average rating
-- (weighted: 70% normalized units, 30% normalized rating)
-- ============================================================================
WITH book_sales AS (
    SELECT book_id, SUM(quantity) AS units
    FROM order_items
    GROUP BY book_id
),
book_ratings AS (
    SELECT book_id, AVG(rating) AS avg_rating, COUNT(*) AS review_count
    FROM reviews
    GROUP BY book_id
),
maxes AS (
    SELECT MAX(units) AS max_units FROM book_sales
)
SELECT
    b.title,
    COALESCE(bs.units, 0)                                   AS units_sold,
    ROUND(COALESCE(br.avg_rating, 0), 2)                    AS avg_rating,
    COALESCE(br.review_count, 0)                            AS review_count,
    ROUND(
        0.7 * (COALESCE(bs.units, 0) * 1.0 / m.max_units) +
        0.3 * (COALESCE(br.avg_rating, 0) / 5.0),
        3
    )                                                        AS popularity_score
FROM books b
LEFT JOIN book_sales   bs ON bs.book_id = b.book_id
LEFT JOIN book_ratings br ON br.book_id = b.book_id
CROSS JOIN maxes m
ORDER BY popularity_score DESC;

-- ============================================================================
-- 4. GENRE PERFORMANCE: sales and avg rating per genre
-- ============================================================================
SELECT
    g.name                                          AS genre,
    COUNT(DISTINCT b.book_id)                       AS titles_in_catalog,
    COALESCE(SUM(oi.quantity), 0)                   AS units_sold,
    ROUND(COALESCE(SUM(oi.quantity * oi.unit_price), 0), 2) AS revenue,
    ROUND(AVG(r.rating), 2)                         AS avg_rating
FROM genres g
LEFT JOIN books       b  ON b.genre_id  = g.genre_id
LEFT JOIN order_items oi ON oi.book_id  = b.book_id
LEFT JOIN reviews     r  ON r.book_id   = b.book_id
GROUP BY g.genre_id, g.name
ORDER BY revenue DESC;

-- ============================================================================
-- 5. AUTHOR LEADERBOARD: top authors by revenue
-- ============================================================================
SELECT
    a.full_name                                          AS author,
    a.country,
    COUNT(DISTINCT b.book_id)                            AS titles_published,
    SUM(oi.quantity)                                     AS total_units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)           AS total_revenue
FROM authors a
JOIN books       b  ON b.author_id = a.author_id
JOIN order_items oi ON oi.book_id  = b.book_id
GROUP BY a.author_id, a.full_name, a.country
ORDER BY total_revenue DESC;

-- ============================================================================
-- 6. MONTHLY REVENUE TREND
-- ============================================================================
SELECT
    strftime('%Y-%m', o.order_date)                       AS month,
    COUNT(DISTINCT o.order_id)                            AS orders,
    SUM(oi.quantity)                                      AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY strftime('%Y-%m', o.order_date)
ORDER BY month;

-- ============================================================================
-- 7. CHANNEL COMPARISON: online vs in-store
-- ============================================================================
SELECT
    o.channel,
    COUNT(DISTINCT o.order_id)                            AS order_count,
    SUM(oi.quantity)                                      AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)            AS revenue,
    ROUND(SUM(oi.quantity * oi.unit_price) * 1.0
          / COUNT(DISTINCT o.order_id), 2)                AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.channel;

-- ============================================================================
-- 8. CUSTOMER VALUE: top spenders
-- ============================================================================
SELECT
    c.customer_id,
    c.full_name,
    c.country,
    COUNT(DISTINCT o.order_id)                          AS orders,
    SUM(oi.quantity)                                    AS items_bought,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)          AS lifetime_spend
FROM customers c
JOIN orders      o  ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.full_name, c.country
ORDER BY lifetime_spend DESC
LIMIT 10;

-- ============================================================================
-- 9. RATINGS DEEP DIVE: best-rated books with at least 3 reviews
-- ============================================================================
SELECT
    b.title,
    a.full_name                AS author,
    COUNT(r.review_id)         AS review_count,
    ROUND(AVG(r.rating), 2)    AS avg_rating,
    MIN(r.rating)              AS min_rating,
    MAX(r.rating)              AS max_rating
FROM books b
JOIN reviews r ON r.book_id = b.book_id
JOIN authors a ON a.author_id = b.author_id
GROUP BY b.book_id, b.title, a.full_name
HAVING COUNT(r.review_id) >= 3
ORDER BY avg_rating DESC, review_count DESC;

-- ============================================================================
-- 10. UNDERPERFORMERS: books in catalog but never sold
-- ============================================================================
SELECT
    b.book_id,
    b.title,
    a.full_name      AS author,
    g.name           AS genre,
    b.publish_year,
    b.stock_qty
FROM books b
JOIN authors a ON a.author_id = b.author_id
JOIN genres  g ON g.genre_id  = b.genre_id
LEFT JOIN order_items oi ON oi.book_id = b.book_id
WHERE oi.order_item_id IS NULL
ORDER BY b.publish_year;

-- ============================================================================
-- 11. INVENTORY RISK: low stock on hot sellers (sold > 5 units, stock < 20)
-- ============================================================================
SELECT
    b.title,
    b.stock_qty,
    SUM(oi.quantity) AS units_sold_to_date
FROM books b
JOIN order_items oi ON oi.book_id = b.book_id
GROUP BY b.book_id, b.title, b.stock_qty
HAVING SUM(oi.quantity) > 5
   AND b.stock_qty       < 20
ORDER BY b.stock_qty ASC;

-- ============================================================================
-- 12. REPEAT BUYERS: customers who bought the same book more than once
--     (across different orders)
-- ============================================================================
SELECT
    c.full_name,
    b.title,
    COUNT(DISTINCT o.order_id) AS times_purchased
FROM customers c
JOIN orders      o  ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN books       b  ON b.book_id     = oi.book_id
GROUP BY c.customer_id, c.full_name, b.book_id, b.title
HAVING COUNT(DISTINCT o.order_id) > 1
ORDER BY times_purchased DESC;

-- ============================================================================
-- 13. RANKING: top 3 best-sellers per genre (window function)
-- ============================================================================
WITH ranked AS (
    SELECT
        g.name                            AS genre,
        b.title,
        SUM(oi.quantity)                  AS units_sold,
        RANK() OVER (
            PARTITION BY g.genre_id
            ORDER BY SUM(oi.quantity) DESC
        )                                 AS rank_in_genre
    FROM genres g
    JOIN books       b  ON b.genre_id  = g.genre_id
    JOIN order_items oi ON oi.book_id  = b.book_id
    GROUP BY g.genre_id, g.name, b.book_id, b.title
)
SELECT genre, rank_in_genre, title, units_sold
FROM ranked
WHERE rank_in_genre <= 3
ORDER BY genre, rank_in_genre;

-- ============================================================================
-- 14. MONTH-OVER-MONTH GROWTH (window function)
-- ============================================================================
WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_date)               AS month,
        SUM(oi.quantity * oi.unit_price)              AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT
    month,
    ROUND(revenue, 2)                                  AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2)       AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0),
        2
    )                                                  AS pct_growth
FROM monthly
ORDER BY month;

-- ============================================================================
-- 15. PROFIT MARGIN by genre
-- ============================================================================
SELECT
    g.name                                                  AS genre,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)              AS revenue,
    ROUND(SUM(oi.quantity * b.cost), 2)                     AS cogs,
    ROUND(SUM(oi.quantity * (oi.unit_price - b.cost)), 2)   AS gross_profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price - b.cost)) * 100.0
        / NULLIF(SUM(oi.quantity * oi.unit_price), 0),
        2
    )                                                       AS gross_margin_pct
FROM genres g
JOIN books       b  ON b.genre_id = g.genre_id
JOIN order_items oi ON oi.book_id = b.book_id
GROUP BY g.genre_id, g.name
ORDER BY gross_margin_pct DESC;
