INSERT INTO enriched_orders
SELECT
  CAST(o.order_id AS VARBINARY),
  o.order_id,
  r.recipe_id,
  o.customer_name,
  o.customer_address,
  o.status,
  r.ingredients,
  r.steps
FROM `raw.orders` o
JOIN `raw.recipes` r
  ON o.recipe_id = r.recipe_id;
