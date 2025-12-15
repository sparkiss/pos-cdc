#!/usr/bin/env python3
"""
Prepare PostgreSQL target database schema from source MySQL schema export.
Converts MySQL DDL to PostgreSQL syntax with the following transformations:
- Adds deleted_at column (TIMESTAMPTZ) to all tables
- Removes excluded tables
- Converts MySQL data types to PostgreSQL equivalents
- Replaces backtick quoting with double quotes
- Removes AUTO_INCREMENT (CDC provides IDs)
- Removes MySQL-specific comments and syntax
"""

import re
import sys
import os

# MySQL to PostgreSQL type mapping
TYPE_MAP = [
    # Integer types - order matters (more specific first)
    (r'\bTINYINT\s*\(\d+\)', 'SMALLINT'),
    (r'\bTINYINT\b', 'SMALLINT'),
    (r'\bSMALLINT\s*\(\d+\)', 'SMALLINT'),
    (r'\bMEDIUMINT\s*\(\d+\)', 'INTEGER'),
    (r'\bMEDIUMINT\b', 'INTEGER'),
    (r'\bBIGINT\s*\(\d+\)', 'BIGINT'),
    (r'\bBIGINT\b', 'BIGINT'),
    (r'\bINTEGER\s*\(\d+\)', 'INTEGER'),
    (r'\bINT\s*\(\d+\)', 'INTEGER'),
    (r'\bINT\b', 'INTEGER'),

    # Floating point
    (r'\bFLOAT\s*\([^)]+\)', 'REAL'),
    (r'\bFLOAT\b', 'REAL'),
    (r'\bDOUBLE\s*\([^)]+\)', 'DOUBLE PRECISION'),
    (r'\bDOUBLE\b', 'DOUBLE PRECISION'),

    # Date/Time types - convert to timezone-aware types
    (r'\bDATETIME\s*\(\d+\)', 'TIMESTAMPTZ'),
    (r'\bDATETIME\b', 'TIMESTAMPTZ'),
    (r'\bTIMESTAMP\s*\(\d+\)', 'TIMESTAMPTZ'),
    (r'\bTIMESTAMP\b', 'TIMESTAMPTZ'),

    # String types
    (r'\bLONGTEXT\b', 'TEXT'),
    (r'\bMEDIUMTEXT\b', 'TEXT'),
    (r'\bTINYTEXT\b', 'TEXT'),

    # Binary types
    (r'\bLONGBLOB\b', 'BYTEA'),
    (r'\bMEDIUMBLOB\b', 'BYTEA'),
    (r'\bTINYBLOB\b', 'BYTEA'),
    (r'\bBLOB\b', 'BYTEA'),
    (r'\bVARBINARY\s*\(\d+\)', 'BYTEA'),
    (r'\bBINARY\s*\(\d+\)', 'BYTEA'),

    # Boolean
    (r'\bBIT\s*\(1\)', 'BOOLEAN'),

    # JSON
    (r'\bJSON\b', 'JSONB'),

    # Decimal
    (r'\bDECIMAL\b', 'NUMERIC'),

    # ENUM and SET to VARCHAR
    (r'\bENUM\s*\([^)]+\)', 'VARCHAR(255)'),
    (r'\bSET\s*\([^)]+\)', 'VARCHAR(255)'),
]


def remove_mysql_comments(content):
    """Remove MySQL conditional comments /*!...*/."""
    # Remove MySQL conditional comments (handle nested carefully)
    content = re.sub(r'/\*!\d+\s*', '', content)
    content = re.sub(r'\*/', '', content)
    # Remove MariaDB comments
    content = re.sub(r'/\*M!\d+[^*]*\*/', '', content, flags=re.DOTALL)
    content = re.sub(r'/\*M!.*?\*/', '', content, flags=re.DOTALL)
    # Remove SET statements that are MySQL-specific
    content = re.sub(r'^\s*SET\s+@\w+\s*=.*?;\s*$', '', content, flags=re.IGNORECASE | re.MULTILINE)
    return content


def convert_types(line):
    """Convert MySQL types to PostgreSQL equivalents."""
    result = line
    for mysql_pattern, pg_type in TYPE_MAP:
        result = re.sub(mysql_pattern, pg_type, result, flags=re.IGNORECASE)
    return result


