from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("asha_workers", "0003_villagevisit"),
        ("consultations", "0007_consultation_is_emergency"),
    ]

    operations = [
        migrations.AlterField(
            model_name="consultation",
            name="doctor",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name="consultations",
                to="doctors.doctor",
            ),
        ),
        migrations.AddField(
            model_name="consultation",
            name="asha_worker",
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name="consultations",
                to="asha_workers.ashaworker",
            ),
        ),
    ]
