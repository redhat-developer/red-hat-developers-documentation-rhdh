# CQA #11 - Procedures

## Procedure prerequisites requirements

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md) - Prerequisites

**Quality Level:** Required/non-negotiable

If a procedure includes prerequisites:
- Use the `.Prerequisites` label (with leading period)
- Use consistent formatting (bulleted list)
- Do not exceed 10 prerequisites
- Do not include steps in prerequisites (prerequisites are completed states, not actions)

## Commands

### Find All Procedure Prerequisites

```bash
# Find all .Prerequisites sections
grep -rn "^\.Prerequisites" modules/

# Count prerequisites in each procedure
grep -A 20 "^\.Prerequisites" modules/proc-*.adoc | grep -c "^-"

# Find procedures with > 10 prerequisites
for file in modules/proc-*.adoc; do
  count=$(grep -A 30 "^\.Prerequisites" "$file" | grep -c "^-")
  [ $count -gt 10 ] && echo "$file: $count prerequisites (exceeds limit of 10)"
done
```

### Check Prerequisites Format

```bash
# Find prerequisites without leading period
grep -rn "^Prerequisites" modules/ | grep -v "^\.Prerequisites"

# Find prerequisites with inconsistent formatting
grep -rn "^\.Prerequisites" -A 20 modules/ | grep -v "^-" | grep -v "^$"
```

## Prerequisites Format Requirements

### Correct Format

```asciidoc
.Prerequisites

- You have cluster administrator privileges.
- You have installed the OpenShift CLI (`oc`).
- You have configured authentication for your cluster.
```

**Requirements:**
- Section label: `.Prerequisites` (with leading period)
- List format: Bulleted list using `-` or `*`
- Present perfect tense: "You have...", "The system is...", "Your environment includes..."
- Completed states, not instructions: Prerequisites describe what must already be true

### Common Violations and Fixes

| Violation | Incorrect | Correct |
|-----------|-----------|---------|
| **Missing leading period** | `Prerequisites` | `.Prerequisites` |
| **Too many items** | 15 prerequisites listed | Split into ≤10 items, combine related items |
| **Steps in prerequisites** | "Install the Operator" | "You have installed the Operator" |
| **Imperative form** | "Be a cluster administrator" | "You have cluster administrator privileges" |
| **Future tense** | "You will need admin access" | "You have administrator access" |
| **Inconsistent format** | Mix of bullets and numbered steps | Use bullets only |

## Prerequisites vs Procedure Steps

**Prerequisites** = Completed states (things that must already be true before starting)
**Procedure steps** = Actions to perform (numbered instructions in imperative form)

| Type | Form | Example |
|------|------|---------|
| ✅ **Prerequisite** | Present perfect / completed state | "You have installed the Operator" |
| ❌ **NOT a prerequisite** | Imperative instruction | "Install the Operator" |
| ✅ **Procedure step** | Imperative instruction | "Install the Operator by running..." |

**Rule:** If it's an action to perform, it belongs in the procedure steps, not prerequisites.

## Limit: Maximum 10 Prerequisites

**Why the 10-item limit:**
- Prevents overwhelming users before they even start
- Indicates procedure may be too complex (consider splitting)
- Forces prioritization of essential prerequisites

**If you have > 10 prerequisites:**
1. **Combine related items:**
   - ❌ "You have installed Operator A", "You have installed Operator B", "You have installed Operator C"
   - ✅ "You have installed the required Operators (A, B, C)"

2. **Remove non-essential items:**
   - Move "nice to have" items to a note or "Additional resources"

3. **Split the procedure:**
   - If many prerequisites, procedure may be doing too much
   - Consider splitting into multiple focused procedures

## Validation Checklist

- [ ] All `.Prerequisites` sections use leading period
- [ ] All prerequisites use bulleted list format (not numbered)
- [ ] Each procedure has ≤10 prerequisites
- [ ] Prerequisites use present perfect tense ("You have...", "The system is...")
- [ ] No action items in prerequisites (only completed states)
- [ ] No imperative instructions in prerequisites
- [ ] Prerequisites are consistent across modules
- [ ] Prerequisites describe what must be true, not what to do

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
