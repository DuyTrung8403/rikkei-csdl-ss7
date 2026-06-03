CREATE TABLE book
(
    book_id     SERIAL PRIMARY KEY,
    title       VARCHAR(255),
    author      VARCHAR(100),
    genre       VARCHAR(50),
    price       DECIMAL(10, 2),
    description TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Thêm dữ liệu mẫu vào bảng book
INSERT INTO book (title, author, genre, price, description)
SELECT
    'Sách Thử Nghiệm Số ' || i AS title,
    (ARRAY['Nguyễn Nhật Ánh', 'Dale Carnegie', 'Paulo Coelho', 'Yuval Noah Harari', 'Trần Đặng Đăng Khoa'])[floor(random() * 5) + 1] AS author,
    (ARRAY['Truyện dài', 'Kỹ năng sống', 'Tiểu thuyết', 'Khoa học lịch sử', 'Du ký'])[floor(random() * 5) + 1] AS genre,
    floor(random() * (200000 - 50000 + 1) + 50000)::DECIMAL(10,2) AS price,
    'Mô tả ngẫu nhiên cho cuốn sách số ' || i || ' phục vụ mục đích kiểm tra hiệu năng hệ thống.' AS description
FROM generate_series(1, 500000) AS i;

-- 1. Tạo các chỉ mục phù hợp để tối ưu truy vấn sau:
CREATE INDEX idx_book_author ON book(author);
CREATE INDEX idx_genre_genre ON book(genre);
--2.
DROP INDEX idx_book_author;
EXPLAIN ANALYZE SELECT * FROM book where author ILIKE '%Rowling%';
EXPLAIN ANALYZE SELECT * FROM book where genre='Fantasy';
--3.
CREATE INDEX idx_title_description ON book USING GIN (to_tsvector('english',description));
EXPLAIN ANALYZE SELECT * FROM book where genre='Fantasy';
--4.
CLUSTER book USING idx_book_author;
SELECT * FROM book ;