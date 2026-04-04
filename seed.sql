-- ============================================================
-- Lindenmeyer Munroe AI Agent — Database Schema & Seed Data
-- ============================================================
-- ERP-ready: add ERP tables later and they are auto-discovered
-- by the schema introspection in main.py.

-- ============================================================
-- SCHEMA
-- ============================================================

CREATE TABLE IF NOT EXISTS warehouses (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    state        CHAR(2)      NOT NULL,
    zip_code     VARCHAR(10),
    phone        VARCHAR(20),
    is_active    BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS product_categories (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS products (
    id                SERIAL PRIMARY KEY,
    sku               VARCHAR(50)    UNIQUE NOT NULL,
    name              VARCHAR(200)   NOT NULL,
    category_id       INTEGER        REFERENCES product_categories(id),
    brand             VARCHAR(100),
    size_width        NUMERIC(6,2),   -- inches
    size_height       NUMERIC(6,2),   -- inches
    weight_lb         INTEGER,        -- basis weight (e.g. 20, 24, 60, 80)
    finish            VARCHAR(50),    -- uncoated, gloss, matte, silk, bond
    color             VARCHAR(50)     DEFAULT 'White',
    sheets_per_carton INTEGER,
    carton_weight_lb  NUMERIC(6,2),
    is_active         BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS pricing (
    id               SERIAL PRIMARY KEY,
    product_id       INTEGER        NOT NULL REFERENCES products(id),
    price_tier       VARCHAR(20)    NOT NULL, -- list, distributor, preferred, contract
    price_per_carton NUMERIC(10,2)  NOT NULL,
    price_per_sheet  NUMERIC(10,4),
    effective_date   DATE           NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS inventory (
    id               SERIAL PRIMARY KEY,
    product_id       INTEGER   NOT NULL REFERENCES products(id),
    warehouse_id     INTEGER   NOT NULL REFERENCES warehouses(id),
    quantity_cartons INTEGER   NOT NULL DEFAULT 0,
    reorder_point    INTEGER   NOT NULL DEFAULT 10,
    last_updated     TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (product_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS customers (
    id              SERIAL PRIMARY KEY,
    company_name    VARCHAR(200) NOT NULL,
    account_number  VARCHAR(20)  UNIQUE NOT NULL,
    city            VARCHAR(100),
    state           CHAR(2),
    pricing_tier    VARCHAR(20)  DEFAULT 'list',
    sales_rep       VARCHAR(100),
    is_active       BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS orders (
    id             SERIAL PRIMARY KEY,
    order_number   VARCHAR(20)    UNIQUE NOT NULL,
    customer_id    INTEGER        NOT NULL REFERENCES customers(id),
    warehouse_id   INTEGER        NOT NULL REFERENCES warehouses(id),
    order_date     DATE           NOT NULL,
    ship_date      DATE,
    status         VARCHAR(20)    NOT NULL DEFAULT 'pending',
    total_amount   NUMERIC(12,2)  NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS order_items (
    id               SERIAL PRIMARY KEY,
    order_id         INTEGER       NOT NULL REFERENCES orders(id),
    product_id       INTEGER       NOT NULL REFERENCES products(id),
    quantity_cartons INTEGER       NOT NULL,
    unit_price       NUMERIC(10,2) NOT NULL,
    line_total       NUMERIC(12,2) NOT NULL
);

-- ============================================================
-- WAREHOUSES (5 locations)
-- ============================================================
INSERT INTO warehouses (name, city, state, zip_code, phone) VALUES
    ('Boston Distribution Center',      'Boston',      'MA', '02101', '617-555-0100'),
    ('New York Metro Warehouse',         'Secaucus',    'NJ', '07094', '201-555-0200'),
    ('Chicago Midwest Hub',              'Chicago',     'IL', '60601', '312-555-0300'),
    ('Atlanta Southeast Facility',       'Atlanta',     'GA', '30301', '404-555-0400'),
    ('Los Angeles Pacific Distribution', 'Los Angeles', 'CA', '90001', '213-555-0500');

-- ============================================================
-- PRODUCT CATEGORIES
-- ============================================================
INSERT INTO product_categories (name, description) VALUES
    ('Bond & Writing',   'Premium writing and letterhead papers, typically uncoated'),
    ('Copy & Multipurpose', 'Everyday copy and multipurpose papers for office use'),
    ('Text & Cover',     'Premium printing papers for books, brochures, and covers'),
    ('Digital',          'Papers optimized for digital presses and laser/inkjet'),
    ('Wide Format',      'Large-format rolls and sheets for CAD, banners, and signage'),
    ('Packaging',        'Kraft, chipboard, and specialty packaging materials');

-- ============================================================
-- PRODUCTS (~50 realistic SKUs)
-- ============================================================
-- Bond & Writing
INSERT INTO products (sku, name, category_id, brand, size_width, size_height, weight_lb, finish, color, sheets_per_carton, carton_weight_lb) VALUES
    ('BND-8511-20W',  'Hammermill Bond 8.5x11 20lb White',          1, 'Hammermill',  8.5,  11.0,  20, 'uncoated', 'White', 5000, 50.0),
    ('BND-8511-24W',  'Hammermill Bond 8.5x11 24lb White',          1, 'Hammermill',  8.5,  11.0,  24, 'uncoated', 'White', 5000, 60.0),
    ('BND-8514-20W',  'Hammermill Bond 8.5x14 20lb White',          1, 'Hammermill',  8.5,  14.0,  20, 'uncoated', 'White', 5000, 55.0),
    ('BND-1117-24W',  'Hammermill Bond 11x17 24lb White',           1, 'Hammermill', 11.0,  17.0,  24, 'uncoated', 'White', 2500, 60.0),
    ('BND-8511-24CR', 'Domtar Lettermark 8.5x11 24lb Cream',        1, 'Domtar',      8.5,  11.0,  24, 'uncoated', 'Cream', 5000, 60.0),
    ('BND-8511-24GY', 'Domtar Lettermark 8.5x11 24lb Gray',         1, 'Domtar',      8.5,  11.0,  24, 'uncoated', 'Gray',  5000, 60.0);

-- Copy & Multipurpose
INSERT INTO products (sku, name, category_id, brand, size_width, size_height, weight_lb, finish, color, sheets_per_carton, carton_weight_lb) VALUES
    ('CPY-8511-20W',  'Hammermill Copy Plus 8.5x11 20lb White',     2, 'Hammermill',  8.5,  11.0,  20, 'uncoated', 'White', 5000, 50.0),
    ('CPY-8511-20C',  'HP Office 8.5x11 20lb White',                2, 'HP',          8.5,  11.0,  20, 'uncoated', 'White', 5000, 50.0),
    ('CPY-8514-20W',  'Hammermill Copy Plus 8.5x14 20lb White',     2, 'Hammermill',  8.5,  14.0,  20, 'uncoated', 'White', 5000, 55.0),
    ('CPY-1117-20W',  'Hammermill Copy Plus 11x17 20lb White',      2, 'Hammermill', 11.0,  17.0,  20, 'uncoated', 'White', 2500, 50.0),
    ('CPY-8511-20CL', 'Boise Aspen 30 8.5x11 20lb White 30% PCW',  2, 'Boise',       8.5,  11.0,  20, 'uncoated', 'White', 5000, 50.0),
    ('CPY-8511-24W',  'Xerox Business 4200 8.5x11 24lb White',      2, 'Xerox',       8.5,  11.0,  24, 'uncoated', 'White', 5000, 60.0);

-- Text & Cover
INSERT INTO products (sku, name, category_id, brand, size_width, size_height, weight_lb, finish, color, sheets_per_carton, carton_weight_lb) VALUES
    ('TXT-8511-60W',  'Sappi Somerset 8.5x11 60lb Text Gloss White',    3, 'Sappi',   8.5,  11.0,  60, 'gloss',   'White', 2500, 41.0),
    ('TXT-8511-70W',  'Sappi Somerset 8.5x11 70lb Text Gloss White',    3, 'Sappi',   8.5,  11.0,  70, 'gloss',   'White', 2500, 48.0),
    ('TXT-8511-80W',  'Sappi Somerset 8.5x11 80lb Text Gloss White',    3, 'Sappi',   8.5,  11.0,  80, 'gloss',   'White', 2500, 55.0),
    ('TXT-1218-60W',  'Sappi Somerset 12x18 60lb Text Gloss White',     3, 'Sappi',  12.0,  18.0,  60, 'gloss',   'White', 1000, 40.0),
    ('TXT-1218-80W',  'Sappi Somerset 12x18 80lb Text Gloss White',     3, 'Sappi',  12.0,  18.0,  80, 'gloss',   'White', 1000, 53.0),
    ('TXT-1218-100W', 'Sappi Somerset 12x18 100lb Text Gloss White',    3, 'Sappi',  12.0,  18.0, 100, 'gloss',   'White', 1000, 66.0),
    ('TXT-8511-80MT', 'Mohawk Via 8.5x11 80lb Text Matte White',        3, 'Mohawk',  8.5,  11.0,  80, 'matte',   'White', 2000, 53.0),
    ('TXT-1218-80MT', 'Mohawk Via 12x18 80lb Text Matte White',         3, 'Mohawk', 12.0,  18.0,  80, 'matte',   'White', 1000, 53.0),
    ('COV-8511-65W',  'Sappi McCoy 8.5x11 65lb Cover Gloss White',      3, 'Sappi',   8.5,  11.0,  65, 'gloss',   'White', 1000, 43.0),
    ('COV-8511-80W',  'Sappi McCoy 8.5x11 80lb Cover Gloss White',      3, 'Sappi',   8.5,  11.0,  80, 'gloss',   'White',  800, 53.0),
    ('COV-1218-65W',  'Sappi McCoy 12x18 65lb Cover Gloss White',       3, 'Sappi',  12.0,  18.0,  65, 'gloss',   'White',  500, 43.0),
    ('COV-1218-80W',  'Sappi McCoy 12x18 80lb Cover Gloss White',       3, 'Sappi',  12.0,  18.0,  80, 'gloss',   'White',  500, 53.0),
    ('COV-8511-65SL', 'Appvion Accent 8.5x11 65lb Cover Silk White',    3, 'Appvion', 8.5,  11.0,  65, 'silk',    'White', 1000, 43.0),
    ('TXT-8511-60UC', 'Mohawk Superfine 8.5x11 60lb Text Uncoated White',3,'Mohawk',  8.5,  11.0,  60, 'uncoated','White', 2500, 41.0),
    ('TXT-1218-60UC', 'Mohawk Superfine 12x18 60lb Text Uncoated White', 3,'Mohawk', 12.0,  18.0,  60, 'uncoated','White', 1000, 40.0);

-- Digital
INSERT INTO products (sku, name, category_id, brand, size_width, size_height, weight_lb, finish, color, sheets_per_carton, carton_weight_lb) VALUES
    ('DIG-8511-60W',  'Xerox Vitality 8.5x11 60lb Digital White',       4, 'Xerox',   8.5,  11.0,  60, 'gloss',   'White', 2500, 41.0),
    ('DIG-8511-80W',  'Xerox Vitality 8.5x11 80lb Digital White',       4, 'Xerox',   8.5,  11.0,  80, 'gloss',   'White', 2000, 55.0),
    ('DIG-1319-80W',  'Sappi Flo 13x19 80lb Digital Text Gloss White',  4, 'Sappi',  13.0,  19.0,  80, 'gloss',   'White',  750, 53.0),
    ('DIG-1319-100W', 'Sappi Flo 13x19 100lb Digital Text Gloss White', 4, 'Sappi',  13.0,  19.0, 100, 'gloss',   'White',  500, 66.0),
    ('DIG-1218-80W',  'HP Color Choice 12x18 80lb Digital Matte White', 4, 'HP',     12.0,  18.0,  80, 'matte',   'White', 1000, 53.0),
    ('DIG-8511-90W',  'Neenah Digital 8.5x11 90lb Text Uncoated White', 4, 'Neenah',  8.5,  11.0,  90, 'uncoated','White', 2000, 62.0);

-- Wide Format
INSERT INTO products (sku, name, category_id, brand, size_width, size_height, weight_lb, finish, color, sheets_per_carton, carton_weight_lb) VALUES
    ('WF-36-20W',   'HP Universal Bond 36" x 150ft Roll 20lb',          5, 'HP',     36.0, NULL,   20, 'uncoated', 'White', NULL, 8.0),
    ('WF-42-20W',   'HP Universal Bond 42" x 150ft Roll 20lb',          5, 'HP',     42.0, NULL,   20, 'uncoated', 'White', NULL, 10.0),
    ('WF-36-24W',   'Hammermill CAD 36" x 150ft Roll 24lb',             5, 'Hammermill',36.0,NULL, 24, 'uncoated', 'White', NULL, 10.0),
    ('WF-2436-80W', 'HP Premium Matte 24x36 80lb Presentation Sheets',  5, 'HP',     24.0,  36.0,  80, 'matte',    'White', 100,  18.0),
    ('WF-3648-80W', 'HP Premium Matte 36x48 80lb Presentation Sheets',  5, 'HP',     36.0,  48.0,  80, 'matte',    'White',  50,  20.0);

-- Packaging
INSERT INTO products (sku, name, category_id, brand, size_width, size_height, weight_lb, finish, color, sheets_per_carton, carton_weight_lb) VALUES
    ('PKG-8511-60KR', 'Georgia-Pacific Kraft 8.5x11 60lb Brown',        6, 'Georgia-Pacific', 8.5, 11.0, 60, 'uncoated', 'Brown', 2500, 53.0),
    ('PKG-1117-60KR', 'Georgia-Pacific Kraft 11x17 60lb Brown',         6, 'Georgia-Pacific',11.0, 17.0, 60, 'uncoated', 'Brown', 1000, 53.0),
    ('PKG-8511-80CB', 'Clearwater Chipboard 8.5x11 80pt Tan',           6, 'Clearwater',       8.5, 11.0, 80, 'uncoated', 'Tan',   500,  30.0),
    ('PKG-1218-80CB', 'Clearwater Chipboard 12x18 80pt Tan',            6, 'Clearwater',      12.0, 18.0, 80, 'uncoated', 'Tan',   250,  33.0);

-- ============================================================
-- PRICING (list, distributor, preferred tiers)
-- ============================================================
INSERT INTO pricing (product_id, price_tier, price_per_carton, price_per_sheet, effective_date)
SELECT p.id, tier.name,
       ROUND((base_price * tier.multiplier)::numeric, 2),
       ROUND((base_price * tier.multiplier / p.sheets_per_carton)::numeric, 6),
       '2024-01-01'
FROM products p
CROSS JOIN (
    VALUES ('list', 1.00), ('distributor', 0.88), ('preferred', 0.82)
) AS tier(name, multiplier)
CROSS JOIN LATERAL (
    SELECT
        CASE
            -- Copy/Bond: cheaper per carton
            WHEN p.category_id IN (1,2) AND p.weight_lb <= 20 THEN 48.00
            WHEN p.category_id IN (1,2) AND p.weight_lb = 24 THEN 58.00
            WHEN p.category_id IN (1,2) AND p.weight_lb > 24  THEN 68.00
            -- Text 60lb
            WHEN p.category_id = 3 AND p.weight_lb = 60 THEN 95.00
            WHEN p.category_id = 3 AND p.weight_lb = 65 THEN 105.00
            WHEN p.category_id = 3 AND p.weight_lb = 70 THEN 112.00
            WHEN p.category_id = 3 AND p.weight_lb = 80 THEN 130.00
            WHEN p.category_id = 3 AND p.weight_lb = 100 THEN 162.00
            -- Digital
            WHEN p.category_id = 4 AND p.weight_lb <= 80 THEN 138.00
            WHEN p.category_id = 4 AND p.weight_lb > 80  THEN 170.00
            -- Wide format (per roll/sheet pack)
            WHEN p.category_id = 5 AND p.size_height IS NULL THEN 42.00
            WHEN p.category_id = 5 THEN 85.00
            -- Packaging
            WHEN p.category_id = 6 THEN 72.00
            ELSE 80.00
        END AS base_price
) bp
WHERE p.sheets_per_carton IS NOT NULL;

-- Wide format rolls (no sheets_per_carton) — price per roll
INSERT INTO pricing (product_id, price_tier, price_per_carton, price_per_sheet, effective_date)
SELECT p.id, tier.name,
       ROUND((42.00 * tier.multiplier)::numeric, 2),
       NULL,
       '2024-01-01'
FROM products p
CROSS JOIN (VALUES ('list', 1.00), ('distributor', 0.88), ('preferred', 0.82)) AS tier(name, multiplier)
WHERE p.sheets_per_carton IS NULL;

-- ============================================================
-- INVENTORY (quantity_cartons per warehouse per product)
-- ============================================================
INSERT INTO inventory (product_id, warehouse_id, quantity_cartons, reorder_point)
SELECT
    p.id,
    w.id,
    -- Vary stock levels realistically by warehouse and product popularity
    GREATEST(0, (
        CASE
            WHEN p.category_id IN (1,2) THEN 80  -- high-volume copy/bond
            WHEN p.category_id = 3      THEN 40  -- text/cover
            WHEN p.category_id = 4      THEN 30  -- digital
            WHEN p.category_id = 5      THEN 15  -- wide format
            WHEN p.category_id = 6      THEN 25  -- packaging
            ELSE 20
        END
        -- New York and Boston carry more stock
        * CASE w.id WHEN 1 THEN 1.3 WHEN 2 THEN 1.5 ELSE 1.0 END
        -- Adjust by SKU popularity (mod to create variety)
        + ((p.id * 7 + w.id * 3) % 40) - 20
    )::int),
    CASE
        WHEN p.category_id IN (1,2) THEN 20
        WHEN p.category_id = 3      THEN 10
        ELSE 5
    END
FROM products p
CROSS JOIN warehouses w;

-- ============================================================
-- CUSTOMERS (20 anonymized B2B customers)
-- ============================================================
INSERT INTO customers (company_name, account_number, city, state, pricing_tier, sales_rep) VALUES
    ('Northeast Print Solutions',     'ACC-10001', 'Boston',       'MA', 'preferred',   'Sarah Chen'),
    ('Metro Graphics Group',          'ACC-10002', 'New York',     'NY', 'preferred',   'James Kowalski'),
    ('Windy City Paper Co.',          'ACC-10003', 'Chicago',      'IL', 'distributor', 'Maria Santos'),
    ('Peach State Printers',          'ACC-10004', 'Atlanta',      'GA', 'distributor', 'Robert Taylor'),
    ('Pacific Print Partners',        'ACC-10005', 'Los Angeles',  'CA', 'preferred',   'Linda Nguyen'),
    ('Harbor Copy Center',            'ACC-10006', 'Boston',       'MA', 'list',        'Sarah Chen'),
    ('Tri-State Office Supply',       'ACC-10007', 'Newark',       'NJ', 'distributor', 'James Kowalski'),
    ('Great Lakes Business Forms',    'ACC-10008', 'Cleveland',    'OH', 'list',        'Maria Santos'),
    ('Capitol Document Services',     'ACC-10009', 'Washington',   'DC', 'preferred',   'Robert Taylor'),
    ('Sunset Design Studio',          'ACC-10010', 'San Diego',    'CA', 'list',        'Linda Nguyen'),
    ('Bay Area Print Exchange',       'ACC-10011', 'San Francisco','CA', 'distributor', 'Linda Nguyen'),
    ('Rocky Mountain Paper',          'ACC-10012', 'Denver',       'CO', 'list',        'Maria Santos'),
    ('Gulf Coast Graphics',           'ACC-10013', 'Houston',      'TX', 'distributor', 'Robert Taylor'),
    ('Keystone Printing & Copy',      'ACC-10014', 'Philadelphia', 'PA', 'preferred',   'James Kowalski'),
    ('Emerald City Office Products',  'ACC-10015', 'Seattle',      'WA', 'list',        'Linda Nguyen'),
    ('Magnolia Press & Design',       'ACC-10016', 'Memphis',      'TN', 'list',        'Robert Taylor'),
    ('Heartland Paper Distributors',  'ACC-10017', 'Indianapolis', 'IN', 'distributor', 'Maria Santos'),
    ('Old Dominion Office Supply',    'ACC-10018', 'Richmond',     'VA', 'list',        'James Kowalski'),
    ('Desert Southwest Printing',     'ACC-10019', 'Phoenix',      'AZ', 'distributor', 'Linda Nguyen'),
    ('Twin Cities Paper & Print',     'ACC-10020', 'Minneapolis',  'MN', 'preferred',   'Maria Santos');

-- ============================================================
-- ORDERS (100 orders over past 12 months)
-- ============================================================
-- We'll generate orders with a mix of statuses
DO $$
DECLARE
    i        INT;
    cust_id  INT;
    wh_id    INT;
    o_date   DATE;
    s_date   DATE;
    status   VARCHAR(20);
    o_number VARCHAR(20);
    o_id     INT;
    p_id     INT;
    qty      INT;
    uprice   NUMERIC(10,2);
    ltotal   NUMERIC(12,2);
    ototal   NUMERIC(12,2);
    num_lines INT;
    j        INT;
BEGIN
    FOR i IN 1..100 LOOP
        cust_id  := (i % 20) + 1;
        wh_id    := (i % 5) + 1;
        o_date   := CURRENT_DATE - ((100 - i) * 3 + (i % 7));
        status   := CASE
                        WHEN i <= 5  THEN 'pending'
                        WHEN i <= 15 THEN 'processing'
                        WHEN i <= 20 THEN 'cancelled'
                        WHEN i <= 30 THEN 'shipped'
                        ELSE              'delivered'
                    END;
        s_date   := CASE WHEN status IN ('shipped','delivered') THEN o_date + 3 ELSE NULL END;
        o_number := 'LM-' || TO_CHAR(2024 + (i / 50), 'FM9999') || '-' || LPAD(i::text, 4, '0');
        ototal   := 0;

        INSERT INTO orders (order_number, customer_id, warehouse_id, order_date, ship_date, status, total_amount)
        VALUES (o_number, cust_id, wh_id, o_date, s_date, status, 0)
        RETURNING id INTO o_id;

        num_lines := (i % 4) + 1;
        FOR j IN 1..num_lines LOOP
            p_id := ((i * 7 + j * 13) % 50) + 1;
            qty  := ((i + j) % 5) + 1;

            SELECT price_per_carton INTO uprice
            FROM pricing pr
            JOIN customers c ON c.id = cust_id
            WHERE pr.product_id = p_id AND pr.price_tier = c.pricing_tier
            LIMIT 1;

            IF uprice IS NULL THEN
                SELECT price_per_carton INTO uprice
                FROM pricing WHERE product_id = p_id AND price_tier = 'list' LIMIT 1;
            END IF;

            IF uprice IS NOT NULL THEN
                ltotal := qty * uprice;
                ototal := ototal + ltotal;
                INSERT INTO order_items (order_id, product_id, quantity_cartons, unit_price, line_total)
                VALUES (o_id, p_id, qty, uprice, ltotal);
            END IF;
        END LOOP;

        UPDATE orders SET total_amount = ototal WHERE id = o_id;
    END LOOP;
END $$;
