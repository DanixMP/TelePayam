from sqlalchemy import select

from app.db.models import StudentProfile, User


async def test_student_otp_and_registration(client, db):
    otp = await client.post("/api/v1/auth/otp/request", json={"phone": "09121234567"})
    assert otp.status_code == 202
    code = otp.json()["development_code"]

    login = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "09121234567", "code": code, "platform": "android"},
    )
    assert login.status_code == 200
    token = login.json()["access_token"]
    assert login.json()["user"]["status"] == "pending_profile"

    response = await client.post(
        "/api/v1/users/me/student-profile",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "first_name": "Sara",
            "last_name": "Ahmadi",
            "national_id": "0084575948",
            "degree": "MSc",
            "department": "Computer Engineering",
            "university_id": "40310001",
        },
    )
    assert response.status_code == 200
    assert response.json()["status"] == "pending_approval"

    db.expire_all()
    user = await db.scalar(select(User).where(User.phone == "+989121234567"))
    profile = await db.get(StudentProfile, user.id)
    assert profile.national_id_enc != "0084575948"
    assert profile.national_id_last4 == "5948"


async def test_wrong_otp_is_rejected(client):
    await client.post("/api/v1/auth/otp/request", json={"phone": "09123334444"})
    response = await client.post(
        "/api/v1/auth/otp/verify",
        json={"phone": "09123334444", "code": "000000"},
    )
    assert response.status_code == 400
    assert response.json()["error"]["code"] == "otp_invalid"
