#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sync_locale_files.py
将项目根 gcg/ 下的 cards.cdb, strings.conf, servers.conf
复制到 gcg/locales/zh-CN/ 目录下
根据脚本位置自动定位项目根
"""

import shutil
import sys
from pathlib import Path

FILES_TO_COPY = ["cards.cdb", "strings.conf", "servers.conf"]

def main():
    script_dir = Path(__file__).resolve().parent

    # 脚本路径: gcg/dev/tools -> 项目根是上2级目录 gcg/
    project_root = script_dir.parent.parent

    target_dir = project_root / "locales" / "zh-CN"
    target_dir.mkdir(parents=True, exist_ok=True)

    print(f"项目根目录: {project_root}")
    print(f"目标目录: {target_dir}")

    copied = 0
    for fname in FILES_TO_COPY:
        src = project_root / fname
        dst = target_dir / fname

        if not src.exists():
            print(f"未找到源文件: {src}")
            continue

        try:
            shutil.copy2(src, dst)
            print(f"已复制: {src.name} -> {dst}")
            copied += 1
        except Exception as e:
            print(f"复制失败 ({src.name}): {e}")

    if copied == 0:
        print("没有文件被复制。请确认项目根目录下是否存在要复制的文件。")
        sys.exit(2)

    print("同步完成。")

if __name__ == "__main__":
    main()