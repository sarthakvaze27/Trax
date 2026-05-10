"""
Run once to seed the DB:
  python seed.py
"""
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext
from datetime import datetime, UTC

MONGO_URI = "mongodb://localhost:27017"
DB_NAME   = "sportsetu"

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

FACILITIES = [
    {
        "name": "Panaji Sports Complex",
        "location": "Panaji",
        "sag_tag": "SAG-PNJ-01",
        "emoji": "🏟️",
        "sports": ["Football", "Basketball", "Volleyball"],
        "amenities": ["Parking", "Changing Rooms", "Floodlights", "Cafeteria"],
        "price_per_hr": 500,
        "rating": 4.5,
        "is_open": True,
        "lat": 15.4909,
        "lng": 73.8278,
        "distance_km": 0.8,
        "utilization": 65,
    },
    {
        "name": "Margao Football Ground",
        "location": "Margao",
        "sag_tag": "SAG-MGO-01",
        "emoji": "⚽",
        "sports": ["Football", "Athletics"],
        "amenities": ["Parking", "Changing Rooms", "Floodlights"],
        "price_per_hr": 400,
        "rating": 4.2,
        "is_open": True,
        "lat": 15.2745,
        "lng": 74.0134,
        "distance_km": 33.0,
        "utilization": 72,
    },
    {
        "name": "Vasco Multipurpose Hall",
        "location": "Vasco da Gama",
        "sag_tag": "SAG-VSC-01",
        "emoji": "🏸",
        "sports": ["Badminton", "Table Tennis", "Basketball"],
        "amenities": ["AC", "Parking", "Changing Rooms"],
        "price_per_hr": 600,
        "rating": 4.7,
        "is_open": True,
        "lat": 15.3969,
        "lng": 73.8116,
        "distance_km": 29.0,
        "utilization": 88,
    },
    {
        "name": "Mapusa Cricket Ground",
        "location": "Mapusa",
        "sag_tag": "SAG-MAP-01",
        "emoji": "🏏",
        "sports": ["Cricket"],
        "amenities": ["Parking", "Floodlights", "Pitch Covers"],
        "price_per_hr": 700,
        "rating": 4.3,
        "is_open": True,
        "lat": 15.5918,
        "lng": 73.8143,
        "distance_km": 12.0,
        "utilization": 45,
    },
    {
        "name": "Ponda Aquatic Centre",
        "location": "Ponda",
        "sag_tag": "SAG-PND-01",
        "emoji": "🏊",
        "sports": ["Swimming"],
        "amenities": ["Locker Rooms", "Shower", "Lifeguard"],
        "price_per_hr": 300,
        "rating": 4.0,
        "is_open": False,
        "lat": 15.4036,
        "lng": 74.0020,
        "distance_km": 28.0,
        "utilization": 30,
    },
    {
        "name": "Campal Indoor Complex",
        "location": "Panaji",
        "sag_tag": "SAG-CMP-01",
        "emoji": "🏸",
        "sports": ["Badminton", "Table Tennis", "Fitness"],
        "amenities": ["Indoor Courts", "Locker Rooms", "Drinking Water", "First Aid"],
        "price_per_hr": 150,
        "rating": 4.7,
        "is_open": True,
        "lat": 15.4992,
        "lng": 73.8171,
        "distance_km": 1.2,
        "utilization": 54,
    },
    {
        "name": "Bambolim Athletic Track",
        "location": "Bambolim",
        "sag_tag": "SAG-BAM-01",
        "emoji": "🏃",
        "sports": ["Athletics", "Football", "Fitness"],
        "amenities": ["Track", "Floodlights", "Medical Room", "Parking"],
        "price_per_hr": 250,
        "rating": 4.4,
        "is_open": True,
        "lat": 15.4633,
        "lng": 73.8567,
        "distance_km": 7.0,
        "utilization": 61,
    },
    {
        "name": "Fatorda Sports Arena",
        "location": "Margao",
        "sag_tag": "SAG-FAT-01",
        "emoji": "🏟️",
        "sports": ["Football", "Athletics", "Basketball"],
        "amenities": ["Seating", "Changing Rooms", "Floodlights", "Cafeteria"],
        "price_per_hr": 800,
        "rating": 4.8,
        "is_open": True,
        "lat": 15.2892,
        "lng": 73.9588,
        "distance_km": 31.5,
        "utilization": 79,
    },
    {
        "name": "Calangute Community Court",
        "location": "Calangute",
        "sag_tag": "SAG-CAL-01",
        "emoji": "🏀",
        "sports": ["Basketball", "Volleyball"],
        "amenities": ["Open Court", "Lighting", "Parking"],
        "price_per_hr": 220,
        "rating": 4.1,
        "is_open": True,
        "lat": 15.5439,
        "lng": 73.7553,
        "distance_km": 14.4,
        "utilization": 38,
    },
    {
        "name": "Dr Shyama Prasad Mukherjee Indoor Stadium",
        "location": "Taleigao",
        "sag_tag": "SAG-TLG-01",
        "emoji": "🏟️",
        "sports": ["Basketball", "Volleyball", "Badminton", "Futsal"],
        "amenities": ["Indoor Arena", "Seating", "Parking", "Medical Room"],
        "price_per_hr": 900,
        "rating": 4.9,
        "is_open": True,
        "lat": 15.4647,
        "lng": 73.8298,
        "distance_km": 5.2,
        "utilization": 82,
    },
    {
        "name": "Tilak Maidan Sports Complex",
        "location": "Vasco da Gama",
        "sag_tag": "SAG-TMK-01",
        "emoji": "⚽",
        "sports": ["Football", "Athletics"],
        "amenities": ["Stadium Seating", "Floodlights", "Changing Rooms", "Parking"],
        "price_per_hr": 750,
        "rating": 4.6,
        "is_open": True,
        "lat": 15.3958,
        "lng": 73.8136,
        "distance_km": 27.5,
        "utilization": 74,
    },
    {
        "name": "Navelim Multipurpose Ground",
        "location": "Navelim",
        "sag_tag": "SAG-NAV-01",
        "emoji": "🏏",
        "sports": ["Cricket", "Football", "Athletics"],
        "amenities": ["Open Ground", "Practice Nets", "Parking", "Drinking Water"],
        "price_per_hr": 350,
        "rating": 4.2,
        "is_open": True,
        "lat": 15.2561,
        "lng": 73.9581,
        "distance_km": 36.8,
        "utilization": 49,
    },
    {
        "name": "Curchorem Sports Centre",
        "location": "Curchorem",
        "sag_tag": "SAG-CUR-01",
        "emoji": "🏐",
        "sports": ["Volleyball", "Badminton", "Table Tennis"],
        "amenities": ["Indoor Hall", "Changing Rooms", "First Aid", "Lighting"],
        "price_per_hr": 280,
        "rating": 4.0,
        "is_open": True,
        "lat": 15.2637,
        "lng": 74.1081,
        "distance_km": 48.2,
        "utilization": 42,
    },
    {
        "name": "Sankhali Community Sports Hub",
        "location": "Sankhali",
        "sag_tag": "SAG-SNK-01",
        "emoji": "🏃",
        "sports": ["Athletics", "Football", "Fitness"],
        "amenities": ["Track", "Open Gym", "Parking", "Drinking Water"],
        "price_per_hr": 200,
        "rating": 4.1,
        "is_open": True,
        "lat": 15.5645,
        "lng": 74.0079,
        "distance_km": 28.5,
        "utilization": 36,
    },
    {
        "name": "Canacona Sports Ground",
        "location": "Canacona",
        "sag_tag": "SAG-CAN-01",
        "emoji": "⚽",
        "sports": ["Football", "Cricket", "Volleyball"],
        "amenities": ["Open Ground", "Changing Rooms", "Parking"],
        "price_per_hr": 260,
        "rating": 3.9,
        "is_open": True,
        "lat": 15.0096,
        "lng": 74.0232,
        "distance_km": 68.0,
        "utilization": 27,
    },
    {
        "name": "Pernem Sports Ground",
        "location": "Pernem",
        "sag_tag": "SAG-PER-01",
        "emoji": "🏏",
        "sports": ["Cricket", "Football"],
        "amenities": ["Practice Nets", "Open Ground", "Parking", "Water"],
        "price_per_hr": 240,
        "rating": 4.0,
        "is_open": True,
        "lat": 15.7230,
        "lng": 73.7951,
        "distance_km": 30.1,
        "utilization": 33,
    },
    {
        "name": "Dona Paula Water Sports Centre",
        "location": "Dona Paula",
        "sag_tag": "SAG-DPA-01",
        "emoji": "🏊",
        "sports": ["Swimming", "Fitness"],
        "amenities": ["Showers", "Locker Rooms", "Lifeguard", "First Aid"],
        "price_per_hr": 320,
        "rating": 4.3,
        "is_open": False,
        "lat": 15.4527,
        "lng": 73.8035,
        "distance_km": 7.4,
        "utilization": 22,
    },
]

