-- Bookstore Analytics: Schema
-- Target: SQLite / PostgreSQL compatible
-- Run order: 01_schema.sql -> 02_seed.sql -> 03_analytics.sql

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS publishers;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS customers;

CREATE TABLE authors (
    author_id     INTEGER PRIMARY KEY,
    full_name     TEXT NOT NULL,
    country       TEXT,
    birth_year    INTEGER
);

CREATE TABLE publishers (
    publisher_id  INTEGER PRIMARY KEY,
    name          TEXT NOT NULL,
    country       TEXT
);

CREATE TABLE genres (
    genre_id      INTEGER PRIMARY KEY,
    name          TEXT NOT NULL UNIQUE
);

CREATE TABLE books (
    book_id       INTEGER PRIMARY KEY,
    title         TEXT NOT NULL,
    author_id     INTEGER NOT NULL REFERENCES authors(author_id),
    publisher_id  INTEGER NOT NULL REFERENCES publishers(publisher_id),
    genre_id      INTEGER NOT NULL REFERENCES genres(genre_id),
    publish_year  INTEGER,
    price         NUMERIC(6,2) NOT NULL,
    cost          NUMERIC(6,2) NOT NULL,
    stock_qty     INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    full_name     TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    city          TEXT,
    country       TEXT,
    signup_date   DATE NOT NULL
);

CREATE TABLE orders (
    order_id      INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date    DATE NOT NULL,
    channel       TEXT NOT NULL CHECK (channel IN ('online','in-store'))
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders(order_id),
    book_id       INTEGER NOT NULL REFERENCES books(book_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(6,2) NOT NULL
);

CREATE TABLE reviews (
    review_id     INTEGER PRIMARY KEY,
    book_id       INTEGER NOT NULL REFERENCES books(book_id),
    customer_id   INTEGER NOT NULL REFERENCES customers(customer_id),
    rating        INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_date   DATE NOT NULL
);

CREATE INDEX idx_books_genre     ON books(genre_id);
CREATE INDEX idx_books_author    ON books(author_id);
CREATE INDEX idx_orders_date     ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_items_book      ON order_items(book_id);
CREATE INDEX idx_items_order     ON order_items(order_id);
CREATE INDEX idx_reviews_book    ON reviews(book_id);
