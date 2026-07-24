`jq` is not installed — the VERIFY block's `jq` extraction would silently fail (masked by `2>/dev/null || true`), but all acceptance checks passed via direct file reading and node.	TASK_0001
