import sqlite3
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
conn = sqlite3.connect(os.path.join(BASE_DIR, 'db.sqlite3'))
cur = conn.cursor()

cur.execute("""
    SELECT n.id, n.title, COALESCE(SUM(c.word_count), 0) as total_wc
    FROM novel n
    LEFT JOIN chapter c ON c.novel_id = n.id
    WHERE n.word_count = 0 AND n.status != 2
    GROUP BY n.id
""")
rows = cur.fetchall()

print(f"需要修复字数的小说: {len(rows)} 本\n")

fixed = 0
for nid, title, total in rows:
    if total > 0:
        cur.execute("UPDATE novel SET word_count=? WHERE id=?", (total, nid))
        print(f"  [{nid}] {title}: 0 -> {total}字")
        fixed += 1
    else:
        print(f"  [{nid}] {title}: 章节总字数也是0，跳过")

conn.commit()
print(f"\n修复完成: {fixed} 本")

cur.close()
conn.close()