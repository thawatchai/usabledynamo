usabledynamo
============


Installation
------------

Using bundler, in Gemfile:

```
gem 'usabledynamo', :git => 'http://github.com/thawatchai/usabledynamo.git'
```


Defining Model
--------------

The basic structure of a usabledynamo document is as follows (create in ```app/models```):

```
class UsableDynamoExample
  include UsableDynamo::Document

  string_attr 	:id, auto: true

  string_attr 	:username
  string_attr	  :email

  datetime_attr	:created_at
  datetime_attr :updated_at

  index [:username, :created_at]
  index [:email, :created_at]
end

```

Only ```:id field``` can have ```auto: true```, it's automatically assigned as the primary key and contains random generated string.


Table
-----

To create a new table, using the document model example above:
```
UsableDynamoExample.create_table(read_capacity_units = 4, write_capacity_units = 4)
```

To check whether a table exists:
```
UsableDynamoExample.table_exists?
```

To view the table definitions:
```
UsableDynamoExample.describe_table
```

To drop the table:
```
UsableDynamoExample.drop_table
```
or
```
UsableDynamoExample.delete_table
```

To update the provisioned_throughputs:
```
UsableDynamoExample.update_provisioned_throughputs(read_capacity_units = 4, write_capacity_units = 4, options = {})
```
If no options specified, the global_secondary_indexes' provisioned_throughputs will be set to be the same as the table.
Currently available options:
```
{
  global_secondary_indexes: {
    index_on_username_created_at: {
      read: 4,
      write: 4
    },
    index_on_email_created_at: {
      read: 4,
      write: 4
    }    
  }
}
```


Column & Data Types
-------------------

Currently available data types are:
```
string_attr
integer_attr
float_attr
boolean_attr
date_attr
datetime_attr
binary_attr
timestamps
```

```timestamps``` is a shortcut for:
```
datetime_attr :created_at
datetime_attr :updated_at
```

To show available column names:
```
UsableDynamoExample.column_names
```

To retrieve the column definition for a column name:
```
UsableDynamoExample.column_for(column_name)
```

To check whether a column exists:
```
UsableDynamoExample.column_exists?(column_name)
```


Index
-----

We only can define one hash and an optional range key for the index:
```
index [:username]
index [:email], name: index_custom_email
index [:username, :created_at], name: index_custom_name
index({ hash: email, range: created_at }, name: index_on_email)
```


Validations
-----------

Currently available validation methods are:
```
validates_presence_of
validates_uniqueness_of
validate :validation_method
```


Finding Records
---------------

Please note that dynamodb needs the complete index key(s) defined to perform the search using ```query``` method, otherwise it will use the much slower ```scan``` method. Only range key can use the range operators such as ```ge```, ```gt```, ```le```, ```lt```, ```between```, etc. Please refer to official dynamodb documentation for this.

To find a single record matching certain conditions:
```
UsableDynamoExample.find_by(username: "foo", "created_at.ge" => 0)
UsableDynamoExample.find_by(username: "foo", "created_at.between" => [DateTime.parse("2000-01-01"), DateTime.parse("2014-12-31")])
```

To find all records matching certain conditions (paginated, only the first batch retrieved):
```
UsableDynamoExample.find_all_by(username: "foo", "created_at.ge" => 0)
UsableDynamoExample.find_all_by(username: "foo", "created_at.between" => [DateTime.parse("2000-01-01"), DateTime.parse("2014-12-31")])
```

To find all records (paginated, only the first batch retrieved):
```
UsableDynamoExample.all
```

To find all records matching certain conditions and process each of them with code block (this will automatically read the next batch until none available):
```
UsableDynamoExample.find_each(username: "foo", "created_at.ge" => 0) do |record|
  puts record.inspect
end
```

To verify that a record with certain conditions is available:
```
UsableDynamoExample.exists?(username: "foo", "created_at.ge" => 0)
```

To count number of records matching certain conditions:
```
UsableDynamoExample.count(username: "foo", "created_at.ge" => 0)
```

To find a record or initialize a new one if none available:
```
UsableDynamoExample.find_or_initialize_by(username: "foo", "created_at" => DateTime.parse("2000-1-1"))
```

To find a record or create a new one if none available:
```
UsableDynamoExample.find_or_create_by(username: "foo", "created_at" => DateTime.parse("2000-1-1"))

```
