#!/usr/bin/python3
# 中文注释：GPU 初始化超时看门狗；只终止本次初始化脚本及其子进程，不重启整台电脑。
import os
import signal
import subprocess
import sys
import time


def process_table():
    """读取 PID 与 PPID 关系，供后续限定终止范围。"""
    result = subprocess.run(
        ["/bin/ps", "-axo", "pid=,ppid="],
        check=True,
        capture_output=True,
        text=True,
    )
    table = {}
    for line in result.stdout.splitlines():
        fields = line.split()
        if len(fields) != 2:
            continue
        try:
            pid, ppid = map(int, fields)
        except ValueError:
            continue
        table[pid] = ppid
    return table


def collect_process_tree(root_pid, table):
    """只收集指定初始化脚本的后代进程，不触碰无关进程。"""
    children = {}
    for pid, ppid in table.items():
        children.setdefault(ppid, []).append(pid)

    found = []
    pending = [(root_pid, 0)]
    visited = {root_pid}
    while pending:
        parent, depth = pending.pop()
        for child in children.get(parent, []):
            if child in visited:
                continue
            visited.add(child)
            found.append((child, depth + 1))
            pending.append((child, depth + 1))
    return found


def terminate_initialization_tree(root_pid):
    """先温和终止本次初始化树，再清理仍未退出的同一批 PID。"""
    table = process_table()
    if root_pid not in table:
        print("超时发生时，初始化父进程已不存在；无需处理。", flush=True)
        return

    descendants = collect_process_tree(root_pid, table)
    targets = [pid for pid, _ in sorted(descendants, key=lambda item: item[1], reverse=True)]
    targets.append(root_pid)

    # 当前看门狗进程不终止自己，以便完成日志和退出。
    targets = [pid for pid in targets if pid != os.getpid()]
    print(
        f"GPU 初始化超时：仅终止本次进程树，根 PID={root_pid}，"
        f"后代进程数={len(targets) - 1}；不会重启整台电脑。",
        flush=True,
    )

    for pid in targets:
        try:
            os.kill(pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        except PermissionError:
            print(f"无权终止进程 PID={pid}。", flush=True)

    time.sleep(2)

    for pid in targets:
        try:
            os.kill(pid, 0)
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        except PermissionError:
            print(f"无法强制结束残留进程 PID={pid}。", flush=True)


def main():
    if len(sys.argv) != 2:
        raise SystemExit("用法：watchdog.py <秒数>")

    try:
        delay = int(sys.argv[1])
    except ValueError:
        raise SystemExit("秒数必须是整数")

    if delay < 1 or delay > 1800:
        raise SystemExit("秒数必须在 1 到 1800 之间")

    # 在等待前固定父进程 PID；若父进程提前退出，超时后不会误伤其他进程。
    parent_pid = os.getppid()
    time.sleep(delay)

    if parent_pid <= 1:
        print("看门狗超时，但父进程 PID 无效；按安全策略不执行重启动作。", flush=True)
        return 0

    terminate_initialization_tree(parent_pid)
    return 124


if __name__ == "__main__":
    raise SystemExit(main())
