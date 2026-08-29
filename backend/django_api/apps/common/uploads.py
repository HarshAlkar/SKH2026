"""Safe file upload validation — do not trust extension alone."""

import uuid

from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import UploadedFile
from PIL import Image


ALLOWED_IMAGE_FORMATS = {'jpeg', 'jpg', 'png', 'webp', 'gif'}
MAGIC_TO_EXT = {
    'jpeg': '.jpg',
    'png': '.png',
    'webp': '.webp',
    'gif': '.gif',
}


def _sniff_image_format(file_obj: UploadedFile) -> str | None:
    try:
        file_obj.seek(0)
        with Image.open(file_obj) as img:
            fmt = (img.format or '').lower()
        file_obj.seek(0)
        if fmt == 'jpeg':
            return 'jpeg'
        if fmt in ALLOWED_IMAGE_FORMATS:
            return fmt
    except Exception:
        try:
            file_obj.seek(0)
        except Exception:
            pass
    return None


def validate_image_upload(
    file_obj: UploadedFile,
    *,
    max_bytes: int = 3 * 1024 * 1024,
    max_width: int = 4096,
    max_height: int = 4096,
    allowed_formats: set | None = None,
) -> str:
    """
    Validate uploaded image. Returns safe extension (e.g. '.jpg').
    Raises ValidationError on failure.
    """
    allowed = allowed_formats or ALLOWED_IMAGE_FORMATS
    if not file_obj:
        raise ValidationError('No file provided.')

    name = getattr(file_obj, 'name', '') or ''
    if '..' in name or name.startswith('/') or '\\' in name:
        raise ValidationError('Invalid filename.')

    size = getattr(file_obj, 'size', None)
    if size is not None and size > max_bytes:
        raise ValidationError(f'File too large (max {max_bytes // (1024 * 1024)}MB).')

    kind = _sniff_image_format(file_obj)
    if not kind or kind not in allowed:
        raise ValidationError('File must be a valid JPEG, PNG, WebP, or GIF image.')

    try:
        file_obj.seek(0)
        with Image.open(file_obj) as img:
            w, h = img.size
            img.verify()
        file_obj.seek(0)
    except Exception as exc:
        raise ValidationError('Invalid or corrupted image.') from exc

    if w > max_width or h > max_height:
        raise ValidationError(f'Image dimensions too large (max {max_width}x{max_height}).')

    return MAGIC_TO_EXT.get(kind, f'.{kind}')


def safe_upload_name(extension: str, prefix: str = 'upload') -> str:
    ext = extension if extension.startswith('.') else f'.{extension}'
    return f'{prefix}_{uuid.uuid4().hex}{ext}'


def validate_document_upload(file_obj: UploadedFile, max_bytes: int = 5 * 1024 * 1024) -> str:
    """Allow images or PDF for verification docs; returns safe extension."""
    if not file_obj:
        raise ValidationError('No file provided.')
    name = getattr(file_obj, 'name', '') or ''
    if '..' in name or name.startswith('/') or name.startswith('\\'):
        raise ValidationError('Invalid filename.')

    size = getattr(file_obj, 'size', None)
    if size is not None and size > max_bytes:
        raise ValidationError(f'File too large (max {max_bytes // (1024 * 1024)}MB).')

    pos = file_obj.tell() if hasattr(file_obj, 'tell') else 0
    header = file_obj.read(8)
    file_obj.seek(pos)

    if header.startswith(b'%PDF'):
        return '.pdf'

    kind = _sniff_image_format(file_obj)
    if kind and kind in ALLOWED_IMAGE_FORMATS:
        return MAGIC_TO_EXT.get(kind, f'.{kind}')

    raise ValidationError('Document must be PDF or an image (JPEG/PNG/WebP/GIF).')
