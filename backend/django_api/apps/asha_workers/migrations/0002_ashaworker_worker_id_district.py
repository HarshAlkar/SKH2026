from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("asha_workers", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="ashaworker",
            name="district",
            field=models.CharField(blank=True, default="", max_length=100),
        ),
        migrations.AddField(
            model_name="ashaworker",
            name="worker_id",
            field=models.CharField(blank=True, default="", max_length=50),
        ),
    ]
