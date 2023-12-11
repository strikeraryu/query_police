# QueryPolice

It is a rule-based engine with custom rules to Analyze Active-Record relations using explain results and detect bad queries.

## Installation

Install the gem and add it to the application's Gemfile by executing:

    $ gem 'query_police', '~> 0.1.7.beta'

If the bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install query_police --pre

---

## Get started

### Basic Usage

Use `QueryPolice.analyse` to generate an analysis object for your Active-Record relation or query and then you can use pretty print on the object.

```ruby
analysis = QueryPolice.analyse(<query>)
puts analysis.pretty_analysis
```

**Eg.** 
```ruby
analysis = QueryPolice.analyse(
  User.joins('join orders on orders.user_id = users.id') # analyse query using active record relation
)
# or
analysis = QueryPolice.analyse(
  "select * from users join orders on orders.user_id = users.id" # analyse query using query string
)

puts analysis.pretty_analysis
```
**Results**

**Note:** [Query debt significance](#significance)  


```
+------------------+-------------------------------+
| Total Query Debt | 330.0 (Potentially Bad Query) |
+------------------+-------------------------------+

+-------------------------------------------------------------------------------------------------------------------+
|                                                      orders                                                       |
+------------+------------------------------------------------------------------------------------------------------+
| Debt       | 200.0                                                                                                |
+------------+------------------------------------------------------------------------------------------------------+
| Column     | type                                                                                                 |
| Value      | ALL                                                                                                  |
| Impact     | negative                                                                                             |
| Tag Debt   | 100.0                                                                                                |
| Message    | The entire orders table is scanned to find matching rows. There are 0 possible keys that could be    |
|            | used                                                                                                 |
| Suggestion | Use an index in this scenario. You can use the index from possible key: absent or add a new index to |
|            | the orders table as needed                                                                           |
+------------+------------------------------------------------------------------------------------------------------+
| Column     | possible_keys                                                                                        |
| Value      | absent                                                                                               |
| Impact     | negative                                                                                             |
| Tag Debt   | 50.0                                                                                                 |
| Message    | There are no possible keys for the orders table, which can lead to a full scan                       |
| Suggestion | Add appropriate index keys for the orders table                                                      |
+------------+------------------------------------------------------------------------------------------------------+
| Column     | key                                                                                                  |
| Value      | absent                                                                                               |
| Impact     | negative                                                                                             |
| Tag Debt   | 50.0                                                                                                 |
| Message    | No index key is being used for the orders table, which may result in a full table scan               |
| Suggestion | Use an index from possible_keys: absent or add a new one to the orders table as required             |
+------------+------------------------------------------------------------------------------------------------------+
+--------------------------------------------------------------------------------------------------+
|                                              users                                               |
+------------+-------------------------------------------------------------------------------------+
| Debt       | 130.0                                                                               |
+------------+-------------------------------------------------------------------------------------+
| Column     | detailed#used_columns                                                               |
| Value      | ["id", "name", "username", "phone_number", "dob", "email", "encrypted_password",... |
| Impact     | negative                                                                            |
| Tag Debt   | 130.0                                                                               |
| Message    | You have selected 18 columns, which could be excessive                              |
| Suggestion | Please only select the required columns                                             |
+------------+-------------------------------------------------------------------------------------+
```

###  Analysis for a Impact 

To print pretty analysis for different impacts
```ruby
analysis = QueryPolice.analyse("select * from users")
puts analysis.pretty_analysis_for('positive') # impact negative, positive, caution

# puts
# +------------------+-------------------------------+
# | Total Query Debt | 330.0 (Potentially Bad Query) |
# +------------------+-------------------------------+
# 
# +------------------------------------------------------------------------+
# |                                 users                                  |
# +----------+-------------------------------------------------------------+
# | Debt     | 330.0                                                       |
# +----------+-------------------------------------------------------------+
# | Column   | select_type                                                 |
# | Value    | SIMPLE                                                      |
# | Impact   | positive                                                    |
# | Tag Debt | 0                                                           |
# | Message  | This query is a simple one without any subqueries or unions |
# +----------+-------------------------------------------------------------+
```

### Analysis for Multiple Impacts

To print pretty analysis for multiple impacts, default: `{ 'negative' => true, 'caution' => true }`
```ruby
analysis = QueryPolice.analyse("select * from users")
puts analysis.pretty_analysis({'negative' => true, 'positive' => true})
```

### Query debt

To get the final debt of the query
```ruby
analysis = QueryPolice.analyse("select * from users")
puts analysis.query_debt

# puts
# 100.0
```

#### Significance
Query debt signifies the quality of the query, high value represents a bad query. 
- `0 - 199` - Good Query
- `200 - 499` - Potentially Bad query
- `>=500` - Bad query

### Word wrap

To change the word wrap width for the pretty analysis result, default value: `100`
```ruby
analysis = QueryPolice.analyse("select * from users")
puts analysis.pretty_analysis_for('positive', {'wrap_width' => 40})
# or
puts analysis.pretty_analysis({'positive' => true, 'wrap_width' => 40})

# puts
# +------------------+-------------------------------+
# | Total Query Debt | 330.0 (Potentially Bad Query) |
# +------------------+-------------------------------+
# 
# +---------------------------------------------------+
# |                       users                       |
# +----------+----------------------------------------+
# | Debt     | 330.0                                  |
# +----------+----------------------------------------+
# | Column   | select_type                            |
# | Value    | SIMPLE                                 |
# | Impact   | positive                               |
# | Tag Debt | 0                                      |
# | Message  | This query is a simple one without any |
# |          | subqueries or unions                   |
# +----------+----------------------------------------+

puts analysis.pretty_analysis_for('positive', {'wrap_width' => 20})
# or
puts analysis.pretty_analysis({'positive' => true, 'wrap_width' => 20})

# puts
# +------------------+-------------------------------+
# | Total Query Debt | 330.0 (Potentially Bad Query) |
# +------------------+-------------------------------+
#
# +-------------------------------+
# |             users             |
# +----------+--------------------+
# | Debt     | 330.0              |
# +----------+--------------------+
# | Column   | select_type        |
# | Value    | SIMPLE             |
# | Impact   | positive           |
# | Tag Debt | 0                  |
# | Message  | This query is a    |
# |          | simple one without |
# |          | any subqueries or  |
# |          | unions             |
# +----------+--------------------+
```

### Skip footer

To skip the footer (added in [query police config](#analysis-footer)) after an analysis of a query
```ruby
analysis = QueryPolice.analyse("select * from users")
puts analysis.pretty_analysis_for('positive', {'skip_footer' => true})
# or
puts analysis.pretty_analysis({'positive' => true, 'skip_footer' => true})
```
### Analysis Debt Ranges
To define ranges of debt for categorization of query. 
Default Ranges:
- `0 - 199` - Good Query
- `200 - 499` - Potentially Bad query
- `>=500` - Bad query

```ruby
QueryPolice.analysis_debt_ranges = [
  { "range" => (0...200), "message" => "Good Query", "colour" => "green" },
  { "range" => (200...500), "message" => "Potentially Bad Query", "colour" => "yellow" }
]
# or
QueryPolice.configure do |config|
  config.analysis_debt_ranges = [
    { "range" => (0...200), "message" => "Good Query", "colour" => "green" },
    { "range" => (200...500), "message" => "Potentially Bad Query", "colour" => "yellow" }
  ]
end

# puts
# +------------------+-------------------------------+
# | Total Query Debt | 330.0 (Potentially Bad Query) |
# +------------------+-------------------------------+
```

### Analysis Footer
To define a footer text that will be added after an analysis for a query, by default there is no footer
```ruby
QueryPolice.analysis_footer = 'Please check more details with this link...'
# or
QueryPolice.configure do |config|
  config.analysis_footer = 'Please check more details with this link...'
end

# puts
# +------------------+-------------------------------+
# | Total Query Debt | 330.0 (Potentially Bad Query) |
# +------------------+-------------------------------+
#
# +------------------------------------------------------------------------+
# |                                 users                                  |
# +----------+-------------------------------------------------------------+
# | Debt     | 330.0                                                       |
# +----------+-------------------------------------------------------------+
# | Column   | select_type                                                 |
# | Value    | SIMPLE                                                      |
# | Impact   | positive                                                    |
# | Tag Debt | 0                                                           |
# | Message  | This query is a simple one without any subqueries or unions |
# +----------+-------------------------------------------------------------+
# Please check more details with this link...
```

### Custom rules path

To define custom rules path (More details about [how to define custom rules](#how-to-define-custom-rules))
```ruby
QueryPolice.rules_path = 'path/to/rules/file.<json/yml>'
# or
QueryPolice.configure do |config|
  config.rules_path = 'path/to/rules/file.<json/yml>'
end
```

### Custom app dir

To define custom app dir for file tracing
```ruby
QueryPolice.app_dir = 'path/to/app'
# or
QueryPolice.configure do |config|
  config.app_dir = 'path/to/app'
end
```

### Verbosity

Verbosity defines which `EXPLAIN` result should be used for analysis. (More details about [EXPLAIN vs Detailed EXPLAIN](#execution-plan))
- `basic` - It uses only `EXPLAIN`(basic) result
- `detailed` - It uses both `EXPLAIN`(basic) and `EXPLAIN format=json`(detailed) results `(default value)`
```ruby
QueryPolice.verbosity = "detailed"
# or
QueryPolice.configure do |config|
  config.verbosity = "detailed"
end
```

### Disable Actions

To disable actions that are performed on each query.
```ruby
# Note: A logger action is already added, so query police will log pretty analysis after each query by default
QueryPolice.action_enabled = false
# or
QueryPolice.configure do |config|
  config.action_enabled = false
end
```

### Custom Actions

To add custom actions, by default a logger action is already added and enabled (More details about [Analysis Object](#analysis-object))
```ruby
QueryPolice.add_action do |analysis| # analysis object for the query
  puts analysis.tables
end
```

### Logger config

To change the logger options which will be used to generate analysis
```ruby
QueryPolice.logger_options = {'negative' => true}
# or
QueryPolice.configure do |config|
  config.logger_options = {'negative' => true}
end

# default logger_config: {'negative' => true, 'caution' => true}
# options negative: <Boolean>, positive: <Boolean>, caution: <Boolean>, wrap_width: <Integer>, skip_footer: <Boolean>
```

---

## How to define custom rules?

Rules defined in the `json/yaml` file at rules_path is applied to the execution plan. Query Police have variety of option to define rules.

You can change this by `QueryPolice.rules_path=<path>` and define your own rules

### Rule Structure
**Note:** Check Query Police default rules defined at [rules.json](lib/query_police/rules.json) or examples at [examples/rules/](examples/rules/) for better clarity 

A basic rule structure - 

JSON
```json
"<column_name>": { 
  "description": "<string>",
  "value_type": "<string>",
  "delimiter": "<string>", 
  "rules": {
    "<rule>": {
      "amount": "<integer>",
      "impact": "<string>",
      "message": "<string>",
      "suggestion": "<string>",
      "debt": {
        "value": "<integer>",
        "type": "<string>"
      } 
    }
  }
}
```
YAML
```yaml
<column_name>:
  description: <string>
  value_type: <string>
  delimiter: <string>
  rules:
    <rule>:
      amount: <integer>
      impact: <string>
      message: <string>
      suggestion: <string>
      debt:
        value: <integer>
        type: <string>
```
- `<column_name>` - attribute name in the final execution plan. (more details about [attributes](#attributes-for-rules))
- `description` - description of the attribute
- `value_type` - value type of the attribute
- `delimiter` - delimiter to parse array type attribute values, if no delimiter is passed engine will consider value is already in array form.
- `<rule>` - kind of rule for the attribute
    - `<tag>` - direct value match eg. ALL, SIMPLE
    - `absent` - when the value is missing
    - `threshold` - a greater than threshold check based on the amount set inside the rule.
- `amount` - the amount of threshold that needs to check for 
    - length for string
    - value for number
    - size for the array
- `impact` - impact of the rule
    - `negative`
    - `postive`
    - `caution`
- `message` - the message needs to provide the significance of the rule
- `suggestion` - suggestion on how we can fix the issue
- `debt` - debt-related config that will be affected to final query debt
    - `value` - value that will be added to the query debt 
    -  `type` - the type of scoring that will be added to the query debt
        - `base`- value
        - `relative` - value * (amount for that column in query)
        - `threshold_relative` - (value - (threshold amount)) * (amount for that column in query)



### Dynamic messages and suggestion

We can define dynamic messages and suggestions with variables provided by the engine.

- `$amount` - the amount of the value 
    - length for string
    - value for number
    - size for the array
- `$column` - attribute name
- `$impact` - impact for the rule
- `$table` - table alias used in the plan
- `$tag` - tag for which rule is applied 
- `$value` - original parsed value
- `$<column_name>` - the value of that specific column in that table
- `$amount_<column_name>` - amount of that specific column

### Rules Examples

#### Basic rule example 
File: [JSON](examples/rules/json/basic_rule.json) | [YAML](examples/rules/yaml/basic_rule.yml)
```json
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
      "suggestion": "Use index here. You can use index from possible key: $possible_keys or add new one to $table table as per the requirements.",
      "debt": {
        "value": 200,
        "type": "base" 
      }
    }
  }
}
```
For the above rule, dynamic message will be generated as-
```
Entire users table is scanned to find matching rows, you have 1 possible keys to use
```
For the above rule, dynamic suggestion will be generated as-
```
Use index here. You can use index from possible key: ["PRIMARY", "user_email"] or add new one to users table as per the requirements.
```


#### Absent rule example
File: [JSON](examples/rules/json/absent_rule.json) | [YAML](examples/rules/yaml/absent_rule.yml)
```json
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

For the above rule, dynamic message will be generated as-
```
There is no index key used for users table, and can result into full scan of the users table
```
For the above rule, dynamic suggestion will be generated as-
```
Please use index from possible_keys: ["PRIMARY", "user_email"] or add new one to users table as per the requirements.
```


#### Threshold rule example
File: [JSON](examples/rules/json/threshold_rule.json) | [YAML](examples/rules/yaml/threshold_rule.yml)
```json
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
For the above rule, dynamic message will be generated as-
```
There are 10 possible keys for users table, having too many index keys can be unoptimal
```
For the above rule, dynamic suggestion will be generated as-
```
Please check if there are extra indexes in users table.
```


#### Complex Detailed rule example
File: [JSON](examples/rules/json/complex_detailed_rule.json) | [YAML](examples/rules/yaml/complex_detailed_rule.yml)
```json
"detailed#used_columns": {
  "description": "",
  "value_type": "array",
  "rules": {
    "threshold": {
      "amount": 7,
      "impact": "negative",
      "message": "You have selected $amount columns, You should not select too many columns.",
      "suggestion": "Please only select required columns.",
      "debt": {
        "value": 10,
        "type": "threshold_relative" 
      }
    }
  }
}
```
For the above rule, dynamic message will be generated as-
```
You have selected 10 columns, You should not select too many columns.
```
For the above rule, dynamic suggestions will be generated as-
```
Please only select required columns.
```


### Summary in Analysis

You can define similar rules for the summary. Current only one attribute is supported in summary - 

- `cardinality` - cardinality based on all tables

**NOTE:** You can add custom summary attributes by defining how to calculate them in `QueryPolice.add_summary` for an attribute key.



### Attributes for Rules

There are a lot of attributes for you to use based on the final execution plan. 

You can use the normal execution plan attribute directly.
Eg. `select_type, type, Extra, possible_keys`

To check more keys you can use `EXPLAIN <query>`

You can use the detailed execution plan attribute can be used in flattened form with the `detailed#` prefix.
Eg. `detailed#used_columns, detailed#cost_info#read_cost`

To check more keys you can use `EXPLAIN format=JSON <query>`

---

## How Query Police works?

1. Query police converts the relation into SQL query

2. Query police generates an execution plan using EXPLAIN and EXPLAIN format=JSON based on the configuration.

3. Query police load rules from the config file.

4. Query police apply rules on the execution plan and generate a new analysis object.

5. Analysis object provides different methods to print the analysis in a more descriptive format.


## Execution plan

We have 2 possible execution plans:-

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


The result for this is added as it is in the final execution plan

**Eg.**

```ruby
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

```ruby
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


The result for this is added in the flattened form to the final execution plan, where the `detailed#` prefix is added before each key.

**Truncated Eg.**

```ruby
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

---

## Analysis object

Analysis object stores a detailed analysis report of a relation inside `:tables :summary attributes`.

#### Attributes

**tables [Hash] - detailed table analysis**

```ruby
{
  'users' => {                        
    'id'=>1,                    
    'name' => 'users',               # table alias user in the execution plan
    'debt' => <float>               # debt for the table   
    'analysis' => {
      'type' => {                    # attribute name
        'value' => <string>,         # raw value of attribute in execution plan
        'tags' => {
          'all' => {                 # tag based on the value of a attribute
            'impact'=> <string>,     # negative, positive, cautions
            'warning'=> <string>,    # Eg. 'warning to represent the issue'
            'suggestions'=> <string> # Eg. 'some follow-up suggestions'
            'debt' => <float>       # debt for the tag
          }
        }
      }
    }
  }
}
```
**summary [Hash] - hash of analysis summary**

```ruby
{
  'cardinality' => {
    'amount' => 10,
    'warning' => 'warning to represent the issue',
    'suggestions' => 'some follow up suggestions',
    'debt' => 100.0
  }
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/query_police. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/query_police/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the QueryPolice project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/query_police/blob/master/CODE_OF_CONDUCT.md).
