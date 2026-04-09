---
name: update-resources
description: Update CQA reference materials (SSG, peer review guide, modular docs, Vale styles). Use before starting a CQA audit or when resources may be stale.
---

# Update All CQA Resources

**Purpose:** Update all CQA reference materials and style guides to ensure current documentation standards.

**Update frequency:** Weekly minimum (7 days), daily maximum (1 day) for each resource

**Resources:**
- Red Hat Supplementary Style Guide (SSG)
- Red Hat Peer Review Guide
- Red Hat Modular Documentation Reference Guide
- Vale linting styles

## Commands

**Update all resources (recommended):**
```bash
./build/scripts/update-cqa-resources.sh
```

The script automatically:
- Checks age of each resource
- Updates resources >= 7 days old
- Skips resources < 1 day old
- Creates missing resources immediately

**Check resource ages manually:**
```bash
for file in .claude/resources/red-hat-{ssg,peer-review,modular-docs}.md; do
  [ -f "$file" ] && echo "$file: $(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 )) days old" || echo "$file: MISSING"
done
[ -f .claude/.vale-sync-timestamp ] && echo "Vale: synced $(( ($(date +%s) - $(cat .claude/.vale-sync-timestamp)) / 86400 )) days ago" || echo "Vale: NEVER SYNCED"
```

## Update Frequency Rules

| Resource | Location | Update Logic |
|----------|----------|--------------|
| **SSG** | `.claude/resources/red-hat-ssg.md` | Skip if < 1 day, update if >= 7 days |
| **Peer Review** | `.claude/resources/red-hat-peer-review.md` | Skip if < 1 day, update if >= 7 days |
| **Modular Docs** | `.claude/resources/red-hat-modular-docs.md` | Skip if < 1 day, update if >= 7 days |
| **Vale** | `.claude/.vale-sync-timestamp` | Skip if < 1 day, sync if >= 7 days |

**Update logic:**
- **< 1 day:** Skip (daily max)
- **1-6 days:** Optional
- **>= 7 days:** Update (weekly min)
- **Missing:** Fetch immediately

## When to Update

**Automatic:**
- Phase 0 of CQA master workflow (before starting CQA assessment)
- Resource files don't exist
- Resource files > 7 days old

**Manual:**
- User requests update
- Working on CQA requirements referencing guides
- Before major CQA work

## Usage in CQA Master Workflow

Phase 0 uses this skill to ensure all resources are current before starting CQA 2.1 compliance assessment. See [cqa-main-workflow.md](cqa-main-workflow.md) Phase 0.
