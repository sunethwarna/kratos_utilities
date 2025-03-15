import sys
from importlib import import_module
import KratosMultiphysics as Kratos

if sys.argv[1] != "None":
    import_module(f"KratosMultiphysics.{sys.argv[1]}")
Kratos.Tester.SetVerbosity(Kratos.Tester.Verbosity.TESTS_OUTPUTS)
if len(sys.argv) == 3:
    Kratos.Tester.RunTestCases(f"*{sys.argv[2]}*")
else:
    Kratos.Tester.RunAllTestCases()