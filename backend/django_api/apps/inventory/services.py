from django.db import transaction
from django.db.models import F
from rest_framework.exceptions import ValidationError

from .models import StockBatch, StockMovement


def apply_stock_adjustment(
    *,
    batch: StockBatch,
    action: str,
    quantity: int,
    actor,
    client_id,
    reason: str = '',
    invoice_no: str = '',
    notes: str = '',
    supplier_name: str = '',
):
    """
    Idempotent stock mutation keyed by client_id.
    Returns (movement, created: bool).
    """
    if quantity is None or int(quantity) < 0:
        raise ValidationError({'quantity': 'Quantity must be a non-negative integer.'})
    quantity = int(quantity)

    existing = StockMovement.objects.filter(client_id=client_id).select_related(
        'batch', 'batch__catalog', 'batch__facility',
    ).first()
    if existing:
        return existing, False

    if action not in dict(StockMovement.ACTION_CHOICES):
        raise ValidationError({'action': f'Invalid action: {action}'})

    with transaction.atomic():
        locked = StockBatch.objects.select_for_update().get(pk=batch.pk)
        previous = locked.quantity

        if action == 'add':
            new_qty = previous + quantity
        elif action in ('remove', 'disposal', 'return'):
            if quantity > previous:
                raise ValidationError({
                    'quantity': f'Cannot remove {quantity}; only {previous} units available.',
                })
            new_qty = previous - quantity
        elif action == 'adjust':
            # Absolute set
            new_qty = quantity
            quantity = abs(new_qty - previous)
        else:
            raise ValidationError({'action': f'Unsupported action: {action}'})

        locked.quantity = new_qty
        locked.save(update_fields=['quantity', 'updated_at'])

        movement = StockMovement.objects.create(
            batch=locked,
            action=action,
            quantity=quantity,
            previous_quantity=previous,
            new_quantity=new_qty,
            reason=reason or '',
            invoice_no=invoice_no or '',
            notes=notes or '',
            supplier_name=supplier_name or '',
            actor=actor,
            client_id=client_id,
        )
        return movement, True


def facility_stock_health(facility):
    """Aggregate low / out / expiring counts for map markers."""
    from django.utils import timezone
    from datetime import timedelta

    today = timezone.localdate()
    soon = today + timedelta(days=30)
    batches = StockBatch.objects.filter(facility=facility)
    total = batches.count()
    out = batches.filter(quantity=0).count()
    low = batches.filter(quantity__gt=0, quantity__lte=F('reorder_level')).count()
    expiring = batches.filter(expiry_date__gte=today, expiry_date__lte=soon, quantity__gt=0).count()
    expired = batches.filter(expiry_date__lt=today).count()
    return {
        'total_batches': total,
        'out_of_stock': out,
        'low_stock': low,
        'expiring_soon': expiring,
        'expired': expired,
    }
