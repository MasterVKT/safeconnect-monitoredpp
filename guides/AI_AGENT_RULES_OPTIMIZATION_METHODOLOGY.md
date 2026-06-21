# AI Agent Rules Optimization Methodology

**Version**: 2.4 (Universal Edition - Existing Rules Detection)
**Date**: January 2026
**Project**: XP Trading (Reference Implementation)
**Reusable**: Yes - Apply to any multi-agent AI project (Frontend, Backend, or Full-Stack)
**Automation**: 100% AI Agent Executable

---

## 📝 Version History

### Version 2.4 (Current) - Universal Edition - Existing Rules Detection
**Date**: January 23, 2026

**Major Changes**:
- ✅ **Added Step 0: Check for Existing Rules**: MANDATORY first step before any action
- ✅ **Decision Tree for Existing Rules**: 4 options (Optimize, Synchronize, Start from scratch, Add Gemini)
- ✅ **Smart Context Awareness**: AI agents now check what already exists before asking user
- ✅ **Improved User Experience**: Only asks necessary questions based on current state
- ✅ **Updated Automated Execution Steps**: Now starts with Step 0 (silent check)

**Impact**: Methodology now intelligently handles projects with existing rules, avoiding redundant questions and respecting existing work.

**Critical Addition**:
```
Step 0: IF rules exist → Analyze → Offer optimization paths
        ELSE → Proceed to create from scratch
```

**Use Cases Covered**:
1. Project with CLAUDE.md only → Offer synchronization to other agents
2. Project with all agents but large files → Offer optimization
3. Project with 3 agents, missing Gemini → Offer Gemini addition
4. Project with no rules → Create from scratch

### Version 2.3 - Universal Edition - Gemini Support
**Date**: January 23, 2026

**Major Changes**:
- ✅ **Added Google Gemini Code Assist Support**: Fourth AI agent integrated into methodology
- ✅ **Gemini Configuration Method**: Added VS Code Settings UI-based rules configuration
- ✅ **Created .gemini/styleguide.md**: XP Trading rules file for Gemini
- ✅ **Updated Documentation**: All sections now reference four agents (Claude Code, Cursor, GitHub Copilot, Gemini)
- ✅ **Official Paths Verified**: Confirmed Gemini uses `~/.gemini/settings.json` and `.gemini/styleguide.md`

**Impact**: Methodology now supports all major AI coding assistants in VS Code ecosystem (4 agents total).

**Files Added**:
- `.gemini/styleguide.md` - Gemini rules for XP Trading (synchronized with other agents)

**Documentation Updated**: Official File Locations section, Summary Table, Verification Commands, automation scripts.

### Version 2.2 - Universal Edition - Zero Redundancy
**Date**: January 23, 2026

**Major Changes**:
- ✅ **Eliminated Cross-Agent References**: Removed all references to `CLAUDE.md` from Cursor and GitHub Copilot files
- ✅ **Zero Redundancy Architecture**: Each agent's rules are now completely isolated with no cross-references
- ✅ **Token Waste Prevention**: Eliminated risk of agents reading other agents' rules files
- ✅ **Maintained Documentation Quality**: Kept all essential documentation references within each agent's scope

**Impact**: Guarantees zero token waste from cross-agent file access. Each agent reads only its own rules.

**Files Modified**:
- `.cursor/rules/apptradingfrontrules.mdc` - Removed `CLAUDE.md` reference (line 204)
- `.github/copilot-instructions.md` - Removed `CLAUDE.md` reference (line 282)

**Verification**: All cross-references eliminated, no agent can accidentally read another agent's rules.

### Version 2.1 - Universal Edition
**Date**: January 23, 2026

**Major Changes**:
- ✅ Added **Project Type Detection** (Frontend, Backend, Full-Stack)
- ✅ Added **Backend-Specific Critical Rules** section (6 backend rules)
- ✅ Added **Server-Side Code Examples** (API endpoints, middleware, validation)
- ✅ Renamed "Backend Issue Documentation Rule" → "Integration Issue Documentation Rule"
- ✅ Added **Language-Specific Backend Adaptations** (Express, FastAPI, Spring Boot, Gin)
- ✅ Enhanced methodology to work seamlessly with backend-only projects
- ✅ Maintained full compatibility with frontend and full-stack projects

**Impact**: Methodology now truly universal - works for ANY project type without modification.

### Version 2.0 - Fully Automated Edition
**Date**: January 23, 2026

