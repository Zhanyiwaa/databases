-- LABORATORY WORK 8: SQL INDEXES
-- PostgreSQL
-- Rerunning this script resets only the lab8 exercise tables.

CREATE SCHEMA IF NOT EXISTS lab8;
SET search_path TO lab8;

-- PART 1: DATABASE SETUP

DROP TABLE IF EXISTS projects, employees, departments CASCADE;

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT REFERENCES departments(dept_id),
    salary DECIMAL(10,2)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);


-- EXERCISE 2.1: SIMPLE B-TREE INDEX

CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'lab8'
  AND tablename = 'employees';

-- Answer: Two indexes:
-- employees_pkey, created automatically for the primary key.
-- emp_salary_idx, created manually.


-- EXERCISE 2.2: FOREIGN KEY INDEX

CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT *
FROM employees
WHERE dept_id = 101;

-- Answer: Indexing foreign keys can speed up joins and searches.
-- It also helps locate referencing rows when a parent row is
-- deleted or its referenced key is updated.
-- PostgreSQL does not automatically index foreign key columns.
-- Small tables may still use a sequential scan.


-- EXERCISE 2.3: VIEW INDEX INFORMATION

SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'lab8'
ORDER BY tablename, indexname;

-- Answer:
-- departments_pkey: automatic.
-- employees_pkey: automatic.
-- projects_pkey: automatic.
-- emp_salary_idx: manual.
-- emp_dept_idx: manual.


-- EXERCISE 3.1: MULTICOLUMN INDEX

CREATE INDEX emp_dept_salary_idx
ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- Answer: This index is most effective when dept_id is filtered.
-- A salary-only query can sometimes use it, but a salary-leading
-- index is generally more suitable for that query.


-- EXERCISE 3.2: COLUMN ORDER

CREATE INDEX emp_salary_dept_idx
ON employees(salary, dept_id);

SELECT *
FROM employees
WHERE dept_id = 102 AND salary > 50000;

SELECT *
FROM employees
WHERE salary > 50000 AND dept_id = 102;

-- Answer: Column order inside the index matters.
-- (dept_id, salary) is well suited to equality on dept_id
-- followed by a range condition on salary.
-- Reordering AND conditions in the query does not change its meaning
-- or force PostgreSQL to choose a different index.


-- EXERCISE 4.1: UNIQUE INDEX

ALTER TABLE employees
ADD COLUMN email VARCHAR(100);

UPDATE employees
SET email = CASE emp_id
    WHEN 1 THEN 'john.smith@company.com'
    WHEN 2 THEN 'jane.doe@company.com'
    WHEN 3 THEN 'mike.johnson@company.com'
    WHEN 4 THEN 'sarah.williams@company.com'
    WHEN 5 THEN 'tom.brown@company.com'
END;

CREATE UNIQUE INDEX emp_email_unique_idx
ON employees(email);

-- Catch the expected error so the remaining script continues.

DO $$
BEGIN
    INSERT INTO employees
        (emp_id, emp_name, dept_id, salary, email)
    VALUES
        (6, 'New Employee', 101, 55000, 'john.smith@company.com');
EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Expected error: %', SQLERRM;
END;
$$;

-- Answer:
-- duplicate key value violates unique constraint "emp_email_unique_idx"
-- SQLSTATE: 23505.
-- The duplicate employee was not inserted.


-- EXERCISE 4.2: UNIQUE CONSTRAINT

ALTER TABLE employees
ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'lab8'
  AND tablename = 'employees'
  AND indexname LIKE '%phone%';

-- Answer: PostgreSQL automatically creates a unique B-tree index
-- named employees_phone_key.


-- EXERCISE 5.1: INDEX FOR SORTING

CREATE INDEX emp_salary_desc_idx
ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- Answer: An ordered index scan can return rows in salary order
-- without a separate sorting step.
-- An ascending B-tree index can also be scanned backward
-- to satisfy this particular descending query.


-- EXERCISE 5.2: NULL HANDLING

CREATE INDEX proj_budget_nulls_first_idx
ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;


-- EXERCISE 6.1: EXPRESSION INDEX

CREATE INDEX emp_name_lower_idx
ON employees(LOWER(emp_name));

