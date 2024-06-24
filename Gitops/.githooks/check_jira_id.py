"""
Verify that Git Commit Messages contain Jira IDs.

Invoked by `pre-commit`
"""

import re
import sys

failure_message = "FAILURE: You must include a Jira Story ID (e.g. [ENG-12345]) in your commit message."

pattern = re.compile(
    r"(\[(DEV|LAB|DOC|DCB|VOL|DEVOPS|OPS|ENG|CMP|INC|IN)-[0-9]+\])|(Merge (branch|pull))"
)

with open(sys.argv[1], "r") as f:
    commit_message = f.read().replace("\n", "")

if not bool(pattern.search(commit_message)):
    print(failure_message)
    exit(1)

exit(0)
