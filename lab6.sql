-- LAB 6: SQL JOINS
-- PART 1: DATABASE SETUP

BEGIN;

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
);

INSERT INTO employees VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 102, 60000),
    (3, 'Mike Johnson', 101, 55000),
    (4, 'Sarah Williams', 103, 65000),
    (5, 'Tom Brown', NULL, 45000);

INSERT INTO departments VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Finance', 'Building C'),
    (104, 'Marketing', 'Building D');

INSERT INTO projects VALUES
    (1, 'Website Redesign', 101, 100000),
    (2, 'Employee Training', 102, 50000),
    (3, 'Budget Analysis', 103, 75000),
    (4, 'Cloud Migration', 101, 150000),
    (5, 'AI Research', NULL, 200000);

COMMIT;


-- PART 2: CROSS JOIN

-- 2.1. Every employee paired with every department: 5 * 4 = 20 rows.
SELECT e.emp_name, d.dept_name
FROM employees e
CROSS JOIN departments d;

-- 2.2a. Comma notation.
SELECT e.emp_name, d.dept_name
FROM employees e, departments d;

-- 2.2b. INNER JOIN with ON TRUE.
SELECT e.emp_name, d.dept_name
FROM employees e
INNER JOIN departments d ON TRUE;

-- 2.3. Every employee paired with every project: 5 * 5 = 25 rows.
SELECT e.emp_name, p.project_name
FROM employees e
CROSS JOIN projects p
ORDER BY e.emp_id, p.project_id;


-- PART 3: INNER JOIN

-- 3.1. Four rows. Tom Brown has a NULL dept_id, so he has no match.
SELECT e.emp_name, d.dept_name, d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- 3.2. Same three selected columns as 3.1.
-- With SELECT *, USING shows one dept_id and ON shows two.
SELECT emp_name, dept_name, location
FROM employees
INNER JOIN departments USING (dept_id);

-- 3.3. NATURAL JOIN uses the shared column name dept_id.
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

-- 3.4. Employee, department, and project names: 6 rows.
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;


-- PART 4: LEFT JOIN

-- 4.1. Tom Brown appears with NULL department values.
SELECT e.emp_name, e.dept_id AS emp_dept,
       d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id;

-- 4.2. Keep the same output columns using USING.
SELECT e.emp_name, e.dept_id AS emp_dept,
       d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d USING (dept_id);

-- 4.3. Employees without a matching department: Tom Brown.
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

-- 4.4. IT = 2, Finance = 1, HR = 1, Marketing = 0.
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC, d.dept_name;


-- PART 5: RIGHT JOIN

-- 5.1. Marketing appears with a NULL employee name.
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

-- 5.2. Same result using LEFT JOIN.
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;

-- 5.3. Departments without employees: Marketing.
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;


-- PART 6: FULL JOIN

-- 6.1. Marketing has NULL employee columns.
-- Tom Brown has NULL department columns.
SELECT e.emp_name, e.dept_id AS emp_dept,
       d.dept_id AS dept_dept, d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id;

-- 6.2. Marketing has no project. AI Research has no department.
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL OUTER JOIN projects p ON d.dept_id = p.dept_id;

-- 6.3. Keep only unmatched rows from either side.
SELECT CASE
           WHEN e.emp_id IS NULL THEN 'Department without employees'
           ELSE 'Employee without department'
       END AS record_status,
       e.emp_name,
       d.dept_name
FROM employees e
FULL OUTER JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;


-- PART 7: ON VS WHERE

-- 7.1. ON controls which departments match. All five employees remain.
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d
    ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- 7.2. WHERE filters the joined rows. Only John and Mike remain.
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';

-- 7.3a. INNER JOIN with the location filter in ON.
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d
    ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- 7.3b. INNER JOIN with the location filter in WHERE.
-- Both versions return John and Mike because both conditions must be true.
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';


-- PART 8: COMPLEX JOINS

-- 8.1. Keep all departments and show any employees and projects.
SELECT d.dept_name, e.emp_name, e.salary, p.project_name, p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name, p.project_name;

-- 8.2. Run these three statements in order. Mike manages the other four.
ALTER TABLE employees ADD COLUMN manager_id INT;

UPDATE employees
SET manager_id = 3
WHERE emp_id IN (1, 2, 4, 5);

SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

-- 8.3. Average salary above 50,000: Finance, HR, and IT.
SELECT d.dept_name, s.avg_salary
FROM departments d
INNER JOIN (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
    HAVING AVG(salary) > 50000
) s ON d.dept_id = s.dept_id
ORDER BY s.avg_salary DESC;


-- LAB QUESTIONS

-- 1. INNER JOIN keeps matching pairs. LEFT JOIN also keeps unmatched
--    left rows and fills their right-side columns with NULL.
-- 2. CROSS JOIN can pair every employee with every project.
-- 3. ON controls matches. WHERE filters the result, so it can remove
--    the NULL-filled rows that an outer join preserves. For an INNER JOIN,
--    the same AND filter in ON or WHERE keeps the same matching pairs.
-- 4. COUNT(*) returns 5 * 10 = 50.
-- 5. NATURAL JOIN uses all column names that both tables share.
-- 6. Adding a shared column name can silently change the join condition.
--    With no shared column names, NATURAL JOIN acts like CROSS JOIN.
-- 7. SELECT A.*, B.* FROM B RIGHT JOIN A ON A.id = B.id;
-- 8. Use FULL OUTER JOIN when you need matches and unmatched rows
--    from both tables.


-- OPTIONAL CHALLENGES

-- 1. Simulate FULL OUTER JOIN. The second branch adds unmatched departments.
SELECT e.emp_name, e.dept_id AS emp_dept,
       d.dept_id AS dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id

UNION ALL

SELECT e.emp_name, e.dept_id, d.dept_id, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-- 2. Employees in departments with more than one project.
SELECT e.emp_name, d.dept_name, p.project_count
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN (
    SELECT dept_id, COUNT(*) AS project_count
    FROM projects
    GROUP BY dept_id
    HAVING COUNT(*) > 1
) p ON d.dept_id = p.dept_id;

-- 3. Reporting hierarchy. Run Exercise 8.2 first.
WITH RECURSIVE organization AS (
    SELECT emp_id, emp_name, manager_id, 0 AS depth,
           CAST(emp_name AS TEXT) AS reporting_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.emp_id, e.emp_name, e.manager_id, o.depth + 1,
           o.reporting_path || ' -> ' || e.emp_name
    FROM organization o
    INNER JOIN employees e ON e.manager_id = o.emp_id
)
SELECT o.depth, o.emp_name AS employee, m.emp_name AS manager,
       o.reporting_path
FROM organization o
LEFT JOIN employees m ON o.manager_id = m.emp_id
ORDER BY o.reporting_path;

-- 4. Employee pairs in the same department. Each pair appears once.
SELECT d.dept_name, e1.emp_name AS employee_1, e2.emp_name AS employee_2
FROM employees e1
INNER JOIN employees e2
    ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
INNER JOIN departments d ON e1.dept_id = d.dept_id;