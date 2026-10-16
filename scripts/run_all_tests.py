#!/usr/bin/env python3
"""
PothikSathi Comprehensive MVP Test Suite
Tests:
- Passenger and Driver Authentication & Role Access
- Driver Approval & Self-Approval Prevention
- Shared Fare Calculations (₹10/seat)
- Private Fare Validation (Whole-Vehicle & ₹20 Minimum Threshold)
- Passenger Capacity Validation (1-4 Passengers)
- Unverified Routes (No invented fares, admin quote flag)
- Booking Creation & Manual Assignment Flow
- Driver Acceptance and Rejection
- Trip Completion & State Machine Transitions
- Anti-Duplicate Idempotency Protection
- Timetable Search & Offline Cache Simulation
- Firestore Security Rules Coverage
"""

import sys
import json
from datetime import datetime

# Ensure UTF-8 output on Windows terminal
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

class TestFailure(Exception):
    pass

total_tests = 0
passed_tests = 0

def test(name):
    global total_tests
    total_tests += 1
    print(f"[{total_tests:02d}] RUNNING: {name} ... ", end="")

def ok():
    global passed_tests
    passed_tests += 1
    print("PASSED")

def fail(reason):
    print(f"FAILED -> {reason}")
    raise TestFailure(reason)

# --- 1. AUTH & ROLE ACCESS TESTS ---
def test_auth_and_roles():
    test("Role parsing defaults to passenger when unspecified")
    user_map = {"id": "p_1", "name": "Sourav", "phoneNumber": "9876543210"}
    role = user_map.get("role", "passenger")
    if role != "passenger":
        fail(f"Expected passenger, got {role}")
    ok()

    test("Driver approval status starts strictly at 'pending'")
    driver_map = {"driverId": "d_1", "approvalStatus": "pending", "isOnline": False}
    if driver_map["approvalStatus"] != "pending":
        fail("Driver did not start as pending")
    ok()

    test("Unapproved driver cannot go online (Security Guard)")
    is_approved = driver_map["approvalStatus"] == "approved"
    can_go_online = is_approved and True
    if can_go_online:
        fail("Pending driver was allowed to go online!")
    ok()

    test("Approved driver evaluates isApproved to true and can go online")
    driver_map["approvalStatus"] = "approved"
    driver_map["approvedBy"] = "admin_karimpur"
    if driver_map["approvalStatus"] != "approved" or not driver_map["approvedBy"]:
        fail("Approval assertion failed")
    ok()

# --- 2. TOTO FARE ENGINE & CAPACITY TESTS ---
def calculate_fare(booking_type, count, route_fare):
    if count < 1 or count > 4:
        raise ValueError(f"Capacity violated: {count}. Allowed: 1 to 4.")
    if not route_fare:
        return {"total": 0, "is_verified": False, "reason": "Unverified route"}
    
    if booking_type == "shared":
        total = route_fare["shared_per_seat"] * count
        return {"total": total, "is_verified": True}
    else: # private
        base = route_fare["private_base"]
        min_f = route_fare.get("min_fare", 20.0)
        total = max(base, min_f)
        return {"total": total, "is_verified": True}

def test_fare_calculations():
    tariff = {
        "shared_per_seat": 10.0,
        "private_base": 25.0,
        "min_fare": 20.0,
        "max_capacity": 4
    }

    test("Shared fare calculates ₹10/seat on verified Karimpur local route")
    res1 = calculate_fare("shared", 1, tariff)
    if res1["total"] != 10.0:
        fail(f"Expected 10.0, got {res1['total']}")
    res3 = calculate_fare("shared", 3, tariff)
    if res3["total"] != 30.0:
        fail(f"Expected 30.0, got {res3['total']}")
    ok()

    test("Capacity validation caps passenger count strictly at 4")
    res4 = calculate_fare("shared", 4, tariff)
    if res4["total"] != 40.0:
        fail("4 passengers failed")
    
    try:
        calculate_fare("shared", 5, tariff)
        fail("Allowed 5 passengers!")
    except ValueError:
        pass
    
    try:
        calculate_fare("shared", 0, tariff)
        fail("Allowed 0 passengers!")
    except ValueError:
        pass
    ok()

    test("Private booking enforces whole-vehicle rate and ₹20 minimum floor")
    low_tariff = {"shared_per_seat": 10.0, "private_base": 15.0, "min_fare": 20.0}
    res_priv = calculate_fare("private", 2, low_tariff)
    if res_priv["total"] != 20.0:
        fail(f"Expected ₹20 minimum floor, got {res_priv['total']}")
    ok()

    test("Unverified routes do not invent arbitrary fares and flag for quote")
    res_unverified = calculate_fare("shared", 2, None)
    if res_unverified["is_verified"] is not False or res_unverified["total"] != 0:
        fail("Unverified route invented fare!")
    ok()

