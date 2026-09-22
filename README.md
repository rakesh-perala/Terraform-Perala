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
# Git Revert and Cherry-Pick — Real-Time Enterprise & Interview Guide

This section explains two very important Git commands:

* `git revert`
* `git cherry-pick`

The explanations use **dummy commit IDs** so the Git history is easy to visualize.

---

# 32. Git Revert

## What Is `git revert`?

> **`git revert` creates a new commit that reverses the changes introduced by an earlier commit.**

The most important point:

> **Revert does NOT delete the old commit. It creates a new commit that undoes the changes.**

---

# 33. Simple Revert Example

Suppose our `main` branch looks like this:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   |
J1K2L3
```

Assume:

```text
A1B2C3 = Initial application
D4E5F6 = Add login
G7H8I9 = Add payment
J1K2L3 = Add monitoring
```

Now suppose we discover that:

```text
G7H8I9
Add payment
```

introduced a production problem.

We want to undo the payment changes.

We run:

```bash
git revert G7H8I9
```

Git creates a **new commit**:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   |
J1K2L3
   |
M4N5O6
```

Where:

```text
M4N5O6 = Revert "Add payment"
```

---

# 34. Very Important Revert Concept

Before:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   |
J1K2L3
```

After:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   |
J1K2L3
   |
M4N5O6
```

The original commit:

```text
G7H8I9
```

**still exists.**

Git did not remove it.

Instead:

```text
G7H8I9
   ↓
introduced changes

M4N5O6
   ↓
reverses those changes
```

This is why `git revert` is considered a **safe way to undo a change on a shared branch**.

---

# 35. Revert Mental Model

Think:

```text
Original commit
      ↓
   Add feature
      ↓
Production issue
      ↓
git revert
      ↓
New commit
      ↓
Undo that feature's changes
```

Remember:

> **Revert = Undo by creating another commit.**

---

# 36. Real-Time Production Example

Imagine a DevOps team deploys a banking application.

History:

```text
A10001
   |
B20002
   |
C30003
   |
D40004
```

Suppose:

```text
A10001 = Initial application
B20002 = User authentication
C30003 = Payment API
D40004 = Monitoring
```

After deployment, the team discovers:

```text
C30003
Payment API
```

is causing production failures.

The team wants to remove the payment changes while keeping the rest of the history.

They can run:

```bash
git revert C30003
```

Git creates:

```text
A10001
   |
B20002
   |
C30003
   |
D40004
   |
E50005
```

Where:

```text
E50005
Revert "Payment API"
```

The repository now clearly records:

```text
C30003 → Payment API was introduced

E50005 → Payment API changes were reverted
```

This gives the team an auditable history.

---

# 37. Why Is Revert Useful in Enterprise Teams?

Suppose your production branch is:

```text
main
```

and 20 developers are working with it.

You should generally avoid rewriting shared history just to remove a bad commit.

Instead:

```bash
git revert <commit-id>
```

creates a new commit.

Example:

```text
main

A---B---C---D---E
        ↑
      bad change

A---B---C---D---E---F
                    ↑
               revert commit
```

The history remains intact.

---

# 38. Revert vs Delete

This is very important.

### Revert

```text
Old commit remains
        +
New commit undoes it
```

### Delete/rewrite history

```text
Old commit is removed from visible branch history
```

Therefore:

```text
REVERT
↓
Preserve history
↓
Add an undo commit
```

---

# 39. Interview Question — What Is Git Revert?

### Strong Interview Answer

> **"Git revert is used to undo the changes introduced by a previous commit. Instead of deleting or rewriting the existing commit, Git creates a new commit that reverses those changes. I commonly use revert when I need to safely undo a change on a shared branch such as main or a production branch."**

---

# 40. Interview Question — Why Use Revert Instead of Reset?

### Answer

> **"Reset moves the branch pointer and can rewrite local history depending on the reset mode, whereas revert creates a new commit that reverses an earlier commit. For shared branches, I prefer revert because it preserves the existing commit history."**

Simple memory:

```text
RESET
↓
Move HEAD / rewrite local history

REVERT
↓
Create new commit that undoes changes
```

---

# 41. Git Revert Command

To revert a specific commit:

```bash
git revert <commit-id>
```

Example:

```bash
git revert G7H8I9
```

Git may open an editor for the revert commit message.

You can then verify:

```bash
git log --oneline
```

Example:

```text
M4N5O6 Revert "Add payment"
J1K2L3 Add monitoring
G7H8I9 Add payment
D4E5F6 Add login
A1B2C3 Initial application
```

---

# 42. Git Cherry-Pick

Now let's understand:

```bash
git cherry-pick
```

## Simple Definition

> **`git cherry-pick` takes a specific commit from another branch and applies that commit's changes to your current branch.**

This is different from merge and rebase.

You are saying:

> "I don't want the entire branch. I only want this particular commit."

---

# 43. Simple Cherry-Pick Example

Suppose we have:

```text
main:

A1B2C3
   |
D4E5F6
   |
G7H8I9
```

And another branch:

```text
feature/payment:

A1B2C3
   |
D4E5F6
   |
P1Q2R3
   |
S4T5U6
```

Suppose:

```text
P1Q2R3 = Add payment validation
S4T5U6 = Add payment UI
```

The production branch only needs:

```text
P1Q2R3
```

We don't want:

```text
S4T5U6
```

So we can cherry-pick only `P1Q2R3`.

---

# 44. Cherry-Pick Command

First switch to the branch that should receive the change:

```bash
git checkout main
```

Then:

```bash
git cherry-pick P1Q2R3
```

Git applies the changes from `P1Q2R3` to `main`.

Conceptually:

### Before

```text
main:

A1B2C3
   |
D4E5F6
   |
G7H8I9


feature/payment:

A1B2C3
   |
D4E5F6
   |
P1Q2R3
   |
S4T5U6
```

### After cherry-pick

```text
main:

A1B2C3
   |
D4E5F6
   |
G7H8I9
   |
V7W8X9
```

Where:

```text
V7W8X9
Cherry-pick "Add payment validation"
```

The original:

```text
P1Q2R3
```

still exists on the feature branch.

The new commit:

```text
V7W8X9
```

contains the equivalent changes on `main`.

---

# 45. Very Important Cherry-Pick Concept

Notice:

```text
P1Q2R3 → V7W8X9
```

The commit ID changes.

Why?

Because Git creates a new commit on the target branch.

So:

```text
Original commit
      ↓
P1Q2R3

Cherry-pick
      ↓
New commit
      ↓
V7W8X9
```

Remember:

> **Cherry-pick copies the changes from a specific commit and creates a new commit on your current branch.**

---

# 46. Real-Time Enterprise Example

Imagine your team has:

```text
main
develop
release
hotfix
```

A developer discovers a security fix.

They create:

```text
feature/security-fix
```

and commit:

```text
SEC123
Fix authentication validation
```

The security fix is needed immediately in:

```text
production
```

But the entire feature branch contains other unfinished work.

Instead of merging the whole feature branch, the team can selectively apply the security commit.

For example:

```bash
git checkout main
git cherry-pick SEC123
```

Conceptually:

```text
feature/security-fix

A---B---C---SEC123---D---E
          ↑
      needed fix


main

A---B---F

After cherry-pick:

A---B---F---SEC123'
```

Only the required commit is brought into `main`.

---

# 47. Another Common DevOps Example — Hotfix

Suppose:

```text
release/1.5

A---B---C---H
          ↑
       hotfix
```

The same hotfix is needed in:

```text
main
```

But `main` has moved ahead:

```text
main

A---B---D---E---F
```

Instead of merging the whole release branch:

```bash
git checkout main
git cherry-pick H
```

Conceptually:

```text
Before:

release:
A---B---C---H

main:
A---B---D---E---F
```

After:

```text
main:

A---B---D---E---F---H'
```

Only the hotfix changes are copied.

---

# 48. Interview Question — What Is Cherry-Pick?

### Strong Interview Answer

> **"Git cherry-pick allows me to apply the changes from a specific commit onto my current branch without merging the entire source branch. I use it when I need a particular bug fix or hotfix from another branch. Git creates a new commit on the target branch."**

---

# 49. Interview Question — Why Does Cherry-Pick Create a New Commit ID?

### Answer

> **"Cherry-pick applies the changes from the source commit to the current branch and creates a new commit there. Because the new commit has a different parent and commit metadata/history, it receives a different SHA."**

Example:

