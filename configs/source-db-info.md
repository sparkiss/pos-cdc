# Source Database Information

## Connection Details
- **Host**: 192.168.0.74
- **Port**: 3306
- **Version**: MySQL 5.7.23
- **Database**: pos
- **User**: <user>

## CDC Configuration
- **Binary Logging**: Enabled
- **Binary Log Format**: ROW
- **Binary Log Files**: mysql-bin.XXXXXX

## Tables
- **Total**: 60 tables
- **Excluded from CDC**:
  - recorded_order
  - lock
  - log

## Transaction Volume
- **Inserts/Updates/Deletes**: < 100 ops/sec
- **Database Size**: < 10 GB

## Maintenance Window
- **Available**: After 9:30 PM ET, or any Tuesday
- **For**: Initial snapshot operations

## Notes
- Production database - handle with care
- All changes should be non-invasive
- Read-only access for CDC
