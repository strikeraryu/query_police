# QueryPolice

It is a rule-based engine with custom rules to Analyze Active-Record relations using explain results to detect bad queries.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add query_police

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install query_police

---

## Get started

### Basic Usage

Use `QueryPolice.analyse` to generate an analysis object for your Active-Record relation or query and then you can use pretty print on the object.

```
analysis = QueryPolice.analyse(<active_record_relation>)
puts analysis.pretty_analysis_for(<impact>)
```

**Eg.** 
```
analysis = QueryPolice.analyse(
  User.joins('join sessions on sessions.user_email = users.email ')
  .where('sessions.created_at < ?', Time.now - 5.months).order('sessions.created_at')
)
puts analysis.pretty_analysis_for('negative')
# or
puts analysis.pretty_analysis({'negative' => true, 'positive' => true})
```
**Results**

```
table: sessions
column: type
impact: negative
message: Entire sessions table is scanned to find matching rows, you have 1 possible keys to use.
suggestion: Use index here. You can use index from possible key: ["index_sessions_on_user_email"] or add new one to sessions table as per the requirements.
column: key
impact: negative
message: There is no index key used for sessions table, and can result into full scan of the sessions table
suggestion: Please use index from possible_keys: ["index_sessions_on_user_email"] or add new one to sessions table as per the requirements.
column: rows
impact: negative
message: 2982924 rows are being scanned per join for sessions table.
suggestion: Please see if it is possible to use index from ["index_sessions_on_user_email"] or add new one to sessions table as per the requirements to reduce the number of rows scanned.
```

### Add logger for every query

Add `QueryPolice.subscribe_logger` to your initial load file like `application.rb`

You can make logger silence of error using `QueryPolice.subscribe_logger silent: true`.

You can change logger config using `QueryPolice logger_config: <config>`, default logger_config `{'negative' => true}`, options `positive: <Boolean>, caution: <Boolean>`.



## How it works?

1. Query police converts the relation into sql query

2. Query police generates execution plan using EXPLAIN and EXPLAIN format=JSON based on the configuration.

3. Query police load rules from the config file.

4. Query police apply rules on the execution plan and generate a new analysis object.

5. Analysis object provide different methods to print the analysis in more descriptive format.


## Execution plan

We have 2 possible execution plan:-

Normal - using `EXPLAIN`

Detailed - using `EXPLAIN format=JSON`

**NOTE:** By default Detailed execution plan is added in the final execution plan, you can remove that by `QueryPolice.detailed=false`

### Normal execution plan

Generated using `EXPAIN <query>`

**Result**

| id | select_type | table   | partitions | type.  | possible_keys             | key                 | key_len | ref                         | rows | filtered | Extra                    |
|----|-------------|---------|------------|--------|---------------------------|---------------------|---------|-----------------------------|------|----------|--------------------------|
|  1 | SIMPLE      | profile | NULL.      | index  | fk_rails_249a7ebca1       | fk_rails_249a7ebca1 | 5       | NULL                        |  603 |  100.00  | Using where; Using index |
|  1 | SIMPLE      | users   | NULL       | eq_ref | PRIMARY,index_users_on_id | PRIMARY             | 4       | development.profile.user_id |1     |  100.00  | NULL                     |


Result for this is added as it is in the final execution plan

**Eg.**

```
{
    "profile" => {
                   "id" => 1,
          "select_type" => "SIMPLE",
                "table" => "profile",
           "partitions" => nil,
                 "type" => "index",
        "possible_keys" => "fk_rails_249a7ebca1",
                  "key" => "fk_rails_249a7ebca1",
              "key_len" => "5",
                  "ref" => nil,
                 "rows" => 603,
             "filtered" => 100.0,
                "Extra" => "Using where; Using index"
    },
                  "users" => {
                   "id" => 1,
          "select_type" => "SIMPLE",
                "table" => "users",
           "partitions" => nil,
                 "type" => "eq_ref",
        "possible_keys" => "PRIMARY,index_users_on_id",
                  "key" => "PRIMARY",
              "key_len" => "4",
                  "ref" => "development.profile.user_id",
                 "rows" => 1,
             "filtered" => 100.0,
                "Extra" => nil
    }
}
```

