# Generating Code Variants with AI

Learn how to generate new code based on existing blueprints using semantic similarity and large language model prompting.

---

## Table of Contents

1. [Overview](#overview)
2. [How Variant Generation Works](#how-variant-generation-works)
3. [Basic Variant Generation](#basic-variant-generation)
4. [Advanced Patterns](#advanced-patterns)
5. [Prompt Engineering Tips](#prompt-engineering-tips)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Overview

Variant generation is the most powerful feature of Blueprints. It lets you:

1. **Describe what you want** in natural language
2. **Find similar code** in your blueprints using semantic search
3. **Generate new code** based on that pattern
4. **Get production-ready code** adapted to your needs

### Why This Works

Traditional code search is keyword-based:
```
Search "email sending" → finds "mail", "send", "email" literals
Problem: Misses "dispatch_message" or "notify_user"
```

Blueprints uses semantic similarity:
```
Search "notify user via email" → finds similar concepts
Result: Finds "UserMailer.welcome_email", "send_notification", etc.
Problem solved: Semantic meaning, not keywords
```

---

## How Variant Generation Works

### The Three-Step Process

```
Step 1: Encode Your Description
   Input: "Admin welcome email with privileges"
   → Vector embedding: [0.234, -0.189, ..., 0.456]

Step 2: Find Similar Blueprints
   Compare to existing vectors using cosine distance
   → Best match: UserMailer.welcome_email (blueprint ID: 42)

Step 3: Generate Variant
   Prompt LLM: "Adapt this code for admin welcome email"
   → Generated code: AdminMailer.welcome_email
```

### Response Time Expectations

| Component | Time |
|-----------|------|
| Encode description to vector | 100-200ms |
| Search similar blueprints | 15-50ms |
| LLM generation | 800-1500ms |
| **Total** | **1.5-2.2 seconds** |

---

## Basic Variant Generation

### Example 1: Email Mailer Variant

**Existing Blueprint in System:**

```ruby
class UserMailer < ApplicationMailer
  def welcome_email(user)
    mail(to: user.email, subject: "Welcome to Blueprints!")
  end
end
```

**Generate Admin Notification Email:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Admin notification email for system alerts with priority level"
  }'
```

**Expected Generated Code:**

```ruby
class AdminMailer < ApplicationMailer
  def alert_notification(admin, message, priority = :medium)
    @message = message
    @priority = priority
    mail(to: admin.email, subject: "Alert [#{priority.upcase}]: #{message}")
  end
end
```

**What the AI did:**
- Found the UserMailer pattern (semantic similarity)
- Changed recipient from user to admin
- Added priority level parameter
- Adjusted subject line for alerts
- Maintained the same architecture

### Example 2: Validation Logic Variant

**Existing Blueprint:**

```ruby
def validate_email(email)
  email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
end
```

**Generate Phone Validation:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Validate phone numbers for US format (10 digits or +1)"
  }'
```

**Expected Generated Code:**

```ruby
def validate_us_phone(phone)
  phone.match?(/\A\+?1?[-.\s]?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\z/)
end
```

### Example 3: Database Query Variant

**Existing Blueprint:**

```ruby
def active_users
  User.where(status: 'active').order(created_at: :desc)
end
```

**Generate Similar Queries:**

```bash
# Variant 1: Recently updated users
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Find users who updated their profile in the last 7 days"
  }'

# Expected:
# def recently_updated_users
#   User.where('updated_at > ?', 7.days.ago).order(updated_at: :desc)
# end
```

```bash
# Variant 2: Premium users
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Get all active premium users sorted by registration date"
  }'

# Expected:
# def premium_active_users
#   User.where(status: 'active', plan: 'premium').order(created_at: :desc)
# end
```

---

## Advanced Patterns

### Pattern 1: Complex Adaptation with Context

**Scenario:** You have a payment processing method and need a refund variant.

**Existing Blueprint:**

```ruby
def process_payment(user, amount)
  gateway = PaymentGateway.new(user.payment_method)
  transaction = gateway.charge(amount)

  Transaction.create(
    user_id: user.id,
    amount: amount,
    status: transaction.success? ? 'completed' : 'failed'
  )

  transaction.success?
end
```

**Generate Refund Logic:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Process refund for a transaction with partial refund support and notification"
  }'
```

**Generated Code:**

```ruby
def process_refund(user, transaction_id, refund_amount = nil)
  transaction = Transaction.find(transaction_id)
  refund_amount ||= transaction.amount

  gateway = PaymentGateway.new(user.payment_method)
  refund = gateway.refund(transaction_id, refund_amount)

  if refund.success?
    transaction.update(status: 'refunded', refunded_amount: refund_amount)
    UserMailer.refund_confirmation(user, refund_amount).deliver_later
    true
  else
    false
  end
end
```

### Pattern 2: Transform Between Frameworks

**Scenario:** Generate a Sinatra controller from a Rails controller pattern.

**Existing Blueprint (Rails):**

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    render :show
  end

  def create
    @article = Article.create(article_params)
    redirect_to @article
  end

  private

  def article_params
    params.require(:article).permit(:title, :content)
  end
end
```

**Generate Sinatra Version:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Sinatra-style HTTP handlers for articles API returning JSON"
  }'
```

**Generated Code:**

```ruby
require 'sinatra'

get '/articles/:id' do
  article = Article.find(params[:id])
  article.to_json
end

post '/articles' do
  request.body.rewind
  data = JSON.parse(request.body.read)
  article = Article.create(
    title: data['title'],
    content: data['content']
  )
  article.to_json
end
```

### Pattern 3: Add Cross-Cutting Concerns

**Scenario:** Add error handling, logging, and validation to existing method.

**Existing Blueprint:**

```ruby
def send_notification(user, message)
  Email.deliver(user.email, message)
end
```

**Generate with Error Handling:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Send notification with retry logic, error handling, and activity logging"
  }'
```

**Generated Code:**

```ruby
def send_notification(user, message, max_retries = 3)
  retries = 0

  begin
    Email.deliver(user.email, message)
    ActivityLog.create(user_id: user.id, action: 'notification_sent')
  rescue StandardError => e
    retries += 1
    if retries <= max_retries
      sleep(2 ** retries)  # Exponential backoff
      retry
    else
      ActivityLog.create(user_id: user.id, action: 'notification_failed', error: e.message)
      raise
    end
  end
end
```

### Pattern 4: Database Optimization

**Existing Blueprint:**

```ruby
def user_orders_total
  user.orders.map(&:total).sum
end
```

**Generate Optimized Version:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Calculate total user orders efficiently with database aggregation and caching"
  }'
```

**Generated Code:**

```ruby
def user_orders_total(user, force_refresh = false)
  cache_key = "user_#{user.id}_orders_total"

  return Rails.cache.read(cache_key) if !force_refresh && Rails.cache.exist?(cache_key)

  total = user.orders.sum('total')
  Rails.cache.write(cache_key, total, expires_in: 1.hour)

  total
end
```

### Pattern 5: Batch Operations

**Existing Blueprint:**

```ruby
def send_welcome_email(user)
  UserMailer.welcome_email(user).deliver_now
end
```

**Generate Bulk Version:**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Send welcome emails to multiple users asynchronously with batch processing"
  }'
```

**Generated Code:**

```ruby
def send_bulk_welcome_emails(users, batch_size = 100)
  users.each_slice(batch_size) do |batch|
    batch.each do |user|
      UserMailer.welcome_email(user).deliver_later
    end

    sleep(1)  # Rate limiting
  end
end
```

---

## Prompt Engineering Tips

### Tip 1: Be Specific About Your Needs

```bash
# Bad: Too vague
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -d '{"description": "Similar function"}'

# Good: Specific and clear
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -d '{"description": "Validate international phone numbers with country code support"}'
```

**Why:** Vague prompts result in generic code. Specific descriptions guide the LLM better.

### Tip 2: Include Context About Use Case

```bash
# Less helpful
"User authentication method"

# More helpful
"OAuth2 authentication for third-party API integration with token refresh"
```

### Tip 3: Mention Constraints and Requirements

```bash
# Bad
"Database query for users"

# Good
"Efficient database query for active users using HNSW index with pagination"
```

**Include:**
- Performance requirements (fast, low memory)
- Technology constraints (PostgreSQL, Redis)
- Functional requirements (pagination, filtering)

### Tip 4: Reference Patterns if Similar

```bash
# Less effective
"Email validation"

# More effective
"Email validation similar to the existing regex pattern but supporting new TLDs"
```

### Tip 5: Specify Output Format

```bash
# Vague
"Generate a API endpoint"

# Clear
"REST endpoint for retrieving user profile data returning JSON with status codes"
```

### Tip 6: Use Action Words

**Better prompt patterns:**

- "Transform X into Y"
- "Add error handling to X"
- "Optimize X for performance"
- "Convert X to use Y library"
- "Create a Y version of X"
- "Refactor X to be more maintainable"

**Examples:**

```bash
# Transform
"Transform Rails controller to Sinatra route handler"

# Add concern
"Add rate limiting to API endpoint"

# Optimize
"Optimize database query with proper indexing"

# Convert
"Convert callback-based authentication to async/await style"

# Create variant
"Create async job version of synchronous processing method"

# Refactor
"Refactor deeply nested conditionals into guard clauses"
```

---

## Best Practices

### DO

✅ **Start with good blueprint base**
- Quality blueprints → quality variants
- Save multiple patterns for comparison

✅ **Review generated code before using**
- Check for security issues
- Verify it follows your patterns
- Test before deploying

✅ **Use variants for learning**
- See how patterns adapt
- Understand code design better
- Discover new approaches

✅ **Iterate if first variant isn't perfect**
- Refine your description
- Try different prompts
- Combine with other approaches

✅ **Save successful variants as new blueprints**
- Build your blueprint library
- Create team knowledge base
- Improve future generations

### DON'T

❌ **Don't blindly trust generated code**
- AI can make mistakes
- Always review security
- Test thoroughly

❌ **Don't generate without understanding the base**
- Know what blueprint it's adapting from
- Understand why that pattern was chosen
- Learn from the example

❌ **Don't use for complex domain logic**
- Variants work best for infrastructure patterns
- Avoid for business-critical calculations
- Always verify math and logic

❌ **Don't forget to test**
- Generated code needs testing
- Add unit tests
- Check edge cases

### Workflow Example: Complete End-to-End

**Step 1: Find or Create Base Blueprint**

```bash
# Search for email patterns
curl "http://localhost:3000/api/v1/blueprints?query=welcome+email"
```

**Step 2: Study the Blueprint**

- Read the code
- Understand its structure
- Note important patterns

**Step 3: Generate Variant**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Password reset email with secure token link"
  }'
