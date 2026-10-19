#!/usr/bin/env python3
"""MID-360 time sync, from what the LiDAR itself sends: its 1 Hz status push (time_sync_type,
time_offset) and the time_type of its data packets. Read-only (a raw socket: run as root with
host networking, as in the livox container). Exits 1 unless the LiDAR reports PTP/gPTP sync.

    livox-status <iface> [lidar_ip]
"""
import socket
import struct
import sys
import time

iface = sys.argv[1]
lidar = sys.argv[2] if len(sys.argv) > 2 else '192.168.1.104'
SYNC = {0: 'none (stamped on arrival by the driver)', 1: 'PTP/gPTP', 2: 'GPS'}

s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(0x0800))
s.bind((iface, 0))
s.settimeout(1.0)
status = data = None
end = time.time() + 3
while time.time() < end and (status is None or data is None):
    try:
        ip = s.recv(4096)[14:]
    except socket.timeout:
        continue
    if ip[9] != 17 or socket.inet_ntoa(ip[12:16]) != lidar:
        continue
    ihl = (ip[0] & 15) * 4
    p = ip[ihl + 8:]
    if p[:1] == b'\xaa' and struct.unpack('<H', p[8:10])[0] == 0x0102:  # status push
        d, kv, o = p[24:], {}, 4
        for _ in range(struct.unpack('<H', d[:2])[0]):
            k, n = struct.unpack('<HH', d[o:o + 4])
            kv[k], o = d[o + 4:o + 4 + n], o + 4 + n
        if 0x800C in kv:
            status = (kv[0x800C][0], struct.unpack('<q', kv[0x800B])[0])
    elif len(p) > 36 and p[0] == 0 and data is None:  # point or IMU data packet (version 0)
        data = (p[11], struct.unpack('<Q', p[28:36])[0] * 1e-9 - time.time())

if status is None or data is None:
    sys.exit(f'no status push or data from {lidar} on {iface} within 3 s')
print(f'time_sync_type {status[0]}: {SYNC.get(status[0], "?")}, offset {status[1] / 1e3:+.1f} us')
print(f'packet time_type {data[0]}, packet stamp - host clock {data[1] * 1e3:+.2f} ms')
sys.exit(0 if status[0] == 1 and data[0] == 1 else 1)