TOURNAMENTS = [
    {
        "name": "Goa Premier Football League",
        "sport": "Football",
        "start_date": "2026-06-01",
        "end_date": "2026-06-28",
        "location": "Panaji Sports Complex",
        "max_teams": 16,
        "prize_pool": "Rs 1,00,000",
        "status": "upcoming",
        "created_at": datetime.now(UTC),
    },
    {
        "name": "SAG Badminton Open",
        "sport": "Badminton",
        "start_date": "2026-05-18",
        "end_date": "2026-05-20",
        "location": "Vasco Multipurpose Hall",
        "max_teams": 32,
        "prize_pool": "Rs 50,000",
        "status": "ongoing",
        "created_at": datetime.now(UTC),
    },
    {
        "name": "Goa Monsoon Athletics Meet",
        "sport": "Athletics",
        "start_date": "2026-07-10",
        "end_date": "2026-07-12",
        "location": "Bambolim Athletic Track",
        "max_teams": 24,
        "prize_pool": "Rs 75,000",
        "status": "upcoming",
        "created_at": datetime.now(UTC),
    },
    {
        "name": "Coastal Basketball Cup",
        "sport": "Basketball",
        "start_date": "2026-08-05",
        "end_date": "2026-08-09",
        "location": "Calangute Community Court",
        "max_teams": 16,
        "prize_pool": "Rs 40,000",
        "status": "upcoming",
        "created_at": datetime.now(UTC),
    },
    {
        "name": "State Swimming Sprint",
        "sport": "Swimming",
        "start_date": "2026-09-18",
        "end_date": "2026-09-19",
        "location": "Ponda Aquatic Centre",
        "max_teams": 32,
        "prize_pool": "Rs 60,000",
        "status": "upcoming",
        "created_at": datetime.now(UTC),
    },
]

