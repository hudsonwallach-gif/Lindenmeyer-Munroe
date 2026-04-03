-- Departments
CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    budget NUMERIC(12, 2) NOT NULL
);

INSERT INTO departments (name, budget) VALUES
    ('Engineering',  850000.00),
    ('Sales',        620000.00),
    ('Marketing',    430000.00),
    ('HR',           210000.00),
    ('Finance',      310000.00);

-- Employees
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    department_id INTEGER REFERENCES departments(id),
    role TEXT NOT NULL,
    salary NUMERIC(10, 2) NOT NULL,
    hired_at DATE NOT NULL
);

INSERT INTO employees (name, email, department_id, role, salary, hired_at) VALUES
    ('Alice Johnson',  'alice@example.com',   1, 'Senior Engineer',    115000, '2021-03-15'),
    ('Bob Smith',      'bob@example.com',     1, 'Engineer',            95000, '2022-07-01'),
    ('Carol White',    'carol@example.com',   2, 'Account Executive',   78000, '2020-11-20'),
    ('David Lee',      'david@example.com',   2, 'Sales Manager',       98000, '2019-05-10'),
    ('Eva Martinez',   'eva@example.com',     3, 'Marketing Lead',      88000, '2021-09-01'),
    ('Frank Brown',    'frank@example.com',   3, 'Content Strategist',  72000, '2023-01-15'),
    ('Grace Kim',      'grace@example.com',   4, 'HR Manager',          82000, '2020-04-22'),
    ('Henry Park',     'henry@example.com',   1, 'Engineer',            92000, '2022-10-03'),
    ('Iris Chen',      'iris@example.com',    5, 'Financial Analyst',   86000, '2021-06-14'),
    ('James Wilson',   'james@example.com',   2, 'Account Executive',   76000, '2023-03-28');

-- Sales
CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(id),
    amount NUMERIC(10, 2) NOT NULL,
    product TEXT NOT NULL,
    sold_at DATE NOT NULL
);

INSERT INTO sales (employee_id, amount, product, sold_at) VALUES
    (3, 14200.00, 'Enterprise Plan',  '2024-01-08'),
    (3, 8750.00,  'Pro Plan',         '2024-01-22'),
    (4, 31000.00, 'Enterprise Plan',  '2024-02-05'),
    (3, 11500.00, 'Pro Plan',         '2024-02-14'),
    (10, 9200.00, 'Starter Plan',     '2024-02-19'),
    (4, 27500.00, 'Enterprise Plan',  '2024-03-03'),
    (10, 13400.00,'Pro Plan',         '2024-03-17'),
    (3, 18900.00, 'Enterprise Plan',  '2024-03-25'),
    (4, 22000.00, 'Enterprise Plan',  '2024-04-02'),
    (10, 7600.00, 'Starter Plan',     '2024-04-11');
