from apps.users.models import User, generate_abha_id

users = User.objects.all()
print(f"Converting ABHA IDs for {users.count()} users...")

for user in users:
    old_id = user.abha_id
    if not old_id or '-' not in old_id:
        # If it's 14 digits, format it.
        digits = ''.join(c for c in (old_id or '') if c.isdigit())
        if len(digits) != 14:
            # Re-generate it
            digits = ''.join(random.choices(string.digits, k=14)) if 'random' in globals() else '00000000000000'
            import random, string
            digits = ''.join(random.choices(string.digits, k=14))

        new_id = f"{digits[:4]}-{digits[4:8]}-{digits[8:12]}-{digits[12:]}"
        user.abha_id = new_id
        user.save()
        print(f"Updated {user.username}: {old_id} -> {new_id}")

print("Migration completed.")
