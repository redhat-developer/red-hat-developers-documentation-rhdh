# Red Hat Modular Documentation Reference Guide

## Core Concepts

**Modular documentation** structures content into self-contained, reusable units called modules, which writers combine into assemblies. "A module must make sense and provide value on its own, even when read separately from other modules."

### Module Types

#### CONCEPT modules
Purpose: Explain ideas and concepts users need to understand a product.

Structure requirements:
- Single introductory paragraph answering "What is this?" and "Why care?"
- Body content using paragraphs, lists, tables, graphics
- Optional additional resources section
- Avoid action items (belong in procedures)

Title format: Noun phrase (e.g., "Guided decision tables")

#### PROCEDURE modules
Purpose: Provide numbered, step-by-step instructions for accomplishing single tasks.

Required sections:
- Title (gerund phrase: "Creating guided decision tables")
- Introduction explaining context and benefits
- Steps in imperative form

Optional sections:
- Prerequisites (bulleted list, plural heading)
- Verification/Results
- Troubleshooting
- Next steps
- Additional resources

#### REFERENCE modules
Purpose: Present lookup data users need but don't memorize (commands, configurations, defaults).

Structure requirements:
- Concise introduction
- Strictly organized reference data (lists or tables)
- Alphabetical or logical ordering for scannability

Title format: Noun phrase

#### SNIPPET
Not a module type. Reusable text sections (paragraphs, lists, tables, notes) included via `include::` directives. Naming convention: prefix with `snip-` or `snip_`.

### ASSEMBLY structure
Collections combining multiple modules to address user stories.

Required elements:
- Introduction explaining what users accomplish
- Multiple modules (concept, procedure, reference combinations)

Optional elements:
- Prerequisites (applicable to all modules)
- Additional resources

Title format: Gerund phrase if task-focused ("Encrypting block devices using LUKS"); noun phrase otherwise.

## File Naming & Anchors

**File naming convention:**
```
prefix-filename.adoc or prefix_filename.adoc
```

Prefixes:
- `con`: Concept
- `proc`: Procedure
- `ref`: Reference
- `assembly`: Assembly

Example: `proc-creating-guided-decision-tables.adoc`

**Anchor format:**
```
[id="filename_{context}"]
= Module heading
```

The `{context}` variable enables module reuse across assemblies without ID conflicts.

## Metadata Requirements

Content type attribute for each file:
```
:_mod-docs-content-type: ASSEMBLY
:_mod-docs-content-type: PROCEDURE
:_mod-docs-content-type: CONCEPT
:_mod-docs-content-type: REFERENCE
:_mod-docs-content-type: SNIPPET
```

Context variable in assemblies:
```
:context: assembly-name
```

## Module Reuse Guidelines

When reusing modules across assemblies:

1. Embed `{context}` variable in anchor IDs
2. Define `:context: value` immediately above each include statement
3. For multiple reuses in one assembly: use section-specific context
4. For single reuse across assemblies: use assembly-specific context

Cross-reference format: `xref:anchor-name_context-variable-name[]`

## Nesting Assemblies

When including assemblies within assemblies, preserve context:

**At assembly start:**
```
ifdef::context[:parent-context: {context}]
```

**At assembly end:**
```
ifdef::parent-context[:context: {parent-context}]
ifndef::parent-context[:!context:]
```

This prevents duplicate ID errors in nested structures.

## Best Practices

- Modules should NOT contain other modules
- Create meaningful, standalone modules (not arbitrary fragments)
- Use consistent heading levels: H1 for all module/assembly titles
- Keep introductions concise (single paragraph)
- Focus additional resources on relevance, not completeness
- Use subheadings (H2+) in concept/reference modules for complex content
- Never create subheadings in procedure modules

## Distinction: User Stories vs. Use Cases

**User stories** describe what users accomplish ("As a system administrator, I want to...so that...").

**Use cases** describe system interactions and requirements from product perspective.

Modular documentation is based on user stories, organized by customer product lifecycle phases: Plan, Install, Configure/Verify, Develop/Test, Manage, Monitor/Tune, Upgrade/Migrate, Troubleshoot.
