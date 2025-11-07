# SQA Project - Task List

**Session:** claude/review-codebase-planning-011CUqHdDz75cZMoeGXq8XfR
**Last Updated:** 2025-01-05

## Current Status

### ✅ Completed Tasks

- [x] Comprehensive codebase review and analysis
- [x] Architecture design and planning
- [x] Create sqa-talib gem structure
- [x] Implement 20+ TA-Lib indicator wrappers
- [x] Write comprehensive tests for sqa-talib
- [x] Set up MkDocs documentation for sqa-talib
- [x] Configure GitHub Actions (tests + docs) for sqa-talib
- [x] Document architecture decisions (ARCHITECTURE.md)
- [x] Create task list (this document)

### 🔄 In Progress

- [ ] Push sqa-talib to GitHub (using workaround via sqa repo)
- [ ] Create planning documentation in sqa repo

### ⏳ Pending Tasks

#### sqa-talib Repository
- [ ] **USER ACTION:** Authorize sqa-talib repository access
- [ ] Copy sqa-talib code from sqa repo to sqa-talib repo
- [ ] Verify GitHub Actions run successfully
- [ ] Enable GitHub Pages for documentation
- [ ] Test sqa-talib gem independently
- [ ] Publish sqa-talib v0.1.0 to RubyGems.org

#### sqa Repository Refactoring (v1.0.0)
- [ ] Create feature branch for refactoring
- [ ] Remove indicator implementations from lib/sqa/indicator/
- [ ] Add sqa-talib as dependency in gemspec
- [ ] Update lib/sqa/indicator.rb to provide deprecation wrappers
- [ ] Update tests to use sqa-talib
- [ ] Remove CLI command files (move to sqa-cli)
- [ ] Remove Stock, Portfolio, Config classes (move to sqa-cli)
- [ ] Remove data loading code (move to sqa-cli)
- [ ] Update hashie dependency (4.1.0 → 5.0.0)
- [ ] Create MIGRATION.md guide
- [ ] Update README for v1.0.0
- [ ] Update CHANGELOG for v1.0.0
- [ ] Run full test suite
- [ ] Bump version to 1.0.0
- [ ] Tag and publish release

#### sqa-cli Repository
- [ ] **USER ACTION:** Authorize sqa-cli repository access
- [ ] Create sqa-cli gem structure
- [ ] Copy CLI commands from sqa
- [ ] Copy Stock, Portfolio, Config, Trade, Activity classes from sqa
- [ ] Copy data loading code from sqa
- [ ] Add sqa and sqa-talib as dependencies
- [ ] Create SQA::AI module structure
- [ ] Add ruby_llm dependency
- [ ] Add ruby_llm-mcp dependency
- [ ] Add prompt_manager dependency
- [ ] Add sqlite3 dependency
- [ ] Implement SQLite storage layer
- [ ] Implement AI client wrapper
- [ ] Create prompt templates
- [ ] Implement strategy analyzer (AI)
- [ ] Implement market commentator (AI)
- [ ] Set up MkDocs documentation
- [ ] Configure GitHub Actions
- [ ] Write comprehensive README
- [ ] Create usage examples
- [ ] Write tests
- [ ] Tag v0.1.0 release
- [ ] Publish to RubyGems.org

#### Integration & Testing
- [ ] Test sqa-talib independently
- [ ] Test sqa v1.0.0 with sqa-talib
- [ ] Test sqa-cli with both dependencies
- [ ] Create integration test suite
- [ ] Performance benchmarking
- [ ] User acceptance testing

#### Documentation
- [ ] Finalize all README files
- [ ] Complete API documentation
- [ ] Write migration guides
- [ ] Create tutorial videos
- [ ] Write blog post announcing refactoring
- [ ] Update all CHANGELOG files

#### Release & Announcement
- [ ] Coordinate release dates
- [ ] Publish all three gems
- [ ] Deploy all documentation sites
- [ ] Announce on GitHub
- [ ] Post to Ruby communities
- [ ] Email existing users (if any)

---

## Immediate Next Steps

1. **Push sqa-talib code to sqa repo branch**
   - Create branch: `feature/sqa-talib-code`
   - Copy all sqa-talib files
   - Commit and push
   - User manually transfers to sqa-talib repo

2. **Save all planning documents to sqa main branch**
   - ARCHITECTURE.md (comprehensive architecture docs)
   - TASKS.md (this task list)
   - Commit to main branch

3. **Wait for repository authorization**
   - User authorizes sqa-talib repo
   - User authorizes sqa-cli repo

4. **Continue with sqa-cli creation**
   - Begin building sqa-cli structure
   - Use same workaround if needed

---

## Blocked Tasks (Waiting on User)

### Critical
- **Repository Access:** Need authorization for:
  - MadBomber/sqa-talib
  - MadBomber/sqa-cli

### Optional
- **API Keys:** For testing AI integration:
  - OpenAI API key (or other LLM provider)
  - AlphaVantage API key

---

## File Manifest

### sqa-talib Files (Created, in /home/user/sqa-talib)

