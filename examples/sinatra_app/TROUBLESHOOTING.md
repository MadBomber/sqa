# Troubleshooting the Sinatra App

## Dashboard page loads but buttons/charts don't work

This usually means JavaScript errors are preventing the page from functioning.

### Quick Fix Checklist

1. **Install dependencies first:**
   ```bash
   cd examples/sinatra_app
   bundle install
   ```

2. **Start the server with bundle exec:**
   ```bash
   bundle exec ruby app.rb
   # OR
   bundle exec rackup
   ```

3. **Check browser console for errors:**
   - Open browser DevTools (F12 or Ctrl+Shift+I)
   - Go to "Console" tab
   - Look for red error messages
   - Take a screenshot and check what's failing

4. **Check Network tab:**
   - Open DevTools → Network tab
   - Reload the dashboard page
   - Look for failed requests (red status codes)
   - Check if `/api/stock/AAPL`, `/api/indicators/AAPL`, `/api/analyze/AAPL` are returning 200 or errors

### Common Issues

#### Issue: "ApexCharts is not defined"
**Symptom:** Charts don't render, console shows `Uncaught ReferenceError: ApexCharts is not defined`

**Fix:** The CDN link for ApexCharts is missing or blocked. Check `views/layout.erb`:
```html
<script src="https://cdn.jsdelivr.net/npm/apexcharts"></script>
```

#### Issue: API calls failing with 500 errors
**Symptom:** Network tab shows `/api/indicators/AAPL` returns 500

**Fix:** This is expected if TA-Lib isn't installed. The app should handle this gracefully.

#### Issue: Buttons don't respond
**Symptom:** Clicking buttons does nothing

**Possible causes:**
1. JavaScript not loaded (check console for errors)
2. Event handlers not attached (check if page finished loading)
3. JavaScript errors earlier in the file preventing execution

### Debug Mode

Run the server with verbose logging:
```bash
RACK_ENV=development bundle exec ruby app.rb
```

### Test API Endpoints Manually

While server is running, test in another terminal:

```bash
# Test stock data
curl -s "http://localhost:4567/api/stock/AAPL?period=30d" | python3 -m json.tool

# Test indicators (may fail without TA-Lib - that's OK)
curl -s "http://localhost:4567/api/indicators/AAPL?period=30d"

# Test analysis
curl -s "http://localhost:4567/api/analyze/AAPL" | python3 -m json.tool
```

All should return JSON. If you get HTML error pages, there's a server-side issue.

### Check if all gems are installed

```bash
bundle check
```

If it says "The Gemfile's dependencies are satisfied", you're good.

### Still not working?

Please provide:
1. Screenshot of browser console (DevTools → Console tab)
2. Screenshot of network tab showing failed requests
3. Output of `bundle check`
4. Any errors from server console