```text
Original:

P1Q2R3
   |
   ↓
Feature branch


Cherry-pick:

P1Q2R3
   |
   ↓
Changes copied
   |
   ↓
V7W8X9
   |
   ↓
Main branch
```

---

# 50. Revert vs Cherry-Pick

This is an important interview comparison.

| Revert                                          | Cherry-Pick                               |
| ----------------------------------------------- | ----------------------------------------- |
| Undoes a commit                                 | Applies a commit                          |
| Creates a new commit                            | Creates a new commit                      |
| Used to reverse changes                         | Used to selectively copy changes          |
| Usually used on shared branches to undo changes | Used when a specific commit is needed     |
| Example: remove a bad production change         | Example: bring a hotfix to another branch |

Simple memory:

```text
REVERT
↓
UNDO this commit

CHERRY-PICK
↓
TAKE this commit
```

---

# 51. Rebase vs Revert vs Cherry-Pick

| Command           | Main Purpose                                 |
| ----------------- | -------------------------------------------- |
| `git rebase`      | Replay commits on another base               |
| `git revert`      | Undo a commit with a new commit              |
| `git cherry-pick` | Copy a specific commit to the current branch |

Memory:

```text
REBASE
"Move/replay my commits"

REVERT
"Undo that commit"

CHERRY-PICK
"Give me that specific commit"
```

---

# 52. One Diagram for All Three

Imagine:

```text
                 A
                 |
                 B
              /     \
             C       D
             |       |
             E       F
```

### Rebase

Take your commits and replay them on another base:

```text
A---B---D---F---C'---E'
```

### Revert

Undo commit `C`:

```text
A---B---C---E---R
                ↑
          revert of C
```

### Cherry-pick

Take only commit `C` to another branch:

```text
Source:
A---B---C

Target:
A---B---D---C'
```

---

# 53. Real-Time Decision Guide

When you have a Git problem, think:

```text
What do I need?
       |
       ├── Update my branch with another branch's history?
       │          ↓
       │       REBASE
       │
       ├── Undo a bad/shared commit?
       │          ↓
       │       REVERT
       │
       └── Take only one specific commit?
                  ↓
             CHERRY-PICK
```

---

# 54. Interview Scenario

### Interviewer:

> "A developer pushed a bad commit to production. What would you do?"

### Answer:

> **"If the commit is already part of the shared production history, I would normally use `git revert` rather than rewriting the shared history. Revert creates a new commit that reverses the bad change while preserving the existing commit history."**

---

# 55. Interview Scenario

### Interviewer:

> "A security fix exists on another branch, but you don't want to merge the entire branch. What would you do?"

### Answer:

> **"I would identify the specific commit containing the security fix and cherry-pick that commit onto the target branch. This allows me to selectively apply only the required change without bringing the entire branch history."**

---

# 56. Interview Scenario

### Interviewer:

> "Your feature branch is behind main. What can you do?"

### Answer:

> **"I can update my feature branch by merging main into it or by rebasing my feature branch onto the latest main, depending on the team's Git workflow. Rebase gives a linear history but rewrites the feature branch commits, so I use it carefully if the branch is already shared."**

---

# 57. The Three Commands — Easy Memory

## `git rebase`

```text
MY COMMITS
     ↓
Replay on latest base
     ↓
New history
```

## `git revert`

```text
BAD COMMIT
     ↓
Create undo commit
     ↓
History preserved
```

## `git cherry-pick`

```text
SPECIFIC COMMIT
     ↓
Copy changes
     ↓
New commit on current branch
```

---

# 58. Most Important Interview Memory

Remember these three sentences:

> **Rebase:** "Put my commits on top of another branch."

> **Revert:** "Undo a commit by creating a new commit."

> **Cherry-pick:** "Take one specific commit and apply it to my current branch."

---

# 59. Commit ID Visualization — Final Memory

### Rebase

```text
Before:

A
|
B
|\
C D
  |
  E


After rebase:

A
|
B
|
D
|
E
|
C'
```

---

### Revert

```text
Before:

A---B---C---D

C = Bad change
```

After:

```text
A---B---C---D---R

R = Revert C
```

**C still exists.**

---

### Cherry-Pick

```text
Source branch:

A---B---C---D
        ↑
     wanted


Target branch:

A---B---X---Y
```

After:

```text
A---B---X---Y---C'
                 ↑
          cherry-picked commit
```

**C still exists on the source branch.**

---

# 60. Final Interview Cheat Sheet

```text
┌──────────────┬─────────────────────────────────────┐
│ COMMAND      │ PURPOSE                             │
├──────────────┼─────────────────────────────────────┤
│ REBASE       │ Replay commits on a new base        │
│ REVERT       │ Undo a commit with a new commit     │
│ CHERRY-PICK  │ Apply one specific commit           │
└──────────────┴─────────────────────────────────────┘
```

### One-line memory:

```text
REBASE       → MOVE/REPLAY
REVERT       → UNDO
CHERRY-PICK  → COPY ONE COMMIT
```

---

# 61. Strong 7-Year-Level Interview Answer

If an interviewer asks:

> **"Explain rebase, revert and cherry-pick with real-world examples."**

You can answer:

> **"Rebase, revert, and cherry-pick solve different Git problems. I use rebase when I need to replay my feature branch commits on top of the latest target branch and maintain a linear history, usually before sharing the feature branch. I use revert when I need to undo a change that has already been pushed to a shared branch such as main or production, because revert preserves the existing history and creates a new inverse commit. I use cherry-pick when I need to selectively apply a specific commit from another branch, such as bringing a production hotfix or security fix without merging the entire branch. Rebase and cherry-pick can create new commit IDs because the changes are recreated in a different history, while revert intentionally adds a new commit that reverses an existing commit."**

---

# 62. Final Memory Table

| Situation                           | Command                           | Think                       |
| ----------------------------------- | --------------------------------- | --------------------------- |
| My branch needs latest main history | `git rebase main`                 | **Replay**                  |
| Bad commit already shared           | `git revert <commit>`             | **Undo**                    |
| Need one particular commit          | `git cherry-pick <commit>`        | **Copy**                    |
| Remote has commits I don't have     | `git fetch origin`                | **See remote**              |
| Local and remote diverged           | `git rebase origin/main` or merge | **Integrate**               |
| Push rejected as non-fast-forward   | Fetch + integrate + push          | **Don't force immediately** |

---

# 63. Final Mental Model

```text
                    GIT HISTORY
                         |
          ┌──────────────┼──────────────┐
          ↓              ↓              ↓
       REBASE          REVERT       CHERRY-PICK
          |              |              |
          ↓              ↓              ↓
     Replay commits   Undo changes   Copy one commit
          |              |              |
          ↓              ↓              ↓
      New history     New commit     New commit
```

## Never Forget This

```text
REBASE
"My commits → new base"

REVERT
"That commit → undo it"

CHERRY-PICK
"That one commit → bring it here"
```

These three commands are different tools for different Git problems. Understanding the **commit graph first** makes the commands much easier to reason about.
# Git Reset and Important Git Commands — Dummy Commit ID Interview Guide

This section continues the Git interview guide.

The goal is not just to memorize commands.

The goal is to understand:

```text
COMMIT GRAPH
     ↓
What happened?
     ↓
What does Git need?
     ↓
Which command should I use?
```

---

# 64. Git Reset

## What Is `git reset`?

> **`git reset` moves the current branch/HEAD to another commit and can optionally change the staging area and working tree depending on the reset mode.**

The three important modes are:

```text
git reset --soft
git reset --mixed
git reset --hard
```

The biggest interview mistake is thinking:

> "Reset simply deletes a commit."

That is not a complete explanation.

Reset primarily **moves the branch pointer (`HEAD`)**.

What happens to staged and working files depends on the mode.

---

# 65. Simple Git Reset Example

Suppose our branch is:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   |
J1K2L3
   ↑
  HEAD
  main
```

Assume:

```text
A1B2C3 = Initial project
D4E5F6 = Login feature
G7H8I9 = Payment feature
J1K2L3 = Monitoring feature
```

Now we decide:

> "I want my branch pointer to go back to `G7H8I9`."

We can run:

```bash
git reset G7H8I9
```

Now:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   ↑
  HEAD
  main

J1K2L3
```

The branch pointer moved backward.

---

# 66. What Happened to `J1K2L3`?

This is important.

The commit:

```text
J1K2L3
```

was not necessarily immediately destroyed.

It is no longer pointed to by `main`.

It may still be reachable through Git's reflog for some time.

