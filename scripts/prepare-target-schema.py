#!/usr/bin/env python3
"""
Prepare target database schema from source schema export.
Adds deleted_at column to all tables and removes excluded tables.
Replaces source database name with target database name.
"""

import re
import sys
import os

def process_schema(input_file, output_file, excluded_tables, source_db, target_db):
    """Process SQL schema file."""
    with open(input_file, 'r') as f:
        content = f.read()

    # Replace source database name with target database name
    content = content.replace(f'DATABASE `{source_db}`', f'DATABASE `{target_db}`')
    content = content.replace(f'USE `{source_db}`', f'USE `{target_db}`')
    content = re.sub(rf'\b{source_db}\b', target_db, content)

    # Split into statements
    statements = content.split(';')

    modified_statements = []
    current_table = None
    skip_table = False

    for statement in statements:
        statement = statement.strip()
        if not statement:
            continue

        # Check if this is a CREATE TABLE statement
        create_match = re.search(r'CREATE TABLE [`\"]?(\w+)[`\"]?', statement, re.IGNORECASE)
        if create_match:
            current_table = create_match.group(1)
            skip_table = current_table in excluded_tables

            if skip_table:
                print(f"Skipping excluded table: {current_table}")
                continue

            # Add deleted_at column before the closing parenthesis
            # Find the last comma before closing parenthesis
            if re.search(r'\)', statement):
                # Add deleted_at column
                statement = re.sub(
                    r'(\s*\)\s*ENGINE)',
                    r',\n  `deleted_at` TIMESTAMP NULL DEFAULT NULL,\n  KEY `idx_deleted_at` (`deleted_at`)\n) ENGINE',
                    statement,
                    flags=re.IGNORECASE
                )
                print(f"Added deleted_at to table: {current_table}")

        # Skip DROP/CREATE for triggers, procedures, functions
        if any(keyword in statement.upper() for keyword in ['CREATE TRIGGER', 'CREATE PROCEDURE', 'CREATE FUNCTION', 'CREATE EVENT']):
            print(f"Skipping: {statement[:50]}...")
            continue

        # Skip statements for excluded tables
        if skip_table:
            continue

        modified_statements.append(statement)

    # Write output
    with open(output_file, 'w') as f:
        f.write('-- Target Database Schema\n')
        f.write('-- Generated from source with modifications for CDC\n')
        f.write('-- Added: deleted_at column to all tables\n')
        f.write(f'-- Excluded tables: {", ".join(excluded_tables)}\n\n')

        for stmt in modified_statements:
            if stmt.strip():
                f.write(stmt + ';\n\n')

    print(f"\nSchema prepared successfully: {output_file}")
    print(f"Total statements: {len(modified_statements)}")

if __name__ == '__main__':
    # Get database names from environment or use defaults
    source_db = os.getenv('SOURCE_DB_NAME', 'pos')
    target_db = os.getenv('TARGET_DB_NAME', 'pos_replica')

    excluded = ['recorded_order', 'lock', 'log']

    input_file = '../configs/source-schema.sql'
    output_file = '../configs/target-schema.sql'

    print(f"Source database: {source_db}")
    print(f"Target database: {target_db}")
    print(f"Excluded tables: {', '.join(excluded)}\n")

    process_schema(input_file, output_file, excluded, source_db, target_db)

