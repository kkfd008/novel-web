# 此脚本原用于从 SQLite 迁移数据到 MySQL。
# 项目已全面切换为 SQLite3，此脚本不再需要。
# 如需备份/恢复数据，请直接复制 db.sqlite3 文件。
import sqlite3, pymysql, sys

sqlite_path = r"d:\python damo\vue\novel_backend\db.sqlite3"
mysql_cfg = dict(host='localhost', port=3306, user='root',
                 password='200486qq.', database='novel_fiction', charset='utf8mb4')

scon = sqlite3.connect(sqlite_path)
scon.row_factory = sqlite3.Row
sc = scon.cursor()
mcon = pymysql.connect(**mysql_cfg)
mc = mcon.cursor()

TABLES = [
    ('user', ['id','password','last_login','is_superuser','username','first_name',
              'last_name','email','is_staff','is_active','date_joined','avatar',
              'phone','is_vip','vip_expire_date','is_author','pen_name','bio','created_at']),
    ('novel', ['id','title','author','author_user_id','cover','description',
               'category','tags','status','audit_status','word_count','view_count',
               'recommend','created_at','updated_at']),
    ('chapter', ['id','novel_id','title','content','chapter_order','word_count',
                 'publish_status','created_at','updated_at']),
    ('favorite', ['id','user_id','novel_id','created_at']),
    ('reading_progress', ['id','user_id','novel_id','chapter_id','position','updated_at']),
    ('bookmark', ['id','user_id','novel_id','chapter_id','position','note','created_at']),
    ('comment', ['id','novel_id','user_id','content','rating','created_at']),
]

def convert_val(v, col):
    if v is None: return None
    if col in ('last_login','date_joined','vip_expire_date','created_at','updated_at'):
        if isinstance(v, str): return v
        return v.strftime('%Y-%m-%d %H:%M:%S.%f') if hasattr(v,'strftime') else str(v)
    return v

total_migrated = 0

for tbl, cols in TABLES:
    sc.execute(f'SELECT * FROM {tbl}')
    rows = sc.fetchall()
    if not rows:
        print(f"  [SKIP] {tbl}: 0 rows")
        continue
    placeholders = ','.join(['%s']*len(cols))
    col_str = ','.join([f'`{c}`' for c in cols])
    insert_sql = f"INSERT INTO `{tbl}` ({col_str}) VALUES ({placeholders})"
    cnt = 0
    for row in rows:
        vals = [convert_val(row[c], c) for c in cols]
        try:
            mc.execute(insert_sql, vals)
            cnt += 1
        except Exception as e:
            err = str(e).split('\n')[0]
            print(f"  [WARN] {tbl} id={row['id']}: {err}")
    mcon.commit()
    total_migrated += cnt
    print(f"  [OK]   {tbl}: {cnt} rows migrated")

print(f"\nTotal migrated: {total_migrated} rows")

mc.close()
mcon.close()
sc.close()
scon.close()