Conceptually:

```text
Before:

A---B---C---D
            ↑
           main


After reset:

A---B---C
        ↑
       main

D
```

The branch pointer moved from `D` to `C`.

---

# 67. Git Reset Mental Model

Remember:

> **Reset = Move my branch pointer backward/forward to another commit.**

Example:

```text
Before:

A---B---C---D
            ↑
           main


After:

A---B---C
        ↑
       main
```

The important thing is:

```text
main
 ↓
moves
 ↓
C
```

---

# 68. `git reset --soft`

Command:

```bash
git reset --soft HEAD~1
```

Suppose:

```text
A---B---C
        ↑
       HEAD
```

Run:

```bash
git reset --soft HEAD~1
```

Result:

```text
A---B
    ↑
   HEAD

C
```

But the changes introduced by `C` remain **staged**.

Think:

```text
Commit removed from branch
        ↓
Changes remain
        ↓
Staged
```

---

# 69. Soft Reset Example

Suppose you accidentally created:

```text
C12345
Add Jenkins pipeline
```

But you realize:

> "I forgot to include one more file."

Instead of creating another unnecessary commit, you can:

```bash
git reset --soft HEAD~1
```

Then the changes from that commit remain staged.

You can modify the missing file and create a corrected commit.

---

# 70. Soft Reset Diagram

Before:

```text
A---B---C
        ↑
       HEAD
```

After:

```text
A---B
    ↑
   HEAD

C's changes
     ↓
   STAGED
```

Memory:

```text
SOFT
↓
Move commit
↓
Keep changes staged
```

---

# 71. `git reset --mixed`

Command:

```bash
git reset --mixed HEAD~1
```

This is also the default reset mode.

Result:

```text
A---B
    ↑
   HEAD

C's changes
     ↓
WORKING TREE
```

The commit is removed from the current branch pointer.

The changes remain in your working directory but are **unstaged**.

Memory:

```text
MIXED
↓
Move commit
↓
Keep changes
↓
Unstage them
```

---

# 72. Mixed Reset Example

Suppose:

```text
A---B---C
        ↑
       main
```

Run:

```bash
git reset HEAD~1
```

Because `mixed` is the default:

```text
A---B
    ↑
   main

C's file changes
       ↓
Working tree
       ↓
Unstaged
```

You can then modify the files and stage only what you actually want.

---

# 73. `git reset --hard`

Command:

```bash
git reset --hard HEAD~1
```

This moves the branch pointer and resets the staging area and working tree to match the target commit.

Example:

```text
Before:

A---B---C
        ↑
       main
```

After:

```text
A---B
    ↑
   main

C
```

The changes introduced by `C` are removed from the current working tree.

### WARNING

Do not use:

```bash
git reset --hard
```

carelessly.

If the changes are not safely stored somewhere, they can be difficult to recover.

---

# 74. Reset Modes — Easy Table

| Command         | HEAD  | Staging              | Working Tree  |
| --------------- | ----- | -------------------- | ------------- |
| `reset --soft`  | Moves | Keeps changes staged | Keeps changes |
| `reset --mixed` | Moves | Unstages changes     | Keeps changes |
| `reset --hard`  | Moves | Resets               | Resets        |

Memory:

```text
SOFT
↓
Staged

MIXED
↓
Unstaged

HARD
↓
Discard working changes
```

---

# 75. Reset vs Revert

This is one of the most common interview questions.

## Reset

```text
A---B---C
        ↑
       main

reset to B

A---B
    ↑
   main
```

The branch pointer moves.

## Revert

```text
A---B---C---D
        ↑
       bad commit

revert C

A---B---C---D---E
                ↑
          undo C changes
```

The original commit remains.

### Memory:

```text
RESET
→ Move branch pointer

REVERT
→ Create new undo commit
```

---

# 76. Reset vs Restore

These are also frequently confused.

## Reset

Works primarily with:

```text
HEAD
branch pointer
staging area
working tree
```

depending on mode.

## Restore

Primarily restores file content.

Example:

```bash
git restore app.py
```

Meaning:

> Restore `app.py` from the appropriate Git state.

Memory:

```text
RESET
→ Commit/HEAD/staging history

RESTORE
→ File content
```

---

# 77. Git HEAD

`HEAD` is one of the most important Git concepts.

> **HEAD represents the commit/branch that your current working state is based on.**

Suppose:

```text
A1B2C3
   |
D4E5F6
   |
G7H8I9
   ↑
  HEAD
```

You are currently at:

```text
G7H8I9
```

You can check:

```bash
git log --oneline
```

---

# 78. `HEAD~1`

Suppose:

```text
A
|
B
|
C
|
D
↑
HEAD
```

Then:

```text
HEAD      = D
HEAD~1    = C
HEAD~2    = B
HEAD~3    = A
```

Example:

```bash
git reset --soft HEAD~1
```

means:

> Move HEAD back by one commit.

---

# 79. `HEAD^`

For a normal linear history:

```text
A---B---C
        ↑
       HEAD
```

Then:

```text
HEAD^
```

means:

```text
B
```

And:

```text
HEAD~1
```

also means:

```text
B
```

for this simple case.

---

# 80. Git Stash

## What Is Stash?

> **Git stash temporarily stores uncommitted changes so you can work on another task without committing incomplete work.**

Suppose:

```text
main
 |
A---B
```

You are modifying:

```text
application.yml
Dockerfile
Jenkinsfile
```

but suddenly your lead asks:

> "Production issue! Switch to the hotfix branch."

You don't want to commit unfinished work.

Run:

```bash
git stash
```

Conceptually:

```text
Working changes
      ↓
    STASH
      ↓
Working tree clean
```

Then work on the hotfix.

Later:

```bash
git stash pop
```

Your changes return.

---

# 81. Stash Diagram

Before:

```text
A---B
    ↑
   main

Working changes:
+ Dockerfile
+ Jenkinsfile
```

Run:

```bash
git stash
```

Then:

```text
A---B
    ↑
   main

Working tree clean

Stash:
Dockerfile changes
Jenkinsfile changes
```

Later:

```bash
git stash pop
```

The changes return.

---

# 82. Stash vs Commit

| Stash                                      | Commit                          |
| ------------------------------------------ | ------------------------------- |
| Temporary storage                          | Permanent project history       |
| Usually for incomplete work                | Used for completed logical work |
| Not normally part of shared branch history | Can be pushed/shared            |
| Useful during context switching            | Used to record project changes  |

Memory:

```text
STASH
→ "I am not finished yet."

COMMIT
→ "This logical change is ready to record."
```

---

# 83. Git Fetch vs Pull

## Fetch

```bash
git fetch origin
```

Means:

> Download remote information without automatically integrating it into my current branch.

Example:

```text
GitHub:

A---B---C

Local:

A---B
```

After:

```bash
git fetch origin
```

Git knows:

```text
origin/main → C
main        → B
```

but your local `main` has not automatically moved to `C`.

---

# 84. Git Pull

`git pull` generally performs:

```text
git fetch
+
integration
```

The integration may be a merge or rebase depending on configuration/options.

Example:

```bash
git pull
```

Conceptually:

```text
Fetch remote changes
        ↓
Integrate them
        ↓
Update local branch
```

Memory:

```text
FETCH
→ Download

PULL
→ Download + Integrate
```

---

# 85. `git pull --rebase`

Instead of creating a merge commit, a team may configure or explicitly use:

```bash
git pull --rebase
```

Conceptually:

```text
Remote:

A---B---C


Local:

A---B---D
```

After pull with rebase:

```text
A---B---C---D'
```

Your local commit is replayed on top of the latest remote commit.

---

# 86. Git Merge

Suppose:

```text
main:

A---B---C


feature:

A---B---D---E
```

We switch to main:

```bash
git checkout main
```

Then:

```bash
git merge feature
```

Git combines the histories.

Depending on the history, this can result in a merge commit:

```text
A---B---C-------M
     \         /
      D---E----
```

Where:

```text
M = merge commit
```

---

# 87. Fast-Forward Merge

Suppose:

```text
main:

A---B

feature:

A---B---C---D
```

If main has not moved independently, Git can simply move the main pointer:

```text
A---B---C---D
            ↑
           main
```

This is called:

> **Fast-forward merge.**

No merge commit is required.

---

# 88. Non-Fast-Forward Merge

Suppose:

```text
A---B---C
     \
      D---E
```

Both branches have independent work.

Git may need a merge commit:

