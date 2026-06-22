#!/usr/bin/env node

/**
 * Verify that nav and con file titles match the TSV exactly
 * Usage: node verify-titles.js [category-name]
 */

const fs = require('fs');
const path = require('path');

const TSV_PATH = path.join(__dirname, 'jtbd-toc-mapping.tsv');
const CATEGORY_MAPS_DIR = path.join(__dirname, '../../../titles/product_product/category-maps');

function parseTSV() {
  const content = fs.readFileSync(TSV_PATH, 'utf-8');
  const lines = content.split('\n');
  const entries = [];
  let currentCategory = '';

  for (let i = 1; i < lines.length; i++) { // Skip header
    const line = lines[i];
    if (!line.trim()) continue;

    const cols = line.split('\t');

    // Track current category (category field is only set on category header rows)
    if (cols[0]?.trim()) {
      currentCategory = cols[0].trim();
    }

    // Find the "Is a job?" value - it might be in different columns depending on the level
    let isJobValue = false;
    let navtitleValue = '';

    // Look for TRUE/FALSE values in the expected positions
    for (let colIndex = 7; colIndex <= 10; colIndex++) {
      const colValue = cols[colIndex]?.trim().toUpperCase();
      if (colValue === 'TRUE' || colValue === 'FALSE') {
        isJobValue = (colValue === 'TRUE');
        // Navtitle is typically the next column after the job indicator
        navtitleValue = cols[colIndex + 1]?.trim() || '';
        break;
      }
    }

    const entry = {
      lineNumber: i + 1,
      category: currentCategory,  // Use tracked category, not just the column value
      level2: cols[1]?.trim() || '',  // Column 2: "Level 2 (Jobs)"
      level3: cols[2]?.trim() || '',  // Column 3: "Level 3 (Jobs or Topics)"
      level4: cols[3]?.trim() || '',  // Column 4: "Level 4 (Jobs or Topics)"
      topicH2: cols[4]?.trim() || '', // Column 5: "Topic (H2)"
      topicH3: cols[5]?.trim() || '', // Column 6: "H3"
      filePath: cols[6]?.trim() || '', // Column 7: "Full .adoc file path"
      isJob: isJobValue,              // Detected from scanning columns 8-11
      navtitle: navtitleValue,        // Column after the job indicator
      jira: cols[9]?.trim() || '',    // Column 10: "Jira" (may shift)
      assignee: cols[10]?.trim() || '', // Column 11: "Assignee" (may shift)
    };

    // Skip empty or category-only rows that don't represent actual content
    if (!entry.level2 && !entry.level3 && !entry.level4 && !entry.topicH2 && !entry.topicH3) {
      continue;
    }

    entries.push(entry);
  }

  return entries;
}

function kebabCase(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function getEntryType(entry) {
  // Determine what type of entry this is in the hierarchy
  if (entry.topicH3) return 'Topic H3';
  if (entry.topicH2) return 'Topic H2';
  if (entry.level4) return entry.isJob ? 'Job L4' : 'Topic L4';
  if (entry.level3) return entry.isJob ? 'Job L3' : 'Topic L3';
  if (entry.level2) return entry.isJob ? 'Job L2' : 'Topic L2';
  return 'Unknown';
}

function shouldHaveNavFile(entry) {
  // Determine if this entry should have a nav+con file pair
  // Jobs always get nav files, regardless of level
  if (entry.isJob) return true;

  // Level 2 entries typically get nav files (parent jobs)
  if (entry.level2 && !entry.level3 && !entry.level4) return true;

  // Level 3 entries get nav files if they have children (level 4 or H2/H3 topics)
  if (entry.level3 && !entry.level4) return true;

  // Level 4 entries might get nav files if they have H2/H3 topics as children
  if (entry.level4) return true;

  return false;
}

function getExpectedTitle(entry) {
  // Determine which level this entry represents
  // Priority order: Level 4 > Level 3 > Level 2 > H3 > H2
  // This determines the title for the nav/con file at this specific level

  // For jobs (is a job = TRUE), use the job level title
  if (entry.isJob) {
    if (entry.level4) return entry.level4;
    if (entry.level3) return entry.level3;
    if (entry.level2) return entry.level2;
  }

  // For non-jobs (leaf topics), use H3 first, then H2, then fall back to job levels
  if (entry.topicH3) return entry.topicH3;
  if (entry.topicH2) return entry.topicH2;

  // Fall back to job levels for topics that don't have H2/H3
  if (entry.level4) return entry.level4;
  if (entry.level3) return entry.level3;
  if (entry.level2) return entry.level2;

  return null;
}

function getFilePrefix(entry) {
  const title = getExpectedTitle(entry);
  if (!title) return null;
  return kebabCase(title);
}

function extractTitleFromFile(filePath) {
  if (!fs.existsSync(filePath)) return null;

  const content = fs.readFileSync(filePath, 'utf-8');
  const match = content.match(/^= (.+)$/m);
  return match ? match[1].trim() : null;
}

function extractNavtitlesFromFile(filePath) {
  if (!fs.existsSync(filePath)) return [];

  const content = fs.readFileSync(filePath, 'utf-8');
  const navtitles = [];

  // Match include directives with navtitle attributes
  // Matches: include::...adoc[leveloffset=+1,navtitle="Title"]
  // or: include::...adoc[navtitle="Title",leveloffset=+1]
  const regex = /include::(.*?\.adoc)\[.*?navtitle="([^"]+)".*?\]/g;
  let match;

  while ((match = regex.exec(content)) !== null) {
    const modulePath = match[1];
    const navtitle = match[2];
    navtitles.push({ modulePath, navtitle });
  }

  return navtitles;
}

