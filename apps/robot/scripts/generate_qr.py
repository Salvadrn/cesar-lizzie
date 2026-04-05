#!/usr/bin/env python3
"""
Generate a QR code for robot pairing with the Adapt AI app.
The QR encodes: adaptai://pair?sn=SERIAL_NUMBER&code=PAIRING_CODE

Usage:
  python scripts/generate_qr.py --serial AAI-001 --code abc12345
  python scripts/generate_qr.py --from-config   # reads from config/default.yaml

The QR can be:
  - Printed and stuck on the robot
  - Displayed on an attached screen
  - Shown in terminal (ASCII)
"""

import argparse
import sys
import os

try:
    import qrcode
except ImportError:
    print("Install qrcode: pip install qrcode[pil]")
    sys.exit(1)


def generate_pairing_qr(serial_number: str, pairing_code: str, output: str = "terminal"):
    payload = f"adaptai://pair?sn={serial_number}&code={pairing_code}"

    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(payload)
    qr.make(fit=True)

    print(f"\n  Adapt AI Robot Pairing QR")
    print(f"  Serial: {serial_number}")
    print(f"  Code:   {pairing_code}")
    print(f"  Payload: {payload}\n")

    if output == "terminal":
        qr.print_ascii(invert=True)
        print("\n  Scan this QR with the Adapt AI app to pair.\n")

    elif output == "png":
        img = qr.make_image(fill_color="#4078DA", back_color="white")
        filename = f"pairing_qr_{serial_number}.png"
        img.save(filename)
        print(f"  Saved to: {filename}\n")

    elif output == "screen":
        # Display on attached screen (RPi with display)
        img = qr.make_image(fill_color="#4078DA", back_color="white")
        img = img.resize((400, 400))
        img.show()


def main():
    parser = argparse.ArgumentParser(description="Generate Adapt AI Robot Pairing QR")
    parser.add_argument("--serial", help="Robot serial number")
    parser.add_argument("--code", help="Pairing code")
    parser.add_argument("--from-config", action="store_true", help="Read from config/default.yaml")
    parser.add_argument("--output", choices=["terminal", "png", "screen"], default="terminal")
    args = parser.parse_args()

    if args.from_config:
        import yaml
        config_path = os.path.join(os.path.dirname(__file__), "..", "config", "default.yaml")
        with open(config_path) as f:
            config = yaml.safe_load(f)
        serial = config.get("robot", {}).get("serial_number", "AAI-001")
        code = config.get("robot", {}).get("pairing_code", "")
        if not code:
            print("Error: No pairing_code in config. Set robot.pairing_code in default.yaml")
            sys.exit(1)
    else:
        serial = args.serial
        code = args.code
        if not serial or not code:
            print("Error: --serial and --code are required (or use --from-config)")
            sys.exit(1)

    generate_pairing_qr(serial, code, args.output)


if __name__ == "__main__":
    main()
