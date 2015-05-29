# Simple Stats Store

## Introduction

The purpose of Simple Stats Store is to provide a simple and lightweight method
for multiple processes to dump data into an SQLite database without contention.

It is appropriate to be used when:

* There are multiple threads or processes submitting statistics
* Data concurrency is less important than avoiding waiting on database locks

This is achieved by the threads dropping uniquely named files into a common
directory containing the statistics which are then picked up by a single thread
that is the sole accessor of the database.

## Usage

### General

Create the repository for temporary data files:

```ruby
require 'simple_stats_store/file_dump'

dir = '/path/to/temporary/data/directory'
Dir.mkdir(dir)
data_dump = SimpleStatsStore::FileDump.new(dir)
```

### Server

Set up the database:

```ruby
require 'simple_stats_store/server'
require 'active_record'

db_file = '/path/to/database.sql'
ActiveRecord::Base.establish_connection(
  adapter: :sqlite3,
  database: db_file,
  timeout: 200
)
ActiveRecord::Schema.define do
  create_table :table do |table|
    table.column :timestamp, :string
    table.column :key_1, :integer
    table.column :key_2, :float
    # etc.
  end
end
class Table < ActiveRecord::Base
end

ssss = SimpleStatsStore::Server.new(
  data_dump: data_dump,
  models: { table_ref: Table },
  name: 'process_name'                # Optional
)

t_next = Time.new + 300
server_pid = ssss.run do
  if Time.new >= t_next
    # Code to be executed every 5 minutes
    # ...
    t_next += 300
  end
end
```

### Client

Write data

```ruby
data_dump.write(
  table_ref,
  {
    timestamp: Time.new.to_s,
    key_1: value_1,
    key_2: value_2,
    # etc.
  }
)
```

## License

Simple Stats Store is available to everyone under the terms of the MIT open source licence. Take a look at the LICENSE file in the code.

Copyright (c) 2015 BBC
