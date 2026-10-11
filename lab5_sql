
-- PART 1: CHECK CONSTRAINTS

-- Task 1.1: Basic CHECK
CREATE TABLE employees (
    employee_id INTEGER,
    first_name  TEXT,
    last_name   TEXT,
    age         INTEGER CHECK (age BETWEEN 18 AND 65),  -- working age only
    salary      NUMERIC CHECK (salary > 0)              -- salary must be positive
);

-- Task 1.2: Named CHECK
CREATE TABLE products_catalog (
    product_id     INTEGER,
    product_name   TEXT,
    regular_price  NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

-- Task 1.3: Multi-column CHECK
CREATE TABLE bookings (
    booking_id     INTEGER,
    check_in_date  DATE,
    check_out_date DATE,
    num_guests     INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)   -- departure must be after arrival
);

-- Task 1.4: Testing CHECK constraints
-- Valid data
INSERT INTO employees VALUES (1, 'Aigerim', 'Nurlan', 25, 450000);
INSERT INTO employees VALUES (2, 'Daniyar', 'Sadykov', 40, 800000.50);

INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 850);
INSERT INTO products_catalog VALUES (2, 'Mouse', 25, 20);

INSERT INTO bookings VALUES (1, '2026-11-01', '2026-11-05', 2);
INSERT INTO bookings VALUES (2, '2026-12-20', '2026-12-27', 10);

-- Invalid data
-- INSERT INTO employees VALUES (3, 'Young', 'Person', 17, 300000);
-- RESULT: ERROR: new row for relation "employees" violates check constraint "employees_age_check"
-- WHY: age 17 is below the minimum of 18.

-- INSERT INTO employees VALUES (4, 'Old', 'Person', 70, 300000);
-- RESULT: ERROR: violates check constraint "employees_age_check" (70 > 65)

-- INSERT INTO employees VALUES (5, 'Zero', 'Pay', 30, 0);
-- RESULT: ERROR: violates check constraint "employees_salary_check"
-- WHY: salary must be strictly greater than 0.

-- INSERT INTO products_catalog VALUES (3, 'Keyboard', 50, 60);
-- RESULT: ERROR: violates check constraint "valid_discount"
-- WHY: discount_price (60) is not less than regular_price (50).

-- INSERT INTO products_catalog VALUES (4, 'Cable', -5, 3);
-- RESULT: ERROR: violates check constraint "valid_discount"
-- WHY: regular_price must be > 0.

-- INSERT INTO products_catalog VALUES (5, 'Monitor', 200, 0);
-- RESULT: ERROR: violates check constraint "valid_discount"
-- WHY: discount_price must be > 0.

-- INSERT INTO bookings VALUES (3, '2026-11-01', '2026-11-03', 11);
-- RESULT: ERROR: violates check constraint "bookings_num_guests_check"
-- WHY: more than 10 guests.

-- INSERT INTO bookings VALUES (4, '2026-11-01', '2026-11-03', 0);
-- RESULT: ERROR: violates check constraint "bookings_num_guests_check" (0 < 1)

-- INSERT INTO bookings VALUES (5, '2026-11-05', '2026-11-01', 2);
-- RESULT: ERROR: violates check constraint "bookings_check"
-- WHY: check_out_date is before check_in_date.


-- PART 2: NOT NULL CONSTRAINTS

-- Task 2.1
CREATE TABLE customers (
    customer_id       INTEGER NOT NULL,
    email             TEXT NOT NULL,
    phone             TEXT,                 -- optional
    registration_date DATE NOT NULL
);

