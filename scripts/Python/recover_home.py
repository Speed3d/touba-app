import json
import re

with open('/Users/sinanayad/.gemini/antigravity/brain/a63c8f3c-0820-4403-a6ba-425c2d30d700/.system_generated/logs/transcript.jsonl', 'r') as f:
    lines = f.readlines()

for line in lines:
    try:
        data = json.loads(line)
        if 'tool_calls' in data:
            continue
        if 'content' in data:
            c = data['content']
            if 'File Path: `file:///Users/sinanayad/Projects/touba-app/lib/presentation/screens/home/home_screen.dart`' in c and 'Total Lines: 666' in c:
                # Found the exact response!
                # We need to strip the line numbers
                file_lines = []
                for cl in c.split('\n'):
                    match = re.match(r'^\d+:\s(.*)$', cl)
                    if match:
                        file_lines.append(match.group(1))
                with open('lib/presentation/screens/home/home_screen.dart', 'w') as out:
                    out.write('\n'.join(file_lines))
                print("Recovered home_screen.dart successfully!")
                break
    except:
        pass