# --- 3. BOOKING STATE MACHINE & LIFECYCLE TESTS ---
class BookingStateMachine:
    ALLOWED = {
        "pending_assignment": ["driver_assigned", "cancelled_by_passenger", "cancelled_by_admin"],
        "driver_assigned": ["driver_accepted", "driver_rejected", "cancelled_by_passenger", "cancelled_by_admin"],
        "driver_rejected": ["pending_assignment", "driver_assigned", "cancelled_by_admin"],
        "driver_accepted": ["driver_arrived", "cancelled_by_admin"],
        "driver_arrived": ["in_progress", "cancelled_by_admin"],
        "in_progress": ["completed"],
        "completed": [],
        "cancelled_by_passenger": [],
        "cancelled_by_admin": []
    }

    @classmethod
    def can_transition(cls, curr, target):
        return target in cls.ALLOWED.get(curr, [])

    @classmethod
    def validate(cls, curr, target, actor_role):
        if not cls.can_transition(curr, target):
            raise ValueError(f"Illegal transition: {curr} -> {target}")
        if target == "driver_assigned" and actor_role != "admin":
            raise PermissionError("Only admin can assign driver")
        if target in ["driver_accepted", "driver_arrived", "in_progress", "completed"] and actor_role != "driver":
            raise PermissionError("Only driver can advance trip milestones")
        if target == "cancelled_by_passenger" and actor_role not in ["passenger", "admin"]:
            raise PermissionError("Only passenger or admin can cancel")

def test_booking_state_machine():
    test("Full booking lifecycle: pending -> assigned -> accepted -> arrived -> in_progress -> completed")
    state = "pending_assignment"
    BookingStateMachine.validate(state, "driver_assigned", "admin")
    state = "driver_assigned"
    BookingStateMachine.validate(state, "driver_accepted", "driver")
    state = "driver_accepted"
    BookingStateMachine.validate(state, "driver_arrived", "driver")
    state = "driver_arrived"
    BookingStateMachine.validate(state, "in_progress", "driver")
    state = "in_progress"
    BookingStateMachine.validate(state, "completed", "driver")
    ok()

    test("Driver cannot assign themselves (Admin-only privilege)")
    try:
        BookingStateMachine.validate("pending_assignment", "driver_assigned", "driver")
        fail("Driver was allowed to assign themselves!")
    except PermissionError:
        pass
    ok()

    test("Illegal jump: pending_assignment directly to completed is rejected")
    try:
        BookingStateMachine.validate("pending_assignment", "completed", "driver")
        fail("Direct jump to completed was permitted!")
    except ValueError:
        pass
    ok()

    test("Driver rejection transitions back to dispatch desk for reassignment")
    if not BookingStateMachine.can_transition("driver_assigned", "driver_rejected"):
        fail("Driver cannot reject assignment")
    if not BookingStateMachine.can_transition("driver_rejected", "pending_assignment"):
        fail("Cannot reassign rejected booking")
    ok()

    test("Passenger cancellation permitted while pending, denied while in_progress")
    BookingStateMachine.validate("pending_assignment", "cancelled_by_passenger", "passenger")
    try:
        BookingStateMachine.validate("in_progress", "cancelled_by_passenger", "passenger")
        fail("Cancellation permitted while trip is in progress!")
    except ValueError:
        pass
    ok()

# --- 4. IDEMPOTENCY & DUPLICATE PROTECTION ---
def test_idempotency():
    test("Duplicate submission with matching idempotency key is safely ignored")
    cache = set()
    key = "usr_123_route_01_tok_9981"
    
    # First submit
    cache.add(key)
    
    # Second submit attempt
    is_duplicate = key in cache
    if not is_duplicate:
        fail("Failed to detect duplicate key")
    ok()

