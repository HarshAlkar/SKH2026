from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("consultations", "0005_consultation_end_time"),
    ]

    operations = [
        migrations.AlterField(
            model_name="consultation",
            name="patient",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="consultations",
                to="patients.patient",
            ),
        ),
        migrations.AddField(
            model_name="consultation",
            name="initiated_by",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="started_consultations",
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]