-- Task 2.2: Combining constraints
CREATE TABLE inventory (
    item_id      INTEGER NOT NULL,
    item_name    TEXT NOT NULL,
    quantity     INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price   NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3: Testing NOT NULL
-- 1. Complete records
INSERT INTO customers VALUES (1, 'a@example.com', '+77001112233', '2026-01-10');
INSERT INTO inventory VALUES (1, 'Widget', 100, 2.50, '2026-10-01 09:00:00');
INSERT INTO inventory VALUES (2, 'Gadget', 0, 15.00, '2026-10-02 10:30:00');

-- 2. NULL in NOT NULL columns
-- INSERT INTO customers VALUES (2, NULL, '+77004445566', '2026-02-01');
-- RESULT: ERROR: null value in column "email" of relation "customers" violates not-null constraint

-- INSERT INTO customers VALUES (NULL, 'b@example.com', NULL, '2026-02-01');
-- RESULT: ERROR: null value in column "customer_id" ... violates not-null constraint

-- INSERT INTO inventory VALUES (3, 'Thing', NULL, 5.00, '2026-10-03 08:00:00');
-- RESULT: ERROR: null value in column "quantity" ... violates not-null constraint

-- INSERT INTO inventory VALUES (4, 'Item', 10, 5.00, NULL);
-- RESULT: ERROR: null value in column "last_updated" ... violates not-null constraint

-- 3. NULL in nullable column (works)
INSERT INTO customers VALUES (2, 'b@example.com', NULL, '2026-02-01');
INSERT INTO customers VALUES (3, 'c@example.com', NULL, '2026-03-15');


-- PART 3: UNIQUE CONSTRAINTS

-- Task 3.1
CREATE TABLE users (
    user_id    INTEGER,
    username   TEXT UNIQUE,
    email      TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2: Multi-column UNIQUE
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id    INTEGER,
    course_code   TEXT,
    semester      TEXT,
    UNIQUE (student_id, course_code, semester)  -- a student can take a course once per semester
);

INSERT INTO course_enrollments VALUES (1, 100, 'CS101', 'Fall2026');
INSERT INTO course_enrollments VALUES (2, 100, 'CS101', 'Spring2027');  -- OK: different semester
INSERT INTO course_enrollments VALUES (3, 101, 'CS101', 'Fall2026');    -- OK: different student
-- INSERT INTO course_enrollments VALUES (4, 100, 'CS101', 'Fall2026');
-- RESULT: ERROR: duplicate key value violates unique constraint
--         "course_enrollments_student_id_course_code_semester_key"

-- Task 3.3: Named UNIQUE constraints
-- Replace the auto-named constraints from 3.1 with named ones.
ALTER TABLE users DROP CONSTRAINT users_username_key;
ALTER TABLE users DROP CONSTRAINT users_email_key;
ALTER TABLE users ADD CONSTRAINT unique_username UNIQUE (username);
ALTER TABLE users ADD CONSTRAINT unique_email UNIQUE (email);

INSERT INTO users VALUES (1, 'zhania', 'zhania@example.com', NOW());
INSERT INTO users VALUES (2, 'alex',   'alex@example.com',   NOW());

-- INSERT INTO users VALUES (3, 'zhania', 'new@example.com', NOW());
-- RESULT: ERROR: duplicate key value violates unique constraint "unique_username"

-- INSERT INTO users VALUES (4, 'newuser', 'alex@example.com', NOW());
-- RESULT: ERROR: duplicate key value violates unique constraint "unique_email"

-- NULLs are allowed multiple times in a UNIQUE column (NULL <> NULL):
INSERT INTO users VALUES (5, NULL, NULL, NOW());
INSERT INTO users VALUES (6, NULL, NULL, NOW());


-- PART 4: PRIMARY KEY CONSTRAINTS

-- Task 4.1
CREATE TABLE departments (
    dept_id   INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location  TEXT
);

INSERT INTO departments VALUES (1, 'Engineering', 'Almaty');
INSERT INTO departments VALUES (2, 'Marketing',   'Astana');
INSERT INTO departments VALUES (3, 'Finance',     'Almaty');

-- INSERT INTO departments VALUES (1, 'Duplicate', 'Shymkent');
-- RESULT: ERROR: duplicate key value violates unique constraint "departments_pkey"

-- INSERT INTO departments VALUES (NULL, 'No ID', 'Shymkent');
-- RESULT: ERROR: null value in column "dept_id" ... violates not-null constraint

-- Task 4.2: Composite PRIMARY KEY
CREATE TABLE student_courses (
    student_id      INTEGER,
    course_id       INTEGER,
    enrollment_date DATE,
    grade           TEXT,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (1, 10, '2026-09-01', 'A');
INSERT INTO student_courses VALUES (1, 11, '2026-09-01', 'B');
INSERT INTO student_courses VALUES (2, 10, '2026-09-02', 'A-');
-- INSERT INTO student_courses VALUES (1, 10, '2026-09-05', 'C');
-- RESULT: ERROR: duplicate key value violates unique constraint "student_courses_pkey"

-- Task 4.3: Comparison Exercise
-- 1. UNIQUE vs PRIMARY KEY
--    * Both guarantee no duplicate values.
--    * PRIMARY KEY = UNIQUE + NOT NULL; it is the row's main identifier.
--    * UNIQUE columns may contain NULLs (multiple NULLs allowed in PostgreSQL).
--    * PRIMARY KEY is the default target of foreign keys (REFERENCES table).
-- 2. Single-column vs composite PRIMARY KEY
--    * Single-column: one attribute identifies a row (e.g. dept_id); preferred
--      for entity tables, simple to reference from foreign keys.
--    * Composite: identity comes from a combination (e.g. student_id + course_id
--      in a junction/many-to-many table); neither column alone is unique.
-- 3. One PRIMARY KEY but many UNIQUE constraints
--    * The primary key defines the single "official" identity of a row, so a
--      table can have only one. UNIQUE constraints just enforce additional
--      uniqueness rules (e.g. email, username, isbn), and a table may have
--      several candidate keys.

-- PART 5: FOREIGN KEY CONSTRAINTS

-- Task 5.1
CREATE TABLE employees_dept (
    emp_id    INTEGER PRIMARY KEY,
    emp_name  TEXT NOT NULL,
    dept_id   INTEGER REFERENCES departments,
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Aigerim', 1, '2024-03-01');
INSERT INTO employees_dept VALUES (2, 'Daniyar', 2, '2025-06-15');
INSERT INTO employees_dept VALUES (3, 'Madina',  NULL, '2026-01-10'); -- NULL FK is allowed
-- INSERT INTO employees_dept VALUES (4, 'Ghost', 99, '2026-02-01');
-- RESULT: ERROR: insert or update on table "employees_dept" violates foreign key
--         constraint "employees_dept_dept_id_fkey" (dept_id 99 not in departments)

-- Task 5.2: Library schema
CREATE TABLE authors (
    author_id   INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country     TEXT
);

CREATE TABLE publishers (
    publisher_id   INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city           TEXT
);

CREATE TABLE books (
    book_id          INTEGER PRIMARY KEY,
    title            TEXT NOT NULL,
    author_id        INTEGER REFERENCES authors,
    publisher_id     INTEGER REFERENCES publishers,
    publication_year INTEGER,
    isbn             TEXT UNIQUE
);

INSERT INTO authors VALUES
    (1, 'George Orwell', 'UK'),
    (2, 'Abai Kunanbayev', 'Kazakhstan'),
    (3, 'Haruki Murakami', 'Japan');

INSERT INTO publishers VALUES
    (1, 'Penguin Books', 'London'),
    (2, 'Zhazushy', 'Almaty'),
    (3, 'Knopf', 'New York');

INSERT INTO books VALUES
    (1, '1984',            1, 1, 1949, '978-0-452-28423-4'),
    (2, 'Animal Farm',     1, 1, 1945, '978-0-452-28424-1'),
    (3, 'Words of Edification', 2, 2, 1918, '978-601-00-0001-1'),
    (4, 'Kafka on the Shore',   3, 3, 2002, '978-1-4000-7927-8');

-- INSERT INTO books VALUES (5, 'Dup ISBN', 1, 1, 2000, '978-0-452-28423-4');
-- RESULT: ERROR: duplicate key value violates unique constraint "books_isbn_key"
-- INSERT INTO books VALUES (6, 'Bad Author', 99, 1, 2000, '978-0-000-00000-0');
-- RESULT: ERROR: violates foreign key constraint "books_author_id_fkey"

-- Task 5.3: ON DELETE options
CREATE TABLE categories (
    category_id   INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id   INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id  INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id    INTEGER PRIMARY KEY,
    order_id   INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity   INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics'), (2, 'Books');
INSERT INTO products_fk VALUES (1, 'Phone', 1), (2, 'Novel', 2);
INSERT INTO orders VALUES (1, '2026-10-01'), (2, '2026-10-02');
INSERT INTO order_items VALUES (1, 1, 1, 2), (2, 1, 2, 1), (3, 2, 1, 5);

-- Scenario 1: RESTRICT
-- DELETE FROM categories WHERE category_id = 1;
-- RESULT: ERROR: update or delete on table "categories" violates foreign key
--         constraint "products_fk_category_id_fkey" on table "products_fk"
-- EXPLANATION: products still reference the category, so RESTRICT blocks the delete.

-- Scenario 2: CASCADE
DELETE FROM orders WHERE order_id = 1;
-- RESULT: DELETE 1. Items 1 and 2 (order_id = 1) were deleted automatically.
SELECT * FROM order_items;   -- RESULT: only item_id 3 (order 2) remains

-- Default behavior (NO ACTION): deleting a product used by order_items fails:
-- DELETE FROM products_fk WHERE product_id = 1;
-- RESULT: ERROR: violates foreign key constraint "order_items_product_id_fkey"

-- ############################################################
-- PART 6: E-COMMERCE DATABASE
-- ############################################################

-- Remove earlier practice tables whose names clash with this schema
DROP TABLE order_items;
DROP TABLE orders;
DROP TABLE customers;

CREATE TABLE customers (
    customer_id       SERIAL PRIMARY KEY,
    name              TEXT NOT NULL,
    email             TEXT NOT NULL UNIQUE,            -- one account per email
    phone             TEXT,
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE products (
    product_id     SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    description    TEXT,
    price          NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0)
);

CREATE TABLE orders (
    order_id     SERIAL PRIMARY KEY,
    customer_id  INTEGER NOT NULL
                 REFERENCES customers ON DELETE RESTRICT,  -- keep order history
    order_date   DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders ON DELETE CASCADE,   -- lines die with order
    product_id      INTEGER NOT NULL REFERENCES products ON DELETE RESTRICT, -- protect sold products
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

-- Sample data (5+ rows per table)
INSERT INTO customers (name, email, phone, registration_date) VALUES
    ('Aigerim Nurlan',  'aigerim@example.com', '+77011111111', '2026-01-05'),
    ('Daniyar Sadykov', 'daniyar@example.com', '+77022222222', '2026-02-10'),
    ('Madina Omarova',  'madina@example.com',  NULL,           '2026-03-15'),
    ('Timur Beketov',   'timur@example.com',   '+77044444444', '2026-04-20'),
    ('Aliya Serik',     'aliya@example.com',   '+77055555555', '2026-05-25');

INSERT INTO products (name, description, price, stock_quantity) VALUES
    ('Laptop',     '15-inch laptop',      450000.00, 15),
    ('Phone',      'Smartphone 128GB',    250000.00, 40),
    ('Headphones', 'Wireless headphones',  30000.00, 100),
    ('Mouse',      'USB optical mouse',     5000.00, 200),
    ('Keyboard',   'Mechanical keyboard',  25000.00, 60);

INSERT INTO orders (customer_id, order_date, total_amount, status) VALUES
    (1, '2026-09-01', 480000.00, 'delivered'),
    (2, '2026-09-05', 250000.00, 'shipped'),
    (3, '2026-09-10',  35000.00, 'processing'),
    (4, '2026-09-15',  30000.00, 'pending'),
    (5, '2026-09-20', 450000.00, 'cancelled');

INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 450000.00),
    (1, 3, 1,  30000.00),
    (2, 2, 1, 250000.00),
    (3, 4, 2,   5000.00),
    (3, 5, 1,  25000.00),
    (4, 3, 1,  30000.00),
    (5, 1, 1, 450000.00);

-- ---------- Constraint tests (failures commented out) ----------
-- PRIMARY KEY
-- INSERT INTO customers (customer_id, name, email) VALUES (1, 'Dup', 'dup@example.com');
-- RESULT: ERROR: duplicate key value violates unique constraint "customers_pkey"

-- UNIQUE email
-- INSERT INTO customers (name, email) VALUES ('Copy', 'aigerim@example.com');
-- RESULT: ERROR: duplicate key value violates unique constraint "customers_email_key"

-- NOT NULL
-- INSERT INTO customers (name, email) VALUES (NULL, 'x@example.com');
-- RESULT: ERROR: null value in column "name" ... violates not-null constraint

-- CHECK: non-negative price / stock
-- INSERT INTO products (name, price, stock_quantity) VALUES ('Bad', -1, 5);
-- RESULT: ERROR: violates check constraint "products_price_check"
-- INSERT INTO products (name, price, stock_quantity) VALUES ('Bad', 1, -5);
-- RESULT: ERROR: violates check constraint "products_stock_quantity_check"

-- CHECK: order status
-- INSERT INTO orders (customer_id, total_amount, status) VALUES (1, 10, 'lost');
-- RESULT: ERROR: violates check constraint "orders_status_check"

-- CHECK: positive quantity
-- INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES (1, 1, 0, 10);
-- RESULT: ERROR: violates check constraint "order_details_quantity_check"

-- FOREIGN KEY: non-existent parent
-- INSERT INTO orders (customer_id, total_amount) VALUES (999, 10);
-- RESULT: ERROR: violates foreign key constraint "orders_customer_id_fkey"

-- ON DELETE RESTRICT: customer with orders
-- DELETE FROM customers WHERE customer_id = 1;
-- RESULT: ERROR: violates foreign key constraint "orders_customer_id_fkey" on table "orders"

-- ON DELETE RESTRICT: product that was sold
-- DELETE FROM products WHERE product_id = 1;
-- RESULT: ERROR: violates foreign key constraint "order_details_product_id_fkey"

-- ON DELETE CASCADE: deleting an order removes its details
DELETE FROM orders WHERE order_id = 5;
-- RESULT: DELETE 1; order_details row for order 5 is deleted too.
SELECT COUNT(*) FROM order_details WHERE order_id = 5;   -- RESULT: 0

-- Valid delete: customer with no orders is allowed
INSERT INTO customers (name, email) VALUES ('Temp User', 'temp@example.com');
DELETE FROM customers WHERE email = 'temp@example.com';  -- RESULT: DELETE 1