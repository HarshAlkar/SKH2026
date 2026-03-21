from apps.users.models import User
import random
import string

def gen():
    return ''.join(random.choices(string.digits, k=14))

users = User.objects.all()
count = 0
for u in users:
    if not u.abha_id:
        while True:
            nid = gen()
            if not User.objects.filter(abha_id=nid).exists():
                u.abha_id = nid
                u.save()
                count += 1
                break
print(f"Successfully assigned ABHA IDs to {count} users.")