```
sqa-talib/
├── .github/workflows/
│   ├── docs.yml                    # GitHub Pages deployment
│   └── test.yml                    # CI tests (Ruby 3.1, 3.2, 3.3)
├── docs/
│   ├── api-reference.md            # Complete API docs
│   ├── getting-started/
│   │   ├── installation.md         # TA-Lib installation guide
│   │   └── quick-start.md          # Quick start tutorial
│   └── index.md                    # Documentation home
├── lib/
│   └── sqa/
│       ├── talib.rb                # Main wrapper (300+ lines)
│       └── talib/
│           └── version.rb          # v0.1.0
├── test/
│   ├── sqa/
│   │   └── talib_test.rb           # Comprehensive tests
│   └── test_helper.rb              # Test setup
├── .gitignore
├── CHANGELOG.md
├── Gemfile
├── LICENSE (MIT)
├── mkdocs.yml
├── Rakefile
├── README.md (comprehensive)
└── sqa-talib.gemspec
```

**Total Files:** 18
**Lines of Code:** ~2000
**Test Coverage:** Comprehensive (all indicators tested)

### sqa Planning Files (Created, in /home/user/sqa)

```
sqa/
├── ARCHITECTURE.md                 # Complete architecture document (1000+ lines)
└── TASKS.md                        # This task list
```

---

## Dependencies Overview

### sqa-talib Dependencies
```ruby
# Runtime
ta_lib_ffi ~> 0.3

# Development
minitest ~> 5.0
minitest-reporters
simplecov
debug
```

### sqa v1.0.0 Dependencies (Planned)
```ruby
# Runtime
sqa-talib ~> 0.1          # NEW!
hashie ~> 5.0             # UPGRADED from 4.1.0

# Development (same as current)
minitest ~> 5.0
simplecov
```

### sqa-cli Dependencies (Planned)
```ruby
# Core
sqa ~> 1.0
sqa-talib ~> 0.1

# CLI
dry-cli
tty-table

# Data
alphavantage
faraday
api_key_manager

# Storage
sqlite3                    # NEW!

# AI
ruby_llm                   # NEW!
ruby_llm-mcp               # NEW!
prompt_manager             # NEW!

# Utilities
nenv
sem_version
```

---

## Time Estimates

### sqa-talib
- Repository setup: 1 hour
- Testing & fixes: 2 hours
- Documentation review: 1 hour
- **Total: 4 hours** (mostly complete)

### sqa Refactoring
- Code removal: 2 hours
- Dependency updates: 1 hour
- Test updates: 3 hours
- Documentation: 2 hours
- Testing: 2 hours
- **Total: 10 hours**

### sqa-cli Creation
- Structure setup: 2 hours
- Code migration: 4 hours
- AI integration: 8 hours
- SQLite integration: 3 hours
- Testing: 4 hours
- Documentation: 3 hours
- **Total: 24 hours**

### Integration & Release
- Integration testing: 4 hours
- Documentation: 2 hours
- Release process: 2 hours
- **Total: 8 hours**

**Grand Total: ~46 hours**

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| TA-Lib installation issues | High | High | Comprehensive docs, Docker image |
| Breaking changes upset users | Medium | Medium | Migration guide, deprecation warnings |
| Repository access delays | High | Low | Use workaround (push via sqa repo) |
| AI integration complexity | Medium | Medium | Phased approach, optional feature |
| Three gems coordination | Low | High | Semantic versioning, integration tests |
| Performance issues | Low | Medium | Benchmarking, TA-Lib is fast |

---

## Questions & Decisions Log

### Answered
- ✅ Use TA-Lib or pure Ruby? → TA-Lib (faster, more indicators)
- ✅ Monolithic or modular? → Modular (3 gems)
- ✅ Namespace strategy? → Keep SQA namespace
- ✅ Documentation tool? → MkDocs Material
- ✅ Ruby version? → >= 3.1.0
- ✅ AI libraries? → ruby_llm ecosystem
- ✅ Data storage? → SQLite + CSV
- ✅ Version numbers? → sqa-talib 0.1.0, sqa 1.0.0, sqa-cli 0.1.0

### Open
- ❓ API key configuration? (env vars, config file, both?)
- ❓ Web interface framework? (Rails, Sinatra, separate app?)
- ❓ Backtesting location? (sqa or sqa-cli?)
- ❓ Container support? (Docker image?)
- ❓ Release date? (when ready?)

---

## Communication Plan

### Announcements
1. **GitHub Release Notes** - All three repos
2. **Blog Post** - Announcing refactoring
3. **Reddit** - r/ruby, r/investing
4. **Twitter** - Use #ruby, #trading hashtags
5. **Email** - Existing users (if any)

### Documentation Sites
- https://madbomber.github.io/sqa-talib/
- https://madbomber.github.io/sqa/
- https://madbomber.github.io/sqa-cli/

---

## Success Criteria

### Technical Quality
- [ ] All tests passing (100%)
- [ ] Code coverage > 80%
- [ ] Documentation complete (100%)
- [ ] No critical bugs
- [ ] Performance benchmarks met

### User Experience
- [ ] Clear installation instructions
- [ ] Working examples
- [ ] Migration guide tested
- [ ] AI integration working
- [ ] Positive user feedback

### Community
- [ ] 100+ gem downloads first month
- [ ] 5+ stars per repository
- [ ] Active issues/PRs
- [ ] Community contributions

---

**Status Summary:**
- ✅ Planning: 100% complete
- ✅ sqa-talib: 90% complete (awaiting repo access)
- ⏳ sqa refactoring: 0% complete
- ⏳ sqa-cli: 0% complete

**Next Action:** Push sqa-talib code to sqa repo branch, wait for repository authorization.
