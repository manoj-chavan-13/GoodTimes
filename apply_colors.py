import os, re

# Files to update with AppColors
files = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens\home_screen.dart',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens\course_screen.dart',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens\settings_screen.dart',
    r'm:\PROJECT\PlayIt\lib\widgets\custom_title_bar.dart',
    r'm:\PROJECT\PlayIt\lib\widgets\hoverable_card.dart',
]

IMPORT = "import 'package:goodtimes/core/themes/app_colors.dart';\n"

# Ordered replacements: most specific first
replacements = [
    # Text colors - ordered from most specific (with opacity) to least
    ("Colors.white.withOpacity(0.08)", "AppColors.border(context)"),
    ("Colors.white.withOpacity(0.05)", "AppColors.border(context).withValues(alpha: 0.05)"),
    ("Colors.white.withOpacity(0.02)", "AppColors.bg(context).withValues(alpha: 0.02)"),
    ("Colors.white.withOpacity(0.2)", "AppColors.text(context).withValues(alpha: 0.2)"),
    ("Colors.white.withOpacity(0.3)", "AppColors.text(context).withValues(alpha: 0.3)"),
    ("Colors.white.withOpacity(0.1)", "AppColors.text(context).withValues(alpha: 0.1)"),
    ("Colors.white.withOpacity(0.15)", "AppColors.textFaint(context)"),
    ("Colors.white.withOpacity(0.05)", "AppColors.border(context).withValues(alpha: 0.6)"),
    # Named opacity variants
    ("Colors.white70", "AppColors.textMuted(context)"),
    ("Colors.white54", "AppColors.textMuted(context)"),
    ("Colors.white38", "AppColors.textFaint(context)"),
    ("Colors.white24", "AppColors.textFaint(context)"),
    ("Colors.white10", "AppColors.scanBtn(context)"),
    # Plain white - ONLY as text/icon colors (background uses scaffoldBackgroundColor or AppColors.bg)
    # Use a context-aware approach: replace Colors.white when used as color: value (text/icon context)
    # Sidebar specific
    ("color: Colors.black,\n      child:", "color: AppColors.sidebar(context),\n      child:"),  # sidebar
    ("color: Colors.black,\n        child:", "color: AppColors.sidebar(context),\n        child:"),  # sidebar indent
    # Main backgrounds
    ("color: const Color(0xFF141414)", "color: AppColors.bg(context)"),
    ("color: Color(0xFF141414)", "color: AppColors.bg(context)"),
    ("backgroundColor: const Color(0xFF141414)", "backgroundColor: AppColors.bg(context)"),
    ("backgroundColor: Color(0xFF141414)", "backgroundColor: AppColors.bg(context)"),
    # Card color
    ("const Color(0xFF141414),\n                        image:", "AppColors.card(context),\n                        image:"),
    ("const Color(0xFF141414),\n              image:", "AppColors.card(context),\n              image:"),
]

# Simple line-by-line color replacements for text/icon colors
LINE_REPLACEMENTS = [
    # icon color white
    (r'\bcolor:\s*Colors\.white\b(?!\.)', 'color: AppColors.text(context)'),
    (r'\bcolor:\s*Colors\.white,', 'color: AppColors.text(context),'),
    # text color white in style
    (r'\bcolor:\s*Colors\.white\)', 'color: AppColors.text(context))'),
    # backgroundColor white (used for 'Play' button - keep as white for contrast on dark video)
    # Don't change button backgrounds - keep them as-is for branding
]

def has_import(content):
    return 'app_colors.dart' in content

def add_import(content):
    # Add after last import line
    lines = content.split('\n')
    last_import = -1
    for i, l in enumerate(lines):
        if l.strip().startswith('import '):
            last_import = i
    if last_import >= 0:
        lines.insert(last_import + 1, IMPORT.strip())
    return '\n'.join(lines)

for filepath in files:
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    original = content

    # Add import if missing
    if not has_import(content):
        content = add_import(content)

    # Apply string replacements
    for old, new in replacements:
        content = content.replace(old, new)

    # Apply line-level regex replacements for remaining Colors.white text/icon usages
    lines = content.split('\n')
    for i, line in enumerate(lines):
        # Skip lines that are about backgroundColor for buttons (ElevatedButton) - keep branding
        if 'ElevatedButton' in line or 'foregroundColor' in line:
            continue
        # Replace icon/text color: Colors.white on its own
        # Only replace when it's a property value (color: Colors.white) not part of withOpacity etc
        if 'Colors.white,' in line and 'color:' in line and 'withOpacity' not in line and 'AppColors' not in line:
            line = re.sub(r'(color:\s*)Colors\.white,', r'\1AppColors.text(context),', line)
        if 'Colors.white)' in line and 'color:' in line and 'withOpacity' not in line and 'AppColors' not in line:
            line = re.sub(r'(color:\s*)Colors\.white\)', r'\1AppColors.text(context))', line)
        lines[i] = line
    content = '\n'.join(lines)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated: {filepath}")

print("Done.")
