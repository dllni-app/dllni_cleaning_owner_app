"""Validate frozen fixture hashes and JSON Schema without modifying sources.

Run: py -3 lib/presentation/worker_v2/contracts/tooling/verify_fixtures.py
Requires jsonschema (development verification only; no Flutter dependency).
"""

import hashlib
import json
import copy
from pathlib import Path
from datetime import datetime

from jsonschema import Draft202012Validator


root = Path(__file__).resolve().parent.parent
manifest = json.loads((root / "FIXTURE_HASHES.json").read_text(encoding="utf-8"))
version = (root / "VERSION").read_text(encoding="utf-8").strip()
assert version == manifest["version"] == "V2"
assert manifest["algorithm"] == "SHA256"

for name, expected in manifest["fixtures"].items():
    path = root / name
    actual = hashlib.sha256(path.read_bytes()).hexdigest().upper()
    assert actual == expected, f"Fixture changed without a versioned review: {name}"

fixture = json.loads((root / "fixtures/base_scenarios.json").read_text(encoding="utf-8"))
schema = json.loads((root / "fixtures/base_scenarios.schema.json").read_text(encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(fixture)
assert fixture["contractVersion"] == version
codes = [item["code"] for item in fixture["scenarios"]]
expected_codes = {
    "legacy_single_worker", "standard_kind_supervisor_v2", "independent_later_visit",
    "room_interval_overlap_gap", "ambiguous_bounds", "unaccepted_discoverable_offer",
    "customer_wait_rework", "valid_zero_money", "missing_allocation", "mixed_currencies",
    "deposit_restriction", "exact_session_dispute", "notification_selected_session",
    "offline_24h_expiry", "assignment_removed", "stale_409", "uncertain_timeout",
}
assert set(codes) == expected_codes and len(codes) == len(expected_codes)

by_code = {row["code"]: row for row in fixture["scenarios"]}
intervals = by_code["room_interval_overlap_gap"]["intervals"]
assert intervals[1]["start"] < intervals[0]["end"]  # overlap
assert intervals[1]["end"] < intervals[2]["start"]  # gap
assert by_code["notification_selected_session"]["scope"]["sessionId"] != by_code["exact_session_dispute"]["scope"]["sessionId"]
assert len(by_code["mixed_currencies"]["totalsByCurrency"]) == 2
assert by_code["missing_allocation"]["earning"]["authoritativeAmount"] is None

# Independently specified business semantics. Updating the fixture *and* JSON
# Schema together must never make an unsafe renamed/rewritten scenario pass.
# Columns: booking, selected session, assignment, owner, can execute,
# personal attendance capability, sanitized blocked reasons.
expected_semantics = {
    "legacy_single_worker": ("101", None, None, "worker", True, True, ()),
    "standard_kind_supervisor_v2": ("202", "301", "401", "supervisor", False, True, ("supervisor_managed",)),
    "independent_later_visit": ("202", "302", "402", "supervisor", False, True, ("not_yet_available",)),
    "room_interval_overlap_gap": ("202", "301", "401", "supervisor", False, True, ("execution_unavailable",)),
    "ambiguous_bounds": ("202", "301", "401", "supervisor", False, True, ("unavailable",)),
    "unaccepted_discoverable_offer": ("203", None, None, None, False, False, ("not_assigned",)),
    "customer_wait_rework": ("202", "301", "401", "supervisor", False, True, ("waiting_customer",)),
    "valid_zero_money": ("101", None, None, "worker", True, True, ()),
    "missing_allocation": ("202", "302", "402", "worker", True, True, ()),
    "mixed_currencies": ("101", None, None, "worker", True, True, ()),
    "deposit_restriction": ("101", None, None, "worker", False, True, ("financial_restriction",)),
    "exact_session_dispute": ("202", "301", "401", "worker", True, True, ()),
    "notification_selected_session": ("202", "302", "402", "worker", True, True, ()),
    "offline_24h_expiry": ("202", "301", "401", "worker", False, True, ("unavailable",)),
    "assignment_removed": ("202", "301", "401", "worker", False, False, ("not_assigned",)),
    "stale_409": ("202", "301", "401", "worker", False, True, ("state_changed",)),
    "uncertain_timeout": ("202", "301", "401", "worker", True, True, ()),
}
assert set(expected_semantics) == expected_codes
for code, (booking, session, assignment, owner, can_execute, attendance, reasons) in expected_semantics.items():
    row = by_code[code]
    assert row["scope"] == {k:v for k,v in
        (("bookingId", booking), ("sessionId", session), ("assignmentId", assignment)) if v is not None}, code
    assert row["owner"] == owner and row["executionCapability"] is can_execute, code
    assert row["canRecordAttendance"] is attendance, code
    assert tuple(row["blockedReasons"]) == reasons, code
    assert row["allowedActions"] == (["view", "start_travel", "arrive"] if code == "legacy_single_worker" else ["view"]), code

assert by_code["standard_kind_supervisor_v2"]["bookingKind"] == "standard"
assert by_code["ambiguous_bounds"]["startsAt"] is None and by_code["ambiguous_bounds"]["endsAt"] is None
assert by_code["unaccepted_discoverable_offer"]["discoverable"] is True and by_code["unaccepted_discoverable_offer"]["assigned"] is False
assert by_code["valid_zero_money"]["amount"] == {"decimal": "0.00", "currency": "SYP"}
assert by_code["missing_allocation"]["earning"]["reconciliationState"] == "incomplete"
assert by_code["mixed_currencies"]["totalsByCurrency"] == {"USD":"13.25", "SYP":"100.00"}
assert by_code["deposit_restriction"]["depositEligible"] is False
assert by_code["exact_session_dispute"]["disputeId"] == "500"
assert by_code["notification_selected_session"]["notificationId"] == "900"
assert by_code["offline_24h_expiry"]["cacheAgeSeconds"] > 86400
assert by_code["assignment_removed"]["denied"] is True
assert by_code["stale_409"]["commandOutcome"] == "rejected"
assert by_code["uncertain_timeout"]["commandOutcome"] == "outcomeUnknown"
for interval in intervals:
    assert datetime.fromisoformat(interval["start"].replace("Z", "+00:00")) < datetime.fromisoformat(interval["end"].replace("Z", "+00:00"))

def must_reject(mutator):
    candidate = copy.deepcopy(fixture)
    mutator(candidate)
    assert not Draft202012Validator(schema).is_valid(candidate), "Invalid fixture accepted"

must_reject(lambda d: d["scenarios"][0]["allowedActions"].append("admin_refund"))
must_reject(lambda d: d["scenarios"][0]["blockedReasons"].append("internal_supervisor_rate"))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "room_interval_overlap_gap").pop("intervals"))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "uncertain_timeout").update(code="surprise_case"))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "independent_later_visit")["scope"].pop("sessionId"))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "standard_kind_supervisor_v2").update(owner="worker", executionCapability=True, canRecordAttendance=False, blockedReasons=[]))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "customer_wait_rework").update(executionCapability=True, blockedReasons=[]))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "offline_24h_expiry").update(executionCapability=True))
must_reject(lambda d: d["scenarios"][0].update(code="independent_later_visit"))
must_reject(lambda d: d["scenarios"][0].update(denied=True))
must_reject(lambda d: next(r for r in d["scenarios"] if r["code"] == "room_interval_overlap_gap")["intervals"][0].update(start="not-a-dateZ"))
print("PASS: 3 SHA256 fixture hashes, V2, 17 independently guarded scenarios, 11 negative schema probes")
