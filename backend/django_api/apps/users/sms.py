import json
import os
import urllib.parse
import urllib.request


def send_otp_sms(phone_number, otp_code):
    """Send OTP via MSG91 or Twilio when env credentials exist. Returns True on success."""
    message = f"Your VitalReach OTP is {otp_code}. Valid for 5 minutes."
    msg91_key = os.environ.get("MSG91_AUTH_KEY")
    if msg91_key:
        template_id = os.environ.get("MSG91_TEMPLATE_ID", "")
        payload = {
            "template_id": template_id,
            "short_url": "0",
            "recipients": [{"mobiles": f"91{phone_number}", "otp": otp_code}],
        }
        req = urllib.request.Request(
            "https://control.msg91.com/api/v5/flow/",
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "authkey": msg91_key,
                "Content-Type": "application/json",
                "accept": "application/json",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                return 200 <= resp.status < 300
        except Exception:
            return False

    sid = os.environ.get("TWILIO_ACCOUNT_SID")
    token = os.environ.get("TWILIO_AUTH_TOKEN")
    from_number = os.environ.get("TWILIO_FROM_NUMBER")
    if sid and token and from_number:
        body = urllib.parse.urlencode({
            "To": f"+91{phone_number}",
            "From": from_number,
            "Body": message,
        }).encode("utf-8")
        url = f"https://api.twilio.com/2010-04-01/Accounts/{sid}/Messages.json"
        req = urllib.request.Request(url, data=body, method="POST")
        credentials = f"{sid}:{token}".encode("ascii")
        import base64
        req.add_header("Authorization", "Basic " + base64.b64encode(credentials).decode("ascii"))
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                return 200 <= resp.status < 300
        except Exception:
            return False

    return False