**Major Changes**:
- ✅ Added "FOR AI AGENTS: Automated Implementation" section (complete automation guide)
- ✅ Added "Official File Locations" section with verified paths from official docs:
  - [Claude Code Settings](https://code.claude.com/docs/en/settings)
  - [Cursor Rules Docs](https://docs.cursor.com/context/rules)
  - [GitHub Copilot Instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- ✅ Transformed Appendix E to "AI Agent Automated Implementation Guide"
- ✅ Removed all manual steps - 100% executable by AI agents
- ✅ Added language-specific adaptation algorithms (JavaScript, Python, Go, Rust)
- ✅ Added automatic verification and reporting
- ✅ Added error handling during automation

**Benefits**:
- Developer only provides project info once
- AI agent does ALL work automatically
- No manual file editing required
- Works for any tech stack (React, Vue, Python, Go, etc.)

### Version 1.0 - Initial Release
**Date**: January 23, 2026

**Features**:
- Complete 4-step methodology
- XP Trading reference implementation
- Manual adaptation guide
- Verification procedures
- Maintenance guidelines

---

## 📋 Table of Contents

1. [**FOR AI AGENTS: Automated Implementation**](#for-ai-agents-automated-implementation) ⭐
2. [Official File Locations](#official-file-locations)
3. [Problem Statement](#problem-statement)
4. [Methodology Overview](#methodology-overview)
5. [Step 1: Create Comprehensive Base Rules](#step-1-create-comprehensive-base-rules)
6. [Step 2: Synchronize Rules Across Agents](#step-2-synchronize-rules-across-agents)
7. [Step 3: Optimize for Token Efficiency](#step-3-optimize-for-token-efficiency)
8. [Step 4: Apply Optimization to All Agents](#step-4-apply-optimization-to-all-agents)
9. [Verification & Validation](#verification--validation)
10. [Maintenance & Updates](#maintenance--updates)
11. [Appendices](#appendices)

---

## FOR AI AGENTS: Automated Implementation

**⚠️ CRITICAL: If you are an AI agent reading this file to implement rules optimization for a project, START HERE.**

### Your Mission

You will **automatically** create optimized, synchronized AI agent rules for a project using this methodology. **No human intervention required** beyond providing project-specific information.

### Step 0: Check for Existing Rules (MANDATORY FIRST STEP)

**CRITICAL**: Before asking the user for any information, you MUST first check if AI agent rules already exist in the project.

**Actions to Execute Automatically**:

```bash
# Check for existing rules files
ls -la CLAUDE.md 2>/dev/null
ls -la .claude/rules/ 2>/dev/null
ls -la .cursor/rules/*.mdc 2>/dev/null
ls -la .cursor/rules/detailed/ 2>/dev/null
ls -la .github/copilot-instructions.md 2>/dev/null
ls -la .github/copilot-rules/ 2>/dev/null
ls -la .gemini/styleguide.md 2>/dev/null
ls -la .gemini/rules/ 2>/dev/null
```

**Decision Tree**:

```
IF rules files exist (any of CLAUDE.md, .cursor/rules/*.mdc, .github/copilot-instructions.md, .gemini/styleguide.md)
  THEN
    1. Read all existing rules files
    2. Analyze their content (line counts, critical rules, structure)
    3. Ask user: "I found existing AI agent rules in this project. What would you like to do?"
       - Option A: "Optimize existing rules" (apply Step 3 & 4 of methodology)
       - Option B: "Synchronize rules across all agents" (some agents have rules, others don't)
       - Option C: "Start from scratch" (delete existing and recreate)
       - Option D: "Add Gemini support to existing setup" (if Gemini missing)
    4. Based on user choice, proceed accordingly

ELSE (no rules files exist)
  THEN
    → Proceed to "Prerequisites You Need from User" section below
```

**Example Scenarios**:

**Scenario 1**: Project has CLAUDE.md (400 lines) but no Cursor/Copilot/Gemini rules
- **Action**: Offer Option B (Synchronize) - replicate CLAUDE.md to other agents

**Scenario 2**: Project has all 4 agent rules but files are large (>500 lines each)
- **Action**: Offer Option A (Optimize) - apply token efficiency optimization

**Scenario 3**: Project has CLAUDE.md, Cursor, Copilot rules, but no Gemini
- **Action**: Offer Option D (Add Gemini) - create .gemini/styleguide.md from existing

**Scenario 4**: No rules files exist
- **Action**: Proceed to create from scratch using Prerequisites section

### Prerequisites You Need from User

**Only ask these questions if no existing rules were found, or if user chose "Start from scratch":**

Before starting, collect these details from the user:

1. **Project Name**: (e.g., "MyApp")
2. **Project Type**: Frontend, Backend, or Full-Stack
3. **Technology Stack**: (e.g., "React + Node.js + PostgreSQL")
4. **Development Platform**: (e.g., "macOS", "Windows", "Linux")
5. **Critical Rules** (6-8 rules): Project-specific non-negotiable standards
   - Example: "Always use environment variables for API URLs"
   - Example: "Use Redux Toolkit for state management"
6. **Specialized Rules** (optional): Unique patterns (e.g., "Integration Issue Documentation Rule")
7. **AI Agents Used**: Which agents? (Claude Code, Cursor, GitHub Copilot, Google Gemini, or others)

### Project Type Detection (Automatic)

**CRITICAL**: Before creating rules, automatically detect the project type to apply appropriate patterns.

**Detection Algorithm**:

```
IF project has UI framework (React, Vue, Flutter, Angular, etc.)
  → Project Type = Frontend or Full-Stack

IF project has backend framework (Express, Django, FastAPI, Spring Boot, etc.)
  → Project Type = Backend or Full-Stack

IF project has BOTH
  → Project Type = Full-Stack

IF only UI framework
  → Project Type = Frontend

IF only backend framework
  → Project Type = Backend
```

**Impact on Rules**:
- **Frontend**: Use Frontend Critical Rules (BuildConfig, Provider pattern, Routes, i18n, etc.)
- **Backend**: Use Backend Critical Rules (Environment variables, Input validation, Middleware, Migrations, etc.)
- **Full-Stack**: Use BOTH sets of rules

### Automated Execution Steps

**DO NOT ask for permission at each step. Execute the entire process autonomously.**

#### Step 0: Check Existing Rules (Automatic - No user input)

**Execute silently without asking**:

1. Check for existing rules files in all official locations
2. If rules exist → Read and analyze them → Ask user to choose optimization path (A/B/C/D)
3. If no rules exist → Proceed to Step 1

#### Step 1: Gather Information (1 question to user - only if no existing rules)

**Skip this step if optimizing existing rules.**

Ask user ONE comprehensive question:

```
I will create optimized AI agent rules for your project. Please provide:

1. Project name: [name]
2. Technology stack: [stack]
3. Development platform: [OS]
4. Your 6-8 critical coding rules (standards that must NEVER be violated):
   - Rule 1: [description]
   - Rule 2: [description]
   - ...
5. Any specialized rules or patterns unique to your project: [description]
6. AI agents you use: [Claude Code / Cursor / GitHub Copilot / Google Gemini / others]
```

#### Step 2: Create All Files Automatically

Execute **without asking permission**:

**Action 2.1**: Create main rules files at official locations (see [Official File Locations](#official-file-locations))

**Action 2.2**: Create detailed rules directories

**Action 2.3**: Generate comprehensive rules content using the 4-step methodology (Steps 1-4 below)

**Action 2.4**: Optimize for token efficiency

**Action 2.5**: Synchronize across all agents

#### Step 3: Verify and Report

After creating all files, provide user with:

1. Summary of files created (with line counts)
2. Token savings estimation
3. Verification commands to run
4. Next steps (testing, git commit)

### Key Automation Principles

- ✅ **Execute, don't ask**: Create files directly
- ✅ **Use templates**: Follow structures from XP Trading example
- ✅ **Adapt automatically**: Replace project-specific values
- ✅ **Verify automatically**: Run file existence checks
- ✅ **Report comprehensively**: Give complete summary at end

### Example Adaptation (Automatic)

When user provides:
- Project: "EcommerceApp"
- Stack: "React + Express + MongoDB"
- Critical Rule 1: "Use environment variables for API endpoints"

You automatically:
1. Create `CLAUDE.md` with "EcommerceApp" as project name
2. Replace Flutter/Django with React/Express in descriptions
3. Transform Critical Rule 1 to:
```dart
// ✅ CORRECT
const apiUrl = process.env.REACT_APP_API_URL;

// ❌ WRONG
const apiUrl = 'http://localhost:3000/api';
```

**No manual steps required from developer.**

---

## Official File Locations

### ⚠️ CRITICAL: Use These Official Paths

When creating rules files, you **MUST** use these official locations as defined by each AI agent's creators:

#### Claude Code

**Official Documentation**: [Claude Code Settings](https://code.claude.com/docs/en/settings) | [Complete CLAUDE.md Guide](https://www.builder.io/blog/claude-md-guide)

**Main Rules File**:
- **Location**: `CLAUDE.md` at project root
- **Format**: Markdown
- **Auto-loaded**: Yes, at conversation start
- **Import Support**: Yes, using `@path/to/file.md` syntax
- **Max Import Nesting**: 5 levels

**Detailed Rules Directory** (conventional, not official):
- **Location**: `.claude/rules/`
- **Purpose**: Store detailed rules files for on-demand loading
- **Import Syntax**: `@.claude/rules/filename.md`

**Alternative Locations** (optional):
- `CLAUDE.local.md` - Personal preferences (gitignored)
- `~/.claude/CLAUDE.md` - Global rules for all projects
- Parent directories - For monorepo setups
- Child directories - Loaded on-demand when working in subdirectories

#### Cursor

**Official Documentation**: [Cursor Rules Docs](https://docs.cursor.com/context/rules) | [Rules for AI](https://cursor.com/docs/context/rules)

**Main Rules File**:
- **Location**: `.cursor/rules/*.mdc` (MDC files in `.cursor/rules/` directory)
- **Format**: MDC (Markdown with YAML frontmatter)
- **Auto-loaded**: Based on `alwaysApply: true` in frontmatter
- **Import Support**: No native import, but can reference other files

**YAML Frontmatter** (required):
```yaml
---
description: ProjectName - AI Agent Rules
globs:
alwaysApply: true
---
```

**Detailed Rules Directory** (conventional):
- **Location**: `.cursor/rules/detailed/`
- **Purpose**: Store detailed guidance files
- **Reference**: Via path mentions in main file (informational)

**Legacy Support**:
- `.cursorrules` file at project root (deprecated but still works)

#### GitHub Copilot

**Official Documentation**: [Adding Custom Instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) | [GitHub Blog](https://github.blog/ai-and-ml/unlocking-the-full-power-of-copilot-code-review-master-your-instructions-files/)

**Main Rules File**:
- **Location**: `.github/copilot-instructions.md` at project root
- **Format**: Markdown (natural language)
- **Auto-loaded**: Yes, attached to all Copilot Chat requests
- **Import Support**: No

**Path-Specific Instructions** (optional):
- **Location**: `.github/instructions/**/*.instructions.md`
- **Purpose**: Instructions for specific file types (e.g., unit tests, React components)
- **Format**: Same as main file

**Detailed Rules Directory** (conventional):
- **Location**: `.github/copilot-rules/`
- **Purpose**: Store detailed guidance files (informational references)

**Platform Support**: Works in VS Code, Visual Studio, GitHub.com

#### Google Gemini Code Assist

**Official Documentation**: [Code with Gemini](https://cloud.google.com/gemini/docs/codeassist/write-code-gemini) | [Set up Gemini](https://developers.google.com/gemini-code-assist/docs/set-up-gemini)

**Configuration Method**:
- **Settings UI**: Access via Control+I (Windows/Linux) or Command+I (macOS) → Gemini icon → Preferences → "Geminicodeassist: Rules"
- **Settings File**: `~/.gemini/settings.json` (for MCP server configuration and global settings)
- **Style Guide File**: `.gemini/styleguide.md` at project root
- **Import Support**: No

**How Rules Work**:
- Rules configured via VS Code Settings UI are included in every chat prompt automatically
- Can set IDE-level (private, in `~/.gemini/settings.json`) or project-level (shared, in `.gemini/styleguide.md`)
- Style guide file uses standard Markdown format (no special frontmatter)
- Rules are NOT imported on-demand; entire style guide is loaded per request

**Best Practices**:
- Keep `.gemini/styleguide.md` concise (<500 lines recommended)
- Use same structure as other agents for consistency
- Include 6 Critical Rules with code examples
- Reference detailed files for additional context (informational only, manual access)

**Detailed Rules Directory** (conventional):
- **Location**: `.gemini/rules/`
- **Purpose**: Store detailed guidance files (informational references, not auto-loaded)

**Platform Support**: VS Code with Gemini extension

### Summary Table

| Agent | Main File | Detailed Dir | Import Support | Official Docs |
|-------|-----------|--------------|----------------|---------------|
| **Claude Code** | `CLAUDE.md` (root) | `.claude/rules/` | ✅ Yes (`@path`) | [Docs](https://code.claude.com/docs/en/settings) |
| **Cursor** | `.cursor/rules/*.mdc` | `.cursor/rules/detailed/` | ❌ No (reference only) | [Docs](https://docs.cursor.com/context/rules) |
| **GitHub Copilot** | `.github/copilot-instructions.md` | `.github/copilot-rules/` | ❌ No | [Docs](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) |
| **Google Gemini** | `.gemini/styleguide.md` | `.gemini/rules/` | ❌ No | [Docs](https://cloud.google.com/gemini/docs/codeassist/write-code-gemini) |

### Verification Commands

Check if files exist at official locations:

```bash
# Claude Code
ls -la CLAUDE.md
ls -la .claude/rules/

# Cursor
ls -la .cursor/rules/*.mdc
ls -la .cursor/rules/detailed/

# GitHub Copilot
ls -la .github/copilot-instructions.md
ls -la .github/copilot-rules/

# Google Gemini
ls -la .gemini/styleguide.md
ls -la .gemini/rules/
```

---

## How This Methodology Adapts to Your Project Type

**UNIVERSAL COMPATIBILITY**: This methodology works seamlessly for Frontend, Backend, and Full-Stack projects.

### Frontend Projects (React, Vue, Flutter, Angular, etc.)

**Critical Rules Focus**:
- Environment configuration (BuildConfig, API URLs)
- State management patterns (Provider, Redux, Vuex)
- Navigation (Routes, routing)
- Internationalization (i18n)
- Authentication (Bearer tokens in requests)
- Error handling

**Integration Issue Rule**: "Backend Issue Documentation Rule" - Documents issues when calling backend APIs

**Code Examples**: HTTP client code, UI components, state management

---

### Backend Projects (Express, Django, FastAPI, Spring Boot, etc.)

**Critical Rules Focus**:
- Environment variables (database credentials, secrets)
- Input validation at API boundaries
- Authentication middleware
- Database migrations
- Error logging with context
- Rate limiting

**Integration Issue Rule**: Adaptable based on integrations:
- "Frontend/Client Issue Documentation Rule" (if serving a frontend)
- "Database Issue Documentation Rule" (database connection problems)
- "External API Integration Issue Rule" (third-party API failures)

**Code Examples**: API endpoint creation, middleware, database queries, validation

---

### Full-Stack Projects

**Critical Rules**: Combination of both Frontend AND Backend rules (8-12 total)

**Integration Issue Rules**: Multiple directions:
- Frontend → Backend issues
- Backend → Database issues
- Backend → External API issues

**Code Examples**: Both client-side and server-side patterns

---

### How Auto-Detection Works

When you provide your tech stack, the AI agent automatically detects your project type:

```
Tech Stack: "React + Redux"           → Frontend
Tech Stack: "Express + PostgreSQL"     → Backend
Tech Stack: "Next.js + Prisma"         → Full-Stack
Tech Stack: "Flutter + Firebase"       → Frontend
Tech Stack: "FastAPI + MongoDB"        → Backend
Tech Stack: "Vue + Django REST"        → Full-Stack
```

The agent then applies the appropriate critical rules, code examples, and integration issue rules.

---

## Problem Statement

### Context

Modern software development projects often use multiple AI coding assistants simultaneously:
- **Claude Code** (claude.ai/code) - Full-featured AI agent with conversation context
- **Cursor** - AI-powered code editor
- **GitHub Copilot** - AI code completion and chat
- **Google Gemini Code Assist** - AI pair programmer integrated in VS Code

Each AI agent has its own rules/instructions file format and location, leading to:

### Core Problems

#### 1. **Inconsistency Across Agents**

**Problem**: Different AI agents receive different instructions, leading to conflicting code suggestions and violations of project standards.

**Example**:
- Claude Code follows rule: "Use `BuildConfig.apiUrl`"
- GitHub Copilot hardcodes URLs (no such rule)
- Cursor suggests MaterialPageRoute instead of named routes

**Impact**: Code quality degrades, technical debt accumulates, developers must manually review and fix AI-generated code.

#### 2. **Rules Duplication & Maintenance Burden**

**Problem**: Each agent needs its own rules file, resulting in duplication of content. When project standards change, developers must update multiple files, often inconsistently.

**Example**:
- `CLAUDE.md` (662 lines)
- `.cursor/rules/apptradingfrontrules.mdc` (364 lines)
- `.github/copilot-instructions.md` (359 lines)
- `.gemini/styleguide.md` (would be ~350 lines if created)
- Total: ~1,735 lines with ~70% duplication across 4 agents

**Impact**: Time wasted maintaining multiple files, easy to forget updating one agent, rules drift apart over time.

#### 3. **Token Budget Inefficiency**

**Problem**: Claude Code reads the entire `CLAUDE.md` file at the start of EVERY conversation, consuming valuable context tokens even for unrelated work.

**Technical Details**:
- Claude Code has a context window (e.g., 200K tokens for Sonnet 4.5)
- Large rules files (662 lines ≈ 3,000-4,000 tokens) consume budget unnecessarily
- When user asks "Fix this typo", Claude still loads all 662 lines about backend API endpoints, chart implementation, deployment procedures, etc.

**Impact**: Reduced effective context for actual work, higher costs, slower performance.

#### 4. **Lack of Structured Knowledge Organization**

**Problem**: Monolithic rules files become hard to navigate, update, and understand. Finding specific guidance requires scanning hundreds of lines.

**Example**: Developer needs backend issue documentation process but must scroll through 662 lines to find it.

**Impact**: Poor developer experience, increased cognitive load, rules less likely to be followed correctly.

---

## Methodology Overview

### Solution Approach

This methodology solves all four problems through a 4-step process:

```
Step 1: Create Comprehensive Base Rules
         ↓
         → Consolidate knowledge from all sources
         → Establish single source of truth
         → Define critical standards

Step 2: Synchronize Rules Across Agents
         ↓
         → Replicate base rules to other agents
         → Adapt to each agent's format
         → Ensure consistency

Step 3: Optimize for Token Efficiency
         ↓
         → Identify content for extraction
         → Create import-based structure
         → Reduce main file to essentials

Step 4: Apply Optimization to All Agents
         ↓
         → Replicate optimization pattern
         → Create agent-specific detailed files
         → Verify all agents synchronized

Result: Consistent, maintainable, efficient AI agent rules
```

### Key Principles

1. **Single Source of Truth**: One comprehensive base from which all agent rules derive
2. **Progressive Enhancement**: Start comprehensive, then optimize
3. **On-Demand Loading**: Detailed rules loaded only when needed (via imports)
4. **Agent-Agnostic Standards**: Core rules work across all agents
5. **Maintainability**: Changes propagate systematically

---

## Step 1: Create Comprehensive Base Rules

**📌 Note**: This section describes the detailed manual process. **AI agents** should use the automated process in [FOR AI AGENTS: Automated Implementation](#for-ai-agents-automated-implementation) which starts with **Step 0: Check Existing Rules**.

### Objective

Create a complete, detailed rules file for Claude Code (the primary AI agent) that captures ALL project standards, patterns, and critical rules.

### Sub-Steps

#### 1.1 Gather Existing Rules

**Action**: Collect all existing AI agent rules from the project.

**⚠️ IMPORTANT**: This step checks if rules already exist. If optimizing existing rules, you may skip some subsequent steps and jump to Step 3 (Optimization).

**Locations to Check**:
- `CLAUDE.md` (Claude Code)
- `.cursor/rules/*.mdc` (Cursor)
- `.github/copilot-instructions.md` (GitHub Copilot)
- `.github/copilot-chat.md` (GitHub Copilot Chat, if exists)
- Any `.copilot-instructions.md` files

**For XP Trading Example**:
```
Found:
- CLAUDE.md (238 lines, basic)
- .cursor/rules/apptradingfrontrules.mdc (28 lines, minimal)
- .github/copilot-instructions.md (358 lines, detailed)
```

#### 1.2 Analyze External Reference Rules

**Action**: If available, review rules from similar projects or templates to identify best practices.

**XP Trading Example**: Reviewed external project rules for inspiration, then adapted them to XP Trading's specific needs.

**What to Look For**:
- Backend issue documentation patterns
- Code style enforcement
- Error handling patterns
- Security considerations

#### 1.3 Identify Critical Rules

**Action**: Determine the non-negotiable rules that MUST be followed in every code change.

**Categories**:
1. **Environment Configuration**: How to handle different environments (dev/prod)
2. **State Management**: Patterns for application state
3. **Navigation**: Routing conventions
4. **Localization**: Internationalization requirements
5. **Authentication**: Security patterns
6. **Error Handling**: How to handle failures

**XP Trading Example - 6 Critical Rules (Frontend Project)**:
1. Never hardcode API URLs (use `BuildConfig.apiUrl`)
2. Use Provider pattern for state management
3. Use named routes only
4. Always internationalize text (AppLocalizations)
5. Include Bearer token in auth requests
6. Handle errors gracefully

**Backend Project Example - 6 Critical Rules**:
1. Never hardcode database credentials (use environment variables)
2. Always validate input at API boundaries
3. Implement proper authentication middleware
4. Use database migrations for schema changes
5. Always log errors with context (request ID, user, timestamp)
6. Implement rate limiting on public endpoints

**Full-Stack Project**: Use BOTH sets of rules (12 total, or merge to 8-10 most critical)

**How to Identify**:
- Rules that, if violated, cause production bugs
- Rules that ensure security
- Rules that maintain architecture integrity
- Rules frequently violated by AI agents

#### 1.4 Define Operating Principles

**Action**: Establish how AI agents should behave during development.

**Phases to Define**:
1. **Before Acting**: What to do before writing code
2. **During Implementation**: Guidelines while coding
3. **Backend Considerations**: When/how to handle backend changes
4. **After Acting**: Post-implementation steps
5. **Platform-Specific**: Environment considerations (e.g., Windows)

**XP Trading Example**:
```markdown
Before Acting:
- Ask questions if unclear
- Verify context
- Check specs
- Review related code
- Never assume

During Implementation:
- Complete code (no pseudocode)
- Exact file paths
- Follow patterns
- Check regressions
- Test features
```

#### 1.5 Create Specialized Rules

**Action**: Define project-specific rules that go beyond general coding standards.

**XP Trading Example - Integration Issue Documentation Rule**:
- Automatically create markdown file when integration problem detected
- File naming (adapt based on project type):
  - **Frontend → Backend**: `BACKEND_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
  - **Backend → Frontend**: `FRONTEND_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
  - **Backend → Database**: `DATABASE_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
  - **Backend → External API**: `API_INTEGRATION_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
- 8 required sections
- Triggers (examples):
  - **Frontend**: 4xx/5xx errors, missing endpoints, auth failures, CORS issues
  - **Backend**: Database connection errors, external API failures, authentication issues, validation failures

**Purpose**: Ensures systematic documentation of integration issues across system boundaries.

#### 1.6 Document Architecture

**Action**: Provide essential architecture information for context.

**Include**:
- Directory structure
- Key services and their purposes
- Critical initialization order (e.g., Firebase)
- Backend API endpoints
- Common gotchas

**Keep It Concise**: Only essential architecture, not exhaustive documentation.

#### 1.7 Add Development Guidance

**Action**: Include practical information for daily development.

**Sections**:
- Development commands (run, test, build)
- Code style guidelines
- Testing strategies
- Debugging tips

#### 1.8 Create Implementation Checklist

**Action**: Provide a comprehensive checklist for code review.

**Categories**:
- Planning (context gathering, architecture review)
- Implementation (code quality, naming, organization)
- Security & Privacy (auth, validation, API security)
- Testing (manual, regression, platform-specific)
- Documentation (code docs, backend docs)

**XP Trading Result**: 29-item checklist across 6 categories

#### 1.9 Assemble Complete Document

**Action**: Combine all elements into a comprehensive `CLAUDE.md` file.

**Structure**:
```markdown
# CLAUDE.md

## Quick Navigation (with links)

## Project Overview
- What is the project
- Technology stack
- Development environment

## How to Operate
- Before/During/After acting
- Backend considerations
- Platform-specific notes

## Critical Rules (6)
- Rule 1 with code examples
- Rule 2 with code examples
- ... (all rules with ✅ correct and ❌ wrong examples)

## Specialized Rules
- Backend issue documentation
- Other project-specific rules

## Architecture & Structure
- Directory structure
- Key services
- Firebase integration
- Backend endpoints
- Common gotchas

## Development Commands
- Run, Test, Quality, Dependencies

## Code Style & Conventions
- Naming conventions
- Widget structure
- Async patterns
- Documentation comments

## Testing & Debugging
- Debugging guides
- Common scenarios

## Implementation Checklist
- Complete 29-item checklist

## Deployment
- Build commands
- Pre-production checklist

## Key Documentation Files
- Links to other docs

## Summary
- Quick takeaways
```

**XP Trading Result**: `CLAUDE.md` with 662 lines - comprehensive but verbose.

---

## Step 2: Synchronize Rules Across Agents

### Objective

Ensure all AI agents (Cursor, GitHub Copilot, Google Gemini) use the same standards as Claude Code.

### Sub-Steps

#### 2.1 Understand Agent-Specific Formats

**Action**: Research how each AI agent loads and interprets rules.

**Claude Code**:
- File: `CLAUDE.md` at project root
- Format: Markdown
- Loading: Automatically loaded at conversation start
- Import Support: Yes (`@path/to/file.md`)
- Max Nesting: 5 levels

**Cursor**:
- File: `.cursor/rules/*.mdc` (MDC format)
- Format: Markdown with YAML frontmatter
- Loading: Based on globs and always Apply
- Import Support: Limited (best practice: separate files referenced, not imported)

**GitHub Copilot**:
- File: `.github/copilot-instructions.md`
- Format: Markdown
- Loading: Automatically loaded
- Import Support: No (monolithic file recommended)

**Google Gemini**:
- File: `.gemini/styleguide.md` at project root
- Settings: `~/.gemini/settings.json` for global config
- Format: Markdown
- Loading: Loaded via VS Code Settings UI or style guide file
- Import Support: No (monolithic file recommended)

#### 2.2 Adapt Content to Each Agent

**Action**: Create agent-specific versions of the comprehensive rules.

**Key Adaptations**:

**For Cursor** (`.cursor/rules/apptradingfrontrules.mdc`):
```markdown
---
description: XP Trading - AI Agent Rules for Cursor
globs:
alwaysApply: true
---

# Cursor AI Agent Rules - XP Trading

[Same content as CLAUDE.md but adapted to Cursor's format]
```

**For GitHub Copilot** (`.github/copilot-instructions.md`):
```markdown
# GitHub Copilot Instructions for XP Trading

[Same content as CLAUDE.md adapted to GitHub Copilot's context]
```

**For Google Gemini** (`.gemini/styleguide.md`):
```markdown
# Gemini Style Guide - XP Trading

**Project**: XP Trading - Trading Signals App (Forex & Crypto)
**Stack**: Flutter + Provider + Firebase Auth + Django REST API

[Same content as CLAUDE.md adapted to Gemini's format]
```

#### 2.3 Ensure Critical Rules Consistency

**Action**: Verify that all 6 critical rules are identically expressed in all agent files.

**Verification Checklist**:
- [ ] Rule 1 (BuildConfig.apiUrl) present with same code examples
- [ ] Rule 2 (Provider pattern) present with same code examples
- [ ] Rule 3 (Named routes) present with same code examples
- [ ] Rule 4 (i18n) present with same code examples
- [ ] Rule 5 (Bearer token) present with same code examples
- [ ] Rule 6 (Error handling) present with same code examples

**XP Trading Verification**: All 6 rules synchronized across CLAUDE.md, Cursor, and GitHub Copilot.

#### 2.4 Synchronize Backend Issue Rule

**Action**: Ensure specialized rules (like Backend Issue Documentation) are identical across all agents.

**Key Elements to Synchronize**:
- Triggers (when to create files)
- File naming convention
- 8 required sections
- Process steps

**Result**: All agents will create identical backend issue files.

#### 2.5 Test Agent Synchronization

**Action**: Manually verify that each agent understands the rules correctly.

**Testing Method**:
1. Open same project in Claude Code, Cursor, GitHub Copilot, and Gemini
2. Ask identical question to each agent (e.g., "How should I fetch coach data from API?")
3. Verify responses follow same critical rules
4. Check for consistency in suggestions

**Expected Outcome**: All 4 agents suggest `BuildConfig.apiUrl`, Provider pattern, named routes, etc.

---

## Step 3: Optimize for Token Efficiency

### Objective

Reduce the main rules file (CLAUDE.md) from 662 lines to ~350-400 lines while maintaining all information through an import-based structure.

### Sub-Steps

#### 3.1 Analyze Token Consumption

**Action**: Understand how much context the rules file consumes.

**Calculation**:
- 662 lines of markdown ≈ 3,000-4,000 tokens (rough estimate)
- For a 200K token context window, this is 1.5-2% of budget
- Every conversation loads this, regardless of relevance

**Question**: Does a "Fix typo" conversation need backend API endpoint documentation?

**Answer**: No → Opportunity for optimization.

#### 3.2 Identify Content for Extraction

**Action**: Categorize content into "always needed" vs "on-demand".

**Always Needed (Keep in Main File)**:
- Project overview
- Operating principles
- 6 Critical Rules (with code examples, adapted to project type)
- Integration Issue Documentation Rule (summary)
- Quick architecture overview
- Quick checklist

**On-Demand (Extract to Detailed Files)**:
- Complete integration issue template (extract to `integration-issue-documentation.md` or `backend-issue-documentation.md` for frontend projects)
- Detailed code style guide (extract to `code-style-detailed.md`)
- Full 29-item checklist (extract to `implementation-checklist.md`)

#### 3.3 Create Directory Structure

**Action**: Create organized directory for detailed rules.

**For Claude Code**:
```bash
mkdir -p .claude/rules/
```

**For Cursor**:
```bash
mkdir -p .cursor/rules/detailed/
```

**For GitHub Copilot**:
```bash
mkdir -p .github/copilot-rules/
```

**For Google Gemini**:
```bash
mkdir -p .gemini/rules/
```

#### 3.4 Extract Detailed Content

**Action**: Create separate files for detailed guidance.

**File 1: Backend Issue Documentation** (`.claude/rules/backend-issue-documentation.md`):

**Content**: ~200-300 lines
- Overview
- Triggers (detailed list)
- File naming convention
- 8 required sections with descriptions
- Complete template
- Best practices
- Examples

**File 2: Code Style Detailed** (`.claude/rules/code-style-detailed.md`):

**Content**: ~300-400 lines
- Naming conventions (detailed)
- Widget structure (Stateless, Stateful, with examples)
- Async patterns (basic, multiple operations, error handling)
- Provider pattern usage (read, watch, select)
- Model classes (fromJson, toJson, copyWith)
- Internationalization (detailed)
- Navigation (all patterns)
- API communication
- Documentation comments
- File organization
- Import ordering
- Code formatting
- Null safety

**File 3: Implementation Checklist** (`.claude/rules/implementation-checklist.md`):

**Content**: ~300-400 lines
- Before Writing Code (context, architecture, dependencies)
- During Implementation (code quality, naming, organization, async, providers, models, UI/UX)
- Security & Privacy (auth, validation, API security)
- Testing (manual, regression, platform)
- Code Analysis (static, performance)
- Documentation (code, backend)
- Backend Considerations (changes required, workarounds)
- Deployment Readiness (environment, build, pre-release)
- Windows Environment
- Final Checks (code review, git, communication)

#### 3.5 Update Main File with References

**Action**: Replace extracted content with references to detailed files.

**Before Optimization** (CLAUDE.md, 662 lines):
```markdown
## Implementation Checklist

Before validating any code change:

### Planning
- [ ] Understood user request completely
- [ ] Asked clarifying questions if needed
- [ ] Reviewed project specifications
- [ ] Identified all affected files

### Implementation
- [ ] Provided complete, functional code
- [ ] Specified exact file paths
... (25 more items)
```

**After Optimization** (CLAUDE.md, ~400 lines):
```markdown
## Implementation Checklist

**Quick Checklist**:

### Critical (6 Rules)
- [ ] `BuildConfig.apiUrl` (no hardcoded URLs)
- [ ] Provider pattern
- [ ] Named routes
- [ ] `AppLocalizations` (fr/en)
- [ ] Bearer token
- [ ] Error handling

### Quality
- [ ] No regressions
- [ ] `flutter analyze` passes
- [ ] Backend issue file if needed
- [ ] Summary provided

**Complete checklist** (29 items): @.claude/rules/implementation-checklist.md
```

**Import Syntax for Claude Code**:
```markdown
@.claude/rules/backend-issue-documentation.md
@.claude/rules/code-style-detailed.md
@.claude/rules/implementation-checklist.md
```

**Note**: Use `@` prefix for imports. Claude Code will load these files on-demand when relevant to the conversation.

#### 3.6 Optimize Each Section

**Action**: Condense all sections while preserving critical information.

**Example - Architecture Section**:

**Before** (45 lines):
```markdown
## Architecture & Structure

### Directory Structure
```
lib/
├── core/                   # Core configurations and utilities
│   ├── config/            # Environment, API, theme, build, route configs
│   ├── constants/         # App-wide constants
│   ├── l10n/             # Localization (LocaleProvider)
│   ├── services/         # Core services
│   └── utils/            # Utility functions
├── data/                  # Data layer
│   ├── data_sources/     # Remote & local data sources
│   ├── models/           # Data models
│   └── repositories/     # Repository pattern
├── presentation/          # UI layer
...
```

**After** (15 lines):
```markdown
## Architecture & Structure

**Structure**:
```
lib/
├── core/           # Config, constants, l10n, utils
├── data/           # Models, repositories, data sources
├── presentation/   # Screens, widgets
├── providers/      # State management
├── services/       # Business logic
└── main.dart
```

**Services**: ✅ Use `chart_api_service.dart` | ⚠️ Avoid `api_service.dart` (hardcoded)
```

**Optimization Techniques**:
1. **Use arrows (→)** instead of bullet points
2. **Condense to single lines** where possible
3. **Use pipe (|)** for multiple items: "Debug→Dev | Release→Prod"
4. **Remove verbose explanations**, keep essentials
5. **Consolidate code examples** (one good example instead of three)

#### 3.7 Verify Token Reduction

**Action**: Calculate token savings.

**XP Trading Results**:
- Before: 662 lines ≈ 3,500 tokens
- After: 405 lines ≈ 2,100 tokens
- **Savings**: ~40% reduction (1,400 tokens saved per conversation)

**Benefit**: More context available for actual code and conversation.

---

## Step 4: Apply Optimization to All Agents

### Objective

Apply the same optimization pattern to Cursor, GitHub Copilot, and Google Gemini rules.

### Sub-Steps

#### 4.1 Create Agent-Specific Detailed Directories

**Action**: Create detailed rules directories for each agent.

**Cursor**:
```bash
mkdir -p .cursor/rules/detailed/
```

**GitHub Copilot**:
```bash
mkdir -p .github/copilot-rules/
```

**Google Gemini**:
```bash
mkdir -p .gemini/rules/
```

#### 4.2 Replicate Detailed Files

**Action**: Create agent-specific versions of detailed files.

**Option A - Copy & Adapt** (Recommended):
```bash
# For Cursor
cp .claude/rules/backend-issue-documentation.md .cursor/rules/detailed/backend-issue-documentation.md
cp .claude/rules/code-style-detailed.md .cursor/rules/detailed/code-style-guide.md
cp .claude/rules/implementation-checklist.md .cursor/rules/detailed/implementation-checklist.md

# For GitHub Copilot
cp .claude/rules/backend-issue-documentation.md .github/copilot-rules/backend-issue-documentation.md
cp .claude/rules/code-style-detailed.md .github/copilot-rules/code-style-guide.md
cp .claude/rules/implementation-checklist.md .github/copilot-rules/implementation-checklist.md

# For Google Gemini
cp .claude/rules/backend-issue-documentation.md .gemini/rules/backend-issue-documentation.md
cp .claude/rules/code-style-detailed.md .gemini/rules/code-style-guide.md
cp .claude/rules/implementation-checklist.md .gemini/rules/implementation-checklist.md

# Adapt headers to mention respective agent instead of Claude Code
```

**Option B - Symbolic Links** (If supported):
```bash
# Link to same files (changes apply to all agents)
ln -s ../../.claude/rules/backend-issue-documentation.md .cursor/rules/detailed/
```

**XP Trading Implementation**: Used Option A with minor adaptations.

#### 4.3 Optimize Cursor Rules File

**Action**: Apply same optimization to `.cursor/rules/apptradingfrontrules.mdc`.

**Before**: 364 lines
**After**: 210 lines
**Reduction**: 42%

**Changes**:
- Condensed Operating Principles
- Kept 6 Critical Rules with code examples
- Reduced Backend Issue Documentation to summary with reference
- Simplified Architecture section
- Condensed Code Style
- Replaced full checklist with quick checklist + reference

**References in Cursor File**:
```markdown
**Complete template & instructions**: `.cursor/rules/detailed/backend-issue-documentation.md`

**Detailed style guide**: `.cursor/rules/detailed/code-style-guide.md`

**Complete checklist** (29 items): `.cursor/rules/detailed/implementation-checklist.md`
```

**Note**: Cursor doesn't support `@import` like Claude Code, so references are informational. AI agents can still read these files when needed.

#### 4.4 Optimize GitHub Copilot Rules

**Action**: Apply same optimization to `.github/copilot-instructions.md`.

**Before**: 359 lines
**After**: 318 lines
**Reduction**: 11%

**Note**: GitHub Copilot optimization is less aggressive because:
- No import support
- Shorter initial file
- Benefits less from file splitting

**Still Includes**:
- References to detailed files (informational)
- Developers can read detailed files manually
- Future: GitHub may add import support

#### 4.5 Optimize Google Gemini Rules

**Action**: Create optimized `.gemini/styleguide.md`.

**Target**: ~350-400 lines
**Approach**: Similar to GitHub Copilot (moderate optimization)

**Note**: Gemini doesn't support import, so references are informational. Keep main file concise but comprehensive.

**Structure**:
```markdown
# Gemini Style Guide - XP Trading

**Version**: 2.0 (Optimized)
**Project**: XP Trading - Trading Signals App

## Operating Principles

[Condensed principles]

## Critical Rules (6)

[Full rules with code examples - KEEP COMPLETE]

## Backend Issue Documentation

[Summary + reference to .gemini/rules/backend-issue-documentation.md]

## Architecture

[Condensed overview]

## Quick Checklist

[Summary + reference to detailed checklist]
```

**References in Gemini File**:
```markdown
**Complete template**: `.gemini/rules/backend-issue-documentation.md`
**Detailed guide**: `.gemini/rules/code-style-guide.md`
**Full checklist**: `.gemini/rules/implementation-checklist.md`
```

#### 4.6 Synchronize Optimization Patterns

**Action**: Ensure all four agents use the same optimization approach.

**Checklist**:
- [ ] All 4 agents have detailed rules directories
- [ ] All 4 agents have backend issue documentation (detailed)
- [ ] All 4 agents have code style guide (detailed)
- [ ] All 4 agents have implementation checklist (detailed)
- [ ] Main files reference detailed files
- [ ] 6 Critical Rules kept complete in all main files
- [ ] Backend Issue Rule kept as summary in all main files

**XP Trading Verification**: ✅ All 4 agents synchronized

---

## Verification & Validation

### Verification Steps

#### 1. File Structure Verification

**Check** that all files exist:

```bash
# Claude Code
ls -la CLAUDE.md
ls -la .claude/rules/backend-issue-documentation.md
ls -la .claude/rules/code-style-detailed.md
ls -la .claude/rules/implementation-checklist.md

# Cursor
ls -la .cursor/rules/apptradingfrontrules.mdc
ls -la .cursor/rules/detailed/backend-issue-documentation.md
ls -la .cursor/rules/detailed/code-style-guide.md
ls -la .cursor/rules/detailed/implementation-checklist.md

# GitHub Copilot
ls -la .github/copilot-instructions.md
ls -la .github/copilot-rules/backend-issue-documentation.md
ls -la .github/copilot-rules/code-style-guide.md
ls -la .github/copilot-rules/implementation-checklist.md

# Google Gemini
ls -la .gemini/styleguide.md
ls -la .gemini/rules/backend-issue-documentation.md
ls -la .gemini/rules/code-style-guide.md
ls -la .gemini/rules/implementation-checklist.md
```

#### 2. Line Count Verification

**Measure** optimization effectiveness:

```bash
wc -l CLAUDE.md                                  # Should be ~350-450 lines
wc -l .cursor/rules/apptradingfrontrules.mdc    # Should be ~200-250 lines
wc -l .github/copilot-instructions.md            # Should be ~300-350 lines
wc -l .gemini/styleguide.md                      # Should be ~300-400 lines
```

**XP Trading Results**:
- CLAUDE.md: 405 lines (from 662, -39%)
- Cursor: 210 lines (from 364, -42%)
- GitHub Copilot: 318 lines (from 359, -11%)
- Gemini: 350 lines (new, optimized from start)

#### 3. Critical Rules Verification

**Test** that all 6 critical rules are present in all main files:

```bash
# Rule 1: BuildConfig.apiUrl
grep -l "BuildConfig.apiUrl" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md

# Rule 2: Provider pattern
grep -l "Provider pattern" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md

# Rule 3: Named routes
grep -l "Named routes" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md

# Rule 4: AppLocalizations
grep -l "AppLocalizations" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md

# Rule 5: Bearer token
grep -l "Bearer token" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md

# Rule 6: Error handling
grep -l "Handle Errors" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md
```

**Expected**: All 4 files found for each rule.

#### 4. Backend Issue Rule Verification

**Test** backend issue documentation is present:

```bash
grep -l "BACKEND_ISSUE" CLAUDE.md .cursor/rules/apptradingfrontrules.mdc .github/copilot-instructions.md .gemini/styleguide.md
```

**Verify** all 4 files mention:
- File naming: `BACKEND_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
- 8 required sections
- Automatic creation

#### 5. Reference Link Verification

**Check** that main files reference detailed files:

```bash
# Claude Code (should have @import syntax)
grep "@.claude/rules/" CLAUDE.md

# Cursor (should have reference paths)
grep "\.cursor/rules/detailed/" .cursor/rules/apptradingfrontrules.mdc

# GitHub Copilot (should have reference paths)
grep "\.github/copilot-rules/" .github/copilot-instructions.md

# Gemini (should have reference paths)
grep "\.gemini/rules/" .gemini/styleguide.md
```

#### 6. Consistency Verification

**Compare** that all agents have same critical content:

**Manual Check**:
1. Open all three main rules files side-by-side
2. Compare each Critical Rule section
3. Verify code examples are identical
4. Check that Operating Principles match

**Automated Check** (optional):
```bash
# Extract critical rules from each file and compare
# (Requires custom script)
./verify_rule_consistency.sh
```

### Functional Testing

#### Test 1: Claude Code Import Test

**Action**: Start a new Claude Code conversation.

**Ask**: "What are the detailed code style guidelines?"

**Expected**: Claude Code should respond by loading `@.claude/rules/code-style-detailed.md` and providing detailed widget structure, async patterns, etc.

**Verification**: Response includes details not in main `CLAUDE.md` file.

#### Test 2: Backend Issue Creation Test

**Action**: Use Claude Code/Cursor/GitHub Copilot to generate code with a backend error scenario.

**Trigger**: Simulate a 403 error from backend.

**Expected**: AI agent creates `BACKEND_ISSUE_403_[DESC]_[DATE].md` with all 8 sections.

**Verification**: File created, all sections present, follows template.

#### Test 3: Critical Rules Adherence Test

**Action**: Ask each AI agent to write code for the same feature (e.g., "Fetch coaches from API").

**Agents to Test**:
1. Claude Code
2. Cursor
3. GitHub Copilot
4. Google Gemini

**Expected Code** (all 4 agents should produce identical or very similar code):
```dart
import 'package:xp_trading/core/config/build_config.dart';

Future<List<Coach>> fetchCoaches() async {
  final url = '${BuildConfig.apiUrl}/coaching/coaches/';  // ✅ Rule 1
  // ... Provider pattern, error handling, etc.
}
```

**Verification**:
- [ ] No hardcoded URLs (Rule 1)
- [ ] Uses Provider pattern if applicable (Rule 2)
- [ ] Suggests named routes if navigation (Rule 3)
- [ ] No hardcoded strings (Rule 4)
- [ ] Includes Bearer token if auth request (Rule 5)
- [ ] Has try-catch error handling (Rule 6)

---

## Maintenance & Updates

### When to Update Rules

#### Trigger 1: New Critical Rule

**Scenario**: Project adopts a new standard (e.g., "Always use Riverpod instead of Provider").

**Action**:
1. Add new rule to `CLAUDE.md` Critical Rules section (with code examples)
2. Update `.cursor/rules/apptradingfrontrules.mdc` with same rule
3. Update `.github/copilot-instructions.md` with same rule
4. If rule is detailed, create/update detailed file

#### Trigger 2: Project Architecture Change

**Scenario**: Project migrates from Django to FastAPI.

**Action**:
1. Update Architecture section in `CLAUDE.md`
2. Update backend endpoints in all agent files
3. Update detailed files if backend issue documentation changes

#### Trigger 3: New Specialized Rule

**Scenario**: Add "Frontend Performance Monitoring Rule".

**Action**:
1. Add to `CLAUDE.md` after Critical Rules
2. Create detailed file: `.claude/rules/performance-monitoring.md`
3. Add reference in main file
4. Replicate to Cursor and GitHub Copilot

### Update Process

#### Step 1: Identify Scope

**Question**: Does this change affect:
- [ ] Critical Rules (6 rules)
- [ ] Operating Principles
- [ ] Specialized Rules (Backend Issue, etc.)
- [ ] Architecture
- [ ] Code Style
- [ ] Checklist

#### Step 2: Update Primary File

**Action**: Update `CLAUDE.md` first (single source of truth).

**Review**:
- Does change fit within optimized structure?
- Does it need a new detailed file?
- Should existing detailed file be updated?

#### Step 3: Synchronize to Other Agents

**Action**: Apply identical changes to Cursor, GitHub Copilot, and Gemini.

**Checklist**:
- [ ] Updated `.cursor/rules/apptradingfrontrules.mdc`
- [ ] Updated `.github/copilot-instructions.md`
- [ ] Updated `.gemini/styleguide.md`
- [ ] Updated detailed files if applicable for all agents

#### Step 4: Verify Synchronization

**Action**: Run verification steps (see Verification & Validation section).

### Version Control

**Best Practices**:
1. **Commit all agent rules together**: One commit should update all four agents
2. **Descriptive commit messages**: "Add RULE_7: Use Riverpod for state management across all agents"
3. **Review diffs carefully**: Ensure consistency across files
4. **Document breaking changes**: If rule changes break existing code, note in commit

**Example Commit**:
```
git add CLAUDE.md .claude/rules/ .cursor/rules/ .github/ .gemini/
git commit -m "Add Critical Rule 7: Use Riverpod instead of Provider

- Updated all 4 agent rules files (Claude Code, Cursor, GitHub Copilot, Gemini)
- Added detailed Provider-to-Riverpod migration guide
- Updated implementation checklist
"
```

---

## Appendices

### Appendix A: File Structure Reference

#### Complete File Structure (XP Trading Example)

```
xp_trading/
├── CLAUDE.md                                           # Claude Code rules (405 lines)
├── .claude/
│   └── rules/
│       ├── backend-issue-documentation.md              # Detailed backend issue guide (~320 lines)
│       ├── code-style-detailed.md                      # Detailed code style guide (~380 lines)
│       └── implementation-checklist.md                 # Detailed checklist (~360 lines)
├── .cursor/
│   └── rules/
│       ├── apptradingfrontrules.mdc                    # Cursor rules (210 lines)
│       └── detailed/
│           ├── backend-issue-documentation.md          # Detailed backend issue guide
│           ├── code-style-guide.md                     # Detailed code style guide
│           └── implementation-checklist.md             # Detailed checklist
├── .github/
│   ├── copilot-instructions.md                         # GitHub Copilot rules (318 lines)
│   └── copilot-rules/
│       ├── backend-issue-documentation.md              # Detailed backend issue guide
│       ├── code-style-guide.md                         # Detailed code style guide
│       └── implementation-checklist.md                 # Detailed checklist
└── .gemini/
    ├── styleguide.md                                   # Gemini rules (350 lines)
    └── rules/
        ├── backend-issue-documentation.md              # Detailed backend issue guide
        ├── code-style-guide.md                         # Detailed code style guide
        └── implementation-checklist.md                 # Detailed checklist
```

**Total Lines**:
- Main files: 405 + 210 + 318 + 350 = 1,283 lines (down from estimated 1,735 lines, -26%)
- Detailed files: ~1,060 lines per agent × 4 agents = 4,240 lines
- **Effective**: Only load what's needed (on-demand for Claude Code, reference for others)

### Appendix B: Critical Rules Template

Use this template for defining critical rules in any project:

```markdown
## Critical Rules

### Rule 1: [Rule Name]

```[language]
// ✅ CORRECT
[correct code example]

// ❌ WRONG
[incorrect code example]
```

**Why**: [Brief explanation of why this rule is critical]

**Config**: [Related configuration files or settings]

### Rule 2: [Rule Name]

[Repeat same structure]
```

**Guidelines**:
- Limit to 6-8 critical rules
- Each rule must have code examples
- Show both ✅ correct and ❌ wrong
- Keep explanations concise

### Appendix C: Optimization Checklist

When optimizing rules files:

**Condensation Techniques**:
- [ ] Use arrows (→) instead of "then"/"next"
- [ ] Use pipes (|) for alternatives: "Dev | Prod"
- [ ] Combine related items: "Run: `cmd1` | `cmd2`"
- [ ] Remove verbose phrases: "It is important to" → just state the rule
- [ ] Collapse multi-line lists to single lines where possible
- [ ] Use checkboxes ([ ]) for quick checklists
- [ ] Keep code examples minimal (one good example)
- [ ] Remove duplicate information across sections

**Content Extraction**:
- [ ] Identify detailed content (>50 lines on one topic)
- [ ] Create separate file in detailed rules directory
- [ ] Replace with summary + reference link
- [ ] Ensure reference is clear and actionable

**Preservation**:
- [ ] Keep all critical rules complete with examples
- [ ] Keep operating principles (condensed)
- [ ] Keep essential architecture overview
- [ ] Keep quick checklists (summary form)

### Appendix D: Agent-Specific Considerations

#### Claude Code

**Strengths**:
- Supports `@import` syntax
- Automatically loads CLAUDE.md
- Can handle longer files but prefers optimized
- Context-aware (loads imports when relevant)

**Optimization Strategy**: Aggressive optimization with imports

**File Location**: `CLAUDE.md` at project root

**Import Syntax**: `@.claude/rules/filename.md`

#### Cursor

**Strengths**:
- MDC format with glob patterns
- Fast code editor integration
- Good at following concise rules

**Limitations**:
- No native import support
- Prefers shorter, focused rules

**Optimization Strategy**: Aggressive optimization with references (informational)

**File Location**: `.cursor/rules/*.mdc`

**YAML Frontmatter**:
```yaml
---
description: Project Name - AI Rules
globs:
alwaysApply: true
---
```

#### GitHub Copilot

**Strengths**:
- Code completion focused
- Good at following patterns
- Works across GitHub ecosystem

**Limitations**:
- No import support
- Prefers monolithic files
- Less context-aware than Claude Code

**Optimization Strategy**: Moderate optimization, keep more in main file

**File Location**: `.github/copilot-instructions.md`

#### Google Gemini Code Assist

**Strengths**:
- Integrated in VS Code
- Good at following concise rules
- Settings UI configuration
- Project-level style guides

**Limitations**:
- No import support
- No automatic file loading (must configure via UI or style guide)
- Relatively new, evolving features

**Optimization Strategy**: Moderate optimization similar to GitHub Copilot

**File Locations**:
- **Global settings**: `~/.gemini/settings.json` (IDE-level private rules)
- **Project style guide**: `.gemini/styleguide.md` (shared with team)

**Configuration**:
- Access via Control+I (Windows/Linux) or Command+I (macOS)
- Navigate to Preferences → "Geminicodeassist: Rules"
- Can set rules per-project or globally

### Appendix E: AI Agent Automated Implementation Guide

**⚠️ FOR AI AGENTS ONLY**: These instructions are for AI agents implementing rules optimization autonomously.

#### Prerequisites Check

Before proceeding, verify you have received from the user:

```python
required_info = {
    "project_name": str,          # e.g., "MyEcommerceApp"
    "tech_stack": str,            # e.g., "React + Node.js + PostgreSQL"
    "platform": str,              # e.g., "Windows", "macOS", "Linux"
    "critical_rules": list[str],  # 6-8 rules, each with description
    "specialized_rules": list[str] or None,  # Optional unique patterns
    "ai_agents": list[str]        # e.g., ["Claude Code", "Cursor", "GitHub Copilot", "Google Gemini"]
}
```

If missing, ask user for missing information ONLY.

#### Automated Adaptation Algorithm

**EXECUTE THIS AUTOMATICALLY** - No permission required:

##### 1. Create Directory Structure

```bash
# For Claude Code
mkdir -p .claude/rules/

# For Cursor
mkdir -p .cursor/rules/detailed/

# For GitHub Copilot
mkdir -p .github/copilot-rules/

# For Google Gemini
mkdir -p .gemini/rules/
```

##### 2. Transform User Input to Code Examples

For each critical rule provided by user, automatically generate code examples:

**Input Example** (from user):
```
Rule: "Always use environment variables for API URLs"
Stack: "React + Node.js"
```

**Your Automatic Output** (in rules file):
```markdown
### Rule 1: Never Hardcode API URLs

```javascript
// ✅ CORRECT
const apiUrl = process.env.REACT_APP_API_URL || process.env.API_URL;

// ❌ WRONG
const apiUrl = 'http://localhost:3000/api';
```

**Why**: Hardcoded URLs break in different environments

**Config**: `.env` files, environment-specific configs
```

**Transformation Rules**:
- Flutter/Django → React/Node.js: Use `process.env.*` instead of `BuildConfig.*`
- Python → JavaScript: Transform syntax appropriately
- Java → TypeScript: Adjust type annotations
- Go → Rust: Adapt to language conventions

##### 3. Generate Main Rules Files Automatically

**For each AI agent**, create main rules file with this structure:

```markdown
# [Agent Name] Instructions - [Project Name]

**Version**: 1.0
**Date**: [Current Date]
**Project**: [Project Name] - [Brief Description]

## Project Overview

[Project Name] is a [Tech Stack] application for [Purpose]:
- [Feature 1]
- [Feature 2]
- [Tech Stack details]

## Operating Principles

**Before**: Ask questions → Verify context → Review code → Never assume
**During**: Complete code → Exact paths → Follow patterns → Check regressions
**After**: Summarize → List tasks → Next steps

## Critical Rules ([N] Rules)

[Auto-generated from user's critical_rules, with code examples]

### Rule 1: [Title]
[Code example with ✅ CORRECT and ❌ WRONG]

### Rule 2: [Title]
[Code example]

[... repeat for all rules ...]

## Specialized Rules

[If user provided specialized_rules, include them here]
[Otherwise, adapt Integration Issue Documentation Rule from XP Trading template based on project type:
 - Frontend projects: "Backend Issue Documentation Rule"
 - Backend projects: "Frontend/Client Issue Documentation Rule" or "External API Integration Issue Rule"
 - Full-stack: Both directions as needed]

## Architecture & Structure

[Adapt from tech_stack - show directory structure for React/Node/etc.]

## Development Commands

[Auto-generate based on tech_stack]
- React: npm start, npm test, npm run build
- Python: python -m venv, pip install, python manage.py
- Go: go run, go test, go build
[etc.]

## Code Style & Conventions

[Auto-adapt from language conventions]
- Files: snake_case (Python) or kebab-case (JavaScript)
- Classes: PascalCase
- Variables: camelCase (JS) or snake_case (Python)

## Implementation Checklist

**Critical (N Rules)**:
- [ ] [Rule 1 one-liner]
- [ ] [Rule 2 one-liner]
[... all critical rules ...]

**Quality**:
- [ ] No regressions
- [ ] Linter passes
- [ ] Tests pass
- [ ] Summary provided
```

##### 4. Generate Detailed Rules Files

**Create 3 detailed files automatically**:

**File 1**: `backend-issue-documentation.md`
- Adapt XP Trading template
- Replace Django with user's backend framework
- Keep structure identical (8 sections)

**File 2**: `code-style-detailed.md`
- Generate language-specific style guide
- Include: naming, widget/component structure, async patterns, documentation
- Use tech_stack to determine language conventions

**File 3**: `implementation-checklist.md`
- Adapt 29-item checklist
- Replace Flutter-specific items with relevant tech
- Keep structure: Before/During/Security/Testing/Deployment

##### 5. Apply Optimization Automatically

**For each main file created**:
1. Calculate line count
2. If > 500 lines, extract detailed content to separate files
3. Add references/imports to detailed files
4. Reduce to ~350-450 lines
5. Keep all critical rules complete with examples

##### 6. Language-Specific Adaptations

**IMPORTANT**: Provide BOTH frontend (client) and backend (server) examples based on project type.

**JavaScript/TypeScript**:

*Frontend (React)*:
```javascript
// Environment variables
const apiUrl = process.env.REACT_APP_API_URL;

// Async patterns (calling API)
async function fetchData() {
  try {
    const response = await fetch(apiUrl);
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
}
```

*Backend (Express)*:
```javascript
// Environment variables
const dbUrl = process.env.DATABASE_URL;

// Creating API endpoint
app.get('/api/users', async (req, res) => {
  try {
    const users = await db.query('SELECT * FROM users');
    res.json(users);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Authentication middleware
const authMiddleware = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  // Verify token...
  next();
};
```

**Python**:

*Frontend (calling API)*:
```python
# Environment variables
import os
api_url = os.getenv('API_URL')

# Async patterns (calling API)
async def fetch_data():
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(api_url)
            return response.json()
    except Exception as e:
        logger.error(f"Error: {e}")
        raise
```

*Backend (FastAPI)*:
```python
# Environment variables
import os
db_url = os.getenv('DATABASE_URL')

# Creating API endpoint
@app.get('/api/users')
async def get_users(db: Session = Depends(get_db)):
    try:
        users = db.query(User).all()
        return users
    except Exception as e:
        logger.error(f"Error: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

# Input validation
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)

@app.post('/api/users')
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    # Validation happens automatically via Pydantic
    # ...
```

**Go**:

*Frontend (calling API)*:
```go
// Environment variables
apiURL := os.Getenv("API_URL")

// Error handling (calling API)
func fetchData() (Data, error) {
    resp, err := http.Get(apiURL)
    if err != nil {
        return Data{}, fmt.Errorf("fetch failed: %w", err)
    }
    defer resp.Body.Close()
    // ...
}
```

*Backend (Gin)*:
```go
// Environment variables
dbURL := os.Getenv("DATABASE_URL")

// Creating API endpoint
func getUsers(c *gin.Context) {
    var users []User
    if err := db.Find(&users).Error; err != nil {
        log.Printf("Error fetching users: %v", err)
        c.JSON(500, gin.H{"error": "Internal server error"})
        return
    }
    c.JSON(200, users)
}

// Authentication middleware
func authMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := c.GetHeader("Authorization")
        if token == "" {
            c.JSON(401, gin.H{"error": "Unauthorized"})
            c.Abort()
            return
        }
        // Verify token...
        c.Next()
    }
}

// Input validation
type CreateUserRequest struct {
    Email    string `json:"email" binding:"required,email"`
    Password string `json:"password" binding:"required,min=8"`
}
```

**Rust**:

*Frontend (calling API)*:
```rust
// Environment variables
let api_url = std::env::var("API_URL")?;

// Error handling (calling API)
async fn fetch_data() -> Result<Data, Error> {
    let response = reqwest::get(&api_url).await?;
    let data = response.json::<Data>().await?;
    Ok(data)
}
```

*Backend (Axum)*:
```rust
// Environment variables
let db_url = std::env::var("DATABASE_URL")?;

// Creating API endpoint
async fn get_users(
    State(db): State<DatabasePool>,
) -> Result<Json<Vec<User>>, StatusCode> {
    let users = sqlx::query_as::<_, User>("SELECT * FROM users")
        .fetch_all(&db)
        .await
        .map_err(|e| {
            tracing::error!("Database error: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    Ok(Json(users))
}

// Input validation
#[derive(Deserialize, Validate)]
struct CreateUser {
    #[validate(email)]
    email: String,
    #[validate(length(min = 8))]
    password: String,
}

async fn create_user(
    State(db): State<DatabasePool>,
    Json(payload): Json<CreateUser>,
) -> Result<Json<User>, StatusCode> {
    payload.validate().map_err(|_| StatusCode::BAD_REQUEST)?;
    // ...
}
```

##### 7. Verification Automation

After creating all files, automatically run:

```bash
# Check file existence
test -f CLAUDE.md && echo "✅ CLAUDE.md created"
test -d .claude/rules && echo "✅ .claude/rules/ directory created"
test -f .cursor/rules/*.mdc && echo "✅ Cursor rules created"
test -f .github/copilot-instructions.md && echo "✅ GitHub Copilot rules created"

# Count lines
echo "CLAUDE.md: $(wc -l < CLAUDE.md) lines"
echo "Cursor: $(wc -l < .cursor/rules/*.mdc) lines"
echo "GitHub Copilot: $(wc -l < .github/copilot-instructions.md) lines"
```

##### 8. Generate Report Automatically

After completion, provide this report to user:

```markdown
## ✅ AI Agent Rules Created Successfully

### Files Created

**Claude Code**:
- ✅ CLAUDE.md ([N] lines)
- ✅ .claude/rules/backend-issue-documentation.md
- ✅ .claude/rules/code-style-detailed.md
- ✅ .claude/rules/implementation-checklist.md

**Cursor**:
- ✅ .cursor/rules/[project]-rules.mdc ([N] lines)
- ✅ .cursor/rules/detailed/ (3 files)

**GitHub Copilot**:
- ✅ .github/copilot-instructions.md ([N] lines)
- ✅ .github/copilot-rules/ (3 files)

**Google Gemini**:
- ✅ .gemini/styleguide.md ([N] lines)
- ✅ .gemini/rules/ (3 files)

### Optimization Results

- **Total main files**: [N] lines (optimized from estimated [N+40%])
- **Token savings**: ~[N] tokens per conversation
- **Critical rules**: [N] rules synchronized across all 4 agents

### Next Steps for You

1. **Review** the generated rules files
2. **Test** with each AI agent (ask them to generate code)
3. **Adjust** critical rules if needed
4. **Commit** to version control:
   ```bash
   git add CLAUDE.md .claude/ .cursor/ .github/ .gemini/
   git commit -m "Add optimized AI agent rules for all 4 agents (v1.0)"
   ```

### Verification Commands

```bash
# Verify all files exist
ls -la CLAUDE.md .claude/rules/ .cursor/rules/ .github/copilot-instructions.md .gemini/styleguide.md

# Test with Claude Code
# Open new conversation and ask: "What are our critical coding rules?"
```
```

#### Complete Automation Example: React Project

**User Input**:
```
Project: "TaskMaster"
Stack: "React + Express + MongoDB"
Platform: "macOS"
Critical Rules:
1. Use Redux Toolkit for state management
2. Use React Query for API calls
3. Use environment variables for configs
4. Always use TypeScript strict mode
5. Use React Hook Form for forms
6. Handle errors with error boundaries
Specialized: None
Agents: Claude Code, Cursor, GitHub Copilot, Google Gemini
```

**Your Automated Actions** (execute without asking):

1. ✅ Create `CLAUDE.md` with "TaskMaster" as title
2. ✅ Transform Rule 1 to Redux Toolkit code example
3. ✅ Transform Rule 2 to React Query code example
4. ✅ Generate architecture section for React + Express
5. ✅ Create 3 detailed files adapted for React/TypeScript
6. ✅ Replicate to Cursor, GitHub Copilot, and Gemini
7. ✅ Optimize all files to ~350-450 lines
8. ✅ Run verification commands
9. ✅ Generate completion report

**Result**: Complete optimized rules for TaskMaster project in ~2 minutes of AI agent work.

#### Error Handling During Automation

If errors occur, handle gracefully:

```python
try:
    create_rules_files(user_info)
except FileExistsError:
    # Ask user: "Rules files already exist. Overwrite? (yes/no)"
    if user_confirms:
        overwrite_files()
    else:
        merge_with_existing()
except InvalidTechStack:
    # Ask user: "I don't recognize '[stack]'. Please provide examples of critical rules for this stack."
except MissingCriticalInfo:
    # Ask user specific question for missing piece
```

**DO NOT stop execution for minor issues** - make reasonable assumptions and continue.

### Appendix F: Metrics & KPIs

**Track** effectiveness of optimized rules:

#### Token Efficiency

**Metric**: Tokens saved per conversation

**Formula**: (Old file tokens - New file tokens) × Conversations per day

**XP Trading Example**:
- Old: 3,500 tokens
- New: 2,100 tokens
- Savings: 1,400 tokens
- Conversations/day: 20
- **Daily savings**: 28,000 tokens

#### Code Quality

**Metric**: Critical rule violations per code review

**Measurement**:
- Before optimization: Count violations in AI-generated code
- After optimization: Count violations
- **Target**: 80% reduction

**XP Trading Example**:
- Before: 5 violations per 10 AI code suggestions
- After: 1 violation per 10 AI code suggestions
- **Improvement**: 80% reduction

#### Maintenance Time

**Metric**: Time to update rules across all agents

**Measurement**:
- Before optimization: Time to update 3 separate files manually
- After optimization: Time to update synchronized files
- **Target**: 50% reduction

**Example**:
- Before: 30 minutes (10 min per file)
- After: 15 minutes (synchronized updates)
- **Improvement**: 50% reduction

#### Developer Satisfaction

**Metric**: Survey results from developers

**Questions**:
1. How confident are you in AI-generated code? (1-5)
2. How often do you need to fix AI suggestions? (1-5)
3. How easy is it to understand project rules? (1-5)

**Target**: Improvement in all metrics post-optimization

---

## Conclusion

This methodology provides a systematic approach to optimizing AI agent rules across multiple assistants. By following the 4-step process, projects can achieve:

1. **Consistency**: All AI agents follow the same standards
2. **Efficiency**: Reduced token consumption, more context for actual work
3. **Maintainability**: Centralized updates, synchronized changes
4. **Quality**: Better AI-generated code, fewer violations

**Key Takeaways**:
- Start comprehensive, then optimize
- Synchronize first, optimize second
- Use imports/references for detailed content
- Maintain consistency across all agents
- Establish clear maintenance processes

**Next Steps**:
1. Apply methodology to your project
2. Track metrics (token savings, code quality)
3. Iterate and improve based on results
4. Share learnings with team

---

**Version**: 2.4 (Universal Edition - Existing Rules Detection) | **Date**: January 23, 2026 | **Author**: Claude Code | **License**: MIT (Reusable)

---

## 🚀 Quick Start for AI Agents

If you are an AI agent, jump to: [FOR AI AGENTS: Automated Implementation](#for-ai-agents-automated-implementation)

## 📖 Quick Start for Developers

1. **Read this file** to understand the methodology
2. **Provide your AI agent** with this file
3. **Answer one question** with your project info (name, stack, critical rules)
4. **Let AI agent create everything** automatically
5. **Review and test** the generated rules
6. **Commit to version control**

---

## 📚 References

- [Claude Code Official Documentation](https://code.claude.com/docs/en/settings)
- [CLAUDE.md Complete Guide](https://www.builder.io/blog/claude-md-guide)
- [Cursor Rules Documentation](https://docs.cursor.com/context/rules)
- [GitHub Copilot Custom Instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot)
- [GitHub Copilot Instructions Blog](https://github.blog/ai-and-ml/unlocking-the-full-power-of-copilot-code-review-master-your-instructions-files/)
