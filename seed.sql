-- ============================================================
-- Lindenmeyr Munroe — Realistic ERP Sample Data
-- Paper, Packaging & Wide Format Distribution
-- ============================================================

-- Warehouses / Branch Locations
CREATE TABLE warehouses (
    id          SERIAL PRIMARY KEY,
    code        TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    city        TEXT NOT NULL,
    state       TEXT NOT NULL,
    region      TEXT NOT NULL
);

INSERT INTO warehouses (code, name, city, state, region) VALUES
    ('TET', 'Teterboro Distribution Center',    'Teterboro',    'NJ', 'Northeast'),
    ('PUR', 'Purchase Headquarters',             'Purchase',     'NY', 'Northeast'),
    ('PHI', 'Philadelphia Branch',               'Philadelphia', 'PA', 'Mid-Atlantic'),
    ('BOS', 'Boston Branch',                     'Boston',       'MA', 'Northeast'),
    ('ATL', 'Atlanta Distribution Center',       'Atlanta',      'GA', 'Southeast'),
    ('DAL', 'Dallas Branch',                     'Dallas',       'TX', 'Southwest'),
    ('CHI', 'Chicago Branch',                    'Chicago',      'IL', 'Midwest'),
    ('MIA', 'Miami Branch',                      'Miami',        'FL', 'Southeast'),
    ('DET', 'Detroit Branch',                    'Detroit',      'MI', 'Midwest');

-- Product Categories
CREATE TABLE product_categories (
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    division TEXT NOT NULL
);

INSERT INTO product_categories (name, division) VALUES
    ('Coated Paper',           'Paper'),
    ('Uncoated Offset Paper',  'Paper'),
    ('Text & Cover Stock',     'Paper'),
    ('Digital Substrates',     'Paper'),
    ('Bond & Copy Paper',      'Paper'),
    ('Wide Format Media',      'Wide Format'),
    ('Carton Sealing Tape',    'Packaging'),
    ('Bubble Wrap & Mailers',  'Packaging'),
    ('Corrugated & Boxes',     'Packaging'),
    ('Poly Bags & Stretch Film','Packaging'),
    ('Janitorial Supplies',    'Facility Solutions'),
    ('Breakroom Supplies',     'Facility Solutions');

