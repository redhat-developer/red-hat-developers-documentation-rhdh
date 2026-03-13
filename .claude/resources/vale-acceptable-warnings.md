# Vale Acceptable Warnings

Some Vale DITA warnings are acceptable and do not block CQA 2.1 compliance.

## Callout Warnings

- **Warning**: `AsciiDocDITA.CalloutList`: "Callouts are not supported in DITA"
- **Context**: Callouts (`<1>`, `<2>`, etc.) in code blocks with corresponding explanations
- **Acceptable**: Yes - this is a known DITA limitation, but callouts are valuable for technical documentation
- **Note**: Track these warnings but do not remove callouts

**Example**:
```asciidoc
[source,yaml]
----
app:
  baseUrl: https://example.com  # <1>
  title: My App  # <2>
----
<1> The base URL for your application
<2> The display title
```

## Concept Link False Positives

- **Warning**: `AsciiDocDITA.ConceptLink`: "Move all links and cross references to Additional resources"
- **Context**: Vale sometimes detects abbreviations like "CR" (Custom Resource) as cross-references
- **Acceptable**: Yes - if the warning is on plain text abbreviations, not actual links
- **Fix**: You can ignore these false positives, or spell out the abbreviation if desired

**Example** (false positive):
```asciidoc
Create a CR (Custom Resource) for the configuration.
```

## Task Step Warnings in Introductory Content

- **Warning**: `AsciiDocDITA.TaskStep`: "Content other than a single list cannot be mapped to DITA tasks"
- **Context**: Descriptive content before `.Procedure` section
- **Acceptable**: Sometimes - if the content is legitimately before the procedure section (like field definitions)
- **Fix**: If the warning appears AFTER `.Procedure`, add a continuation mark (+). If before, it may be acceptable.

**Example** (acceptable - before .Procedure):
```asciidoc
[role="_abstract"]
Configure the plugin settings.

The following fields are available:

Name::
The display name for the plugin

Type::
The plugin type (frontend or backend)

.Procedure

. Edit the configuration file.
```

**Example** (NOT acceptable - after .Procedure):
```asciidoc
.Procedure

. Edit the configuration file.

The file contains the following settings:
* Setting 1
* Setting 2
```

## Success Criteria

CQA 2.1 compliance is achieved when:
- Vale DITA validation shows: `0 errors, 0-15 acceptable warnings, 0 suggestions`
- Acceptable warnings are documented and verified as false positives or known limitations
- Vale Red Hat style validation shows: `0 errors, 0 warnings`
- Build validation (`build/scripts/build-ccutil.sh`) completes successfully with all titles built and no xref errors
