#!/usr/bin/env python
import sys

if len(sys.argv) != 2:
    raise RuntimeError("Please provide a mdpa name to create vtk visualization.")

mdpa_name = sys.argv[1]
if mdpa_name.endswith(".mdpa"):
    mdpa_name = mdpa_name[:-5]

import KratosMultiphysics as Kratos
import KratosMultiphysics.StructuralMechanicsApplication
import KratosMultiphysics.FluidDynamicsApplication
from KratosMultiphysics.vtk_output_process import VtkOutputProcess

model = Kratos.Model()
model_part = model.CreateModelPart(mdpa_name)

Kratos.ModelPartIO(mdpa_name).ReadModelPart(model_part)

default_settings = Kratos.Parameters("""{"model_part_name":"", "save_output_files_in_folder": false}""")
default_settings["model_part_name"].SetString(mdpa_name)
vtk_output_process = VtkOutputProcess(model, default_settings)
vtk_output_process.PrintOutput()