```

**Step 4: Review Generated Code**

- Check structure makes sense
- Verify security (tokens, links, headers)
- Review for potential bugs

**Step 5: Test the Code**

```ruby
# In test file
def test_password_reset_email
  user = create(:user)
  reset_token = user.generate_reset_token

  email = UserMailer.password_reset_email(user, reset_token)
  assert_equal user.email, email.to.first
  assert_includes email.body.encoded, reset_token
end
```

**Step 6: Adapt if Needed**

- Fix any issues
- Add your customizations
- Ensure it matches your code style

**Step 7: Save as New Blueprint**

```bash
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "# Your tested and refined code",
    "description": "Password reset email mailer with secure token handling",
    "categories": ["Email", "Security", "User", "Production-Ready"]
  }'
```

---

## Troubleshooting

### Issue: Generated Code is Too Generic

**Symptoms:** Code doesn't match your needs

**Solution:** Be more specific in description

```bash
# Before (too generic)
"Email notification"

# After (specific)
"Payment receipt email with itemized charges, tax, and download link"
```

### Issue: Generated Code Doesn't Match Your Style

**Symptoms:** Uses different patterns than your codebase

**Solution:** Save a stylized blueprint first

1. Create a blueprint that matches your team's style
2. Ensure it's well-documented
3. Use it as the base for variants

```bash
# Save your style guide as a blueprint
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "# Your canonical code style example",
    "description": "Team style guide - error handling with guard clauses, explicit types, comprehensive logging",
    "categories": ["Style:Guide", "Internal", "Team:Backend"]
  }'