```text
A---B---C------M
     \        /
      D---E---
```

This is a non-fast-forward merge.

---

# 89. Git Diff

`git diff` shows differences between Git states.

Example:

```bash
git diff
```

Shows:

```text
Working tree
     ↓
Compared with
     ↓
Index/staged state
```

For staged changes:

```bash
git diff --staged
```

Memory:

```text
git diff
→ Unstaged changes

git diff --staged
→ Staged changes
```

---

# 90. Git Log

Use:

```bash
git log --oneline --graph --decorate
```

This is extremely useful when troubleshooting branch history.

Example:

```text
* 91AB22D Add monitoring
* 72CD34E Add Jenkins pipeline
|\
| * 55EF67A Update README
|/
* 11AA22B Initial project
```

This helps you understand:

```text
Branches
Commits
Merges
HEAD
Divergence
```

---

# 91. Git Reflog

This is one of the most important senior-level Git troubleshooting commands.

> **Reflog records movements of HEAD and branch references in your local repository.**

Suppose you accidentally run:

```bash
git reset --hard HEAD~2
```

and think:

> "Oh no! My commits disappeared!"

First:

```bash
git reflog
```

You may see:

```text
91AB22D HEAD@{0}: reset: moving to HEAD~2
72CD34E HEAD@{1}: commit: Add monitoring
55EF67A HEAD@{2}: commit: Add Jenkins pipeline
```

You can identify the previous commit:

```text
72CD34E
```

Then potentially recover by moving the branch back:

```bash
git reset --hard 72CD34E
```

### Interview memory:

> **Reflog is my local safety net for recovering lost Git references.**

---

# 92. Git Commit Amend

Suppose:

```text
A---B
    ↑
   HEAD
```

You committed:

```text
git commit -m "Add Jenkins pipeline"
```

Then realize:

> "I forgot to include Jenkinsfile."

You can stage the file:

```bash
git add Jenkinsfile
```

Then:

```bash
git commit --amend
```

Instead of creating:

```text
A---B---C
```

you update the previous commit.

Conceptually:

```text
Before:

A---B


After amend:

A---B'
```

The commit ID changes because the commit was recreated.

---

# 93. Git Clean

`git clean` removes untracked files.

First preview:

```bash
git clean -n
```

Example:

```text
Would remove test.txt
Would remove temp.log
```

Then, if you are sure:

```bash
git clean -f
```

Be careful with:

```bash
git clean -fd
```

because it can remove untracked directories too.

Memory:

```text
git clean
→ Untracked files/directories
```

---

# 94. Git Tag

Tags are commonly used to identify releases.

Example:

```text
A---B---C---D
        ↑
       v1.0.0
```

Create:

```bash
git tag v1.0.0
```

Push:

```bash
git push origin v1.0.0
```

Enterprise example:

```text
v1.0.0 → Production release
v1.1.0 → New feature release
v1.1.1 → Bug-fix release
```

---

# 95. Git Branch

A branch is essentially a movable reference to a commit.

Example:

```text
A---B---C
        ↑
       main
```

Create:

```bash
git branch feature/login
```

Now:

```text
A---B---C
        ↑
       main
       feature/login
```

When you commit on the feature branch:

```text
A---B---C---D
        ↑   ↑
       main feature/login
```

Actually, after switching and committing:

```text
A---B---C
        ↑
       main
        \
         D
         ↑
      feature/login
```

The important concept:

> **A branch is a pointer/reference to a commit.**

---

# 96. Detached HEAD

Normally:

```text
A---B---C
        ↑
       main
        ↑
       HEAD
```

But if you checkout a commit directly:

```bash
git checkout B
```

you may enter:

```text
A---B---C
    ↑
   HEAD
```

HEAD is now pointing directly to a commit rather than a branch.

This is called:

> **Detached HEAD state.**

If you create commits there and want to keep them, create a branch:

```bash
git switch -c recovery-branch
```

---

# 97. Git Cherry-Pick Recap

Suppose:

```text
feature:

A---B---C---D
        ↑
       wanted
```

Target:

```text
main:

A---B---E
```

Run:

```bash
git cherry-pick C
```

Result:

```text
main:

A---B---E---C'
```

Memory:

```text
CHERRY-PICK
→ Bring one specific commit
```

---

# 98. Git Revert Recap

Suppose:

```text
A---B---C---D
        ↑
       bad
```

Run:

```bash
git revert C
```

Result:

```text
A---B---C---D---R
                ↑
             revert C
```

Memory:

```text
REVERT
→ Undo through a new commit
```

---

# 99. Git Rebase Recap

Suppose:

```text
main:

A---B---C

feature:

A---B---D---E
```

Main moves:

```text
A---B---C---F---G
```

Rebase:

```bash
git rebase main
```

Result:

```text
A---B---C---F---G---D'---E'
```

Memory:

```text
REBASE
→ Replay my commits on a new base
```

---

# 100. Reset vs Restore vs Revert vs Rebase

This is an extremely important interview table.

| Command   | Main purpose                     | Commit history             |
| --------- | -------------------------------- | -------------------------- |
| `reset`   | Move HEAD/branch pointer         | Can rewrite history        |
| `restore` | Restore file content             | Does not create commit     |
| `revert`  | Undo an earlier commit           | Creates new commit         |
| `rebase`  | Replay commits onto another base | Rewrites/recreates commits |

Easy memory:

```text
RESET
→ MOVE

RESTORE
→ FILE

REVERT
→ UNDO

REBASE
→ REPLAY
```

---

# 101. Merge vs Rebase vs Cherry-Pick

| Command     | What are we trying to do?            |
| ----------- | ------------------------------------ |
| Merge       | Combine entire branch histories      |
| Rebase      | Replay our commits onto another base |
| Cherry-pick | Apply one specific commit            |

Memory:

```text
MERGE
→ "Bring the branch"

REBASE
→ "Move/replay my commits"

CHERRY-PICK
→ "Bring this one commit"
```

---

# 102. Stash vs Reset

| Stash                                  | Reset                                   |
| -------------------------------------- | --------------------------------------- |
| Temporarily stores uncommitted work    | Moves HEAD/branch pointer               |
| Useful for context switching           | Useful for changing local history/state |
| Does not normally alter commit history | Can rewrite local history               |
| Work can be restored later             | Depends on reset mode                   |

---

# 103. Merge Conflict

Suppose:

```text
main:

A---B---C
        \
         main changes


feature:

A---B---D
        \
         feature changes
```

Both branches changed the same lines.

During merge:

```bash
git merge feature
```

Git may report:

```text
CONFLICT (content): Merge conflict in application.yml
```

Git stops and asks you to resolve the conflict.

Typical process:

```text
git merge
     ↓
CONFLICT
     ↓
Open conflicting file
     ↓
Resolve conflict
     ↓
git add file
     ↓
git commit
```

---

# 104. Rebase Conflict

Rebase can also produce conflicts.

Example:

```bash
git rebase origin/main
```

If conflict occurs:

```text
CONFLICT
```

Resolve the file.

Then:

```bash
git add <file>
git rebase --continue
```

If you decide to cancel:

```bash
git rebase --abort
```

Memory:

```text
REBASE CONFLICT
→ resolve
→ git add
→ git rebase --continue

Want to cancel?
→ git rebase --abort
```

---

# 105. Merge Conflict vs Rebase Conflict

The conflict itself is not fundamentally different:

```text
Two changes
     ↓
Same area
     ↓
Git cannot automatically decide
     ↓
CONFLICT
```

The continuation commands differ.

### Merge

```bash
git add <file>
git commit
```

### Rebase

```bash
git add <file>
git rebase --continue
```

Abort:

```bash
git merge --abort
```

or:

```bash
git rebase --abort
```

---

# 106. Git Bisect

`git bisect` is useful when a bug was introduced somewhere in Git history.

Suppose:

```text
A---B---C---D---E---F
                ↑
           bug discovered
```

You know:

```text
A = good
F = bad
```

But you don't know which commit introduced the bug.

Run:

```bash
git bisect start
git bisect bad
git bisect good A
```

Git checks a middle commit.

You test it.

Tell Git:

```bash
git bisect good
```

or:

```bash
git bisect bad
```

Git continues narrowing the range.

Eventually:

```text
C = good
D = bad
```

You identify the problematic commit.

Memory:

> **Git bisect = binary search through commit history to find the commit that introduced a bug.**

---

# 107. Git Blame

`git blame` shows which commit last changed each line of a file.

Example:

