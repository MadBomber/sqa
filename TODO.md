# TODO List

This file tracks outstanding tasks and improvements for the SQA project.

## High Priority

### lib/sqa/config.rb
- [ ] **FIXME**: Getting undefined error PredefinedValues - needs investigation
- [ ] If no path is given, implement proper fallback behavior
- [ ] Need a custom proc for Boolean class type handling
- [ ] Arrange configuration order by most often used

### Testing
- [ ] Add tests for individual strategy implementations (11 strategies untested)
- [ ] Add tests for Stock class
- [ ] Add tests for Config class
- [ ] Add integration tests for data adapters (Alpha Vantage, Yahoo Finance)

## Medium Priority

### lib/sqa/strategy.rb
- [ ] Implement parallel strategy execution (currently sequential)

### lib/api/alpha_vantage_api.rb
- [ ] Reorganize methods by category for better maintainability

### lib/sqa/init.rb
- [ ] Figure out how to parse a fake argv for testing purposes

### lib/sqa/config.rb
- [ ] Consider using svggraph for visualization

## Low Priority

### lib/sqa.rb
- [ ] Create a new gem for the dumbstockapi website integration
- [ ] Move debug_me gem out of dev dependencies (currently in dev, consider if needed in runtime)

## Completed ✓
- [x] Update CHANGELOG (v0.0.25-0.0.31) - Completed 2024-11-09
- [x] Remove legacy indicator tests - Completed 2024-11-09
- [x] Delete orphaned activity.rb file - Completed 2024-11-09
