import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('asha_workers', '0004_ashaworker_verification_ashadocument'),
        ('patients', '0002_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='patient',
            name='assigned_asha',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='assigned_patients',
                to='asha_workers.ashaworker',
            ),
        ),
    ]
