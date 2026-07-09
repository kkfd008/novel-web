"""
Vercel Production Settings - Lean version optimized for Serverless cold start.
Removes admin, minimizes middleware, optimizes DB connection.
"""
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent

def env(key, default=''):
    return os.environ.get(key, default)

# === Security ===
SECRET_KEY = env('SECRET_KEY', 'vercel-production-change-me')
DEBUG = False
ALLOWED_HOSTS = ['*']

# === Lean INSTALLED APPS (removed admin, messages, staticfiles) ===
INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'rest_framework',
    'corsheaders',
    'novels',
]

# === Minimal MIDDLEWARE stack ===
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'novels.csrf_middleware.CsrfExemptApiMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
]

ROOT_URLCONF = 'novel_project.urls'

# No templates needed for API-only serverless
TEMPLATES = []

WSGI_APPLICATION = 'novel_project.wsgi.application'

# === Database: SQLite3 ===
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

AUTH_USER_MODEL = 'novels.User'

# Skip password validation on serverless (saves init time)
AUTH_PASSWORD_VALIDATORS = []

# Disable i18n (saves ~0.3s)
LANGUAGE_CODE = 'zh-hans'
TIME_ZONE = 'Asia/Shanghai'
USE_I18N = False
USE_TZ = False

# Static files not served by Django on Vercel (CDN handles it)
STATIC_URL = 'static/'
MEDIA_URL = '/media/'

# === CORS ===
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# === Auth ===
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'novels.auth.AdminUserBackend',
]

# Cookie-based sessions (no DB backend)
SESSION_ENGINE = 'django.contrib.sessions.backends.signed_cookies'
SESSION_COOKIE_SAMESITE = 'Lax'
SESSION_COOKIE_SECURE = False
SESSION_COOKIE_PATH = '/'
SESSION_COOKIE_DOMAIN = None
SESSION_COOKIE_HTTPONLY = False
CSRF_COOKIE_SAMESITE = 'None'
CSRF_COOKIE_SECURE = False

# === DRF (API only) ===
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 12,
    'PAGE_SIZE_QUERY_PARAM': 'page_size',
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer'],
    'DEFAULT_AUTHENTICATION_CLASSES': ['novels.auth.CsrfExemptSessionAuthentication'],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.AllowAny'],
}

# No static files collection on serverless
STATIC_ROOT = BASE_DIR / 'staticfiles'

# === Logging (required by Django setup) ===
LOGGING_CONFIG = 'logging.config.dictConfig'
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {'format': '%(levelname)s %(asctime)s %(module)s %(message)s'},
        'simple': {'format': '%(levelname)s %(message)s'},
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {'handlers': ['console'], 'level': 'INFO', 'propagate': False},
        'django.request': {'handlers': ['console'], 'level': 'WARNING', 'propagate': False},
        'novels': {'handlers': ['console'], 'level': 'DEBUG', 'propagate': False},
    },
}