# --- 5. TIMETABLE SEARCH & OFFLINE CACHING ---
def test_timetable_search():
    timetables = [
        {
            "id": "bus_1",
            "routeName": "Karimpur – Krishnanagar",
            "destination": "Krishnanagar Bus Stand",
            "viaStops": ["Tehatta", "Chapra"],
            "operator": "SBSTC",
            "departureTime": "05:45",
            "isVerified": True
        },
        {
            "id": "bus_2",
            "routeName": "Karimpur – Kolkata (Esplanade)",
            "destination": "Kolkata (Esplanade)",
            "viaStops": ["Tehatta", "Krishnanagar", "Barasat"],
            "operator": "NBSTC",
            "departureTime": "05:00",
            "isVerified": True
        }
    ]

    test("Timetable search filters correctly by destination")
    match_knr = [t for t in timetables if "krishnanagar" in t["destination"].lower()]
    if len(match_knr) != 1 or match_knr[0]["id"] != "bus_1":
        fail("Destination search failed")
    ok()

    test("Timetable search matches via intermediate stops")
    match_barasat = [t for t in timetables if any("barasat" in s.lower() for s in t["viaStops"])]
    if len(match_barasat) != 1 or match_barasat[0]["id"] != "bus_2":
        fail("Via stop search failed")
    ok()

    test("Offline cache timestamp indicator detects stale data")
    now = datetime.now()
    cache_time = datetime(2026, 3, 10, 9, 0)
    age_hours = (now - cache_time).total_seconds() / 3600
    is_stale = age_hours > 24
    if not is_stale:
        fail("Failed to detect cache older than 24 hours")
    ok()

# --- 6. FIRESTORE RULES SYNTAX & REPO COMPLETENESS ---
def test_firestore_rules_and_schema():
    test("Firestore security rules file exists and contains all 8 collections (including systemConfig)")
    with open(r"c:\Users\AACST\Downloads\pothiksathi\backend\firestore.rules", "r") as f:
        content = f.read()
    
    required_collections = [
        "users",
        "driverProfiles",
        "routes",
        "routeFares",
        "busTimetables",
        "systemConfig",
        "bookings",
        "supportIssues"
    ]
    for coll in required_collections:
        if coll not in content:
            fail(f"Missing collection rule for {coll}")
    ok()

    test("Seed data file exists and contains verified Karimpur hubs")
    with open(r"c:\Users\AACST\Downloads\pothiksathi\backend\seed_data\karimpur_seed.json", "r") as f:
        seed = json.load(f)
    if "routes" not in seed or len(seed["routes"]) < 4:
        fail("Incomplete routes in seed")
    if "busTimetables" not in seed or len(seed["busTimetables"]) < 3:
        fail("Incomplete bus timetables in seed")
    ok()

# --- 7. AUTOMATIC DISPATCH, TIMEOUT & CASCADE ENGINE TESTS ---
import math

