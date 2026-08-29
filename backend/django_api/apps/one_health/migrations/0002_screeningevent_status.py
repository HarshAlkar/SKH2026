from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('one_health', '0001_one_health_and_vet'),
    ]

    operations = [
        migrations.AddField(
            model_name='screeningevent',
            name='status',
            field=models.CharField(
                choices=[('released', 'Released to history'), ('held', 'Held in TEMP vault')],
                db_index=True,
                default='released',
                max_length=20,
            ),
        ),
    ]
