CREATE TABLE customer
(
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(100),
    region      VARCHAR(50)
);

CREATE TABLE orders
(
    order_id     SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES customer (customer_id),
    total_amount DECIMAL(10, 2),
    order_date   DATE,
    status       VARCHAR(20)
);

CREATE TABLE product
(
    product_id SERIAL PRIMARY KEY,
    name       VARCHAR(100),
    price      DECIMAL(10, 2),
    category   VARCHAR(50)
);

CREATE TABLE order_detail
(
    order_id   INT REFERENCES orders (order_id),
    product_id INT REFERENCES product (product_id),
    quantity   INT
);

-- Tạo 1000 Khách hàng ngẫu nhiên ở 3 miền
INSERT INTO customer (full_name, region)
SELECT 'Khách hàng ' || i,
       (ARRAY ['Miền Bắc', 'Miền Trung', 'Miền Nam', 'Tây Nguyên'])[floor(random() * 4 + 1)]
FROM generate_series(1, 1000) AS i;

-- Tạo 100 Sản phẩm ngẫu nhiên thuộc 5 danh mục
INSERT INTO product (name, price, category)
SELECT 'Sản phẩm ' || i,
       (random() * 9900000 + 100000)::DECIMAL(10, 2), -- Giá ngẫu nhiên từ 100k đến 10 triệu
       (ARRAY ['Điện tử', 'Thời trang', 'Gia dụng', 'Sách', 'Mỹ phẩm'])[floor(random() * 5 + 1)]
FROM generate_series(1, 100) AS i;

-- Tạo 1000 Đơn hàng ngẫu nhiên trong vòng 1 năm qua
INSERT INTO orders (customer_id, total_amount, order_date, status)
SELECT (random() * 999 + 1)::INT,                      -- Gắn ngẫu nhiên cho 1000 khách hàng
       (random() * 49000000 + 100000)::DECIMAL(10, 2), -- Tổng tiền ngẫu nhiên
       CURRENT_DATE - (random() * 365)::INT,           -- Ngày mua lùi về tối đa 365 ngày trước
       (ARRAY ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'])[floor(random() * 5 + 1)]
FROM generate_series(1, 1000);

-- Tạo Chi tiết đơn hàng (Mỗi đơn hàng mua ngẫu nhiên từ 1 đến 3 sản phẩm)
INSERT INTO order_detail (order_id, product_id, quantity)
SELECT o.order_id,
       (random() * 99 + 1)::INT, -- Chọn bừa 1 trong 100 sản phẩm
       (random() * 4 + 1)::INT   -- Số lượng mua từ 1 đến 5 cái
FROM orders o
         CROSS JOIN LATERAL generate_series(1, (random() * 2 + 1)::INT);

--1:Tạo View tổng hợp doanh thu theo khu vực: Viết truy vấn xem top 3 khu vực có doanh thu cao nhất
CREATE VIEW v_revenue_by_region AS
SELECT c.region,
       SUM(o.total_amount) AS total_revenue
FROM customer c
         JOIN orders o on c.customer_id = o.customer_id
GROUP BY c.region;

DROP VIEW v_revenue_by_region;

SELECT *
FROM v_revenue_by_region
ORDER BY total_revenue DESC
LIMIT 3;


-- 2. Tạo View phức hợp (Nested View):Từ v_revenue_by_region, tạo View mới v_revenue_above_avg chỉ hiển thị khu vực có doanh thu > trung bình toàn quốc
CREATE VIEW v_revenue_above_avg AS
SELECT total_revenue,
       region
FROM v_revenue_by_region WHERE total_revenue > (
    SELECT
        AVG(total_revenue)
    FROM v_revenue_by_region
    );

SELECT * FROM v_revenue_above_avg;

