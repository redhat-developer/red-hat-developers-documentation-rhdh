# Procedure Module Style Guide

Complete formatting and style reference for procedure modules in Red Hat Developer Hub documentation.

## Title → ID → Filename Sequence (CRITICAL)

**Always follow this exact order:**

1. **Fix the TITLE first** (the title is the source of truth):
   - Use imperative form (not gerund): "Enable the plugin" not "Enabling the plugin"
   - Remove unnecessary context: "Enable the plugin" not "Enable the plugin in {product}"
   - Example: `= Enable the Adoption Insights plugin`

2. **Update the ID to match the title** (ID derives from title, not filename):
   - Convert title to lowercase with hyphens
   - Add `_{context}` suffix
   - **Do NOT include the proc- prefix** in the ID
   - Example: `[id="enable-the-adoption-insights-plugin_{context}"]`

3. **Rename the filename to match the title** (filename derives from title):
   - Keep the `proc-` prefix in the filename
   - Convert title to lowercase with hyphens
   - Example: `proc-enable-the-adoption-insights-plugin.adoc`

### Complete Example (Correct Sequence)
```asciidoc
# File: proc-enable-the-adoption-insights-plugin.adoc (renamed to match title)

[id="enable-the-adoption-insights-plugin_{context}"]  ← Matches title

= Enable the Adoption Insights plugin  ← Source of truth
```

## Procedure Formatting

**Multi-step procedures**: Use ordered lists (numbered steps) with imperative statements
```asciidoc
.Procedure

. First step.
. Second step.
. Third step.
```

**Single-step procedures**: Use unordered list (single bullet) instead of numbered list
```asciidoc
.Procedure

* In your `dynamic-plugins.yaml` file, update the value to `true`.
```

**Note on title format**: Red Hat modular docs specify gerund phrases (e.g., "Creating tables"), but Style Guide uses imperative form (e.g., "Create tables"). Only imperative form is acceptable.

**Substeps**: Use proper indentation with continuation (+)
```asciidoc
. Main step.
+
Additional context for the step.
+
[source,yaml]
----
code example
----

. Next step with substeps:

.. Substep 1.
.. Substep 2.
```

## Standard Procedure Sections

From Red Hat modular docs:

- `.Prerequisites` - Bulleted list of conditions (always plural)
- `.Procedure` - Numbered steps (required) or single bullet for one-step procedures
- `.Verification` - How to confirm success (show expected output or verification actions)
- `.Troubleshooting` - Brief issue resolution; link to separate procedures for complex troubleshooting
- `.Next steps` - Links to related instructions only (not additional instruction sequences)
- `.Additional resources` - Links to related documentation

## Content Organization

**One sentence per line**: Each sentence on its own line for better diff tracking and readability.

**Move non-procedure content before .Procedure**:
```asciidoc
[role="_abstract"]
Short description here.

Introductory content explaining context.

Field definitions or data descriptions go here:

Name::
Description of the name field

Kind::
Description of the kind field

.Procedure

. The actual steps go here.
```

## Description Lists vs Unordered Lists

**Use description lists** (not unordered lists with bold formatting) for field definitions:

✗ **Wrong**:
```asciidoc
* *Name*: Description
* *Kind*: Description
```

✓ **Correct**:
```asciidoc
Name::
Description

Kind::
Description
```

**Do NOT use bold formatting in description list terms** - the term itself is automatically formatted.

## Configuration Settings

**Use description lists for configuration parameters**:
```asciidoc
`maxBufferSize`::
(Optional) Enter the maximum buffer size for event batching.
The default value is `20`.

`flushInterval`::
(Optional) Enter the flush interval in milliseconds.
The default value is `5000ms`.
```

**Use "Enter" rather than "Specifies"** in parameter descriptions.

## File and Object References

- **Be specific about what you're referencing**:
  - Use "`dynamic-plugins.yaml` file" not "dynamic plugins config map" (unless you specifically mean a ConfigMap object)
  - Use "config map" (lowercase, two words) for the general concept
  - Use "ConfigMap" (one word, capitalized) only for Kubernetes ConfigMap objects

## Lists in Procedures

**Convert inline lists to proper list formatting**:

✗ **Wrong**:
```asciidoc
You can use the following options: *Option 1*, *Option 2*, or *Option 3*.
```

✓ **Correct**:
```asciidoc
You can use any of the following options:

* *Option 1*
* *Option 2*
* *Option 3*
```

## Source Code Block Types

**Use the correct source type for code blocks**:

- Use `[source,terminal]` for terminal commands (commands you run in a shell)
- Use `[source,bash]` only for bash scripts (complete scripts with shebang, variables, logic)
- Use `[source,yaml]`, `[source,json]`, etc. for configuration files

✗ **Wrong**:
```asciidoc
[source,bash]
----
$ oc project openshift-logging
----
```

✓ **Correct**:
```asciidoc
[source,terminal]
----
$ oc project openshift-logging
----
```

## Voice and Tense in Procedures

**Avoid passive voice in procedures (except in prerequisites)**:

✗ **Wrong**:
```asciidoc
. Configure outputs to specify where the captured logs are sent.
. Tuning can be applied per output as needed.
. Confirm that logs are being forwarded to your Splunk instance.
```

✓ **Correct**:
```asciidoc
. Configure outputs to specify where to send the captured logs.
. You can apply tuning per output as needed.
. Verify that your Splunk instance receives logs.
```

**Use present tense in procedures (except in prerequisites)**:

✗ **Wrong** (past or future tense):
```asciidoc
. The forwarder will send logs to the destination.
. The system was configured to use TLS.
```

✓ **Correct** (present tense):
```asciidoc
. The forwarder sends logs to the destination.
. The system uses TLS for secure communication.
```

**Note**: Prerequisites can use past tense (e.g., "You have installed", "You have configured").

## Abstract Guidelines

**Keep abstracts concise and focused**:

- 50-300 characters
- Focus on the essential action and tools
- Avoid excessive implementation details
- Describe the value/purpose, not just "Learn about X"

✗ **Wrong** (217 characters, too detailed):
```asciidoc
[role="_abstract"]
To forward audit logs from {product-short} to Splunk, use the {logging-brand-name} ({logging-short}) Operator and a ClusterLogForwarder instance to capture streamed logs and send them to the HTTPS endpoint of your Splunk instance.
```

✓ **Correct** (113 characters, focused):
```asciidoc
[role="_abstract"]
Forward audit logs from {product-short} to Splunk by using the {logging-short} Operator and a ClusterLogForwarder instance.
```
