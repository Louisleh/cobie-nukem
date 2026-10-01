#!/usr/bin/env python3
"""Offline readiness-v1 integrity/math validator; never engine or taste approval."""
import argparse
import hashlib
import json
import pathlib
import re
from fractions import Fraction


class Invalid(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise Invalid(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical(record):
    return json.dumps(record, ensure_ascii=False, sort_keys=True,
                      separators=(',', ':'), allow_nan=False).encode('utf-8')


def is_sha(value):
    return isinstance(value, str) and re.fullmatch('[0-9a-f]{64}', value) is not None


def approval_ok(approval, evidence):
    require(isinstance(approval, dict), 'Positive human credit requires an approval record')
    require(isinstance(approval.get('reviewer'), str) and approval['reviewer'].strip(),
            'Human approval needs a named reviewer')
    require(approval.get('actual_human_review') is True,
            'Human approval must explicitly identify actual human review')
    require(isinstance(approval.get('scope'), str) and approval['scope'].strip(),
            'Human approval needs declared actual scope')
    eid = approval.get('evidence_id')
    require(eid in evidence, 'Human approval needs linked evidence')
    h = approval.get('approval_record_sha256')
    require(is_sha(h) and h == evidence[eid]['sha256'],
            'Human approval hash must match its linked approval evidence')


def validate(rubric, records, rubric_bytes, task_root=None):
    require(rubric['schema_version'] == '1.0', 'Unsupported rubric schema')
    require(rubric['rubric_version'] == 'readiness-v1', 'Unsupported rubric version')
    require(rubric['dimension_score_values'] == [0, 25, 50, 75, 100], 'v1 score anchors changed')
    require(rubric['formula']['rounding_step'] == 5, 'v1 rounding changed')
    require(set(rubric['general_anchors']) == {'0', '25', '50', '75', '100'}, 'Missing anchors')
    mids = ['V' + str(n) for n in range(1, 9)]
    definitions = rubric['milestones']
    require([m['id'] for m in definitions] == mids, 'Milestone order/scope changed')
    gate_names = set(rubric['gate_definitions'])
    all_dims = set()
    for m in definitions:
        dims = m['dimensions']
        require(len(dims) == 5, 'Every milestone requires five dimensions')
        require([d['id'] for d in dims] == [m['id'] + '.' + str(n) for n in range(1, 6)],
                'Dimension identity/order mismatch')
        require(all(type(d['weight']) is int and 0 < d['weight'] <= 100 for d in dims),
                'Weights must be positive integers')
        require(sum(d['weight'] for d in dims) == 100, 'Milestone weights must sum to 100')
        for d in dims:
            require(d['id'] not in all_dims, 'Duplicate dimension')
            all_dims.add(d['id'])
            require(d['claim_type'] in ('human', 'mechanical', 'artifact'), 'Invalid claim type')
            require(bool(d['acceptance_target'].strip()), 'Missing frozen target')
        require(set(m['stage_anchors']) == {'0', '25', '50', '75', '100'}, 'Missing stage anchors')
        ids = []
        for rule in m['cap_rules']:
            ids.append(rule['id'])
            if 'dynamic' in rule:
                require(m['id'] == 'V6' and rule['dynamic'] == 'minimum_readiness'
                        and rule['dependencies'] == mids[:5] and 'cap' not in rule,
                        'V6 weakest cap must be dynamic over V1–V5, never a fixed 15')
            else:
                require(type(rule['cap']) is int and rule['cap'] in (0, 25, 50, 75, 100), 'Invalid cap')
                require(len(rule['condition']) == 1, 'Cap needs one declared condition')
                op, keys = next(iter(rule['condition'].items()))
                require(op in ('any_true', 'any_false', 'any_unaccepted') and bool(keys), 'Invalid cap condition')
                require(set(keys) <= (set(mids) if op == 'any_unaccepted' else gate_names), 'Unknown cap gate')
                if op == 'any_unaccepted':
                    require(all(mids.index(k) < mids.index(m['id']) for k in keys), 'Dependency must precede milestone')
        require(len(ids) == len(set(ids)), 'Duplicate cap rule')
    require(len(all_dims) == 40, 'Exactly forty dimensions required')
    # Explicit dependency contract, in addition to generic rule evaluation.
    require(any(r.get('dynamic') == 'minimum_readiness' for r in definitions[5]['cap_rules']), 'V6 weakest cap missing')
    for i, deps in ((6, ['V6']), (7, ['V6', 'V7'])):
        require(any(r.get('cap') == 0 and r.get('condition') == {'any_unaccepted': deps}
                    for r in definitions[i]['cap_rules']), 'V7/V8 dependency gate missing')
    require(bool(records), 'History is empty')
    previous = None
    previous_scores = None
    checked = []
    rehashed = set()
    for n, record in enumerate(records, 1):
        require(record['schema_version'] == '1.0' and record['rubric_version'] == rubric['rubric_version'],
                'History schema/rubric mismatch')
        require(record['sequence'] == n and record['parent_record_hash'] == previous, 'Broken history parent/sequence')
        raw = dict(record); h = raw.pop('record_hash')
        require(is_sha(h) and digest(canonical(raw)) == h, 'Record hash mismatch')
        require(record['rubric_sha256'] == digest(rubric_bytes), 'Rubric byte identity mismatch')
        require(bool(record['assessed_utc']) and bool(record['assessment_author']), 'Missing dated assessor')
        for key in ('candidate_docs_tools', 'packaged_runtime', 'merged_main'):
            require(re.fullmatch('[0-9a-f]{40}', record['source_identity'][key]) is not None, 'Invalid source identity')
        evidence = record['evidence']
        require(bool(evidence), 'Evidence map is empty')
        for eid, item in evidence.items():
            require(is_sha(item['sha256']) and type(item['bytes']) is int and item['bytes'] >= 0, 'Invalid input identity')
            require(item['kind'] in ('git_blob', 'task_archive'), 'Unknown evidence locator')
            require(item['scope'].strip(), 'Missing evidence scope')
            rel = pathlib.PurePosixPath(item['frozen_task_archive_copy'])
            require(not rel.is_absolute() and '..' not in rel.parts, 'Archive locator must be portable and bounded')
            if task_root is not None:
                frozen = task_root / str(rel)
                b = frozen.read_bytes()
                require(len(b) == item['bytes'] and digest(b) == item['sha256'], 'Frozen input mismatch: ' + eid)
                rehashed.add((str(rel), item['sha256']))
        gates = record['gate_facts']
        require(set(gates) == gate_names, 'Missing/extra factual gate')
        for key, fact in gates.items():
            require(type(fact['value']) is bool, 'Gate facts must be booleans')
            require(bool(fact['reason'].strip()) and bool(fact['evidence_ids'])
                    and set(fact['evidence_ids']) <= set(evidence), 'Gate fact needs source-bound explanation')
        rows = record['milestones']
        require([m['id'] for m in rows] == mids, 'History milestone scope/order mismatch')
        computed = {}
        acceptance = {}
        for definition, row in zip(definitions, rows):
            mid = row['id']
            require(type(row['accepted']) is bool, 'Acceptance must be explicit boolean')
            require([d['id'] for d in row['dimensions']] == [d['id'] for d in definition['dimensions']], 'Assessment dimension mismatch')
            subtotal = Fraction(0)
            for d, assessment in zip(definition['dimensions'], row['dimensions']):
                s = assessment['assessment_score']
                require(type(s) is int and s in rubric['dimension_score_values'], 'Non-v1 dimension score')
                require(set(assessment['evidence_ids']) <= set(evidence), 'Unknown dimension evidence')
                require(bool(assessment['reason'].strip()), 'Missing credit/zero reason')
                require(bool(assessment['next_evidence_gate'].strip()), 'Missing next evidence gate')
                require(assessment['confidence']['evidence_support'] in ('low', 'medium', 'high')
                        and assessment['confidence']['human_quality'] in ('low', 'medium', 'high'), 'Invalid confidence label')
                if s > 0:
                    require(bool(assessment['evidence_ids']) and assessment['status'] == 'scoped_supported_credit', 'Unsupported positive credit')
                    if d['claim_type'] == 'human':
                        approval_ok(assessment.get('human_approval'), evidence)
                else:
                    require(assessment['status'] == 'unsupported_or_unperformed', 'Zero score needs unsupported/unperformed status')
                subtotal += Fraction(d['weight'] * s, 100)
            require(Fraction(str(row['weighted_subtotal'])) == subtotal, 'Weighted subtotal mismatch: ' + mid)
            caps = []
            for rule in definition['cap_rules']:
                if 'dynamic' in rule:
                    active, cap = True, min(computed[k] for k in rule['dependencies'])
                else:
                    op, keys = next(iter(rule['condition'].items()))
                    if op == 'any_true': active = any(gates[k]['value'] for k in keys)
                    elif op == 'any_false': active = any(not gates[k]['value'] for k in keys)
                    else: active = any(not acceptance[k] for k in keys)
                    cap = rule['cap']
                if active:
                    caps.append({'rule_id': rule['id'], 'cap': cap, 'reason': rule['reason']})
            require(row['applied_caps'] == caps, 'Observed caps mismatch: ' + mid)
            result = (min([subtotal] + [Fraction(c['cap']) for c in caps]) // 5) * 5
            require(type(row['readiness_index']) is int and row['readiness_index'] == result, 'Capped readiness mismatch: ' + mid)
            computed[mid] = int(result)
            if row['accepted']:
                approval_ok(row.get('acceptance_record'), evidence)
                if mid == 'V6':
                    require(all(acceptance[k] for k in mids[:5]), 'V6 accepted with unaccepted foundations')
                if mid == 'V7': require(acceptance['V6'], 'V7 accepted without V6')
                if mid == 'V8': require(acceptance['V6'] and acceptance['V7'], 'V8 accepted without V6/V7')
            acceptance[mid] = row['accepted']
        change = record['change']
        current_scores = [computed[k] for k in mids]
        require(change['previous_scores'] == previous_scores, 'Change log previous scores mismatch')
        deltas = None if previous_scores is None else [b-a for a,b in zip(previous_scores,current_scores)]
        require(change['score_deltas'] == deltas and bool(change['reason'].strip()), 'Change log deltas/reason mismatch')
        previous_scores, previous = current_scores, h
        checked.append({'sequence': n, 'record_hash': h, 'indices': current_scores})
    return {'status': 'PASS', 'records_checked': checked, 'frozen_inputs_rehashed': len(rehashed),
            'scope': 'Offline identity/math/policy validation; evidence semantics, actual humans and runtime approval require independent review.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    here = pathlib.Path(__file__).resolve().parent
    parser.add_argument('--rubric', type=pathlib.Path, default=here / 'rubric-v1.json')
    parser.add_argument('--history', type=pathlib.Path, default=here / 'history.jsonl')
    parser.add_argument('--task-root', type=pathlib.Path, help='Optional sealed task archive root for frozen input rehashing')
    args = parser.parse_args()
    try:
        rb = args.rubric.read_bytes()
        records = [json.loads(line) for line in args.history.read_text().splitlines() if line.strip()]
        print(json.dumps(validate(json.loads(rb), records, rb, args.task_root), indent=2))
    except (Invalid, KeyError, TypeError, ValueError, OSError) as e:
        parser.exit(1, 'FAIL: ' + str(e) + '\n')


if __name__ == '__main__':
    main()
