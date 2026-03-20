# Red Hat Supplementary Style Guide - CQA Extract

**Purpose:** This file contains selected sections from the full Red Hat Supplementary Style Guide that are most relevant for CQA (Content Quality Assessment) documentation reviews.

**Full version:** For the complete guide, see `.claude/resources/red-hat-ssg.md`

**Contents:**
- Conscious language
- Contractions
- Conversational style
- Minimalism
- Users
- Product names and version references
- Single-step procedures
- Titles and headings
- User-replaced values
- Admonitions
- Lead-in sentences
- Prerequisites
- Short descriptions
- Developer Preview
- Technology Preview

---

## Conscious language

The Conscious Language Group supports the Red Hat commitment to remove problematic language from our code, documentation, websites, and open source projects with which Red Hat is involved.
For more information about the Conscious Language Group, see https://github.com/conscious-lang/conscious-lang-docs.

> **IMPORTANT:**

To ensure consistency and success, it is imperative for product team stakeholders to align internally. For example, documentation teams should engage in discussions with their engineering leadership to reach an agreement on replacement terms. This ensures that the product documentation matches the code.


### Blacklist and whitelist

When possible, rewrite documentation to avoid these terms.
When it is not possible to remove the terms _blacklist_ and _whitelist_, replace them with one of the following alternatives:

* Blocklist / allowlist: This combination is recommended by the _IBM Style_ guide. Use this combination unless your product area has another specific replacement that is agreed between engineering leadership and your documentation team.
* Denylist / allowlist
* Blocklist / passlist
* You can also use a term that has been agreed by your product team stakeholders.

**Examples**

* Removing blacklist

  ![no](images/no.png) Heat _blacklists_ any servers in the list from receiving updated heat deployments. After the stack operation completes, any blacklisted servers remain unchanged. You can also power off or stop the `os-collect-config` agents during the operation.

  ![yes](images/yes.png) Heat _excludes_ any servers in the list from receiving updated heat deployments. After the stack operation completes, any excluded servers remain unchanged. You can also power off or stop the `os-collect-config` agents during the operation.
* Removing whitelist

  ![no](images/no.png) The following steps demonstrate adding a new rule to _whitelist_ a custom binary.

  ![yes](images/yes.png) The following steps demonstrate adding a new rule to _allow_ a custom binary.

### Master and slave

When possible, rewrite documentation to avoid these terms. When it is not possible to rewrite, you can use the following alternatives for _master_ / _slave_:

* Primary / secondary
* Source / replica
* Initiator, requester / responder
* Controller, host / device, worker, proxy
* Director / performer
* Controller / port interface (in networking)
* You can also use a term that has been agreed by your product team stakeholders.

**Examples**

* Removing _master_

  ![no](images/no.png) A Ceph Monitor maintains the _master_ copy of the Red Hat Ceph Storage cluster map with the current state of the Red Hat Ceph Storage cluster.

  ![yes](images/yes.png) A Ceph Monitor maintains the _primary_ copy of the Red Hat Ceph Storage cluster map with the current state of the Red Hat Ceph Storage cluster.

  ![yes](images/yes.png) A Ceph Monitor maintains the _main_ copy of the Red Hat Ceph Storage cluster map with the current state of the Red Hat Ceph Storage cluster.
* Removing _slave_

  ![no](images/no.png) Use the following command to copy the public key to the _slave_ node.

  ![yes](images/yes.png) Use the following command to copy the public key to the _secondary_ node.

## Contractions

Avoid contractions in product documentation to leave no ambiguity and to make it easier for translation and international audiences.

