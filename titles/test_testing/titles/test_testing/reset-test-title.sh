#!/bin/bash
# Reset the test title to its original skeleton state

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Resetting test title to original state..."

# Remove all content files but keep the directory
cd "$REPO_ROOT"
rm -f assemblies/test_testing/*.adoc
rm -f modules/test_testing/*.adoc
rm -f titles/test_testing/master.adoc

# Recreate symlinks in titles/test_testing/
cd titles/test_testing
rm -f artifacts assemblies modules images docinfo.xml
ln -sf ../../artifacts artifacts
ln -sf ../../assemblies assemblies
ln -sf ../../modules modules
ln -sf ../../images images
ln -sf ../../artifacts/docinfo.xml docinfo.xml

cd "$REPO_ROOT"

# Recreate master.adoc
cat > titles/test_testing/master.adoc << 'MASTER'
:_mod-docs-content-type: ASSEMBLY
:_mod-docs-category: Test

include::artifacts/attributes.adoc[]

:title: Testing AsciiDoc Structures
:subtitle: Skeleton title for testing AsciiDoc structures and conventions
:abstract: This is a test title for experimenting with AsciiDoc structures, modular documentation patterns, and build configurations.
:context: test-testing

:platform-id: ocp
:platform-long: {ocp-brand-name} ({ocp-very-short})
:platform: {ocp-short}
:platform-cli: oc
:platform-cli-link: {ocp-docs-link}/html-single/cli_tools/index#cli-about-cli_cli-developer-commands[{openshift-cli}]
:platform-cli-name: {ocp-brand-name} CLI ('oc')
:a-platform-generic: an OpenShift
:platform-generic: OpenShift
:namespace: project
:optional-steps: enable

[id="{context}"]
= {title}

[role="_abstract"]
{abstract}

include::assemblies/test_testing/assembly-test-example.adoc[leveloffset=+1]
MASTER

# Recreate assembly
cat > assemblies/test_testing/assembly-test-example.adoc << 'ASSEMBLY'
:_mod-docs-content-type: ASSEMBLY
ifdef::context[:parent-context: {context}]

[id="test-example_{context}"]
= Test example assembly

:context: test-example

[role="_abstract"]
This is a test assembly that demonstrates the modular documentation structure with concept, procedure, and reference modules.

include::../modules/test_testing/con-test-concept.adoc[leveloffset=+1]

include::../modules/test_testing/proc-test-procedure.adoc[leveloffset=+1]

include::../modules/test_testing/ref-test-reference.adoc[leveloffset=+1]

ifdef::parent-context[:context: {parent-context}]
ifndef::parent-context[:!context:]
ASSEMBLY

# Recreate concept module
cat > modules/test_testing/con-test-concept.adoc << 'CONCEPT'
:_mod-docs-content-type: CONCEPT

[id="test-concept_{context}"]
= Test concept module

[role="_abstract"]
This is a test concept module that explains background information, definitions, or architectural overview.

Concept modules provide context and understanding. They answer "what is it?" and "why does it matter?"

Key characteristics of concept modules:

* Provide background information
* Explain architectural decisions
* Define terminology
* Describe how components relate to each other
* Do not include procedures or reference information

[role="_additional-resources"]
.Additional resources
* xref:test-procedure_{context}[Test procedure module]
* xref:test-reference_{context}[Test reference module]
CONCEPT

# Recreate procedure module
cat > modules/test_testing/proc-test-procedure.adoc << 'PROCEDURE'
:_mod-docs-content-type: PROCEDURE

[id="test-procedure_{context}"]
= Test procedure module

[role="_abstract"]
This is a test procedure module that provides step-by-step instructions for completing a task.

Procedure modules are task-oriented. They answer "how do I do this?"

.Prerequisites

* You have completed the prerequisite task
* You have the required permissions
* You understand the concept explained in xref:test-concept_{context}[Test concept module]

.Procedure

. First step in the procedure.
+
This is additional context for step 1.

. Second step in the procedure.
+
[source,yaml]
----
example:
  configuration: value
----

. Third step in the procedure.
+
--
* Sub-item A
* Sub-item B
--

. Fourth step completes the procedure.

.Verification

* Verify that the task completed successfully by checking the output.
+
The expected result should appear.

.Troubleshooting

If the procedure fails, check the following:

* Ensure prerequisites are met
* Review the configuration syntax
* Check the logs for errors

[role="_additional-resources"]
.Additional resources
* xref:test-concept_{context}[Test concept module]
* xref:test-reference_{context}[Test reference module]
PROCEDURE

# Recreate reference module
cat > modules/test_testing/ref-test-reference.adoc << 'REFERENCE'
:_mod-docs-content-type: REFERENCE

[id="test-reference_{context}"]
= Test reference module

[role="_abstract"]
This is a test reference module that provides detailed reference information such as API specifications, configuration options, or command syntax.

Reference modules provide lookup information. They answer "what are the options?" and "what is the syntax?"

[cols="1,1,1,3",options="header"]
|===
|Parameter
|Type
|Required
|Description

|`parameter1`
|string
|Yes
|Description of parameter1. This parameter controls the primary behavior.

|`parameter2`
|integer
|No
|Description of parameter2. Default value is `100`.

|`parameter3`
|boolean
|No
|Description of parameter3. Default value is `true`.

|`parameter4`
|object
|No
|Description of parameter4. This is a complex object with nested properties.
|===

== Configuration example

The following example shows a complete configuration:

[source,yaml]
----
apiVersion: example.com/v1
kind: TestResource
metadata:
  name: test-example
spec:
  parameter1: "value1"
  parameter2: 200
  parameter3: false
  parameter4:
    nestedField1: "nested-value"
    nestedField2: 42
----

== Additional reference information

[cols="1,2",options="header"]
|===
|Option
|Description

|Option A
|Description of option A

|Option B
|Description of option B

|Option C
|Description of option C
|===

[role="_additional-resources"]
.Additional resources
* xref:test-concept_{context}[Test concept module]
* xref:test-procedure_{context}[Test procedure module]
REFERENCE

echo "✅ Test title reset complete!"
echo ""
echo "Files restored:"
echo "  - titles/test_testing/master.adoc"
echo "  - assemblies/test_testing/assembly-test-example.adoc"
echo "  - modules/test_testing/con-test-concept.adoc"
echo "  - modules/test_testing/proc-test-procedure.adoc"
echo "  - modules/test_testing/ref-test-reference.adoc"
