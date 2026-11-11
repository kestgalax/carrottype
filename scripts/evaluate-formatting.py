#!/usr/bin/env python3
"""Opt-in synthetic cleanup evaluation against an ALREADY installed model. Never downloads.
Responses/latencies are observations for human quality review, not a semantic pass/fail test.
Uses helper v3 path jail and pinned local package. No app/microphone/clipboard/statistics access.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--helper', type=Path, required=True)
parser.add_argument('--model-directory', type=Path, required=True)
parser.add_argument('--mode', choices=['smart', 'gemma'], required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
if not args.helper.is_file() or not (args.model_directory / 'config.json').is_file():
    raise SystemExit('Expected existing built helper and installed model')
cases = json.loads((Path(__file__).parent / 'fixtures/formatting-quality.json').read_text())
results = []
for case in cases:
    request = dict(v=3, mode=args.mode, modelDirectory=str(args.model_directory.resolve()),
                   purpose='dictation', text=case['text'] * case.get('repeat', 1) + case.get('suffix', ''),
                   dictationRules=dict(removeFillers=True, removeRepetitions=True,
                                       applySelfCorrections=True, paragraphs=False, customRules='') | case.get('rules', {}))
    if 'instructions' in case:
        request.pop('dictationRules')
        request.update(purpose='transform', instructions=case['instructions'])
    start = time.monotonic()
    process = subprocess.run([str(args.helper.resolve())], input=json.dumps(request, ensure_ascii=False),
                             text=True, capture_output=True, timeout=120)
    response = json.loads(process.stdout)
    if response.get('v') != 3:
        raise SystemExit('Incompatible helper response')
    result = dict(case=case['id'], seconds=round(time.monotonic() - start, 2), response=response)
    results.append(result)
    print(json.dumps(result, ensure_ascii=False), flush=True)
args.output.write_text(json.dumps(dict(mode=args.mode, results=results), ensure_ascii=False, indent=2) + '\n')