function extractAllIncludesFromFile(filePath) {
  if (!fs.existsSync(filePath)) return [];

  const content = fs.readFileSync(filePath, 'utf-8');
  const includes = [];

  // Match all include directives (with or without navtitle)
  const regex = /include::(.*?\.adoc)\[(.*?)\]/g;
  let match;

  while ((match = regex.exec(content)) !== null) {
    const modulePath = match[1];
    const attributes = match[2];

    // Extract navtitle if present
    const navtitleMatch = attributes.match(/navtitle="([^"]+)"/);
    const navtitle = navtitleMatch ? navtitleMatch[1] : null;

    includes.push({ modulePath, navtitle });
  }

  return includes;
}

function verifyCategory(categoryName, entries) {
  const categoryDir = path.join(CATEGORY_MAPS_DIR, kebabCase(categoryName));

  if (!fs.existsSync(categoryDir)) {
    console.log(`Category directory not found: ${categoryDir}`);
    return { mismatches: [], missing: [], navtitleMismatches: [], missingTopics: [], hierarchyIssues: [] };
  }

  const categoryEntries = entries.filter(e =>
    e.category.toLowerCase() === categoryName.toLowerCase()
  );

  const mismatches = [];
  const missing = [];
  const navtitleMismatches = [];
  const missingTopics = [];
  const hierarchyIssues = [];

  // Build a map of expected titles for navtitle verification
  // This includes both job-level entries (L2/L3/L4) and leaf topics (H2/H3)
  const topicTitleMap = new Map();
  for (const entry of categoryEntries) {
    const expectedTitle = getExpectedTitle(entry);
    if (expectedTitle) {
      const key = kebabCase(expectedTitle);
      // Store if not already present (first occurrence wins)
      if (!topicTitleMap.has(key)) {
        topicTitleMap.set(key, {
          title: expectedTitle,
          lineNumber: entry.lineNumber,
          entryType: getEntryType(entry)
        });
      }
    }
  }

  // Build parent-child relationships to detect missing topics
  let currentParent = null;
  const childTopics = new Map(); // parent nav file -> array of expected child topics

  for (const entry of categoryEntries) {
    const expectedTitle = getExpectedTitle(entry);
    if (!expectedTitle) continue;

    // Check if this is a parent (job level with nav file)
    if (entry.isJob || entry.level2 || entry.level3 || entry.level4) {
      currentParent = expectedTitle;
      if (!childTopics.has(currentParent)) {
        childTopics.set(currentParent, []);
      }
    } else if (currentParent && entry.topicH2) {
      // This is a leaf topic under the current parent
      childTopics.get(currentParent).push({
        title: expectedTitle,
        lineNumber: entry.lineNumber,
      });
    }
  }

  for (const entry of categoryEntries) {
    const expectedTitle = getExpectedTitle(entry);
    if (!expectedTitle) continue;

    const filePrefix = getFilePrefix(entry);
    if (!filePrefix) continue;

    // Check nav file
    const navPath = path.join(categoryDir, `nav-${filePrefix}.adoc`);
    if (fs.existsSync(navPath)) {
      const actualTitle = extractTitleFromFile(navPath);
      if (actualTitle && actualTitle !== expectedTitle) {
        mismatches.push({
          file: navPath,
          lineNumber: entry.lineNumber,
          expected: expectedTitle,
          actual: actualTitle,
          entryType: getEntryType(entry),
          tsvHierarchy: {
            category: entry.category,
            level2: entry.level2,
            level3: entry.level3,
            level4: entry.level4,
            topicH2: entry.topicH2,
            topicH3: entry.topicH3,
            isJob: entry.isJob
          }
        });
      }

      // Check navtitle attributes in includes
      const navtitles = extractNavtitlesFromFile(navPath);
      for (const { modulePath, navtitle } of navtitles) {
        const navtitleKey = kebabCase(navtitle);
        const expected = topicTitleMap.get(navtitleKey);

        if (expected && expected.title !== navtitle) {
          navtitleMismatches.push({
            file: navPath,
            modulePath,
            lineNumber: expected.lineNumber,
            expected: expected.title,
            actual: navtitle,
            entryType: expected.entryType || 'Unknown'
          });
        }
      }

      // Check for missing child topics
      const expectedChildren = childTopics.get(expectedTitle);
      if (expectedChildren && expectedChildren.length > 0) {
        const allIncludes = extractAllIncludesFromFile(navPath);
        const includedTitles = new Set();

        // Collect all titles that are included (either as file title or navtitle)
        const parentConFile = `con-${filePrefix}.adoc`;
        for (const { modulePath, navtitle } of allIncludes) {
          // Skip the parent concept file (matches the nav file) and nav- sub-job files
          // But include con- modules from the modules directory (they're leaf topics)
          if (modulePath.endsWith(parentConFile) || modulePath.includes('/nav-')) {
            continue;
          }

          // If there's a navtitle, add it
          if (navtitle) {
            includedTitles.add(kebabCase(navtitle));
          }

          // Always extract and add the module's actual title too
          if (modulePath.startsWith('modules/')) {
            const moduleFullPath = path.join(categoryDir, modulePath);
            const moduleTitle = extractTitleFromFile(moduleFullPath);
            if (moduleTitle) {
              includedTitles.add(kebabCase(moduleTitle));
            }
          }
        }

        // Check each expected child
        for (const child of expectedChildren) {
          const childKey = kebabCase(child.title);
          if (!includedTitles.has(childKey)) {
            missingTopics.push({
              parentFile: navPath,
              parentTitle: expectedTitle,
              missingTopic: child.title,
              lineNumber: child.lineNumber,
            });
          }
        }
      }
    } else if (entry.isJob || entry.level2 || entry.level3 || entry.level4) {
      // Jobs should have nav files
      missing.push({
        file: navPath,
        lineNumber: entry.lineNumber,
        expected: expectedTitle,
      });
    }

    // Check con file
    const conPath = path.join(categoryDir, `con-${filePrefix}.adoc`);
    if (fs.existsSync(conPath)) {
      const actualTitle = extractTitleFromFile(conPath);
      if (actualTitle && actualTitle !== expectedTitle) {
        mismatches.push({
          file: conPath,
          lineNumber: entry.lineNumber,
          expected: expectedTitle,
          actual: actualTitle,
          entryType: getEntryType(entry),
          tsvHierarchy: {
            category: entry.category,
            level2: entry.level2,
            level3: entry.level3,
            level4: entry.level4,
            topicH2: entry.topicH2,
            topicH3: entry.topicH3,
            isJob: entry.isJob
          }
        });
      }
    } else if (entry.isJob || entry.level2 || entry.level3 || entry.level4) {
      // Jobs should have con files
      missing.push({
        file: conPath,
        lineNumber: entry.lineNumber,
        expected: expectedTitle,
      });
    }
  }

  return { mismatches, missing, navtitleMismatches, missingTopics, hierarchyIssues };
}

