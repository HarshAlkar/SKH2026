from rest_framework import serializers

from .models import (
    HealthcareFacility,
    MedicalStaffProfile,
    MedicineCatalog,
    Supplier,
    StockBatch,
    StockMovement,
)
from .services import apply_stock_adjustment, facility_stock_health


class HealthcareFacilitySerializer(serializers.ModelSerializer):
    stock_health = serializers.SerializerMethodField()

    class Meta:
        model = HealthcareFacility
        fields = [
            'id', 'name', 'facility_type', 'village', 'district',
            'latitude', 'longitude', 'is_active', 'created_at', 'stock_health',
        ]
        read_only_fields = ['created_at']

    def get_stock_health(self, obj):
        return facility_stock_health(obj)


class MedicineCatalogSerializer(serializers.ModelSerializer):
    display_name = serializers.SerializerMethodField()

    class Meta:
        model = MedicineCatalog
        fields = [
            'id', 'sku', 'name', 'form', 'strength', 'category',
            'unit', 'is_active', 'display_name', 'created_at',
        ]
        read_only_fields = ['created_at']

    def get_display_name(self, obj):
        return obj.display_name


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = ['id', 'name', 'contact', 'notes', 'is_active', 'created_at']
        read_only_fields = ['created_at']


class StockBatchSerializer(serializers.ModelSerializer):
    medicine_name = serializers.CharField(source='catalog.display_name', read_only=True)
    sku = serializers.CharField(source='catalog.sku', read_only=True)
    category = serializers.CharField(source='catalog.category', read_only=True)
    unit = serializers.CharField(source='catalog.unit', read_only=True)
    facility_name = serializers.CharField(source='facility.name', read_only=True)
    facility_village = serializers.CharField(source='facility.village', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True, default=None)
    status = serializers.CharField(read_only=True)
    days_to_expiry = serializers.IntegerField(read_only=True)

    class Meta:
        model = StockBatch
        fields = [
            'id', 'facility', 'facility_name', 'facility_village', 'catalog',
            'medicine_name', 'sku', 'category', 'unit', 'batch_no', 'quantity',
            'expiry_date', 'reorder_level', 'supplier', 'supplier_name',
            'status', 'days_to_expiry', 'updated_at', 'created_at',
        ]
        read_only_fields = ['updated_at', 'created_at']


class StockMovementSerializer(serializers.ModelSerializer):
    medicine_name = serializers.CharField(source='batch.catalog.display_name', read_only=True)
    batch_no = serializers.CharField(source='batch.batch_no', read_only=True)
    facility_name = serializers.CharField(source='batch.facility.name', read_only=True)
    actor_name = serializers.SerializerMethodField()

    class Meta:
        model = StockMovement
        fields = [
            'id', 'batch', 'batch_no', 'medicine_name', 'facility_name',
            'action', 'quantity', 'previous_quantity', 'new_quantity',
            'reason', 'invoice_no', 'notes', 'supplier_name',
            'actor', 'actor_name', 'client_id', 'created_at',
        ]
        read_only_fields = [
            'previous_quantity', 'new_quantity', 'actor', 'created_at',
        ]

    def get_actor_name(self, obj):
        if not obj.actor:
            return None
        return obj.actor.name or obj.actor.username


class StockAdjustSerializer(serializers.Serializer):
    batch_id = serializers.IntegerField(required=False)
    facility_id = serializers.IntegerField(required=False)
    catalog_id = serializers.IntegerField(required=False)
    batch_no = serializers.CharField(required=False, allow_blank=True)
    expiry_date = serializers.DateField(required=False)
    reorder_level = serializers.IntegerField(required=False, min_value=0)
    action = serializers.ChoiceField(choices=[c[0] for c in StockMovement.ACTION_CHOICES])
    quantity = serializers.IntegerField(min_value=0)
    client_id = serializers.UUIDField()
    reason = serializers.CharField(required=False, allow_blank=True, default='')
    invoice_no = serializers.CharField(required=False, allow_blank=True, default='')
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    supplier_name = serializers.CharField(required=False, allow_blank=True, default='')
    supplier_id = serializers.IntegerField(required=False, allow_null=True)

    def validate(self, attrs):
        batch_id = attrs.get('batch_id')
        if batch_id:
            try:
                attrs['batch'] = StockBatch.objects.select_related(
                    'catalog', 'facility', 'supplier',
                ).get(pk=batch_id)
            except StockBatch.DoesNotExist:
                raise serializers.ValidationError({'batch_id': 'Batch not found.'})
            return attrs

        facility_id = attrs.get('facility_id')
        catalog_id = attrs.get('catalog_id')
        batch_no = (attrs.get('batch_no') or '').strip()
        expiry_date = attrs.get('expiry_date')
        if not all([facility_id, catalog_id, batch_no, expiry_date]):
            raise serializers.ValidationError(
                'Provide batch_id, or facility_id + catalog_id + batch_no + expiry_date to create a batch.'
            )
        try:
            facility = HealthcareFacility.objects.get(pk=facility_id, is_active=True)
        except HealthcareFacility.DoesNotExist:
            raise serializers.ValidationError({'facility_id': 'Facility not found.'})
        try:
            catalog = MedicineCatalog.objects.get(pk=catalog_id, is_active=True)
        except MedicineCatalog.DoesNotExist:
            raise serializers.ValidationError({'catalog_id': 'Medicine not found.'})

        supplier = None
        sid = attrs.get('supplier_id')
        if sid:
            supplier = Supplier.objects.filter(pk=sid).first()

        batch, _ = StockBatch.objects.get_or_create(
            facility=facility,
            catalog=catalog,
            batch_no=batch_no,
            defaults={
                'expiry_date': expiry_date,
                'reorder_level': attrs.get('reorder_level', 20),
                'quantity': 0,
                'supplier': supplier,
            },
        )
        attrs['batch'] = batch
        return attrs

    def create(self, validated_data):
        batch = validated_data['batch']
        movement, created = apply_stock_adjustment(
            batch=batch,
            action=validated_data['action'],
            quantity=validated_data['quantity'],
            actor=self.context['request'].user,
            client_id=validated_data['client_id'],
            reason=validated_data.get('reason', ''),
            invoice_no=validated_data.get('invoice_no', ''),
            notes=validated_data.get('notes', ''),
            supplier_name=validated_data.get('supplier_name', ''),
        )
        return {'movement': movement, 'created': created}


class MedicalStaffProfileSerializer(serializers.ModelSerializer):
    facility_detail = HealthcareFacilitySerializer(source='facility', read_only=True)
    name = serializers.CharField(source='user.name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = MedicalStaffProfile
        fields = ['id', 'user', 'name', 'username', 'facility', 'facility_detail', 'designation']
