# Product Documentation Content Types (CQA Extract)

> **This is a condensed CQA-focused extract.** Full version: [content-types.md](content-types.md)

Modular, topic-based content that supports the use of a product, service, or technology. Product documentation is a release requirement and is carefully vetted by QE, SMEs, and other stakeholders.

Modular documentation is based on units of content called **modules**, which authors combine into organizational units called **assemblies**. A module is a self-contained unit of content that is based on one of three officially supported content types: **concept**, **task**, or **reference**. An assembly is a collection of several modules that the author creates to document a user story.

## Purpose

- Sets expectations of what the product, service, or technology can do
- Guides users through tasks: What do I need to do, why do I need to do it, and how do I do it?
- Enables informed decision making when evaluating the offering
- Helps users troubleshoot and recover from mistakes
- Provides a comprehensive, trustworthy reference source for information that users look up on demand

## Module Types

| Module Type | File prefix | Purpose | Title form |
|-------------|-------------|---------|------------|
| **Concept** | con-*.adoc | Explain what and why | Noun phrase |
| **Procedure** | proc-*.adoc | Step-by-step how-to instructions | Imperative verb |
| **Reference** | ref-*.adoc | Lookup data (commands, configurations, options) | Noun phrase |
| **Assembly** | assembly-*.adoc | Combine modules to address user stories | Imperative or noun phrase |
| **Snippet** | snip-*.adoc | Reusable content fragments (no structural elements) | N/A |

## Choosing the Right Module Type

| User Need | Module Type |
|-----------|-------------|
| Understand a concept | Concept module |
| Complete a task | Procedure module |
| Look up reference data | Reference module |
| Address a user story end-to-end | Assembly (combining modules) |

## Style Guide

IBM Style guide, Red Hat Supplementary Style guide