async def seed():
    client = AsyncIOMotorClient(MONGO_URI)
    db = client[DB_NAME]

    # Clear existing
    await db.facilities.delete_many({})
    await db.tournaments.delete_many({})
    await db.users.delete_many({})

    # Insert facilities
    for f in FACILITIES:
        f["created_at"] = datetime.now(UTC)
    await db.facilities.insert_many(FACILITIES)
    print(f"Inserted {len(FACILITIES)} facilities")

    # Insert tournaments
    await db.tournaments.insert_many(TOURNAMENTS)
    print(f"Inserted {len(TOURNAMENTS)} tournaments")

    # Create default admin
    await db.users.insert_one({
        "name": "SAG Admin",
        "email": "admin@sportsetu.goa.gov.in",
        "password_hash": pwd_ctx.hash("Admin@1234"),
        "phone": "0832-2229-000",
        "role": "admin",
        "loyalty_points": 0,
        "created_at": datetime.now(UTC),
    })
    print("Admin created: admin@sportsetu.goa.gov.in / Admin@1234")

    # Create demo user
    await db.users.insert_one({
        "name": "Rahul Parab",
        "email": "rahul@demo.com",
        "password_hash": pwd_ctx.hash("User@1234"),
        "phone": "9876543210",
        "role": "user",
        "loyalty_points": 120,
        "created_at": datetime.now(UTC),
    })
    print("Demo user: rahul@demo.com / User@1234")

    # Create local friends so the app's Friends tab has real contacts
    friends = [
        {
            "name": "Arjun Desai",
            "email": "arjun@demo.com",
            "password_hash": pwd_ctx.hash("User@1234"),
            "phone": "9876500001",
            "role": "user",
            "loyalty_points": 85,
            "created_at": datetime.now(UTC),
        },
        {
            "name": "Neha Naik",
            "email": "neha@demo.com",
            "password_hash": pwd_ctx.hash("User@1234"),
            "phone": "9876500002",
            "role": "user",
            "loyalty_points": 210,
            "created_at": datetime.now(UTC),
        },
        {
            "name": "Jason D Souza",
            "email": "jason@demo.com",
            "password_hash": pwd_ctx.hash("User@1234"),
            "phone": "9876500003",
            "role": "user",
            "loyalty_points": 45,
            "created_at": datetime.now(UTC),
        },
        {
            "name": "Meera Kamat",
            "email": "meera@demo.com",
            "password_hash": pwd_ctx.hash("User@1234"),
            "phone": "9876500004",
            "role": "user",
            "loyalty_points": 160,
            "created_at": datetime.now(UTC),
        },
    ]
    await db.users.insert_many(friends)
    print(f"Inserted {len(friends)} local friends")

    client.close()
    print("\nSeed complete!")

asyncio.run(seed())