def remove_mysql_specific(line):
    """Remove MySQL-specific syntax from a line."""
    patterns = [
        r'\s*AUTO_INCREMENT(?:\s*=\s*\d+)?',
        r'\s*ENGINE\s*=\s*\w+',
        r'\s*DEFAULT\s+CHARSET\s*=\s*\w+',
        r'\s*COLLATE\s*=?\s*[\w_]+',
        r'\s*CHARACTER\s+SET\s+\w+',
        r'\s*UNSIGNED',
        r'\s*ZEROFILL',
        r'\s*ON\s+UPDATE\s+CURRENT_TIMESTAMP(?:\s*\([^)]*\))?',
        r"\s*COMMENT\s+'[^']*'",
        r'\s*COMMENT\s+"[^"]*"',
        r'\s*ROW_FORMAT\s*=\s*\w+',
        r'\s*KEY_BLOCK_SIZE\s*=\s*\d+',
        r'\s*USING\s+\w+',  # USING BTREE, USING HASH
    ]
    result = line
    for pattern in patterns:
        result = re.sub(pattern, '', result, flags=re.IGNORECASE)

    # Convert MySQL bit literals to PostgreSQL booleans
    # b'0' -> FALSE, b'1' -> TRUE
    result = re.sub(r"\bDEFAULT\s+b'0'", 'DEFAULT FALSE', result, flags=re.IGNORECASE)
    result = re.sub(r"\bDEFAULT\s+b'1'", 'DEFAULT TRUE', result, flags=re.IGNORECASE)

    # Remove precision from CURRENT_TIMESTAMP(n) -> CURRENT_TIMESTAMP
    result = re.sub(r'CURRENT_TIMESTAMP\s*\(\d+\)', 'CURRENT_TIMESTAMP', result, flags=re.IGNORECASE)

    return result


def find_matching_paren(s, start):
    """Find the index of the closing parenthesis matching the opening one at start."""
    depth = 0
    for i in range(start, len(s)):
        if s[i] == '(':
            depth += 1
        elif s[i] == ')':
            depth -= 1
            if depth == 0:
                return i
    return -1


def extract_create_table(content, table_name):
    """Extract a CREATE TABLE statement for a specific table."""
    # Find CREATE TABLE for this table
    pattern = rf'CREATE\s+TABLE\s+[`"]?{re.escape(table_name)}[`"]?\s*\('
    match = re.search(pattern, content, re.IGNORECASE)
    if not match:
        return None, None

    # Find the opening paren
    open_paren = match.end() - 1  # Position of '('

    # Find matching closing paren
    close_paren = find_matching_paren(content, open_paren)
    if close_paren == -1:
        return None, None

    # Extract the content between parentheses
    columns_body = content[open_paren + 1:close_paren]

    # Find the semicolon after the closing paren
    semicolon = content.find(';', close_paren)
    if semicolon == -1:
        semicolon = len(content)

    full_stmt = content[match.start():semicolon + 1]

    return full_stmt, columns_body


def parse_column_definitions(columns_str):
    """Parse column definitions from CREATE TABLE body."""
    columns = []
    constraints = []
    indexes = []

    # Split by newlines and process each line
    lines = columns_str.split('\n')

    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Remove trailing comma
        line = line.rstrip(',')
        if not line:
            continue

        # Convert backticks to double quotes
        line = line.replace('`', '"')

        # Check for PRIMARY KEY constraint
        if re.match(r'^\s*PRIMARY\s+KEY\s*\(', line, re.IGNORECASE):
            constraints.append(line)
            continue

        # Check for UNIQUE KEY/INDEX
        unique_match = re.match(r'^\s*UNIQUE\s+(?:KEY|INDEX)\s+"?(\w+)"?\s*\(([^)]+)\)', line, re.IGNORECASE)
        if unique_match:
            cols = unique_match.group(2).replace('`', '"')
            constraints.append(f'UNIQUE ({cols})')
            continue

        # Check for KEY/INDEX (non-unique) - these become CREATE INDEX
        key_match = re.match(r'^\s*(?:KEY|INDEX)\s+"?(\w+)"?\s*\(([^)]+)\)', line, re.IGNORECASE)
        if key_match:
            index_name = key_match.group(1)
            cols = key_match.group(2).replace('`', '"')
            indexes.append((index_name, cols))
            continue

        # Check for CONSTRAINT (foreign keys, etc.)
        if re.match(r'^\s*CONSTRAINT\s+', line, re.IGNORECASE):
            line = remove_mysql_specific(line)
            constraints.append(line)
            continue

        # Skip empty or whitespace-only after processing
        if not line.strip():
            continue

        # Regular column definition
        line = convert_types(line)
        line = remove_mysql_specific(line)

        # Clean up multiple spaces
        line = re.sub(r'\s+', ' ', line).strip()

        if line:
            columns.append(line)

    return columns, constraints, indexes


