import sqlite3
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
db_path = os.path.join(BASE_DIR, 'db.sqlite3')

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# SQLite3 建表（Django 迁移已自动管理，此处仅作为手动建表参考）
# 如需手动建表，请使用: python manage.py migrate

# 查看已有表
cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
tables = cur.fetchall()
print(f"Total tables: {len(tables)}")
for row in tables:
    t = row[0]
    cur.execute(f"SELECT COUNT(*) FROM [{t}]")
    cnt = cur.fetchone()[0]
    print(f"  {t}: {cnt} rows")

cur.close()
conn.close()