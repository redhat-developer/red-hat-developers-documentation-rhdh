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

    const entry = {
      lineNumber: i + 1,
      category: currentCategory,  // Use tracked category, not just the column value
      level2: cols[1]?.trim() || '',
      level3: cols[2]?.trim() || '',
      level4: cols[3]?.trim() || '',
      topicH2: cols[4]?.trim() || '',  // Column 5 "Topic (H2)"
      topicH3: cols[5]?.trim() || '',  // Column 6 "H3"
      filePath: cols[6]?.trim() || '', // Column 7 "Full .adoc file path"
      // Note: Columns 8-9 appear shifted in actual data vs header
      // Actual data has "Is a job?" at column 10, not column 8
      isJob: (cols[9]?.trim().toUpperCase() === 'TRUE') || (cols[7]?.trim().toUpperCase() === 'TRUE'),
      navtitle: cols[8]?.trim() || '',
    };
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

function getExpectedTitle(entry) {
  // Determine which level this entry represents
  // Return the first non-empty value from the hierarchy
  if (entry.level4) {
    return entry.level4;
  }
  if (entry.level3) {
    return entry.level3;
  }
  if (entry.level2) {
    return entry.level2;
  }
  if (entry.topicH3) {
    return entry.topicH3;
  }
  if (entry.topicH2) {
    return entry.topicH2;
  }
  // Category-only entries (no L2/L3/L4/H2/H3) return the category
  if (entry.category && !entry.level2 && !entry.level3 && !entry.level4 && !entry.topicH2 && !entry.topicH3) {
    return entry.category;
  }
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
    return { mismatches: [], missing: [], navtitleMismatches: [], missingTopics: [] };
  }

  const categoryEntries = entries.filter(e =>
    e.category.toLowerCase() === categoryName.toLowerCase()
  );

  const mismatches = [];
  const missing = [];
  const navtitleMismatches = [];
  const missingTopics = [];

  // Build a map of expected titles for navtitle verification
  // This includes both job-level entries (L2/L3/L4) and leaf topics (H2/H3)
  const topicTitleMap = new Map();
  for (const entry of categoryEntries) {
    const expectedTitle = getExpectedTitle(entry);
    if (expectedTitle) {
      const key = kebabCase(expectedTitle);
      // Store if not already present (first occurrence wins)
      if (!topicTitleMap.has(key)) {
        topicTitleMap.set(key, { title: expectedTitle, lineNumber: entry.lineNumber });
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

          if (navtitle) {
            includedTitles.add(kebabCase(navtitle));
          }
          // Also extract the title from the module file if no navtitle
          if (!navtitle && modulePath.startsWith('modules/')) {
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

  return { mismatches, missing, navtitleMismatches, missingTopics };
}

function main() {
  const categoryArg = process.argv[2];

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

  let totalMismatches = 0;
  let totalMissing = 0;
  let totalNavtitleMismatches = 0;
  let totalMissingTopics = 0;

  for (const category of categoriesToCheck) {
    console.log(`\n=== Checking category: ${category} ===`);
    const { mismatches, missing, navtitleMismatches, missingTopics } = verifyCategory(category, entries);

    if (mismatches.length > 0) {
      console.log(`\nTitle mismatches (${mismatches.length}):`);
      for (const m of mismatches) {
        console.log(`\n  File: ${path.relative(process.cwd(), m.file)}`);
        console.log(`  TSV line: ${m.lineNumber}`);
        console.log(`  Expected: "${m.expected}"`);
        console.log(`  Actual:   "${m.actual}"`);
      }
      totalMismatches += mismatches.length;
    }

    if (navtitleMismatches.length > 0) {
      console.log(`\nNavtitle mismatches (${navtitleMismatches.length}):`);
      for (const m of navtitleMismatches) {
        console.log(`\n  File: ${path.relative(process.cwd(), m.file)}`);
        console.log(`  Module: ${m.modulePath}`);
        console.log(`  TSV line: ${m.lineNumber}`);
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
  }

  console.log(`\n=== Summary ===`);
  console.log(`Total title mismatches: ${totalMismatches}`);
  console.log(`Total navtitle mismatches: ${totalNavtitleMismatches}`);
  console.log(`Total missing files: ${totalMissing}`);
  console.log(`Total missing topic includes: ${totalMissingTopics}`);

  process.exit((totalMismatches + totalNavtitleMismatches + totalMissingTopics) > 0 ? 1 : 0);
}

main();