```

### Issue: Can't Find Good Base Blueprint

**Symptoms:** Search returns nothing useful

**Solution:**
1. Create blueprints first
2. Or search more broadly
3. Start with a simple pattern

```bash
# Search broadly
curl "http://localhost:3000/api/v1/blueprints?query=mail"
curl "http://localhost:3000/api/v1/blueprints?query=email"

# Browse all categories
curl "http://localhost:3000/api/v1/blueprints?page=1&per_page=50"
```

### Issue: LLM Generates Incomplete Code

**Symptoms:** Generated code has `...` or truncated methods

**Solution:**
- Simplify the description
- Request smaller scope
- Try a different LLM provider (see AI_GENERATORS.md)

```bash
# More specific scope
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "User email validation using regex only, no external libraries"
  }'
```

### Issue: Generated Code Has Security Issues

**Symptoms:** SQL injection, XSS, or auth problems

**Solution:**
1. Never use generated code without review
2. Add explicit security requirements to prompt
3. Save secure blueprint as reference

```bash
# Explicit security requirements
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Parameterized database query preventing SQL injection, sanitize all user inputs"
  }'
```

### Issue: Generated Code Uses Wrong Library

**Symptoms:** Code uses Rails methods but you're in Sinatra

**Solution:** Reference the framework in your description

```bash
# Include framework context
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Sinatra route handler for user API returning JSON, use Sinatra helpers only"
  }'
```

---

## Advanced Workflow: Building Domain Patterns

### Scenario: Creating a Complete Email System

**Step 1: Create Base Blueprint**

```bash
# Save a basic mailer
curl -X POST http://localhost:3000/api/v1/blueprints \
  -d '{
    "code": "class UserMailer < ApplicationMailer\n...",
    "description": "Base user mailer with standard headers and footer"
  }'
```

**Step 2: Generate Variants for Each Email Type**

```bash
# Welcome
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -d '{"description": "Welcome email with onboarding checklist"}'

# Password reset
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -d '{"description": "Password reset email with expiration time"}'

# Notification
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -d '{"description": "Daily digest notification email"}'
```

**Step 3: Review and Save Each**

```bash
# Save the ones you like as blueprints
curl -X POST http://localhost:3000/api/v1/blueprints \
  -d '{
    "code": "# Reviewed and tested welcome email",
    "categories": ["Email", "Welcome", "Production"]
  }'
```

**Step 4: Build on Success**

```bash
# Generate based on your new blueprints
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -d '{"description": "Personalized welcome email with user preferences"}'
```

---

## Related Guides

- **[Creating Blueprints](creating_blueprints.md)** - Save your own code patterns
- **[Editor Integration](editor_integration.md)** - Generate directly from your IDE
- **[REST API Reference](../api/REST_API.md)** - Complete API documentation
- **[AI Generators](../technical/AI_GENERATORS.md)** - LLM provider details and optimization

---

**Pro Tip:** Start with small, focused blueprints. The better your base patterns, the better your variants will be.
