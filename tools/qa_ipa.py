#!/usr/bin/env python3
"""qa_ipa.py — QA-проверки собранного IPA (Фаза 7.1):
1. Структура: Payload/*.app, Info.plist, наличие бинарника.
2. Наличие dylib мода в .app и LC_LOAD_DYLIB ссылки в бинарнике.
3. class-dump-подобная проверка хукаемых классов: использует nm/strings на Mach-O
   бинарнике для поиска имен классов Obj-C (__objc_classname секция).
Отчёт печатается и падает, если структура битая.
"""
import os
import plistlib
import re
import subprocess
import sys
import tempfile
import zipfile

HOOKED_CLASSES = [
    # core feature hooks
    "AWEAwemeModel", "AWEAwemeACLItem", "CTCarrier", "TTKStoreRegionService",
    "TIKTOKRegionManager", "SparkViewController", "TTKSettingsBaseCellPlugin",
    "AWESettingsNormalSectionViewModel", "AWELiveFeedEntranceView",
    # download
    "AWEFeedViewTemplateCell", "AWEAwemeDetailTableViewCell", "AWEURLModel",
    "AWEFeedCellViewController", "AWEAwemeBaseViewController",
    # jb bypass
    "BDADeviceHelper", "TTInstallUtil", "AppsFlyerUtils", "AWEAPMManager",
]


def main():
    ipa = sys.argv[1]
    tmp = tempfile.mkdtemp()
    with zipfile.ZipFile(ipa) as z:
        names = z.namelist()
        z.extractall(tmp)

    # 1. structure
    app_dir = None
    for root, dirs, files in os.walk(os.path.join(tmp, "Payload")):
        if root.endswith(".app"):
            app_dir = root
            break
    assert app_dir, "QA FAIL: no .app in Payload"
    app_name = os.path.basename(app_dir)
    binary = os.path.join(app_dir, app_name[:-4])
    assert os.path.exists(binary), f"QA FAIL: binary {binary} missing"

    pl = None
    with open(os.path.join(app_dir, "Info.plist"), "rb") as f:
        pl = plistlib.load(f)
    print(f"[qa] app: {app_name}")
    print(f"[qa] display name: {pl.get('CFBundleDisplayName')}")
    print(f"[qa] version: {pl.get('CFBundleShortVersionString')} ({pl.get('CFBundleVersion')})")
    print(f"[qa] bundle id: {pl.get('CFBundleIdentifier')}")

    # 2. dylib presence (cyan injects into .app root OR Frameworks/)
    dylibs = [f for f in os.listdir(app_dir) if f.endswith(".dylib")]
    frameworks_dir = os.path.join(app_dir, "Frameworks")
    if os.path.isdir(frameworks_dir):
        dylibs += [f for f in os.listdir(frameworks_dir) if f.endswith(".dylib")]
    assert dylibs, "QA FAIL: no injected dylib in .app"
    print(f"[qa] dylibs: {dylibs}")

    # dylib may live in .app root or Frameworks/; otool -L on the main binary shows
    # @executable_path/... paths — match on basename only.
    # Only the injected tweak dylib MUST be linked; stock Apple dylibs
    # (libswift_*) live in Frameworks/ without being linked from the main binary.
    linked = subprocess.run(["otool", "-L", binary], capture_output=True, text=True).stdout
    tweak_dylibs = [d for d in dylibs if not d.startswith("libswift_")]
    missing_link = [d for d in tweak_dylibs if d not in linked]
    assert not missing_link, f"QA FAIL: dylib not linked into binary: {missing_link}"
    print("[qa] dylib load commands: OK")

    # 3. hooked classes present in binary (ObjC class names in __DATA __objc_classname)
    # TikTok 47.x keeps almost all code in Frameworks/MusicallyCore.framework/MusicallyCore
    # (the main .app/TikTok binary is a 73KB stub) — scan both.
    classnames = set()
    scan_targets = [binary]
    frameworks_dir = os.path.join(app_dir, "Frameworks")
    if os.path.isdir(frameworks_dir):
        for fw in os.listdir(frameworks_dir):
            fwbin = os.path.join(frameworks_dir, fw, fw[:-10] if fw.endswith(".framework") else fw)
            if os.path.isfile(fwbin) and os.path.getsize(fwbin) > 10_000_000:
                scan_targets.append(fwbin)
    for tgt in scan_targets:
        try:
            out = subprocess.run(["strings", "-arch", "arm64", tgt],
                                 capture_output=True, text=True, timeout=600).stdout
            classnames |= set(out.split())
        except Exception as e:
            print(f"[qa] WARN: strings failed on {tgt}: {e}")

    print("[qa] class check (hooked classes found in binary):")
    found = 0
    for c in HOOKED_CLASSES:
        ok = c in classnames
        if ok:
            found += 1
        print(f"  {'OK ' if ok else 'MISS'} {c}")
    print(f"[qa] hooked classes found: {found}/{len(HOOKED_CLASSES)}")
    if found < len(HOOKED_CLASSES):
        print("[qa] NOTE: some hooked classes are missing in this TikTok version — "
              "those features degrade to OFF at runtime (see hook log in app).")
    print("[qa] ALL STRUCTURE CHECKS PASSED")


if __name__ == "__main__":
    main()
