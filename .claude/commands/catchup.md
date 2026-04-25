---
description: Summarize recent changes on the current branch (commits, diff vs master, status)
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git status:*), Bash(git branch:*)
---

Run these commands and produce a tight summary of what changed on this branch:

!`git branch --show-current`
!`git status --short`
!`git log --oneline master..HEAD 2>/dev/null || git log --oneline -10`
!`git diff --stat master...HEAD 2>/dev/null || git diff --stat HEAD~5...HEAD`

Then summarize in 5-10 bullets: what files changed, what each commit accomplishes, any visible TODOs or WIP markers, anything that looks unfinished or unreviewed. If the branch is `master` itself, summarize the last 10 commits instead.
