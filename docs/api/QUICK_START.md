# Quick Start Guide - Blueprints by Sublayer

**Version:** 1.0
**Last Updated:** 2025-10-26
**Target Audience:** Developers wanting to get productive in 15 minutes

---

## Get Started in 5 Minutes

### Step 1: Installation (2 minutes)

**Prerequisites**
```bash
# Check Ruby version (3.2.0+)
ruby --version

# Check if PostgreSQL is installed
psql --version

# Check if pgvector is available
psql -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

**Clone and Setup**
```bash
# Clone the repository
git clone https://github.com/sublayerapp/blueprints
cd blueprints

# Install dependencies
bundle install

# Setup database
bin/rails db:create
bin/rails db:migrate

# Precompile assets (Tailwind CSS)
bin/rails tailwindcss:build
```

### Step 2: Configure API Keys (1 minute)

**Choose Your AI Provider**

**Option A: Google Gemini (Free Tier)**
```bash
# Get free API key at https://ai.google.dev

# Set environment variable
export GEMINI_API_KEY="AIzaSy..."

# Or add to .env file
echo "GEMINI_API_KEY=AIzaSy..." >> .env
```

**Option B: OpenAI (Paid)**
```bash
# Get API key at https://platform.openai.com/api-keys

export OPENAI_API_KEY="sk-..."
```

**Verify Configuration**
```ruby
# Start Rails console
bin/rails console

# Test API key
Sublayer.configuration.ai_provider
# => Sublayer::Providers::Gemini (or OpenAI)
```

### Step 3: Start the Server (2 minutes)

```bash
# Start Rails development server
bin/rails server

# Server running at http://localhost:3000
# Visit in browser
```

### Step 4: Create Your First Blueprint (1 minute)

**Via Web UI**
1. Navigate to http://localhost:3000
2. Click "New Blueprint"
3. Paste Ruby code:
   ```ruby
   def greet(name)
     "Hello, #{name}!"
   end
   ```
4. Click "Create"
5. Watch as AI generates:
   - **Name:** "Greeting Method"
   - **Description:** "A simple method that generates greeting messages for given names"
   - **Categories:** Ruby, Functions, Output

**Via API**
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
  "description": "A simple method that generates greeting messages...",
  "code": "def greet(name)\n  \"Hello, #{name}!\"\nend",
  "categories": ["Ruby", "Functions", "Output"],
  "created_at": "2025-10-26T15:30:00Z"
}
```

---

## Next Steps (10 minutes)

### Generate Your First Variant

Blueprints can generate variations of your code using semantic similarity.

**Step 1: Create a Base Blueprint**
```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def sum_array(arr)\n  arr.reduce(0) { |acc, x| acc + x }\nend"
  }'
```

**Step 2: Generate a Variant**
Ask for code that does something similar but different:

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Calculate the product of all numbers in an array"
  }'
```

**Response:**
```json
{
  "result": "def product_array(arr)\n  arr.reduce(1) { |acc, x| acc * x }\nend",
  "source_blueprint": {
    "id": 1,
    "name": "Array Sum Method",
    "similarity_score": 0.89
  }
}
```

The AI found the most similar blueprint (sum_array) and used it as a pattern to generate product_array.

---

## Common Workflows

### Workflow 1: Save Your Best Code Patterns

**Problem:** You have good code snippets scattered across projects

**Solution:** Store as blueprints for reuse

```bash
# Save a database migration pattern
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "class CreateUsers < ActiveRecord::Migration[7.1]\n  def change\n    create_table :users do |t|\n      t.string :name\n      t.string :email\n      t.timestamps\n    end\n  end\nend"
  }'

# Later: Generate variant for different table
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{"description": "Create products table with name, price, and inventory"}'

# AI generates:
# class CreateProducts < ActiveRecord::Migration[7.1]
#   def change
#     create_table :products do |t|
#       t.string :name
#       t.decimal :price
#       t.integer :inventory
#       t.timestamps
#     end
#   end
# end
```

### Workflow 2: Learn from Patterns

**Problem:** New team member wants to learn coding patterns

**Solution:** Browse blueprints and use them as examples

```bash
# View all Rails patterns
curl "http://localhost:3000/api/v1/blueprints?category=Rails"

