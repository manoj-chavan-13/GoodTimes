import os
import re

directories = [
    r'm:\PROJECT\PlayIt\lib\features\home\screens',
    r'm:\PROJECT\PlayIt\lib\features\folder\screens',
    r'm:\PROJECT\PlayIt\lib\features\settings\screens',
    r'm:\PROJECT\PlayIt\lib\widgets'
]

def remove_const_recursively(content):
    # This is a bit tricky, but usually it's `const Text(` or `const Icon(` or `const CircularProgressIndicator(`
    # or `const SizedBox(` where there is `Theme.of` inside.
    # We can just remove `const ` if the same line has `Theme.of`.
    lines = content.split('\n')
    changed = False
    for i, line in enumerate(lines):
        if 'Theme.of' in line and 'const ' in line:
            # removing 'const ' before widgets
            lines[i] = re.sub(r'\bconst\s+(Text|Icon|CircularProgressIndicator|SizedBox|Row|Column|Container|Center|Padding|BoxDecoration|BorderSide|Divider|ElevatedButton|SnackBar|AlertDialog|ListTile|ExpansionTile|Material|Positioned)\b', r'\1', lines[i])
            if lines[i] != line: changed = True
    return '\n'.join(lines), changed

for d in directories:
    if os.path.exists(d):
        for f in os.listdir(d):
            if f.endswith('.dart'):
                filepath = os.path.join(d, f)
                with open(filepath, 'r', encoding='utf-8') as f_in:
                    content = f_in.read()
                
                new_content, changed = remove_const_recursively(content)
                
                # Further cleanup: "const Color(0xFF..." replacements might have left `const Theme.of`
                new_content2 = new_content.replace('const Theme.of', 'Theme.of')
                
                if changed or new_content2 != content:
                    with open(filepath, 'w', encoding='utf-8') as f_out:
                        f_out.write(new_content2)
                    print(f"Removed const in {filepath}")

print("Done")
