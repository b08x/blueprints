# Creating and Managing Blueprints

This guide shows practical patterns for creating, organizing, and managing blueprints in Blueprints by Sublayer.

---

## Table of Contents

1. [Overview](#overview)
2. [Basic Blueprint Creation](#basic-blueprint-creation)
3. [Advanced Patterns](#advanced-patterns)
4. [Bulk Operations](#bulk-operations)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Overview

Creating a blueprint means storing code with AI-generated or manual metadata. The system automatically:

- Generates a short name for your code
- Writes a description of what the code does
- Suggests relevant categories
- Creates vector embeddings for semantic search
- Deduplicates identical blueprints

### Blueprint Lifecycle

```
Write Code → Save as Blueprint → AI Generates Metadata → Indexed for Search
     ↓              ↓                      ↓                     ↓
Local         Database         Name + Description      Searchable Globally
             + Embedding       + Categories
```

---

## Basic Blueprint Creation

### Method 1: Web UI (Fastest for Learning)

Perfect for trying Blueprints for the first time.

**Step-by-Step:**

1. Open `http://localhost:3000` in your browser
2. Click **"New Blueprint"** button
3. Paste your code in the editor
4. Click **"Create"**
5. Watch AI generate metadata
6. Copy generated name/description if desired
7. Click **"Save"** to confirm

**Example: Greeting Function**

```ruby
def greet(name)
  "Hello, #{name}!"
end
```

**AI-Generated Result:**
```
Name: Greeting Method
Description: A simple method that generates greeting messages for given names
Categories: Ruby, Functions, Output
Embedding: [0.234, -0.189, ..., 0.456] (1536 dimensions)
```

### Method 2: REST API (For Automation)

Use when integrating with scripts or other systems.

**Basic Example:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def greet(name)\n  \"Hello, #{name}!\"\nend"
  }'
```

**Response:**

```json
{
  "id": 1,
  "name": "Greeting Method",
  "description": "A simple method that generates greeting messages for given names",
  "code": "def greet(name)\n  \"Hello, #{name}!\"\nend",
  "categories": ["Ruby", "Functions", "Output"],
  "embedding_dimension": 1536,
  "created_at": "2025-10-26T10:30:00Z",
  "updated_at": "2025-10-26T10:30:00Z"
}
```

### Method 3: Editor Plugin (Most Convenient)

Integrate Blueprints directly into your workflow.

**VSCode Example:**

1. Highlight code you want to save
2. Press `Cmd+Shift+B` (Mac) or `Ctrl+Shift+B` (Windows)
3. Blueprint is created automatically
4. Continue working - no context switching

**Vim Example:**

```vim
" Visual select code
:BlueprintSave
" Blueprint created silently
```

**IntelliJ Example:**

1. Right-click selected code
2. Choose "Blueprints → Save as Blueprint"
3. View confirmation notification

---

## Advanced Patterns

### Pattern 1: Create with Custom Description

Override AI-generated description with your own.

**Why?** The AI-generated description might be too generic or miss important context.

**Example:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "class UserMailer < ApplicationMailer\n  def welcome_email(user)\n    mail(to: user.email, subject: \"Welcome!\")\n  end\nend",
    "description": "Sends welcome email to new users with onboarding content and company logo"
  }'
```

**When to use:**
- Description needs specific business context
- Standard patterns that benefit from custom categorization
- Code with non-obvious purpose

### Pattern 2: Create with Custom Categories

Organize blueprints for your team's workflow.

**Example:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def validate_email(email)\n  email.match?(/\\A[\\w+\\-.]+@[a-z\\d\\-]+(\\.[a-z\\d\\-]+)*\\.[a-z]+\\z/i)\nend",
    "description": "Validates email format using regex pattern",
    "categories": ["Validation", "Email", "Production-Ready", "Team:Billing"]
  }'
```

**Naming conventions:**
- Use domain-specific terms (not generic "Utility")
- Include "Team:" prefix for team-specific organization
- Use "Status:" for maturity (e.g., "Status:Deprecated")

### Pattern 3: Update Existing Blueprint

Modify code without creating a duplicate.

**When to use:**
- Bug fixes for existing patterns
- Performance optimizations
- Refactoring patterns

**Example:**

```bash
# Get blueprint ID first
curl http://localhost:3000/api/v1/blueprints | grep "id"

# Update blueprint
curl -X PATCH http://localhost:3000/api/v1/blueprints/42 \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def greet(name)\n  \"Hello, #{name.capitalize}!\"\nend",
    "description": "Greeting method with capitalized names"
  }'
```

**What gets updated:**
- Code (new embedding generated automatically)
- Description (manual or re-generated)
- Categories (manual specification)

**What stays the same:**
- ID
- Created timestamp

### Pattern 4: Create Private/Team Blueprints

Use naming conventions to organize by team or project.

**Example:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def internal_audit_log(action, user_id)\n  AuditLog.create(action: action, user_id: user_id, timestamp: Time.now)\nend",
    "description": "Internal audit logging - Billing team only",
    "categories": ["Team:Billing", "Internal", "Audit", "Security"]
  }'
```

**Searching later:**
```bash
# Find team-specific blueprints
curl "http://localhost:3000/api/v1/blueprints?query=Team:Billing"
```

### Pattern 5: Clone and Adapt

Create variants of existing blueprints with custom names.

**Rails Mailer Example:**

**Original Blueprint:**
```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    mail(to: user.email, subject: "Welcome!")
  end
end
```

**Create Admin Mailer Blueprint:**
```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "class AdminMailer < ApplicationMailer\n  def admin_notification(admin, message)\n    mail(to: admin.email, subject: \"Admin Alert: #{message}\")\n  end\nend",
    "description": "Sends administrative notifications with alert context",
    "categories": ["Rails", "Mailer", "Admin", "Notifications"]
  }'
```

---

## Bulk Operations

### Pattern 1: Batch Import from File

Import multiple blueprints from a YAML or JSON file.

**YAML Format (blueprints.yml):**

```yaml
blueprints:
  - name: Welcome Email Mailer
    code: |
      class UserMailer < ApplicationMailer
        def welcome_email(user)
          mail(to: user.email, subject: "Welcome!")
        end
      end
    categories:
      - Rails
      - Mailer
      - Email

  - name: Admin Audit Logger
    code: |
      def log_admin_action(action, admin_id)
        AdminAuditLog.create(action: action, admin_id: admin_id)
      end
    categories:
      - Rails
      - Admin
      - Audit
      - Security
```

**Import Script (Ruby):**

```ruby
#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'yaml'

blueprints_data = YAML.load_file('blueprints.yml')

blueprints_data['blueprints'].each do |bp|
  uri = URI('http://localhost:3000/api/v1/blueprints')
  http = Net::HTTP.new(uri.host, uri.port)

  request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
  request.body = {
    code: bp['code'],
    description: bp['description'],
    categories: bp['categories']
  }.to_json

  response = http.request(request)

  if response.code == '201'
    data = JSON.parse(response.body)
    puts "Created: #{data['name']} (ID: #{data['id']})"
  else
    puts "Error: #{bp['name']} - #{response.body}"
  end
end
```

**Run the import:**

```bash
ruby import_blueprints.rb
```

### Pattern 2: Export All Blueprints

Create a backup or share blueprints with your team.

**Bash Script:**

```bash
#!/bin/bash

# Get all blueprints
blueprints=$(curl -s http://localhost:3000/api/v1/blueprints?per_page=1000)

# Save to JSON
echo "$blueprints" | jq '.blueprints' > blueprints_backup.json

# Count
count=$(echo "$blueprints" | jq '.blueprints | length')
echo "Exported $count blueprints to blueprints_backup.json"
```

**Export with code:**

```bash
curl -s http://localhost:3000/api/v1/blueprints?per_page=1000 | \
  jq '.blueprints[] | {name, description, code, categories}' > blueprints_data.json
```

### Pattern 3: Bulk Delete by Category

Remove outdated blueprints.

**Example: Delete Deprecated Blueprints**

```bash
#!/bin/bash

# Get IDs of blueprints with "Status:Deprecated"
blueprints=$(curl -s "http://localhost:3000/api/v1/blueprints?query=Status:Deprecated")

# Delete each
echo "$blueprints" | jq -r '.blueprints[].id' | while read id; do
  curl -X DELETE "http://localhost:3000/api/v1/blueprints/$id"
  echo "Deleted blueprint $id"
done
```

### Pattern 4: Sync Multiple Instances

Keep blueprints synchronized across development, staging, and production.

**Sync Script:**

```bash
#!/bin/bash

SOURCE="http://dev-blueprints:3000"
DEST="http://prod-blueprints:3000"

# Get all blueprints from source
blueprints=$(curl -s "$SOURCE/api/v1/blueprints?per_page=1000")

# Create in destination
echo "$blueprints" | jq -c '.blueprints[]' | while read bp; do
  code=$(echo "$bp" | jq -r '.code')
  desc=$(echo "$bp" | jq -r '.description')
  cats=$(echo "$bp" | jq -r '.categories | @json')

  curl -X POST "$DEST/api/v1/blueprints" \
    -H "Content-Type: application/json" \
    -d "{\"code\": $code, \"description\": $desc, \"categories\": $cats}"
done

echo "Sync complete!"
```

---

## Best Practices

### DO

✅ **Keep code samples focused**
- One concept per blueprint
- 5-50 lines is ideal
- Too large: refactor into multiple blueprints

✅ **Use descriptive custom names**
- "User Email Validation" (good)
- "Util 1" (bad)
- AI generates names, but you can improve them

✅ **Organize with consistent categories**
- Establish team standards
- Use "Team:" prefix for team-specific blueprints
- Use "Status:" for maturity levels

✅ **Include context in descriptions**
- What does it do?
- When would you use it?
- What are the prerequisites?

✅ **Save patterns, not implementations**
- Save the pattern (authentication logic)
- Don't save exact production code with secrets

### DON'T

❌ **Don't save secrets or credentials**
- Remove API keys before saving
- Remove database passwords
- Remove private tokens

❌ **Don't save entire applications**
- Save individual patterns
- Break into focused blueprints
- Use variants for adaptations

❌ **Don't duplicate similar patterns**
- Search first (semantic search catches variations)
- Update existing blueprints instead

❌ **Don't ignore AI-generated metadata**
- Read the AI description
- Improve if it's inaccurate
- Learn from AI suggestions

### Best Practice Examples

**Pattern: Email Mailer**

```ruby
# Good: Focused pattern
class UserMailer < ApplicationMailer
  def welcome_email(user)
    mail(to: user.email, subject: "Welcome!")
  end
end

# Bad: Too much code
class UserMailer < ApplicationMailer
  def welcome_email(user); ... end
  def password_reset_email(user); ... end
  def two_factor_email(user); ... end
  # 200 more lines
end
```

**Pattern: Validation Logic**

```ruby
# Good: Clear pattern
def validate_email(email)
  email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
end

# Bad: Too abstract
def validate_data(data)
  # validation logic
end
```

---

## Troubleshooting

### Issue: Blueprint Creation Takes Too Long

**Symptoms:** Request takes 2-3 seconds to complete

**Cause:** AI generation and embedding creation takes time

**Solution:**
- This is normal for first-time creation
- Subsequent operations are faster
- Consider batching imports during off-peak hours

**Code:**
```bash
# Monitor request time
time curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{"code": "..."}'
```

### Issue: Duplicate Blueprint Error

**Symptoms:**
```json
{
  "error": "Validation failed: composite key already exists",
  "error_code": "VALIDATION_ERROR"
}
```

**Cause:** Blueprint with same (name, description, code) exists

**Solution:**
- Modify the code slightly (formatting, comment)
- Or update the existing blueprint instead

**Check for duplicates:**
```bash
curl "http://localhost:3000/api/v1/blueprints?query=def+validate"
```

### Issue: AI Description is Generic

**Symptoms:** AI generates vague description like "Ruby method definition"

**Solution:** Provide a custom description

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def validate_email(email)...",
    "description": "Validates RFC 5322-compliant email addresses with regex"
  }'
