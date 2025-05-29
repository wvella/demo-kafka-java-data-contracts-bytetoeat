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
FROM `byte-to-eat`.`restaurant-kafka-cluster`.`raw.orders` o
JOIN `byte-to-eat`.`restaurant-kafka-cluster`.`raw.recipes` r
  ON o.recipe_id = r.recipe_id;
