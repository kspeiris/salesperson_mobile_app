# Salesperson Daily Recorder

A polished Flutter starter project for the offline sales and collections app described in the SRS.

## What is implemented
- Material 3 mobile UI with professional forms and navigation
- Offline SQLite storage using `sqflite`
- Local repository layer for shops, products, sales, collections, and settings
- Input validation for login, shops, products, sales, collections, and settings
- Daily dashboard totals from local data
- Soft-delete style voiding for sales and collections with reason capture
- PDF daily report generation and local file export
- CSV and JSON export bundle for manual desktop import
- Native share flows for PDF, CSV, and JSON files
- SQLite backup creation and restore flow
- Barcode scanning for product master data and sales entry
- CSV/TXT import screens for shops and products

## Included screens
- Login / PIN
- Dashboard
- Shops list + add/edit + import
- Products list + add/edit + import
- New sale + barcode scan helper
- Sales history
- New collection
- Collections history
- Reports / PDF + CSV/JSON export
- Settings
- Data Management (backup / restore)
- Barcode scanner

## Packages used
- `provider`
- `sqflite`
- `path`
- `path_provider`
- `intl`
- `pdf`
- `share_plus`
- `crypto`
- `file_picker`
- `mobile_scanner`

## Notes
- Shop import header example: `name,owner_contact,area,phone,credit_limit,balance`
- Product import header example: `name,sku,unit_price,description,barcode`
- CSV / JSON export files are generated in the app documents directory under `exports/`
- SQLite backups are generated in the app documents directory under `backups/`
