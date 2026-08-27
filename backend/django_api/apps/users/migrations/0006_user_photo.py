from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_unique_phone_number'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='photo',
            field=models.ImageField(blank=True, null=True, upload_to='profiles/'),
        ),
    ]
