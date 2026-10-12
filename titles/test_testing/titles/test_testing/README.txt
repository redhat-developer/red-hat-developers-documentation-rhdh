TEST TITLE - NOT FOR PRODUCTION
================================

This is a skeleton title structure for testing AsciiDoc patterns.
It will NEVER be committed to git (see .gitignore).

FILES
-----
  titles/test_testing/master.adoc          - Title master file
  assemblies/test_testing/                 - Assembly files
  modules/test_testing/                    - Module files (con-, proc-, ref-)

USAGE
-----
Build this test title:
  ccutil compile --lang en-US --format html-single titles/test_testing/master.adoc

Or with asciidoctor:
  asciidoctor titles/test_testing/master.adoc

RESET TO ORIGINAL STATE
------------------------
After experimenting, restore the original skeleton files:

Option 1 - Run the reset script:
  bash titles/test_testing/reset-test-title.sh

Option 2 - Manual deletion:
  rm -f assemblies/test_testing/*.adoc
  rm -f modules/test_testing/*.adoc
  rm -f titles/test_testing/master.adoc
  # Then run the reset script to recreate

Option 3 - Complete removal and recreation:
  rm -rf titles/test_testing assemblies/test_testing modules/test_testing
  # Then re-run the original setup commands

The reset script will:
  - Delete all .adoc files in test directories
  - Recreate all original skeleton files
  - Restore symlinks in titles/test_testing/
  - Leave any build artifacts (build/ directory) untouched
