# Git Rebase — Real-Time Push Error & Interview Guide

## 1. Real-Time Git Problem We Faced

While pushing the Terraform project to GitHub, we ran:

```bash
git push origin main
```

Git rejected the push:

```text
! [rejected] main -> main (fetch first)
```

This was a **Git non-fast-forward / branch divergence problem**.

It was **not a Terraform error**.

---

# 2. What Does `fetch first` Mean?

The important meaning is:

> **GitHub's `main` branch had commits that our local `main` branch did not have.**

Git rejected the push because directly pushing the local branch could overwrite commits that already existed on GitHub.

Git protects remote history by default.

---

# 3. Our Real-Time Commit History

Initially, both local and remote branches shared the same common commit:

```text
                 bfb9ed9
                    |
              common history
              /            \
        LOCAL main       origin/main
          |                  |
       ce9b299             eb1accf
```

The common commit was:

```text
bfb9ed9
```

From that common point, two different commits existed.

### Local commit

Our local Terraform changes created:

```text
ce9b299
Add Terraform backend and Jenkins IAM configuration
```

### Remote commit

GitHub had another commit:

```text
eb1accf
Create README.md
```

Therefore the history looked like:

```text
LOCAL                         GITHUB

bfb9ed9                       bfb9ed9
    |                             |
 ce9b299                       eb1accf
```

The branches had **diverged**.

---

# 4. What Is Branch Divergence?

Branch divergence means:

> Local and remote branches started from the same commit but then received different commits.

Example:

```text
                 A
                 |
             common point
             /           \
            B             C
         LOCAL          REMOTE
```

Local has `B`.

Remote has `C`.

Neither side contains the other side's commit.

Therefore a direct push may not be possible.

---

# 5. Why Did `git push` Fail?

We ran:

```bash
git push origin main
```

Git responded:

```text
! [rejected] main -> main (fetch first)
```

Git was essentially saying:

```text
Your local main is behind/diverged from origin/main.

I cannot safely replace the remote branch with your local history.
First integrate the remote changes.
```

This protection prevents accidental loss of remote commits.

---

# 6. First Step — `git fetch`

We ran:

```bash
git fetch origin
```

Output:

```text
From https://github.com/rakesh-perala/terraform-project
   bfb9ed9..eb1accf  main -> origin/main
```

`git fetch` downloads the latest information from the remote repository.

It updates our remote-tracking branch:

```text
origin/main
```

It does **not** automatically merge those changes into our current branch.

After fetch:

```text
LOCAL main                 origin/main

ce9b299                   eb1accf
    \                       /
     \                     /
       bfb9ed9
```

Now Git knows exactly what exists on both sides.

---

# 7. Why Did We Use `git rebase`?

We wanted our local Terraform changes to sit on top of the latest GitHub changes.

So we ran:

```bash
git rebase origin/main
```

This is the most important concept.

## Simple Definition

> **Git rebase takes my commits and replays them on top of another branch's latest commit.**

In our case:

```text
git rebase origin/main
```

means:

> Take my local commits and replay them on top of the latest `origin/main`.

---

# 8. Before Rebase

Our history was:

```text
                 bfb9ed9
                    |
             ┌──────┴──────┐
             ↓             ↓
          ce9b299       eb1accf
          LOCAL          REMOTE
```

Remember:

```text
ce9b299 = our Terraform work

eb1accf = GitHub README work
```

---

# 9. What Does Rebase Actually Do?

Conceptually, Git performs these steps:

```text
1. Identify the commits that exist only on our local branch.

2. Temporarily remove/replay those commits.

3. Move our branch to origin/main.

4. Replay our local changes on top of origin/main.

5. Create new commit(s) containing those changes.
```

So:

```text
Before:

                 bfb9ed9
                    |
             ┌──────┴──────┐
             ↓             ↓
          ce9b299       eb1accf
          LOCAL          REMOTE
```

After rebase:

```text
bfb9ed9
    |
 eb1accf
    |
 01ec504
    ↑
 LOCAL main
```

---

# 10. Very Important — Why Did the Commit ID Change?

This is one of the most important interview concepts.

Before rebase:

```text
ce9b299
```

After rebase:

```text
01ec504
```

So:

```text
ce9b299  →  01ec504
```

Why?

Because Git rebase **recreates/replays the commit on top of a different parent commit**.

A Git commit is not identified only by its message.

Its identity is affected by things such as:

```text
Commit content
Parent commit
Author information
Commit metadata
```

When the parent/history changes, the resulting commit gets a different hash.

Therefore:

```text
ce9b299
```

and

```text
01ec504
```

represent the replayed version of our change in the new history.

---

# 11. The Best Mental Model for Rebase

Think of two roads.

Initially:

```text
                 bfb9ed9
                    |
             ┌──────┴──────┐
             ↓             ↓
        Your work       GitHub work
        ce9b299         eb1accf
```