SELECT *
FROM employees
WHERE LOWER(emp_name) = 'john smith';

-- Answer: Without a suitable expression index, PostgreSQL
-- typically scans the table and evaluates LOWER(emp_name)
-- for each row.


-- EXERCISE 6.2: INDEX ON CALCULATED VALUES

ALTER TABLE employees
ADD COLUMN hire_date DATE;

UPDATE employees
SET hire_date = CASE emp_id
    WHEN 1 THEN DATE '2020-01-15'
    WHEN 2 THEN DATE '2019-06-20'
    WHEN 3 THEN DATE '2021-03-10'
    WHEN 4 THEN DATE '2020-11-05'
    WHEN 5 THEN DATE '2018-08-25'
END;

CREATE INDEX emp_hire_year_idx
ON employees((EXTRACT(YEAR FROM hire_date)));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;


-- EXERCISE 7.1: RENAME AN INDEX

ALTER INDEX emp_salary_idx
RENAME TO employees_salary_index;

SELECT indexname
FROM pg_indexes
WHERE schemaname = 'lab8'
  AND tablename = 'employees';


-- EXERCISE 7.2: DROP AN INDEX

DROP INDEX emp_salary_dept_idx;

-- Answer: Drop an index when it is redundant or rarely useful.
-- This saves storage and reduces index maintenance during writes.


-- EXERCISE 7.3: REBUILD AN INDEX

REINDEX INDEX employees_salary_index;

-- Answer: REINDEX rebuilds an index.
-- It is useful for significant index bloat or index corruption.
-- Bulk inserts alone do not automatically require REINDEX.


-- EXERCISE 8.1: OPTIMIZE A QUERY

CREATE INDEX emp_salary_filter_idx
ON employees(salary)
WHERE salary > 50000;

-- emp_dept_idx and emp_salary_desc_idx already exist.

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- The planner chooses which indexes, if any, are worthwhile.
-- The partial salary index can also be scanned backward
-- to provide descending salary order.


-- EXERCISE 8.2: PARTIAL INDEX

CREATE INDEX proj_high_budget_idx
ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- Answer: A partial index stores only rows satisfying its predicate.
-- It can use less space and require less maintenance than
-- a full index, while supporting queries for that subset.


-- EXERCISE 8.3: ANALYZE INDEX USAGE

ANALYZE employees;

EXPLAIN
SELECT *
FROM employees
WHERE salary > 52000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE salary > 52000;

-- Answer: Read the actual plan above.
-- Seq Scan means PostgreSQL scans the table.
-- Index Scan means PostgreSQL uses an index to locate rows.
-- A Bitmap Index Scan is another possible form of index access.
-- With only five employees, a Seq Scan is usually cheaper.
-- A Seq Scan does not mean that the index is incorrect.


-- EXERCISE 9.1: HASH INDEX

CREATE INDEX dept_name_hash_idx
ON departments USING HASH(dept_name);

SELECT *
FROM departments
WHERE dept_name = 'IT';

-- Answer: Consider a hash index for equality-only searches
-- when measurements show a benefit.
-- Hash indexes do not support range searches or ordered scans.
-- B-tree is generally the more versatile default.


-- EXERCISE 9.2: COMPARE INDEX TYPES

CREATE INDEX proj_name_btree_idx
ON projects USING BTREE(proj_name);

CREATE INDEX proj_name_hash_idx
ON projects USING HASH(proj_name);

-- Equality: either index type can support this condition.

SELECT *
FROM projects
WHERE proj_name = 'Website Redesign';

-- Range: B-tree supports this condition; hash does not.

SELECT *
FROM projects
WHERE proj_name > 'Database';


-- EXERCISE 10.1: INDEX SIZES

SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(
        pg_relation_size(
            format('%I.%I', schemaname, indexname)::regclass
        )
    ) AS index_size
FROM pg_indexes
WHERE schemaname = 'lab8'
ORDER BY tablename, indexname;

-- Find the largest index or indexes, including ties.

WITH index_sizes AS (
    SELECT
        tablename,
        indexname,
        pg_relation_size(
            format('%I.%I', schemaname, indexname)::regclass
        ) AS size_bytes
    FROM pg_indexes
    WHERE schemaname = 'lab8'
)
SELECT
    tablename,
    indexname,
    pg_size_pretty(size_bytes) AS index_size