```bash
git blame application.yml
```

You may see:

```text
72AB91 developer1  server.port=8080
83CD44 developer2  spring.datasource.url=...
```

This does not mean:

> "Blame the developer."

It means:

> **Identify the commit and author associated with the last modification of each line.**

Useful for troubleshooting configuration changes.

---

# 108. Git Remote

Check configured remotes:

```bash
git remote -v
```

Example:

```text
origin  https://github.com/company/project.git (fetch)
origin  https://github.com/company/project.git (push)
```

Memory:

```text
origin
→ Name of the remote repository
```

---

# 109. Git Clone

Clone a repository:

```bash
git clone <repository-url>
```

Conceptually:

```text
GitHub repository
       ↓
     clone
       ↓
Local repository
       ↓
Working directory
```

Clone normally creates:

```text
.git/
working files
remote configuration
```

---

# 110. Git Status

One of the first commands to use when troubleshooting:

```bash
git status
```

It tells you things such as:

```text
Current branch
Ahead/behind information
Staged changes
Unstaged changes
Untracked files
Merge/rebase state
```

Memory:

> **When in doubt, start with `git status`.**

---

# 111. Git Log — Useful Interview Command

A very useful command:

```bash
git log --oneline --graph --decorate --all
```

Example:

```text
* 01EC504 (HEAD -> main, origin/main) Add Terraform backend
* EB1ACCF Create README
|\
| * ABC1234 Previous feature
|/
* BFB9ED9 Initial project
```

This lets you visually understand the commit graph.

---

# 112. Enterprise Git Troubleshooting Flow

When something goes wrong:

```text
Git problem
     |
     ↓
git status
     |
     ↓
Understand current state
     |
     ↓
git log --oneline --graph --decorate --all
     |
     ↓
Understand commit history
     |
     ├── Remote has new commits?
     │        ↓
     │      fetch
     │
     ├── Need to undo shared commit?
     │        ↓
     │      revert
     │
     ├── Need one specific commit?
     │        ↓
     │      cherry-pick
     │
     ├── Need to replay feature commits?
     │        ↓
     │      rebase
     │
     └── Need to move local HEAD?
              ↓
            reset
```

---

# 113. Senior-Level Git Decision Tree

```text
What is the problem?
        |
        +--- Remote has changes
        |       |
        |       +--- git fetch
        |       |
        |       +--- merge or rebase
        |
        +--- Bad shared commit
        |       |
        |       +--- git revert
        |
        +--- Need one commit from another branch
        |       |
        |       +--- git cherry-pick
        |
        +--- Need to move local branch back
        |       |
        |       +--- git reset
        |
        +--- Need to restore a file
        |       |
        |       +--- git restore
        |
        +--- Need temporary unfinished work
        |       |
        |       +--- git stash
        |
        +--- Accidentally lost commit
        |       |
        |       +--- git reflog
        |
        +--- Bug somewhere in history
                |
                +--- git bisect
```

---

# 114. Most Important Git Commands for DevOps Interviews

```text
git clone
git status
git add
git commit
git push
git fetch
git pull
git pull --rebase
git merge
git rebase
git revert
git cherry-pick
git reset
git restore
git stash
git reflog
git log
git diff
git branch
git switch
git tag
git remote
git clean
git commit --amend
git bisect
git blame
```

---

# 115. Final Memory Table

| Command       | Easy meaning                            |
| ------------- | --------------------------------------- |
| `clone`       | Copy repository                         |
| `status`      | What is my Git state?                   |
| `add`         | Stage changes                           |
| `commit`      | Record changes                          |
| `push`        | Send commits to remote                  |
| `fetch`       | Download remote information             |
| `pull`        | Fetch + integrate                       |
| `merge`       | Combine branches                        |
| `rebase`      | Replay commits on another base          |
| `revert`      | Undo with a new commit                  |
| `cherry-pick` | Copy one specific commit                |
| `reset`       | Move HEAD/branch pointer                |
| `restore`     | Restore file content                    |
| `stash`       | Temporarily store changes               |
| `reflog`      | Recover/reference previous local states |
| `diff`        | Compare changes                         |
| `log`         | View history                            |
| `tag`         | Mark a release/commit                   |
| `clean`       | Remove untracked files                  |
| `amend`       | Modify latest commit                    |
| `bisect`      | Find bug-introducing commit             |
| `blame`       | Find commit/author for line changes     |

---

# 116. The Four Commands You Must Never Confuse

```text
                 GIT
                  |
       ┌──────────┼──────────┬──────────┐
       ↓          ↓          ↓          ↓
     RESET      RESTORE    REVERT     REBASE
       |          |          |          |
       ↓          ↓          ↓          ↓
      MOVE       FILE       UNDO      REPLAY
```

### RESET

> Move the branch/HEAD.

### RESTORE

> Restore file content.

### REVERT

> Create a new commit that undoes an earlier commit.

### REBASE

> Replay commits on top of another base.

---

# 117. The Five Commands You Should Explain With Commit IDs

When an interviewer asks for practical Git knowledge, use diagrams.

## Reset

```text
A---B---C
        ↑
       main

reset B

A---B
    ↑
   main
```

## Revert

```text
A---B---C---D

revert C

A---B---C---D---E
                ↑
             undo C
```

## Rebase

```text
A---B---C
     \
      D---E

rebase onto C

A---B---C---D'---E'
```

## Cherry-pick

```text
Source:
A---B---C

Target:
A---B---D

cherry-pick C

Target:
A---B---D---C'
```

## Merge

```text
A---B---C
     \   /
      D-E
       \ /
        M
```

---

# 118. Strong Senior-Level Interview Answer

### Interviewer:

> "How do you decide which Git command to use?"

### Answer:

> **"I first identify whether I am changing files, changing local history, integrating branches, undoing a shared change, or selectively applying a commit. If I need to restore file content, I use restore. If I need to move a local branch pointer, I consider reset. If a bad commit has already been shared, I generally use revert because it preserves history. If I need to replay my feature commits onto the latest target branch, I use rebase. If I need only one specific commit from another branch, I use cherry-pick. For combining complete branch histories, I use merge according to the team's workflow."**

---

# 119. Ultimate Git Memory Map

```text
                    GIT
                     |
     ┌───────────────┼────────────────┐
     |               |                |
   FILES           COMMITS          BRANCHES
     |               |                |
     ↓               ↓                ↓
 restore          reset            merge
 diff             revert            rebase
 clean            cherry-pick       fetch
                  amend             pull
                  reflog
                  bisect
```

And the simplest possible memory:

```text
RESTORE
→ FILE

RESET
→ MOVE

REVERT
→ UNDO

REBASE
→ REPLAY

CHERRY-PICK
→ ONE COMMIT

MERGE
→ COMBINE

STASH
→ TEMPORARY

REFLOG
→ RECOVER

BISECT
→ FIND BUG
```

---

# 120. Final Interview Rule

Before running a Git command, ask yourself:

```text
"What exactly am I trying to change?"
```

If the answer is:

```text
File?
    → restore

Branch pointer?
    → reset

Already-shared bad commit?
    → revert

My commits need a new base?
    → rebase

One specific commit?
    → cherry-pick

Entire branch history?
    → merge

Temporary unfinished work?
    → stash

Lost local commit?
    → reflog

Unknown bad commit?
    → bisect
```

This approach is much more powerful than memorizing Git commands individually.

---

# 121. Final Interview Cheat Sheet

```text
git fetch origin
    ↓
See remote changes

git rebase origin/main
    ↓
Replay local commits

git merge feature
    ↓
Combine branch histories

git revert <commit>
    ↓
Undo shared commit safely

git cherry-pick <commit>
    ↓
Bring one specific commit

git reset --soft HEAD~1
    ↓
Move HEAD, keep changes staged

git reset HEAD~1
    ↓
Move HEAD, keep changes unstaged

git reset --hard HEAD~1
    ↓
Move HEAD and reset files

git restore file
    ↓
Restore file content

git stash
    ↓
Temporarily store unfinished work

git reflog
    ↓
Find previous local HEAD states

git bisect
    ↓
Find which commit introduced a bug
```

## Final Memory

> **Git becomes easy when you understand the commit graph first.**

Don't start with:

```text
"What command should I type?"
```

Start with:

```text
"What does my commit graph look like?"
```

Then choose the command.

That is the difference between **memorizing Git** and **actually understanding Git**.
_______________________

Practical LAB SECTION

# 122. Practical Git Lab — Real-World DevOps Hands-On

