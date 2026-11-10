-- PART 1. Lab 6 setup
-- Run the SQL inside this comment only if the three tables are missing.
/*
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

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
    (1, 'John Smith', 101, 50000),
    (2, 'Jane Doe', 102, 60000),
    (3, 'Mike Johnson', 101, 55000),
    (4, 'Sarah Williams', 103, 65000),
    (5, 'Tom Brown', NULL, 45000);

INSERT INTO departments (dept_id, dept_name, location) VALUES
    (101, 'IT', 'Building A'),
    (102, 'HR', 'Building B'),
    (103, 'Finance', 'Building C'),
    (104, 'Marketing', 'Building D');

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
    (1, 'Website Redesign', 101, 100000),
    (2, 'Employee Training', 102, 50000),
    (3, 'Budget Analysis', 103, 75000),
    (4, 'Cloud Migration', 101, 150000),
    (5, 'AI Research', NULL, 200000);
*/

-- PART 2. Basic views

-- 2.1 Employee details
CREATE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id;

SELECT * FROM employee_details;
-- 4 rows. Tom Brown has NULL dept_id, so the INNER JOIN excludes him.

-- 2.2 Department statistics
CREATE VIEW dept_statistics AS
SELECT d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       AVG(e.salary) AS average_salary,
       MAX(e.salary) AS maximum_salary,
       MIN(e.salary) AS minimum_salary
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name;

SELECT * FROM dept_statistics ORDER BY employee_count DESC;

