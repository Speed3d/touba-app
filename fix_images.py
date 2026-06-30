import os
import re

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if 'CachedNetworkImageProvider' in content:
        if "import '../../../core/utils/image_helper.dart';" not in content and "import '../../core/utils/image_helper.dart';" not in content:
            # try to figure out depth
            depth = filepath.count('/') - 1
            prefix = '../' * depth
            content = f"import '{prefix}core/utils/image_helper.dart';\n" + content
            
        content = re.sub(r'CachedNetworkImageProvider\((.*?)\)', r'ImageHelper.getProvider(\1)', content)
        
        with open(filepath, 'w') as f:
            f.write(content)

for root, _, files in os.walk('lib/presentation/screens'):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