This lab is designed to practice the most important Git commands in a realistic DevOps workflow.

You will practice:

* Repository initialization
* Commits
* Branches
* Merge
* Merge conflicts
* Rebase
* Cherry-pick
* Revert
* Reset
* Stash
* Reflog
* Remote repository
* Push rejection
* `git pull --rebase`
* `git push --force-with-lease`
* Git history investigation

---

# 123. Lab Setup

Create a temporary Git repository:

```bash
mkdir git-interview-lab
cd git-interview-lab

git init
```

Configure Git if required:

```bash
git config user.name "DevOps Engineer"
git config user.email "devops@example.com"
```

Check:

```bash
git status
```

Expected:

```text
On branch main

No commits yet
```

---

# 124. Lab 1 — Create Your First Commit

Create a simple application configuration file:

```bash
cat > app.conf <<'EOF'
APP_NAME=ShopSphere
APP_ENV=dev
APP_PORT=8080
EOF
```

Check:

```bash
git status
```

You should see:

```text
Untracked files:
    app.conf
```

Stage and commit:

```bash
git add app.conf
git commit -m "Add application configuration"
```

Check:

```bash
git log --oneline
```

Example:

```text
A1B2C3D Add application configuration
```

Concept:

```text
A1B2C3D
   |
app.conf
```

Interview point:

> Git tracks snapshots of the project through commits. Each commit represents a point in the project's history.

---

# 125. Lab 2 — Create Multiple Commits

Modify the application configuration:

```bash
cat >> app.conf <<'EOF'
APP_LOG_LEVEL=INFO
EOF
```

Commit:

```bash
git add app.conf
git commit -m "Configure application logging"
```

Add another change:

```bash
cat >> app.conf <<'EOF'
DB_HOST=localhost
EOF
```

Commit:

```bash
git add app.conf
git commit -m "Add database configuration"
```

View history:

```bash
git log --oneline --graph --decorate
```

Example:

```text
C3D4E5F (HEAD -> main) Add database configuration
B2C3D4E Configure application logging
A1B2C3D Add application configuration
```

Visualize it:

```text
A1B2C3D
   |
B2C3D4E
   |
C3D4E5F
   |
  main
   |
  HEAD
```

Remember:

```text
HEAD
 ↓
main
 ↓
latest commit
```

---

# 126. Lab 3 — Create a Feature Branch

Create a feature branch:

```bash
git switch -c feature/monitoring
```

Check:

```bash
git branch
```

Example:

```text
* feature/monitoring
  main
```

Create monitoring configuration:

```bash
cat > monitoring.conf <<'EOF'
METRICS_ENABLED=true
HEALTH_CHECK=/health
EOF
```

Commit:

```bash
git add monitoring.conf
git commit -m "Add application monitoring configuration"
```

History:

```text
A1B2C3D---B2C3D4E---C3D4E5F---D4E5F6A
                                  ↑
                           feature/monitoring
```

Main still points to:

```text
A1B2C3D---B2C3D4E---C3D4E5F
                           ↑
                          main
```

Important:

> A branch is basically a movable pointer to a commit.

---

# 127. Lab 4 — Merge Feature Branch

Switch back to main:

```bash
git switch main
```

Merge:

```bash
git merge feature/monitoring
```

If Git performs a fast-forward merge:

```text
Before:

A---B---C       main
         \
          D     feature


After:

A---B---C---D
             ↑
            main
```

Check:

```bash
git log --oneline --graph --decorate
```

Interview answer:

> A fast-forward merge happens when the target branch has no new commits since the feature branch diverged, so Git can simply move the branch pointer forward.

---

# 128. Lab 5 — Practice a Merge Conflict

Create a new branch:

```bash
git switch -c feature/app-port
```

Change:

```bash
sed -i 's/APP_PORT=8080/APP_PORT=9090/' app.conf
```

Commit:

```bash
git add app.conf
git commit -m "Change application port"
```

Now switch to main:

```bash
git switch main
```

Make a conflicting change:

```bash
sed -i 's/APP_PORT=8080/APP_PORT=7070/' app.conf
```

Commit:

```bash
git add app.conf
git commit -m "Update application port for production"
```

Now merge:

```bash
git merge feature/app-port
```

Git should report a conflict.

Check:

```bash
git status
```

You may see:

```text
both modified: app.conf
```

Open the file:

```bash
cat app.conf
```

You may see:

```text
<<<<<<< HEAD
APP_PORT=7070
=======
APP_PORT=9090
>>>>>>> feature/app-port
```

Meaning:

```text
<<<<<<< HEAD
        |
        | current branch
        |
=======
        |
        | incoming branch
        |
>>>>>>> feature/app-port
```

Choose the correct configuration and remove the conflict markers.

For example:

```text
APP_NAME=ShopSphere
APP_ENV=dev
APP_PORT=9090
APP_LOG_LEVEL=INFO
DB_HOST=localhost
```

Stage:

```bash
git add app.conf
```

Complete the merge:

```bash
git commit
```

Check:

```bash
git log --oneline --graph --decorate
```

You may now see:

```text
        D4E5F6A
       /       \
C3D4E5F         G7H8I9J
       \       /
        E5F6G7H
```

The important concept:

> A merge conflict is not a Git failure. Git is asking the developer to decide which changes should remain.

---

# 129. Lab 6 — Practice Rebase

Create another feature:

```bash
git switch -c feature/security
```

Create:

```bash
cat > security.conf <<'EOF'
TLS_ENABLED=true
SECURITY_HEADERS=true
EOF
```

Commit:

```bash
git add security.conf
git commit -m "Add security configuration"
```

Now create another commit on main:

```bash
git switch main

cat >> app.conf <<'EOF'
APP_TIMEOUT=30
EOF

git add app.conf
git commit -m "Configure application timeout"
```

Now feature/security is behind main.

Visualize:

```text
             D4E5F6A  feature/security
            /
A---B---C
         \
          E5F6G7H    main
```

Actually, conceptually the feature branch is based on `C`, while main moved to `E`.

Run:

```bash
git switch feature/security
git rebase main
```

After rebase:

```text
A---B---C---E5F6G7H---F6G7H8I
                       ↑
                feature/security
```

The security commit was replayed on top of the latest main commit.

Important:

```text
MERGE
→ combine histories

REBASE
→ replay commits on a new base
```

Interview answer:

> I use rebase when I want to update my feature branch with the latest target-branch changes while keeping a linear history. I avoid rebasing shared commits because rebase rewrites commit IDs.

---

# 130. Lab 7 — Practice Cherry-Pick

Suppose the security fix exists on:

```text
feature/security
```

but production is represented by:

```text
release/1.0
```

Create the release branch:

```bash
git switch main
git switch -c release/1.0
```

Now find the security commit:

```bash
git log --oneline feature/security
```

Example:

```text
F6G7H8I Add security configuration
E5F6G7H Configure application timeout
...
```

Cherry-pick only the security commit:

```bash
git cherry-pick F6G7H8I
```

History:

```text
feature/security:

A---B---C---E---F
                ↑
           security fix


release/1.0:

A---B---C---E---F'
                ↑
          cherry-picked
```

Notice:

```text
F6G7H8I
   ↓
F6G7H8I'
```

The changes are similar, but the commit ID is different because Git created a new commit.

Interview answer:

> I use cherry-pick when I need one specific commit, such as a production hotfix or security fix, without bringing the entire feature branch.

---

# 131. Lab 8 — Practice Git Revert

Find the latest commit:

```bash
git log --oneline -5
```

Suppose:

```text
F6G7H8I Add security configuration
E5F6G7H Configure application timeout
```

If the security change needs to be undone:

```bash
git revert F6G7H8I
```

Git creates a new commit.

History:

```text
A---B---C---E---F---R
                    ↑
              revert F
```

Check:

```bash
git log --oneline --graph
```

Important:

```text
Original commit remains.
New commit reverses its changes.
```

Interview answer:

> For a shared branch such as main or production, I normally prefer revert because it preserves the existing history and creates an explicit undo commit.

---

# 132. Lab 9 — Practice Reset

Create a temporary commit:

```bash
echo "temporary=true" >> app.conf

git add app.conf
git commit -m "Temporary configuration"
```

Check:

```bash
git log --oneline -3
```

Suppose:

```text
H8I9J0K Temporary configuration
R7S8T9U Revert "Add security configuration"
...
```

Now practice soft reset:

```bash
git reset --soft HEAD~1
```

