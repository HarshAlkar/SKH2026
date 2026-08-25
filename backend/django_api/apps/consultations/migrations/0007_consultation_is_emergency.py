from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("consultations", "0006_consultation_initiated_by_nullable_patient"),
    ]

    operations = [
        migrations.AddField(
            model_name="consultation",
            name="is_emergency",
            field=models.BooleanField(default=False),
        ),
    ]
