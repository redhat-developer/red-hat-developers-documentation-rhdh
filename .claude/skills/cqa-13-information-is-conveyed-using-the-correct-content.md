# CQA #13 - Editorial

## Information is conveyed using the correct content type

**Reference:** [Product Documentation Content Types (CQA extract)](../resources/content-types-for-cqa.md)

**Quality Level:** Required/non-negotiable

## Overview

For Red Hat Developer Hub documentation, ensure information is conveyed using the correct **content type** and **module type** (for modular documentation).

### Content Types vs Module Types

**Content type** = The overall category of content (Product documentation, Developer documentation, Tutorial, etc.)

**Module type** = The structure within modular Product documentation (CONCEPT, PROCEDURE, REFERENCE)

## Red Hat Developer Hub Documentation Standards

RHDH documentation uses **Product documentation** content type with **modular documentation structure**:

### Module Types (for Product Documentation)

| Module Type | Purpose | Content Characteristics | File Prefix |
|-------------|---------|------------------------|-------------|
| **CONCEPT** | Explain ideas and concepts | What it is, why it matters. No action items. | `con-*.adoc` |
| **PROCEDURE** | Provide step-by-step instructions | How to accomplish a task. Numbered steps in imperative form. | `proc-*.adoc` |
| **REFERENCE** | Present lookup data | Tables, lists, configurations, commands. Data users look up but don't memorize. | `ref-*.adoc` |
| **ASSEMBLY** | Combine modules for user story | Introduction + includes for modules. Single user story focus. | `assembly-*.adoc` |
| **SNIPPET** | Reusable content fragments | Paragraphs, lists, notes. No structural elements (anchors, H1 headings). | `snip-*.adoc` |

### Validation: Content Matches Declared Type

**Check metadata vs actual content:**

```bash
# Find all content type declarations
grep -r ":_mod-docs-content-type:" titles/ assemblies/ modules/ artifacts/

# Verify each file contains appropriate content for its declared type
```

**Common violations:**

| Violation | Incorrect | Correct |
|-----------|-----------|---------|
| **Procedure with no steps** | File declared as PROCEDURE but only contains concept explanation | Change to CONCEPT or add numbered steps |
| **Concept with steps** | File declared as CONCEPT but includes step-by-step instructions | Change to PROCEDURE or remove numbered steps |
| **Reference with explanations** | File declared as REFERENCE but includes lengthy explanations | Move explanations to CONCEPT, keep only lookup data in REFERENCE |
| **Assembly with detailed content** | Assembly contains detailed instructions instead of includes | Move detailed content to modules, keep only introduction + includes in assembly |

### Other Content Types (When Applicable)

While RHDH documentation primarily uses Product documentation with modular structure, related content may use:

- **Developer documentation**: API references, Javadocs, code samples (typically auto-generated)
- **Quick start**: In-UI guided tutorials with validation steps
- **Release notes**: Version-specific changes and known issues
- **FAQ**: Frequently asked questions (evolve-loop content)
- **In-app content**: UI microcopy, tooltips, help text

**See [content-types-for-cqa.md](../resources/content-types-for-cqa.md) for complete definitions and guidance on choosing content types.**

## Command

**Run content type verification:**
```bash
./build/scripts/cqa-13-information-is-conveyed-using-the-correct-content.sh [--fix] titles/<your-title>/master.adoc
```

**What the script does:**
- Validates PROCEDURE files have `.Procedure` section with steps
- Validates CONCEPT files do not have `.Procedure` sections
- Validates REFERENCE files do not have `.Procedure` sections
- Validates ASSEMBLY files contain only intro + includes
- Checks filename prefix matches content type (proc-, con-, ref-, assembly-)

**Target Results:**
- ✅ All content matches declared type
- ✅ All filename prefixes match content type

## Validation

**Note:** Content type metadata is automatically validated by CQA #3. This requirement focuses on manual verification that content matches declared types.

**Manual checks:**
- Review each module to ensure content aligns with its declared type
- Verify PROCEDURE modules contain actual numbered steps (not just explanations)
- Verify CONCEPT modules don't include step-by-step instructions
- Verify REFERENCE modules contain lookup data (not lengthy explanations)

## Assessment Checklist

- [ ] All modules have correct `:_mod-docs-content-type:` metadata
- [ ] PROCEDURE modules contain numbered steps (not just explanations)
- [ ] CONCEPT modules explain ideas (no step-by-step instructions)
- [ ] REFERENCE modules contain lookup data (tables, lists, specs)
- [ ] ASSEMBLY files contain only introduction + includes (no detailed content)
- [ ] SNIPPET files contain only reusable fragments (no structural elements)
- [ ] Content matches declared type (no mismatches between metadata and actual content)
- [ ] File naming matches content type (proc-, con-, ref-, assembly-, snip- prefixes)

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
