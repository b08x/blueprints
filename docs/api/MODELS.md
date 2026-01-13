# Data Models Reference - Blueprints by Sublayer

**Version:** 1.0
**Last Updated:** 2025-10-26
**Purpose:** Developer guide to working with Blueprint and Category models

---

## Table of Contents

1. [Blueprint Model](#blueprint-model)
2. [Category Model](#category-model)
3. [Relationships](#relationships)
4. [Validations](#validations)
5. [Callbacks](#callbacks)
6. [Query Examples](#query-examples)
7. [Factory Examples](#factory-examples)
8. [Vector Integration](#vector-integration)

---

## Blueprint Model

### Location
`/app/models/blueprint.rb`

### Database Table: `blueprints`

```sql
CREATE TABLE blueprints (
  id BIGSERIAL PRIMARY KEY,
  code TEXT NOT NULL,
  description TEXT,
  name VARCHAR,
  embedding vector(768),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_blueprints_name ON blueprints(name);
CREATE INDEX idx_blueprints_updated_at ON blueprints(updated_at DESC);
```

### Attributes

| Attribute | Type | Description | Default | Validation |
|-----------|------|-------------|---------|-----------|
| `id` | BigInteger | Primary key | Auto | Unique, not null |
| `code` | Text | Source code content | - | Not blank, not null |
| `description` | Text | Functional description (AI-generated or custom) | - | - |
| `name` | String | Short identifier (AI-generated or custom) | - | Unique with scope |
| `embedding` | Vector(768) | Semantic embedding for similarity search | - | Auto-generated |
| `created_at` | DateTime | Creation timestamp | NOW() | Auto |
| `updated_at` | DateTime | Last modification timestamp | NOW() | Auto |

### Associations

```ruby
class Blueprint < ApplicationRecord
  # Many-to-many relationship with categories
  has_and_belongs_to_many :categories,
    class_name: 'Category',
    join_table: 'blueprints_categories'
end
```

**Related Model:**
```ruby
blueprint.categories
# => [#<Category id: 1, title: "authentication">, ...]

blueprint.categories.pluck(:title)
# => ["authentication", "security", "rails"]
```

### Validations

```ruby
class Blueprint < ApplicationRecord
  validates :code, presence: true

  validates :name, uniqueness: {
    scope: %i[description code],
    message: "must be unique in combination with description and code"
  }
end
```

**Validation Rules:**

1. **code is required** - Cannot create blueprint without code
2. **Composite uniqueness** - (name, description, code) tuple must be unique
   - Same code + different description = allowed (different blueprint)
   - Same code + same description + different name = allowed
   - Exact same (code + description + name) = prevented (duplicate)

**Validation Examples:**

```ruby
# Valid: Code only
Blueprint.create(code: "def hello; 'world'; end")
# → Creates with AI-generated name, description, categories

# Invalid: No code
Blueprint.create(code: "")
# → ValidationError: Code can't be blank

# Valid: Different description
Blueprint.create(
  code: "def hello; 'world'; end",
  description: "Different description"
)
# → Creates successfully (different from previous despite same code)

# Invalid: Exact duplicate
Blueprint.create(
  code: "def hello; 'world'; end",
  description: "Print hello world",
  name: "Hello World"
)
# → ValidationError: Name has already been taken
```

### Key Methods

#### `nearest_neighbors(query_text, limit: 5)`

Find semantically similar blueprints using vector search.

```ruby
# Find blueprints most similar to a query
similar = Blueprint.nearest_neighbors("authentication system", limit: 5)

similar.each do |bp|
  puts "#{bp.name} (similarity: #{bp.similarity_score})"
end

# Output:
# User Authentication Module (similarity: 0.87)
# JWT Authentication Handler (similarity: 0.82)
# Session Manager (similarity: 0.76)
# ...
```

**Implementation Details:**
- Uses pgvector cosine similarity
- Searches across all blueprints in database
- O(n) complexity (full table scan for < 10K blueprints)
- Returns ordered by similarity descending
- Similarity score: 0.0 (completely different) to 1.0 (identical)

**Parameters:**
- `query_text` (String): Natural language query or code description
- `limit` (Integer): Maximum results (default: 5)

**Returns:**
- ActiveRecord::Relation with `similarity_score` attribute

---

#### `generate_embedding`

Auto-generates vector embedding from blueprint content. Called automatically before save.

```ruby
# Manual call (usually automatic)
blueprint.generate_embedding

# Embedding is auto-generated on:
# 1. blueprint.save (new or modified)
# 2. blueprint.update
# 3. blueprint.update_attribute(:code)
```

**Process:**
1. Calls `as_vector` method to get JSON representation
2. Sends to embedding service (OpenAI Ada-002)
3. Returns 768-dimensional vector
4. Stores in `embedding` column

**Latency:** 200-500ms per embedding

---

#### `as_vector`

Defines what gets embedded as a vector (name + description).

```ruby
def as_vector
  { description: description, name: name }.to_json
end

# Example output:
# '{"description":"Print hello world","name":"Hello Printer"}'
```

**Why not full code?**
- Code is implementation detail (too much noise)
- Name + description captures semantic intent
- Reduces embedding cost (fewer tokens)
- Better similarity search quality

---

#### `build_categories_from_text(text)`

Parse comma-separated categories and associate with blueprint.

```ruby
categories_text = "Ruby, Rails, Authentication, Security"
blueprint.build_categories_from_text(categories_text)

blueprint.categories.pluck(:title)
# => ["ruby", "rails", "authentication", "security"]
```

**Process:**
1. Splits text by comma
2. Strips whitespace
3. Finds or creates each category (lowercased)
4. Associates with blueprint
5. Prevents duplicates

**Example with LLM Output:**
```ruby
description = CodeDescriptionGenerator.new(code: code).generate
# → "Authenticates users with JWT"

name = NameFromCodeAndDescriptionGenerator.new(
  code: code,
  description: description
).generate
# → "JWT Authentication Helper"

categories_text = CategoriesFromCodeGenerator.new(code: code).generate
# → "Ruby, Rails, Authentication, JWT, Security"

blueprint = Blueprint.new(code: code, description: description, name: name)
blueprint.build_categories_from_text(categories_text)
blueprint.save!
```

---

### Callbacks

```ruby
class Blueprint < ApplicationRecord
  before_save :generate_embedding, if: :should_generate_embedding?
  after_save :upsert_to_vectorsearch, if: :saved_changes?

  private

  def should_generate_embedding?
    code_changed? || description_changed? || name_changed? || new_record?
  end
end
```

**Callback Chain on Save:**

```
1. before_save :generate_embedding
   ↓ (generates 768-dim vector from name+description)
   ↓
2. Validations run
   ↓
3. Database INSERT/UPDATE
   ↓
4. after_save :upsert_to_vectorsearch
   ↓ (updates vector search index)
   ↓
5. Return blueprint instance
```

**Performance Impact:**
- `generate_embedding`: 200-500ms (API call to embedding service)
- `upsert_to_vectorsearch`: 10-50ms (database operation)
- Total overhead: ~250-550ms per save operation

---

### Query Examples

**Basic Queries**

```ruby
# Find by ID
blueprint = Blueprint.find(42)

# Find by name
blueprint = Blueprint.find_by(name: "Hello World Printer")

# All blueprints
blueprints = Blueprint.all

# Count
Blueprint.count  # => 42
```

**Filtering**

```ruby
# By category
Blueprint.joins(:categories)
  .where(categories: { title: 'authentication' })

# By name pattern
Blueprint.where("name ILIKE ?", "%hello%")

# By created date
Blueprint.where(created_at: 1.day.ago..Time.current)

# By code length
Blueprint.where("LENGTH(code) > ?", 500)
```

**Pagination**

```ruby
# Limit and offset
Blueprint.order(updated_at: :desc).limit(20).offset(40)

# With Rails will_paginate gem
Blueprint.paginate(page: 2, per_page: 25)

# With kaminari gem
Blueprint.page(2).per(25)
```

**Associations**

```ruby
# Load with categories
blueprints = Blueprint.includes(:categories)

# Filter blueprints that have specific category
blueprints = Blueprint.joins(:categories)
  .where(categories: { title: 'rails' })
  .distinct

# Get category names for blueprint
blueprint.categories.pluck(:title)
# => ["ruby", "rails", "patterns"]

# Check if blueprint has category
blueprint.categories.map(&:title).include?('authentication')
# => true
```

**Sorting**

```ruby
# By creation date (newest first)
Blueprint.order(created_at: :desc)

# By last modified
Blueprint.order(updated_at: :desc)

# By name (alphabetical)
Blueprint.order(name: :asc)

# By code length
Blueprint.select("blueprints.*, LENGTH(code) as code_length")
  .order("code_length DESC")
```

**Vector Search**

```ruby
# Find similar blueprints
similar = Blueprint.nearest_neighbors("authentication system")

# With limit
similar = Blueprint.nearest_neighbors("JWT token validation", limit: 10)

# Get similarity score
similar.each do |bp|
  puts "#{bp.name}: #{bp.similarity_score.round(2)}"
end
```

---

### Destruction

```ruby
# Delete single blueprint
blueprint.destroy

# Delete multiple
Blueprint.where(created_at: ..3.months.ago).destroy_all

# On delete:
# - Blueprint record removed
# - All associations in blueprints_categories join table removed
# - Vector embedding removed
```

---

## Category Model

### Location
`/app/models/category.rb`

### Database Table: `categories`

```sql
CREATE TABLE categories (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR UNIQUE NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX idx_categories_title ON categories(title);
```

### Attributes

| Attribute | Type | Description | Validation |
|-----------|------|-------------|-----------|
| `id` | BigInteger | Primary key | Unique, not null |
| `title` | String | Category name | Unique, not blank, auto-lowercased |
| `created_at` | DateTime | Creation timestamp | Auto |
| `updated_at` | DateTime | Last modification | Auto |

### Associations

```ruby
class Category < ApplicationRecord
  has_and_belongs_to_many :blueprints,
    class_name: 'Blueprint',
    join_table: 'blueprints_categories'
end
```

**Related Models:**
```ruby
category.blueprints
# => [#<Blueprint id: 1, name: "User Auth">, ...]

category.blueprints.count
# => 5 (5 blueprints in this category)
```

### Validations

```ruby
class Category < ApplicationRecord
  validates :title, presence: true, uniqueness: true

  before_save :downcase_title

  private

  def downcase_title
    title.downcase!
  end
end
```

**Validation Rules:**

1. **title is required** - Cannot be blank
2. **title is unique** - No duplicate categories
3. **title is lowercased** - Always stored in lowercase

**Examples:**

```ruby
# Valid
Category.create(title: "Authentication")
# → Stored as "authentication"

# Valid (automatic lowercasing)
Category.create(title: "RAILS")
# → Stored as "rails"

# Invalid (duplicate)
Category.create(title: "authentication")
# → ValidationError: Title has already been taken

# Invalid (blank)
Category.create(title: "")
# → ValidationError: Title can't be blank
```

### Key Methods

#### `find_or_create_by(title:)`

Find category by title or create if doesn't exist.

```ruby
category = Category.find_or_create_by(title: "Authentication")

# First call: Creates category "authentication"
# Second call: Returns existing "authentication"
# Always returns category with title "authentication" (lowercased)
```

**Usage in Blueprint Creation:**

```ruby
categories_text = "Ruby, Rails, Authentication"

categories_text.split(",").map(&:strip).each do |cat_title|
  category = Category.find_or_create_by(title: cat_title.downcase)
  blueprint.categories << category
end

# Result:
# blueprint.categories
# => [#<Category title: "ruby">, #<Category title: "rails">, ...]
```

### Query Examples

**Find Categories**

```ruby
# Get all categories
Category.all

# Find by title
Category.find_by(title: "authentication")

# Find with blueprints (eager load)
Category.includes(:blueprints)

# Count blueprints in category
category.blueprints.count
# => 3

# Get blueprints in category
category.blueprints
# => [#<Blueprint name: "JWT Auth">, ...]
```

**Filter by Blueprint Count**

```ruby
# Categories with at least 2 blueprints
Category.joins(:blueprints)
  .group("categories.id")
  .having("COUNT(blueprints.id) >= 2")

# Most used categories
Category.joins(:blueprints)
  .group("categories.id")
  .select("categories.*, COUNT(blueprints.id) as blueprint_count")
  .order("blueprint_count DESC")
```

**Sorting**

```ruby
# Alphabetical
Category.order(title: :asc)

# Most recently created
Category.order(created_at: :desc)

# By number of blueprints
Category.joins(:blueprints)
  .group("categories.id")
  .select("categories.*, COUNT(blueprints.id) as count")
  .order("count DESC")
```

---

## Relationships

### Blueprint ↔ Category (Many-to-Many)

**Join Table: `blueprints_categories`**

```sql
CREATE TABLE blueprints_categories (
  blueprint_id BIGINT NOT NULL REFERENCES blueprints(id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  PRIMARY KEY (blueprint_id, category_id)
);

CREATE INDEX idx_blueprints_categories_blueprint ON blueprints_categories(blueprint_id);
CREATE INDEX idx_blueprints_categories_category ON blueprints_categories(category_id);
```

**Rails Association:**

```ruby
class Blueprint < ApplicationRecord
  has_and_belongs_to_many :categories
end

class Category < ApplicationRecord
  has_and_belongs_to_many :blueprints
end
```

### Adding/Removing Categories

```ruby
blueprint = Blueprint.find(42)

# Add category
category = Category.find_or_create_by(title: "authentication")
blueprint.categories << category

# Remove category
blueprint.categories.delete(category)

# Replace all categories
blueprint.categories = [Category.find_by(title: "ruby"), Category.find_by(title: "rails")]

# Check associations
blueprint.categories.exists?(category)  # => true/false
blueprint.categories.any? { |c| c.title == "rails" }  # => true/false
```

### Cascade Deletion

When deleting a blueprint or category, associations are automatically cleaned up:

```ruby
blueprint.destroy
# → Removes blueprint and all its category associations
# → Categories themselves are NOT deleted (other blueprints may reference them)

category.destroy
# → Removes category and all its blueprint associations
# → Blueprints themselves are NOT deleted
```

---

## Factory Examples

### For Testing

**Location:** `/spec/factories/blueprint_factory.rb`

```ruby
FactoryBot.define do
  factory :blueprint do
    code { "def hello\n  'world'\nend" }
    description { "A simple Ruby method that returns 'world'" }
    name { "Hello World Method" }

    trait :with_categories do
      after(:create) do |blueprint|
        ['ruby', 'hello', 'example'].each do |title|
          category = create(:category, title: title)
          blueprint.categories << category
        end
      end
    end

    trait :large_code do
      code { "class ComplexClass\n" + ("  def method_#{rand(100)}\n    'code'\n  end\n" * 50) + "end" }
    end

    trait :authentication do
      code { "def authenticate(user, password)\n  user.password_hash == hash(password)\nend" }
      description { "Authenticates a user with password validation" }
      name { "User Authentication" }

      after(:create) do |blueprint|
        ['authentication', 'security', 'ruby'].each do |title|
          category = create(:category, title: title)
          blueprint.categories << category
        end
      end
    end
  end

  factory :category do
    sequence(:title) { |n| "category_#{n}".downcase }
  end
end
```

**Usage in Tests:**

```ruby
# Create single blueprint
blueprint = create(:blueprint)

# Create with associations
blueprint = create(:blueprint, :with_categories)

# Create with custom attributes
blueprint = create(:blueprint, code: custom_code, name: "Custom Name")

# Create multiple
blueprints = create_list(:blueprint, 5)

# Create specialized blueprint
auth_blueprint = create(:blueprint, :authentication)
```

### In Database Seeds

**Location:** `/db/seeds.rb`

```ruby
# Clear existing data
Category.delete_all
Blueprint.delete_all

# Create categories
auth_category = Category.create!(title: "authentication")
rails_category = Category.create!(title: "rails")
security_category = Category.create!(title: "security")

# Create blueprints
blueprint1 = Blueprint.create!(
  code: "def authenticate_jwt(token)\n  JWT.decode(token, secret)\nend",
  description: "Authenticates a user using JWT tokens",
  name: "JWT Authentication",
  categories: [auth_category, security_category, rails_category]
)

blueprint2 = Blueprint.create!(
  code: "def hash_password(password)\n  BCrypt::Password.create(password)\nend",
  description: "Hashes a password using bcrypt for secure storage",
  name: "Password Hashing",
  categories: [security_category, rails_category]
)

puts "Created #{Blueprint.count} blueprints and #{Category.count} categories"
```

---

## Vector Integration

### How Embeddings Work

```ruby
blueprint = Blueprint.create!(code: "def hello; 'world'; end")

# Automatically:
# 1. Generates 768-dimensional vector from name+description
# 2. Stores in embedding column
# 3. Indexes for similarity search

blueprint.embedding  # => [0.123, -0.456, 0.789, ...] (768 values)
blueprint.embedding.size  # => 768
```

### Similarity Search

```ruby
# Find 5 most similar blueprints to your description
similar = Blueprint.nearest_neighbors("print greeting to user", limit: 5)

similar.each do |bp|
  puts "#{bp.name}: #{(bp.similarity_score * 100).round(0)}% similar"
end

# Output:
# Hello World Printer: 92% similar
# Greeting Message: 87% similar
# Console Output Helper: 82% similar
```

### Re-generating Embeddings

```ruby
# Automatic (on save)
blueprint.code = new_code
blueprint.save!  # → embedding auto-regenerated

# Manual regeneration
blueprint.generate_embedding
blueprint.save!

# Bulk regenerate (if needed after schema changes)
Blueprint.find_each do |bp|
  bp.generate_embedding
  bp.save
end
```

---

## Common Patterns

### Creating Blueprint with AI Metadata

```ruby
# This is typically done in the API controller
code = params[:code]

# Step 1: Generate metadata via AI
description = Sublayer::Generators::CodeDescriptionGenerator
  .new(code: code)
  .generate

name = Sublayer::Generators::NameFromCodeAndDescriptionGenerator
  .new(code: code, description: description)
  .generate

categories_text = Sublayer::Generators::CategoriesFromCodeGenerator
  .new(code: code)
  .generate

# Step 2: Create blueprint
blueprint = Blueprint.new(
  code: code,
  description: description,
  name: name
)

# Step 3: Associate categories
blueprint.build_categories_from_text(categories_text)

# Step 4: Save (triggers embedding generation)
blueprint.save!

blueprint
```

### Searching and Displaying Results

```ruby
def search_blueprints(query)
  if query.blank?
    Blueprint.order(updated_at: :desc).limit(50)
  else
    Blueprint.nearest_neighbors(query, limit: 50)
  end
end

# Usage
results = search_blueprints("authentication with JWT")

results.each do |bp|
  puts "#{bp.name}"
  puts "  Description: #{bp.description}"
  puts "  Categories: #{bp.categories.pluck(:title).join(', ')}"
  puts "  Similarity: #{bp.similarity_score.round(2)}" if bp.respond_to?(:similarity_score)
end
```

---

## Migration Guide

### Adding New Field to Blueprint

```ruby
# db/migrate/[timestamp]_add_language_to_blueprints.rb
class AddLanguageToBlueprints < ActiveRecord::Migration[7.1]
  def change
    add_column :blueprints, :language, :string, default: 'ruby'
  end
end

# app/models/blueprint.rb
class Blueprint < ApplicationRecord
  validates :language, inclusion: { in: %w(ruby python javascript) }
end
```

### Changing Embedding Dimension

```ruby
# Only if upgrading embedding model to higher dimension
# Current: 768 dimensions
# Never downgrade (data loss)

class UpgradeEmbeddingDimension < ActiveRecord::Migration[7.1]
  def change
    change_column :blueprints, :embedding, 'vector(1536)'

    # Then regenerate all embeddings
    # Run in rake task: bin/rails db:seed or custom script
  end
end
```

---

## Performance Tips

### N+1 Query Prevention

```ruby
# Bad: N+1 queries
blueprints = Blueprint.all
blueprints.each do |bp|
  puts bp.categories.map(&:title).join(', ')  # Query per blueprint
end

# Good: Eager load
blueprints = Blueprint.includes(:categories)
blueprints.each do |bp|
  puts bp.categories.map(&:title).join(', ')  # No additional queries
end
```

### Efficient Bulk Operations

```ruby
# Bad: Individual saves
blueprints.each { |bp| bp.update(name: compute_name(bp)) }

# Good: Bulk update (if only updating one field)
blueprint_ids_and_names = blueprints.map { |bp| [bp.id, compute_name(bp)] }
blueprint_ids_and_names.each do |id, name|
  Blueprint.where(id: id).update_all(name: name)
end

# Best: Use insert_all for bulk creates
Blueprint.insert_all([
  { code: code1, description: desc1 },
  { code: code2, description: desc2 }
])
```

### Vector Search Optimization

```ruby
# For large tables (>10K blueprints), add index:
# db/migrate/[timestamp]_add_vector_index.rb
class AddVectorIndexToBlueprints < ActiveRecord::Migration[7.1]
  def change
    # This requires pgvector HNSW or IVFFlat index
    execute <<-SQL
      CREATE INDEX ON blueprints USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end
end
```

---

## Reference

### Complete Model Diagram

```
┌─────────────────────────┐
│      Blueprint          │
├─────────────────────────┤
│ id (PK)                 │
│ code (TEXT)             │
│ description (TEXT)      │
│ name (VARCHAR)          │
│ embedding (vector(768)) │
│ created_at              │
│ updated_at              │
└──────────┬──────────────┘
           │
           │ (HABTM)
           │
           ▼
┌──────────────────────────┐
│ blueprints_categories    │
├──────────────────────────┤
│ blueprint_id (FK)        │
│ category_id (FK)         │
│ PRIMARY KEY (blueprint,  │
│               category)  │
└──────────────────────────┘
           △
           │ (HABTM)
           │
           │
      ┌────┴────────────┐
      │    Category     │
      ├─────────────────┤
      │ id (PK)         │
      │ title (VARCHAR) │
      │ created_at      │
      │ updated_at      │
      └─────────────────┘
```

---

**Document Version:** 1.0
**Source:** `/home/b08x/Workspace/RubyAI/blueprints/docs/api/MODELS.md`
