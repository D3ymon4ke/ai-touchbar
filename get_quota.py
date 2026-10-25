#!/usr/bin/env python3
import subprocess
import re
import urllib.request
import ssl
import json
import sys

def fetch_quota():
    try:
        out = subprocess.check_output(['ps', '-A', '-o', 'pid,args'], timeout=2).decode()
    except Exception:
        return None

    servers = []
    for line in out.splitlines():
        if 'language_server_macos_x64' in line and not 'python' in line:
            m_csrf = re.search(r'--csrf_token\s+([a-f0-9\-]+)', line)
            m_port = re.search(r'--extension_server_port\s+(\d+)', line)
            if m_csrf and m_port:
                servers.append((m_csrf.group(1), int(m_port.group(1))))

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    for csrf, ext_port in servers:
        for offset in [1, 2, 3]:
            port = ext_port + offset
            url = f'https://127.0.0.1:{port}/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary'
            req = urllib.request.Request(url, data=b'{}', headers={
                'Content-Type': 'application/json',
                'Connect-Protocol-Version': '1',
                'x-codeium-csrf-token': csrf
            })
            try:
                with urllib.request.urlopen(req, context=ctx, timeout=0.8) as resp:
                    data = json.loads(resp.read().decode())
                    if 'response' in data and 'groups' in data['response']:
                        return parse_groups(data['response']['groups'])
            except Exception:
                pass
    return None

def parse_groups(groups):
    gemini_5h = 100.0
    gemini_weekly = 100.0
    gemini_5h_desc = ""
    gemini_weekly_desc = ""
    claude_5h = 100.0
    claude_weekly = 100.0

    for g in groups:
        name = g.get('displayName', '')
        buckets = g.get('buckets', [])
        if 'Gemini' in name:
            for b in buckets:
                bid = b.get('bucketId', '')
                frac = b.get('remainingFraction', 1.0) * 100.0
                desc = b.get('description', '')
                if '5h' in bid:
                    gemini_5h = round(frac, 1)
                    gemini_5h_desc = desc
                elif 'weekly' in bid:
                    gemini_weekly = round(frac, 1)
                    gemini_weekly_desc = desc
        elif 'Claude' in name or 'GPT' in name:
            for b in buckets:
                bid = b.get('bucketId', '')
                frac = b.get('remainingFraction', 1.0) * 100.0
                if '5h' in bid:
                    claude_5h = round(frac, 1)
                elif 'weekly' in bid:
                    claude_weekly = round(frac, 1)

    return {
        "geminiFiveHour": gemini_5h,
        "geminiWeekly": gemini_weekly,
        "geminiFiveHourDesc": gemini_5h_desc,
        "geminiWeeklyDesc": gemini_weekly_desc,
        "claudeFiveHour": claude_5h,
        "claudeWeekly": claude_weekly,
        "primaryPercent": gemini_5h
    }

if __name__ == '__main__':
    res = fetch_quota()
    if res:
        print(json.dumps(res))
    else:
        sys.exit(1)
