# Enhanced JTBD Title Verification Example

## RHIDP-14693: Verification Enhancement

The enhanced verification now ensures that titles are exactly the same as those mentioned in the TSV file, with comprehensive hierarchy validation.

## Example Usage

### Check a specific category:
```bash
node .claude/skills/jtbd-map/verify-titles.js "Discover"
```

### Show TSV hierarchy for debugging:
```bash
node .claude/skills/jtbd-map/verify-titles.js "Discover" --hierarchy
```

### Sample Output - Hierarchy Display:

```
=== TSV Hierarchy for Discover ===

Line 4:
  Entry type: Job L3
  Category: "Discover"
  L3: "Why Internal developer platforms?"
  Is Job: true
  Expected file title: "Why Internal developer platforms?"
  Expected file prefix: "why-internal-developer-platforms"

Line 5:
  Entry type: Topic H2
  Category: "Discover"
  H2: "Core platform features for your development toolchain"
  Is Job: false
  Expected file title: "Core platform features for your development toolchain"
  Expected file prefix: "core-platform-features-for-your-development-toolchain"
```

### Sample Output - Verification Issues:

```
=== Checking category: Discover ===

Title mismatches (1):

  File: titles/product_product/category-maps/discover/nav-example.adoc
  TSV line: 7
  Entry type: Job L3
  TSV hierarchy:
    L3: "System architecture for deployment strategy planning"
    Is job: true
  Expected title: "System architecture for deployment strategy planning"
  Actual title:   "System Architecture for Deployment Strategy Planning"

Navtitle mismatches (1):

  File: titles/product_product/category-maps/discover/nav-example.adoc
  Module: modules/shared/proc-example.adoc
  TSV line: 8
  Entry type: Topic H2
  Expected navtitle: "Frontend client layer for user access and routing"
  Actual navtitle:   "Frontend Client Layer for User Access and Routing"
```

## Key Improvements

1. **Enhanced TSV parsing**: Handles variable column positions for "Is a job?" field
2. **Entry type classification**: Clearly identifies Job L2/L3/L4, Topic L2/L3/L4, Topic H2/H3
3. **Detailed hierarchy context**: Shows complete TSV hierarchy when reporting mismatches
4. **Exact title matching**: Requires precise capitalization, punctuation, and spacing
5. **Missing topic validation**: Verifies parent-child relationships from TSV structure
6. **Debugging support**: `--hierarchy` flag shows complete TSV structure for troubleshooting

## Verification Requirements

- **Level 2 job names**: Must match TSV "Level 2 (Jobs)" column exactly
- **H1/H2/H3 categories**: Must match TSV "Topic (H2)" and "H3" columns exactly  
- **Job hierarchy**: Level 3 and Level 4 job titles must match corresponding TSV columns
- **Navtitle attributes**: Must use exact TSV titles when module titles don't match
- **File structure**: Nav and con files must exist for all jobs and parent topics
- **Include completeness**: Parent nav files must include all expected child topics