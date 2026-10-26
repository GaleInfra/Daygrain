CREATE TABLE IF NOT EXISTS query_business_state (
  product_id TEXT NOT NULL,
  installation TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('activity', 'success', 'failure')),
  used INTEGER NOT NULL,
  resets_at TEXT NOT NULL,
  is_test INTEGER NOT NULL CHECK (is_test IN (0, 1)),
  control_revision TEXT NOT NULL,
  delay_ms INTEGER NOT NULL DEFAULT 0 CHECK (delay_ms BETWEEN 0 AND 30000),
  PRIMARY KEY (product_id, installation),
  CHECK (is_test = 1 OR delay_ms = 0)
);
CREATE TABLE IF NOT EXISTS query_rate (
  product_id TEXT NOT NULL,
  installation TEXT NOT NULL,
  minute INTEGER NOT NULL,
  count INTEGER NOT NULL,
  PRIMARY KEY (product_id, installation)
);