Git rebase says:

> "Take my work and put it after the latest GitHub work."

So Git creates:

```text
bfb9ed9
    |
 eb1accf
    |
 01ec504
```

That is rebase.

---

# 12. Why Did `git push` Work After Rebase?

After rebase, our history became:

```text
bfb9ed9
    |
 eb1accf
    |
 01ec504
    ↑
 LOCAL main
```

Now our local branch included:

```text
eb1accf
```

plus our Terraform changes:

```text
01ec504
```

So we ran:

```bash
git push origin main
```

and it succeeded:

```text
eb1accf..01ec504  main -> main
```

GitHub was updated successfully.

---

# 13. Final Verification

We then ran:

```bash
git rebase origin/main
```

Git responded:

```text
Current branch main is up to date.
```

This confirmed our local branch was synchronized with `origin/main`.

---

# 14. Another Error We Encountered During Rebase

Our first rebase attempt failed because of:

```text
error: The following untracked working tree files would be overwritten by checkout:
        terraform/tfplan
```

## Why?

There was a local untracked file:

```text
tfplan
```

Terraform plan files are generated artifacts.

Git did not want the rebase operation to overwrite that untracked file.

Our `.gitignore` already contained:

```gitignore
*.tfplan
```

So we safely removed the generated local file:

```bash
rm -f tfplan
```

Then:

```bash
git status
```

showed:

```text
nothing to commit, working tree clean
```

After that:

```bash
git rebase origin/main
```

succeeded.

---

# 15. Complete Real-Time Workflow We Used

Our actual workflow was:

```text
git push origin main
        |
        ↓
Push rejected
(fetch first)
        |
        ↓
git fetch origin
        |
        ↓
Remote history downloaded
        |
        ↓
Local and remote branches identified as divergent
        |
        ↓
git rebase origin/main
        |
        ↓
Local Terraform commit replayed
        |
        ↓
ce9b299 → 01ec504
        |
        ↓
git push origin main
        |
        ↓
Push successful
```

---

# 16. Interview Definition of Git Rebase

### Interview Answer

> **Git rebase is used to move or replay my branch commits on top of another branch's latest commit. It creates a cleaner and linear Git history by avoiding an unnecessary merge commit.**

---

# 17. Real-Time Interview Example

Suppose we have:

```text
A---B---C        main
     \
      D---E      feature
```

Meanwhile `main` receives new commits:

```text
A---B---C---F---G        main
     \
      D---E              feature
```

Now from the feature branch:

```bash
git rebase main
```

Git replays `D` and `E` after `G`:

```text
A---B---C---F---G---D'---E'
```

The important thing is:

```text
D → D'
E → E'
```

The commit IDs can change because Git recreated those commits on a new parent history.

---

# 18. Merge vs Rebase

## Merge

Command:

```bash
git merge main
```

Conceptually:

```text
A---B---C---F---G
     \         /
      D---E---M
```

`M` is a merge commit.

Merge preserves the branch history.

---

## Rebase

Command:

```bash
git rebase main
```

Conceptually:

```text
A---B---C---F---G---D'---E'
```

Rebase creates a linear history.

---

# 19. Merge vs Rebase Interview Table

| Merge                              | Rebase                          |
| ---------------------------------- | ------------------------------- |
| Combines two histories             | Replays commits                 |
| Can create a merge commit          | Usually no merge commit         |
| Preserves branch topology          | Creates linear history          |
| Does not rewrite existing commits  | Recreates commits               |
| Generally safer for shared history | Be careful with shared branches |
| History shows the actual merge     | History looks more linear       |

---

# 20. When Should You Avoid Rebase?

### Interview Answer

> **I avoid rebasing commits that have already been shared with other developers because rebase rewrites history and changes commit hashes. I normally use rebase on my local feature branch before sharing it, according to the team's Git workflow.**

The important rule is:

```text
Private/local feature branch
        ↓
Rebase is commonly acceptable

Shared branch
        ↓
Be careful with rebase
```

---

# 21. Why Didn't We Use `git push --force`?

We did **not** use:

```bash
git push --force
```

because GitHub contained a commit that we needed to preserve:

```text
eb1accf
Create README.md
```

Force pushing can replace remote branch history.

Instead, we integrated the remote history:

```text
git fetch
     ↓
git rebase origin/main
     ↓
git push origin main
```

This preserved the remote commit and our local Terraform changes.

---

# 22. Interview Question — Why Was Your Push Rejected?

### Strong Answer

> **My Git push was rejected with a fetch-first non-fast-forward error because my local main and remote main had diverged. I had a local Terraform commit that was not on GitHub, while GitHub had a README commit that was not in my local branch. I fetched the latest remote changes and rebased my local commit on top of origin/main. The rebase recreated my commit with a new hash because its parent changed. After verifying the branch was synchronized, I pushed successfully without force-pushing.**