### Detailed execution plan

Generated using `EXPAIN format=JSON <query>`

**Truncated Result**

```
{
  "query_block": {
    "select_id": 1,
    "cost_info": {
      "query_cost": "850.20"
    },
    "nested_loop": [
      {
        "table": {
          "table_name": "profile",
          "access_type": "index",
          "key_length": "5",
          "cost_info": {
            "read_cost": "6.00",
            "eval_cost": "120.60",
            "prefix_cost": "126.60",
            "data_read_per_join": "183K"
          },
          "used_columns": [
            "user_id"
          ],
          "attached_condition": "(`development`.`profile`.`user_id` is not null)"
        }
      }
    ]
  }
}
```


Result for this is added in flatten form to final execution plan, where `detailed#` prefix is added before each key.

**Truncated Eg.**

```
{
    "detailed#key_length" => "5",
    "detailed#rows_examined_per_scan" => 603,
    "detailed#rows_produced_per_join" => 603,
    "detailed#filtered" => "100.00",
    "detailed#using_index" => true,
    "detailed#cost_info#read_cost" => "6.00",
    "detailed#cost_info#eval_cost" => "120.60",
    "detailed#cost_info#prefix_cost" => "126.60",
    "detailed#cost_info#data_read_per_join" => "183K",
    "detailed#used_columns" => ["user_id"]
...
```



##### Flatten

`{a: {b: 1}, c: 2}` is converted into `{a#b: 1, c: 2}`.


## Analysis object

Analysis object stores a detailed analysis report of a relation inside `:tables :table_count :summary attributes`.

#### Attributes

**table_count [Integer]  - No. Tables used in the relation**

**tables [Hash] - detailed table analysis**

```
{
  'users' => {                        
    'id'=>1,                    
    'name'=>'users',                 # table alias user in the execution plan
    'analysis'=>{
      'type'=>{                      # attribute name
        'value' => <string>,         # raw value of attribute in execution plan
        'tags' => {
          'all' => {                 # tag based on the value of a attribute
            'impact'=> <string>,     # negative, positive, cautions
            'warning'=> <string>,    # Eg. 'warning to represent the issue'
            'suggestions'=> <string> # Eg. 'some follow up suggestions'
          }
        }
      }
    }
  }
}
```
**summary [Hash] - hash of analysis summary**

```
{
  'cardinality'=>{
    'amount'=>10,
    'warning'=>'warning to represent the issue',
    'suggestions'=>'some follow up suggestions'
  }
}
```



## How to define rules?

Rules defined in the json file at config_path is applied to the execution plan. We have variety of option to define rules.

You can change this by `QueryPolice.rules_path=<path>` and define your own rules

### Rule Structure

A basic rule structure - 
```
"<column_name>": { 
  "description": <string>,
  "value_type": <string>,
  "delimiter": <string>, 
  "rules": {
    "<rule>": {
      "amount": <integer>
      "impact": <string>,
      "message": <string>,
      "suggestion": <string> 
    }
  }
}
```
- `<column_name>` - attribute name in the final execution plan.

- `description` - description of the attribute

- `value_type` - value type of the attribute

- `delimiter` - delimiter to parse array type attribute values, if no delimiter is passed engine will consider value is already in array form.

- `<rule>` - kind of rule for the attribute

    - `<tag>` - direct value match eg. ALL, SIMPLE

    - `absent` - when value is missing

    - `threshold` - a greater than threshold check based on the amount set inside the rule.

- `amount` - amount of threshold need to check for 

    - length for string

    - value for number

    - size for array

- `impact` - impact for the rule

    - `negative`

    - `postive`

    - `caution`

- `message` - message need to provide the significance of the rule

