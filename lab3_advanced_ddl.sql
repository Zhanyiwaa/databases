CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,                
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    department VARCHAR(50),                       
    salary     INTEGER,                           
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50) NOT NULL,
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- PART B: Advanced INSERT Operations

-- 2. INSERT 
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Alice', 'Ivanova', 'IT'),
       (2, 'Bob',   'Petrov',  'Sales'),
       (3, 'Carol', 'Sidorova','HR');

SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- 3. INSERT с DEFAULT 
INSERT INTO employees (first_name, last_name, department, salary, status)
VALUES ('Dan', 'Kim', 'IT', DEFAULT, DEFAULT);

-- 4. INSERT 
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT',    150000, 1),
       ('Sales',  80000, 2),
       ('HR',     60000, 3);

-- 5. INSERT 
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Eva', 'Lee', 'IT', (50000 * 1.1)::INTEGER, CURRENT_DATE);

-- 6. INSERT ... SELECT: 
CREATE TEMPORARY TABLE temp_employees (LIKE employees);

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';


INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Frank', 'Novak', 'IT',    90000, '2018-03-15', 'Active'),
       ('Grace', 'Ross',  'Sales', 70000, '2019-07-01', 'Active'),
       ('Henry', 'Stone', 'Sales', 45000, '2021-05-20', 'Active'),
       ('Irene', 'Volk',  'HR',    38000, '2023-06-10', 'Active'),
       ('Jack',  'Wood',  'IT',    65000, '2021-11-11', 'Inactive'),
       ('Kate',  'Young', NULL,    35000, '2024-02-02', 'Active'),
       ('Leo',   'Zorin', 'Sales', 52000, '2022-09-09', 'Terminated'),
       ('Mia',   'Belov', 'HR',    85000, '2015-01-20', 'Active');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Website',       1, '2022-01-01', '2022-12-31',  60000),
       ('Mobile App',    1, '2023-03-01', '2023-12-31', 120000),
       ('Recruiting',    3, '2021-01-01', '2022-06-30',  20000),
       ('Sales Portal',  2, '2023-05-01', '2024-05-01',  40000),
       ('Data Platform', 1, '2024-01-01', '2024-12-31',  90000);



-- PART C: Complex UPDATE Operations

-- 7. UPDATE 
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE 
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. UPDATE с CASE
UPDATE employees
SET department = CASE
                     WHEN salary > 80000               THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

-- 10. UPDATE с DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Oscar', 'Pak',   'IT',    48000, '2021-04-04', 'Inactive'),
       ('Paul',  'Quinn', 'IT',    72000, '2021-08-01', 'Active'),
       ('Rita',  'Sato',  'IT',    55000, '2022-02-14', 'Active'),
       ('Sam',    'Tran', 'IT',    61000, '2023-01-10', 'Active'),
       ('Tina',  'Ulm',   'Sales', 58000, '2019-12-01', 'Active'),
       ('Uma',   'Vega',  'Sales', 43000, '2024-01-15', 'Active'),
       ('Vera',  'Wolf',  'HR',    50000, '2020-06-01', 'Active'),
       ('Nina',  'Ortiz', NULL,    30000, '2024-03-03', 'Active');

INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('Legal', 30000, NULL);   -- отдел без сотрудников (для задания 15)

-- 11. UPDATE с подзапросом: 
UPDATE departments d
SET budget = (SELECT AVG(e.salary) * 1.20
              FROM employees e
              WHERE e.department = d.dept_name)::INTEGER
WHERE EXISTS (SELECT 1
              FROM employees e
              WHERE e.department = d.dept_name
                AND e.salary IS NOT NULL);

-- 12. UPDATE 
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';


-- PART D: Advanced DELETE Operations

-- 13. DELETE с простым WHERE
DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE со сложным WHERE
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. DELETE с подзапросом
DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

-- 16. DELETE с RETURNING
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


-- PART E: Operations with NULL Values
-- 17. INSERT с NULL
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Null', 'Person', NULL, NULL, CURRENT_DATE);

-- 18. UPDATE: замена NULL 
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;


-- PART F: RETURNING Clause Operations

-- 20. INSERT с RETURNING:
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zoe', 'Adams', 'IT', 60000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE с RETURNING:
UPDATE employees e
SET salary = e.salary + 5000
FROM employees old
WHERE old.emp_id = e.emp_id
  AND e.department = 'IT'
RETURNING e.emp_id,
          old.salary AS old_salary,
          e.salary   AS new_salary;

-- 22. DELETE с RETURNING
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


-- PART G: Advanced DML Patterns
-- 23. Условный INSERT
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Alice', 'Ivanova', 'IT', 70000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Alice'
                    AND last_name  = 'Ivanova');

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Anna', 'Smirnova', 'HR', 52000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Anna'
                    AND last_name  = 'Smirnova');

-- 24. UPDATE на основе бюджета отдела 
UPDATE employees e
SET salary = e.salary * CASE
                            WHEN (SELECT d.budget
                                  FROM departments d
                                  WHERE d.dept_name = e.department) > 100000
                                THEN 1.10
                            ELSE 1.05
                        END
WHERE EXISTS (SELECT 1
              FROM departments d
              WHERE d.dept_name = e.department);

-- 25. Массовые операции
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bulk1', 'Batch', 'IT',    50000, CURRENT_DATE),
       ('Bulk2', 'Batch', 'IT',    51000, CURRENT_DATE),
       ('Bulk3', 'Batch', 'Sales', 52000, CURRENT_DATE),
       ('Bulk4', 'Batch', 'HR',    53000, CURRENT_DATE),
       ('Bulk5', 'Batch', 'HR',    54000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Batch';

CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

BEGIN;

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

COMMIT;

UPDATE projects p
SET end_date = p.end_date + 30
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3;