# Search semantically
curl "http://localhost:3000/api/v1/blueprints?search=handle%20authentication"

# Get specific blueprint
curl http://localhost:3000/api/v1/blueprints/1
```

### Workflow 3: Accelerate Development

**Problem:** Writing boilerplate code takes time

**Solution:** Generate variants from stored patterns

```bash
# 1. Create a base pattern once
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "class UsersController < ApplicationController\n  def index\n    @users = User.all\n    render json: @users\n  end\nend"
  }'

# 2. Generate variants for other resources
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{"description": "Create a products controller with index action returning JSON"}'

# 3. Generate more variants
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{"description": "Create a categories controller with index action"}'

# Each takes ~2-3 seconds, saves 5+ minutes of manual coding
```

---

## Integration with Your Editor

### VS Code Extension (Planned)

```bash
# Install extension (coming soon)
code --install-extension sublayerapp.blueprints

# Usage:
# 1. Select code in editor
# 2. Press Ctrl+Shift+B to save as blueprint
# 3. Type description
# 4. Press Ctrl+Shift+G to generate variant
```

### Vim Plugin (Planned)

```vim
" In .vimrc
Plug 'sublayerapp/blueprints.vim'

" Usage:
" Select code in visual mode
" :BlueprintCreate
" :BlueprintGenerate "description"
```

### Manual: Save Code Snippets

Until editor plugins are available, save to database manually:

```ruby
# In Rails console
code = %{
  def process_users(users)
    users.select { |u| u.active? }
         .map { |u| u.email }
         .uniq
  end
}

blueprint = Blueprint.create!(
  code: code,
  description: "Filter active users and get their unique emails"
)

puts "Created blueprint ##{blueprint.id}: #{blueprint.name}"
```

---

## Common Tasks

### Task 1: Search for Blueprints

```bash
# Simple search
curl "http://localhost:3000/api/v1/blueprints?search=authentication"

# Filter by category
curl "http://localhost:3000/api/v1/blueprints?category=Rails"

# Combine filters
curl "http://localhost:3000/api/v1/blueprints?search=auth&category=security"

# Paginate results
curl "http://localhost:3000/api/v1/blueprints?limit=10&offset=20"
```

### Task 2: View Blueprint Details

```bash
# Get specific blueprint
curl http://localhost:3000/api/v1/blueprints/42

# Response includes:
# - Code
# - Description
# - Categories
# - Timestamps
```

### Task 3: Update Blueprint

```bash
# Update description and name
curl -X PATCH http://localhost:3000/api/v1/blueprints/42 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "User Authentication with JWT",
    "description": "Authenticates users using JWT tokens with refresh"
  }'
```

### Task 4: Delete Blueprint

```bash
# Delete blueprint (removes associations too)
curl -X DELETE http://localhost:3000/api/v1/blueprints/42
```

---

## Troubleshooting

### Issue: "cannot load such file -- phlex/rails"

**Solution:** Bundle wasn't installed correctly
```bash
rm Gemfile.lock
bundle install
```

### Issue: "could not find PostgreSQL"

**Solution:** Install PostgreSQL
```bash
# macOS
brew install postgresql

# Linux (Ubuntu)
sudo apt-get install postgresql postgresql-contrib

# Windows
# Download from https://www.postgresql.org/download/windows/
```

### Issue: "ERROR: extension vector not found"

**Solution:** Install pgvector extension
```bash
# macOS
brew install pgvector

# Or enable in database
psql
CREATE EXTENSION vector;
```

### Issue: API returns 504 (Timeout)

**Solution:** LLM API is slow - try with smaller code
```bash
# Before: 50+ line file → Timeout
# After: <20 lines → Works

# Or: Use Gemini (faster) instead of GPT-4
```

### Issue: Duplicate blueprint error

**Solution:** You already have this exact code
```bash
# Check existing blueprints
curl "http://localhost:3000/api/v1/blueprints?search=hello"

