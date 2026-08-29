# Generated manually for ASHA verification support

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('asha_workers', '0003_villagevisit'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='ashaworker',
            name='rejection_reason',
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='ashaworker',
            name='verification_status',
            field=models.CharField(
                choices=[
                    ('INCOMPLETE', 'Incomplete'),
                    ('PENDING_VERIFICATION', 'Pending Verification'),
                    ('VERIFIED', 'Verified'),
                    ('REJECTED', 'Rejected'),
                ],
                default='INCOMPLETE',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='ashaworker',
            name='verified_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='ashaworker',
            name='verified_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='verified_asha_workers',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.CreateModel(
            name='ASHADocument',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('document_type', models.CharField(max_length=50)),
                ('file', models.FileField(upload_to='asha_documents/')),
                ('uploaded_at', models.DateTimeField(auto_now_add=True)),
                (
                    'asha_worker',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='documents',
                        to='asha_workers.ashaworker',
                    ),
                ),
            ],
        ),
    ]
