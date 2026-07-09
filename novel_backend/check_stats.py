import sqlite3
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
c = sqlite3.connect(os.path.join(BASE_DIR, 'db.sqlite3'))
r = c.cursor()
r.execute('SELECT id,title,category FROM novel WHERE id>=88 ORDER BY id')
rows = r.fetchall()
print(f'=== New novels: {len(rows)} ===')
for row in rows:
    print(f'{row[0]:3d} | {row[2]:4s} | {row[1]}')
r.execute('SELECT COUNT(*), COUNT(DISTINCT category) FROM novel WHERE id>=88')
tc, cc = r.fetchone()
print(f'\nTotal: {tc} books, {cc} categories')
c.close()