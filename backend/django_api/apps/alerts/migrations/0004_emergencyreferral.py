from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("patients", "0002_initial"),
        ("asha_workers", "0003_villagevisit"),
        ("alerts", "0003_alertnotification"),
    ]

    operations = [
        migrations.CreateModel(
            name="EmergencyReferral",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("symptoms", models.TextField(blank=True)),
                (
                    "severity",
                    models.CharField(
                        choices=[
                            ("normal", "Normal"),
                            ("moderate", "Moderate"),
                            ("critical", "Critical"),
                        ],
                        default="moderate",
                        max_length=20,
                    ),
                ),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("pending", "Pending"),
                            ("sent", "Sent"),
                            ("accepted", "Accepted"),
                            ("completed", "Completed"),
                        ],
                        default="sent",
                        max_length=20,
                    ),
                ),
                ("notes", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "asha_worker",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name="emergency_referrals",
                        to="asha_workers.ashaworker",
                    ),
                ),
                (
                    "patient",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="emergency_referrals",
                        to="patients.patient",
                    ),
                ),
            ],
        ),
    ]
