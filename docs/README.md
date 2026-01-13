# Blueprints by Sublayer - Documentation

Welcome to the comprehensive documentation for **Blueprints**, an AI-powered Rails application that stores code "blueprints" and uses vector embeddings to generate new code variants.

---

## What is Blueprints?

Blueprints allows you to:

- **Save code patterns** as blueprints with AI-generated descriptions, names, and categories
- **Search semantically** using vector similarity (not keywords) to find relevant code patterns
- **Generate variants** based on existing blueprints using AI to create new code
- **Organize automatically** with AI-suggested categories for easy discovery
- **Integrate seamlessly** with your favorite editor (Vim, VSCode, IntelliJ, Sublime)

### Example Workflow

1. **Save** a Ruby method as a blueprint
2. **Blueprints** automatically generates a description and categories
3. **Search** using natural language ("email sending with attachments")
4. **Generate** new variants that match your description
5. **Copy** generated code directly into your project

---

## Quick Navigation

### Getting Started (15 minutes)

New to Blueprints? Start here:

- **[Quick Start Guide](api/QUICK_START.md)** - Installation, configuration, and first blueprint
- **[Creating Blueprints](examples/creating_blueprints.md)** - Practical patterns for saving code

### API Reference

Integrating Blueprints into your workflow:

- **[REST API Reference](api/REST_API.md)** - Complete endpoint reference with curl examples
- **[Data Models](api/MODELS.md)** - Blueprint and Category data structures
- **[View Components](api/COMPONENTS.md)** - Phlex component catalog for custom UI

### Technical Documentation

Understanding the system architecture and implementation:

- **[System Architecture](technical/ARCHITECTURE.md)** - High-level design, components, and integration points
- **[Vector Embeddings](technical/VECTOR_EMBEDDINGS.md)** - How semantic search works, scaling strategies
- **[AI Generators](technical/AI_GENERATORS.md)** - LLM provider comparison and cost analysis
- **[Performance Analysis](technical/PERFORMANCE_ANALYSIS.md)** - Benchmarks, latency, optimization strategies

### Practical Examples

Real-world usage patterns and code:

- **[Creating Blueprints](examples/creating_blueprints.md)** - Web UI, API, and bulk import examples
- **[Generating Variants](examples/generating_variants.md)** - AI-powered code generation workflows
- **[Editor Integration](examples/editor_integration.md)** - VSCode, Vim, IntelliJ, Sublime plugin guides

---

## Documentation by Role

Choose your path based on your role:

### For API Developers

Building integrations or custom clients:

1. Read **[Quick Start Guide](api/QUICK_START.md)** to understand the system
2. Study **[REST API Reference](api/REST_API.md)** for all available endpoints
3. Review **[Data Models](api/MODELS.md)** to understand response structures
4. See **[Creating Blueprints](examples/creating_blueprints.md)** for integration patterns
5. Check **[Error Handling](api/REST_API.md#error-handling)** for edge cases

### For Rails Developers

Working with the Blueprints codebase:

1. Understand **[System Architecture](technical/ARCHITECTURE.md)** for project structure
2. Study **[Data Models](api/MODELS.md)** for ActiveRecord patterns and relationships
3. Review **[View Components](api/COMPONENTS.md)** for Phlex component patterns
4. Check **[Performance Analysis](technical/PERFORMANCE_ANALYSIS.md)** for optimization tips
5. Reference **[Quick Start Guide](api/QUICK_START.md#debugging)** for development setup

### For AI/ML Engineers

Optimizing AI generation and embeddings:

1. Deep dive into **[AI Generators](technical/AI_GENERATORS.md)** for provider details
2. Study **[Vector Embeddings](technical/VECTOR_EMBEDDINGS.md)** for semantic search mechanics
3. Review provider comparisons: Gemini vs GPT-4 vs Claude
4. Optimize costs using documented strategies in **[AI Generators](technical/AI_GENERATORS.md#cost-comparison)**
5. Check **[Performance Analysis](technical/PERFORMANCE_ANALYSIS.md#ai-latency)** for LLM latency

### For DevOps/SREs

Deploying and maintaining Blueprints at scale:

1. Study **[System Architecture](technical/ARCHITECTURE.md#deployment-architecture)** for deployment patterns
2. Review **[Performance Analysis](technical/PERFORMANCE_ANALYSIS.md)** for scaling strategies
3. Plan database setup using **[Vector Embeddings](technical/VECTOR_EMBEDDINGS.md#database-setup)**
4. Set up monitoring using metrics documented in **[Performance Analysis](technical/PERFORMANCE_ANALYSIS.md#monitoring)**
5. Review **[Security Architecture](technical/ARCHITECTURE.md#security-architecture)** for hardening

---

## Frequently Asked Questions

### Q: How does semantic search work?

**A:** Blueprints converts code descriptions into 1,536-dimensional vectors using OpenAI's `text-embedding-ada-002` model. When you search with natural language, the system:

1. Converts your search query to a vector
2. Calculates cosine distance to existing blueprint vectors
3. Returns the most similar blueprints (not keyword matches)

This means you can search "email with attachments" and find blueprints about "sending files via mail" even though the keywords don't match.

**Learn more:** [Vector Embeddings Deep Dive](technical/VECTOR_EMBEDDINGS.md)

### Q: Which LLM provider should I use?

**A:** Choose based on your priorities:

| Provider | Cost | Speed | Quality | Best For |
|----------|------|-------|---------|----------|
| **Gemini Flash** | $0.27/1K blueprints | Very Fast | Good | Cost-conscious, high volume |
| **GPT-4** | $60.75/1K blueprints | Slower | Excellent | Quality-critical, production |
| **Claude 3.5** | $6.09/1K blueprints | Fast | Excellent | Balanced cost/quality |

**Learn more:** [AI Generators Provider Comparison](technical/AI_GENERATORS.md#provider-comparison)

### Q: What's the typical API response time?

**A:** Response times vary by operation:

| Operation | Time | Notes |
|-----------|------|-------|
| GET blueprints (list) | 15-25ms | Database query only |
| GET blueprint (single) | 10-20ms | Database lookup |
| POST blueprint (create) | 1.2-1.8s | Includes embedding generation |
| POST variant (generate) | 1.5-2.2s | Includes LLM call (slowest) |
| PATCH blueprint (update) | 1.1-1.7s | Includes re-embedding |

**Note:** LLM API calls account for 90-95% of latency in create/variant operations.

**Learn more:** [Performance Analysis](technical/PERFORMANCE_ANALYSIS.md#api-response-times)

### Q: How do I scale to 1 million+ blueprints?

**A:** The system handles scaling through:

1. **HNSW Index on pgvector** - Reduces search time from 18 seconds (brute force) to 60ms
2. **Read Replicas** - Use PostgreSQL read replicas for search-heavy workloads
3. **Dedicated Vector Database** - Consider Pinecone/Weaviate for 10M+ blueprints
4. **Caching** - Implement Redis caching for frequently accessed blueprints

**Learn more:** [Vector Embeddings Scaling Strategy](technical/VECTOR_EMBEDDINGS.md#scaling-strategy)

### Q: Can I use Blueprints offline?

**A:** Partially:
- **Creating blueprints locally:** Yes (no AI generation needed)
- **Semantic search locally:** Yes (vectors are stored in PostgreSQL)
- **Generating variants:** No (requires LLM API calls to OpenAI/Gemini/Claude)
- **Editor sync:** Can work in offline mode, sync when connection restored

**Learn more:** [System Architecture - Integration Points](technical/ARCHITECTURE.md#integration-points)

### Q: How do I backup my blueprints?

**A:** Use standard PostgreSQL backup tools:

```bash
# Full backup
pg_dump blueprints_development > backup.sql

# Restore
psql blueprints_development < backup.sql

# Automated backup
pg_basebackup -D /backup/blueprints -Ft -z
```

**Learn more:** [Quick Start Guide - Backup Section](api/QUICK_START.md#backup-and-restore)

### Q: How accurate is the AI-generated metadata?

**A:** Accuracy varies by LLM provider:

- **Gemini Flash:** 85-90% useful descriptions
- **GPT-4:** 95%+ highly accurate descriptions
- **Claude 3.5:** 93%+ accurate and clear descriptions

You can always edit descriptions manually after creation. Custom descriptions override AI-generated ones.

**Learn more:** [AI Generators - Accuracy Discussion](technical/AI_GENERATORS.md#model-accuracy)

### Q: What happens if my LLM API key expires?

**A:** The system gracefully handles API errors:

1. Blueprint creation will fail with a clear error message
2. Existing blueprints remain accessible (no data loss)
3. Variant generation will not work until API key is renewed
4. You can update the API key and retry the operation

**Learn more:** [Error Handling](api/REST_API.md#error-handling)

### Q: Can I use Blueprints with private/custom LLMs?

**A:** Currently, Blueprints supports:
- Google Gemini (API)
- OpenAI GPT-4 and 3.5 (API)
- Claude (API)

For self-hosted LLMs, you would need to modify the generator classes. This is planned as a future enhancement.

**Learn more:** [AI Generators Architecture](technical/AI_GENERATORS.md#architecture)

### Q: How do I migrate from one AI provider to another?

**A:** The system supports seamless provider switching:

1. Change your API key in `.env`
2. Existing blueprints remain unchanged (vectors are provider-agnostic)
3. New blueprints will use the new provider
4. Run migration task to re-generate descriptions with new provider (optional)

**Learn more:** [AI Generators - Provider Switching](technical/AI_GENERATORS.md#switching-providers)

---

## Getting Help

### Documentation Structure

```
docs/
├── README.md                    (You are here)
├── api/
│   ├── QUICK_START.md          (Get productive in 15 minutes)
│   ├── REST_API.md             (API endpoint reference)
│   ├── MODELS.md               (Data structures)
│   └── COMPONENTS.md           (UI components)
├── technical/
│   ├── ARCHITECTURE.md         (System design)
│   ├── VECTOR_EMBEDDINGS.md    (Semantic search)
│   ├── AI_GENERATORS.md        (LLM integration)
│   └── PERFORMANCE_ANALYSIS.md (Benchmarks & optimization)
└── examples/
    ├── creating_blueprints.md  (Save code patterns)
    ├── generating_variants.md  (Generate new code)
    └── editor_integration.md   (IDE plugins)
```

### Finding Answers

| Question | Start Here |
|----------|-----------|
| "How do I get started?" | [Quick Start Guide](api/QUICK_START.md) |
| "How do I save code?" | [Creating Blueprints](examples/creating_blueprints.md) |
| "How do I generate variants?" | [Generating Variants](examples/generating_variants.md) |
| "What's the API endpoint?" | [REST API Reference](api/REST_API.md) |
| "How does it work?" | [System Architecture](technical/ARCHITECTURE.md) |
| "Why is it slow?" | [Performance Analysis](technical/PERFORMANCE_ANALYSIS.md) |
| "How do I optimize costs?" | [AI Generators](technical/AI_GENERATORS.md) |
| "How do I set up my editor?" | [Editor Integration](examples/editor_integration.md) |

### Search Tips

- **By technology:** Search for "Rails", "PostgreSQL", "pgvector", "API"
- **By concept:** Search for "embedding", "semantic", "vector", "variant"
- **By provider:** Search for "Gemini", "GPT-4", "Claude", "OpenAI"
- **By use case:** Search for "scaling", "backup", "offline", "backup"

---

## Contributing to Documentation

Found an error or have a suggestion? Help improve the documentation:

### Reporting Issues

1. Check if the issue exists in the [Issues](https://github.com/sublayerapp/blueprints/issues)
2. Create a new issue with:
   - Document title and section
   - What's incorrect or missing
   - Suggested improvement
   - Evidence or examples

### Suggesting Improvements

1. Fork the repository
2. Create a branch: `git checkout -b docs/improvement-name`
3. Edit the relevant document
4. Submit a pull request with a clear description

### Adding Examples

1. Ensure the example is practical and tested
2. Include expected input/output
3. Add any prerequisites or setup needed
4. Place in the appropriate `examples/` section

---

## Documentation Standards

### Audience

Each document targets specific audiences:

- **Quick Start:** New developers (5-15 minute time budget)
- **API Reference:** Developers integrating via REST (detailed, comprehensive)
- **Architecture:** System designers and DevOps engineers (strategic decisions)
- **Examples:** All developers (practical, copy-paste ready)

### Format

- **Markdown** for all documentation
- **Code blocks** with language syntax highlighting
- **Tables** for comparisons and reference
- **Mermaid diagrams** for architecture and flows
- **Anchors** for linking between sections

### Maintenance

Documentation is kept current through:
- Automated checks during development
- Manual review during each release
- Version tracking in document headers
- User feedback integration

---

## License & Support

### Community

- **GitHub:** [sublayerapp/blueprints](https://github.com/sublayerapp/blueprints)
- **Issues:** [GitHub Issues](https://github.com/sublayerapp/blueprints/issues)
- **Discussions:** [GitHub Discussions](https://github.com/sublayerapp/blueprints/discussions)

### License

Blueprints is released under the **MIT License**. See the [LICENSE](../LICENSE) file for details.

### Support Resources

| Resource | Use Case |
|----------|----------|
| [Quick Start](api/QUICK_START.md) | Getting started |
| [REST API](api/REST_API.md) | API integration |
| [Examples](examples/) | Practical patterns |
| [Architecture](technical/ARCHITECTURE.md) | Design questions |
| [Issues](https://github.com/sublayerapp/blueprints/issues) | Bug reports |
| [Discussions](https://github.com/sublayerapp/blueprints/discussions) | Feature requests |

---

## Last Updated

**Date:** 2025-10-26
**Version:** 1.0
**Maintained By:** Sublayer Team

---

## Quick Links for Common Tasks

### I want to...

- **Create my first blueprint** → [Quick Start: Create Blueprint](api/QUICK_START.md#step-4-create-your-first-blueprint)
- **Integrate via API** → [REST API Reference](api/REST_API.md)
- **Generate code variants** → [Generating Variants Guide](examples/generating_variants.md)
- **Set up my editor** → [Editor Integration](examples/editor_integration.md)
- **Understand how it works** → [System Architecture](technical/ARCHITECTURE.md)
- **Optimize performance** → [Performance Analysis](technical/PERFORMANCE_ANALYSIS.md)
- **Choose an AI provider** → [AI Generators Comparison](technical/AI_GENERATORS.md#provider-comparison)
- **Scale to millions of blueprints** → [Scaling Strategy](technical/VECTOR_EMBEDDINGS.md#scaling-strategy)
- **Find API examples** → [REST API Integration Examples](api/REST_API.md#integration-examples)
- **Debug an issue** → [Troubleshooting](api/REST_API.md#troubleshooting)

---

**Welcome to Blueprints! Start with the [Quick Start Guide](api/QUICK_START.md) if you're new.**