```

### Issue: Categories Don't Match My Needs

**Symptoms:** AI suggests generic categories

**Solution:** Override with custom categories

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "...",
    "categories": ["Team:Backend", "Validation", "Production-Ready", "Status:Stable"]
  }'
```

### Issue: Can't Find Newly Created Blueprint

**Symptoms:** Search doesn't return recent blueprint

**Solution:** Give embedding generation time to complete

```bash
# Wait 2-3 seconds after creation
sleep 3

# Then search
curl "http://localhost:3000/api/v1/blueprints?query=your+code+description"
```

### Issue: API Returns 500 Error

**Symptoms:**
```json
{
  "error": "Internal server error",
  "error_code": "SERVER_ERROR",
  "request_id": "abc123"
}
```

**Solutions:**
1. Check that PostgreSQL is running
2. Verify pgvector extension is installed
3. Check that AI provider API key is valid
4. Review Rails logs: `tail -f log/development.log`

**Check API key validity:**
```bash
# Verify environment variable is set
echo $GEMINI_API_KEY  # or $OPENAI_API_KEY

# Or check .env file
cat .env | grep API_KEY
```

---

## Related Guides

- **[Generating Variants](generating_variants.md)** - Create new code from existing blueprints
- **[Editor Integration](editor_integration.md)** - Use plugins to save blueprints from your IDE
- **[REST API Reference](../api/REST_API.md)** - Complete API documentation
- **[Quick Start Guide](../api/QUICK_START.md)** - Initial setup and configuration

---

**Next Step:** Ready to generate code variants? See [Generating Variants](generating_variants.md).
