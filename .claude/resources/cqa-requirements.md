# CQA 2.1 Pre-Migration Requirements

*Extracted from official CQA 2.1 Google Sheets*

---


## Asciidoc

### #1 - Content passes this Vale asciidoctor-dita-vale tool check wi...

**Requirement:** [Content passes this Vale asciidoctor-dita-vale tool check with no errors or warnings](https://github.com/jhradilek/asciidoctor-dita-vale)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** [The AsciiDocDITA tool identifies markup that does not have a direct equivalent in DITA 1.3. See the readme for details about specific issues that it finds. Note: The AsciiDocDITA tool is updated frequently.](https://github.com/jhradilek/asciidoctor-dita-vale)



### #2 - Assemblies should contain only an introductory section, whic...

**Requirement:** Assemblies should contain only an introductory section, which can be one or more paragraphs, and include statements. You can also have an Additional resources section at the end of the assembly, after all of the includes.DITA maps do not accept text between include statements for modules.

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** Note: Will be added to Vale check shortly.




## Modularization

### #3 - Content is modularized...

**Requirement:** [Content is modularized](https://redhat-documentation.github.io/modular-docs/)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data



### #4 - Modules use the official templates:- Concept- Procedure- Ref...

**Requirement:** [Modules use the official templates:- Concept- Procedure- Reference](https://github.com/redhat-documentation/modular-docs/tree/main/modular-docs-manual/files)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data



### #5 - All Required/non-negotiable modular elements are present...

**Requirement:** All Required/non-negotiable modular elements are present

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** [See (WIP) Modular documentation templates checklist](https://docs.google.com/document/d/13NAUVAby1y1qfT77QFIZrMBhi872e7IEvAC9MUpGXbQ/edit?tab=t.0)



### #6 - Assemblies use the official template.Assemblies are one user...

**Requirement:** [Assemblies use the official template.Assemblies are one user story.](https://redhat-documentation.github.io/modular-docs/#assembly-definition)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data



### #7 - Content is not deeply nested in the TOC (recommended: no mor...

**Requirement:** Content is not deeply nested in the TOC (recommended: no more than 3 levels)

**Quality Level:** Important/negotiable

**Current Assessment:** No data

**Notes:** Note: For migration, you can start counting levels where your content starts, not including categories and the repetitive book titles that Pantheon generates.



### #8 - Modules and assemblies start with a clear short description....

**Requirement:** Modules and assemblies start with a clear short description. A short description: - Describes why the user should read the content- Uses concise language that will be used as a link preview or for summaries in search results- Includes keywords that users are likey to search on for SEO and AI - Must not include self referential language ("This document describes...")

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** [See the following doc about shortdesc in DITA: https://docs.oasis-open.org/dita/dita/v1.3/errata02/os/complete/part3-all-inclusive/langRef/base/shortdesc.html](https://docs.oasis-open.org/dita/dita/v1.3/errata02/os/complete/part3-all-inclusive/langRef/base/shortdesc.html)



### #9 - In asciidoc, short descriptions must be:- be a single paragr...

**Requirement:** In asciidoc, short descriptions must be:- be a single paragraph between 50 and 300 characters - Introduced with [role="_abstract"] - Include a blank line between the level 0 (=) title and the short description in asciidoc

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** [Note: See Rewrite for Impact: DITA short descriptions](https://docs.google.com/presentation/d/1cl5PFL0SRV7M6GHBJOZ1jNMAtbVI_85iHKe5XWMV0ek/edit?slide=id.g37974b26b7e_0_2#slide=id.g37974b26b7e_0_2)



### #10 - Titles are brief, complete, and descriptive...

**Requirement:** Titles are brief, complete, and descriptive

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** [Use the following guidelines for titles:- Procedure modules in the Modular documentation reference guide- Peer review checklist for style in Red Hat peer review guide for technical documentation](https://ccs-internal-documentation.pages.redhat.com/peer-review/#_style)




## Procedures

### #11 - If a procedures includes prerequisites: - Use the Prerequisi...

**Requirement:** [If a procedures includes prerequisites: - Use the Prerequisites label- Use consistent formattingDo not exceed 10 prerequisites. Do not include steps in prerequisites.](https://redhat-documentation.github.io/modular-docs/#prerequisites)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data




## Editorial

### #12 - Content is grammatically correct and follows rules of Americ...

**Requirement:** Content is grammatically correct and follows rules of American English grammar

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data



### #13 - Information is conveyed using the correct content type...

**Requirement:** [Information is conveyed using the correct content type](https://source.redhat.com/groups/public/content_design_and_planning/content_types)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data




## URLs and links

### #14 - No broken links...

**Requirement:** No broken links

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data



### #15 - Redirects (if needed) are in place and work correctly...

**Requirement:** Redirects (if needed) are in place and work correctly

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data




## Legal and Branding

### #16 - Official product names are used...

**Requirement:** [Official product names are used](http://red.ht/opl)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data



### #17 - Includes appropriate, legal-approved disclaimers for Technol...

**Requirement:** [Includes appropriate, legal-approved disclaimers for Technology Preview and Developer Preview features/content](https://access.redhat.com/support/offerings/devpreview)

**Quality Level:** Required/non-negotiable

**Current Assessment:** No data

**Notes:** You can use snippets for these disclaimers in assembly files. They will resolve appropriately during migration.


