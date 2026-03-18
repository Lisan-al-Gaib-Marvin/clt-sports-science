"""
CLT Sports Science — Data Import Script (SQLAlchemy + PyMySQL)
===============================================================
Imports data from uncc_players_data.xlsx into an EXISTING MySQL database.

The database and tables must already exist in MySQL.
Run sports_science_schema.sql in MySQL Workbench first.

Prerequisites:
    pip install pymysql sqlalchemy pandas openpyxl

Usage:
    python load_to_mysql.py
"""

import pandas as pd
from sqlalchemy import create_engine, text

# =============================================================================
# CONFIG
# =============================================================================
USERNAME = "root"
PASSWORD = "your_password"
HOST = "localhost"
DATABASE = "uncc_fb_data"

FILE_PATH = "/Users/appadad/Downloads/uncc_players_data.xlsx"

# =============================================================================
# CONNECT to existing database
# =============================================================================
engine = create_engine(f"mysql+pymysql://{USERNAME}:{PASSWORD}@{HOST}/{DATABASE}")
print(f"Connected to '{DATABASE}'")

# =============================================================================
# CLEAR existing data (truncate in correct order — children first)
# =============================================================================
print("\nClearing existing data...")
with engine.connect() as conn:
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
    for table in ["tap_tests", "grip_tests", "gps_sessions",
                   "nordbord_tests", "cmj_tests", "bodyweights", "players"]:
        conn.execute(text(f"TRUNCATE TABLE {table}"))
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
    conn.commit()
print("  Tables cleared")

# =============================================================================
# READ ALL SHEETS
# =============================================================================
print(f"\nReading {FILE_PATH}...")

players = pd.read_excel(FILE_PATH, sheet_name="players")
bodyweights = pd.read_excel(FILE_PATH, sheet_name="bodyweights")
cmj_tests = pd.read_excel(FILE_PATH, sheet_name="cmj_tests")
nordbord_tests = pd.read_excel(FILE_PATH, sheet_name="nordbord_tests")
gps_sessions = pd.read_excel(FILE_PATH, sheet_name="gps_sessions")
grip_tests = pd.read_excel(FILE_PATH, sheet_name="grip_tests")
tap_tests = pd.read_excel(FILE_PATH, sheet_name="tap_tests")

# =============================================================================
# CLEAN — remove junk rows (header leaks, nulls)
# =============================================================================
print("\nCleaning data...")

players = players.dropna(subset=["player_name"])
bodyweights = bodyweights.dropna(subset=["player_id"])
cmj_tests = cmj_tests.dropna(subset=["player_id"])
nordbord_tests = nordbord_tests.dropna(subset=["player_id"])
gps_sessions = gps_sessions[gps_sessions["session_date"] != "Date"]
gps_sessions = gps_sessions.dropna(subset=["player_id"])
grip_tests = grip_tests.dropna(subset=["player_id"])
tap_tests = tap_tests.dropna(subset=["player_id"])

print("  Junk rows removed")

# =============================================================================
# IMPORT — append data into existing tables
# =============================================================================
print("\nImporting to MySQL...")

players.to_sql(name="players", con=engine, if_exists="append", index=False)
print(f"  players         → {len(players)} rows")

bodyweights.to_sql(name="bodyweights", con=engine, if_exists="append", index=False)
print(f"  bodyweights     → {len(bodyweights)} rows")

cmj_tests.to_sql(name="cmj_tests", con=engine, if_exists="append", index=False)
print(f"  cmj_tests       → {len(cmj_tests)} rows")

nordbord_tests.to_sql(name="nordbord_tests", con=engine, if_exists="append", index=False)
print(f"  nordbord_tests  → {len(nordbord_tests)} rows")

gps_sessions.to_sql(name="gps_sessions", con=engine, if_exists="append", index=False)
print(f"  gps_sessions    → {len(gps_sessions)} rows")

grip_tests.to_sql(name="grip_tests", con=engine, if_exists="append", index=False)
print(f"  grip_tests      → {len(grip_tests)} rows")

tap_tests.to_sql(name="tap_tests", con=engine, if_exists="append", index=False)
print(f"  tap_tests       → {len(tap_tests)} rows")

# =============================================================================
# VERIFY
# =============================================================================
print("\nVerification:")
with engine.connect() as conn:
    for table in ["players", "bodyweights", "cmj_tests", "nordbord_tests",
                   "gps_sessions", "grip_tests", "tap_tests"]:
        result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
        count = result.scalar()
        print(f"  {table:20s} {count:>6} rows")

total = len(players) + len(bodyweights) + len(cmj_tests) + len(nordbord_tests) + len(gps_sessions) + len(grip_tests) + len(tap_tests)
print(f"\nDone. {total} total rows imported into '{DATABASE}'")
