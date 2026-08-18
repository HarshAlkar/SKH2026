from django.db import migrations, models


def normalize_phones(apps, schema_editor):
    User = apps.get_model("users", "User")
    User.objects.filter(phone_number="").update(phone_number=None)

    seen = {}
    for user in User.objects.exclude(phone_number__isnull=True).order_by("id"):
        phone = user.phone_number
        if phone in seen:
            suffix = str(user.id)
            trimmed = phone[: max(1, 15 - 1 - len(suffix))]
            user.phone_number = f"{trimmed}_{suffix}"[:15]
            user.save(update_fields=["phone_number"])
        else:
            seen[phone] = user.id


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0004_otpverification_delete_otp"),
    ]

    operations = [
        migrations.RunPython(normalize_phones, migrations.RunPython.noop),
        migrations.AlterField(
            model_name="user",
            name="phone_number",
            field=models.CharField(blank=True, max_length=15, null=True, unique=True),
        ),
    ]
