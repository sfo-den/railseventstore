### Unreleased

* Fix: Updating messages via `RubyEventStore::Client#overwrite` with ROM repository no longer changes `created_at` column in the database.

  Given that `created_at` is now a source of a timestamp, you should consider overwriting timestamps from serialized metadata into `created_at` column if you have used `event_store.overwrite` in the past with ROM repository. If your serializer was YAML, this could be used to extract the timestamp in MySQL:

  ```
  SELECT STR_TO_DATE(SUBSTR(metadata, LOCATE(':timestamp: ', metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f') FROM event_store_events;
  ```


* Fix: Timestamps changed to local time as Sequel expects. Those were previously put as UTC, which then was interpreted as a local time. Affects historical data. Mostly harmless if you acknowledge uniform time skew before certain point in time.

  If that drift is problematic to you, consider migrating the timestamp from `metadata` to `created_at`. If your serializer was YAML, this could be used to extract the timestamp in MySQL:

  ```
  SELECT STR_TO_DATE(SUBSTR(metadata, LOCATE(':timestamp: ', metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f') FROM event_store_events;
  ```


* Change: Increase timestamp precision on MySQL and SQLite. Adds fractional time component [#674]

  ⚠️ **This requires migrating your database**.

  You can skip it to maintain current timestamp precision (up to seconds). No sample ROM migration provided.

  Related: https://blog.arkency.com/how-to-migrate-large-database-tables-without-a-headache/


* Change: Store timestamp only in a dedicated, indexed column making it independent of serializer. [#729, #627, #674]

  This means timestamp is no longer present in serialized metadata within database table. Timestamp is still present in event object     metadata.

  This also means that historical data takes `created_at` column as a source of a timestamp. This can introduce a sub-second drift in timestamps.

  If that drift is problematic to you, consider migrating the timestamp from `metadata` to `created_at`. If your serializer was YAML, this could be used to extract the timestamp in MySQL:

  ```
  SELECT STR_TO_DATE(SUBSTR(metadata, LOCATE(':timestamp: ', metadata) + 12, 31), '%Y-%m-%d %H:%i:%s.%f') FROM event_store_events;
  ```


* Add: Support for Bi-Temporal Event Sourcing. [#765]

  ⚠️ **This requires migrating your database and it is not optional**.

  No sample ROM migration provided.


* Performance: Optimize storage of global stream. Cut by half the number of rows needed  in `event_store_events_in_streams`. One insert statement less for non-named stream appends. [#514, #673]

  ⚠️ **This requires migrating your database and it is not optional**.

  No sample ROM migration provided.


### 1.3.0

Changes up-to version 1.3.0 can be tracked at [releases page](https://github.com/RailsEventStore/rails_event_store/releases).

### 0.1.0 (03.04.2018)

* Implemented ROM SQL adapter
* Add `rom-sql` 2.4.0 dependency
* Add `rom-repository` 2.0.2 dependency
* Add `rom-changeset` 1.0.2 dependency
* Add `sequel` 4.49 dependency