---

# 23. Interview Question — What Is the Difference Between Fetch and Pull?

### `git fetch`

```bash
git fetch origin
```

Means:

> Download remote changes and update remote-tracking information, but don't automatically integrate them into my current branch.

### `git pull`

Conceptually:

```text
git pull
    =
git fetch
+
git merge/rebase
```

depending on the configured pull strategy/options.

For interview purposes:

> **Fetch lets me inspect remote changes before integrating them.**

---

# 24. Interview Question — Why Does Rebase Change Commit IDs?

### Answer

> **Because rebase recreates commits on top of a different parent commit. Since the commit's history and parent are part of what determines its SHA, the recreated commit receives a new commit ID.**

Example:

```text
Before:

bfb9ed9
   |
ce9b299
```

After rebase:

```text
bfb9ed9
   |
eb1accf
   |
01ec504
```

Therefore:

```text
ce9b299 → 01ec504
```

---

# 25. Interview Question — What Is the Difference Between Rebase and Reset?

Do not confuse these.

### Rebase

```bash
git rebase origin/main
```

Purpose:

> Replay my commits on top of another branch.

### Reset

```bash
git reset
```

Purpose:

> Move the current branch/HEAD and potentially change the staging area or working tree depending on the reset mode.

Simple memory:

```text
REBASE
↓
Rearrange/replay commit history

RESET
↓
Move HEAD/branch pointer
```

---

# 26. Interview Question — What Is the Difference Between Rebase and Restore?

### Restore

```bash
git restore file.txt
```

Primarily used to restore file content in the working tree or staging area.

### Rebase

```bash
git rebase main
```

Used to replay commits onto another base.

Memory:

```text
RESTORE
→ Files

REBASE
→ Commits/history
```

---

# 27. Enterprise Scenario

Imagine a DevOps team:

```text
main
 |
 +--- release changes
 |
 +--- security changes
 |
 +--- feature/JENKINS-245
```

A developer has been working on:

```text
feature/JENKINS-245
```

Meanwhile the team continues merging changes into `main`.

Before creating a PR, the developer may update the feature branch:

```bash
git fetch origin
git rebase origin/main
```

Conceptually:

```text
Before:

main:
A---B---C---D

feature:
A---B---C---X---Y
```

After main receives changes:

```text
main:
A---B---C---D---E---F

feature:
A---B---C---X---Y
```

After:

```bash
git rebase origin/main
```

the feature history becomes conceptually:

```text
A---B---C---D---E---F---X'---Y'
```

Now the feature work is based on the latest main history.

---

# 28. Git Rebase Memory Trick

Remember these three words:

```text
FETCH
  ↓
See remote changes

REBASE
  ↓
Put my commits on top

PUSH
  ↓
Send the updated history
```

Or simply:

> **FETCH → REBASE → PUSH**

---

# 29. The Most Important Diagram to Remember

Your actual Terraform incident:

```text
                    bfb9ed9
                 Common Commit
                      |
              ┌───────┴───────┐
              ↓               ↓
           ce9b299          eb1accf
           LOCAL             GITHUB
              \               /
               \             /
                \           /
              REBASE origin/main
                      |
                      ↓
                  eb1accf
                      |
                      ↓
                  01ec504
                      |
                      ↓
                    PUSH
                      |
                      ↓
               GitHub main
```

---

# 30. One-Line Definition to Never Forget

> **Rebase = Take my commits and replay them on top of the latest commit of another branch.**

And your real example:

```text
LOCAL:
bfb9ed9 → ce9b299

REMOTE:
bfb9ed9 → eb1accf

REBASE:

bfb9ed9 → eb1accf → 01ec504
                         ↑
                  replayed local work
```

The most important thing to remember is:

```text
ce9b299 → 01ec504
```

**The changes stayed; the commit ID changed because the commit was recreated on a new parent history.**

---

# 31. Final Interview Story

If the interviewer asks:

**"Tell me about a real Git issue you handled."**

You can explain:

> **"In one of my Terraform projects, I created a local commit and tried to push it to GitHub. The push was rejected with a fetch-first non-fast-forward error. I checked the history and found that local main and origin/main had diverged from a common commit. My local branch had the Terraform changes, while the remote branch had a README change. I fetched the remote history and rebased my local branch on top of origin/main. During the first rebase attempt, Git detected an untracked Terraform plan file that could be overwritten, so I removed the generated file after confirming it was ignored. The rebase then succeeded. My original commit hash changed because rebase recreated the commit on top of the new parent. Finally, I pushed the rebased branch successfully without using force push."**

This is a strong **real-world DevOps Git troubleshooting example** because it demonstrates:

```text
Git troubleshooting
        +
Branch divergence
        +
Fetch
        +
Rebase
        +
Commit history
        +
Non-fast-forward protection
        +
Untracked files
        +
Safe push
```
