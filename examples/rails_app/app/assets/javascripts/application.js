// Global functions for modal and navigation

function showTickerModal() {
  document.getElementById('tickerModal').style.display = 'block';
  document.getElementById('tickerInput').focus();
}

function closeTickerModal() {
  document.getElementById('tickerModal').style.display = 'none';
}

function searchTicker(event) {
  event.preventDefault();

  const input = event.target.querySelector('input[type="text"]');
  const ticker = input.value.trim().toUpperCase();

  if (!ticker) {
    alert('Please enter a stock ticker symbol');
    return false;
  }

  // Validate ticker format (letters and optional dot)
  if (!/^[A-Z]{1,5}(\.[A-Z]{1,2})?$/.test(ticker)) {
    alert('Please enter a valid ticker symbol (e.g., AAPL, BRK.A)');
    return false;
  }

  // Navigate to dashboard
  window.location.href = `/dashboard/${ticker}`;
  return false;
}

// Close modal when clicking outside
window.onclick = function(event) {
  const modal = document.getElementById('tickerModal');
  if (event.target === modal) {
    closeTickerModal();
  }
}

// Keyboard shortcuts
document.addEventListener('keydown', function(event) {
  // Ctrl/Cmd + K to open search
  if ((event.ctrlKey || event.metaKey) && event.key === 'k') {
    event.preventDefault();
    showTickerModal();
  }

  // Escape to close modal
  if (event.key === 'Escape') {
    closeTickerModal();
  }
});

// Utility functions
function formatCurrency(value) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD'
  }).format(value);
}

function formatPercent(value) {
  return `${value >= 0 ? '+' : ''}${value.toFixed(2)}%`;
}

function formatNumber(value) {
  return new Intl.NumberFormat('en-US').format(value);
}

// Show loading indicator
function showLoading(elementId) {
  const element = document.getElementById(elementId);
  if (element) {
    element.innerHTML = '<p class="loading"><i class="fas fa-spinner fa-spin"></i> Loading...</p>';
  }
}

// Show error message
function showError(elementId, message) {
  const element = document.getElementById(elementId);
  if (element) {
    element.innerHTML = `<p class="error"><i class="fas fa-exclamation-circle"></i> ${message}</p>`;
  }
}

// Debounce function for performance
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Console welcome message
console.log('%cSQA Analytics', 'font-size: 24px; font-weight: bold; color: #2196F3;');
console.log('%cPowered by Ruby & Plotly.js', 'font-size: 14px; color: #666;');
console.log('');
console.log('Keyboard shortcuts:');
console.log('  Ctrl/Cmd + K: Open ticker search');
console.log('  Escape: Close modal');
