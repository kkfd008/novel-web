# ============================================================
#   墨香书阁 - 云服务器一键部署命令
#   系统: Ubuntu 22.04+
#   数据库: SQLite3 (零配置)
#   复制以下全部命令，粘贴到服务器终端执行
# ============================================================

# ===== 第1步：安装基础依赖 =====
apt-get update && apt-get install -y nginx python3 python3-venv python3-pip git curl nodejs npm ca-certificates

# ===== 第2步：克隆项目代码 =====
mkdir -p /www
cd /www
git clone https://github.com/qsd22763/novel-web.git temp_repo
mv temp_repo/novel_backend .
mv temp_repo/novel_frontend .
cp -r temp_repo/deploy . 2>/dev/null || mkdir -p deploy
rm -rf temp_repo

# ===== 第3步：Python 环境 + 后端依赖 =====
cd /www/novel_backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# ===== 第4步：配置 Django .env =====
cat > .env <<'EOF'
SECRET_KEY=change-this-to-a-random-secret-key
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1
EOF

# ===== 第5步：数据库迁移 + 收集静态文件 =====
python manage.py migrate
python manage.py collectstatic --noinput --clear 2>/dev/null || true

# ===== 第6步：构建前端 =====
cd /www/novel_frontend
npm install && npm run build

# ===== 第7步：配置 Nginx =====
sed 's|your-domain.com|localhost|g' /www/deploy/nginx.conf > /etc/nginx/sites-available/novel-web.conf
ln -sf /etc/nginx/sites-available/novel-web.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# ===== 第8步：配置 Gunicorn + Systemd 服务 =====
cp /www/deploy/gunicorn_config.py /www/novel_backend/
cp /www/deploy/novel-web.service /etc/systemd/system/
chown -R www-data:www-data /www
chmod -R 755 /www
systemctl daemon-reload
systemctl enable novel-web
systemctl start novel-web

# ===== 第9步：创建管理员账号 =====
cd /www/novel_backend && source venv/bin/activate && echo "=== 创建后台管理员 ===" && python manage.py createsuperuser

echo ""
echo "============================================="
echo "   部署完成！(SQLite3)"
echo "   数据库文件: /www/novel_backend/db.sqlite3"
echo "   备份: cp /www/novel_backend/db.sqlite3 /www/novel_backend/db.sqlite3.bak"
echo "============================================="

# ===== 查看状态 =====
echo ""
echo "--- Gunicorn 状态 ---"
systemctl status novel-web --no-pager | head -10
echo ""
echo "--- Nginx 状态 ---"
systemctl status nginx --no-pager | head -5