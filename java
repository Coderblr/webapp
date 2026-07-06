feature = "src/features/deposits/MyNewFeature.feature"

with open(r"D:\NBC_Suraj\src\TestRunner.java", "r") as f:
    text = f.read()

import re

text = re.sub(
    r'"src/features/.*?\.feature"',
    f'"{feature}"',
    text
)

with open(r"D:\NBC_Suraj\src\TestRunner.java", "w") as f:
    f.write(text)
