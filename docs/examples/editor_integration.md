# Editor Plugin Integration Guide

Learn how to integrate Blueprints with your favorite code editor for seamless workflow integration.

---

## Table of Contents

1. [Overview](#overview)
2. [VSCode Plugin Guide](#vscode-plugin-guide)
3. [Vim Plugin Guide](#vim-plugin-guide)
4. [IntelliJ/WebStorm Guide](#intellijetlij-guide)
5. [Sublime Text Guide](#sublime-text-guide)
6. [Configuration Guide](#configuration-guide)
7. [Troubleshooting](#troubleshooting)

---

## Overview

Editor plugins allow you to:

- **Save blueprints** without leaving your editor
- **Search blueprints** and insert code directly
- **Generate variants** with a keyboard shortcut
- **Browse** your blueprint library

### Plugin Capabilities

| Feature | VSCode | Vim | IntelliJ | Sublime |
|---------|--------|-----|----------|---------|
| Save selection | ✅ | ✅ | ✅ | ✅ |
| Generate variant | ✅ | ✅ | ✅ | ✅ |
| Search blueprints | ✅ | ✅ | ✅ | ✅ |
| Browse by category | ✅ | ✅ | ✅ | ✅ |
| Inline insertion | ✅ | ✅ | ✅ | ✅ |
| Custom descriptions | ✅ | ✅ | ✅ | ✅ |

### Plugin Architecture

```
Your Code Editor
     ↓
   Plugin
     ↓
Blueprints API (http://localhost:3000/api/v1/)
     ↓
Database + AI Services
```

---

## VSCode Plugin Guide

### Installation

**Option 1: From VS Code Marketplace**

1. Open VS Code
2. Go to Extensions (Cmd+Shift+X / Ctrl+Shift+X)
3. Search "Blueprints by Sublayer"
4. Click Install

**Option 2: From GitHub**

```bash
# Clone the plugin repo
git clone https://github.com/sublayerapp/blueprints-vscode-plugin.git
cd blueprints-vscode-plugin

# Build
npm install
npm run build

# Package
vsce package

# Install from file
code --install-extension blueprints-0.1.0.vsix
```

### Configuration

**Option 1: VS Code Settings UI**

1. Open Settings (Cmd+, / Ctrl+,)
2. Search "blueprints"
3. Configure:
   - `blueprints.apiUrl`: `http://localhost:3000`
   - `blueprints.autoSave`: `false` (recommended)
   - `blueprints.theme`: `auto` (auto, light, dark)

**Option 2: settings.json**

```json
{
  "blueprints.apiUrl": "http://localhost:3000",
  "blueprints.autoSave": false,
  "blueprints.showNotifications": true,
  "blueprints.theme": "auto",
  "blueprints.defaultCategory": "Development"
}
```

**Option 3: Environment File**

Create `.blueprints.env` in your workspace root:

```bash
BLUEPRINTS_API_URL=http://localhost:3000
BLUEPRINTS_AUTO_SAVE=false
BLUEPRINTS_THEME=auto
```

### Usage

#### Keyboard Shortcuts (macOS)

| Action | Shortcut |
|--------|----------|
| Save Blueprint | `Cmd+Shift+B` |
| Generate Variant | `Cmd+Shift+G` |
| Search Blueprints | `Cmd+Shift+F` |
| Browse Blueprints | `Cmd+Shift+L` |
| Insert Blueprint | `Cmd+Shift+I` |

#### Keyboard Shortcuts (Windows/Linux)

| Action | Shortcut |
|--------|----------|
| Save Blueprint | `Ctrl+Shift+B` |
| Generate Variant | `Ctrl+Shift+G` |
| Search Blueprints | `Ctrl+Shift+F` |
| Browse Blueprints | `Ctrl+Shift+L` |
| Insert Blueprint | `Ctrl+Shift+I` |

#### Via Command Palette

1. Open Command Palette (Cmd+Shift+P / Ctrl+Shift+P)
2. Search "Blueprints"
3. Choose action:
   - `Blueprints: Save Selection`
   - `Blueprints: Generate Variant`
   - `Blueprints: Search`
   - `Blueprints: Browse`
   - `Blueprints: Insert Blueprint`

#### Via Context Menu

1. Right-click selected code
2. Choose from Blueprints submenu:
   - "Save as Blueprint"
   - "Generate Variant"
   - "Search Similar"

### Workflow Examples

#### Example 1: Save a Helper Method

```ruby
# Step 1: Highlight code
def validate_email(email)
  email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
end

# Step 2: Press Cmd+Shift+B (or via Command Palette)
# Step 3: Confirm in prompt
# Step 4: See success notification "Blueprint saved!"
```

#### Example 2: Generate Variant with Description

```ruby
# Step 1: Position cursor
# def validate_

# Step 2: Press Cmd+Shift+G
# Step 3: Type in prompt: "Phone number validation for US format"
# Step 4: Generated code appears:
def validate_us_phone(phone)
  phone.match?(/\A\+?1?[-.\s]?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\z/)
end

# Step 5: Review and press Enter to accept, or Escape to reject
```

#### Example 3: Search and Insert

```ruby
# Step 1: Position cursor where you want code
# Step 2: Press Cmd+Shift+F to search
# Step 3: Type search: "user authentication"
# Step 4: Results appear in panel
# Step 5: Click a result to insert it
# Code is inserted at cursor position
```

#### Example 4: Browse All Blueprints

```bash
# Step 1: Press Cmd+Shift+L
# Step 2: Browse sidebar organized by category
# Step 3: Click category to expand
# Step 4: Click blueprint to preview in editor
# Step 5: Press Cmd+Shift+I or click Insert to add to file
```

### Advanced Features

#### Custom Categories for Organization

In `settings.json`:

```json
{
  "blueprints.categories": {
    "Team:Backend": "Backend team patterns",
    "Team:Frontend": "Frontend team patterns",
    "Status:Deprecated": "Old patterns to avoid",
    "Optimization:Performance": "Performance-critical code"
  }
}
```

When saving, you'll see these as suggestions.

#### Auto-Save Configuration

```json
{
  "blueprints.autoSave": false,
  "blueprints.promptBeforeSave": true,
  "blueprints.defaultDescription": "Review and update this description"
}
```

#### Snippet Templates

Create a template file `.blueprints-template.txt`:

```
# Save snippet template (optional, will be merged with generated description)
Use case: {{USER_INPUT}}
Framework: Ruby on Rails
Dependencies: None
```

---

## Vim Plugin Guide

### Installation

**Using vim-plug:**

```vim
" In your .vimrc
Plug 'sublayerapp/blueprints.vim'
```

Then run `:PlugInstall`

**Using Vundle:**

```vim
" In your .vimrc
Plugin 'sublayerapp/blueprints.vim'
```

Then run `:BundleInstall`

**Manual Installation:**

```bash
# Clone into plugins directory
git clone https://github.com/sublayerapp/blueprints.vim ~/.vim/pack/plugins/start/blueprints

# Or copy to ~/.vim/plugin/blueprints.vim
```

### Configuration

Add to your `.vimrc`:

```vim
" Blueprints configuration
let g:blueprints_api_url = 'http://localhost:3000'
let g:blueprints_show_notifications = 1
let g:blueprints_default_prompt = 'Ruby on Rails'

" Custom keymaps
nmap <leader>bs :BlueprintSave<CR>
nmap <leader>bg :BlueprintGenerate<CR>
nmap <leader>bq :BlueprintSearch<CR>
xmap <leader>bs :BlueprintSave<CR>
xmap <leader>bg :BlueprintGenerate<CR>
```

### Usage

#### Commands

```vim
" Save current selection as blueprint
:BlueprintSave

" Generate variant (interactive prompt)
:BlueprintGenerate

" Search blueprints
:BlueprintSearch query

" Browse all blueprints
:BlueprintBrowse

" Insert blueprint by ID
:BlueprintInsert 42

" Show status
:BlueprintStatus
```

#### Keymaps

With default config:

```vim
<leader>bs  " Save selection (normal & visual)
<leader>bg  " Generate variant
<leader>bq  " Search blueprints
```

### Workflow Examples

#### Example 1: Save Selection in Visual Mode

```vim
# Step 1: Visual select code (v, then arrow keys)
def greet(name)
  "Hello, #{name}!"
end

# Step 2: Press <leader>bs (or :BlueprintSave)
# Step 3: Confirmation message
# Blueprint saved!
```

#### Example 2: Generate Variant with Parameters

```vim
# Step 1: Position cursor or select code
# Step 2: Run command with description
:BlueprintGenerate Admin welcome email with verification

# Step 3: Plugin finds similar blueprint
# Step 4: Generates code with your description
# Step 5: Generated code appears above current line
```

#### Example 3: Search and Insert by Pattern

```vim
# Step 1: Position cursor where you want code
# Step 2: Search for pattern
:BlueprintSearch email validation

# Step 3: Results in split window
# Step 4: Select result and press 'i' to insert
# Code inserted at cursor

# Or use ID directly:
:BlueprintInsert 42
```

### Vim Tips

**Create custom command for your workflow:**

```vim
" Save and generate in one command
command! -range BlueprintQuick execute ":'<,'>BlueprintSave" | "BlueprintGenerate"

" Map it
nmap <leader>bx :BlueprintQuick<CR>
```

**Use with auto-commands:**

```vim
" Auto-sync blueprints on save (careful!)
autocmd BufWritePost *.rb :BlueprintSync

" Disable for specific projects
autocmd BufEnter /tmp/* let g:blueprints_auto_sync = 0
```

**Search within file:**

```vim
" After inserting blueprint, search in editor
:BlueprintSearch email
/email " Then use Vim's native search
```

---

## IntelliJ/IDE Guide

### Installation (JetBrains IDEs)

**Compatible with:**
- IntelliJ IDEA (Community & Ultimate)
- WebStorm
- PyCharm
- Rider
- CLion
- All JetBrains IDEs

**Installation Steps:**

1. Open IDE → Preferences/Settings (Cmd+, / Ctrl+,)
2. Go to Plugins
3. Search "Blueprints by Sublayer"
4. Click Install
5. Restart IDE

**Manual Installation:**

1. Download from [GitHub Releases](https://github.com/sublayerapp/blueprints-intellij)
2. Preferences → Plugins → Install from Disk
3. Select downloaded `.jar` file

### Configuration

**Preferences → Tools → Blueprints**

```
API URL: http://localhost:3000
Authentication: None (leave blank for local)
Notifications: Enabled
Theme: Follow IDE theme
Auto-save: Disabled
```

Or edit in `~/[IDE]/config/preferences.xml`:

```xml
<Blueprints>
  <apiUrl>http://localhost:3000</apiUrl>
  <autoSave>false</autoSave>
  <showNotifications>true</showNotifications>
  <followIdeTheme>true</followIdeTheme>
</Blueprints>
```

### Usage

#### Context Menu

1. Right-click code selection
2. **Blueprints** submenu:
   - Save as Blueprint
   - Generate Variant...
   - Search Blueprints...
   - Browse All
   - Insert Blueprint...

#### Keyboard Shortcuts

| Action | Shortcut (Mac) | Shortcut (Win/Linux) |
|--------|---------------|----------------------|
| Save Blueprint | `Cmd+Shift+B` | `Ctrl+Shift+B` |
| Generate Variant | `Cmd+Shift+G` | `Ctrl+Shift+G` |
| Search | `Cmd+Shift+F` | `Ctrl+Shift+F` |
| Browse | `Cmd+Shift+L` | `Ctrl+Shift+L` |
| Insert | `Cmd+Shift+I` | `Ctrl+Shift+I` |

#### Search Panel

```
Tools → Blueprints → Open Search
or Cmd+Shift+F

- Type query
- Results appear in panel
- Click to preview
- Click Insert to add code
```

### Workflow Examples

#### Example 1: Quick Save from Context Menu

```
1. Select code in editor
2. Right-click → Blueprints → Save as Blueprint
3. Confirmation notification
4. Blueprint saved to system
```

#### Example 2: Generate with Dialog

```
1. Position cursor
2. Right-click → Blueprints → Generate Variant...
3. Dialog opens with prompt field
4. Type: "Admin notification email"
5. Click Generate
6. Code appears in editor
7. Accept or edit
```

#### Example 3: Browse Tool Window

```
1. Right-click → Blueprints → Browse All
2. Tool window opens (usually right side)
3. Categories listed
4. Expand category to see blueprints
5. Click blueprint to preview
6. Click Insert button or press Cmd+Enter
```

### IDE-Specific Tips

#### IntelliJ IDEA

```
# Create intention action for quick access
Preferences → Editor → Intentions → Blueprints
Enable "Save code as blueprint" intention
Now Alt+Enter shows blueprint options
```

#### WebStorm (JavaScript/TypeScript)

```
# Works perfectly with JS/TS code
# Saved as .js or .ts snippets
# Variants generate idiomatic JavaScript
```

#### PyCharm (Python)

```
# Blueprints plugin works with Python code
# Save patterns for data science, Django, etc.
# AI generates Pythonic code
```

---

## Sublime Text Guide

### Installation

**Using Package Control (Recommended):**

1. Install Package Control if not already installed
2. Press Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows)
3. Type "Install Package"
4. Search "Blueprints"
5. Select "Blueprints by Sublayer"

**Manual Installation:**

```bash
# Clone into Packages directory
cd ~/Library/Application\ Support/Sublime\ Text\ 3/Packages  # Mac
# or
cd ~/.config/sublime-text-3/Packages/  # Linux
# or
cd %APPDATA%\Sublime\ Text\ 3\Packages\  # Windows

git clone https://github.com/sublayerapp/blueprints-sublime blueprints
```

### Configuration

**Sublime Text → Preferences → Package Settings → Blueprints → Settings**

```json
{
  "blueprints_api_url": "http://localhost:3000",
  "blueprints_show_notifications": true,
  "blueprints_default_description": "",
  "blueprints_auto_save": false,
  "blueprints_confirm_save": true
}
```

### Usage

**Command Palette**

Press Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows):

```
Blueprints: Save Blueprint
Blueprints: Generate Variant
Blueprints: Search
Blueprints: Browse All
Blueprints: Insert Blueprint
```

**Context Menu**

Right-click selection:

```
Blueprints
├─ Save as Blueprint
├─ Generate Variant
├─ Search
└─ Insert Blueprint
```

**Keyboard Shortcuts**

Create custom shortcuts in Sublime Text → Preferences → Key Bindings:

```json
[
  {
    "keys": ["super+shift+b"],
    "command": "blueprints_save",
    "context": [
      { "key": "selection_empty", "operator": "equal", "operand": false }
    ]
  },
  {
    "keys": ["super+shift+g"],
    "command": "blueprints_generate"
  },
  {
    "keys": ["super+shift+f"],
    "command": "blueprints_search"
  }
]
```

---

## Configuration Guide

### Common Configuration Tasks

#### 1. Change API Endpoint

All editors support custom API URLs:

**VSCode:**
```json
"blueprints.apiUrl": "http://your-server.com"
```

**Vim:**
```vim
let g:blueprints_api_url = 'http://your-server.com'
```

**IntelliJ:**
Preferences → Tools → Blueprints → API URL

**Sublime:**
```json
"blueprints_api_url": "http://your-server.com"
```

#### 2. Disable Notifications

**VSCode:**
```json
"blueprints.showNotifications": false
```

**Vim:**
```vim
let g:blueprints_show_notifications = 0
```

#### 3. Enable Auto-Save

**VSCode:**
```json
"blueprints.autoSave": true,
"blueprints.promptBeforeSave": false
```

**Vim:**
```vim
let g:blueprints_auto_save = 1
```

#### 4. Custom Default Description

**VSCode:**
```json
"blueprints.defaultDescription": "Review and update"
```

**Sublime:**
```json
"blueprints_default_description": "Review and update"
```

### Workspace-Specific Configuration

**VSCode** - Create `.vscode/settings.json`:

```json
{
  "blueprints.apiUrl": "http://internal-blueprints.company.com",
  "blueprints.defaultCategory": "Team:Backend"
}
```

**Vim** - Create `.vimrc.local` in project root:

```vim
let g:blueprints_api_url = 'http://internal-server'
let g:blueprints_default_category = 'Team:Backend'
```

**IntelliJ** - Settings stored per project in `.idea/blueprints.xml`

---

## Troubleshooting

### Issue: Plugin Won't Connect to API

**Symptoms:** Connection errors when trying to save

**Solutions:**

1. **Verify API is running:**
   ```bash
   curl http://localhost:3000/api/v1/blueprints
   ```

2. **Check configuration:**
   ```bash
   # VSCode Settings
   # Vim: echo g:blueprints_api_url
   # IntelliJ: Preferences → Tools → Blueprints
   ```

3. **Verify API URL:**
   ```
   http://localhost:3000 ✅ (correct)
   http://127.0.0.1:3000 ⚠️ (try this if above fails)
   http://localhost:3001 ❌ (wrong port)
   ```

4. **Check firewall:**
   ```bash
   # macOS
   sudo lsof -i :3000

   # Linux
   sudo netstat -tlnp | grep 3000
   ```

### Issue: Notification Not Appearing

**Symptoms:** No feedback after saving

**Solutions:**

1. **Enable notifications:**
   - VSCode: `"blueprints.showNotifications": true`
   - Check IDE notification settings

2. **Check Rails logs:**
   ```bash
   tail -f log/development.log | grep blueprint
   ```

3. **Verify save worked:**
   ```bash
   curl http://localhost:3000/api/v1/blueprints | jq '.blueprints[-1]'
   ```

### Issue: Generated Code is Wrong

**Symptoms:** Generated variants don't match expectations

**Solutions:**

1. **Be more specific in prompt:**
   ```
   "email notification" → "User welcome email with verification link"
   ```

2. **Check base blueprint:**
   - Ensure a good blueprint exists to base variant on
   - Try searching first to verify quality

3. **Change LLM provider:**
   - See AI_GENERATORS.md for provider comparison
   - Some providers generate better code

### Issue: Plugin Crashes on Startup

**Symptoms:** Editor won't start with plugin enabled

**Solutions:**

1. **Disable plugin temporarily:**
   - VSCode: Disable in Extensions panel
   - Vim: Comment out plugin line in .vimrc
   - IntelliJ: Settings → Plugins → Disable Blueprints

2. **Check logs:**
   ```bash
   # VSCode: Help → Toggle Developer Tools
   # Others: Check editor logs
   ```

3. **Reinstall plugin:**
   ```bash
   # VSCode
   code --uninstall-extension sublayerapp.blueprints
   code --install-extension sublayerapp.blueprints
   ```

4. **Report issue:**
   - GitHub: [Issues](https://github.com/sublayerapp/blueprints/issues)

### Issue: Slow Plugin Response

**Symptoms:** Plugin takes 5+ seconds to respond

**Causes:**
- Network latency to API
- Slow embedding/LLM generation
- AI API provider is slow

**Solutions:**

1. **Check network:**
   ```bash
   ping localhost
   # Should be <1ms
   ```

2. **Monitor API:**
   ```bash
   tail -f log/development.log
   # Look for slow requests
   ```

3. **Switch LLM provider:**
   - Gemini Flash is fastest
   - See AI_GENERATORS.md

4. **Disable auto-save:**
   ```json
   "blueprints.autoSave": false
   ```

### Issue: Multiple Editors Conflicting

**Symptoms:** Conflicts when using plugin in multiple editors simultaneously

**Solution:**
- Use different API keys if available
- Or coordinate saves
- Blueprints handles duplicates, so duplicates are safe

### Issue: Can't Find Installed Plugin

**Symptoms:** "Blueprints" doesn't appear in extensions/plugins

**Solutions:**

1. **Restart editor** after installation
2. **Check marketplace:** Is it published for your version?
3. **Install manually** from GitHub
4. **Verify editor version:** Plugin may require newer version

---

## Tips & Tricks

### Pro Tip 1: Create Keyboard Shortcuts for Your Workflow

**VSCode:**
```json
{
  "key": "cmd+b",
  "command": "blueprints.save",
  "when": "editorTextFocus && !editorReadonlyMode"
}
```

### Pro Tip 2: Use with Code Snippets

**Workflow:**
1. Generate a blueprint variant
2. Save as editor snippet
3. Now you can generate + convert to snippet automatically

### Pro Tip 3: Team Standardization

1. Create canonical blueprints for your team
2. Share with team
3. Everyone generates variants from same base
4. Ensures consistent patterns

### Pro Tip 4: Batch Operations

**Vim Example:**

```vim
" Apply blueprint generation to multiple selections
:.'<,'>BlueprintGenerate Add error handling

" Applies to all selected lines
```

### Pro Tip 5: Integration with LSP

For editors with language server support, blueprints complements LSP:
- LSP: Syntax checking, completions
- Blueprints: Semantic code generation

---

## Related Guides

- **[Creating Blueprints](creating_blueprints.md)** - Save code patterns
- **[Generating Variants](generating_variants.md)** - Generate new code
- **[REST API Reference](../api/REST_API.md)** - API for custom tools
- **[Quick Start Guide](../api/QUICK_START.md)** - Initial setup

---

**Happy coding! Your blueprint workflow is now integrated into your editor.**