Check:

```bash
git status
```

The commit disappeared from the current branch history, but the changes remain staged.

Mental model:

```text
SOFT

HEAD moves
   ↓
Changes remain staged
```

Now unstage:

```bash
git reset
```

Changes become unstaged.

Mental model:

```text
MIXED

HEAD moves
   ↓
Changes remain in working tree
   ↓
Not staged
```

For the lab, do not use `--hard` unless you understand the consequences.

---

# 133. Lab 10 — Practice Stash

Create an unfinished change:

```bash
echo "DEBUG_MODE=true" >> app.conf
```

Check:

```bash
git status
```

Now imagine you receive an urgent production task.

Store your unfinished work:

```bash
git stash push -m "WIP debug configuration"
```

Check:

```bash
git status
```

Working tree should be clean.

View stash:

```bash
git stash list
```

Example:

```text
stash@{0}: On main: WIP debug configuration
```

Restore it:

```bash
git stash pop
```

Check:

```bash
git status
```

Mental model:

```text
WORKING TREE
     |
   stash
     |
temporary storage
     |
stash pop
     ↓
WORKING TREE
```

Interview answer:

> I use stash when I have uncommitted work but need to temporarily switch context without creating an unnecessary commit.

---

# 134. Lab 11 — Practice Reflog

Create a commit:

```bash
echo "RECOVERY_TEST=true" >> app.conf

git add app.conf
git commit -m "Add recovery test configuration"
```

Find history:

```bash
git log --oneline -3
```

Now intentionally move the branch backward:

```bash
git reset --hard HEAD~1
```

The commit appears to be gone from normal history.

Check:

```bash
git log --oneline
```

Now use:

```bash
git reflog
```

Example:

```text
abc1234 HEAD@{0}: reset: moving to HEAD~1
xyz7890 HEAD@{1}: commit: Add recovery test configuration
```

Recover the previous commit:

```bash
git reset --hard xyz7890
```

Verify:

```bash
git log --oneline -3
```

The commit is back.

Mental model:

```text
git log
→ normal visible history

git reflog
→ local record of where HEAD/refs moved
```

Interview answer:

> When a local commit appears to be lost after reset or another history operation, I check reflog first. It often allows me to recover the previous HEAD position.

---

# 135. Lab 12 — Simulate Remote Repository

Create a bare repository:

```bash
cd ..
git init --bare git-remote.git
```

Go back:

```bash
cd git-interview-lab
```

Add remote:

```bash
git remote add origin ../git-remote.git
```

Check:

```bash
git remote -v
```

Push:

```bash
git push -u origin main
```

The `-u` establishes the upstream relationship.

After this, you can normally use:

```bash
git push
git pull
```

instead of specifying:

```bash
git push origin main
git pull origin main
```

---

# 136. Lab 13 — Simulate a Push Rejection

This is one of the most important DevOps Git labs.

Clone the remote into another directory:

```bash
cd ..
git clone git-remote.git developer2
```

Now there are two working copies:

```text
Developer 1
git-interview-lab

Developer 2
developer2
```

### Developer 1

Go into your original repository:

```bash
cd git-interview-lab
```

Create a commit:

```bash
echo "DEV1=true" >> app.conf

git add app.conf
git commit -m "Developer 1 configuration"
```

Push:

```bash
git push
```

### Developer 2

Open another terminal:

```bash
cd developer2
```

Create a different commit:

```bash
echo "DEV2=true" >> app.conf

git add app.conf
git commit -m "Developer 2 configuration"
```

Push:

```bash
git push
```

Now Developer 1 is behind the remote.

Create another local commit:

```bash
cd ../git-interview-lab

echo "DEV1_SECOND=true" >> app.conf

git add app.conf
git commit -m "Developer 1 second configuration"
```

Try:

```bash
git push
```

You should get a rejection similar to:

```text
! [rejected] main -> main (fetch first)
error: failed to push some refs
```

Why?

```text
Remote:

A---B---C
        ↑
       origin/main


Local:

A---B---C---D
            ↑
           main

```

Actually, because Developer 2 pushed a commit, the actual divergence is:

```text
             D     local
            /
A---B---C
            \
             E     remote
```

Git refuses to overwrite the remote history.

---

# 137. Lab 14 — Fix Push Rejection Using Rebase

First fetch:

```bash
git fetch origin
```

Now:

```text
Remote-tracking branch updated.

origin/main
     ↓

A---B---C---E
```

Your local branch:

```text
A---B---C---D
            ↑
           main
```

Rebase:

```bash
git rebase origin/main
```

Git replays `D` on top of `E`.

Result:

```text
A---B---C---E---D'
                 ↑
                main
```

Notice:

```text
D
↓
D'
```

The commit ID changes because the parent changed.

Now push:

```bash
git push
```

This should succeed.

This is the exact mental model to remember:

```text
git fetch
    ↓
Update remote-tracking information

git rebase origin/main
    ↓
Replay local commits on latest remote history

git push
    ↓
Update remote
```

Interview answer:

> If my push is rejected because the remote branch has new commits, I first fetch the latest remote state. If my local changes can be replayed cleanly, I commonly rebase my local commits onto the updated remote branch and then push. This keeps the history linear and avoids unnecessarily creating a merge commit.

---

# 138. Lab 15 — Practice Rebase Conflict

Create a feature branch:

```bash
git switch -c feature/config
```

Change:

```bash
sed -i 's/APP_ENV=dev/APP_ENV=test/' app.conf

git add app.conf
git commit -m "Set application environment to test"
```

Switch to main:

```bash
git switch main
```

Make a conflicting change:

```bash
sed -i 's/APP_ENV=dev/APP_ENV=prod/' app.conf

git add app.conf
git commit -m "Set application environment to production"
```

Now:

```bash
git switch feature/config
git rebase main
```

Git may stop with a conflict.

Check:

```bash
git status
```

Resolve the file:

```bash
vim app.conf
```

Remove:

```text
<<<<<<<
=======
>>>>>>>
```

Keep the desired content.

Stage:

```bash
git add app.conf
```

Continue:

```bash
git rebase --continue
```

If more conflicts occur, repeat:

```text
resolve
   ↓
git add
   ↓
git rebase --continue
```

If you want to cancel the entire rebase:

```bash
git rebase --abort
```

Mental model:

```text
REBASE CONFLICT

Pause
  ↓
Resolve
  ↓
git add
  ↓
git rebase --continue
```

---

# 139. Lab 16 — Practice Force-With-Lease

This is an advanced lab.

Suppose you rewrite a feature branch using:

```bash
git rebase -i HEAD~3
```

Your local history changes:

```text
Before:

A---B---C---D
             ↑
            feature
```

After rebase:

```text
A---B---C'---D'
             ↑
            feature
```

The remote still contains:

```text
A---B---C---D
             ↑
        origin/feature
```

A normal push may be rejected because the history was rewritten.

For a personal/shared feature branch where rewriting is allowed:

```bash
git push --force-with-lease origin feature/config
```

Why `--force-with-lease`?

Because it provides an additional safety check.

Imagine:

```text
Remote:

A---B---C---D---E
                 ↑
             someone else's
                commit
```

But your local remote-tracking information only knows:

```text
A---B---C---D
             ↑
        origin/feature
```

Your rewritten local branch is:

```text
A---B---C'---D'
```

`--force-with-lease` can refuse the push because the remote has changed unexpectedly.

Mental model:

```text
--force
→ overwrite remote

--force-with-lease
→ overwrite only if remote is still what I expect
```

Interview answer:

> When a feature branch has intentionally been rebased and requires a non-fast-forward push, I prefer `--force-with-lease` over `--force`. It adds a safety check so I don't accidentally overwrite remote work that appeared after my last known remote state. I avoid rewriting shared protected branches unless the team's workflow explicitly permits it.

---

# 140. Lab 17 — Practice Git Diff

Modify:

```bash
echo "CACHE_ENABLED=true" >> app.conf
```

Check unstaged changes:

```bash
git diff
```

Stage:

```bash
git add app.conf
```

Now:

```bash
git diff
```

may show nothing because the change is staged.

Use:

```bash
git diff --cached
```

to see staged changes.

Mental model:

```text
Working Tree
     |
 git diff
     ↓
unstaged changes


Staging Area
     |
git diff --cached
     ↓
staged changes
```

---

# 141. Lab 18 — Practice Git Log Investigation

Run:

```bash
git log --oneline --graph --decorate --all
```

