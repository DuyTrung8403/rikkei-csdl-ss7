CREATE TABLE customers
(
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(100),
    email       VARCHAR(100) UNIQUE,
    city        VARCHAR(50)
);

CREATE TABLE products
(
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category     TEXT[],
    price        NUMERIC(10, 2)
);

CREATE TABLE orders
(
    order_id    SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers (customer_id),
    product_id  INT REFERENCES products (product_id),
    order_date  DATE,
    quantity    INT
);


--1.Thêm dữ liệu mẫu (ít nhất 5 khách hàng, 5 sản phẩm, 10 đơn hàng)
INSERT INTO customers (full_name, email, city)
VALUES ('Nguyễn Văn An', 'an.nguyen@gmail.com', 'Hà Nội'),
       ('Trần Bình', 'binh.tran@yahoo.com', 'Hồ Chí Minh'),
       ('Lê Thị Cẩm', 'cam.le@gmail.com', 'Đà Nẵng'),
       ('Phạm Duy', 'duy.pham@hotmail.com', 'Hà Nội'),
       ('Hoàng Yến', 'yen.hoang@gmail.com', 'Hải Phòng'),
       ('Vũ Phong', 'phong.vu@côngty.vn', 'Hồ Chí Minh');

INSERT INTO products (product_name, category, price)
VALUES ('Laptop Dell XPS', ARRAY ['Electronics', 'Computers', 'Work'], 1200.00),
       ('Tai nghe Sony WH', ARRAY ['Electronics', 'Audio'], 350.00),
       ('Bàn phím cơ Keychron', ARRAY ['Electronics', 'Accessories'], 550.00),
       ('Màn hình LG 27inch', ARRAY ['Electronics', 'Monitors'], 800.00),
       ('Bàn làm việc gỗ', ARRAY ['Furniture', 'Office'], 250.00),
       ('Áo thun Cotton', ARRAY ['Fashion', 'Men'], 25.00),
       ('Điện thoại iPhone 13', ARRAY ['Electronics', 'Smartphones'], 750.00);

INSERT INTO orders (customer_id, product_id, order_date, quantity)
VALUES (1, 1, '2023-10-05', 1),
       (2, 3, '2023-12-15', 2),
       (1, 4, '2023-11-20', 1),
       (3, 2, '2023-09-10', 3),
       (4, 5, '2023-12-01', 1),
       (5, 7, '2023-10-25', 2),
       (2, 1, '2023-11-05', 1),
       (6, 6, '2023-08-20', 5),
       (1, 7, '2023-12-20', 1),
       (3, 3, '2023-10-18', 1),
       (4, 2, '2023-11-11', 2),
       (5, 4, '2023-09-30', 1);

--2 Tối ưu truy vấn tìm kiếm khách hàng và sản phẩm:
-- Tạo chỉ mục B-tree trên cột email để tối ưu tìm khách hàng theo email
CREATE INDEX idx_customer_email ON customers (email);
-- Tạo chỉ mục Hash trên cột city để lọc theo thành phố
CREATE INDEX idx_customer_city ON customers USING hash (city);
-- Tạo chỉ mục GIN trên cột category của products để hỗ trợ tìm theo danh mục (mảng)
CREATE INDEX idx_customer_category ON products USING gin (category);
-- Tạo chỉ mục GiST trên cột price để hỗ trợ tìm sản phẩm trong khoảng giá
-- Kích hoạt extension (Chỉ cần chạy 1 lần)
CREATE EXTENSION btree_gist;
CREATE INDEX idx_customer_price ON products USING gist (price);

--3 Thực hiện một số truy vấn trước và sau khi có Index:
--  a.Tìm khách hàng có email cụ thể
EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE email = 'binh.tran@yahoo.com';
-- Tốc độ thực thi trước khi có index là 0.040ms và sau khi có index là 0.017ms
-- b.Tìm sản phẩm có category chứa 'Electronics'
EXPLAIN ANALYZE
SELECT *
FROM products
WHERE category @> ARRAY ['Electronics'];
-- Tốc độ thực thi trước khi có index là 0.126ms và sau khi có index là 0.035ms
-- c.Tìm sản phẩm trong khoảng giá từ 500 đến 1000
EXPLAIN ANALYZE
SELECT *
FROM products
WHERE price BETWEEN 500 AND 1000;
-- Tốc độ thực thi trước khi có index là 0.038ms và sau khi có index là 0.024ms
-- d.Dùng EXPLAIN ANALYZE để so sánh hiệu suất truy vấn trước và sau khi tạo Index

--4 Thực hiện Clustered Index trên bảng orders theo cột order_date
CREATE INDEX idx_order_oder_date ON orders (order_date);
CLUSTER orders USING idx_order_oder_date;


--5 Sử dụng View để:
-- Xem top 3 khách hàng mua nhiều nhất
CREATE VIEW v_customer_buy_max AS
SELECT c.full_name,
       COUNT(o.order_id)
FROM orders o
         JOIN customers c on c.customer_id = o.customer_id
GROUP BY c.full_name
ORDER BY COUNT(o.order_id) DESC
LIMIT 3;
SELECT *
FROM v_customer_buy_max;
-- Xem tổng doanh thu theo từng sản phẩm
CREATE VIEW v_total_revenue_by_product AS
SELECT p.product_name,
       SUM(p.price * o.quantity) AS total_revenue
FROM orders o
         JOIN products p on p.product_id = o.product_id
GROUP BY p.product_id
ORDER BY total_revenue DESC;

SELECT *
FROM v_total_revenue_by_product;

-- 6. Thực hành cập nhật dữ liệu qua View có thể ghi:
-- Tạo View cho phép chỉnh sửa city của khách hàng:
CREATE OR REPLACE VIEW v_customer_city AS
SELECT customer_id, full_name, city
FROM customers
        WITH CHECK OPTION;
--Thử cập nhật thành phố của 1 khách hàng qua View và kiểm tra lại bảng gốc
UPDATE v_customer_city
SET city = 'Cần Thơ'
WHERE customer_id = 1;