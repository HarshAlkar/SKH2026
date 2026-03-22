import os
import django
from django.conf import settings

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db.migrations.loader import MigrationLoader
from django.db import connections

connection = connections['default']
loader = MigrationLoader(connection)

print("Disk Migrations for 'patients':")
# loader.disk_migrations is a dict with (app_label, migration_name) as keys
for app_label, migration_name in loader.disk_migrations.keys():
    if app_label == 'patients':
        print(f" - {migration_name}")