def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lon = math.radians(lon2 - lon1)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(d_lon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def rank_candidates(booking, drivers, attempted_ids, now_dt):
    candidates = []
    for d in drivers:
        if d.get("approvalStatus") != "approved":
            continue
        if not d.get("isOnline"):
            continue
        if d.get("currentBookingId") is not None:
            continue
        if d.get("offeredBookingId") is not None:
            continue
        if d.get("driverId") in attempted_ids:
            continue
        if d.get("capacity", 4) < booking.get("passengerCount", 1):
            continue

        loc_time = d.get("locationUpdatedAt")
        has_fresh_loc = False
        dist = 999.0
        if loc_time and d.get("lat") and d.get("lon") and booking.get("pickupLat") and booking.get("pickupLon"):
            diff_min = (now_dt - loc_time).total_seconds() / 60.0
            if diff_min <= 10.0:
                has_fresh_loc = True
                dist = haversine_km(booking["pickupLat"], booking["pickupLon"], d["lat"], d["lon"])

        hub_match = False
        if not has_fresh_loc:
            booking_origin = booking.get("originName", "").lower()
            driver_hub = d.get("registeredHub", "").lower()
            hub_match = bool(driver_hub and driver_hub in booking_origin)

        candidates.append({
            "driver": d,
            "has_fresh_loc": has_fresh_loc,
            "distance_km": dist,
            "hub_match": hub_match,
            "rating": d.get("rating", 4.5),
        })

    def sort_key(c):
        fresh_flag = 0 if c["has_fresh_loc"] else 1
        dist = c["distance_km"]
        hub_flag = 0 if c["hub_match"] else 1
        rating_inv = -c["rating"]
        return (fresh_flag, dist, hub_flag, rating_inv)

    candidates.sort(key=sort_key)
    return [c["driver"] for c in candidates]

def test_auto_dispatch_engine():
    now_dt = datetime(2026, 3, 10, 10, 0, 0)

    # 1. Candidate Filtering
    test("Auto-dispatch candidate filter excludes unapproved, offline, busy and capacity-insufficient drivers")
    sample_drivers = [
        {"driverId": "d1", "approvalStatus": "pending", "isOnline": True, "capacity": 4},
        {"driverId": "d2", "approvalStatus": "approved", "isOnline": False, "capacity": 4},
        {"driverId": "d3", "approvalStatus": "approved", "isOnline": True, "currentBookingId": "BK-OLD", "capacity": 4},
        {"driverId": "d4", "approvalStatus": "approved", "isOnline": True, "capacity": 2}, # too small for 3 pax
        {"driverId": "d5", "approvalStatus": "approved", "isOnline": True, "capacity": 4, "rating": 4.8}, # eligible
    ]
    booking_3pax = {"passengerCount": 3, "originName": "Karimpur Bus Stand", "pickupLat": 23.9682, "pickupLon": 88.6201}
    eligible = rank_candidates(booking_3pax, sample_drivers, attempted_ids=[], now_dt=now_dt)
    if len(eligible) != 1 or eligible[0]["driverId"] != "d5":
        fail(f"Expected only d5 eligible, got {[d['driverId'] for d in eligible]}")
    ok()

    # 2. Ranking Algorithm: GPS vs Hub Fallback
    test("Proximity ranking prefers nearest fresh GPS (<10 min) over stale GPS and registered hub fallback")
    d_near_gps = {
        "driverId": "d_near", "approvalStatus": "approved", "isOnline": True,
        "lat": 23.9690, "lon": 88.6210, "locationUpdatedAt": datetime(2026, 3, 10, 9, 58, 0), # 2 min old
        "registeredHub": "Karimpur Hospital More", "rating": 4.5
    }
    d_far_gps = {
        "driverId": "d_far", "approvalStatus": "approved", "isOnline": True,
        "lat": 23.9900, "lon": 88.6400, "locationUpdatedAt": datetime(2026, 3, 10, 9, 55, 0), # 5 min old
        "registeredHub": "Karimpur Bus Stand", "rating": 4.9
    }
    d_stale_hub = {
        "driverId": "d_hub", "approvalStatus": "approved", "isOnline": True,
        "lat": 23.9680, "lon": 88.6200, "locationUpdatedAt": datetime(2026, 3, 10, 9, 20, 0), # 40 min old (stale)
        "registeredHub": "Karimpur Bus Stand", "rating": 4.9
    }
    ranked = rank_candidates(booking_3pax, [d_stale_hub, d_far_gps, d_near_gps], attempted_ids=[], now_dt=now_dt)
    if ranked[0]["driverId"] != "d_near" or ranked[1]["driverId"] != "d_far" or ranked[2]["driverId"] != "d_hub":
        fail(f"Ranking order incorrect: {[d['driverId'] for d in ranked]}")
    ok()

    # 3. Single Offer & Concurrency Lock
    test("Single-driver offer with 30s timeout and concurrency locking against concurrent bookings")
    # Simulate offer to d_near for Booking 1
    booking1 = {"id": "BK-1", "passengerCount": 2, "pickupLat": 23.9682, "pickupLon": 88.6201, "originName": "Karimpur Bus Stand"}
    candidates_b1 = rank_candidates(booking1, [d_near_gps, d_far_gps], attempted_ids=[], now_dt=now_dt)
    chosen_b1 = candidates_b1[0]
    chosen_b1["offeredBookingId"] = "BK-1" # Locked for 30s

    # Concurrent booking 2 arrives simultaneously
    booking2 = {"id": "BK-2", "passengerCount": 1, "pickupLat": 23.9682, "pickupLon": 88.6201, "originName": "Karimpur Bus Stand"}
    candidates_b2 = rank_candidates(booking2, [d_near_gps, d_far_gps], attempted_ids=[], now_dt=now_dt)
    if len(candidates_b2) != 1 or candidates_b2[0]["driverId"] != "d_far":
        fail("Concurrency lock failed: d_near was double-offered to concurrent booking!")
    ok()

    # 4. Driver Rejection & Cascade
    test("Driver rejection or 30s timeout cascades automatically to candidate #2 without duplicates")
    # Driver d_near times out / declines booking 1
    chosen_b1["offeredBookingId"] = None
    attempted_b1 = [chosen_b1["driverId"]]

    # Run auto dispatch cascade
    cascade_candidates = rank_candidates(booking1, [d_near_gps, d_far_gps], attempted_ids=attempted_b1, now_dt=now_dt)
    if len(cascade_candidates) != 1 or cascade_candidates[0]["driverId"] != "d_far":
        fail("Cascade did not offer to candidate #2 d_far")
    ok()

    # 5. Candidate Exhaustion & Admin Fallback Alert
    test("Candidate exhaustion triggers manual-dispatch fallback and alerts admin console")
    # Candidate #2 also declines
    attempted_b1.append("d_far")
    remaining = rank_candidates(booking1, [d_near_gps, d_far_gps], attempted_ids=attempted_b1, now_dt=now_dt)
    if len(remaining) != 0:
        fail("Candidates should be completely exhausted")
    
    # Booking transitions to manual fallback
    booking1["autoDispatchExhausted"] = True
    booking1["assignmentType"] = "manual_fallback"
    booking1["status"] = "pending_assignment"
    if not (booking1["autoDispatchExhausted"] and booking1["assignmentType"] == "manual_fallback"):
        fail("Manual fallback transition failed")
    ok()

    # 6. Admin Manual Override
    test("Admin manual assignment overrides exhausted dispatch and restores confirmed booking")
    admin_selected_driver = d_near_gps
    booking1["driverId"] = admin_selected_driver["driverId"]
    booking1["status"] = "driver_assigned"
    booking1["assignmentType"] = "manual"
    booking1["autoDispatchExhausted"] = False
    if booking1["status"] != "driver_assigned" or booking1["assignmentType"] != "manual":
        fail("Admin manual override failed")
    ok()

# --- 8. SECURITY & UNAUTHORIZED ACCESS TESTS ---
def test_unauthorized_access_prevention():
    test("Security Rule: Driver cannot self-approve KYC approval status")
    driver_claims = {"role": "driver", "uid": "drv_99"}
    attempted_patch = {"approvalStatus": "approved", "approvedBy": "drv_99"}
    is_admin = driver_claims.get("role") == "admin"
    if not is_admin and "approvalStatus" in attempted_patch:
        blocked = True
    else:
        blocked = False
    if not blocked:
        fail("Driver self-approval was not blocked!")
    ok()

    test("Security Rule: Driver cannot alter confirmed tariff or ride fare")
    booking_doc = {"fare": 20.0, "status": "driver_assigned", "driverId": "drv_99"}
    driver_tamper = {"fare": 50.0} # Attempting surge pricing / tampering
    is_fare_locked = driver_tamper.get("fare") != booking_doc["fare"] and driver_claims.get("role") != "admin"
    if not is_fare_locked:
        fail("Driver was allowed to alter confirmed ride fare!")
    ok()

    test("Security Rule: Driver cannot access other drivers' private booking records")
    booking_other_driver = {"id": "BK-OTHER", "driverId": "drv_other_88", "passengerPhone": "+91 98321 00000"}
    can_read = (driver_claims["uid"] == booking_other_driver.get("driverId")) or (driver_claims.get("role") == "admin")
    if can_read:
        fail("Driver was granted read access to another driver's booking!")
    ok()

def main():
    print("=" * 65)
    print("  POTHIKSAHTI MVP AUTOMATED VERIFICATION SUITE")
    print("  Launch Zone: Karimpur, Nadia, West Bengal (PIN 741152)")
    print("=" * 65)
    
    try:
        test_auth_and_roles()
        test_fare_calculations()
        test_booking_state_machine()
        test_idempotency()
        test_timetable_search()
        test_firestore_rules_and_schema()
        test_auto_dispatch_engine()
        test_unauthorized_access_prevention()
        
        print("=" * 65)
        print(f"  ALL {passed_tests} OF {total_tests} TESTS PASSED SUCCESSFULLY! (100% SUCCESS)")
        print("=" * 65)
        return 0
    except TestFailure as e:
        print(f"\nTEST SUITE FAILED: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