-- Products (SKUs)
CREATE TABLE products (
    id             SERIAL PRIMARY KEY,
    sku            TEXT NOT NULL UNIQUE,
    name           TEXT NOT NULL,
    category_id    INTEGER REFERENCES product_categories(id),
    brand          TEXT,
    weight_lb      NUMERIC(6,2),
    finish         TEXT,
    size           TEXT,
    unit_of_measure TEXT NOT NULL DEFAULT 'Carton',
    list_price     NUMERIC(10,2) NOT NULL,
    active         BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO products (sku, name, category_id, brand, weight_lb, finish, size, unit_of_measure, list_price) VALUES
    ('COA-60-8535-GL', 'Sterling Ultra Gloss 60lb Text 85x35',        1, 'Sterling',      60,   'Gloss',  '85x35',    'Carton', 89.50),
    ('COA-80-2528-GL', 'Sterling Ultra Gloss 80lb Cover 25x38',        1, 'Sterling',      80,   'Gloss',  '25x38',    'Carton', 112.00),
    ('COA-70-2338-MT', 'Moistrite Matte 70lb Text 23x38',              1, 'Moistrite',     70,   'Matte',  '23x38',    'Carton', 94.75),
    ('COA-100-2638-SL','Productolith Silk 100lb Text 26x38',           1, 'Productolith',  100,  'Silk',   '26x38',    'Carton', 134.00),
    ('UNC-60-2438-SM', 'Finch Opaque 60lb Offset 24x38',               2, 'Finch',         60,   NULL,     '24x38',    'Carton', 72.00),
    ('UNC-70-2535-SM', 'Finch Opaque 70lb Offset 25x35',               2, 'Finch',         70,   NULL,     '25x35',    'Carton', 84.50),
    ('UNC-50-2338-SM', 'Husky Opaque 50lb Offset 23x38',               2, 'Husky',         50,   NULL,     '23x38',    'Carton', 61.00),
    ('TXT-70-2338-CL', 'Cougar Natural 70lb Text 23x38',               3, 'Cougar',        70,   NULL,     '23x38',    'Carton', 98.00),
    ('TXT-80-2638-WH', 'Cougar White 80lb Cover 26x38',                3, 'Cougar',        80,   NULL,     '26x38',    'Carton', 118.50),
    ('TXT-60-2538-CL', 'Strathmore Writing 60lb Text 25x38',           3, 'Strathmore',    60,   NULL,     '25x38',    'Carton', 105.00),
    ('DIG-90-1217-TN', 'Color Copy 90gsm Digital 12x17',               4, 'Color Copy',    NULL, NULL,     '12x17',    'Carton', 67.00),
    ('DIG-120-1319-GL','Indigo Gloss 120gsm 13x19',                    4, 'HP Indigo',     NULL, 'Gloss',  '13x19',    'Carton', 143.00),
    ('BND-20-8511-WH', 'Hammermill Bond 20lb 8.5x11',                  5, 'Hammermill',    20,   NULL,     '8.5x11',   'Case',   42.00),
    ('BND-24-3600-WH', 'Hammermill Bond 24lb 36in Roll 300ft',         5, 'Hammermill',    24,   NULL,     '36x300',   'Roll',   38.50),
    ('WF-200-5424-GL', 'Epson Premium Gloss Photo 200gsm 54x24',       6, 'Epson',         NULL, 'Gloss',  '54in Roll','Roll',   189.00),
    ('WF-170-4424-MT', 'Canon Matte Coated 170gsm 44x24',              6, 'Canon',         NULL, 'Matte',  '44in Roll','Roll',   154.00),
    ('PKG-CST-2INCH',  'Carton Sealing Tape 2in x 110yd Clear',        7, 'LM Brand',      NULL, NULL,     '2x110yd',  'Case',   58.00),
    ('PKG-BW-1248',    'Bubble Wrap 12x48in Perforated Roll',          8, 'LM Brand',      NULL, NULL,     '12x48',    'Roll',   34.00),
    ('PKG-BOX-1086',   'Corrugated Box 10x8x6 RSC 32ECT',             9, 'LM Brand',      NULL, NULL,     '10x8x6',   'Bundle', 62.00),
    ('PKG-PLY-1218',   'Poly Bag 12x18 2mil Clear',                   10, 'LM Brand',      NULL, NULL,     '12x18',    'Case',   29.50),
    ('FAC-PAPER-TWL',  'C-Fold Paper Towels White 200ct',             11, 'Georgia-Pacific',NULL, NULL,     '200ct',    'Case',   47.00),
    ('FAC-COFFEE-MED', 'Medium Roast Coffee 12oz Bag',                12, 'Folgers',        NULL, NULL,     '12oz',     'Case',   89.00);

-- Inventory by warehouse
CREATE TABLE inventory (
    id           SERIAL PRIMARY KEY,
    product_id   INTEGER REFERENCES products(id),
    warehouse_id INTEGER REFERENCES warehouses(id),
    qty_on_hand  INTEGER NOT NULL DEFAULT 0,
    qty_on_order INTEGER NOT NULL DEFAULT 0,
    qty_reserved INTEGER NOT NULL DEFAULT 0,
    reorder_point INTEGER NOT NULL DEFAULT 10,
    last_updated TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (product_id, warehouse_id)
);

INSERT INTO inventory (product_id, warehouse_id, qty_on_hand, qty_on_order, qty_reserved, reorder_point) VALUES
    (1,  1, 142, 50,  12, 20), (1,  2, 88,  0,   8,  15),
    (1,  3, 34,  25,  4,  10), (1,  5, 21,  0,   2,  10),
    (2,  1, 76,  0,   6,  15), (2,  2, 43,  30,  3,  10),
    (3,  1, 98,  0,   9,  20), (3,  3, 55,  0,   5,  10),
    (4,  1, 61,  40,  7,  15), (4,  2, 29,  0,   2,  10),
    (5,  1, 210, 100, 18, 30), (5,  2, 134, 0,   11, 20),
    (5,  3, 87,  50,  8,  15), (5,  4, 62,  0,   5,  10),
    (5,  7, 74,  0,   6,  15), (6,  1, 155, 0,   14, 25),
    (6,  2, 91,  60,  9,  15), (7,  1, 180, 80,  16, 30),
    (7,  5, 44,  0,   4,  10), (8,  1, 67,  0,   5,  15),
    (8,  2, 38,  20,  3,  10), (9,  1, 52,  0,   6,  10),
    (10, 1, 41,  30,  4,  10), (11, 1, 93,  0,   8,  15),
    (11, 3, 47,  0,   4,  10), (12, 1, 38,  20,  3,  10),
    (13, 1, 320, 200, 28, 50), (13, 2, 215, 0,   19, 30),
    (13, 3, 178, 100, 16, 25), (13, 6, 142, 0,   12, 20),
    (14, 1, 88,  0,   8,  15), (15, 1, 24,  12,  3,  8),
    (15, 2, 18,  0,   2,  5),  (16, 1, 31,  20,  4,  8),
    (17, 1, 445, 200, 38, 60), (17, 3, 267, 0,   22, 40),
    (18, 1, 312, 0,   26, 50), (19, 1, 189, 100, 18, 30),
    (20, 1, 534, 300, 48, 80), (21, 1, 156, 0,   14, 25),
    (22, 1, 84,  48,  8,  20);

-- Departments
CREATE TABLE departments (
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    division TEXT NOT NULL
);

INSERT INTO departments (name, division) VALUES
    ('Sales',                    'Commercial'),
    ('Customer Service',         'Commercial'),
    ('Warehouse Operations',     'Operations'),
    ('Logistics & Transportation','Operations'),
    ('Inventory & Purchasing',   'Operations'),
    ('Credit & Collections',     'Finance'),
    ('Finance & Accounting',     'Finance'),
    ('Marketing',                'Commercial'),
    ('Human Resources',          'Corporate'),
    ('Information Technology',   'Corporate'),
    ('Wide Format Division',     'Commercial'),
    ('Packaging Division',       'Commercial'),
    ('Executive',                'Corporate');

-- Employees
CREATE TABLE employees (
    id            SERIAL PRIMARY KEY,
    employee_no   TEXT NOT NULL UNIQUE,
    first_name    TEXT NOT NULL,
    last_name     TEXT NOT NULL,
    email         TEXT NOT NULL UNIQUE,
    department_id INTEGER REFERENCES departments(id),
    warehouse_id  INTEGER REFERENCES warehouses(id),
    title         TEXT NOT NULL,
    salary        NUMERIC(10,2) NOT NULL,
    hired_at      DATE NOT NULL,
    active        BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO employees (employee_no, first_name, last_name, email, department_id, warehouse_id, title, salary, hired_at) VALUES
    ('E001', 'Bill',      'Meany',      'bmeany@lindenmeyr.com',     13, 2, 'President',                    285000, '2005-01-10'),
    ('E002', 'Sandra',    'Kowalski',   'skowalski@lindenmeyr.com',   1, 1, 'VP of Sales',                  195000, '2008-03-15'),
    ('E003', 'James',     'Holloway',   'jholloway@lindenmeyr.com',   1, 1, 'Regional Sales Manager',       142000, '2011-06-01'),
    ('E004', 'Patricia',  'Nguyen',     'pnguyen@lindenmeyr.com',     1, 1, 'Senior Account Executive',     112000, '2013-09-12'),
    ('E005', 'Marcus',    'DiSalvo',    'mdisalvo@lindenmeyr.com',    1, 2, 'Account Executive',             94000, '2016-02-20'),
    ('E006', 'Rachel',    'Torres',     'rtorres@lindenmeyr.com',     1, 3, 'Account Executive',             91000, '2017-05-08'),
    ('E007', 'Kevin',     'Park',       'kpark@lindenmeyr.com',       1, 5, 'Account Executive',             88000, '2018-11-14'),
    ('E008', 'Diana',     'Ostrowski',  'dostrowski@lindenmeyr.com',  2, 1, 'Customer Service Manager',      82000, '2014-07-22'),
    ('E009', 'Tom',       'Ferraro',    'tferraro@lindenmeyr.com',    2, 1, 'Customer Service Rep',          54000, '2019-03-05'),
    ('E010', 'Lisa',      'Chambers',   'lchambers@lindenmeyr.com',   2, 2, 'Customer Service Rep',          52000, '2020-08-17'),
    ('E011', 'Anthony',   'Ruiz',       'aruiz@lindenmeyr.com',       3, 1, 'Warehouse Manager',             78000, '2012-04-30'),
    ('E012', 'Denise',    'Washington', 'dwashington@lindenmeyr.com', 3, 1, 'Inventory Specialist',          58000, '2015-10-19'),
    ('E013', 'Carlos',    'Mendez',     'cmendez@lindenmeyr.com',     3, 1, 'Forklift Operator',             48000, '2018-06-25'),
    ('E014', 'Sharon',    'Patel',      'spatel@lindenmeyr.com',      5, 1, 'Purchasing Manager',            96000, '2010-02-14'),
    ('E015', 'Greg',      'Hofmann',    'ghofmann@lindenmeyr.com',    5, 1, 'Buyer',                         72000, '2016-09-07'),
    ('E016', 'Nancy',     'Cho',        'ncho@lindenmeyr.com',        6, 2, 'Credit Manager',                88000, '2013-11-03'),
    ('E017', 'Robert',    'Kleinman',   'rkleinman@lindenmeyr.com',   7, 2, 'Controller',                   145000, '2009-05-18'),
    ('E018', 'Amy',       'Fitzgerald', 'afitzgerald@lindenmeyr.com', 8, 2, 'Marketing Manager',             87000, '2015-03-22'),
    ('E019', 'David',     'Schwartz',   'dschwartz@lindenmeyr.com',  11, 1, 'Wide Format Sales Specialist',  92000, '2017-08-14'),
    ('E020', 'Michelle',  'Brennan',    'mbrennan@lindenmeyr.com',   12, 1, 'Packaging Sales Specialist',    89000, '2018-01-09');

-- Customers
CREATE TABLE customers (
    id              SERIAL PRIMARY KEY,
    account_no      TEXT NOT NULL UNIQUE,
    company_name    TEXT NOT NULL,
    contact_name    TEXT,
    email           TEXT,
    phone           TEXT,
    city            TEXT NOT NULL,
    state           TEXT NOT NULL,
    customer_type   TEXT NOT NULL,
    credit_limit    NUMERIC(12,2) NOT NULL DEFAULT 10000,
    credit_balance  NUMERIC(12,2) NOT NULL DEFAULT 0,
    on_credit_hold  BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_rep_id INTEGER REFERENCES employees(id),
    since_date      DATE NOT NULL
);

INSERT INTO customers (account_no, company_name, contact_name, email, phone, city, state, customer_type, credit_limit, credit_balance, on_credit_hold, assigned_rep_id, since_date) VALUES
    ('ACC-1001', 'Apex Print Group',           'Frank Deluca',    'fdeluca@apexprint.com',      '212-555-0101', 'New York',      'NY', 'Commercial Printer',  75000,  18420.50, FALSE, 4, '2015-03-10'),
    ('ACC-1002', 'Metro Packaging Solutions',  'Gail Thornton',   'gail@metropkg.com',           '201-555-0182', 'Newark',        'NJ', 'Packaging Customer',  50000,  9870.00,  FALSE, 4, '2017-07-22'),
    ('ACC-1003', 'Riverside Press',            'Howard Kim',      'hkim@riversidepress.com',     '617-555-0244', 'Boston',        'MA', 'Commercial Printer',  40000,  12300.75, FALSE, 5, '2016-11-05'),
    ('ACC-1004', 'BlueStar Digital Print',     'Irene Vasquez',   'ivasquez@bluestardigital.com','215-555-0316', 'Philadelphia',  'PA', 'Digital Print Shop',  30000,  6540.00,  FALSE, 6, '2018-02-14'),
    ('ACC-1005', 'Southeastern Paper Co.',     'Jack Monroe',     'jmonroe@sepaperco.com',       '404-555-0427', 'Atlanta',       'GA', 'Commercial Printer',  60000,  22100.00, FALSE, 7, '2014-08-30'),
    ('ACC-1006', 'Crown Publishing House',     'Karen Osei',      'karen@crownpublishing.com',   '212-555-0538', 'New York',      'NY', 'Publisher',          100000, 45000.00, FALSE, 4, '2012-01-15'),
    ('ACC-1007', 'TXTech Graphics',            'Larry Benson',    'lbenson@txtechgfx.com',       '214-555-0649', 'Dallas',        'TX', 'Commercial Printer',  25000,  8900.50,  FALSE, 7, '2019-06-11'),
    ('ACC-1008', 'Great Lakes Print',          'Maria Sorrento',  'msorrento@greatlakesprint.com','312-555-0751','Chicago',       'IL', 'Commercial Printer',  45000, 31200.00, TRUE,  5, '2016-04-27'),
    ('ACC-1009', 'Harbor Sign & Display',      'Neil Yamamoto',   'neil@harborsign.com',         '617-555-0862', 'Boston',        'MA', 'Wide Format Shop',    20000,  4200.00,  FALSE, 5, '2020-09-18'),
    ('ACC-1010', 'Sunshine Fulfillment LLC',   'Olivia Grant',    'ogrant@sunshineff.com',       '305-555-0973', 'Miami',         'FL', 'Fulfillment Center',  35000, 11650.75, FALSE, 7, '2018-12-03'),
    ('ACC-1011', 'Allied Office Supply',       'Peter Huang',     'phuang@alliedoffice.com',     '201-555-1084', 'Teterboro',     'NJ', 'Office Supply',       15000,  3200.00,  FALSE, 4, '2021-03-14'),
    ('ACC-1012', 'Northeast Book Printers',    'Quinn Walsh',     'qwalsh@nebookprint.com',      '617-555-1195', 'Boston',        'MA', 'Book Printer',        80000, 28900.00, FALSE, 5, '2013-05-20');

-- Orders
CREATE TABLE orders (
    id              SERIAL PRIMARY KEY,
    order_no        TEXT NOT NULL UNIQUE,
    customer_id     INTEGER REFERENCES customers(id),
    rep_id          INTEGER REFERENCES employees(id),
    warehouse_id    INTEGER REFERENCES warehouses(id),
    status          TEXT NOT NULL,
    ordered_at      TIMESTAMP NOT NULL,
    shipped_at      TIMESTAMP,
    po_number       TEXT,
    notes           TEXT
);

INSERT INTO orders (order_no, customer_id, rep_id, warehouse_id, status, ordered_at, shipped_at, po_number) VALUES
    ('ORD-24-10001', 1,  4, 1, 'Shipped',    '2024-10-01 09:14:00', '2024-10-02 14:30:00', 'PO-AP-8801'),
    ('ORD-24-10002', 3,  5, 2, 'Shipped',    '2024-10-02 10:22:00', '2024-10-03 11:15:00', 'PO-RP-4421'),
    ('ORD-24-10003', 6,  4, 1, 'Shipped',    '2024-10-03 08:45:00', '2024-10-04 09:00:00', 'PO-CP-9912'),
    ('ORD-24-10004', 8,  5, 2, 'On Hold',    '2024-10-04 11:30:00', NULL,                  'PO-GL-3301'),
    ('ORD-24-10005', 2,  4, 1, 'Processing', '2024-10-07 09:00:00', NULL,                  'PO-MP-5544'),
    ('ORD-24-10006', 5,  7, 5, 'Shipped',    '2024-10-07 10:15:00', '2024-10-08 13:45:00', 'PO-SE-7723'),
    ('ORD-24-10007', 9,  5, 2, 'Shipped',    '2024-10-08 14:00:00', '2024-10-09 10:30:00', 'PO-HS-1102'),
    ('ORD-24-10008', 12, 5, 2, 'Processing', '2024-10-09 08:30:00', NULL,                  'PO-NB-6634'),
    ('ORD-24-10009', 7,  7, 6, 'Shipped',    '2024-10-10 09:45:00', '2024-10-11 14:00:00', 'PO-TX-2287'),
    ('ORD-24-10010', 1,  4, 1, 'Processing', '2024-10-14 10:00:00', NULL,                  'PO-AP-8850'),
    ('ORD-24-10011', 6,  4, 1, 'Processing', '2024-10-14 11:20:00', NULL,                  'PO-CP-9955'),
    ('ORD-24-10012', 10, 7, 8, 'Shipped',    '2024-10-15 09:30:00', '2024-10-16 12:00:00', 'PO-SF-4410'),
    ('ORD-24-10013', 4,  6, 3, 'Processing', '2024-10-15 13:00:00', NULL,                  'PO-BS-3388'),
    ('ORD-24-10014', 11, 4, 1, 'Shipped',    '2024-10-16 08:00:00', '2024-10-17 10:15:00', 'PO-AO-9921'),
    ('ORD-24-10015', 3,  5, 2, 'Processing', '2024-10-16 14:30:00', NULL,                  'PO-RP-4499');

-- Order Line Items
CREATE TABLE order_lines (
    id           SERIAL PRIMARY KEY,
    order_id     INTEGER REFERENCES orders(id),
    product_id   INTEGER REFERENCES products(id),
    qty_ordered  INTEGER NOT NULL,
    qty_shipped  INTEGER NOT NULL DEFAULT 0,
    unit_price   NUMERIC(10,2) NOT NULL,
    line_total   NUMERIC(12,2) GENERATED ALWAYS AS (qty_ordered * unit_price) STORED
);

INSERT INTO order_lines (order_id, product_id, qty_ordered, qty_shipped, unit_price) VALUES
    (1,  1,  20, 20, 85.50),  (1,  5,  50, 50, 68.00),
    (2,  5,  30, 30, 68.00),  (2,  8,  15, 15, 93.00),
    (3,  4,  10, 10, 127.00), (3,  1,  25, 25, 85.50), (3, 13, 100, 100, 39.00),
    (4,  5,  40,  0, 68.00),  (4,  7,  60,  0, 58.00),
    (5,  17, 100,  0, 54.00), (5, 19,  50,  0, 59.00),
    (6,  5,  60, 60, 68.00),  (6,  6,  40, 40, 80.00),
    (7,  15,  8,  8, 179.00), (7, 16,  6,  6, 146.00),
    (8,  8,  20,  0, 93.00),  (8,  9,  10,  0, 112.00), (8, 10, 15, 0, 99.50),
    (9,  5,  25, 25, 68.00),  (9, 13,  80, 80, 39.00),
    (10, 2,  15,  0, 106.00), (10, 4,  10,  0, 127.00),
    (11, 1,  30,  0, 85.50),  (11, 3,  20,  0, 90.00),
    (12, 17, 200,  200, 54.00),(12, 20, 300, 300, 27.00),
    (13, 11, 10,   0, 61.50), (13, 12, 10,  0, 113.00),
    (14, 21, 20,  20, 44.50), (14, 22,  5,  5, 84.00),
    (15, 5,  50,   0, 68.00), (15, 6,  30,  0, 80.00);
