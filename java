import jpype
import jpype.imports

jpype.startJVM()

from javax.swing import JFrame

frame = JFrame("Hello from Python")
frame.setSize(400, 300)
frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE)
frame.setVisible(True)

input("Press Enter to quit...")  # keeps Python alive so the window stays open
jpype.shutdownJVM()


import subprocess
subprocess.run(["java", "-jar", "MyApp.jar"])   # or ["java", "MyFrameClass"]



  import subprocess

classpath = r"C:\MyFramework\bin;C:\MyFramework\lib\*"

runner = "com.project.runner.RunnerFile"

subprocess.run(
    ["java", "-cp", classpath, runner],
    check=True
)
