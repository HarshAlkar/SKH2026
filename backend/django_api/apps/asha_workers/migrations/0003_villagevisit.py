from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("patients", "0002_initial"),
        ("asha_workers", "0002_ashaworker_worker_id_district"),
    ]

    operations = [
        migrations.CreateModel(
            name="VillageVisit",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("visit_date", models.DateField()),
                ("visit_time", models.TimeField()),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("PENDING", "Pending"),
                            ("COMPLETED", "Completed"),
                            ("MISSED", "Missed"),
                        ],
                        default="PENDING",
                        max_length=15,
                    ),
                ),
                ("notes", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "asha_worker",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="visits",
                        to="asha_workers.ashaworker",
                    ),
                ),
                (
                    "patient",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="visits",
                        to="patients.patient",
                    ),
                ),
            ],
        ),
    ]
