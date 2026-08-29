#!/usr/bin/env python3
"""Reformat linq2db-scaffolded .cs files:
- split single-line '[Column(...)] public ... { get; set; }' members into an attribute
  line followed by a property line, collapsing the alignment padding the scaffolder inserts
- convert the block-scoped namespace to a file-scoped namespace
Run after scaffolding, in place of relying on 'dotnet format' for these two changes
(the IDE0161 file-scoped-namespace analyzer is unreliable to invoke via 'dotnet format'
in this SDK, so it's handled directly here instead).
"""
import re
import sys
from pathlib import Path

# matches: <indent>[Column(...)] public ... { get; set; } [// comment]
MEMBER_RE = re.compile(r'^(?P<indent>[ \t]*)\[(?P<attr>Column\(.*?\))\](?P<sep>[ \t]+)(?P<rest>public .+)$')

NAMESPACE_RE = re.compile(r'^namespace\s+(?P<name>[\w.]+)\s*$')


def squeeze(text: str) -> str:
    text = re.sub(r'[ \t]{2,}', ' ', text)
    text = re.sub(r'\s+,', ',', text)
    text = re.sub(r'\(\s+', '(', text)
    text = re.sub(r'\s+\)', ')', text)
    return text.strip()


def split_member_lines(content: str) -> str:
    lines = content.splitlines()
    out = []
    for line in lines:
        match = MEMBER_RE.match(line)
        if match:
            indent = match.group('indent')
            out.append(f"{indent}[{squeeze(match.group('attr'))}]")
            out.append(f"{indent}{squeeze(match.group('rest'))}")
        else:
            out.append(line)
    return '\n'.join(out) + '\n'


def to_file_scoped_namespace(content: str) -> str:
    lines = content.splitlines()

    ns_index = next((i for i, line in enumerate(lines) if NAMESPACE_RE.match(line)), None)
    if ns_index is None or lines[ns_index + 1].strip() != '{':
        return content  # already file-scoped, or shape doesn't match what scaffolding produces

    closing_index = next(i for i in range(len(lines) - 1, ns_index, -1) if lines[i].strip() == '}')

    name = NAMESPACE_RE.match(lines[ns_index]).group('name')
    body = lines[ns_index + 2:closing_index]
    dedented = [line[1:] if line.startswith(('\t', ' ')) else line for line in body]

    new_lines = lines[:ns_index] + [f'namespace {name};', ''] + dedented + lines[closing_index + 1:]
    return '\n'.join(new_lines) + '\n'


def reformat(content: str) -> str:
    return to_file_scoped_namespace(split_member_lines(content))


def main() -> int:
    if len(sys.argv) != 2:
        print('usage: format-entities.py <output-directory>', file=sys.stderr)
        return 1

    target = Path(sys.argv[1])
    for cs_file in target.rglob('*.cs'):
        original = cs_file.read_text(encoding='utf-8')
        updated = reformat(original)
        if updated != original:
            cs_file.write_text(updated, encoding='utf-8')
            print(f'formatted: {cs_file}')

    return 0


if __name__ == '__main__':
    raise SystemExit(main())
