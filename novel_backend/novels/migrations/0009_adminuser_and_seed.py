# Generated for AdminUser model

from django.db import migrations, models
import django.contrib.auth.hashers


class Migration(migrations.Migration):

    dependencies = [
        ('novels', '0008_violationrecord_operationlog_chapteruploadlog_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='AdminUser',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('username', models.CharField(max_length=50, unique=True, verbose_name='管理员账号')),
                ('password', models.CharField(max_length=128, verbose_name='密码')),
                ('real_name', models.CharField(blank=True, default='', max_length=50, verbose_name='真实姓名')),
                ('is_active', models.BooleanField(default=True, verbose_name='是否启用')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='创建时间')),
                ('last_login', models.DateTimeField(blank=True, null=True, verbose_name='最后登录时间')),
            ],
            options={
                'verbose_name': '管理员',
                'verbose_name_plural': '管理员',
                'db_table': 'admin_user',
            },
        ),
        migrations.RunSQL(
            sql="INSERT INTO admin_user (username, password, real_name, is_active, created_at) VALUES ('Admin', '%s', '系统管理员', 1, datetime('now'))" % django.contrib.auth.hashers.make_password('Admin@2026'),
            reverse_sql="DELETE FROM admin_user WHERE username = 'Admin'",
        ),
    ]
