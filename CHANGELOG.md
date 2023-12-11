## [Unreleased]

## [0.1.0] - 2023-04-24

- Initial release

## [0.1.4.beta]

### Feature
- added scoring mechanism in rules
- updated pretty analysis
- updated default rules
- summary analysis
- Added word wrap for logs

### Bug fixes
- auto analysis tables update bug
- wrong amount and value

### Code
- added new components for analyse and transform
- added new robocop rules
- added new dependencies: colorize, terminal-table

## [0.1.7.beta]

### Feature
- wrap width config for pretty analysis
- support YAML files for rules
- added a custom action
- added action enable option
- added configure method to update config
- Added rule for `no matching row in const table`
- added payload for custom action for more data, including last file trace and original query
- better prettier analysis: Improved naming, total query debt more noticeable and new structure for multi-impact 
- added query debt range for categorization

### Bug fixes
- bug with the unsupported group by, order by, distinct for detailed explain
- bug with cardinality calculation
- type fix `treshold_relative` -> `threshold_relative`
- bug with the empty analysis for `pretty_analysis`

### Code
- rules message and suggestions improved and added new rules
- readme updated - structure change, added examples, syntax highlights, other minor changes
- change terminal table dependency from `>= 3.0.0` to `>= 1.5.0`
- Added default param for `pretty_analysis` - `opts = { "negative" => true, "caution" => true }`
- rename score to debt
- Added examples for rules
- no message for empty analysis
