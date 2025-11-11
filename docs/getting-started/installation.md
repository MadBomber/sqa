# Installation Guide

This guide walks you through installing SQA and all its dependencies.

## System Requirements

- **Ruby**: 3.2 or higher
- **Operating System**: Linux, macOS, or Windows (with WSL)
- **Disk Space**: ~100MB for gem and dependencies
- **Internet**: Required for downloading stock data

## Step 1: Install TA-Lib

SQA requires the TA-Lib C library for technical analysis calculations.

### Linux (Ubuntu/Debian)

```bash
# Download and extract TA-Lib source
cd /tmp
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
tar -xzf ta-lib-0.4.0-src.tar.gz

# Compile and install
cd ta-lib
./configure --prefix=/usr/local
make
sudo make install

# Create symlink for compatibility
cd /usr/local/lib
sudo ln -s libta_lib.so libta-lib.so
sudo ldconfig

# Set library path (add to ~/.bashrc for persistence)
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

### macOS

```bash
# Using Homebrew
brew install ta-lib
```

### Verify Installation

```bash
# Check that TA-Lib is installed
ls -la /usr/local/lib/libta_lib.*

# Should show files like:
# libta_lib.a
# libta_lib.so
# libta_lib.so.0
# libta_lib.so.0.0.0
```

## Step 2: Install SQA Gem

### From RubyGems (Recommended)

```bash
gem install sqa
```

### From Source

```bash
# Clone the repository
git clone https://github.com/madbomber/sqa.git
cd sqa

# Install dependencies
bundle install

# Install the gem locally
rake install
```

## Step 3: Verify Installation

Test that SQA is installed correctly:

```bash
# Launch the SQA console
sqa-console

# In the console, try:
SQA::VERSION  # Should display the version number
SQAI.methods.grep(/^[a-z]/).sort  # List available indicators
```

Expected output:
```ruby
=> "0.0.31"  # Version number

=> [:acos, :ad, :add, :adosc, :adx, :adxr, ...]  # 150+ indicators
```

## Step 4: Configure API Access (Optional)

To download live stock data, you'll need an Alpha Vantage API key.

### Get API Key

1. Visit [Alpha Vantage](https://www.alphavantage.co/support/#api-key)
2. Sign up for a free API key
3. Copy your API key

### Set Environment Variable

```bash
# Temporary (current session)
export AV_API_KEY="your_api_key_here"

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export AV_API_KEY="your_api_key_here"' >> ~/.bashrc
source ~/.bashrc
```

### Alternative: Configuration File

Create `~/.sqa.yml`:

```yaml
data_dir: ~/sqa_data
debug: false
verbose: false
```

The API key is read from environment variables, not the config file.

## Troubleshooting

### TA-Lib Not Found

**Error**: `cannot load such file -- sqa/tai (LoadError)`

**Solution**: Make sure TA-Lib is installed and `LD_LIBRARY_PATH` is set:

```bash
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
```

### Permission Denied During Installation

**Error**: `Permission denied @ dir_s_mkdir`

**Solution**: Use `sudo` for system-wide installation:

```bash
sudo gem install sqa
```

Or install to user directory:

```bash
gem install --user-install sqa
```

### Ruby Version Too Old

**Error**: `Required Ruby version is >= 3.2.0`

**Solution**: Update Ruby using rbenv or rvm:

```bash
# Using rbenv
rbenv install 3.3.6
rbenv global 3.3.6

# Using rvm
rvm install 3.3.6
rvm use 3.3.6 --default
```

### Bundle Install Fails

**Error**: Various dependency errors

**Solution**: Update bundler and try again:

```bash
gem update --system
gem install bundler
bundle install
```

## Next Steps

Now that you have SQA installed:

1. **[Quick Start Guide](quick-start.md)** - Run your first analysis
2. **[Core Concepts](../concepts/index.md)** - Understand SQA's architecture
3. **[Trading Strategies](../strategies/index.md)** - Explore built-in strategies

## Additional Dependencies

SQA automatically installs these dependencies:

- `polars-df` - High-performance DataFrames
- `sqa-tai` - TA-Lib wrapper for indicators
- `faraday` - HTTP client for API calls
- `hashie` - Enhanced hash objects
- `tty-table` - Terminal table formatting
- `kbs` - Knowledge-based strategy framework
- `toml-rb` - TOML configuration support

For development, you may also want:

- `amazing_print` - Pretty printing
- `debug_me` - Debugging utilities
- `minitest` - Testing framework
- `simplecov` - Code coverage

## Supported Platforms

SQA has been tested on:

- ✅ Ubuntu 20.04+
- ✅ Debian 11+
- ✅ macOS 12+ (Monterey and later)
- ✅ Fedora 35+
- ⚠️ Windows (via WSL recommended)

---

Having issues? Check our [GitHub Issues](https://github.com/madbomber/sqa/issues) or create a new one.