FROM index_sizes
WHERE size_bytes = (SELECT MAX(size_bytes) FROM index_sizes)
ORDER BY indexname;

-- Answer: The query reports the actual largest index or indexes.
-- Size depends on the index type, indexed values, row count,
-- page allocation, and bloat. Small indexes may have equal sizes.


-- EXERCISE 10.2: DROP AN UNNECESSARY INDEX

DROP INDEX IF EXISTS proj_name_hash_idx;

-- The B-tree index already supports project-name equality
-- and range searches, so the extra hash index is unnecessary
-- for the demonstrated workload.


-- EXERCISE 10.3: DOCUMENT INDEXES

CREATE OR REPLACE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries'::TEXT AS purpose
FROM pg_indexes
WHERE schemaname = 'lab8'
  AND indexname LIKE '%salary%';

SELECT *
FROM index_documentation;


-- SUMMARY QUESTIONS

-- 1. Default index type?
-- B-tree.

-- 2. Three scenarios where an index is useful?
-- Frequently filtered columns in selective WHERE conditions.
-- Columns used to find matching rows in joins.
-- Columns used for ORDER BY, especially with LIMIT.

-- 3. Two scenarios where an index may be unnecessary?
-- Very small tables where sequential scans are cheaper.
-- Rarely queried columns on tables with frequent writes.

-- 4. What happens during INSERT, UPDATE, and DELETE?
-- INSERT adds entries to applicable indexes.
-- UPDATE may require new index entries; HOT updates can avoid this.
-- DELETE makes old entries obsolete; vacuum later reclaims them.
-- Index maintenance increases write overhead.

-- 5. How do you check whether an index is used?
-- Use EXPLAIN or EXPLAIN (ANALYZE, BUFFERS)
-- and inspect the scan nodes.


-- OPTIONAL CHALLENGE 1: EMPLOYEES HIRED IN A SPECIFIC MONTH
-- This example finds January hires across all years.

CREATE INDEX emp_hire_month_idx
ON employees((EXTRACT(MONTH FROM hire_date)));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(MONTH FROM hire_date) = 1;


-- OPTIONAL CHALLENGE 2: COMPOSITE UNIQUE INDEX

CREATE UNIQUE INDEX emp_dept_email_unique_idx
ON employees(dept_id, email);

-- This enforces uniqueness of each department/email pair.
-- The existing globally unique email index is stricter,
-- so this composite index is redundant for uniqueness here.


-- OPTIONAL CHALLENGE 3: COMPARE WITH AND WITHOUT AN INDEX
-- A temporary table provides enough rows for a useful comparison.

CREATE TEMP TABLE lab8_index_benchmark AS
SELECT
    g AS emp_id,
    'Employee ' || g AS emp_name,
    101 + (g % 3) AS dept_id,
    (30000 + g)::NUMERIC(10,2) AS salary
FROM generate_series(1, 100000) AS s(g);

ANALYZE lab8_index_benchmark;

-- Before creating the index.

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM lab8_index_benchmark
WHERE salary = 75000;

CREATE INDEX lab8_benchmark_salary_idx
ON lab8_index_benchmark(salary);

ANALYZE lab8_index_benchmark;

-- After creating the index.

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM lab8_index_benchmark
WHERE salary = 75000;

DROP TABLE lab8_index_benchmark;

-- Compare scan types, buffer usage, and execution times.
-- Timings can also be affected by caching.


-- OPTIONAL CHALLENGE 4: COVERING INDEX

CREATE INDEX emp_dept_salary_cover_idx
ON employees(dept_id, salary)
INCLUDE(emp_name);

EXPLAIN (ANALYZE, BUFFERS)
SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- All required columns are available from the index.
-- An index-only scan is possible when visibility permits it,
-- but the planner can still prefer a sequential scan.


-- BRIEF REFLECTION
-- Indexes help frequently executed, selective searches,
-- joins, and sorting. They consume storage and add write costs.
-- Choose indexes for actual queries, check execution plans,
-- and remove indexes that do not provide enough benefit.