def generate_create_table(table_name, columns, constraints, add_deleted_at=True):
    """Generate PostgreSQL CREATE TABLE statement."""
    all_items = columns.copy()

    # Check if deleted_at already exists
    has_deleted_at = any('deleted_at' in col.lower() for col in columns)

    # Add deleted_at column if not already present
    if add_deleted_at and not has_deleted_at:
        all_items.append('"deleted_at" TIMESTAMPTZ DEFAULT NULL')

    # Add constraints
    all_items.extend(constraints)

    # Format the CREATE TABLE
    items_str = ',\n  '.join(all_items)

    return f'CREATE TABLE IF NOT EXISTS "{table_name}" (\n  {items_str}\n)'


def process_schema(input_file, output_file, excluded_tables, source_db, target_db):
    """Process SQL schema file."""
    with open(input_file, 'r') as f:
        content = f.read()

    # Remove MySQL-specific comments
    content = remove_mysql_comments(content)

    # Replace source database name with target database name
    content = content.replace(f'`{source_db}`', f'"{target_db}"')
    content = re.sub(rf"'{source_db}'", f"'{target_db}'", content)

    # Find all CREATE TABLE statements
    table_pattern = r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?[`"]?(\w+)[`"]?'
    tables = re.findall(table_pattern, content, re.IGNORECASE)

    # Remove duplicates while preserving order
    seen = set()
    unique_tables = []
    for t in tables:
        if t.lower() not in seen and t.lower() not in [e.lower() for e in excluded_tables]:
            seen.add(t.lower())
            unique_tables.append(t)

    create_statements = []
    all_indexes = []

    for table_name in unique_tables:
        full_stmt, columns_body = extract_create_table(content, table_name)

        if not columns_body:
            print(f"Warning: Could not parse table {table_name}")
            continue

        columns, constraints, indexes = parse_column_definitions(columns_body)

        if not columns:
            print(f"Warning: No columns found for table {table_name}")
            continue

        # Generate CREATE TABLE
        create_stmt = generate_create_table(table_name, columns, constraints)
        create_statements.append(create_stmt)

        # Collect indexes (only if not already an index for deleted_at)
        for idx_name, idx_cols in indexes:
            if 'deleted_at' not in idx_name.lower():
                all_indexes.append((table_name, idx_name, idx_cols))

        # Add deleted_at index if not already present
        has_deleted_at_idx = any('deleted_at' in idx_name.lower() for idx_name, _ in indexes)
        if not has_deleted_at_idx:
            all_indexes.append((table_name, 'deleted_at', '"deleted_at"'))

        print(f"Processed table: {table_name}")

    # Write output
    with open(output_file, 'w') as f:
        f.write('-- PostgreSQL Target Database Schema\n')
        f.write('-- Generated from MySQL source with CDC modifications\n')
        f.write('-- Added: deleted_at column (TIMESTAMPTZ) to all tables\n')
        f.write(f'-- Excluded tables: {", ".join(excluded_tables)}\n')
        f.write('-- Type conversions: DATETIME->TIMESTAMPTZ, TINYINT->SMALLINT, etc.\n\n')

        # Write CREATE TABLE statements
        for stmt in create_statements:
            f.write(stmt + ';\n\n')

        # Write CREATE INDEX statements
        if all_indexes:
            f.write('\n-- Indexes\n')
            for table_name, idx_name, idx_cols in all_indexes:
                f.write(f'CREATE INDEX IF NOT EXISTS "idx_{table_name}_{idx_name}" ON "{table_name}" ({idx_cols});\n')

    print(f"\nSchema prepared successfully: {output_file}")
    print(f"Total tables: {len(create_statements)}")
    print(f"Total indexes: {len(all_indexes)}")


if __name__ == '__main__':
    # Get database names from environment or use defaults
    source_db = os.getenv('SOURCE_DB_NAME', 'pos')
    target_db = os.getenv('TARGET_PG_DATABASE', 'pos_replica')

    excluded = ['recorded_order', 'lock', 'log']

    input_file = '../configs/source-schema.sql'
    output_file = '../configs/target-schema-pg.sql'

    # Allow command-line override
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    if len(sys.argv) > 2:
        output_file = sys.argv[2]

    print(f"Source database: {source_db}")
    print(f"Target database: {target_db}")
    print(f"Excluded tables: {', '.join(excluded)}")
    print(f"Input file: {input_file}")
    print(f"Output file: {output_file}\n")

    if not os.path.exists(input_file):
        print(f"Error: Input file not found: {input_file}")
        print("Please export source schema first:")
        print("  mysqldump -h HOST -u USER -p --no-data DATABASE > configs/source-schema.sql")
        sys.exit(1)

    process_schema(input_file, output_file, excluded, source_db, target_db)
