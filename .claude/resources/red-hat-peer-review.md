# Red Hat peer review guide for technical documentation

## Table of Contents

- [Introduction](#introduction)
  - [About this guide](#about-this-guide)
  - [Purpose of peer reviews](#purpose-of-peer-reviews)
- [Peer review checklists](#peer-review-checklists)
  - [Language](#language)
  - [Style](#style)
  - [Minimalism](#minimalism)
  - [Structure](#structure)
  - [Usability](#usability)
- [Providing peer review feedback](#providing-peer-review-feedback)
- [Creating a peer review process](#creating-a-peer-review-process)
  - [Considerations when creating a peer review process](#considerations-when-creating-a-peer-review-process)
  - [Finalizing your team's peer review process](#finalizing-your-teams-peer-review-process)
  - [Example peer review process 1](#example-peer-review-process-1)
  - [Example peer review process 2](#example-peer-review-process-2)
- [Appendix A: Pros and cons of the different peer review platforms](#appendix-a-pros-and-cons-of-the-different-peer-review-platforms)
- [Appendix B: Peer review resources](#appendix-b-peer-review-resources)

## Introduction

### About this guide

This guide provides information about best practices for peer reviewing Red Hat technical documentation.

The Red Hat Customer Content Services (CCS) team created this guide for customer-facing documentation, but upstream communities that want to align more closely with the standards used by Red Hat documentation can also use this guide.

### Purpose of peer reviews

It is recommended to perform a peer review on all updates to Red Hat documentation. Peer review provides the following benefits:

- Ensuring higher quality content, which helps our users
- Giving writers and reviewers a chance to see more content, find new ways to approach changes, and share expertise

For peer reviews to achieve these goals, reviewers should present their comments positively and avoid negative wording. At the same time, writers must be open to reviewers' feedback. Peer reviews can catch issues that writers might miss.

## Peer review checklists

Writers and peer reviewers can use the peer review checklists as a quick reference to the Red Hat technical documentation style guidelines. Use the checklists to help structure your peer reviews, and adapt the checklists to meet the needs of your team.

For guidance on each topic outlined in the checklists, see the following resources:

- IBM Style
- [Red Hat supplementary style guide for product documentation](https://redhat-documentation.github.io/supplementary-style-guide/)
- [Merriam-Webster Dictionary](https://www.merriam-webster.com/)

### Language

**Table 1. Language checklist**

| Check for | Checked |
|-----------|---------|
| **Spelling errors and typos**<br>- American English spelling is used consistently in the text.<br>- Correct punctuation is used in the text. | ☐ |
| **Grammar**<br>- American English grammar is used consistently in the text.<br>- Slang or non-English words are not used in the text. | ☐ |
| **Correct word usage and entity naming**<br>- Precise wording is used. Words are used in accordance with their dictionary definitions.<br>  - The writer has also considered the context of the words, so that the meaning, tone, and implications are appropriate.<br>- Named entities are classified on first use.<br>- Contractions are avoided, unless they are used intentionally for conversational style, such as in quick starts.<br>- Proper nouns are capitalized.<br>- Conscious language guidelines are followed. The terms *blacklist*, *whitelist*, *master*, and *slave* are used only when absolutely necessary. | ☐ |
| **Correct use of acronyms and abbreviations**<br>- Acronyms are expanded on first use.<br>- Abbreviations are used and applied correctly. | ☐ |
| **Terms and constructions**<br>- Phrasal verbs are avoided.<br>- Use of problematic terms such as *should* or *may* are avoided.<br>- Use of anthropomorphism is avoided. | ☐ |

### Style

**Table 2. Style checklist**

| Check for | Checked |
|-----------|---------|
| **Passive voice**<br>- Unnecessary use of passive voice is avoided. | ☐ |
| **Tense**<br>- Future tense is used only when necessary. | ☐ |
| **Titles**<br>- Titles use sentence case.<br>- Titles and headings have consistent styling.<br>- Titles are effective and descriptive.<br>- Titles focus on customer tasks instead of the product.<br>- Titles are 3-11 words long and have 50-80 characters.<br>- Titles of procedure modules begin with a gerund, for example, "Configuring", "Using", or "Installing". | ☐ |
| **Number**<br>- Number conventions are followed. | ☐ |
| **Formatting**<br>- Content follows style and consistency guidelines for formatting, for example, user-replaceable values.<br>- Content uses correct AsciiDoc markup. | ☐ |

### Minimalism

**Table 3. Minimalism checklist**

| Check for | Checked |
|-----------|---------|
| **Customer focus and action orientation**<br>- Content focuses on actions and customer tasks. | ☐ |
| **Scannability/Findability**<br>- Content is easy to scan.<br>- Information is easy to find.<br>- Content uses bulleted lists and tables to make information easier to digest. | ☐ |
| **Sentences**<br>- Sentences are not unnecessarily long and only use the required number of words. Ensure that any long sentences cannot be shortened.<br>- Sentences are concise and informative. | ☐ |
| **Conciseness (no fluff)**<br>- The text does not include unnecessary information.<br>- Admonitions are used only when necessary.<br>- Screenshots and diagrams are used only when necessary.<br>- Content is clear, concise, precise, and unambiguous. | ☐ |

### Structure

**Table 4. Structure checklist**

| Check for | Checked |
|-----------|---------|
| **Structure meets modular guidelines**<br>- Module types are not mixed, for example, concept and procedure information is separate.<br>- Module types are used correctly.<br>- Tags and entities are used correctly.<br>- Modules are as self-contained as possible to facilitate reuse in other locations. | ☐ |
| **A logical flow of information**<br>- Information is provided at the right pace.<br>- Information is presented in the most logical order and location.<br>- Cross-references are used appropriately and only when useful. | ☐ |
| **User stories**<br>- The user goal is clear.<br>- Tasks reflect the intended goal of the user.<br>- Troubleshooting and error recognition steps are included where appropriate. | ☐ |

### Usability

**Table 5. Usability checklist**

| Check for | Checked |
|-----------|---------|
| **Content**<br>- The content is appropriate for the intended audience. | ☐ |
| **Accessibility**<br>- Tables and diagrams have alternative (alt) text and are clearly labeled and explained in surrounding text. | ☐ |
| **Links**<br>- Use of inline links is minimized.<br>- All the links in the document work.<br>- All links are current. | ☐ |
| **Visual continuity**<br>- The content renders correctly in preview, including correct spacing, bulleted lists, and numbering.<br>- Product versioning and release dates are accurate. | ☐ |

## Providing peer review feedback

Peer reviews must be kind, helpful, and consistent among peer reviewers.

- **Support your comments.**
  - Use documented resources, such as style guides or Red Hat writing conventions.
  - Explain the impact of the issue on the audience.
  - If you cannot find documented support, rethink the need for the comment.

- **Use a respectful tone.**
  - Pose comments as questions when you are unsure.
  - Choose your wording carefully and do not be harsh. Be concise for easy content updates. If you have a suggestion, ask the writer to "consider" your comment or state that you "suggest" something.

- **Stay within scope**. Review only the new content, changed content, and content that provides necessary context.
  - Review content that was changed in the pull request (PR) or merge request (MR).
  - Review the preexisting section to ensure that the new or updated content fits.
  - Do not request enhancements to the content unless the content is unclear without it.
  - If you notice an issue in related content that you are not explicitly reviewing, use friendly wording to suggest changes. Some examples of appropriate language include:
    - "I know this was existing content, but would you mind fixing this typo while you're in there?"
    - "I know this is out of scope for this PR, but consider looking into this in a future update."

    The writer might either address the issue now, track it as a future request, or let the peer reviewer know that they cannot apply the change.
  - For more information about scope, see [Scope examples](#scope-examples).

- **Understand that peer reviewers do not review for technical accuracy.**
  - Subject matter experts (SMEs) and quality engineering (QE) associates are responsible for testing and technical accuracy.
  - Peer reviewers check for issues like usability problems, style guide compliance, and unclear or missing steps in a procedure.
  - Peer reviewers do not need to understand all the technical details. The audience might be users who are already familiar with the technology. Request additional technical information as a followup and not as a requirement for the current PR or MR.
  - Some peer reviewers might be more familiar with a particular subject or know that an update can affect another area of the documentation. In these cases, provide this feedback to the writer.
  - If you are certain that information is wrong or that a command will fail, ask the contributor to check with their SME or QE. Avoid tagging their SMEs or QEs directly to ask.

- **Recognize that writers do not have to accept all your suggestions.**
  - Writers must implement mandatory peer review feedback that relates to style guides or typographical errors, but they can implement optional feedback at their discretion. If the issue does not break any rules or is not an actual typographical error or issue, let writers keep it as it is.
  - If you are merging a PR or MR and feel strongly that the writer must make a change but they disagree, speak to the writer in private. Cite style guides or vetted documentation so that they know your reasoning. Listen to their perspective. If the topic of the disagreement is not in any of the guides, consider bringing it to the team for discussion. In some cases, the guidelines might need to be updated.

- **Differentiate between required and optional changes.**
  - Required changes must be fixed before the writer can merge the PR or MR. Support your change with a reference to the relevant style guide or principle. Examples include modular docs template adherence, typographical error fixes, or product-specific guidelines.
  - Optional changes do not have to be addressed before the writer can merge the PR or MR. Use softer language, for example, "Here, it might be clearer to…" or use a [SUGGESTION] tag to clearly indicate it to the writer. Examples: wording improvements, content relocation, and stylistic preference.
  - For more information about required versus suggested changes, see [Scope examples](#scope-examples).

- **Add your own suggestions for improvements** for a problematic area. Do not provide vague or generic comments, such as "this doesn't make sense."
  - Offer rewrites as suggestions, not something that the writer has to take word-for-word. For example, "I don't understand this description. Did you mean…?"
  - Avoid rewriting entire paragraphs of the writer's content. If you find yourself doing this because multiple items in a paragraph need attention, break out your suggestions. If providing an alternative paragraph wording is necessary, ensure that you make it clear that the writer does not need to use your suggestion exactly as written.
  - If you notice a recurring issue, leave a global comment for the writer so that they know to address every instance of the issue. For example, "[GLOBAL] This typo occurs in other locations within the doc. I won't comment on the other examples after this point, but please address all instances."

- **Provide positive feedback as well as negative**
  - If during your review you find a portion of content that you think is exceptionally well done, point that out in your feedback. For example, "This part is pretty much perfect, nicely done!"
  - This reinforces good writing habits and also makes getting reviews less daunting.

- **If the review requires a significant amount of editing or rework, pause the review and contact the writer directly to discuss.**
  - This avoids overwhelming the writer with too many comments and saves the peer reviewer's time.
  - If the content is not ready for peer review, tell the writer and continue after it is ready.
  - Examples of when to pause a review include if the build is broken, if the content is not rendering properly, or if the content is not modularized correctly.
  - Contact the writer privately, for example, by chat, to express your concerns and provide advice on how to move forward.
  - Decide whether you have the time to work with the writer or if you need to request that they contact someone else, for example, an onboarding buddy or a senior writer.

- **Notify the writer when the review is complete.**
  - After you finish the review, notify the writer that the review is complete, so that they can start reviewing and implementing your feedback.

### Scope examples

Some suggested changes might improve the content but are not relevant or in the scope of the updates. The following table includes examples of changes that are in scope and required, in scope but suggested, and out of scope.

**Table 6. Examples of in scope and out of scope feedback**

| In scope - required | In scope - suggested | Out of scope |
|---------------------|----------------------|--------------|
| Typographical errors, grammatical issues, formatting issues | Rearranging:<br>- Moving something to the prerequisites section<br>- Moving verification steps out of the ".Procedure" and into a specific ".Verification" section in the procedure module, if applicable | Comments on content that was not changed in the PR or MR |
| [Modular docs guidelines](https://redhat-documentation.github.io/modular-docs/), for example:<br>- Adhering to the templates<br>- Correct anchor ID format | Reviewing wording that does not sound right to the reviewer to see if it can be improved | Requesting additional details, like default values or units |
| IBM Style Guide and [CCS supplementary style guide](https://redhat-documentation.github.io/supplementary-style-guide/) guidelines, for example:<br>- "may" to "might"<br>- "Click the **Save** button." to "Click **Save**." | Avoiding sequences of admonitions, for example, a [NOTE] followed by an [IMPORTANT] block, especially if they are the same type of admonition | Technical accuracy, unless you know for certain something is wrong or that a command will fail |
| Product-specific guidelines, for example:<br>- Prompts on terminal commands<br>- Separating commands into individual code blocks<br>- Sentence case in titles | | |

## Creating a peer review process

Red Hat Customer Content Services (CCS) does not follow one definitive peer review process. Each team within CCS is different, with unique workflows, preferred tools, release cycles, and engineering team preferences that are customized to meet their product and customer requirements. Each team determines a peer review process that works for them.

Define a process so that peer reviews are used consistently throughout your team.

### Considerations when creating a peer review process

Before you establish a peer review process that works for your team, review the following factors:

- [Is a peer review required or optional?](#is-a-peer-review-required-or-optional)
- [Who are the peer reviewers?](#who-are-the-peer-reviewers)
- [How does a writer request a peer review?](#how-does-a-writer-request-a-peer-review)
- [How is the peer reviewer assigned?](#how-is-the-peer-reviewer-assigned)
- [What is the level or scope of the peer review?](#what-is-the-level-or-scope-of-the-peer-review)
- [Is there a checklist for the peer reviewer to follow?](#is-there-a-checklist-for-the-peer-reviewer-to-follow)
- [What platform and tools are used to perform the review and give feedback?](#what-platform-and-tools-are-used-to-perform-the-review-and-give-feedback)
- [What is the expected turnaround time?](#what-is-the-expected-turnaround-time)
- [How are urgent peer reviews escalated?](#how-are-urgent-peer-reviews-escalated)
- [How is peer review feedback incorporated?](#how-is-peer-review-feedback-incorporated)

#### Is a peer review required or optional?

A technical writing manager, documentation program manager (DPM), or content strategist (CS) determines whether requesting a peer review is required or optional and communicates this expectation to the team.

**Example options**

- Require a peer review on each GitHub PR (or GitLab MR) prior to accepting the request.
- Require a peer review in certain, defined situations.
- Request a peer review at the writer's discretion.

#### Who are the peer reviewers?

Determine who conducts a peer review. A manager, DPM, or CS communicates this expectation to the team.

**Example options**

- Individuals can volunteer as peer reviewers.
- Everyone on the team is expected to be available to review at any time.
- Everyone participates in peer reviews and rotates being available or follows a roster.

#### How does a writer request a peer review?

Determine how writers request a peer review.

**Example options**

- Add the request details to a tracking spreadsheet.
- Communicate with a reviewer in a Google Chat or a Slack channel.
- Request a review through email.
- Use GitHub or GitLab labels to mark when content is ready for review.
- Open a Jira ticket or Bugzilla ticket with the request.
- Contact a reviewer in the original documentation ticket.

#### How is the peer reviewer assigned?

Some assignment methods might work better if the reviewers are on the same product team; others might work better for cross-product reviews. Establish a method that suits the structure and dynamic of the group of writers and reviewers that the process targets.

Writers must ensure that reviewers can access the tools needed to complete the review.

**Example options**

- Reviewers check a tracking spreadsheet and assign themselves.
- Reviewers are notified for all peer review requests and assign themselves.
- Reviewers regularly check a GitHub PR or a GitLab MR queue and assign themselves.
- A writer contacts the reviewer.

#### What is the level or scope of the peer review?

Determine the level or scope of the peer review, so that the writer and reviewer have the same expectations.

> **Note:** The writer is responsible for informing the peer reviewer of any essential information related to the content.

**Example options**

- Perform a general review that checks for typographical errors, style guide compliance, and link checking.
- Perform a deeper review of the content that includes checks on typographical errors and grammar, content placement or flow, structure, style guide compliance, and consistency.

#### Is there a checklist for the peer reviewer to follow?

Determine which checklists and other resources the reviewer should follow.

> **Note:** The writer must inform the peer reviewer of any essential information related to the content.

**Example options**

- Follow the CCS peer review checklist.
- Follow the CCS peer review checklist and a team-specific checklist.

#### What platform and tools are used to perform the review and give feedback?

Determine how to share content and provide feedback.

**Example options**

- Draft content in a Google Doc and use the document for comments and suggestions.
- Share a GitHub PR or GitLab MR. Reviewers can comment directly inline for each change.
- Provide small snippets of content by email, instant messaging, or a ticket.

For more information, see [Appendix A: Pros and cons of the different peer review platforms](#appendix-a-pros-and-cons-of-the-different-peer-review-platforms).

#### What is the expected turnaround time?

Determine the expected turnaround time for completing a peer review. Writers should communicate if there is any urgency or deadlines for the review.

**Example options**

- Reviewers check the GitHub or GitLab queue daily or twice daily.
- Reviewers respond to a Slack or a Google Chat ping within a few hours.
- Reviewers check a tracking spreadsheet daily.
- Writers communicate the requested turnaround time after requesting the peer review.

#### How are urgent peer reviews escalated?

Determine how an unassigned peer review request is escalated if it can affect product release schedules.

**Example options**

- Inform a manager, DPM, or CS of the unassigned time-critical peer review so that they can escalate the peer review request or negotiate a new timeline for reviewing the content.
- Use your peer review request channel to request an urgent peer review. Ensure you detail the tight timelines in the channel.

#### How is peer review feedback incorporated?

Determine the expectations for addressing or incorporating feedback. Expectations become important if the writer and peer reviewer disagree on a review item.

Incorporate an escalation process into your peer review process, such as communicating in a guidelines group or requesting manager, DPM, or CS input. This way, the writer and peer reviewer can resolve any disagreement.

**Example options**

- Incorporate feedback at the writer's discretion.
- Establish a communication channel for informing the peer reviewer of the next steps.
- Address peer review feedback and request the peer reviewer to perform a review of the revised content.

### Finalizing your team's peer review process

Writers and peer reviewers must agree on the expectations for the peer review process.

Complete the following steps to finalize the peer review process:

1. Draft a proposal for the peer review process.
2. Share the proposal with the team and set a time for the team to provide feedback.
3. Test the process to ensure that it works well for your team.
4. Document the final process wherever your team stores its resources.
5. Communicate the final process to the team and any other contributors or stakeholders.

### Example peer review process 1

The first example peer review process demonstrates how a cross-product team uses Jira tickets for communication and GitLab to perform peer reviews.

This team has a peer review squad of at least two members at any specific time. Membership of the squad rotates every week. The team maintains a peer review assignment roster in a Confluence page that lists the assigned reviewers for each week. The assignment roster is published in the Jira product dashboards, so that writers can see the assigned reviewers for the current week.

![A flowchart that is a visual representation of the first example peer review process described in the following procedure](images/example_peer_review_process1_image.png)

**Figure 1. Example 1 of a peer review process conducted through Jira and GitLab**

**Prerequisites**

- A subject matter expert (SME) has completed a technical review.

  To request and mark a technical review as complete, the writer performs the following tasks:

  a. Put a link to the MR in the **Git Pull Request** field in the Jira doc ticket.
  b. Submit the MR for SME review.
  c. Apply the SME reviewer's feedback.
  d. Update the MR in GitLab.

**Procedure**

1. To request a peer review, the writer performs the following tasks:

   a. Check the peer review assignment roster in the Jira product dashboard.
   b. Add a comment in the Jira doc ticket to contact the assigned reviewers.

   > **Note:** The writer needs to contact the reviewers who are currently on duty according to the roster.

   c. Add the assigned reviewers to the **Includes** field in the Jira doc ticket.
   d. Optional: Contact the assigned reviewers in the MR or chat.

2. If a peer review does not start within the expected timeframe and the review deadline is jeopardized, the writer performs the following task:

   - Contact the assigned reviewers again to communicate the urgency of the request.

   > **Note:** If the review deadline is not jeopardized, the writer does not need to take any action at this point.

3. To complete a review, the peer reviewer performs the following tasks:

   a. Notify the other assigned reviewer that you will do the review.
   b. Remove the other assigned reviewer from the **Includes** field in the Jira doc ticket.
   c. Add review comments in the MR.
   d. Notify the writer when you complete the review.

4. To apply feedback and complete the process, the writer performs the following tasks:

   a. Apply the peer reviewer's feedback.
   b. Update the MR in GitLab.

### Example peer review process 2

The second example peer review process demonstrates how a team uses a Slack channel for communication and GitHub to perform peer reviews. The peer review team consists of five team members at a given time. Membership of the peer review team rotates every sprint.

![A flowchart that is a visual representation of the second example peer review process described in the following procedure.](images/example_peer_review_process2_image.png)

**Figure 2. Example 2 of a peer review process conducted through Slack and GitHub**

**Procedure**

1. To request a peer review, the writer performs the following tasks:

   a. Notify the peer review squad using the Slack channel.
   b. Include a link to the PR in the Slack notification.
   c. Specify any deadline or other special considerations in the Slack notification.

2. If a peer review does not start within the expected timeframe and the review deadline is jeopardized, the writer performs the following task:

   - Contact the assigned reviewer or the peer review squad again to communicate the urgency of the request.

   > **Note:** If the review deadline is not jeopardized, the writer does not need to take any action at this point.

3. To complete a review, the peer reviewer performs the following tasks:

   a. Mark the request in Slack to indicate that you will perform the review.
   b. Add review comments in the PR.
   c. Notify the writer when you complete the review.

4. To apply feedback and complete the process, the writer performs the following tasks:

   a. Apply the peer reviewer's feedback.
   b. Update the PR in GitHub.

## Appendix A: Pros and cons of the different peer review platforms

Review the following pros and cons for each platform to choose the right peer review method for your team.

### GitHub or GitLab

**Pros**

- Provides a convenient method for commenting on specific lines of content on a GitHub PR or GitLab MR
- Includes functionality for easily adding additional reviewers
- Includes a mechanism for multiple people to collaborate on the same PR or MR
- Provides an easy linking functionality
- Offers the capability for writers to incorporate feedback before the PR or MR is approved

**Cons**

- Requires that you are familiar with the GitHub or GitLab UI
- Requires that you have login credentials to comment on a PR or MR

### Google Docs

**Pros**

- Includes a convenient method for commenting on specific text
- Includes functionality for easily adding additional reviewers
- Includes a mechanism for multiple people to collaborate on the same Google Doc
- Provides an easy linking functionality
- Supports copying and pasting of AsciiDoc syntax

**Cons**

- Can produce unreliable formatting when copying and pasting HTML, PDF, or markup syntax content
- Can be time consuming to copy and paste AsciiDoc content

### Email

**Pros**

- An easy tool for anyone to use
- A historical record of the discussion

**Cons**

- Can be difficult to link specific email comments to other communication channels
- Can be slow and time consuming
- Can be difficult to understand feedback if the content is not well structured

### IRC, Google Chat, or Slack

**Pros**

- Provides fast communication
- Can send instant notifications to online participants
- Provides an opportunity for immediate discussion

**Cons**

- Requires online access
- Limits message length

### Jira or Bugzilla ticket

**Pros**

- Supports collaboration and approval among multiple reviewers before any change is made
- Sends comments to all followers of the ticket

**Cons**

- Difficulty editing submitted comments
- Not easy to provide inline comments on the ticket
- Unwanted notification emails when there are multiple followers
- Tedious to discuss lengthy content on a ticket
- Limited space to add comments

## Appendix B: Peer review resources

This section lists additional tools and resources available for peer reviewing documentation.

**Table 7. Validation tools**

| Resource | Description |
|----------|-------------|
| [newdoc](https://github.com/redhat-documentation/newdoc) | A script for creating new files for a modular documentation repository. You can also use the script to [validate](https://github.com/redhat-documentation/newdoc#validating-a-file-for-red-hat-requirements) whether a piece of content adheres to Red Hat documentation markup and structure standards. |
| [Vale for Red Hat documentation writers](https://redhat-documentation.github.io/vale-at-red-hat/docs/main/user-guide/introduction/) | A linting system that validates whether your text is compatible with Red Hat writing style. |
| [IBM Equal Access Accessibility Checker](https://www.ibm.com/able/toolkit/verify/) | A toolkit of instructions and [browser extensions](https://www.ibm.com/able/toolkit/verify/automated) to generate automated accessibility reports. |
| [lychee](https://github.com/lycheeverse/lychee) | A fast link checker that validates whether the links in your HTML work. |
| [Grammarly](https://www.grammarly.com/) | A browser plug-in that checks your English spelling and grammar, but also helps improve your writing style. |

**Table 8. Style resources**

| Resource | Description |
|----------|-------------|
| IBM Style Guide | The governing guide for IBM writing style, which most Red Hat documentation follows. |
| [Red Hat supplementary style guide for product documentation](https://redhat-documentation.github.io/supplementary-style-guide/) | A guide for writing documentation the Red Hat way, including style guidelines, formatting, and a glossary of terms and conventions. Complementary to the IBM Style Guide. |
| [The Wisdom of Crowds slides](https://docs.google.com/presentation/d/1Yeql9FrRBgKU-QlRU-nblPJ9pfZKgoKcU8SW6SQ_UqI/edit#slide=id.g1f4790d380_2_176) | A slide deck on Red Hat community outreach, including the principles of minimalism in writing documentation. |

**Table 9. Markup resources**

| Resource | Description |
|----------|-------------|
| [AsciiDoc Mark-up Quick Reference for Red Hat Documentation](https://redhat-documentation.github.io/asciidoc-markup-conventions/) | Guidelines on using the AsciiDoc markup language in Red Hat documentation projects. |

**Table 10. Structure resources**

| Resource | Description |
|----------|-------------|
| [Modular Documentation Reference Guide](https://redhat-documentation.github.io/modular-docs/) | Instructions for creating Red Hat documentation in a modular way, with templates and examples. |
| [How Chunking Helps Content Processing](https://www.nngroup.com/articles/chunking/) | Tips for structuring your docs content in a visually comprehensible way. |
| [Starting a modular documentation Project in Antora](https://antora-for-modular-docs.github.io/antora-for-modular-docs/docs/user-guide/introduction/) | How to use the Antora toolchain to create a community documentation project. |

**Table 11. Methodology resources**

| Resource | Description |
|----------|-------------|
| [Red Hat Community Collaboration Guide](https://redhat-documentation.github.io/community-collaboration-guide/) | Tips and best practices for Red Hat and the upstream community joining forces on documentation projects. |
| [How to edit other people's content without pissing them off](https://www.youtube.com/watch?v=7iWUSetbaos) | Ingrid Towey's talk on conducting peer reviews that inform and inspire but do not infuriate. |

---

*Last updated 2023-06-19 13:04:47 UTC*
