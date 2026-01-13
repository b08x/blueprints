# REST API Reference - Blueprints by Sublayer

**Version:** 1.0
**Last Updated:** 2025-10-26
**Base URL:** `http://localhost:3000/api/v1`
**Content-Type:** `application/json`

---

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication & Rate Limiting](#authentication--rate-limiting)
3. [Response Format](#response-format)
4. [Error Handling](#error-handling)
5. [Blueprints Endpoints](#blueprints-endpoints)
6. [Blueprint Variants Endpoint](#blueprint-variants-endpoint)
7. [Blueprint Changes Endpoint](#blueprint-changes-endpoint)
8. [Integration Examples](#integration-examples)
9. [Troubleshooting](#troubleshooting)

---

## API Overview

The Blueprints API enables developers to:

- **Store code snippets** as reusable blueprints with AI-generated metadata
- **Generate code variants** from existing blueprints using natural language descriptions
- **Modify code** with AI-powered transformations
- **Search blueprints** semantically using vector embeddings

### Key Features

| Feature | Description |
|---------|-------------|
| **AI-Generated Metadata** | Automatically generates descriptions, names, and categories for code |
| **Semantic Search** | Find similar code using natural language (not keyword-based) |
| **Code Generation** | Generate new code variants based on similar patterns |
| **Vector Embeddings** | Every blueprint is indexed with semantic embeddings for intelligent search |
| **No Authentication** | Currently open API (designed for local/private deployment) |

### Processing Guarantees

- **Blueprints are deduplicated** by composite key: (name, description, code)
- **Vector embeddings are automatic** on every blueprint save
- **AI generation is deterministic** (same input → consistent output)
- **All responses are JSON** (no XML or other formats)

---

## Authentication & Rate Limiting

### Current State

- **Authentication:** None (open API)
- **Rate Limiting:** None (no throttling)

### Recommendations for Production

**Option 1: API Key Authentication**
```bash
# Add to request headers
curl -X GET http://localhost:3000/api/v1/blueprints \
  -H "X-API-Key: your-api-key"
```

**Option 2: Environment-Specific Deployment**
- Deploy locally or on private network
- Restrict network access via firewall rules
- No public internet exposure

**Recommended Rate Limits (if adding authentication):**
- Blueprint creation: 10 requests/minute per user
- Variant generation: 5 requests/minute per user (more expensive)
- General queries: 60 requests/minute per user

---

## Response Format

### Successful Response

```json
{
  "id": 1,
  "name": "User Authentication Module",
  "description": "Authenticates users using JWT tokens...",
  "code": "def authenticate_jwt(token)...",
  "categories": ["Authentication", "Rails", "Security"],
  "embedding_dimension": 768,
  "created_at": "2025-10-26T10:30:00Z",
  "updated_at": "2025-10-26T10:30:00Z"
}
```

### List Response

```json
{
  "blueprints": [
    { /* blueprint object */ },
    { /* blueprint object */ }
  ],
  "count": 42,
  "page": 1,
  "per_page": 50
}
```

### Standard Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | Integer | Unique blueprint identifier |
| `name` | String | AI-generated short name |
| `description` | String | AI-generated functional description |
| `code` | String | Source code content |
| `categories` | Array | AI-suggested categories |
| `embedding_dimension` | Integer | Always 768 for pgvector |
| `created_at` | DateTime | ISO 8601 timestamp |
| `updated_at` | DateTime | ISO 8601 timestamp |

---

## Error Handling

### Error Response Format

```json
{
  "error": "Human-readable error message",
  "error_code": "VALIDATION_ERROR",
  "details": {
    "field_name": ["error 1", "error 2"]
  },
  "request_id": "abc123def456"
}
```

### HTTP Status Codes

| Status | Meaning | Example |
|--------|---------|---------|
| **200** | OK | Successful GET, PATCH request |
| **201** | Created | Blueprint successfully created |
| **204** | No Content | Successful DELETE |
| **400** | Bad Request | Missing required parameters |
| **404** | Not Found | Blueprint doesn't exist |
| **422** | Unprocessable Entity | Validation failed (duplicate blueprint) |
| **500** | Internal Server Error | LLM generation failed or database error |
| **504** | Gateway Timeout | LLM API took too long (>30s) |

### Common Error Scenarios

**1. Code Cannot Be Empty (400)**
```json
{
  "error": "Validation failed",
  "details": {
    "code": ["can't be blank"]
  }
}
```

**2. Duplicate Blueprint (422)**
```json
{
  "error": "Validation failed",
  "details": {
    "name": ["has already been taken"]
  }
}
```

**3. LLM Generation Timeout (504)**
```json
{
  "error": "Generation timed out",
  "message": "Code analysis took longer than 30 seconds. Try with a smaller snippet."
}
```

**4. LLM API Failure (500)**
```json
{
  "error": "AI service error",
  "message": "Failed to generate description. Please retry or contact support."
}
```

### Handling Errors in Client Code

**JavaScript/TypeScript**
```javascript
try {
  const response = await fetch('http://localhost:3000/api/v1/blueprints', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ code: userCode })
  });

  if (!response.ok) {
    const error = await response.json();
    console.error(`Error [${response.status}]: ${error.error}`);
    console.error('Details:', error.details);
  }

  const blueprint = await response.json();
  return blueprint;
} catch (err) {
  console.error('Network error:', err.message);
}
```

---

## Blueprints Endpoints

### GET /api/v1/blueprints

Retrieve all blueprints with optional filtering and pagination.

**HTTP Request**
```http
GET /api/v1/blueprints HTTP/1.1
Host: localhost:3000
Accept: application/json
```

**Query Parameters**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `category` | String | - | Filter by category name (case-insensitive) |
| `search` | String | - | Search in name and description (substring match) |
| `limit` | Integer | 50 | Maximum results to return (max 1000) |
| `offset` | Integer | 0 | Pagination offset |

**Response: 200 OK**
```json
{
  "blueprints": [
    {
      "id": 1,
      "name": "User Authentication Module",
      "description": "Handles user login and session management",
      "code": "class AuthController < ApplicationController...",
      "categories": ["Authentication", "Rails", "Security"],
      "created_at": "2025-10-26T10:30:00Z"
    },
    {
      "id": 2,
      "name": "Email Validation Helper",
      "description": "Validates email addresses using regex patterns",
      "code": "def validate_email(email)...",
      "categories": ["Validation", "Ruby", "Email"],
      "created_at": "2025-10-25T14:22:15Z"
    }
  ],
  "count": 2,
  "page": 1,
  "per_page": 50
}
```

**cURL Examples**

```bash
# Get all blueprints
curl -X GET "http://localhost:3000/api/v1/blueprints" \
  -H "Accept: application/json"

# Filter by category
curl -X GET "http://localhost:3000/api/v1/blueprints?category=Authentication" \
  -H "Accept: application/json"

# Search by keyword
curl -X GET "http://localhost:3000/api/v1/blueprints?search=email" \
  -H "Accept: application/json"

# Pagination
curl -X GET "http://localhost:3000/api/v1/blueprints?limit=25&offset=25" \
  -H "Accept: application/json"

# Combined filters
curl -X GET "http://localhost:3000/api/v1/blueprints?category=Rails&search=auth&limit=10" \
  -H "Accept: application/json"
```

---

### POST /api/v1/blueprints

Create a new blueprint. Automatically generates description, name, categories, and vector embedding.

**HTTP Request**
```http
POST /api/v1/blueprints HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "code": "def hello\n  puts 'Hello, World!'\nend"
}
```

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | String | Yes | Source code content (max 50KB) |
| `description` | String | No | Custom description (if not provided, AI-generated) |
| `name` | String | No | Custom name (if not provided, AI-generated) |

**Response: 201 Created**
```json
{
  "id": 42,
  "name": "Hello World Printer",
  "description": "A simple method that outputs 'Hello, World!' to stdout",
  "code": "def hello\n  puts 'Hello, World!'\nend",
  "categories": ["Ruby", "CLI", "Output"],
  "embedding_dimension": 768,
  "created_at": "2025-10-26T14:30:00Z",
  "updated_at": "2025-10-26T14:30:00Z"
}
```

**Processing Pipeline**

```
Input: code
  ↓
1. Generate description (if not provided)
  ↓
2. Generate name (if not provided)
  ↓
3. Generate categories
  ↓
4. Create Blueprint record
  ↓
5. Auto-generate vector embedding (pgvector)
  ↓
Output: Complete blueprint with ID
```

**Timing**
- Without AI generation: 200-500ms (if all fields provided)
- With AI generation: 2-8 seconds (4 LLM calls)
- P95 latency: 5-10 seconds (includes network + LLM delays)

**cURL Examples**

```bash
# Create with code only (AI generates name, description, categories)
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def hello\n  puts '\''Hello, World!'\''\nend"
  }'

# Create with custom description (skips description generation)
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def hello\n  puts '\''Hello, World!'\''\nend",
    "description": "Prints a greeting to stdout"
  }'

# Create with multi-line code
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "class Calculator\n  def add(a, b)\n    a + b\n  end\nend"
  }'
```

**Error Cases**

| Status | Error | Solution |
|--------|-------|----------|
| **400** | Code cannot be empty | Include non-empty `code` field |
| **400** | Code too large (>50KB) | Reduce code size or split into multiple blueprints |
| **422** | Duplicate blueprint | This exact code + description + name already exists |
| **500** | AI generation failed | Retry request (transient LLM error) |

---

### GET /api/v1/blueprints/:id

Retrieve a specific blueprint by ID.

**HTTP Request**
```http
GET /api/v1/blueprints/42 HTTP/1.1
Host: localhost:3000
Accept: application/json
```

**Response: 200 OK**
```json
{
  "id": 42,
  "name": "Hello World Printer",
  "description": "A simple method that outputs 'Hello, World!' to stdout",
  "code": "def hello\n  puts 'Hello, World!'\nend",
  "categories": ["Ruby", "CLI"],
  "created_at": "2025-10-26T14:30:00Z",
  "updated_at": "2025-10-26T14:30:00Z"
}
```

**cURL Example**

```bash
curl -X GET http://localhost:3000/api/v1/blueprints/42 \
  -H "Accept: application/json"
```

**Error Cases**

| Status | Error |
|--------|-------|
| **404** | Blueprint not found (invalid ID) |

---

### PATCH /api/v1/blueprints/:id

Update an existing blueprint.

**HTTP Request**
```http
PATCH /api/v1/blueprints/42 HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "description": "Updated description",
  "name": "Updated Name"
}
```

**Request Body** (all fields optional)

| Field | Type | Description |
|-------|------|-------------|
| `code` | String | Updated source code |
| `description` | String | Updated description |
| `name` | String | Updated name |

**Response: 200 OK**
```json
{
  "id": 42,
  "name": "Updated Name",
  "description": "Updated description",
  "code": "def hello\n  puts 'Hello, World!'\nend",
  "categories": ["Ruby", "CLI"],
  "created_at": "2025-10-26T14:30:00Z",
  "updated_at": "2025-10-26T15:00:00Z"
}
```

**cURL Example**

```bash
curl -X PATCH http://localhost:3000/api/v1/blueprints/42 \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Updated description"
  }'
```

---

### DELETE /api/v1/blueprints/:id

Delete a blueprint.

**HTTP Request**
```http
DELETE /api/v1/blueprints/42 HTTP/1.1
Host: localhost:3000
```

**Response: 204 No Content**
```
(empty response body)
```

**cURL Example**

```bash
curl -X DELETE http://localhost:3000/api/v1/blueprints/42
```

**Note:** Deletion also removes all category associations.

---

## Blueprint Variants Endpoint

### POST /api/v1/blueprint_variants

Generate a new code variant based on an existing blueprint pattern and a natural language description.

**HTTP Request**
```http
POST /api/v1/blueprint_variants HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "description": "Print goodbye world in red text using ANSI codes"
}
```

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `description` | String | Yes | What you want the new code to do |
| `buffer_id` | String | No | Editor buffer identifier (for IDE integration) |
| `start_line` | Integer | No | Starting line number in editor |
| `end_line` | Integer | No | Ending line number in editor |

**Response: 200 OK**
```json
{
  "result": "def goodbye\n  puts \"\\e[31mgoodbye world\\e[0m\"\nend",
  "source_blueprint": {
    "id": 42,
    "name": "Hello World Printer",
    "similarity_score": 0.87
  },
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

**Processing Pipeline**

```
Input: description
  ↓
1. Generate vector embedding of description
  ↓
2. Search all blueprints using cosine similarity
  ↓
3. Find most similar blueprint
  ↓
4. Send blueprint + description to LLM
  ↓
5. LLM generates variant code
  ↓
Output: Generated code + metadata
```

**Timing**
- Vector search: 10-50ms (for <1000 blueprints)
- LLM generation: 2-4 seconds
- Total: 2-5 seconds (p95: 6 seconds)

**How It Works**

The variant generator finds the most semantically similar blueprint to your description, then uses that blueprint as a pattern reference to generate new code. This ensures the generated code maintains the same style, error handling patterns, and structure as existing blueprints.

**Examples**

Example 1: Generate variant from hello world pattern
```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Print goodbye world in red text"
  }'

# Returns code similar to hello world printer but modified for the new requirement
```

Example 2: With editor integration
```bash
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Validate an email address",
    "buffer_id": "vim_buffer_123",
    "start_line": 10,
    "end_line": 15
  }'

# Returns generated code + buffer metadata for IDE plugin to insert at specified location
```

**Similarity Scoring**

| Score | Meaning | Reliability |
|-------|---------|-------------|
| > 0.85 | Highly similar | High - variant will likely match pattern closely |
| 0.70-0.85 | Similar | Good - variant should follow general pattern |
| 0.50-0.70 | Somewhat similar | Fair - variant may diverge from pattern |
| < 0.50 | Dissimilar | Low - consider using different description |

**Error Cases**

| Status | Error | Solution |
|--------|-------|----------|
| **400** | Description cannot be empty | Provide a clear description |
| **404** | No blueprints found | Create blueprints first using POST /blueprints |
| **404** | No similar blueprint found | Rephrase description to be more specific |
| **500** | LLM generation failed | Retry request |

---

## Blueprint Changes Endpoint

### POST /api/v1/blueprint_changes

Modify existing code with AI-powered transformations.

**HTTP Request**
```http
POST /api/v1/blueprint_changes HTTP/1.1
Host: localhost:3000
Content-Type: application/json

{
  "code": "def hello\n  puts 'Hi'\nend",
  "description": "Make it print a random greeting",
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | String | Yes | Current code to modify |
| `description` | String | Yes | What changes you want to make |
| `buffer_id` | String | No | Editor buffer identifier |
| `start_line` | Integer | No | Starting line number |
| `end_line` | Integer | No | Ending line number |

**Response: 200 OK**
```json
{
  "result": "def hello\n  greetings = ['Hi', 'Hello', 'Hey']\n  puts greetings.sample\nend",
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

**cURL Example**

```bash
curl -X POST http://localhost:3000/api/v1/blueprint_changes \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def hello\n  puts '\''Hi'\''\nend",
    "description": "Make it print a random greeting from a list",
    "buffer_id": "editor_123",
    "start_line": 5,
    "end_line": 8
  }'
```

**Difference from Variants**

| Feature | POST /blueprints_variants | POST /blueprint_changes |
|---------|-------------------------|------------------------|
| **Input** | Description of new code | Current code + changes |
| **Use Case** | Generate similar code from pattern | Modify existing code |
| **Pattern Matching** | Finds similar blueprint | Uses provided code as pattern |
| **LLM Calls** | 2 (search + generate) | 2 (analyze + modify) |

---

## Integration Examples

### JavaScript/Node.js

**Installation**
```bash
npm install axios
```

**Create Blueprint**
```javascript
const axios = require('axios');

async function createBlueprint(code, description = null) {
  try {
    const response = await axios.post(
      'http://localhost:3000/api/v1/blueprints',
      { code, description },
      { headers: { 'Content-Type': 'application/json' } }
    );

    console.log('Blueprint created:', response.data);
    return response.data;
  } catch (error) {
    console.error('Error creating blueprint:', error.response?.data || error.message);
    throw error;
  }
}

// Usage
const code = `
  def calculate_total(items)
    items.sum(&:price)
  end
`;

createBlueprint(code).then(blueprint => {
  console.log(`Created: ${blueprint.name}`);
  console.log(`ID: ${blueprint.id}`);
  console.log(`Categories: ${blueprint.categories.join(', ')}`);
});
```

**Generate Variant**
```javascript
async function generateVariant(description) {
  try {
    const response = await axios.post(
      'http://localhost:3000/api/v1/blueprint_variants',
      { description }
    );

    return response.data.result;  // Generated code
  } catch (error) {
    console.error('Error generating variant:', error.response?.data);
    throw error;
  }
}

// Usage
generateVariant('Calculate the sum of all negative numbers').then(code => {
  console.log('Generated code:', code);
});
```

**Search Blueprints**
```javascript
async function searchBlueprints(query, category = null) {
  try {
    const params = new URLSearchParams({ search: query });
    if (category) params.append('category', category);

    const response = await axios.get(
      `http://localhost:3000/api/v1/blueprints?${params}`
    );

    return response.data.blueprints;
  } catch (error) {
    console.error('Error searching:', error.response?.data);
    throw error;
  }
}

// Usage
searchBlueprints('authentication', 'Security').then(blueprints => {
  blueprints.forEach(bp => {
    console.log(`${bp.name} - ${bp.description}`);
  });
});
```

---

### Python

**Installation**
```bash
pip install requests
```

**Create Blueprint**
```python
import requests
import json

def create_blueprint(code, description=None):
    """Create a new blueprint."""
    url = 'http://localhost:3000/api/v1/blueprints'

    payload = {
        'code': code,
        'description': description
    }

    try:
        response = requests.post(
            url,
            json=payload,
            headers={'Content-Type': 'application/json'}
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f'Error: {e.response.json() if hasattr(e, "response") else str(e)}')
        raise

# Usage
code = '''
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)
'''

blueprint = create_blueprint(code)
print(f"Created: {blueprint['name']} (ID: {blueprint['id']})")
print(f"Categories: {', '.join(blueprint['categories'])}")
```

**Generate Variant**
```python
def generate_variant(description):
    """Generate a code variant."""
    url = 'http://localhost:3000/api/v1/blueprint_variants'

    payload = {'description': description}

    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f'Error: {e.response.json()}')
        raise

# Usage
result = generate_variant('Calculate factorial using iteration instead of recursion')
print(f"Generated code:\n{result['result']}")
print(f"From blueprint: {result['source_blueprint']['name']}")
print(f"Similarity: {result['source_blueprint']['similarity_score']:.2f}")
```

---

### Ruby

**Installation**
```bash
gem 'httparty'
```

**Create Blueprint**
```ruby
require 'httparty'

class BlueprintClient
  include HTTParty
  base_uri 'http://localhost:3000/api/v1'

  def create_blueprint(code, description = nil)
    self.class.post(
      '/blueprints',
      body: { code: code, description: description }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def generate_variant(description)
    self.class.post(
      '/blueprint_variants',
      body: { description: description }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def get_blueprints(category: nil, search: nil)
    query = {}
    query[:category] = category if category
    query[:search] = search if search

    self.class.get('/blueprints', query: query)
  end
end

# Usage
client = BlueprintClient.new

blueprint = client.create_blueprint(<<~CODE)
  def greet(name)
    "Hello, #{name}!"
  end
CODE

puts "Created: #{blueprint['name']} (ID: #{blueprint['id']})"

variant = client.generate_variant('Greet someone in multiple languages')
puts "Generated code:\n#{variant['result']}"
```

---

### cURL (Command Line)

**Quick Testing**
```bash
# 1. Create a blueprint
BLUEPRINT=$(curl -s -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{
    "code": "def hello\n  puts '\''Hello'\''\nend"
  }')

echo "Created blueprint:"
echo $BLUEPRINT | jq '.'

# Extract ID (requires jq)
BLUEPRINT_ID=$(echo $BLUEPRINT | jq '.id')

# 2. Generate a variant
curl -s -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Print goodbye instead of hello"
  }' | jq '.result'

# 3. Search blueprints
curl -s "http://localhost:3000/api/v1/blueprints?search=hello" | jq '.blueprints'

# 4. Delete blueprint
curl -X DELETE http://localhost:3000/api/v1/blueprints/$BLUEPRINT_ID
```

---

## Troubleshooting

### Q: API returns 504 Timeout

**Problem:** LLM generation took longer than 30 seconds

**Solutions:**
1. **Try with smaller code** - Reduce code snippet size
2. **Retry the request** - Transient network issue may resolve
3. **Check LLM service status** - Verify GEMINI_API_KEY or OPENAI_API_KEY is valid
4. **Increase timeout** (advanced) - Edit Sublayer configuration if self-hosting

**Debug Steps:**
```bash
# Check if server is responding
curl http://localhost:3000/up

# Check logs
tail -f log/development.log  # or production.log

# Look for: "LLM generation timeout" or provider API errors
```

---

### Q: API returns 422 Duplicate Blueprint

**Problem:** This exact code + description already exists

**Why It Happens:**
- Blueprints are deduplicated by composite key: (name, description, code)
- Prevents storing identical snippets multiple times

**Solutions:**
1. **Modify the code slightly** - Change implementation approach
2. **Provide custom description** - Different description = different blueprint
3. **Query existing blueprint** - Check if it already exists before creating
4. **Check categories** - Maybe it exists under a different category

**Debug:**
```bash
# Search for similar blueprints
curl "http://localhost:3000/api/v1/blueprints?search=authentication"

# Check by ID if you know it
curl http://localhost:3000/api/v1/blueprints/42
```

---

### Q: Generated variant doesn't match blueprint pattern

**Problem:** Generated code doesn't follow the same style/structure as source blueprint

**Possible Causes:**
1. **Conflicting requirements** - Your description is incompatible with blueprint pattern
2. **Poor blueprint quality** - Blueprint doesn't represent good patterns
3. **Weak similarity match** - No similar blueprint found

**Solutions:**
1. **Check similarity score** - If < 0.70, try a different description
2. **Choose better blueprint** - Use a high-quality, well-structured blueprint as reference
3. **Be specific** - Use detailed descriptions (compare code generation quality)
4. **Use better LLM** - Switch from Gemini Flash to GPT-4 for quality-critical code

**Debug:**
```bash
# Check what blueprint was used
curl -X POST http://localhost:3000/api/v1/blueprint_variants \
  -H "Content-Type: application/json" \
  -d '{"description": "your description"}' | jq '.source_blueprint'

# Review the source blueprint
curl http://localhost:3000/api/v1/blueprints/<source_blueprint_id>
```

---

### Q: Slow API response times

**Problem:** Requests take 5-10+ seconds consistently

**Possible Causes:**
1. **LLM provider is slow** - Gemini/OpenAI API latency
2. **Database is slow** - Vector search on large tables
3. **Network latency** - Slow connection to server
4. **Too many LLM calls** - Multiple requests in parallel

**Solutions:**
1. **Use faster provider** - Gemini Flash (600-900ms) vs GPT-4 (2-3s)
2. **Enable caching** - Cache responses for identical inputs (if self-hosting)
3. **Reduce code size** - Smaller prompts = faster LLM generation
4. **Use variants endpoint** - Faster than creating new blueprints (1 LLM call vs 3)

**Performance Benchmarks:**
```
GET /blueprints              : 50-200ms
POST /blueprints             : 2-8 seconds (4 LLM calls)
POST /blueprint_variants     : 2-5 seconds (1 LLM + search)
POST /blueprint_changes      : 2-5 seconds (2 LLM calls)
```

---

### Q: What encoding is required for code parameter?

**Answer:** Standard UTF-8 JSON encoding

**Guidelines:**
- Use `\n` for newlines
- Escape quotes as `\"`
- Use raw strings for readability

**Examples:**
```bash
# Single-line code
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{"code": "puts '\''hello'\''"}'

# Multi-line code (with escaped newlines)
curl -X POST http://localhost:3000/api/v1/blueprints \
  -H "Content-Type: application/json" \
  -d '{"code": "def greet\n  puts '\''hello'\''\nend"}'

# In Python (automatic escaping)
requests.post(url, json={'code': code})

# In JavaScript
JSON.stringify({code: code})  # Automatic encoding
```

---

### Q: Can I use the API without authentication?

**Current:** Yes, the API is open

**For Production:**
- Deploy on private network
- Use environment variables for API keys
- Implement API key authentication (optional feature)
- Add rate limiting via reverse proxy (Nginx)

**Recommended Setup:**
```
[Internet] ← Firewall ← [Nginx + Rate Limiting] → [Rails App]
```

---

## Conclusion

The Blueprints API is designed for simplicity and ease of integration. Key takeaways:

- **Simple REST interface** - Standard HTTP methods and JSON
- **AI-powered generation** - Automatic metadata and code generation
- **Semantic search** - Find blueprints by meaning, not keywords
- **Quick integration** - Works with any programming language that supports HTTP
- **Fast feedback** - Suitable for IDE plugins and editor integrations

For technical questions or feature requests, refer to the project documentation or contact the development team.

---

**Document Version:** 1.0
**Source:** `/home/b08x/Workspace/RubyAI/blueprints/docs/api/REST_API.md`
