CREATE TABLE post
(
    post_id    SERIAL PRIMARY KEY,
    user_id    INT NOT NULL,
    content    TEXT,
    tags       TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_public  BOOLEAN   DEFAULT TRUE
);

CREATE TABLE post_like
(
    user_id  INT NOT NULL,
    post_id  INT NOT NULL,
    liked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, post_id)
);

-- TẠO 1000 BẢN GHI CHO BẢNG POST
-- Sử dụng hàm sinh ngẫu nhiên để tạo dữ liệu đa dạng
INSERT INTO post (user_id, content, tags, created_at, is_public)
SELECT
    -- Random user_id từ 1 đến 50
    (random() * 50 + 1)::INT,

    -- Trộn nội dung ngẫu nhiên (cố tình nhồi từ khóa "du lịch" để test)
    CASE
        WHEN random() < 0.2 THEN 'Hôm nay đi du lịch thật vui'
        WHEN random() < 0.4 THEN 'Một chuyến Du Lịch đáng nhớ cùng gia đình'
        WHEN random() < 0.6 THEN 'Vừa đi phượt về mệt quá'
        ELSE 'Đây là nội dung bài viết bình thường số ' || i
        END,

    -- Trộn mảng tags ngẫu nhiên (cố tình nhồi tag 'travel' để test GIN)
    CASE
        WHEN random() < 0.3 THEN ARRAY ['travel', 'vacation', 'chill']
        WHEN random() < 0.6 THEN ARRAY ['food', 'travel']
        ELSE ARRAY ['tech', 'coding', 'postgres']
        END,

    -- Random thời gian đăng bài trong vòng 30 ngày đổ lại (để test Partial Index 7 ngày)
    CURRENT_TIMESTAMP - (random() * 30 || ' days')::INTERVAL,

    -- Random trạng thái public (80% là True, 20% là False)
    random() > 0.2
FROM generate_series(1, 1000) AS i;

INSERT INTO post_like (user_id, post_id, liked_at)
SELECT (random() * 50 + 1)::INT,  -- random user (1-50)
       (random() * 999 + 1)::INT, -- random post (1-1000)
       CURRENT_TIMESTAMP - (random() * 30 || ' days')::INTERVAL
FROM generate_series(1, 3000)
ON CONFLICT DO NOTHING;
-- Bỏ qua nếu bị trùng lặp Primary Key (1 user like 1 bài nhiều lần)


--1. Tối ưu hóa truy vấn tìm kiếm bài đăng công khai theo từ khóa:
EXPLAIN ANALYSE
SELECT *
FROM post
WHERE is_public = TRUE
  AND content ILIKE '%du lịch%';


--a: Tạo Expression Index sử dụng LOWER(content) để tăng tốc tìm kiếm
-- Kích hoạt tiện ích băm từ (chạy 1 lần)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_content_post ON post USING GIN (LOWER(content) gin_trgm_ops);
DROP INDEX idx_content_post;
--b:So sánh hiệu suất trước và sau khi tạo chỉ mục
/* trước khi tạo chỉ mục: câu lệnh thực thi hết 1.224ms
   sau khi tạo chỉ mục: câu thực thi hết 1.034ms
 */

--2Tối ưu hóa truy vấn lọc bài đăng theo thẻ (tags):
EXPLAIN ANALYZE
SELECT *
FROM post
WHERE tags @> ARRAY ['travel'];
--a. Tạo GIN Index cho cột tags
CREATE INDEX idx_tags_post ON post USING GIN (tags);
DROP INDEX idx_tags_post;
/*b. Phân tích hiệu suất bằng EXPLAIN ANALYZE
  tốc độ trước khi tạo chỉ mục:0.494ms
  tốc độ sau khi tạo chỉ mục:0.396ms
 */

--3 Tối ưu hóa truy vấn tìm bài đăng mới trong 7 ngày gần nhất
CREATE INDEX idx_post_recent_public
    ON post (created_at DESC) WHERE is_public = TRUE;

DROP INDEX idx_post_recent_public;

EXPLAIN ANALYZE SELECT * FROM post WHERE is_public= TRUE AND created_at >= now() - INTERVAL '7 days';

--4 Phân tích chỉ mục tổng hợp(Composite Index):

--a Tạo chỉ mục (user_id, created_at DESC)

CREATE INDEX idx_post_user_recent ON post (user_id, created_at DESC);

EXPLAIN ANALYZE
SELECT * FROM post
WHERE user_id = 5
ORDER BY created_at DESC
LIMIT 10;

/* trước khi tạo chỉ mục: 0.164ms
   sau khi tạo chỉ mục:0.085 ms
 */

