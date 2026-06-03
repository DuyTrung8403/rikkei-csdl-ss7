CREATE TABLE customer
(
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(100),
    email       VARCHAR(100),
    phone       VARCHAR(15)
);

CREATE TABLE orders
(
    order_id     SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES customer (customer_id),
    total_amount DECIMAL(10, 2),
    order_date   DATE
);

INSERT INTO customer (full_name, email, phone)
VALUES ('Nguyễn Văn An', 'an.nguyen@gmail.com', '0912345678'),
       ('Trần Thị Bình', 'binh.tran@gmail.com', '0923456789'),
       ('Lê Hoàng Cường', 'cuong.le@gmail.com', '0934567890');

INSERT INTO orders (customer_id, total_amount, order_date)
VALUES (1, 1500000.00, '2026-01-15'),
       (2, 450000.00, '2026-01-20'),
       (1, 2300000.00, '2026-02-10'),
       (3, 850000.00, '2026-02-25'),
       (2, 3200000.00, '2026-03-05');

-- 1. Tạo một View tên v_order_summary hiển thị:
-- full_name, total_amount, order_date
-- (ẩn thông tin email và phone)
CREATE VIEW v_order_summary AS
    SELECT
        c.full_name,
        o.total_amount,
        o.order_date
    FROM customer c
    JOIN orders o on c.customer_id = o.customer_id;

-- 2. Viết truy vấn để xem tất cả dữ liệu từ View
SELECT * FROM v_order_summary;

-- 3.Tạo 1 view lấy về thông tin của tất cả các đơn hàng với điều kiện total_amount ≥ 1 triệu .
CREATE VIEW v_orders_above_1m AS
SELECT *
FROM orders o
WHERE o.total_amount >= 1000000;

SELECT * FROM v_orders_above_1m;
--  Sau đó bạn hãy cập nhật lại thông tin 1 bản ghi trong view đó nhé .
UPDATE v_orders_above_1m SET total_amount = 5000000 where order_id = 1;

-- 4.Tạo một View thứ hai v_monthly_sales thống kê tổng doanh thu mỗi tháng
CREATE VIEW v_monthly_sales AS
    SELECT SUM(o.total_amount) ,
           extract('month' FROM o.order_date)
    FROM orders o
    GROUP BY o.order_date;
SELECT * FROM v_monthly_sales;

-- 5.Thử DROP View và ghi chú sự khác biệt giữa DROP VIEW và DROP MATERIALIZED VIEW trong PostgreSQL
DROP VIEW v_monthly_sales; -- duoc tao o cau 1

CREATE MATERIALIZED VIEW v_year_sales AS
SELECT SUM(o.total_amount) ,
       extract('year' FROM o.order_date) "Năm"
FROM orders o
GROUP BY o.order_date;

SELECT * FROM v_year_sales;

DROP MATERIALIZED VIEW v_year_sales;

SELECT
    'v_monthly_sales (View thường)' AS ten_view,
    pg_size_pretty(pg_relation_size('v_monthly_sales')) AS dung_luong_o_cung
UNION ALL
SELECT
    'v_year_sales (Materialized View)',
    pg_size_pretty(pg_relation_size('v_year_sales'));

/*note
Tốc độ: DROP VIEW(5ms) có tốc độ hoành thành nhanh hơn so với DROP MATERIALIZED VIEW (8ms)
Dung lượng: Do khi tạo VIEW thì nó chỉ là 1 bảng ảo mà MATERIALIZED VIEW lại là tạo 1 bảng và dữ liệu vật lý nên
khi DROP MATERIALIZED VIEW sẽ giải phóng được ổ cứng
 */
