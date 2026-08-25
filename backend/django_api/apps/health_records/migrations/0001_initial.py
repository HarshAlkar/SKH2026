from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ("patients", "0002_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="HealthRecord",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("temperature", models.CharField(blank=True, max_length=10, null=True)),
                ("blood_pressure", models.CharField(blank=True, max_length=20, null=True)),
                ("blood_sugar", models.CharField(blank=True, max_length=10, null=True)),
                ("weight", models.CharField(blank=True, max_length=10, null=True)),
                ("symptoms", models.TextField(blank=True, null=True)),
                (
                    "risk_level",
                    models.CharField(
                        choices=[
                            ("normal", "Normal"),
                            ("moderate", "Moderate"),
                            ("highRisk", "High Risk"),
                        ],
                        default="normal",
                        max_length=20,
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "patient",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="health_records",
                        to="patients.patient",
                    ),
                ),
            ],
        ),
    ]
