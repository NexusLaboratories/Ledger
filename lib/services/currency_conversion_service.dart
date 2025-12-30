// Currency conversion service removed.
// The app no longer supports per-account or historical currency conversion
// or exchange rate fetching. All amounts are presented in the user's
// selected default currency. This file remains as a stub to help with
// diagnostics if any code path still attempts to use conversion.

class CurrencyConversionService {
  factory CurrencyConversionService() {
    throw UnsupportedError(
      'CurrencyConversionService was removed. Multi-currency conversion is no longer supported.',
    );
  }
}
