import sys
try:
    from smartcard.System import readers
    from smartcard.util import toHexString
    from smartcard.CardConnection import CardConnection
except ImportError:
    print("pyscard not installed.")
    sys.exit(1)

# The candidates from your gp -list output
CANDIDATES = {
    "ISD (Manager)": [0xA0, 0x00, 0x00, 0x01, 0x51, 0x00, 0x00, 0x00],
    "Spooky/SPA":    [0xA0, 0x00, 0x00, 0x01, 0x51, 0x53, 0x50, 0x41],
    "CDocLite":      [0xA0, 0x00, 0x00, 0x01, 0x64, 0x43, 0x44, 0x6F, 0x63, 0x4C, 0x69, 0x74, 0x65, 0x01]
}

def main():
    r_list = readers()
    if not r_list: return
    conn = r_list[0].createConnection()
    conn.connect(CardConnection.T1_protocol)

    print(f"--- SCANNING CARD INSTANCES ---")
    for name, aid in CANDIDATES.items():
        print(f"Trying {name} ({toHexString(aid)})...", end=" ")
        # SELECT command
        apdu = [0x00, 0xA4, 0x04, 0x00, len(aid)] + aid + [0x00]
        resp, sw1, sw2 = conn.transmit(apdu)
        
        if sw1 == 0x90:
            print("SUCCESS! (Active Instance Found)")
            # If successful, try to get card info
            info_resp, i_sw1, i_sw2 = conn.transmit([0x80, 0x40, 0x00, 0x00, 0x00])
            if i_sw1 == 0x90:
                print(f"   > Info: {toHexString(info_resp)}")
        else:
            print(f"FAILED (SW: {sw1:02X}{sw2:02X})")

if __name__ == "__main__":
    main()