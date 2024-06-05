import sys
from importlib import import_module
import KratosMultiphysics as Kratos

if sys.argv[1] != "None":
    import_module(f"KratosMultiphysics.{sys.argv[1]}")
Kratos.Tester.SetVerbosity(Kratos.Tester.Verbosity.TESTS_OUTPUTS)
Kratos.Tester.RunTestCases(f"*{sys.argv[2]}*")