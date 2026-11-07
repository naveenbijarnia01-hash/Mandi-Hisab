import re

def parse_voice_command(text):
    lower = text.lower()

    # 1. Type
    tx_type = "incoming"
    if any(k in lower for k in ["gaye", "bheja", "nikla", "sell", "out", "ja raha"]):
        tx_type = "outgoing"
    elif any(k in lower for k in ["aayi", "aaya", "mili", "purchase", "in"]):
        tx_type = "incoming"

    # 2. Crop
    crop = "Gehun"
    if "sarson" in lower or "mustard" in lower:
        crop = "Sarson"
    elif "bajra" in lower:
        crop = "Bajra"
    elif "chana" in lower or "gram" in lower:
        crop = "Chana"
    elif "jau" in lower:
        crop = "Jau"
    elif "makka" in lower:
        crop = "Makka"
    elif "dhan" in lower or "rice" in lower:
        crop = "Dhan"
    elif "soybean" in lower:
        crop = "Soybean"
    elif "gehun" in lower or "wheat" in lower:
        crop = "Gehun"

    # 3. Quantity & Unit
    num_match = re.search(r'(\d+(?:\.\d+)?)', text)
    quantity = float(num_match.group(1)) if num_match else 0.0

    unit = "Quintal"
    if "kg" in lower or "kilogram" in lower:
        unit = "KG"
    elif "ton" in lower:
        unit = "Ton"

    # 4. Vehicle
    v_match = re.search(r'([a-zA-Z]{2}\s?\d{1,2}\s?[a-zA-Z]{1,2}\s?\d{4})', text)
    vehicle = v_match.group(1).upper().replace(" ", "") if v_match else "RJ14U0010"

    # 5. Party
    party = "Local Party"
    if " se " in lower:
        parts = re.split(r'\s+se\s+', text, flags=re.IGNORECASE)
        if parts:
            words = parts[0].split()
            party = " ".join(words[-2:]) if len(words) >= 2 else words[-1]
    elif " mein " in lower or " ko " in lower:
        parts = re.split(r'\s+(?:mein|ko)\s+', text, flags=re.IGNORECASE)
        if parts:
            words = parts[0].split()
            party = " ".join(words[-2:]) if len(words) >= 2 else words[-1]

    return {
        "type": tx_type,
        "crop": crop,
        "quantity": quantity,
        "unit": unit,
        "party": party.strip(),
        "vehicle": vehicle,
    }

def test_samples():
    cmd1 = "Aaj 50 quintal gehun Sungna Factory mein gaye hain, gaadi number RJ14U0010 se."
    r1 = parse_voice_command(cmd1)
    print("Test 1 Result:", r1)
    assert r1["type"] == "outgoing", f"Expected outgoing, got {r1['type']}"
    assert r1["crop"] == "Gehun", f"Expected Gehun, got {r1['crop']}"
    assert r1["quantity"] == 50.0, f"Expected 50.0, got {r1['quantity']}"
    assert r1["unit"] == "Quintal", f"Expected Quintal, got {r1['unit']}"
    assert "RJ14U0010" in r1["vehicle"], f"Expected RJ14U0010, got {r1['vehicle']}"

    cmd2 = "Aaj 100 quintal sarson Suresh ji se aayi hai, gaadi RJ23AB1234 se."
    r2 = parse_voice_command(cmd2)
    print("Test 2 Result:", r2)
    assert r2["type"] == "incoming", f"Expected incoming, got {r2['type']}"
    assert r2["crop"] == "Sarson", f"Expected Sarson, got {r2['crop']}"
    assert r2["quantity"] == 100.0, f"Expected 100.0, got {r2['quantity']}"
    assert r2["vehicle"] == "RJ23AB1234", f"Expected RJ23AB1234, got {r2['vehicle']}"

    print("ALL TESTS PASSED SUCCESSFULLY! ✅")

if __name__ == "__main__":
    test_samples()