- `suggestion` - suggestion on how we can fix the issue



### Dynamic messages and suggestion

We can define dynamic messages and suggestion with variables provided by the engine.

- `$amount` - amount of the value 

    - length for string

    - value for number

    - size for array

- `$column` - attribute name

- `$impact` - impact for the rule

- `$table` - table alias used in the plan

- `$tag` - tag for which rule is applied 

- `$value` - original parsed value

- `$<column_name>` - value of that specific column in that table

- `$amount_<column_name>` - amount of that specific column



### Rules Examples

#### Basic rule example 

```
"type": {
  "description": "Join used in the query for a specific table.",
  "value_type": "string",
  "rules": {
    "system": {
      "impact": "positive",
      "message": "Table has zero or one row, no change required.",
      "suggestion": "" 
    },
    "ALL": {
      "impact": "negative",
      "message": "Entire $table table is scanned to find matching rows, you have $amount_possible_keys possible keys to use.",
      "suggestion": "Use index here. You can use index from possible key: $possible_keys or add new one to $table table as per the requirements."
    }
}
```
For above rule dynamic message will be generated as-
```
Entire users table is scanned to find matching rows, you have 1 possible keys to use
```
For above rule dynamic suggestion will be generated as-
```
Use index here. You can use index from possible key: ["PRIMARY", "user_email"] or add new one to users table as per the requirements.
```


#### Absent rule example

```
"key": {
  "description": "index key used for the table",
  "value_type": "string",
  "rules": {
    "absent": {
      "impact": "negative",
      "message": "There is no index key used for $table table, and can result into full scan of the $table table",
      "suggestion": "Please use index from possible_keys: $possible_keys or add new one to $table table as per the requirements." 
    }
  }
}
```

For above rule dynamic message will be generated as-
```
There is no index key used for users table, and can result into full scan of the users table
```
For above rule dynamic suggestion will be generated as-
```
Please use index from possible_keys: ["PRIMARY", "user_email"] or add new one to users table as per the requirements.
```


#### Threshold rule example

```
"possible_keys": {
  "description": "Index keys possible for a specifc table",
  "value_type": "array",
  "delimiter": ",",
  "rules": {
    "threshold": {
      "amount": 5,
      "impact": "negative",
      "message": "There are $amount possible keys for $table table, having too many index keys can be unoptimal",
      "suggestion": "Please check if there are extra indexes in $table table." 
    }
  }
}
```
For above rule dynamic message will be generated as-
```
There are 10 possible keys for users table, having too many index keys can be unoptimal
```
For above rule dynamic suggestion will be generated as-
```
Please check if there are extra indexes in users table.
```


#### Complex Detailed rule example

```
"detailed#used_columns": {
  "description": "",
  "value_type": "array",
  "rules": {
    "threshold": {
      "amount": 7,
      "impact": "negative",
      "message": "You have selected $amount columns, You should not select too many columns.",
      "suggestion": "Please only select required columns." 
    }
  }
}
```
For above rule dynamic message will be generated as-
```
You have selected 10 columns, You should not select too many columns.
```
For above rule dynamic suggestion will be generated as-
```
Please only select required columns.
```


### Summary

You can define similar rules for summary. Current summary attribute supported - 

- `cardinality` - cardinality based on the all tables

**NOTE:** You can add custom summary attributes by defining how to calculate them in `QueryPolice.add_summary` for a attribute key.



### Attributes

There all lot of attributes for you to use based on the final execution plan. 

You can use normal execution plan attribute directly.
Eg. `select_type, type, Extra, possible_keys`

To check more keys you can use `EXPLAIN <query>`

You can use detailed execution plan attribute can be used in flatten form with `detailed#` prefix.
Eg. `detailed#used_columns, detailed#cost_info#read_cost`

To check more keys you can use `EXPLAIN format=JSON <query>`

---

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/query_police. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/query_police/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the QueryPolice project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/query_police/blob/master/CODE_OF_CONDUCT.md).
