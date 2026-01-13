# Phlex Components Reference - Blueprints by Sublayer

**Version:** 1.0
**Last Updated:** 2025-10-26
**Purpose:** Developer guide to reusable UI components built with Phlex

---

## Table of Contents

1. [What is Phlex?](#what-is-phlex)
2. [ApplicationComponent Base Class](#applicationcomponent-base-class)
3. [Component Catalog](#component-catalog)
4. [Using Components](#using-components)
5. [Styling with Tailwind CSS](#styling-with-tailwind-css)
6. [Accessibility Guidelines](#accessibility-guidelines)
7. [Component Patterns](#component-patterns)
8. [Testing Components](#testing-components)

---

## What is Phlex?

### Overview

**Phlex** is a Ruby framework for building type-safe, reusable view components using pure Ruby (not templates).

**Key Benefits:**
- **No template syntax to learn** - Just Ruby classes and methods
- **Type safety** - IDE autocomplete and compile-time error detection
- **Composability** - Easily nest and reuse components
- **Performance** - Faster rendering than ERB templates
- **Maintainability** - Components are just Ruby classes with tests

### Hello World Example

```ruby
class HelloComponent < ApplicationComponent
  def initialize(name:)
    @name = name
  end

  def view_template
    div(class: "greeting") do
      h1 { "Hello, #{@name}!" }
      p { "Welcome to Blueprints" }
    end
  end
end

# Usage in controller:
render HelloComponent.new(name: "Alice")

# Output:
# <div class="greeting">
#   <h1>Hello, Alice!</h1>
#   <p>Welcome to Blueprints</p>
# </div>
```

### Phlex vs Other Approaches

| Feature | Phlex | ERB | ViewComponent |
|---------|-------|-----|---------------|
| Language | Ruby | Template DSL | Ruby |
| IDE Support | Excellent | Poor | Good |
| Performance | Fast | Moderate | Good |
| Learning Curve | Easy | Medium | Easy |
| Type Safety | Yes | No | Limited |
| Testing | Easy | Hard | Good |

---

## ApplicationComponent Base Class

### Location
`/app/views/components/application_component.rb`

### Base Class Definition

```ruby
class ApplicationComponent < Phlex::HTML
  # All custom components inherit from this

  def initialize(**options)
    super()
    @options = options
  end

  # Common helper methods available to all components
  def button_class(variant = :default)
    case variant
    when :primary
      "px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
    when :secondary
      "px-4 py-2 bg-gray-200 text-gray-800 rounded hover:bg-gray-300"
    when :danger
      "px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
    else
      "px-4 py-2 bg-gray-100 text-gray-900 rounded hover:bg-gray-200"
    end
  end

  # Shared state variables
  protected

  attr_reader :options
end
```

### Common Patterns

**Passing Data**
```ruby
class MyComponent < ApplicationComponent
  def initialize(title:, items: [], variant: :default)
    @title = title
    @items = items
    @variant = variant
  end

  def view_template
    div { render_title }
    ul { render_items }
  end

  private

  def render_title
    h2(class: title_class) { @title }
  end

  def render_items
    @items.each { |item| li { item } }
  end

  def title_class
    @variant == :primary ? "text-xl font-bold" : "text-lg"
  end
end
```

---

## Component Catalog

### 1. BlueprintCard Component

**Purpose:** Display a single blueprint in a card layout

**Location:** `/app/views/components/blueprint_card.rb`

```ruby
class BlueprintCard < ApplicationComponent
  def initialize(blueprint:, show_code: true)
    @blueprint = blueprint
    @show_code = show_code
  end

  def view_template
    article(class: "blueprint-card border rounded-lg p-4 shadow-md hover:shadow-lg transition") do
      render_header
      render_description
      render_categories if @blueprint.categories.any?
      render_code if @show_code
      render_actions
    end
  end

  private

  def render_header
    div(class: "mb-3") do
      h3(class: "text-lg font-bold") { @blueprint.name }
      span(class: "text-xs text-gray-500") { @blueprint.created_at.strftime("%b %d, %Y") }
    end
  end

  def render_description
    p(class: "text-gray-700 text-sm mb-3") { @blueprint.description }
  end

  def render_categories
    div(class: "mb-3 flex flex-wrap gap-2") do
      @blueprint.categories.each do |category|
        span(class: "bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded") do
          category.title
        end
      end
    end
  end

  def render_code
    details(class: "mb-3") do
      summary(class: "cursor-pointer font-semibold text-sm") { "View Code" }
      pre(class: "bg-gray-100 p-3 mt-2 rounded text-xs overflow-x-auto") do
        code { @blueprint.code }
      end
    end
  end

  def render_actions
    div(class: "flex gap-2") do
      a(href: blueprint_path(@blueprint), class: button_class(:primary)) do
        "View"
      end
      a(href: edit_blueprint_path(@blueprint), class: button_class(:secondary)) do
        "Edit"
      end
      button(data_method: "delete", data_confirm: "Sure?", class: button_class(:danger)) do
        "Delete"
      end
    end
  end
end
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `blueprint` | Blueprint | Required | Blueprint model instance |
| `show_code` | Boolean | true | Whether to show code in collapsible details |

**Usage:**

```ruby
# In controller or view
blueprint = Blueprint.find(42)
render BlueprintCard.new(blueprint: blueprint)

# With options
render BlueprintCard.new(blueprint: blueprint, show_code: false)
```

**Output Example:**
```html
<article class="blueprint-card border rounded-lg...">
  <div class="mb-3">
    <h3 class="text-lg font-bold">Hello World Printer</h3>
    <span class="text-xs text-gray-500">Oct 26, 2025</span>
  </div>
  <p class="text-gray-700 text-sm mb-3">A simple method that outputs...</p>
  <div class="mb-3 flex flex-wrap gap-2">
    <span class="bg-blue-100...">ruby</span>
    <span class="bg-blue-100...">cli</span>
  </div>
  ...
</article>
```

---

### 2. BlueprintList Component

**Purpose:** Display multiple blueprints in a grid or list layout

**Location:** `/app/views/components/blueprint_list.rb`

```ruby
class BlueprintList < ApplicationComponent
  def initialize(blueprints:, layout: :grid, empty_message: "No blueprints found")
    @blueprints = blueprints
    @layout = layout
    @empty_message = empty_message
  end

  def view_template
    if @blueprints.empty?
      render_empty_state
    else
      render_list
    end
  end

  private

  def render_list
    div(class: container_class) do
      @blueprints.each do |blueprint|
        div(class: item_wrapper_class) do
          render BlueprintCard.new(blueprint: blueprint)
        end
      end
    end
  end

  def render_empty_state
    div(class: "text-center py-12") do
      p(class: "text-gray-500 text-lg") { @empty_message }
      a(href: new_blueprint_path, class: button_class(:primary)) do
        "Create Your First Blueprint"
      end
    end
  end

  def container_class
    case @layout
    when :grid
      "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
    when :list
      "space-y-4"
    else
      "flex flex-col gap-4"
    end
  end

  def item_wrapper_class
    @layout == :grid ? "h-full" : ""
  end
end
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `blueprints` | Array<Blueprint> | Required | Collection of blueprints |
| `layout` | Symbol | :grid | Display layout (:grid or :list) |
| `empty_message` | String | "No blueprints found" | Message when empty |

**Usage:**

```ruby
# In controller
@blueprints = Blueprint.order(updated_at: :desc).limit(50)

# In view
render BlueprintList.new(blueprints: @blueprints, layout: :grid)
```

---

### 3. SearchForm Component

**Purpose:** Reusable search form for blueprints

**Location:** `/app/views/components/search_form.rb`

```ruby
class SearchForm < ApplicationComponent
  def initialize(current_query: "", current_category: "")
    @current_query = current_query
    @current_category = current_category
  end

  def view_template
    form(method: :get, action: blueprints_path, class: "flex gap-2 mb-6") do
      input(type: :text, name: :search, placeholder: "Search blueprints...",
            value: @current_query, class: "flex-1 px-4 py-2 border rounded-lg")

      select(name: :category, class: "px-4 py-2 border rounded-lg") do
        option(value: "") { "All Categories" }
        Category.order(:title).each do |category|
          option(value: category.title, selected: (@current_category == category.title)) do
            category.title.capitalize
          end
        end
      end

      button(type: :submit, class: button_class(:primary)) do
        "Search"
      end

      a(href: blueprints_path, class: button_class(:secondary)) do
        "Clear"
      end
    end
  end
end
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `current_query` | String | "" | Current search query |
| `current_category` | String | "" | Current category filter |

**Usage:**

```ruby
render SearchForm.new(
  current_query: params[:search],
  current_category: params[:category]
)
```

---

### 4. CategoryBadge Component

**Purpose:** Display category tags with consistent styling

**Location:** `/app/views/components/category_badge.rb`

```ruby
class CategoryBadge < ApplicationComponent
  def initialize(category:, removable: false)
    @category = category
    @removable = removable
  end

  def view_template
    span(class: badge_class) do
      text @category.title.capitalize

      if @removable
        button(type: :button, class: "ml-1 hover:font-bold",
               aria_label: "Remove #{@category.title}") do
          "×"
        end
      end
    end
  end

  private

  def badge_class
    "inline-flex items-center gap-1 bg-blue-100 text-blue-800 text-xs px-2.5 py-0.5 rounded-full"
  end
end
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `category` | Category | Required | Category model instance |
| `removable` | Boolean | false | Show remove button |

**Usage:**

```ruby
# Simple display
category = Category.find_by(title: "authentication")
render CategoryBadge.new(category: category)

# With remove button
render CategoryBadge.new(category: category, removable: true)
```

---

### 5. CodeViewer Component

**Purpose:** Display code with syntax highlighting

**Location:** `/app/views/components/code_viewer.rb`

```ruby
class CodeViewer < ApplicationComponent
  def initialize(code:, language: "ruby", show_copy_button: true)
    @code = code
    @language = language
    @show_copy_button = show_copy_button
  end

  def view_template
    div(class: "code-viewer border border-gray-300 rounded-lg overflow-hidden") do
      render_header
      pre(class: "bg-gray-900 text-gray-100 p-4 overflow-x-auto") do
        code(class: "language-#{@language}") { @code }
      end
    end
  end

  private

  def render_header
    div(class: "bg-gray-800 text-gray-300 px-4 py-2 flex justify-between items-center") do
      span(class: "text-sm font-mono") { @language }

      if @show_copy_button
        button(type: :button, class: "text-xs bg-gray-700 hover:bg-gray-600 px-3 py-1 rounded",
               data_clipboard_target: "button") do
          "Copy"
        end
      end
    end
  end
end
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `code` | String | Required | Source code to display |
| `language` | String | "ruby" | Programming language for syntax highlighting |
| `show_copy_button` | Boolean | true | Whether to show copy-to-clipboard button |

**Usage:**

```ruby
blueprint = Blueprint.find(42)
render CodeViewer.new(code: blueprint.code, language: "ruby")
```

---

### 6. EmptyState Component

**Purpose:** Display when no data is available

**Location:** `/app/views/components/empty_state.rb`

```ruby
class EmptyState < ApplicationComponent
  def initialize(title:, description: "", icon: "📦", action_text: "", action_url: "")
    @title = title
    @description = description
    @icon = icon
    @action_text = action_text
    @action_url = action_url
  end

  def view_template
    div(class: "text-center py-12") do
      div(class: "text-6xl mb-4") { @icon }

      h2(class: "text-2xl font-bold text-gray-900 mb-2") { @title }

      p(class: "text-gray-600 mb-6") { @description } if @description.present?

      if @action_text.present? && @action_url.present?
        a(href: @action_url, class: button_class(:primary)) do
          @action_text
        end
      end
    end
  end
end
```

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | String | Required | Main empty state title |
| `description` | String | "" | Descriptive text |
| `icon` | String | "📦" | Emoji or icon |
| `action_text` | String | "" | Call-to-action button text |
| `action_url` | String | "" | CTA button link URL |

**Usage:**

```ruby
render EmptyState.new(
  title: "No blueprints yet",
  description: "Create your first blueprint to get started",
  action_text: "Create Blueprint",
  action_url: new_blueprint_path
)
```

---

## Using Components

### In Controllers

```ruby
class BlueprintsController < ApplicationController
  def index
    @blueprints = Blueprint.order(updated_at: :desc)
    render Blueprints::IndexView.new(blueprints: @blueprints)
  end

  def show
    @blueprint = Blueprint.find(params[:id])
    render BlueprintCard.new(blueprint: @blueprint)
  end
end
```

### In View Templates (if using Phlex view components)

```ruby
# app/views/blueprints/index.html.rb
class Blueprints::IndexView < ApplicationComponent
  def initialize(blueprints:)
    @blueprints = blueprints
  end

  def view_template
    div(class: "container mx-auto p-4") do
      h1(class: "text-3xl font-bold mb-6") { "Blueprints" }

      render SearchForm.new

      if @blueprints.any?
        render BlueprintList.new(blueprints: @blueprints, layout: :grid)
      else
        render EmptyState.new(
          title: "No blueprints found",
          action_text: "Create Blueprint",
          action_url: new_blueprint_path
        )
      end
    end
  end
end
```

### Passing Data

```ruby
# Option 1: Via constructor
component = BlueprintCard.new(blueprint: @blueprint, show_code: true)
render component

# Option 2: Inline rendering
render BlueprintCard.new(blueprint: @blueprint)

# Option 3: With block (if component supports it)
render(MyListComponent.new(items: @items)) do |item|
  div { item.name }
end
```

---

## Styling with Tailwind CSS

### Utility Classes

All components use **Tailwind CSS** utility classes. Key utilities:

```ruby
# Spacing
class: "px-4 py-2"        # Padding
class: "mb-4 mt-2"        # Margin
class: "gap-2"            # Gap between flex items

# Colors
class: "bg-blue-600"      # Background color
class: "text-gray-700"    # Text color
class: "border-red-500"   # Border color

# Layout
class: "flex gap-2"       # Flexbox with spacing
class: "grid grid-cols-3" # CSS Grid
class: "hidden md:block"  # Responsive hide/show

# Typography
class: "text-lg font-bold"
class: "text-xs text-gray-500"
class: "font-mono"

# Borders and Shadows
class: "border rounded-lg"
class: "shadow-md hover:shadow-lg"
```

### Responsive Design

```ruby
class: "w-full md:w-1/2 lg:w-1/3"
# Mobile: full width
# Tablet (md): 50% width
# Desktop (lg): 33% width

class: "grid-cols-1 md:grid-cols-2 lg:grid-cols-3"
# 1 column on mobile, 2 on tablet, 3 on desktop
```

### Building Custom Utility Classes

```ruby
class ApplicationComponent < Phlex::HTML
  def primary_button_class
    "px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition"
  end

  def card_class
    "border rounded-lg shadow-md p-4 hover:shadow-lg transition"
  end
end

# Usage
div(class: card_class) { content }
button(class: primary_button_class) { "Click me" }
```

---

## Accessibility Guidelines

### ARIA Attributes

```ruby
# Labels for buttons and links
button(aria_label: "Close menu") { "×" }

# Description for complex elements
img(src: "logo.png", alt: "Company logo")

# Role for custom components
div(role: "alert", class: "alert-box") { "Alert message" }

# Disabled state
button(disabled: true, aria_disabled: true) { "Disabled" }
```

### Semantic HTML

```ruby
# Use semantic tags instead of divs when appropriate
header { "Page Header" }
nav { "Navigation" }
main { "Main Content" }
footer { "Page Footer" }
article { "Blog post" }
section { "Content section" }

# Form elements
label(for: "search") { "Search" }
input(id: "search", type: :text)

# Lists
ul do
  li { "Item 1" }
  li { "Item 2" }
end
```

### Keyboard Navigation

```ruby
# Ensure all interactive elements are keyboard accessible
button(class: "focus:outline-none focus:ring-2 focus:ring-blue-500") do
  "Clickable"
end

# Skip navigation for keyboard users (advanced)
a(href: "#main-content", class: "sr-only focus:not-sr-only") do
  "Skip to main content"
end
```

---

## Component Patterns

### Conditional Rendering

```ruby
class MyComponent < ApplicationComponent
  def initialize(show_content: false)
    @show_content = show_content
  end

  def view_template
    if @show_content
      div { "Content is shown" }
    else
      div { "Content is hidden" }
    end
  end
end
```

### Iteration

```ruby
class ItemList < ApplicationComponent
  def initialize(items:)
    @items = items
  end

  def view_template
    ul do
      @items.each do |item|
        li { item.name }
      end
    end
  end
end
```

### Nested Components

```ruby
class ParentComponent < ApplicationComponent
  def view_template
    div do
      render HeaderComponent.new
      render ContentComponent.new
      render FooterComponent.new
    end
  end
end
```

### Slots (Advanced)

```ruby
class CardComponent < ApplicationComponent
  def view_template
    div(class: "card") do
      yield  # Allows passing content via block
    end
  end
end

# Usage
render CardComponent.new do
  h2 { "Card Title" }
  p { "Card content" }
end
```

---

## Testing Components

### Unit Tests

**Location:** `/spec/components/blueprint_card_spec.rb`

```ruby
RSpec.describe BlueprintCard, type: :component do
  let(:blueprint) { create(:blueprint, name: "Test Blueprint") }

  it "renders blueprint name" do
    render_inline(BlueprintCard.new(blueprint: blueprint))
    expect(page).to have_text("Test Blueprint")
  end

  it "renders code when show_code is true" do
    render_inline(BlueprintCard.new(blueprint: blueprint, show_code: true))
    expect(page).to have_text(blueprint.code)
  end

  it "does not render code when show_code is false" do
    render_inline(BlueprintCard.new(blueprint: blueprint, show_code: false))
    expect(page).not_to have_text(blueprint.code)
  end

  it "renders categories" do
    category = create(:category, title: "ruby")
    blueprint.categories << category

    render_inline(BlueprintCard.new(blueprint: blueprint))
    expect(page).to have_text("ruby")
  end
end
```

### Integration Tests

```ruby
RSpec.describe "Blueprint listing", type: :feature do
  it "displays blueprints in list view" do
    blueprint1 = create(:blueprint, name: "First")
    blueprint2 = create(:blueprint, name: "Second")

    visit blueprints_path

    expect(page).to have_text("First")
    expect(page).to have_text("Second")
  end

  it "renders empty state when no blueprints" do
    Blueprint.destroy_all

    visit blueprints_path

    expect(page).to have_text("No blueprints found")
    expect(page).to have_link("Create Your First Blueprint")
  end
end
```

---

## Common Issues and Solutions

### Issue: Component not rendering

```ruby
# Problem: Forgot to call render
# Wrong:
def index
  BlueprintCard.new(blueprint: @blueprint)
end

# Right:
def index
  render BlueprintCard.new(blueprint: @blueprint)
end
```

### Issue: Attributes not passed to HTML elements

```ruby
# Problem: Class attribute passed as string
div(class: "my-class") { "Content" }  # Correct

# Not:
div("my-class") { "Content" }  # Wrong
```

### Issue: Dynamic class names

```ruby
# Use string interpolation or conditionals
class_name = @active ? "bg-blue-600" : "bg-gray-600"
div(class: class_name) { "Content" }

# Or use conditionals
div(class: (@active ? "active" : "inactive")) { "Content" }
```

---

## Best Practices

1. **Keep components focused** - One responsibility per component
2. **Use descriptive names** - `BlueprintCard` not `Card`
3. **Provide good defaults** - Sensible default values for props
4. **Document public props** - Comment about required vs optional
5. **Extract common styles** - Use helper methods in ApplicationComponent
6. **Test accessibility** - Use tools like axe-core
7. **Maintain consistency** - Reuse components across the app
8. **Avoid deep nesting** - Keep component hierarchy manageable

---

## Summary

Phlex components provide a clean, maintainable way to build the UI layer of the Blueprints application. By using reusable, well-tested components, we ensure consistency and reduce code duplication across the application.

For more information, visit the [Phlex documentation](https://www.phlex.dev/).

---

**Document Version:** 1.0
**Source:** `/home/b08x/Workspace/RubyAI/blueprints/docs/api/COMPONENTS.md`
