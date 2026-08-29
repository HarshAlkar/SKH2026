from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from . import service


class TrustShieldVerifyView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        claim = request.data.get('claim') or ''
        context = request.data.get('context') or 'healthcare'
        offline = bool(request.data.get('offline'))
        language = request.data.get('language') or 'en'
        return Response(service.verify_claim(claim, context=context, offline=offline, language=language))


class TrustShieldReportView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        user = request.user if getattr(request.user, 'is_authenticated', False) else None
        payload = {
            'claim': request.data.get('claim') or '',
            'status': request.data.get('status') or '',
            'riskLevel': request.data.get('riskLevel') or '',
            'explanation': request.data.get('explanation') or '',
            'user_id': getattr(user, 'id', None),
            'role': getattr(user, 'role', None),
        }
        return Response(service.add_report(payload), status=201)

    def get(self, request):
        return Response({'results': service.list_reports()})


class TrustShieldDemoClaimsView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({
            'demos': [
                {
                    'label': 'Antibiotics cure dengue',
                    'claim': 'WhatsApp says antibiotics cure dengue in two days.',
                },
                {
                    'label': 'Household diabetes cure',
                    'claim': 'Drinking a particular household substance is a guaranteed cure for diabetes.',
                },
                {
                    'label': 'Handwashing helps',
                    'claim': 'Washing hands with soap helps reduce infection risk.',
                },
                {
                    'label': 'Obscure claim',
                    'claim': 'A rare mineral tea reverses all heart disease overnight without doctors.',
                },
                {
                    'label': 'Livestock antibiotics tip',
                    'claim': 'Give antibiotics immediately to all cattle if milk drop starts.',
                },
            ]
        })
