#!/usr/bin/env python3
import sys
import json
from pathlib import Path
from pypdf import PdfReader
from pypdf.generic import DictionaryObject, NameObject


def parse_field_flags(flags_int: int) -> dict:
    """Decodes standard AcroForm bitwise field flags."""
    return {
        "read_only": bool(flags_int & (1 << 0)),
        "required": bool(flags_int & (1 << 1)),
        "no_export": bool(flags_int & (1 << 2)),
    }


def extract_font_info(field_dict: DictionaryObject) -> tuple[str | None, float | None]:
    """
    Extracts font name and font size from Default Appearance (/DA) string if available.
    Example /DA string: '/Helv 12 Tf 0 g' -> ('Helv', 12.0)
    """
    da = field_dict.get("/DA")
    if not da:
        return None, None

    da_str = str(da)
    parts = da_str.split()
    font_name = None
    font_size = None

    for i, part in enumerate(parts):
        if part == "Tf" and i >= 2:
            font_name = parts[i - 2].lstrip("/")
            try:
                font_size = float(parts[i - 1])
            except ValueError:
                font_size = None
            break

    return font_name, font_size


def extract_pdf_form_fields(pdf_path: str) -> list[dict]:
    """Parses a PDF file and extracts all AcroForm field details."""
    path = Path(pdf_path)
    if not path.exists():
        raise FileNotFoundError(f"PDF file not found at: {pdf_path}")

    reader = PdfReader(str(path))
    fields_data = []

    # Check if document contains form fields
    fields = reader.get_fields()
    if not fields:
        return fields_data

    # Map field definitions across pages
    for page_idx, page in enumerate(reader.pages):
        annotations = page.get("/Annots")
        if not annotations:
            continue

        for annot in annotations:
            annot_obj = annot.get_object()
            if not isinstance(annot_obj, DictionaryObject):
                continue

            # Ensure annotation is a Widget/Form Field
            if annot_obj.get("/Subtype") != "/Widget":
                continue

            field_name = annot_obj.get("/T")
            if not field_name:
                continue

            # Extract basic metadata
            field_type = str(annot_obj.get("/FT", "Unknown")).lstrip("/")
            val = annot_obj.get("/V")
            default_val = annot_obj.get("/DV")
            rect = annot_obj.get("/Rect")
            flags = int(annot_obj.get("/Ff", 0))

            font_name, font_size = extract_font_info(annot_obj)

            # Coordinates [Left, Bottom, Right, Top]
            rect_coords = [float(x) for x in rect] if rect else None
            bounds = None
            if rect_coords and len(rect_coords) == 4:
                bounds = {
                    "left": rect_coords[0],
                    "bottom": rect_coords[1],
                    "right": rect_coords[2],
                    "top": rect_coords[3],
                    "width": round(rect_coords[2] - rect_coords[0], 2),
                    "height": round(rect_coords[3] - rect_coords[1], 2),
                }

            field_info = {
                "field_name": str(field_name),
                "field_type": field_type,
                "page_number": page_idx + 1,
                "value": str(val) if val is not None else "",
                "default_value": str(default_val) if default_val is not None else "",
                "font_name": font_name,
                "font_size": font_size,
                "flags": parse_field_flags(flags),
                "bounds": bounds,
            }

            fields_data.append(field_info)

    return fields_data


def main():
    if len(sys.argv) < 2:
        print("Usage: python inspect_pdf_fields.py <path_to_pdf> [--json]")
        sys.exit(1)

    pdf_file = sys.argv[1]
    as_json = "--json" in sys.argv

    try:
        results = extract_pdf_form_fields(pdf_file)

        if not results:
            print(f"No AcroForm fields detected in '{pdf_file}'.")
            return

        if as_json:
            print(json.dumps(results, indent=2))
        else:
            print("=" * 70)
            print(f" PDF FORM FIELD REPORT: {Path(pdf_file).name}")
            print(f" Total Fields Extracted: {len(results)}")
            print("=" * 70)

            for idx, field in enumerate(results, start=1):
                print(f"\n[{idx}] Field Name: '{field['field_name']}'")
                print(f"    ├── Type         : {field['field_type']}")
                print(f"    ├── Page         : {field['page_number']}")
                print(f"    ├── Value        : '{field['value']}'")
                print(f"    ├── Default Value: '{field['default_value']}'")
                print(f"    ├── Font Name    : {field['font_name'] or 'N/A'}")
                print(f"    ├── Font Size    : {field['font_size'] or 'N/A'}")
                print(f"    ├── Flags        : ReadOnly={field['flags']['read_only']}, Required={field['flags']['required']}")
                if field['bounds']:
                    b = field['bounds']
                    print(f"    └── Coordinates  : Page {field['page_number']} [L:{b['left']}, B:{b['bottom']}, W:{b['width']}, H:{b['height']}]")
                else:
                    print("    └── Coordinates  : N/A")

    except Exception as ex:
        print(f"Error parsing PDF: {ex}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()