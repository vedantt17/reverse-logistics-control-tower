# VBA Import Instructions

1. Open `outputs/excel/Reverse_Logistics_Control_Tower.xlsx`.
2. Save a copy as `Reverse_Logistics_Control_Tower.xlsm`.
3. Press `Alt+F11` to open the VBA editor.
4. Choose `File > Import File`, then import `vba_modules/ControlTowerOps.bas`.
5. Return to Excel and run `RefreshAllData`.

The workbook expects CSV outputs under `outputs/dashboard_exports`. Run `python run_pipeline.py` before refreshing.

