"""
Django settings for VitalReach / Gramin Health Connect.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

try:
    from dotenv import load_dotenv
    load_dotenv(BASE_DIR / '.env')
except Exception:
    pass


DEBUG = os.environ.get('DEBUG', 'True').lower() in ('1', 'true', 'yes')

_INSECURE_FALLBACK_KEY = 'django-insecure-a4c^3j_@1k@po*kh&5e8i444+@xw&o(18vyapdmcc^m))g1f-!'
SECRET_KEY = os.environ.get('SECRET_KEY', _INSECURE_FALLBACK_KEY if DEBUG else '')

if not DEBUG:
    if not SECRET_KEY or SECRET_KEY.startswith('django-insecure-') or SECRET_KEY == 'change-me-in-production':
        raise RuntimeError(
            'SECRET_KEY must be set to a strong unique value when DEBUG=False.'
        )

_default_hosts = 'localhost,127.0.0.1' if not DEBUG else '*'
ALLOWED_HOSTS = [
    h.strip()
    for h in os.environ.get('ALLOWED_HOSTS', _default_hosts).split(',')
    if h.strip()
]
if not DEBUG and '*' in ALLOWED_HOSTS:
    raise RuntimeError('ALLOWED_HOSTS must not contain * when DEBUG=False.')
# .env often lists only localhost; phones on Wi-Fi use the PC LAN IP and would
# otherwise get DisallowedHost (a huge HTML 400 that looks like a timeout).
if DEBUG and '*' not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append('*')

_render_host = os.environ.get('RENDER_EXTERNAL_HOSTNAME')
if _render_host and _render_host not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(_render_host)

CSRF_TRUSTED_ORIGINS = [
    o.strip()
    for o in os.environ.get('CSRF_TRUSTED_ORIGINS', '').split(',')
    if o.strip()
]
_render_url = os.environ.get('RENDER_EXTERNAL_URL')
if _render_url and _render_url not in CSRF_TRUSTED_ORIGINS:
    CSRF_TRUSTED_ORIGINS.append(_render_url)

if os.environ.get('DATABASE_URL') or not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Production transport / cookie hardening
if not DEBUG:
    SECURE_SSL_REDIRECT = os.environ.get('SECURE_SSL_REDIRECT', 'True').lower() in ('1', 'true', 'yes')
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = int(os.environ.get('SECURE_HSTS_SECONDS', '31536000'))
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
else:
    SECURE_SSL_REDIRECT = False

SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'
CSRF_COOKIE_SAMESITE = 'Lax'
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = 'same-origin'
X_FRAME_OPTIONS = 'DENY'

# Auth / OTP / AI
EXPOSE_OTP_FOR_DEV = os.environ.get('EXPOSE_OTP_FOR_DEV', '0').lower() in ('1', 'true', 'yes')
TOKEN_TTL_HOURS = int(os.environ.get('TOKEN_TTL_HOURS', '72'))
GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '').strip()
SYNC_TIMESTAMP_MAX_SKEW_DAYS = int(os.environ.get('SYNC_TIMESTAMP_MAX_SKEW_DAYS', '30'))
SIGNALING_ALLOWED_ORIGINS = [
    o.strip()
    for o in os.environ.get('SIGNALING_ALLOWED_ORIGINS', '').split(',')
    if o.strip()
]

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'apps.users',
    'apps.patients',
    'apps.doctors',
    'apps.consultations',
    'apps.prescriptions',
    'apps.symptom_analysis',
    'apps.alerts',
    'apps.medicine_tracker',
    'apps.health_records',
    'apps.asha_workers',
    'apps.chat',
    'apps.inventory.apps.InventoryConfig',
    'apps.admin_api.apps.AdminApiConfig',
    'apps.one_health.apps.OneHealthConfig',
    'apps.security_audit.apps.SecurityAuditConfig',
    'apps.ai_proxy.apps.AiProxyConfig',
    'rest_framework.authtoken',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'apps.common.authentication.ExpiringTokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': os.environ.get('THROTTLE_ANON', '60/min'),
        'user': os.environ.get('THROTTLE_USER', '300/min'),
        'login': os.environ.get('THROTTLE_LOGIN', '10/min'),
        'otp': os.environ.get('THROTTLE_OTP', '5/min'),
        'register': os.environ.get('THROTTLE_REGISTER', '10/min'),
        'analyze': os.environ.get('THROTTLE_ANALYZE', '30/min'),
        'upload': os.environ.get('THROTTLE_UPLOAD', '20/min'),
        'sync': os.environ.get('THROTTLE_SYNC', '60/min'),
        'gemini': os.environ.get('THROTTLE_GEMINI', '20/min'),
    },
    'EXCEPTION_HANDLER': 'apps.common.exceptions.safe_exception_handler',
}

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'apps.common.host.JsonDisallowedHostMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

try:
    import whitenoise  # noqa: F401
    MIDDLEWARE.insert(2, 'whitenoise.middleware.WhiteNoiseMiddleware')
except ImportError:
    pass

_cors_origins = [
    o.strip()
    for o in os.environ.get(
        'CORS_ALLOWED_ORIGINS',
        'http://localhost:5173,http://127.0.0.1:5173,http://localhost:3000,http://127.0.0.1:3000',
    ).split(',')
    if o.strip()
]
if DEBUG and os.environ.get('CORS_ALLOW_ALL', '').lower() in ('1', 'true', 'yes'):
    CORS_ALLOW_ALL_ORIGINS = True
else:
    CORS_ALLOW_ALL_ORIGINS = False
    CORS_ALLOWED_ORIGINS = _cors_origins
CORS_ALLOW_CREDENTIALS = True

DATA_UPLOAD_MAX_MEMORY_SIZE = 15 * 1024 * 1024
FILE_UPLOAD_MAX_MEMORY_SIZE = 15 * 1024 * 1024

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

_database_url = os.environ.get('DATABASE_URL', '').strip()
if _database_url:
    import dj_database_url
    DATABASES = {
        'default': dj_database_url.parse(_database_url, conn_max_age=600),
    }
else:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8},
    },
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Django password hashing (PBKDF2 by default) — NOT SHA-256.
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.PBKDF2PasswordHasher',
    'django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher',
    'django.contrib.auth.hashers.Argon2PasswordHasher',
    'django.contrib.auth.hashers.BCryptSHA256PasswordHasher',
    'django.contrib.auth.hashers.ScryptPasswordHasher',
]

AUTH_USER_MODEL = 'users.User'

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

_aws_bucket = os.environ.get('AWS_STORAGE_BUCKET_NAME', '').strip()
if _aws_bucket:
    AWS_STORAGE_BUCKET_NAME = _aws_bucket
    AWS_S3_REGION_NAME = os.environ.get('AWS_S3_REGION_NAME', 'us-east-1')
    AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID', '')
    AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
    AWS_S3_CUSTOM_DOMAIN = os.environ.get('AWS_S3_CUSTOM_DOMAIN', f'{_aws_bucket}.s3.amazonaws.com')
    # Private media — signed URLs via querystring auth
    AWS_DEFAULT_ACL = 'private'
    AWS_QUERYSTRING_AUTH = True
    AWS_QUERYSTRING_EXPIRE = int(os.environ.get('AWS_QUERYSTRING_EXPIRE', '3600'))
    DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'
    MEDIA_URL = f'https://{AWS_S3_CUSTOM_DOMAIN}/'

try:
    import whitenoise  # noqa: F401
    _static_backend = 'whitenoise.storage.CompressedStaticFilesStorage'
except ImportError:
    _static_backend = 'django.contrib.staticfiles.storage.StaticFilesStorage'

if _aws_bucket:
    STORAGES = {
        'default': {
            'BACKEND': 'storages.backends.s3boto3.S3Boto3Storage',
        },
        'staticfiles': {
            'BACKEND': _static_backend,
        },
    }
else:
    try:
        import whitenoise  # noqa: F401
        STORAGES = {
            'default': {
                'BACKEND': 'django.core.files.storage.FileSystemStorage',
            },
            'staticfiles': {
                'BACKEND': 'whitenoise.storage.CompressedStaticFilesStorage',
            },
        }
    except ImportError:
        pass

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO' if not DEBUG else 'DEBUG',
    },
    'loggers': {
        'apps.security_audit': {'level': 'INFO', 'handlers': ['console'], 'propagate': False},
    },
}