-- 2.3 Project overview
CREATE VIEW project_overview AS
SELECT p.project_name, p.budget, d.dept_name, d.location,
       COUNT(e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON d.dept_id = p.dept_id
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name, d.location;

SELECT * FROM project_overview;

-- 2.4 High earners
CREATE VIEW high_earners AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id
WHERE e.salary > 55000;

SELECT * FROM high_earners;
-- Initially Jane Doe and Sarah Williams. LEFT JOIN also keeps
-- any qualifying employee who has no department.

-- PART 3. Modify and manage views

-- 3.1 Add salary grade
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
       CASE
           WHEN e.salary > 60000 THEN 'High'
           WHEN e.salary > 50000 THEN 'Medium'
           ELSE 'Standard'
       END AS salary_grade
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id;

SELECT * FROM employee_details;

-- 3.2 Rename a view
ALTER VIEW high_earners RENAME TO top_performers;
SELECT * FROM top_performers;

-- 3.3 Create and drop a temporary view
CREATE TEMP VIEW temp_view AS
SELECT * FROM employees WHERE salary < 50000;

DROP VIEW temp_view;

-- PART 4. Updatable views

-- 4.1 Create the view
CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

-- 4.2 Update through the view
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

SELECT * FROM employees WHERE emp_name = 'John Smith';
-- The employees table now shows John's salary as 52000.

-- 4.3 Insert through the view
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

SELECT * FROM employees WHERE emp_id = 6;
-- Alice appears in the employees table.

-- 4.4 LOCAL CHECK OPTION
CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

DO $$
BEGIN
    INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
    VALUES (7, 'Bob Wilson', 103, 60000);
EXCEPTION
    WHEN with_check_option_violation THEN
        RAISE NOTICE '%', SQLERRM;
END;
$$;
-- SQLSTATE 44000. Bob's dept_id is 103, but the view requires 101.

-- PART 5. Materialized views

-- 5.1 Department summary
CREATE MATERIALIZED VIEW dept_summary_mv AS
WITH employee_totals AS (
    SELECT dept_id, COUNT(*) AS total_employees, SUM(salary) AS total_salaries
    FROM employees
    GROUP BY dept_id
),
project_totals AS (
    SELECT dept_id, COUNT(*) AS total_projects, SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
)
SELECT d.dept_id, d.dept_name,
       COALESCE(e.total_employees, 0) AS total_employees,
       COALESCE(e.total_salaries, 0) AS total_salaries,
       COALESCE(p.total_projects, 0) AS total_projects,
       COALESCE(p.total_project_budget, 0) AS total_project_budget
FROM departments d
LEFT JOIN employee_totals e ON e.dept_id = d.dept_id
LEFT JOIN project_totals p ON p.dept_id = d.dept_id
WITH DATA;

SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- 5.2 Refresh after inserting Charlie
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

-- Before refresh, IT still shows 2 employees and 107000 in salaries.
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- After refresh, IT shows 3 employees and 161000 in salaries.
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;

-- 5.3 Concurrent refresh
CREATE UNIQUE INDEX dept_summary_mv_dept_id_idx
ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
-- Other sessions can continue reading the view during the refresh.

-- 5.4 Create WITH NO DATA
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT project_name, budget, dept_name, team_size AS employee_count
FROM project_overview
WITH NO DATA;

DO $$
BEGIN
    PERFORM * FROM project_stats_mv;
EXCEPTION
    WHEN object_not_in_prerequisite_state THEN
        RAISE NOTICE '%', SQLERRM;
END;
$$;
-- SQLSTATE 55000. The materialized view has not been populated yet.

REFRESH MATERIALIZED VIEW project_stats_mv;
SELECT * FROM project_stats_mv;

-- PART 6. Database roles

-- 6.1 Basic roles
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report456';

SELECT rolname FROM pg_roles WHERE LEFT(rolname, 3) <> 'pg_';

-- 6.2 Role attributes
CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';

-- 6.3 Grant privileges
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- 6.4 Group roles
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE USER hr_user1 PASSWORD 'hr001';
CREATE USER hr_user2 PASSWORD 'hr002';
CREATE USER finance_user1 PASSWORD 'fin001';

GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- 6.5 Revoke privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- 6.6 Modify roles
ALTER ROLE analyst LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;

-- PART 7. Advanced role management

-- 7.1 Role hierarchy
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE USER junior_analyst PASSWORD 'junior123';
CREATE USER senior_analyst PASSWORD 'senior123';

GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- 7.2 Transfer ownership
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

-- The new view owner needs SELECT on the underlying tables.
GRANT SELECT ON employees, departments TO project_manager;
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'projects';

SELECT viewname, viewowner
FROM pg_views
WHERE schemaname = 'public' AND viewname = 'dept_statistics';

-- 7.3 Reassign and drop a role
CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;
-- temp_table remains in the database under postgres ownership.

-- 7.4 Restricted views
CREATE VIEW hr_employee_view WITH (security_barrier = true) AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

-- Remove the earlier table grant so HR access goes through its view.
REVOKE SELECT ON employees FROM hr_team;
GRANT SELECT ON hr_employee_view TO hr_team;
GRANT SELECT ON finance_employee_view TO finance_team;

-- PART 8. Practical scenarios

-- 8.1 Department dashboard
-- Lab 6 has no project status column, so all assigned projects count as active.
CREATE VIEW dept_dashboard AS
WITH employee_stats AS (
    SELECT dept_id, COUNT(*) AS employee_count, AVG(salary) AS average_salary
    FROM employees
    GROUP BY dept_id
),
project_stats AS (
    SELECT dept_id, COUNT(*) AS active_projects, SUM(budget) AS total_project_budget
    FROM projects
    GROUP BY dept_id
)
SELECT d.dept_name, d.location,
       COALESCE(e.employee_count, 0) AS employee_count,
       ROUND(e.average_salary, 2) AS average_salary,
       COALESCE(p.active_projects, 0) AS active_projects,
       COALESCE(p.total_project_budget, 0) AS total_project_budget,
       ROUND(
           COALESCE(p.total_project_budget, 0) / NULLIF(e.employee_count, 0),
           2
       ) AS budget_per_employee
FROM departments d
LEFT JOIN employee_stats e ON e.dept_id = d.dept_id
LEFT JOIN project_stats p ON p.dept_id = d.dept_id;

SELECT * FROM dept_dashboard;
-- budget_per_employee is NULL when the department has zero employees.

-- 8.2 High-budget project audit
ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_name, p.budget, d.dept_name, p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 100000 THEN 'Management Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON d.dept_id = p.dept_id
WHERE p.budget > 75000;

SELECT * FROM high_budget_projects;

-- 8.3 Access control system
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE USER alice PASSWORD 'alice123';
CREATE USER bob PASSWORD 'bob123';
CREATE USER charlie PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;