This is one of the most useful commands during troubleshooting.

Useful variations:

```bash
git log --oneline
```

```bash
git log --graph --oneline --all
```

```bash
git log --stat
```

```bash
git log -p
```

```bash
git log --author="DevOps Engineer"
```

For a specific file:

```bash
git log -- app.conf
```

---

# 142. Lab 19 — Practice Git Blame

Run:

```bash
git blame app.conf
```

Example:

```text
A1B2C3D (DevOps Engineer 2026-09-21) APP_NAME=ShopSphere
B2C3D4E (DevOps Engineer 2026-09-21) APP_ENV=dev
F6G7H8I (DevOps Engineer 2026-09-21) APP_TIMEOUT=30
```

This helps answer:

```text
Who changed this line?
Which commit changed it?
When was it changed?
```

Important:

> `git blame` is an investigation tool, not a way to assign fault.

In production troubleshooting, combine it with:

```bash
git show <commit-id>
```

to inspect the actual change.

---

# 143. Lab 20 — Practice Git Clean

Create temporary files:

```bash
touch debug.log
touch test.tmp
mkdir temp
touch temp/output.txt
```

Check:

```bash
git status
```

Preview what Git would remove:

```bash
git clean -n
```

This is a dry run.

If you are certain:

```bash
git clean -f
```

For directories:

```bash
git clean -fd
```

Important:

> Always use `git clean -n` first. `git clean` can permanently remove untracked files.

---

# 144. Complete DevOps Git Troubleshooting Flow

When a deployment-related Git issue occurs, follow this sequence.

## Step 1 — Check status

```bash
git status
```

## Step 2 — Understand current branch

```bash
git branch --show-current
```

## Step 3 — Inspect history

```bash
git log --oneline --graph --decorate --all -20
```

## Step 4 — Update remote information

```bash
git fetch origin
```

## Step 5 — Compare local and remote

```bash
git log --oneline HEAD..origin/main
```

Remote-only commits:

```bash
git log --oneline origin/main..HEAD
```

Local-only commits.

## Step 6 — Decide the operation

```text
Need to undo shared commit?
        ↓
      revert

Need to move local branch back?
        ↓
      reset

Need to recover lost local work?
        ↓
     reflog

Need one commit from another branch?
        ↓
   cherry-pick

Need latest target branch in feature?
        ↓
      rebase

Need to combine branches?
        ↓
      merge

Need temporary work storage?
        ↓
      stash
```

---

# 145. Enterprise DevOps Git Workflow

A realistic team workflow may look like:

```text
Developer
   |
   | git clone
   ↓
Local repository
   |
   | feature branch
   ↓
feature/payment-api
   |
   | commits
   ↓
Pull Request
   |
   | code review
   | CI
   | security scan
   | tests
   ↓
main
   |
   | CI/CD
   ↓
Build
   |
   ↓
Docker Image
   |
   ↓
ECR
   |
   ↓
Deployment
   |
   ↓
EKS / ECS / EC2
```

Typical commands:

```bash
git clone <repository>
cd repository

git switch -c feature/payment-api

git add .
git commit -m "Add payment API configuration"

git fetch origin
git rebase origin/main

git push -u origin feature/payment-api
```

Then create a Pull Request.

After review and CI validation, the feature is merged according to the team's branch protection policy.

---

# 146. Git Interview Practical Cheat Sheet

| Situation                       | Command                       |
| ------------------------------- | ----------------------------- |
| Check working tree              | `git status`                  |
| View history                    | `git log --oneline --graph`   |
| Create branch                   | `git switch -c feature/x`     |
| Switch branch                   | `git switch main`             |
| Merge branch                    | `git merge feature/x`         |
| Update remote info              | `git fetch origin`            |
| Update feature using rebase     | `git rebase origin/main`      |
| Undo shared commit              | `git revert <commit>`         |
| Move local branch backward      | `git reset --mixed HEAD~1`    |
| Keep changes staged after reset | `git reset --soft HEAD~1`     |
| Remove changes completely       | `git reset --hard HEAD~1`     |
| Recover lost local commit       | `git reflog`                  |
| Apply one commit                | `git cherry-pick <commit>`    |
| Temporarily save work           | `git stash`                   |
| Restore stash                   | `git stash pop`               |
| See unstaged changes            | `git diff`                    |
| See staged changes              | `git diff --cached`           |
| See who changed a line          | `git blame <file>`            |
| Remove untracked files          | `git clean -f`                |
| Preview clean                   | `git clean -n`                |
| Push branch                     | `git push`                    |
| Safer rewritten-history push    | `git push --force-with-lease` |

---

# 147. The Most Important Git Mental Model

Memorize this:

```text
                GIT COMMAND MENTAL MODEL

git restore
     ↓
   FILE

git reset
     ↓
   MOVE

git revert
     ↓
    UNDO

git rebase
     ↓
   REPLAY

git merge
     ↓
  COMBINE

git cherry-pick
     ↓
 ONE COMMIT

git stash
     ↓
 TEMPORARY

git reflog
     ↓
 RECOVER

git fetch
     ↓
 UPDATE REMOTE INFO

git pull
     ↓
 FETCH + INTEGRATE

git push
     ↓
 SEND COMMITS

git diff
     ↓
 SEE CHANGES

git log
     ↓
 SEE HISTORY

git blame
     ↓
 TRACE LINE

git bisect
     ↓
 FIND BAD COMMIT
```

---

# 148. Senior DevOps Interview Scenario

### Interviewer:

> Your local main branch has a commit, but someone else pushed a commit to GitHub. When you run `git push`, it is rejected. What will you do?

### Strong answer:

> First, I won't force-push immediately. I'll check the working tree with `git status` and inspect the history with `git log --oneline --graph --decorate --all`. Then I'll run `git fetch origin` to update my remote-tracking branch without modifying my working branch.
>
> If my local changes are compatible with the latest remote history, I'll rebase my local commits onto `origin/main` using `git rebase origin/main`. If there are conflicts, I'll resolve them, stage the files, and continue the rebase.
>
> Once the history is linear and my local branch is ahead of `origin/main`, I'll run `git push`.
>
> I would only consider `--force-with-lease` if I intentionally rewrote history on a branch where that operation is allowed. I would not casually force-push a shared protected main branch.

The mental picture is:

```text
Before:

             LOCAL
               D
              /
A---B---C
              \
               E
             REMOTE


git fetch
    ↓

Know about E


git rebase origin/main
    ↓

A---B---C---E---D'
                 ↑
                main


git push
    ↓

Remote updated
```

---

# 149. Final Hands-On Challenge

Try completing this workflow without looking at the commands above.

### Scenario

You are working on:

```text
main
```

Create:

```text
feature/payment
```

Make three commits:

```text
P1 Add payment configuration
P2 Add payment logging
P3 Add payment health check
```

Meanwhile, main receives:

```text
M1 Update production configuration
```

Your task:

```text
1. Rebase feature/payment onto main
2. Resolve any conflict
3. Cherry-pick P3 onto another release branch
4. Accidentally reset the feature branch
5. Recover it using reflog
6. Revert P2
7. Stash an unfinished change
8. Restore the stash
9. Push the feature branch
10. Inspect the final history using git log
```

Your expected final history should conceptually resemble:

```text
main:

A---B---M1
         ↑
        main


feature/payment:

A---B---M1---P1'---P2'---P3'---R
                              ↑
                         feature/payment


release/1.0:

A---B---M1---P3''
                   ↑
                release/1.0
```

The exact commit IDs will be different on your machine.

That is intentional.

The goal of the lab is not memorizing commit IDs.

The goal is understanding:

```text
WHERE THE BRANCH IS
        ↓
WHAT COMMIT IT POINTS TO
        ↓
WHAT CHANGES ARE LOCAL
        ↓
WHAT CHANGES ARE REMOTE
        ↓
WHICH HISTORY OPERATION IS SAFE
```

---

# 150. Final Interview Rule

When troubleshooting Git in production, **don't start by running random commands**.

Start with:

```bash
git status
git branch --show-current
git log --oneline --graph --decorate --all
git fetch origin
```

Understand the history first.

Then choose:

```text
UNDO       → git revert
MOVE BACK  → git reset
REPLAY     → git rebase
COMBINE    → git merge
ONE COMMIT → git cherry-pick
TEMP WORK  → git stash
RECOVER    → git reflog
REMOTE INFO→ git fetch
SEND       → git push
```

That approach is much safer than treating Git as a collection of commands to memorize.