If you are writing quick start or other content that uses a more informal [conversational style](#conversational-style) (_fairly conversational_ or _more conversational_), you may use contractions. In this case, follow the guidance in the _IBM Style_ guide on using contractions.

## Conversational style

Follow the _IBM Style_ guide advice of _less conversational_ style in most cases.

Red Hat Enterprise Linux 8 delivers a stable, secure, and consistent foundation across hybrid cloud deployments with the tools needed to deliver workloads faster with less effort.

As needed, adjust the conversational to _fairly conversational_ for an audience of new users or _least conversational_ for API documentation and other very experienced audiences.

> **NOTE:**

Documentation for cloud services follows the _IBM Style_ guide for _fairly conversational_ tone. When using _fairly conversational_ tone, use contractions where appropriate.

## Minimalism
Minimalism is a methodology for creating targeted documentation focused on your readers' needs. If you understand your customers' needs, you can write shorter and simpler documentation specific to what customers want to do.

Minimalism has five principles:

### Principle 1: Customer focus and action orientation
Know what your users do, what their goals are, and why they perform these actions. Minimize how much content customers must wade through to get to something they recognize as real work. Separate conceptual and background information from procedural tasks.

### Principle 2: Findability
Findability covers two areas:

* Ensure your content is findable through Google search and access.redhat.com site searches.
* Ensure your content is scannable. Use short paragraphs and sentences and bulleted lists where appropriate.

### Principle 3: Titles and headings
Use clear titles with familiar keywords for customers. Keep titles and headings between 3 to 11 words. Headings that are too short lack clarity and don't help customers know what's in a section. Headings that are too long are less visible in Google searches and harder for customers to understand.

### Principle 4: Elimination of fluff
Avoid long introductions and unnecessary context. Shorten unnecessarily long sentences.

### Principle 5: Error recovery, verification, and troubleshooting
Recognize that people make mistakes and need to verify that they have completed a task. Be sure to include troubleshooting, error recovery, and verification steps.

## Users
In most cases, the word "user" refers to a person or a person's user account, and therefore would be considered animate. In these cases, use animate personal pronouns such as "who".

In certain technical cases, these users are not persons but instead system accounts or more abstract concepts (inanimate). For example, Linux `root` and `guest` users do not relate to any person. Applications and services might run as specific Linux users with no person controlling them. SELinux users such as `user_u` or `sysadm_u` are identifiers of one or multiple Linux users for access control purposes. In these specific cases, refer to these inanimate users with inanimate personal pronouns such as "that".

In these specific cases, and only if you cannot write around it, you can refer to these inanimate users with inanimate personal pronouns such as "that".

**Examples**

* Animate user

  ![no](images/no.png) Experienced _users that_ can configure their own systems...

  ![yes](images/yes.png) _Users who_ want to install their own packages...
* Inanimate user

  ![no](images/no.png) A Linux user has the restrictions of the _SELinux user who_ it is assigned to.

  ![no](images/no.png) A Linux user has the restrictions of the _SELinux user_ to _whom_ it is assigned.

  ![yes](images/yes.png) Specify a _user that_ is allowed to perform the requested action.

  ![yes](images/yes.png) A Linux user has the restrictions of the _SELinux user that_ it is assigned to.

## Product names and version references

Use attributes instead of hard-coded references when you refer to the name of your product in full, to its abbreviated form, or to its major or minor version.
Only use hard-coded version references if the version that you are referring to in a particular case never changes.

### Attribute file

Define attributes for product name and product version and store them in a dedicated attributes file for each set of product documentation.
For examples of where you can store the shared attributes file inside your documentation repository, see the [Example modular documentation repository](https://github.com/redhat-documentation/modular-docs/blob/mod-doc-repo-example/_artifacts/document-attributes.adoc).
Include the attributes file at the beginning of the `master.adoc` files of all titles in your documentation set:

**Example AsciiDoc: Attribute file included in a master.adoc file**

```
include::__<path_to_directory_with_attributes_file>__/attributes.adoc[]
```

### Minimum required attributes

Define attributes for the following values in each documentation set.
Note that the attribute names used in this section are only meant as examples.
You can use different attribute names:

* **The name of the product**\
Use the product name attribute for all instances of the product name where possible.
Avoid using hard-coded product names.
For example:

  **Example AsciiDoc: Product name attribute**

  ```
  :name-product: Red Hat JBoss Enterprise Application Platform
  ```
* **The abbreviated form of the product name**\
If it is necessary for your product, you can use an attribute to store a shortened version of the name of your product, for example:

  **Example AsciiDoc: Abbreviated product name attribute**

  ```
  :name-product-abbreviated: JBoss EAP
  ```
* **The major and minor version of the product**\
Use an attribute for the product version in cases where the product version can change with each release and the content is still correct.
For example:

  **Example AsciiDoc: Product version attributes**

  ```
  :version-product-minor: 1.11
  :version-product-patch: 1.11.6
  ```

  > **NOTE:**

  Do not use the product version attribute if the version should not change.
  For example, if a feature was introduced in a certain version, the version should be hard-coded.


You might create additional attributes according to what your documentation requires.
For example, you might combine existing product name attributes to create compound names of products or components:

**Example attributes for compound names of product components**

```
:name-runtime-spring-boot: Spring Boot
:name-runtime-vertx: Eclipse Vert.x
:name-spring-reactive: {name-runtime-spring-boot} with {name-runtime-vertx} reactive components
```

## Single-step procedures

When a procedure contains only one step, use an unnumbered bullet.

For example:
* Install the `dnf-automatic` package.

## Titles and headings

Write all titles and headings, including the titles of product documentation guides and Knowledgebase articles, in sentence-style capitalization. Do not use headline-style capitalization.

**Examples**

* _Composing a customized RHEL system image_
* _Configuring the node port service range_
* _How to perform an unsupported conversion from a RHEL-derived Linux distribution to RHEL_

## User-replaced values

A _user-replaced value_, also known as a replaceable or variable value, is a placeholder that the user replaces with a value that is relevant for their situation. User-replaced values are often found in places such as code blocks, file paths, and commands.

Use descriptive names for user-replaced values and follow this general format: _&lt;value_name>_.

> **NOTE:**

For XML code blocks, see the guidance on [user-replaced values for XML](#user-replaced-values-for-xml).


Ensure that user-replaced values have the following characteristics:

* Surrounded by angle brackets (`< >`)
* Separated by underscores (`_`) for multi-word values
* Lowercase, unless the rest of the related text is uppercase or another capitalization scheme
* Italicized
* If the user-replaced value is referencing a value in code or in a command that is normally monospace, also use monospace for the user-replaced value
* If you want to use a user-replaced value in example output, format the replaceable value with italics and in angle brackets. Alternatively, if you choose to use an example value instead, do not italicize the example value and do not place it in angle brackets.

```
Create an Ansible inventory file that is named `/_<path>_/inventory/hosts`.
```

This example renders as follows in HTML:

Create an Ansible inventory file that is named `/_<path>_/inventory/hosts`.

To italicize a user-replaced value in a code block, you must add an attribute to apply text formatting, such as `subs="+quotes"` or `subs="normal"`, to the attribute list of the code block.

    [subs="+quotes"]
    ----
    $ *oc describe node __<node_name>__*
    ----

This example renders as follows in HTML:

```
$ *oc describe node __<node_name>__*
```

    [subs="+quotes"]
    ----
    connection.id:              __<profile_name>__
    connection.uuid:            b6cdfa1c-e4ad-46e5-af8b-a75f06b79f76
    connection.type:            802-3-ethernet
    connection.interface-name:  enp7s0
    ----

This example renders as follows in HTML:

```
connection.id:              __<profile_name>__
connection.uuid:            b6cdfa1c-e4ad-46e5-af8b-a75f06b79f76
connection.type:            802-3-ethernet
connection.interface-name:  enp7s0
```

To explain user-replaced values used in a code block, you must use a definition list following the code block. See [Explanation of commands and variables used in code blocks](#explanation-of-commands-and-variables-used-in-code-blocks) for details.

### User-replaced values for XML

Because XML uses angle brackets (`< >`), the [default guidance](#user-replaced-values) for user-replaced values does not work well for it. If you are using user-replaced values in an XML code block, use the following format: _${value_name}_.

Ensure that user-replaced values in XML have the following characteristics:

* Surrounded by curly braces and preceded by a dollar sign (`${ }`)
* Separated by underscores (`_`) for multi-word values
* Lowercase, unless the rest of the related text is uppercase or another capitalization scheme
* Italicized
* If the user-replaced value is referencing a value in code or in a command that is normally monospace, also use monospace for the user-replaced value

    [source,xml,subs="+quotes"]
    ----
    <ipAddress>__${ip_address}__</ipAddress>
    ----

This example renders as follows in HTML:

```xml
<ipAddress>__${ip_address}__</ipAddress>
```

    [source,xml,subs="+quotes"]
    ----
    <oauth2-introspection client-id="__${client_id}__"/>
    ----

This example renders as follows in HTML:

```xml
<oauth2-introspection client-id="__${client_id}__"/>
```

To explain user-replaced values used in a code block, you must use a definition list following the code block. See [Explanation of commands and variables used in code blocks](#explanation-of-commands-and-variables-used-in-code-blocks) for details.

## Admonitions

Admonitions should draw the reader's attention to certain information. Keep admonitions to a minimum, and avoid placing multiple admonitions close to one another. If multiple admonitions are necessary, restructure the information by moving the less-important statements into the flow of the main content.

Valid admonition types:

* **NOTE**\
Additional guidance or advice that improves product configuration, performance, or supportability.
* **IMPORTANT**\
Advisory information essential to the completion of a task. Users must not disregard this information.
* **WARNING**\
Information about potential system damage, data loss, or a support-related issue if the user disregards this admonition. Explain the problem, cause, and offer a solution that works. If available, offer information to avoid the problem in the future or state where to find more information.
* **TIP**\
Alternative methods that might not be obvious. Makes applying the techniques and procedures described in the text easier or targets specific needs. Helps users understand the benefits and capabilities of the product. Not essential to using the product.

> **IMPORTANT:**

CAUTION, which is another type of AsciiDoc admonition, is not fully supported by the Red Hat Customer Portal. Do not use this admonition type.


Admonitions should be short and concise. Do not include procedures in an admonition.

Only individual admonitions are allowed, for example, you cannot have a plural **NOTES** heading.

**Example AsciiDoc**

```
[NOTE]
====
Text for note.
====
```

## Lead-in sentences

A lead-in sentence in this context is the text that directly follows a `Prerequisites` or `Procedure` heading in a task-based module. It is distinct from the module abstract, which describes the goals of the user for the module.

Do not use a lead-in sentence in the `Prerequisites` or `Procedure` sections of a module unless it is necessary to aid navigation or add clarity.

The following examples demonstrate when a lead-in sentence might add value.

* Your module has a long list of prerequisites, and you want to group the prerequisites in sections to make it easier for users to understand what tasks must be performed to complete a procedure.
* Your module has a complex procedure or set of prerequisites, and you want to emphasize that all steps or prerequisites must be completed.

Use a complete sentence for the lead-in sentence to reduce ambiguity and support translation.

## Prerequisites

When writing prerequisites, be as clear and concise as possible. You can use the passive voice, _if necessary_, to achieve that end.

Write prerequisites as checks that are true or that the user must have completed before they begin a procedure. They can be actions that the user, another person, or piece of technology has completed. Prerequisites can also include items that the user must have ready before beginning the procedure.

* The passive voice might be appropriate for a prerequisite that is not completed by the current user. For example, having a configuration enabled by a system admin.
* Avoid using imperative formations.
* Use parallel language when you write prerequisites. For example, if one bullet is a complete sentence, write the other bullets as complete sentences. But one bullet can be passive voice and another active voice.

* JDK 11 or later is installed.

  Passive voice: the agent is unknown or unimportant.
* A running Kafka instance in {product}.

  Not a complete sentence: This prerequisite is acceptable if all the other prerequisites in your list are also not complete sentences.
* You are logged in to the Administration Portal.
* You have validated Thing 1.

* [_Procedure Prerequisites_ in the _Modular Documentation Reference Guide_](https://redhat-documentation.github.io/modular-docs/#creating-procedure-modules)

## Short descriptions

Every module and assembly must include a _short description_, formerly called an _abstract_. A short description provides a high-quality summary for both readers and AI-powered search tools.

* Short descriptions ***must*** be at least 50 characters and no more than 300 characters long.
* Place any information that exceeds 300 characters in a new paragraph or paragraphs. It cannot be part of the short description.

The short description must have the correct formatting and tagging:

* In AsciiDoc, label the short description with `[role="_abstract"]`.
* In DITA, tag the short description with `<shortdesc>`.

> **IMPORTANT:**

Do not start a module or assembly with an admonition, even when adding the Technology Preview admonition. Always provide a short description first.


### Placement of the short description in procedures

In procedures, the short description is displayed between the module title and the prerequisites section. Put additional information in a new paragraph or paragraphs.

In AsciiDoc, additional information is displayed ***before*** the prerequisites. The following image illustrates how to place this information:

![Place additional information before prerequisites](images/Structure-of-an-AsciiDoc-procedure.png)

In DITA, include the additional information ***after*** the prerequisites, as the following image illustrates. Be careful that this added text does not rely on the short description for context:

![Place additional information after prerequisites](images/Structure-of-a-DITA-procedure.png)

### Core principles for writing a helpful short description

Short descriptions help readers find the information that they need and confirm that they are in the right place. The following principles ensure that you are writing the best short description that you can:

* Include user intent. Explain **what** the user must do and **why** they must complete that action. Build upon the title--do not repeat it.
* Write for AI and search. High-quality short descriptions are a primary source of metadata for large language models (LLMs) and search engine link previews. A high quality, human-verified summary reduces the risk of AI misinterpretation and saves processing time.
* Do not use DITA-incompatible structures, such as bulleted lists or multiple paragraphs.

### Style guidelines

Be sure to follow Red Hat style guidelines. Pay particular attention to the following rules, because short descriptions frequently violate these standards:

* Use active voice and present tense. Write in plain English using simple, direct sentences.
* Use customer-centric language. Use phrases like "You can... by..." or "To..., configure...".
* Do not use self-referential language, for example, "This topic covers..." or "Use this procedure to...".
* Do not use feature-focused language. Focus on what users can accomplish rather than what the product does. Do not use "This product allows you to...".
* Make modules findable and reusable. Include the product name in either the title or the short description to make the module reusable.

### Short descriptions for complex procedures

If you are documenting two or more ways of completing the same procedure, use the short description to explain why users would want to choose one or the other. For complex procedures that have multiple sub-procedures, include some of the key tasks that a customer must complete.

### Example: Assembly

The original short description for this assembly example is self-referential and does not explain the **why**, although it does explain some of the **what**. The rewrite fixes both issues.

```
*Original:* Use one the following procedures to configure Satellite for the method that you have selected to deploy compliance policies. You will select one of these methods when you later create a compliance policy.
```

```
*Rewrite:* To choose the appropriate method for your infrastructure [*why*], review the compliance policy deployment options in Red Hat Satellite [*what*]. Understanding the Ansible method, Puppet method, and manual method helps you plan your deployment effectively [*why*].
```

### Example: Procedure (Task) topic

The original short description in this example is self-referential and does not contain much information. The rewrite leads with the benefit and explains what you can do after performing the task.

```
*Original:* Use this procedure to create an organization. To use the CLI instead of the Satellite web UI, see the CLI procedure.
```

```
*Rewrite:* Create organizations to divide resources among multiple teams [*why*]. Assign content and subscriptions to each organization or team, based on ownership, purpose, or security level [*what*].
```

### Example: Concept topic

A short description for a concept module briefly explains the **what** or **why** of a concept and helps readers decide if the topic is relevant to them. The following example does this by explaining the benefit of each migration method.

```
You can minimize virtual machine downtime by choosing an appropriate migration path for your workload. Warm migration runs in the background to keep applications active, but cold migration requires a full shutdown and is safer. Both methods provide similar transfer speeds.
```

### Example: Reference topic

A short description for a reference topic should provide a brief direct answer to the question, "What is this?"  The following example does this by describing the repository contents, which are listed in a table below the short description.

## Developer Preview

Developer Preview software provides early access to a technology, component, or feature in advance of its possible inclusion in a Red Hat product offering. Customers can use Developer Preview software to test functionality and provide feedback during the development process. Documentation is not required for Developer Preview software, but if documentation is provided, it is subject to change or removal at any time. Also, testing is limited for Developer Preview software. Red Hat might provide ways to submit feedback on Developer Preview software without an associated SLA.

> **WARNING:**

Some products, such as Red Hat Openshift Container Platform, do not include Developer Preview content in the documentation. Check with your Content Strategist or Support contact to confirm whether you can publish Developer Preview documentation for your product.


When documenting a Developer Preview software, follow these guidelines:

* Add an admonition labeled ***IMPORTANT*** at the beginning of the Developer Preview content and include the template text.
* Use initial uppercase capitalization, that is, Developer Preview.
* Never use the phrase "supported as a Developer Preview", and avoid using "support" in Developer Preview descriptions. Instead, use neutral words like "available", "provide", "capability", and so on.
* When the Developer Preview software becomes generally available, remove the IMPORTANT admonition from any document that includes content about the feature.

  > **NOTE:**

  You might need to replace the Developer Preview admonition with a Technology Preview admonition. For more information, see [Technology Preview](#technology-preview).


Use the following template. Replace _&lt;software_name>_ with the software name:

**Example AsciiDoc: Developer Preview admonition template**

```text
[IMPORTANT]
====
_<software_name>_ is Developer Preview software only. Developer Preview software is not supported by Red Hat in any way and is not functionally complete or production-ready. Do not use Developer Preview software for production or business-critical workloads. Developer Preview software provides early access to upcoming product software in advance of its possible inclusion in a Red Hat product offering. Customers can use this software to test functionality and provide feedback during the development process. This software might not have any documentation, is subject to change or removal at any time, and has received limited testing. Red Hat might provide ways to submit feedback on Developer Preview software without an associated SLA.

For more information about the support scope of Red Hat Developer Preview software, see link:https://access.redhat.com/support/offerings/devpreview/[Developer Preview Support Scope].
====
```

* NUMA-aware scheduling
* Node Health Check Operator
* CSI inline ephemeral volumes

For more information about the support scope of Red Hat Developer Preview features, see [Developer Preview Support Scope](https://access.redhat.com/support/offerings/devpreview/). For a comparison of Developer Preview and Technology Preview features, see [Developer and Technology Previews: How they compare](https://access.redhat.com/articles/6966848).

## Technology Preview

Technology Preview features provide early access to upcoming product innovations, enabling customers to test functionality and provide feedback during the development process. However, these features are not fully supported. Documentation for a Technology Preview feature might be incomplete or include only basic installation and configuration information.

When documenting a Technology Preview feature, follow these guidelines:

* Add an admonition labeled IMPORTANT at the beginning of the Technology Preview content and include the template text.
* Use initial uppercase capitalization, that is, Technology Preview.
* Include a brief description of the Technology Preview feature in the release notes.
* Maintain a list of features that are currently in Technology Preview status in the release notes.
* Never use the phrase "supported as a Technology Preview", and avoid using "support" in Technology Preview descriptions. Instead, use neutral words like "available", "provide", "capability", and so on.
* When the Technology Preview feature becomes generally available, remove the IMPORTANT admonition from the release notes and any other document that includes content about the feature.

Use the following template text verbatim, where _&lt;feature_name>_ is your feature name. If you are not referring to a specific feature, you can omit the first sentence of the template text:

**Example AsciiDoc: Technology Preview admonition template**

```text
[IMPORTANT]
====
_<feature_name>_ is a Technology Preview feature only. Technology Preview features are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using them in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.

For more information about the support scope of Red Hat Technology Preview features, see link:https://access.redhat.com/support/offerings/techpreview/[Technology Preview Features Support Scope].
====
```

* The Driver Toolkit
* SSPI connection support on Microsoft Windows
* Hot-plugging virtual disks

For more information about the support scope of Red Hat Technology Preview features, see [Technology Preview Features Support Scope](https://access.redhat.com/support/offerings/techpreview/). For a comparison of Developer Preview and Technology Preview features, see [Developer and Technology Previews: How they compare](https://access.redhat.com/articles/6966848).