# Provide different description or code
```

---

## Performance Expectations

### Response Times

| Operation | Min | Average | Max |
|-----------|-----|---------|-----|
| List blueprints | 50ms | 100ms | 200ms |
| Create blueprint (no AI) | 100ms | 200ms | 500ms |
| Create blueprint (with AI) | 2s | 5s | 10s |
| Generate variant | 2s | 4s | 8s |
| Search/filter | 50ms | 150ms | 300ms |

**Times are for development environment.** Production will be faster with proper caching.

### Cost Expectations

**Using Gemini Flash (Free):**
- Per blueprint: ~$0.00008 (3-4 LLM calls)
- 1,000 blueprints: ~$0.08/month
- 100,000 blueprints: ~$8/month

**Using OpenAI GPT-4:**
- Per blueprint: ~$0.025
- 1,000 blueprints: ~$25/month
- 100,000 blueprints: ~$2,500/month

---

## Next Level: Advanced Usage

### Use Vector Search

```bash
# Find blueprints similar to a description
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Validate email addresses"
  }' | jq '.source_blueprint'

# This shows:
# - Most similar blueprint
# - Similarity score (0-1)
# - Which blueprint will be used as pattern
```

### Batch Import

```ruby
# Import multiple blueprints at once
blueprints_data = [
  { code: "def...", description: "...", name: "..." },
  { code: "def...", description: "...", name: "..." },
]

blueprints_data.each do |data|
  Blueprint.create!(data)
end
```

### API Key Authentication (Production)

```bash
# Add to .env
API_KEY=your-secret-key

# Use in requests
curl -X GET http://localhost:3000/api/v1/blueprints \
  -H "X-API-Key: your-secret-key"
```

---

## Learning Resources

### Documentation
- **REST API:** `/docs/api/REST_API.md` - Complete endpoint reference
- **Data Models:** `/docs/api/MODELS.md` - Blueprint and Category models
- **Components:** `/docs/api/COMPONENTS.md` - Phlex UI components
- **Technical Architecture:** `/docs/technical/ARCHITECTURE.md` - Deep dive

### Code Examples
- **JavaScript:** `/examples/javascript/`
- **Python:** `/examples/python/`
- **Ruby:** `/examples/ruby/`

### Community
- GitHub Issues: Report bugs and request features
- Discussions: Share blueprints and use cases
- Contributing Guide: Help improve Blueprints

---

## Checklist: Ready to Use Blueprints

- [ ] Ruby 3.2+ installed
- [ ] PostgreSQL installed and running
- [ ] pgvector extension enabled
- [ ] Repository cloned
- [ ] Dependencies installed (`bundle install`)
- [ ] Database created and migrated
- [ ] API key configured (Gemini or OpenAI)
- [ ] Server started (`bin/rails server`)
- [ ] First blueprint created
- [ ] Generated first variant

**Congratulations!** You're ready to use Blueprints.

---

## Time Estimates

| Task | Time |
|------|------|
| Installation | 2 min |
| Configure API key | 1 min |
| Create first blueprint | 1 min |
| Generate variant | 1 min |
| Explore UI | 5 min |
| **Total** | **10 min** |

**You should be productive with Blueprints in under 15 minutes.**

---

## What's Next?

1. **Read REST API docs** (`/docs/api/REST_API.md`)
   - Learn all available endpoints
   - Understand response formats
   - See integration examples

2. **Explore Data Models** (`/docs/api/MODELS.md`)
   - Understand Blueprint and Category models
   - Learn how to query and filter
   - See factory examples for testing

3. **Review Components** (`/docs/api/COMPONENTS.md`)
   - See reusable UI components
   - Learn Phlex patterns
   - Build custom components

4. **Deep Dive Technical** (`/docs/technical/ARCHITECTURE.md`)
   - Understand system architecture
   - See performance characteristics
   - Learn scaling strategies

---

## Getting Help

**Have questions?**

1. Check the **Troubleshooting** section above
2. Read relevant documentation file
3. Search existing GitHub issues
4. Create new issue with details:
   - What you were trying to do
   - Error message
   - Steps to reproduce

**Have ideas for features?**

- Open a GitHub discussion
- Share use cases you're discovering
- Vote on requested features

---

**Document Version:** 1.0
**Source:** `/home/b08x/Workspace/RubyAI/blueprints/docs/api/QUICK_START.md`
**Last Reviewed:** 2025-10-26

Good luck with Blueprints! Happy coding!
