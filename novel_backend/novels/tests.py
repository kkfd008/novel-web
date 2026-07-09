from django.test import TestCase
from django.conf import settings
from django.db import connections


class DatabaseEngineTests(TestCase):
    """测试数据库引擎配置"""

    def test_default_database_engine_is_sqlite3(self):
        """默认数据库引擎应为 SQLite3"""
        engine = settings.DATABASES['default']['ENGINE']
        self.assertEqual(
            engine,
            'django.db.backends.sqlite3',
            f'期望数据库引擎为 django.db.backends.sqlite3，实际为 {engine}'
        )

    def test_database_connection_is_usable(self):
        """数据库连接应可用"""
        connection = connections['default']
        connection.ensure_connection()
        self.assertTrue(connection.is_usable())