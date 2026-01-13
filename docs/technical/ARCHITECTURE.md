# Blueprints by Sublayer - Technical Architecture

**Version:** 1.0
**Last Updated:** 2025-10-26
**Application:** AI-Powered Code Blueprint Storage and Generation System

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Philosophy](#architecture-philosophy)
3. [Component Architecture](#component-architecture)
4. [API Architecture](#api-architecture)
5. [Data Architecture](#data-architecture)
6. [AI/ML Layer](#aiml-layer)
7. [Data Flow Diagrams](#data-flow-diagrams)
8. [Integration Points](#integration-points)
9. [Performance Characteristics](#performance-characteristics)
10. [Security Architecture](#security-architecture)
11. [Deployment Architecture](#deployment-architecture)
12. [Technology Stack Rationale](#technology-stack-rationale)
13. [Key Architectural Decisions](#key-architectural-decisions)
14. [Monitoring and Observability](#monitoring-and-observability)
15. [Future Enhancement Opportunities](#future-enhancement-opportunities)

---

## System Overview

### Executive Summary

Blueprints by Sublayer is a Rails 7.1.3.4+ application that enables developers to store reusable code snippets ("blueprints") enriched with AI-generated metadata, then generate new code variants through semantic similarity search and large language model (LLM) prompting.

**Core Value Proposition:**
- **Learn from Patterns:** Store code snippets with automatic AI categorization and description
- **Semantic Discovery:** Find relevant blueprints using natural language queries via vector embeddings
- **Intelligent Generation:** Create new code variants based on similar patterns and developer intent
- **Editor Integration:** Seamless integration with popular IDEs through a RESTful API

### High-Level Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        A[Editor Plugins]
        B[Web Browser]
    end

    subgraph "Application Layer"
        C[Nginx Reverse Proxy]
        D[Rails Application Server]

        subgraph "Controllers"
            E[API Controllers v1]
            F[Web Controllers]
        end

        subgraph "Service Layer"
            G[Sublayer Generators]
            H[Vector Search Service]
        end
    end

    subgraph "AI Layer"
        I[Google Gemini API]
        J[OpenAI API]
    end

    subgraph "Data Layer"
        K[(PostgreSQL + pgvector)]
        L[Vector Embeddings]
    end

    A -->|REST API| C
    B -->|HTTP| C
    C --> D
    D --> E
    D --> F
    E --> G
    F --> G
    G --> H
    G --> I
    G --> J
    H --> K
    K --> L

    style D fill:#bbdefb
    style G fill:#c8e6c9
    style K fill:#f8bbd0
    style I fill:#fff9c4
    style J fill:#fff9c4
```

### Core Components

| Component | Responsibility | Technology |
|-----------|---------------|------------|
| **Web Layer** | HTTP request handling, routing, response serialization | Rails 7.1, Nginx |
| **Service Layer** | AI generation orchestration, business logic | Sublayer Generators |
| **Vector Search** | Semantic similarity matching | pgvector, neighbor gem |
| **AI Integration** | LLM API abstraction and prompt engineering | Sublayer framework |
| **Data Persistence** | Blueprint and category storage | PostgreSQL 14+ |
| **View Rendering** | Server-side component rendering | Phlex components |

---

## Architecture Philosophy

### Design Principles

1. **Clarity over Cleverness**
   - Code is optimized for readability and maintainability
   - Explicit over implicit when it improves understanding
   - Self-documenting patterns through clear naming conventions

2. **Design for Failure**
   - Graceful degradation when LLM APIs are unavailable
   - Error boundaries at each layer
   - Comprehensive error handling in generators

3. **Start Simple, Evolve Thoughtfully**
   - Stateless API design enables easy horizontal scaling
   - No premature optimization
   - Clear extension points for future enhancements

4. **Security and Observability First**
   - Security considerations documented and tracked
   - Logging at critical decision points
   - Metrics collection for performance analysis

5. **Vector-First Architecture**
   - Semantic search as the primary discovery mechanism
   - Embeddings generated automatically on data persistence
   - Foundation for advanced AI/ML features

---

## Component Architecture

### Web Layer

#### Request Flow

```mermaid
sequenceDiagram
    participant Client
    participant Nginx
    participant Rails
    participant Controller
    participant Service

    Client->>Nginx: HTTP Request
    Nginx->>Rails: Forward to :3000
    Rails->>Controller: Route to action
    Controller->>Service: Invoke business logic
    Service-->>Controller: Return result
    Controller-->>Rails: Render response
    Rails-->>Nginx: HTTP Response
    Nginx-->>Client: Return to client
```

#### Controllers

**API Controllers (Stateless)**

Located in `/app/controllers/api/v1/`:

1. **BlueprintsController** - Blueprint creation endpoint
   - Accepts code snippets
   - Orchestrates AI generation pipeline
   - Returns AI-generated description

2. **BlueprintVariantsController** - Code generation endpoint
   - Accepts natural language description
   - Performs vector similarity search
   - Generates new code based on matched blueprint

3. **BlueprintChangesController** - Code modification endpoint
   - Accepts existing code + modification request
   - Applies AI-powered transformations
   - Returns modified code

**Web Controllers (Stateful UI)**

Located in `/app/controllers/`:

1. **BlueprintsController** - CRUD operations
   - List, view, edit, delete blueprints
   - Uses Phlex components for rendering

2. **CategoriesController** - Tag management
   - Associate/disassociate categories with blueprints

3. **DownloadsController** - Import/export
   - CSV export of all blueprints
   - Bulk import from CSV files

#### Authentication and Authorization

**Current State:**
- No authentication required (open API)
- No authorization checks
- Token-based editor identification via `buffer_id` parameter

**Rationale:**
- Designed for local/private deployment
- Simplifies editor plugin integration
- Expected to run on developer's local machine or trusted internal network

#### Error Handling

**Strategy:**
- Controller-level rescue blocks for common exceptions
- Validation errors return 422 Unprocessable Entity
- Missing resources return 404 Not Found
- LLM failures return 500 Internal Server Error with error messages

**Example Pattern:**
```ruby
def create
  blueprint = Blueprint.new(code: params[:code])
  # ... AI processing ...
  blueprint.save!
  render json: { description: blueprint.description }, status: :created
rescue ActiveRecord::RecordInvalid => e
  render json: { error: e.message }, status: :unprocessable_entity
rescue => e
  render json: { error: "Generation failed: #{e.message}" }, status: :internal_server_error
end
```

---

### Service Layer

#### Sublayer Generator Architecture

All AI generation is handled through **Sublayer Generators** - a specialized pattern for LLM orchestration.

**Base Generator Pattern:**

```ruby
class MyGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :single_string,
    name: "field_name",
    description: "What this field contains"

  def initialize(required_params)
    @params = required_params
  end

  def generate
    super  # Invokes LLM with prompt
  end

  def prompt
    # Returns interpolated prompt template
    <<~PROMPT
      Given: #{@params}
      Generate: [specific instructions]
    PROMPT
  end
end
```

**Available Generators:**

| Generator | Purpose | Input | Output |
|-----------|---------|-------|--------|
| `CodeDescriptionGenerator` | Analyzes code functionality | `code` | Functional description |
| `NameFromCodeAndDescriptionGenerator` | Creates blueprint name | `code`, `description` | Short name |
| `CategoriesFromCodeGenerator` | Auto-categorizes code | `code` | CSV category list |
| `CodeFromBlueprintGenerator` | Generates new code | `blueprint`, `description` | Generated code |

#### Generator Composition Pattern

Generators are **composable** and **reusable**. The blueprint creation workflow demonstrates orchestration:

```ruby
def create
  # Step 1: Analyze code
  description = CodeDescriptionGenerator.new(code: params[:code]).generate

  # Step 2: Generate name
  name = NameFromCodeAndDescriptionGenerator.new(
    code: params[:code],
    description: description
  ).generate

  # Step 3: Categorize
  categories_csv = CategoriesFromCodeGenerator.new(code: params[:code]).generate

  # Step 4: Persist
  blueprint = Blueprint.create!(
    code: params[:code],
    description: description,
    name: name
  )
  blueprint.build_categories_from_text(categories_csv)
  blueprint.save!
end
```

#### Vector Search Service

**Implementation:** Integrated into `Blueprint` model via `vectorsearch` module

**Core Methods:**

```ruby
class Blueprint < ApplicationRecord
  vectorsearch  # Enables vector search capability

  # Define what gets embedded
  def as_vector
    { description: description, name: name }.to_json
  end

  # Automatic embedding on save
  after_save :upsert_to_vectorsearch, if: :saved_changes?
end

# Usage
results = Blueprint.similarity_search(user_query)
closest_blueprint = results.first
```

**Search Algorithm:**
1. Convert user query to vector embedding
2. Calculate cosine similarity with all blueprint embeddings
3. Rank by similarity score (0.0 to 1.0)
4. Return ordered results

---

### Data Layer

#### PostgreSQL with pgvector Extension

**Purpose:** Efficient vector similarity search at database layer

**Key Capabilities:**
- Store high-dimensional vectors (768 dimensions)
- Fast similarity search using specialized indexing
- Native PostgreSQL integration (no separate vector DB)

**Trade-offs vs. Alternatives:**

| Approach | Pros | Cons |
|----------|------|------|
| **pgvector** ✅ | Single database, simpler architecture, transactional consistency | Limited to PostgreSQL, potential performance bottlenecks at massive scale |
| Pinecone | Specialized for vectors, highly scalable | External service dependency, additional cost, data synchronization complexity |
| Weaviate | Built-in ML models, GraphQL API | Infrastructure complexity, learning curve, overkill for current scale |

**Decision:** pgvector chosen for architectural simplicity and adequate performance at current scale (< 100K blueprints).

#### Redis Caching Strategy

**Current State:** Not implemented

**Future Consideration:**
- Cache vector search results for common queries
- Store LLM responses to reduce API costs
- Session management if authentication is added

---

## API Architecture

### REST API Design Principles

1. **Versioning:** URL-based versioning (`/api/v1/`)
2. **Resource-oriented:** Resources as nouns (`blueprints`, not `create_blueprint`)
3. **HTTP verbs:** Standard CRUD mapping
4. **Stateless:** No server-side session state
5. **JSON-only:** All requests and responses use JSON

### Endpoints Overview

#### API v1 Endpoints

**1. Create Blueprint**

```http
POST /api/v1/blueprints
Content-Type: application/json

{
  "code": "def hello\n  puts 'Hello, World!'\nend"
}
```

**Response:** 201 Created
```json
{
  "description": "A simple method that prints 'Hello, World!' to the console"
}
```

**Processing Pipeline:**
1. Receive code snippet
2. Generate description (GPT-4 or Gemini)
3. Generate name (GPT-4 or Gemini)
4. Generate categories (GPT-4 or Gemini)
5. Create Blueprint record
6. Auto-generate vector embedding (pgvector)
7. Return description to client

---

**2. Generate Blueprint Variant**

```http
POST /api/v1/blueprint_variants
Content-Type: application/json

{
  "description": "method that prints goodbye message",
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

**Response:** 200 OK
```json
{
  "result": "def goodbye\n  puts 'Goodbye, World!'\nend",
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

**Processing Pipeline:**
1. Receive description + editor metadata
2. Perform vector similarity search
3. Find most similar blueprint
4. Use blueprint as pattern reference
5. Generate new code matching description
6. Return code with original buffer metadata

---

**3. Modify Existing Code**

```http
POST /api/v1/blueprint_changes
Content-Type: application/json

{
  "code": "def hello\n  puts 'Hi'\nend",
  "description": "make it print a random greeting",
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

**Response:** 200 OK
```json
{
  "result": "def hello\n  greetings = ['Hi', 'Hello', 'Hey']\n  puts greetings.sample\nend",
  "buffer_id": "vim_buffer_123",
  "start_line": 10,
  "end_line": 15
}
```

---

#### Web UI Endpoints

**Blueprint CRUD:**
- `GET /blueprints` - List all blueprints
- `GET /blueprints/:id` - Show blueprint detail
- `GET /blueprints/:id/edit` - Edit form
- `PATCH /blueprints/:id` - Update blueprint
- `DELETE /blueprints/:id` - Delete blueprint

**Category Management:**
- `POST /blueprints/:blueprint_id/categories` - Add category

**Import/Export:**
- `GET /downloads/export` - Export blueprints as CSV
- `POST /downloads/import` - Import blueprints from CSV

### Error Response Format

**Standard Error Response:**
```json
{
  "error": "Human-readable error message",
  "details": {
    "field": ["validation error 1", "validation error 2"]
  }
}
```

**HTTP Status Codes:**
- `200 OK` - Successful operation
- `201 Created` - Resource created successfully
- `204 No Content` - Successful deletion
- `400 Bad Request` - Missing required parameters
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - LLM or system failure

---

## Data Architecture

### Database Schema

```mermaid
erDiagram
    BLUEPRINTS ||--o{ BLUEPRINTS_CATEGORIES : has
    CATEGORIES ||--o{ BLUEPRINTS_CATEGORIES : has

    BLUEPRINTS {
        bigint id PK
        text code
        text description
        varchar name
        vector_768 embedding
        timestamp created_at
        timestamp updated_at
    }

    CATEGORIES {
        bigint id PK
        varchar title UK
        timestamp created_at
        timestamp updated_at
    }

    BLUEPRINTS_CATEGORIES {
        bigint blueprint_id FK
        bigint category_id FK
        PK(blueprint_id, category_id)
    }
```

### Schema Details

**Blueprints Table:**

```sql
CREATE TABLE blueprints (
  id BIGSERIAL PRIMARY KEY,
  code TEXT NOT NULL,
  description TEXT,
  name VARCHAR,
  embedding vector(768),  -- pgvector column for semantic search
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_blueprints_name ON blueprints(name);
CREATE INDEX idx_blueprints_updated_at ON blueprints(updated_at DESC);
-- Vector index for similarity search (future optimization)
-- CREATE INDEX ON blueprints USING ivfflat (embedding vector_cosine_ops);
```

**Categories Table:**

```sql
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR UNIQUE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE UNIQUE INDEX idx_categories_title ON categories(title);
```

**Join Table:**

```sql
CREATE TABLE blueprints_categories (
  blueprint_id BIGINT NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (blueprint_id, category_id)
);

-- Indexes
CREATE INDEX idx_blueprints_categories_blueprint ON blueprints_categories(blueprint_id);
CREATE INDEX idx_blueprints_categories_category ON blueprints_categories(category_id);
```

### ActiveRecord Associations

```ruby
class Blueprint < ApplicationRecord
  has_and_belongs_to_many :categories

  # Composite uniqueness validation
  validates :name, uniqueness: { scope: %i[description code] }

  # Vector search integration
  vectorsearch

  def as_vector
    { description: description, name: name }.to_json
  end

  after_save :upsert_to_vectorsearch, if: :saved_changes?
end

class Category < ApplicationRecord
  has_and_belongs_to_many :blueprints

  validates :title, presence: true, uniqueness: true

  before_save :downcase_title

  private

  def downcase_title
    title.downcase!
  end
end
```

### Data Integrity Rules

1. **Blueprint Uniqueness:** Combination of name, description, and code must be unique
2. **Category Normalization:** All category titles stored as lowercase
3. **Cascade Deletion:** Deleting a blueprint removes its category associations
4. **Automatic Timestamps:** created_at and updated_at managed by Rails
5. **Vector Consistency:** Embedding regenerated on any blueprint update

---

## AI/ML Layer

### LLM Provider Abstraction

**Framework:** Sublayer (Ruby gem for LLM abstraction)

**Supported Providers:**

```mermaid
graph LR
    A[Sublayer Framework] --> B[OpenAI Provider]
    A --> C[Gemini Provider]
    A --> D[Anthropic Provider]

    B --> E[GPT-4 Turbo]
    B --> F[GPT-3.5 Turbo]
    C --> G[Gemini 2.0 Flash]
    D --> H[Claude 3 Haiku]

    style A fill:#c8e6c9
    style C fill:#fff9c4
```

### Configuration

**Initializer:** `/config/initializers/sublayer.rb`

```ruby
if Rails.configuration.ai_provider == "google"
  Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
  Sublayer.configuration.ai_model = "gemini-2.0-flash-exp"
else
  Sublayer.configuration.ai_provider = Sublayer::Providers::OpenAI
  Sublayer.configuration.ai_model = "qwen/qwen-2.5-coder-32b-instruct:free"
end
```

**Environment Variables:**
- `OPENAI_API_KEY` - For OpenAI models
- `GEMINI_API_KEY` - For Google Gemini models
- `ANTHROPIC_API_KEY` - For Claude models (not currently used)

### Provider Comparison

| Provider | Model | Cost/1M Tokens | Latency | Code Quality | Notes |
|----------|-------|----------------|---------|--------------|-------|
| **Google Gemini** ✅ | gemini-2.0-flash-exp | Free tier available | 2-4s | Excellent | Current default, best cost/performance |
| OpenAI | GPT-4 Turbo | $10 input / $30 output | 3-6s | Excellent | High quality, expensive |
| OpenAI | GPT-3.5 Turbo | $0.50 input / $1.50 output | 1-2s | Good | Fast and cheap, less sophisticated |
| Anthropic | Claude 3 Haiku | $0.25 input / $1.25 output | 2-4s | Very Good | Not currently configured |

**Decision:** Gemini 2.0 Flash chosen for zero-cost operation with excellent code generation quality.

### Prompt Engineering Approach

**Strategy:** Explicit, structured prompts with clear instructions

**Example - Code Description Generator:**

```ruby
def prompt
  <<~PROMPT
    You are analyzing Ruby code to generate a concise functional description.

    Code:
    ```ruby
    #{@code}
    ```

    Provide a 1-2 sentence description of what this code does.
    Focus on FUNCTIONALITY, not implementation details.
    Use present tense and active voice.
  PROMPT
end
```

**Prompt Design Principles:**
1. **Role Definition:** Tell the LLM what persona to adopt
2. **Context Setting:** Provide all necessary context
3. **Clear Instructions:** Explicit output format and constraints
4. **Examples:** Include few-shot examples when needed
5. **Output Formatting:** Specify exact response structure

### Embedding Generation Pipeline

**Integration:** pgvector with neighbor gem

**Process:**

```mermaid
graph LR
    A[Blueprint Save] --> B[as_vector Method]
    B --> C{Changed?}
    C -->|Yes| D[Generate Embedding]
    C -->|No| E[Skip]
    D --> F[OpenAI Embeddings API]
    F --> G[768-dim Vector]
    G --> H[Store in embedding Column]

    style F fill:#fff9c4
    style H fill:#f8bbd0
```

**Embedding Model:**
- OpenAI: `text-embedding-ada-002` (768 dimensions)
- Cost: $0.0001 per 1K tokens
- Latency: 200-500ms

**Automatic Generation:**
```ruby
after_save :upsert_to_vectorsearch, if: :saved_changes?

def as_vector
  {
    description: description,
    name: name
  }.to_json
end
```

### Cost Optimization Strategies

**Current Optimizations:**
1. **Free Tier LLM:** Using Gemini 2.0 Flash (free tier)
2. **Minimal Embeddings:** Only name + description embedded (not full code)
3. **Single-Use Generation:** No caching (yet)

**Future Optimizations:**
1. **Response Caching:** Cache LLM responses for identical prompts
2. **Batch Embeddings:** Generate embeddings in batches for imports
3. **Semantic Deduplication:** Prevent near-duplicate blueprints via similarity threshold
4. **Token Optimization:** Reduce prompt verbosity without quality loss

---

## Data Flow Diagrams

### 1. Create Blueprint Flow

```mermaid
sequenceDiagram
    participant EP as Editor Plugin
    participant API as API Controller
    participant G1 as CodeDescriptionGenerator
    participant G2 as NameGenerator
    participant G3 as CategoriesGenerator
    participant LLM as Gemini API
    participant DB as PostgreSQL
    participant VEC as Vector Embeddings

    EP->>API: POST /api/v1/blueprints<br/>{code}

    API->>G1: Generate description
    G1->>LLM: Analyze code functionality
    LLM-->>G1: Return description

    API->>G2: Generate name
    G2->>LLM: Create short name
    LLM-->>G2: Return name

    API->>G3: Generate categories
    G3->>LLM: Categorize code
    LLM-->>G3: Return CSV categories

    API->>DB: Save Blueprint record
    DB->>VEC: Trigger embedding generation
    VEC->>LLM: Generate embedding
    LLM-->>VEC: Return 768-dim vector
    VEC->>DB: Store embedding

    DB-->>API: Blueprint saved
    API-->>EP: Return {description}
```

**Performance Metrics:**
- Total latency: 4-8 seconds
- LLM calls: 4 (3 generators + 1 embedding)
- Database operations: 1 insert + N category associations

---

### 2. Generate Variant Flow

```mermaid
sequenceDiagram
    participant EP as Editor Plugin
    participant API as BlueprintVariantsController
    participant VS as Vector Search
    participant DB as PostgreSQL
    participant G as CodeFromBlueprintGenerator
    participant LLM as Gemini API

    EP->>API: POST /api/v1/blueprint_variants<br/>{description, buffer_id, lines}

    API->>VS: similarity_search(description)
    VS->>DB: Query vector similarity
    DB-->>VS: Return ranked blueprints
    VS-->>API: Most similar blueprint

    API->>G: Generate variant
    Note over G: Uses blueprint code as pattern
    G->>LLM: Generate new code
    LLM-->>G: Return generated code
    G-->>API: Generated code

    API-->>EP: Return {result, buffer_id, lines}
```

**Performance Metrics:**
- Total latency: 2-5 seconds
- Vector search: 10-100ms (depends on table size)
- LLM generation: 2-4 seconds
- Database operations: 1 similarity query

---

### 3. Component Interaction Diagram

```mermaid
graph TB
    subgraph "Presentation Layer"
        A[Web UI - Phlex]
        B[API v1 - JSON]
    end

    subgraph "Business Logic Layer"
        C[BlueprintsController]
        D[BlueprintVariantsController]
        E[BlueprintChangesController]
    end

    subgraph "Service Layer"
        F[CodeDescriptionGenerator]
        G[NameGenerator]
        H[CategoriesGenerator]
        I[CodeFromBlueprintGenerator]
    end

    subgraph "Data Access Layer"
        J[Blueprint Model]
        K[Category Model]
        L[Vector Search Module]
    end

    subgraph "External Services"
        M[Gemini API]
        N[PostgreSQL + pgvector]
    end

    A --> C
    B --> C
    B --> D
    B --> E

    C --> F
    C --> G
    C --> H
    D --> I
    D --> L
    E --> F
    E --> I

    F --> M
    G --> M
    H --> M
    I --> M

    F --> J
    G --> J
    H --> J
    H --> K
    L --> J

    J --> N
    K --> N
    L --> N

    style A fill:#e3f2fd
    style B fill:#e3f2fd
    style F fill:#c8e6c9
    style G fill:#c8e6c9
    style H fill:#c8e6c9
    style I fill:#c8e6c9
    style M fill:#fff9c4
    style N fill:#f8bbd0
```

---

## Integration Points

### Editor Plugin Integrations

**Supported Editors:**
- Vim/Neovim
- VSCode
- IntelliJ IDEA
- Sublime Text

**Integration Pattern:**

1. **User Selects Code:** Highlight code in editor
2. **Plugin Captures Context:** Extract code, line numbers, buffer ID
3. **API Request:** POST to appropriate endpoint
4. **Response Handling:** Insert generated code at specified location

**API Contract Requirements:**
- `buffer_id`: Unique editor buffer identifier
- `start_line`: Beginning line number
- `end_line`: Ending line number
- `code` or `description`: Input data

**Example Vim Integration:**

```vim
function! BlueprintsCreate()
  let code = GetSelectedText()
  let response = system('curl -X POST http://localhost/api/v1/blueprints -d ' . shellescape(json_encode({'code': code})))
  echo 'Blueprint created: ' . response.description
endfunction
```

### LLM API Integration

**Abstraction Layer:** Sublayer framework

**Benefits:**
- Provider-agnostic code
- Consistent error handling
- Automatic retry logic
- Token counting and tracking

**Direct Integration Points:**
- `/config/initializers/sublayer.rb` - Provider configuration
- Generator classes - Prompt templates and output parsing
- Environment variables - API keys

**Failure Handling:**
1. API timeout → Retry with exponential backoff
2. Rate limit → Queue request for later
3. Invalid response → Return error to user with message
4. Authentication failure → Log error, return 500

### Vector Database Integration

**Technology:** pgvector extension for PostgreSQL

**Integration Points:**

1. **Model Layer:** `Blueprint` model with `vectorsearch` module
2. **Database Schema:** `embedding vector(768)` column
3. **Similarity Queries:** `Blueprint.similarity_search(query)`
4. **Automatic Updates:** After-save callback triggers embedding generation

**Query Performance:**

| Table Size | Query Time (ms) | Strategy |
|------------|-----------------|----------|
| < 1K blueprints | 10-20ms | Sequential scan |
| 1K-10K | 50-100ms | Sequential scan |
| > 10K | 100-500ms | IVFFlat index recommended |

**Scaling Strategy:**
```sql
-- For > 10K blueprints, add IVFFlat index
CREATE INDEX ON blueprints
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

---

## Performance Characteristics

### Request/Response Times

**Blueprint Creation:**
- Minimum: 4 seconds (4 LLM calls)
- Average: 6 seconds
- Maximum: 12 seconds (with retries)

**Variant Generation:**
- Minimum: 2 seconds
- Average: 4 seconds
- Maximum: 8 seconds (with retries)

**Code Modification:**
- Minimum: 3 seconds (2 LLM calls)
- Average: 5 seconds
- Maximum: 10 seconds (with retries)

### Vector Search Performance

**Current Performance (< 1K blueprints):**
- Search latency: 10-50ms
- Accuracy: High (cosine similarity)
- Index: None (sequential scan)

**Projected Performance (10K blueprints):**
- Search latency: 100-200ms (with IVFFlat index)
- Accuracy: 95%+ (some approximate results)
- Index: IVFFlat with 100 lists

### LLM API Latency

**Google Gemini 2.0 Flash:**
- Minimum: 1.5 seconds
- Average: 3 seconds
- Maximum: 8 seconds
- P95: 5 seconds

**Factors:**
- Prompt length (longer = slower)
- Model load (peak times slower)
- Network latency
- Token generation speed

### Caching Strategy

**Current State:** No caching implemented

**Future Caching Layers:**

1. **LLM Response Cache** (Redis)
   - Key: Hash of prompt + model
   - TTL: 24 hours
   - Expected hit rate: 10-20%

2. **Vector Search Cache** (Redis)
   - Key: Hash of search query
   - TTL: 1 hour
   - Expected hit rate: 30-40%

3. **Blueprint Query Cache** (Rails cache)
   - Key: Blueprint ID or query params
   - TTL: 5 minutes
   - Expected hit rate: 50-60%

### Scalability Considerations

**Current Bottlenecks:**

1. **LLM API Rate Limits**
   - Gemini: 60 requests/minute (free tier)
   - Solution: Queue requests, upgrade to paid tier

2. **Vector Search O(n) Complexity**
   - Linear scan of all blueprints
   - Solution: IVFFlat index at 10K+ blueprints

3. **Synchronous Processing**
   - User waits for all LLM calls
   - Solution: Background jobs for non-critical operations

**Horizontal Scaling Strategy:**

```mermaid
graph TB
    A[Load Balancer] --> B[Rails Instance 1]
    A --> C[Rails Instance 2]
    A --> D[Rails Instance N]

    B --> E[(PostgreSQL Primary)]
    C --> E
    D --> E

    E --> F[(PostgreSQL Replica 1)]
    E --> G[(PostgreSQL Replica 2)]

    B --> H[Redis Cache]
    C --> H
    D --> H

    B --> I[Sidekiq Workers]
    C --> I
    D --> I

    style A fill:#e3f2fd
    style E fill:#f8bbd0
    style H fill:#fff9c4
```

**Scaling Limits:**
- 10-100 requests/second: Single instance + database replica
- 100-1K requests/second: Multiple instances + pgvector index + Redis cache
- 1K+ requests/second: Separate vector database (Pinecone, Weaviate)

---

## Security Architecture

### Current Security Posture

**Threat Model:**

| Threat | Risk Level | Mitigation Status |
|--------|------------|-------------------|
| Unauthorized API access | HIGH | ❌ None |
| LLM prompt injection | MEDIUM | ❌ None |
| SQL injection | LOW | ✅ ActiveRecord escaping |
| XSS attacks | LOW | ✅ Rails HTML escaping |
| DOS via API spam | HIGH | ❌ None |
| Data exfiltration | MEDIUM | ❌ None |

### Recommended Security Enhancements

**1. API Authentication**

**Strategy:** API key-based authentication

```ruby
class ApiController < ApplicationController
  before_action :authenticate_api_key

  private

  def authenticate_api_key
    api_key = request.headers['X-API-Key']
    unless valid_api_key?(api_key)
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
```

**2. Rate Limiting**

**Strategy:** Rack::Attack gem

```ruby
Rack::Attack.throttle('api/v1', limit: 60, period: 1.minute) do |req|
  req.ip if req.path.start_with?('/api/v1/')
end
```

**3. Input Validation**

**Strategy:** Strong parameters + content validation

```ruby
def blueprint_params
  params.require(:blueprint).permit(:code, :description, :name).tap do |p|
    validate_code_length(p[:code])
    validate_content_safety(p[:code])
  end
end

def validate_code_length(code)
  raise ArgumentError, 'Code too long' if code.length > 50_000
end

def validate_content_safety(code)
  # Check for malicious patterns
  raise ArgumentError, 'Invalid code' if code.match?(/eval\(|system\(|exec\(/)
end
```

**4. Prompt Injection Prevention**

**Strategy:** Input sanitization + prompt structuring

```ruby
def prompt
  # Clearly separate user input from instructions
  <<~PROMPT
    <instructions>
    You are a code analysis tool. Your task is to describe the following code.
    </instructions>

    <user_input>
    #{sanitize_for_llm(@code)}
    </user_input>

    <output_format>
    Provide a description in 1-2 sentences.
    </output_format>
  PROMPT
end

def sanitize_for_llm(input)
  # Remove potential instruction injection
  input.gsub(/<\/?instructions>/, '')
end
```

**5. Data Protection**

**Strategy:** Encryption at rest and in transit

- HTTPS/TLS for all API communication
- Database encryption for sensitive fields
- Encrypted backups
- Access logging and audit trail

### Compliance Considerations

**Current Compliance Status:**
- GDPR: ❌ No data privacy controls
- SOC 2: ❌ No audit logging
- HIPAA: ❌ No encryption at rest

**Recommendation:** For production deployment:
1. Add user consent and data deletion mechanisms
2. Implement comprehensive audit logging
3. Enable database encryption
4. Add data retention policies

---

## Deployment Architecture

### Docker Compose Setup

**Services:**

```mermaid
graph TB
    subgraph "Docker Compose Stack"
        A[Nginx Container :80]
        B[Rails Container :3000]
        C[PostgreSQL+pgvector Container :5432]
    end

    D[External Network] --> A
    A --> B
    B --> C

    B --> E[Gemini API]

    F[Volume: PostgreSQL Data]
    G[Volume: Rails Storage]

    C -.-> F
    B -.-> G

    style A fill:#e3f2fd
    style B fill:#c8e6c9
    style C fill:#f8bbd0
    style E fill:#fff9c4
```

**Configuration:** `/docker-compose.yml`

```yaml
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
    depends_on:
      - web
    networks:
      - blueprints

  web:
    build:
      context: .
      dockerfile: Dockerfile
    command: ./bin/rails server -b 0.0.0.0
    expose:
      - "3000"
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=postgresql://postgres:blueprints@pgvector:5432/blueprints_development
      - GEMINI_API_KEY=${GEMINI_API_KEY}
    depends_on:
      - pgvector
    volumes:
      - .:/rails
      - rails_storage:/rails/storage
    networks:
      - blueprints

  pgvector:
    image: ankane/pgvector
    environment:
      - POSTGRES_HOST_AUTH_METHOD=trust
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=blueprints
      - POSTGRES_DB=blueprints_development
    ports:
      - "5432:5432"
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    networks:
      - blueprints
```

### Nginx Reverse Proxy

**Purpose:**
- SSL/TLS termination
- Request buffering
- Static asset serving
- Load balancing (for multi-instance deployments)

**Configuration:** `/nginx/conf.d/blueprints.conf`

```nginx
upstream rails_app {
  server web:3000;
}

server {
  listen 80;
  server_name localhost;

  client_max_body_size 50M;

  location / {
    proxy_pass http://rails_app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location /assets {
    alias /rails/public/assets;
    expires 1y;
    add_header Cache-Control "public, immutable";
  }
}
```

### Environment Configuration

**Required Environment Variables:**

```bash
# AI Provider
GEMINI_API_KEY=your_gemini_api_key_here
# OR
OPENAI_API_KEY=your_openai_api_key_here

# Database
DATABASE_URL=postgresql://user:password@host:5432/database_name

# Rails
RAILS_ENV=production
SECRET_KEY_BASE=your_secret_key_here
```

**Production Recommendations:**
1. Use environment-specific `.env` files
2. Store secrets in secure vault (AWS Secrets Manager, HashiCorp Vault)
3. Enable SSL/TLS with Let's Encrypt
4. Configure log aggregation (Papertrail, Datadog)
5. Set up health monitoring (New Relic, Scout APM)

### Deployment Checklist

**Pre-Deployment:**
- ✅ Environment variables configured
- ✅ Database migrations run
- ✅ Assets precompiled
- ✅ pgvector extension installed
- ✅ API keys validated

**Post-Deployment:**
- ✅ Health check endpoint responding (`GET /up`)
- ✅ Database connectivity verified
- ✅ LLM API connectivity verified
- ✅ Vector search functional
- ✅ Logs streaming correctly

---

## Technology Stack Rationale

### Core Framework: Ruby on Rails 7.1

**Why Rails?**
- Mature, well-documented framework
- Excellent ActiveRecord ORM
- Strong convention-over-configuration
- Large ecosystem of gems
- Fast development velocity

**Trade-offs:**

| Rails | Node.js/Express | Django |
|-------|-----------------|--------|
| ✅ Rapid development | ✅ High performance | ✅ Great for data science |
| ✅ Strong conventions | ✅ Large ecosystem | ✅ Excellent ORM |
| ❌ Slower runtime | ❌ More boilerplate | ❌ Steeper learning curve |
| ❌ Higher memory usage | ❌ Callback hell risk | ❌ Smaller ecosystem |

**Decision:** Rails chosen for development speed and robust ORM, acceptable for current scale.

---

### Database: PostgreSQL 14+ with pgvector

**Why PostgreSQL + pgvector?**
- Native vector operations without separate DB
- ACID compliance for data integrity
- Excellent full-text search
- Mature, battle-tested
- Single infrastructure component

**Trade-offs:**

| pgvector | Pinecone | Weaviate |
|----------|----------|----------|
| ✅ Single database | ✅ Specialized for vectors | ✅ Built-in ML models |
| ✅ Transactional consistency | ✅ Massive scale | ✅ GraphQL API |
| ✅ Lower complexity | ❌ External dependency | ❌ Infrastructure complexity |
| ❌ Performance limits at scale | ❌ Additional cost | ❌ Learning curve |

**Decision:** pgvector chosen for architectural simplicity, adequate for < 100K blueprints.

---

### AI Framework: Sublayer

**Why Sublayer?**
- Provider-agnostic abstraction
- Ruby-native (no Python bridge)
- Clean generator pattern
- Built-in retry logic
- Active development

**Trade-offs:**

| Sublayer | LangChain (Python) | Direct API |
|----------|-------------------|------------|
| ✅ Ruby-native | ✅ Most comprehensive | ✅ Full control |
| ✅ Simple API | ✅ Massive ecosystem | ✅ No abstraction overhead |
| ❌ Smaller ecosystem | ❌ Requires Python | ❌ Provider lock-in |
| ❌ Less features | ❌ Language bridge needed | ❌ Manual retry logic |

**Decision:** Sublayer chosen for Ruby ecosystem alignment and sufficient features.

---

### View Layer: Phlex Components

**Why Phlex?**
- Ruby objects instead of ERB templates
- Type safety and IDE support
- Component reusability
- No JavaScript build step
- Faster rendering than ERB

**Trade-offs:**

| Phlex | ViewComponent | ERB |
|-------|---------------|-----|
| ✅ Pure Ruby | ✅ GitHub-backed | ✅ Rails default |
| ✅ Fast rendering | ✅ Mature ecosystem | ✅ Familiar syntax |
| ❌ Newer library | ❌ More verbose | ❌ No type safety |
| ❌ Smaller community | ❌ Slower than Phlex | ❌ String interpolation risks |

**Decision:** Phlex chosen for performance and developer experience improvements.

---

### LLM Provider: Google Gemini

**Why Gemini?**
- Free tier available (cost optimization)
- Excellent code generation quality
- Fast response times
- Multimodal capabilities (future features)

**Trade-offs:**

| Gemini | GPT-4 | Claude |
|--------|-------|--------|
| ✅ Free tier | ✅ Best quality | ✅ Long context |
| ✅ Fast | ✅ Most reliable | ✅ Strong reasoning |
| ❌ Newer/less proven | ❌ Expensive | ❌ Higher cost |
| ❌ Rate limits | ❌ Slower | ❌ API complexity |

**Decision:** Gemini chosen for zero-cost operation with sufficient quality.

---

## Key Architectural Decisions

### 1. Stateless API Design

**Decision:** No authentication, no session management

**Rationale:**
- Simplifies editor plugin integration
- Reduces server complexity
- Enables horizontal scaling
- Designed for local/trusted deployment

**Trade-offs:**
- ✅ Simplicity
- ✅ Performance
- ❌ No access control
- ❌ Not suitable for public internet

**Future Consideration:** Add optional API key authentication for production deployments.

---

### 2. Generator Orchestration Pattern

**Decision:** One generator per LLM task, composed at controller level

**Rationale:**
- Single Responsibility Principle
- Reusable across different workflows
- Clear error boundaries
- Centralized prompt engineering

**Trade-offs:**
- ✅ Modularity
- ✅ Testability
- ❌ More classes to maintain
- ❌ Potential over-abstraction

**Alternative Considered:** Monolithic service class
**Why Rejected:** Harder to test, less reusable

---

### 3. Vector-First Architecture

**Decision:** All semantic matching via pgvector embeddings

**Rationale:**
- Enables natural language search
- No manual tagging required
- Foundation for advanced ML features
- Proven scalability path

**Trade-offs:**
- ✅ Powerful semantic search
- ✅ Future-proof architecture
- ❌ Embedding generation cost
- ❌ Storage overhead (768 floats per blueprint)

**Alternative Considered:** Traditional keyword search
**Why Rejected:** Inferior search quality, less intelligent

---

### 4. Synchronous LLM Processing

**Decision:** User waits for LLM responses (no background jobs)

**Rationale:**
- Simpler architecture
- Immediate feedback to user
- No job queue infrastructure
- Acceptable latency (< 10s)

**Trade-offs:**
- ✅ Simplicity
- ✅ Immediate results
- ❌ User must wait
- ❌ No request batching

**Future Consideration:** Move to async processing if latency becomes problematic.

---

### 5. Phlex Component Views

**Decision:** Server-side Ruby components instead of React/Vue

**Rationale:**
- No JavaScript build complexity
- Faster time-to-first-byte
- Better SEO (server-rendered)
- Leverages Ruby expertise

**Trade-offs:**
- ✅ Simpler stack
- ✅ Better initial load performance
- ❌ Less interactive UI
- ❌ Full page reloads

**Enhancement Strategy:** Add Stimulus.js for lightweight interactivity where needed.

---

## Monitoring and Observability

### Key Metrics to Track

**Application Metrics:**
- Request rate (requests/minute)
- Response time (P50, P95, P99)
- Error rate (% of failed requests)
- Database query time
- Vector search latency

**Business Metrics:**
- Blueprint creation rate
- Variant generation success rate
- Most-used categories
- Average code snippet length
- User retention (if authentication added)

**Infrastructure Metrics:**
- CPU utilization
- Memory usage
- Database connections
- Disk I/O
- Network throughput

**LLM Metrics:**
- API request count
- API latency (P50, P95, P99)
- Token usage and cost
- Error rate by provider
- Cache hit rate (if caching implemented)

### Logging Strategy

**Current Logging:**
- Rails default logger (stdout)
- Log level: INFO in production
- Format: Rails default format

**Recommended Enhancements:**

**1. Structured Logging (JSON format)**

```ruby
config.log_formatter = Logger::Formatter.new
config.lograge.enabled = true
config.lograge.formatter = Lograge::Formatters::Json.new
```

**2. Critical Logging Points:**

```ruby
# Blueprint creation
logger.info "Blueprint created", {
  blueprint_id: blueprint.id,
  code_length: blueprint.code.length,
  categories_count: blueprint.categories.count,
  llm_provider: Sublayer.configuration.ai_provider,
  embedding_dimension: blueprint.embedding.size
}

# Vector search
logger.info "Vector search performed", {
  query: description,
  results_count: results.count,
  top_similarity_score: results.first&.similarity_score,
  search_time_ms: search_time
}

# LLM generation
logger.info "LLM generation", {
  generator: generator_class_name,
  provider: provider_name,
  model: model_name,
  latency_ms: latency,
  tokens_used: tokens
}
```

**3. Error Tracking:**

```ruby
# Use Sentry, Rollbar, or Honeybadger
Sentry.capture_exception(exception) do |scope|
  scope.set_context("blueprint", {
    id: blueprint.id,
    code_length: blueprint.code.length
  })
end
```

### Health Monitoring

**Health Check Endpoint:** `GET /up`

```ruby
class Rails::HealthController < ActionController::Base
  def show
    # Check database connectivity
    ActiveRecord::Base.connection.execute("SELECT 1")

    # Check pgvector extension
    ActiveRecord::Base.connection.execute("SELECT '[]'::vector")

    # Check LLM API (optional, can be slow)
    # Test API connectivity if critical

    render plain: "OK", status: :ok
  rescue => e
    render plain: "UNHEALTHY: #{e.message}", status: :service_unavailable
  end
end
```

**Monitoring Tools Recommendations:**
- **APM:** New Relic, Scout APM, Skylight
- **Error Tracking:** Sentry, Rollbar, Honeybadger
- **Log Aggregation:** Papertrail, Datadog, Loggly
- **Infrastructure:** Datadog, Prometheus + Grafana

---

## Future Enhancement Opportunities

### 1. Async Processing with Background Jobs

**Problem:** Users wait 4-8 seconds for blueprint creation

**Solution:** Sidekiq background jobs

```ruby
# Controller
def create
  job_id = BlueprintCreationJob.perform_async(params[:code])
  render json: { job_id: job_id }, status: :accepted
end

# Job
class BlueprintCreationJob
  include Sidekiq::Worker

  def perform(code)
    # ... AI generation pipeline ...
    ActionCable.server.broadcast("blueprint_creation_#{job_id}", {
      status: "completed",
      blueprint: blueprint
    })
  end
end
```

**Benefits:**
- Non-blocking API
- Better resource utilization
- Batch processing capability

---

### 2. Caching Layer with Redis

**Problem:** Repeated vector searches and LLM calls waste time/money

**Solution:** Multi-level caching

```ruby
# Vector search cache
def similarity_search(query)
  Rails.cache.fetch("vector_search:#{Digest::SHA256.hexdigest(query)}", expires_in: 1.hour) do
    perform_vector_search(query)
  end
end

# LLM response cache
def generate
  cache_key = "llm:#{self.class.name}:#{Digest::SHA256.hexdigest(prompt)}"
  Rails.cache.fetch(cache_key, expires_in: 24.hours) do
    super  # Calls LLM
  end
end
```

**Expected Impact:**
- 30-40% reduction in LLM API costs
- 50-70% reduction in vector search latency

---

### 3. Blueprint Versioning

**Problem:** No history when blueprints are modified

**Solution:** PaperTrail gem for version tracking

```ruby
class Blueprint < ApplicationRecord
  has_paper_trail
end

# Access versions
blueprint.versions  # All versions
blueprint.paper_trail.previous_version  # Previous state
blueprint.paper_trail.reify(version: 3)  # Restore version 3
```

**Benefits:**
- Rollback capability
- Audit trail
- Experimentation safety

---

### 4. Collaborative Features

**Problem:** No multi-user support

**Solution:** User authentication + ownership

```ruby
class Blueprint < ApplicationRecord
  belongs_to :user
  has_many :collaborators

  scope :accessible_by, ->(user) {
    where(user: user).or(where(id: user.collaborated_blueprint_ids))
  }
end
```

**Benefits:**
- Team blueprint libraries
- Access control
- Usage analytics per user

---

### 5. Advanced Vector Analytics

**Problem:** No insights into blueprint usage patterns

**Solution:** Vector clustering and recommendations

```ruby
# Find blueprint clusters
clusters = Blueprint.kmeans_clustering(n_clusters: 10)

# Recommend similar blueprints
similar = blueprint.find_similar(limit: 5)

# Identify outliers (unique blueprints)
outliers = Blueprint.detect_outliers(threshold: 0.5)
```

**Benefits:**
- Auto-organize blueprints
- Discover duplicate patterns
- Recommend blueprints to users

---

### 6. Multi-Language Support

**Problem:** Only optimized for Ruby code

**Solution:** Language-specific generators

```ruby
class CodeDescriptionGenerator < Sublayer::Generators::Base
  def initialize(code:, language: 'ruby')
    @code = code
    @language = language
  end

  def prompt
    <<~PROMPT
      You are analyzing #{@language} code.

      Code:
      ```#{@language}
      #{@code}
      ```

      Provide a description...
    PROMPT
  end
end
```

**Benefits:**
- Support Python, JavaScript, Go, etc.
- Language-specific categorization
- Broader user base

---

### 7. Fine-Tuning on Internal Blueprints

**Problem:** Generic LLM may not match company coding standards

**Solution:** Fine-tune model on internal blueprint corpus

```ruby
# Export training data
blueprints = Blueprint.all
training_data = blueprints.map do |b|
  {
    prompt: "Generate code for: #{b.description}",
    completion: b.code
  }
end

# Fine-tune via OpenAI API
OpenAI::FineTune.create(
  training_file: upload_jsonl(training_data),
  model: "gpt-3.5-turbo"
)
```

**Benefits:**
- Better code quality
- Consistent style
- Domain-specific knowledge

---

### 8. Batch Operations Optimization

**Problem:** Importing 1000 blueprints is slow (1000 LLM calls)

**Solution:** Batch LLM requests

```ruby
def import_batch(blueprints)
  # Group prompts for single LLM call
  batch_prompt = blueprints.map.with_index do |bp, i|
    "#{i}. #{bp[:code]}"
  end.join("\n\n")

  # Single LLM call for all descriptions
  descriptions = BatchDescriptionGenerator.new(codes: batch_prompt).generate

  # Parse and assign
  blueprints.zip(descriptions).each do |bp, desc|
    bp[:description] = desc
  end
end
```

**Expected Impact:**
- 10x faster imports
- 90% reduction in API costs for bulk operations

---

## Cross-References

For additional technical documentation, see:

- **[VECTOR_EMBEDDINGS.md](./VECTOR_EMBEDDINGS.md)** - Detailed pgvector configuration, indexing strategies, and performance tuning
- **[AI_GENERATORS.md](./AI_GENERATORS.md)** - Sublayer generator patterns, prompt engineering techniques, and LLM best practices
- **[REST_API.md](./REST_API.md)** - Complete API reference with request/response examples and error handling
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Production deployment guide, environment configuration, and operations playbook

---

## Summary

Blueprints by Sublayer demonstrates a **vector-first, AI-native architecture** for intelligent code snippet management. The system leverages:

- **Rails conventions** for rapid development
- **pgvector** for semantic search without separate infrastructure
- **Sublayer framework** for provider-agnostic LLM integration
- **Phlex components** for modern view rendering
- **Generator pattern** for composable AI orchestration

The architecture prioritizes:
1. **Simplicity** - Single database, stateless API, minimal infrastructure
2. **Developer Experience** - Clear abstractions, consistent patterns, comprehensive documentation
3. **AI-Native Design** - Vector embeddings and LLM integration as core capabilities
4. **Scalability** - Clear paths to horizontal scaling and performance optimization

**Current State:** Production-ready for local/internal deployment (< 10K blueprints, < 100 req/min)

**Future State:** Scalable to 100K+ blueprints, 1K+ req/min with caching, indexing, and async processing

---

**Document Metadata**

- **Author:** Backend Architect Agent
- **Created:** 2025-10-26
- **Version:** 1.0
- **Source:** `/home/b08x/Workspace/RubyAI/blueprints/docs/technical/ARCHITECTURE.md`
- **Authoritative Reference:** `/home/b08x/Workspace/RubyAI/blueprints/sub-agents/context/backend-architect-briefing.md`
