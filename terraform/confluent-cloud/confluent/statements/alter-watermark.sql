-- The default watermark strategy, which is called source_watermark() will wait for 250 events per partition in a topic before calculating the watermark. In a low-volume use-case or exploration this means you simply won’t see data until you’ve pushed enough records into all of your input partitions.
-- A typical topic in Confluent Cloud with 6 partitions would need 1,500 events with evenly distributed keys (or no keys at all) to hit that number before seeing output. To be clear: if you don’t get all the partitions up to the 250 mark then the Compute Pool’s default configuration to align watermarks will ensure that even if all but one partition has more than 250 events in it, the watermark as a whole will not advance.
ALTER TABLE enriched_orders
MODIFY WATERMARK FOR $rowtime AS $rowtime
