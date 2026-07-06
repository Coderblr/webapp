import subprocess

subprocess.run(
    [
        "mvn",
        "test",
        "-Dtest=TestRunner"
    ],
    cwd=r"C:\Projects\JavaAutomationFramework"
)
