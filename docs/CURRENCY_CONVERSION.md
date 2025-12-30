# Currency Conversion Feature

## Overview
The Ledger app now supports **multi-currency accounts** with automatic currency conversion. Each account can have its own currency, and all balances are automatically converted to the user's selected base currency for display and calculations.

## Features

### 1. Multi-Currency Accounts
- Each account stores amounts in its original currency (USD, EUR, GBP, INR, JPY, AUD, CAD, etc.)
- Account balances are preserved in their native currency
- No data loss or rounding issues from conversion

### 2. Automatic Currency Conversion
- Net worth is calculated by converting all account balances to the user's selected base currency
- Exchange rates are fetched from [Frankfurter.app](https://www.frankfurter.app/) (no API key required)
- Rates are cached locally for 12 hours to minimize API calls
- Fallback to cached rates if API is unavailable

### 3. User-Selectable Base Currency
- Users can select their preferred base currency in Settings
- Options: USD, EUR, GBP, INR, JPY, AUD, CAD
- All totals and reports display amounts in the selected base currency
- Net worth updates automatically when base currency changes

### 4. Exchange Rate Management
- Rates refresh automatically every 12 hours
- Manual refresh button in Settings
- Historical rates support for accurate transaction date conversions
- Old rates are auto-deleted after 30 days to save space

## Architecture

### Components

#### 1. `ExchangeRate` Model (`lib/models/exchange_rate.dart`)
- Stores exchange rates with base currency, rates map, and fetch timestamp
- TTL tracking for cache expiration
- JSON serialization for database storage

#### 2. `ExchangeRateDBService` (`lib/services/database/exchange_rate_db_service.dart`)
- Manages local storage of exchange rates in SQLite
- Supports latest and historical rate queries
- Auto-cleanup of expired rates

#### 3. `CurrencyConversionService` (`lib/services/currency_conversion_service.dart`)
- Core conversion logic
- Fetches rates from Frankfurter.app API
- In-memory + database caching
- Stream notifications for rate updates
- Methods:
  - `convert()` - Convert amount between currencies
  - `refreshRates()` - Force refresh from API
  - `getRates()` - Get current rates for a base currency
  - `hasRatesFor()` - Check if rates are cached

#### 4. `CurrencyDisplay` Widget (`lib/components/currency_display.dart`)
- Reusable widget for displaying amounts with conversion
- Shows both original and converted amounts
- Supports historical date conversions
- Formats with appropriate currency symbols

#### 5. Updated `AccountService` (`lib/services/account_service.dart`)
- `fetchNetWorth()` now accepts optional `inCurrency` parameter
- Converts each account balance to the base currency
- Graceful error handling with fallback to original amounts

### Database Schema

New table `exchange_rates`:
```sql
CREATE TABLE exchange_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  base_currency TEXT NOT NULL,
  rates_json TEXT NOT NULL,  -- JSON map of currency -> rate
  fetched_at INTEGER NOT NULL,
  rate_date INTEGER  -- NULL for latest, timestamp for historical
);

-- Indexes for performance
CREATE INDEX idx_exchange_rates_base ON exchange_rates(base_currency);
CREATE INDEX idx_exchange_rates_date ON exchange_rates(base_currency, rate_date);
```

## API Integration

### Frankfurter.app
- **Provider**: Free, no API key required
- **Supported**: 30+ currencies
- **Base URL**: `https://api.frankfurter.app`

#### Endpoints Used
- Latest rates: `GET /latest?from=USD`
- Historical: `GET /2024-12-01?from=EUR`
- Response format:
```json
{
  "amount": 1.0,
  "base": "USD",
  "date": "2024-12-12",
  "rates": {
    "EUR": 0.95,
    "GBP": 0.79,
    "JPY": 149.8
  }
}
```

## Usage

### For Users

1. **Set Base Currency**
   - Go to Settings > Default Currency
   - Select your preferred currency (e.g., USD, EUR, GBP)
   - All totals will update automatically

2. **Create Multi-Currency Accounts**
   - When creating an account, select its currency
   - Default is your base currency
   - Existing accounts keep their original currency

3. **View Converted Balances**
   - Net worth shows the total in your base currency
   - Individual account balances display in both native and converted amounts

4. **Refresh Exchange Rates**
   - Settings > Refresh Exchange Rates
   - Updates rates from the API
   - Automatic refresh every 12 hours

### For Developers

#### Using CurrencyConversionService

```dart
final conversionService = getIt<CurrencyConversionService>();

// Convert amount
final converted = await conversionService.convert(
  amount: 100.0,
  fromCurrency: 'EUR',
  toCurrency: 'USD',
);

// Historical conversion
final historicalConverted = await conversionService.convert(
  amount: 100.0,
  fromCurrency: 'GBP',
  toCurrency: 'USD',
  date: DateTime(2024, 1, 15),
);

// Refresh rates
await conversionService.refreshRates(baseCurrency: 'EUR');

// Listen to rate updates
conversionService.onRatesUpdated.listen((rates) {
  print('Rates updated for ${rates.baseCurrency}');
});
```

#### Using CurrencyDisplay Widget

```dart
CurrencyDisplay(
  amount: 150.50,
  fromCurrency: 'EUR',
  showOriginal: true,  // Shows both EUR and converted amount
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
)
```

#### Updated AccountService Usage

```dart
final accountService = getIt<AccountService>();

// Get net worth in user's default currency
final netWorth = await accountService.fetchNetWorth();

// Get net worth in specific currency
final netWorthEUR = await accountService.fetchNetWorth(inCurrency: 'EUR');
```

## Testing

Run currency conversion tests:
```bash
flutter test test/services/currency_conversion_service_test.dart
```

Run all tests:
```bash
flutter test
```

## Error Handling

The system gracefully handles:
- **API unavailable**: Falls back to cached rates
- **No cached rates**: Uses original amounts (no conversion)
- **Missing currency**: Throws descriptive exception
- **Network timeout**: 10-second timeout with fallback

## Performance

- **In-memory cache**: Fast lookups for repeated conversions
- **Database cache**: Persistent across app restarts
- **TTL**: 12 hours (configurable)
- **Cleanup**: Old rates deleted after 30 days
- **API calls**: Minimized via caching strategy

## Future Enhancements

Potential improvements:
1. Support for more currencies (50+)
2. Offline mode with bundled fallback rates
3. Custom exchange rate overrides
4. Multi-currency transaction support
5. Currency conversion history/trends
6. Per-transaction currency selection
7. Cryptocurrency support

## Configuration

### Changing Cache TTL

Edit `CurrencyConversionService`:
```dart
static const Duration _defaultTtl = Duration(hours: 12);  // Adjust here
```

### Changing Cleanup Period

Edit database cleanup call:
```dart
await _dbService.deleteExpiredRates(ttl: const Duration(days: 30));  // Adjust here
```

### Adding New Currencies

1. Add to Settings screen dropdown:
```dart
DropdownMenuItem(value: 'CHF', child: Text('CHF')),
```

2. Add symbol to `CurrencyHelper`:
```dart
'CHF': 'Fr',
```

## Dependencies

- `http: ^1.2.0` - HTTP client for API calls
- `intl: ^0.20.2` - Currency formatting (already included)
- `sqflite_sqlcipher: ^3.4.0` - Local database (already included)

## Notes

- Exchange rates are indicative and may not match real-time market rates
- Frankfurter.app uses European Central Bank (ECB) data
- Historical rates are available from 1999-01-04 onwards
- Rate accuracy depends on API provider's data quality
