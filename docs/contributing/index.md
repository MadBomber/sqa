# Contributing to SQA

Thank you for your interest in contributing to SQA!

## Ways to Contribute

- Report bugs
- Suggest features
- Improve documentation
- Submit pull requests
- Write tests

## Getting Started

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Development Setup

```bash
git clone https://github.com/madbomber/sqa.git
cd sqa
bundle install
```

## Running Tests

```bash
# Run all tests
rake test

# Run specific test file
ruby -Ilib:test test/strategy/rsi_test.rb

# With coverage
rake test
open coverage/index.html
```

## Code Style

- Follow Ruby community style guidelines
- Use meaningful variable names
- Add comments for complex logic
- Keep methods focused and small

## Pull Request Process

1. Update documentation
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md
5. Submit PR with clear description

## Questions?

Open an issue on GitHub or start a discussion.
