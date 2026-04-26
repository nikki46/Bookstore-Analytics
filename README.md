# Bookstore Analytics — SQL Project

A small data-analytics-focused SQL project simulating a bookstore. Select queries covering popularity, revenue, ratings, inventory, and growth.

## Files

| File | Purpose |
|---|---|
| [01_schema.sql](Create_Bookstore.sql) | DDL: 8 tables (books, authors, publishers, genres, customers, orders, order_items, reviews) + indexes |
| [02_seed.sql](Insert_Bookstore.sql) | ~20 books, 15 customers, 50 orders, 90 line items, 44 reviews |
| [03_analytics.sql](Query_Bookstore.sql) | 15 analytics queries — book popularity, genre/author leaderboards, MoM growth, margin, etc. |

## Query catalog (in [03_analytics.sql](03_analytics.sql))

1. Top 10 best-sellers by units
2. Top books by revenue + gross profit
3. **Composite popularity score** (70% sales + 30% rating, normalized)
4. Genre performance (units, revenue, avg rating)
5. Author leaderboard
6. Monthly revenue trend
7. Channel comparison (online vs in-store, with AOV)
8. Top customers by lifetime spend
9. Best-rated books (≥3 reviews) — ratings deep dive
10. Catalog books that have never sold
11. Inventory risk: hot sellers low on stock
12. Repeat buyers (same book, multiple orders)
13. Top 3 per genre using `RANK() OVER (PARTITION BY …)`
14. Month-over-month growth using `LAG()`
15. Gross margin % by genre