function showTSVHierarchy(entries, categoryName) {
  console.log(`\n=== TSV Hierarchy for ${categoryName} ===`);

  const categoryEntries = entries.filter(e =>
    e.category.toLowerCase() === categoryName.toLowerCase()
  );

  for (const entry of categoryEntries) {
    console.log(`\nLine ${entry.lineNumber}:`);
    console.log(`  Entry type: ${getEntryType(entry)}`);
    console.log(`  Category: "${entry.category}"`);
    if (entry.level2) console.log(`  L2: "${entry.level2}"`);
    if (entry.level3) console.log(`  L3: "${entry.level3}"`);
    if (entry.level4) console.log(`  L4: "${entry.level4}"`);
    if (entry.topicH2) console.log(`  H2: "${entry.topicH2}"`);
    if (entry.topicH3) console.log(`  H3: "${entry.topicH3}"`);
    console.log(`  Is Job: ${entry.isJob}`);
    if (entry.navtitle) console.log(`  Navtitle: "${entry.navtitle}"`);
    console.log(`  Expected file title: "${getExpectedTitle(entry)}"`);
    console.log(`  Expected file prefix: "${getFilePrefix(entry)}"`);
  }
}

function main() {
  const categoryArg = process.argv[2];
  const showHierarchy = process.argv.includes('--hierarchy') || process.argv.includes('-h');

  const entries = parseTSV();

  // Get unique categories
  const categories = [...new Set(entries.map(e => e.category).filter(Boolean))];

  const categoriesToCheck = categoryArg
    ? categories.filter(c => c.toLowerCase() === categoryArg.toLowerCase())
    : categories;

  if (categoriesToCheck.length === 0) {
    console.log(`Category not found: ${categoryArg}`);
    console.log(`Available categories: ${categories.join(', ')}`);
    process.exit(1);
  }

  // If --hierarchy flag is provided, show TSV hierarchy and exit
  if (showHierarchy) {
    for (const category of categoriesToCheck) {
      showTSVHierarchy(entries, category);
    }
    return;
  }

  let totalMismatches = 0;
  let totalMissing = 0;
  let totalNavtitleMismatches = 0;
  let totalMissingTopics = 0;
  let totalHierarchyIssues = 0;

  for (const category of categoriesToCheck) {
    console.log(`\n=== Checking category: ${category} ===`);
    const { mismatches, missing, navtitleMismatches, missingTopics, hierarchyIssues } = verifyCategory(category, entries);

    if (mismatches.length > 0) {
      console.log(`\nTitle mismatches (${mismatches.length}):`);
      for (const m of mismatches) {
        console.log(`\n  File: ${path.relative(process.cwd(), m.file)}`);
        console.log(`  TSV line: ${m.lineNumber}`);
        console.log(`  Entry type: ${m.entryType || 'Unknown'}`);
        console.log(`  TSV hierarchy:`);
        if (m.tsvHierarchy) {
          if (m.tsvHierarchy.level2) console.log(`    L2: "${m.tsvHierarchy.level2}"`);
          if (m.tsvHierarchy.level3) console.log(`    L3: "${m.tsvHierarchy.level3}"`);
          if (m.tsvHierarchy.level4) console.log(`    L4: "${m.tsvHierarchy.level4}"`);
          if (m.tsvHierarchy.topicH2) console.log(`    H2: "${m.tsvHierarchy.topicH2}"`);
          if (m.tsvHierarchy.topicH3) console.log(`    H3: "${m.tsvHierarchy.topicH3}"`);
          console.log(`    Is job: ${m.tsvHierarchy.isJob}`);
        }
        console.log(`  Expected title: "${m.expected}"`);
        console.log(`  Actual title:   "${m.actual}"`);
      }
      totalMismatches += mismatches.length;
    }

    if (navtitleMismatches.length > 0) {
      console.log(`\nNavtitle mismatches (${navtitleMismatches.length}):`);
      for (const m of navtitleMismatches) {
        console.log(`\n  File: ${path.relative(process.cwd(), m.file)}`);
        console.log(`  Module: ${m.modulePath}`);
        console.log(`  TSV line: ${m.lineNumber}`);
        console.log(`  Entry type: ${m.entryType || 'Unknown'}`);
        console.log(`  Expected navtitle: "${m.expected}"`);
        console.log(`  Actual navtitle:   "${m.actual}"`);
      }
      totalNavtitleMismatches += navtitleMismatches.length;
    }

    if (missing.length > 0) {
      console.log(`\nMissing files (${missing.length}):`);
      for (const m of missing) {
        console.log(`\n  File: ${path.relative(process.cwd(), m.file)}`);
        console.log(`  TSV line: ${m.lineNumber}`);
        console.log(`  Expected title: "${m.expected}"`);
      }
      totalMissing += missing.length;
    }

    if (missingTopics.length > 0) {
      console.log(`\nMissing topic includes (${missingTopics.length}):`);
      for (const m of missingTopics) {
        console.log(`\n  Parent nav file: ${path.relative(process.cwd(), m.parentFile)}`);
        console.log(`  Parent title: "${m.parentTitle}"`);
        console.log(`  Missing topic: "${m.missingTopic}"`);
        console.log(`  TSV line: ${m.lineNumber}`);
      }
      totalMissingTopics += missingTopics.length;
    }

    if (mismatches.length === 0 && missing.length === 0 && navtitleMismatches.length === 0 && missingTopics.length === 0) {
      console.log(`✓ All titles match TSV and all topics are included`);
    }

    totalHierarchyIssues += hierarchyIssues.length;
  }

  console.log(`\n=== Summary ===`);
  console.log(`Total title mismatches: ${totalMismatches}`);
  console.log(`Total navtitle mismatches: ${totalNavtitleMismatches}`);
  console.log(`Total missing files: ${totalMissing}`);
  console.log(`Total missing topic includes: ${totalMissingTopics}`);
  console.log(`Total hierarchy issues: ${totalHierarchyIssues}`);

  const totalIssues = totalMismatches + totalNavtitleMismatches + totalMissingTopics + totalHierarchyIssues;

  if (totalIssues === 0) {
    console.log(`\n✅ All verification checks passed! TSV hierarchy matches file structure.`);
  } else {
    console.log(`\n❌ Found ${totalIssues} issues that need to be fixed.`);
  }

  process.exit(totalIssues > 0 ? 1 : 0);
}

main();
