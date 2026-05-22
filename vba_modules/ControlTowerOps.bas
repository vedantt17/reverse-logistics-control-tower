Attribute VB_Name = "ControlTowerOps"
Option Explicit

Private Const EXPORT_FOLDER As String = "outputs\dashboard_exports\"

Private Function EnsureSheet(ByVal sheetName As String) As Worksheet
    On Error Resume Next
    Set EnsureSheet = ThisWorkbook.Worksheets(sheetName)
    On Error GoTo 0

    If EnsureSheet Is Nothing Then
        Set EnsureSheet = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        EnsureSheet.Name = sheetName
    End If
End Function

Private Function CsvPath(ByVal fileName As String) As String
    CsvPath = ThisWorkbook.Path & Application.PathSeparator & EXPORT_FOLDER & fileName
End Function

Private Function LastUsedRow(ByVal ws As Worksheet) As Long
    LastUsedRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
End Function

Private Function LastUsedCol(ByVal ws As Worksheet) As Long
    LastUsedCol = ws.Cells(1, ws.Columns.Count).End(xlToLeft).Column
End Function

Private Function HeaderColumn(ByVal ws As Worksheet, ByVal headerName As String) As Long
    Dim col As Long
    For col = 1 To LastUsedCol(ws)
        If LCase$(Trim$(CStr(ws.Cells(1, col).Value))) = LCase$(headerName) Then
            HeaderColumn = col
            Exit Function
        End If
    Next col
    HeaderColumn = 0
End Function

Private Sub ImportCsvToSheet(ByVal fileName As String, ByVal sheetName As String)
    Dim ws As Worksheet
    Dim sourcePath As String

    Set ws = EnsureSheet(sheetName)
    sourcePath = CsvPath(fileName)

    If Dir(sourcePath) = vbNullString Then
        MsgBox "CSV not found: " & sourcePath, vbExclamation, "Refresh skipped"
        Exit Sub
    End If

    ws.Cells.Clear
    With ws.QueryTables.Add(Connection:="TEXT;" & sourcePath, Destination:=ws.Range("A1"))
        .TextFileParseType = xlDelimited
        .TextFileCommaDelimiter = True
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFilePlatform = 65001
        .Refresh BackgroundQuery:=False
        .Delete
    End With

    With ws.Rows(1)
        .Font.Bold = True
        .Interior.Color = RGB(31, 78, 121)
        .Font.Color = RGB(255, 255, 255)
    End With
    ws.Columns.AutoFit
End Sub

Public Sub RefreshAllData()
    Dim tables As Variant
    Dim i As Long

    Application.ScreenUpdating = False
    Application.DisplayAlerts = False

    tables = Array( _
        Array("kpi_summary.csv", "Dashboard"), _
        Array("backlog_by_region_site.csv", "Backlog"), _
        Array("po_tracker.csv", "PO Tracker"), _
        Array("po_status_by_partner.csv", "PO Status"), _
        Array("truck_delay_trend.csv", "Truck Trend"), _
        Array("removal_aging_distribution.csv", "Removal Aging"), _
        Array("site_exception_table.csv", "Exceptions"), _
        Array("high_priority_material_requests.csv", "Requests"), _
        Array("at_risk_inventory_by_sku.csv", "At Risk SKU"), _
        Array("partner_sla_performance.csv", "Partner SLA"), _
        Array("data_quality_issues.csv", "DQ Issues") _
    )

    For i = LBound(tables) To UBound(tables)
        ImportCsvToSheet CStr(tables(i)(0)), CStr(tables(i)(1))
    Next i

    CreatePOTrackerView
    FlagOverdueRemovals

    Application.DisplayAlerts = True
    Application.ScreenUpdating = True
    MsgBox "Control tower data refreshed from dashboard CSV exports.", vbInformation, "Refresh complete"
End Sub

Public Sub GenerateWeeklyOpsSummary()
    Dim summaryWs As Worksheet
    Dim sourceWs As Worksheet
    Dim nextRow As Long

    Set summaryWs = EnsureSheet("Weekly Summary")
    summaryWs.Cells.Clear

    summaryWs.Range("A1").Value = "Weekly Operations Summary"
    summaryWs.Range("A2").Value = "Generated"
    summaryWs.Range("B2").Value = Now
    summaryWs.Range("A1:B2").Font.Bold = True

    nextRow = 4
    Set sourceWs = EnsureSheet("Dashboard")
    summaryWs.Range("A" & nextRow).Value = "Executive KPIs"
    summaryWs.Range("A" & nextRow).Font.Bold = True
    sourceWs.Range("A1:D12").Copy Destination:=summaryWs.Range("A" & nextRow + 1)

    nextRow = nextRow + 15
    Set sourceWs = EnsureSheet("Backlog")
    summaryWs.Range("A" & nextRow).Value = "Top Backlog Sites"
    summaryWs.Range("A" & nextRow).Font.Bold = True
    sourceWs.Range("A1:I11").Copy Destination:=summaryWs.Range("A" & nextRow + 1)

    nextRow = nextRow + 14
    Set sourceWs = EnsureSheet("DQ Issues")
    summaryWs.Range("A" & nextRow).Value = "Top Data Quality and Escalation Issues"
    summaryWs.Range("A" & nextRow).Font.Bold = True
    sourceWs.Range("A1:E16").Copy Destination:=summaryWs.Range("A" & nextRow + 1)

    summaryWs.Columns.AutoFit
End Sub

Public Sub FlagOverdueRemovals()
    Dim ws As Worksheet
    Dim rowNum As Long
    Dim lastRow As Long
    Dim issueCol As Long
    Dim approvalStatusCol As Long
    Dim accountingStatusCol As Long

    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets("DQ Issues")
    On Error GoTo 0
    If Not ws Is Nothing Then
        issueCol = HeaderColumn(ws, "issue_key")
        If issueCol > 0 Then
            lastRow = LastUsedRow(ws)
            For rowNum = 2 To lastRow
                If CStr(ws.Cells(rowNum, issueCol).Value) = "overdue_removal_older_than_sla" Then
                    ws.Rows(rowNum).Interior.Color = RGB(255, 230, 153)
                End If
            Next rowNum
        End If
    End If

    Set ws = Nothing
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets("PO Tracker")
    On Error GoTo 0
    If Not ws Is Nothing Then
        approvalStatusCol = HeaderColumn(ws, "approval_status")
        accountingStatusCol = HeaderColumn(ws, "accounting_status")
        lastRow = LastUsedRow(ws)
        For rowNum = 2 To lastRow
            If (approvalStatusCol > 0 And (ws.Cells(rowNum, approvalStatusCol).Value = "Pending" Or ws.Cells(rowNum, approvalStatusCol).Value = "Delayed")) _
                Or (accountingStatusCol > 0 And (ws.Cells(rowNum, accountingStatusCol).Value = "Disputed" Or ws.Cells(rowNum, accountingStatusCol).Value = "Accrual Needed")) Then
                ws.Rows(rowNum).Interior.Color = RGB(244, 204, 204)
            End If
        Next rowNum
    End If
End Sub

Public Sub ExportLeadershipReport()
    Dim reportWs As Worksheet
    Dim reportPath As String

    GenerateWeeklyOpsSummary
    Set reportWs = EnsureSheet("Weekly Summary")
    reportPath = ThisWorkbook.Path & Application.PathSeparator & "reports" & Application.PathSeparator & _
        "weekly_leadership_report_" & Format(Date, "yyyymmdd") & ".pdf"

    reportWs.ExportAsFixedFormat Type:=xlTypePDF, Filename:=reportPath, Quality:=xlQualityStandard, _
        IncludeDocProperties:=True, IgnorePrintAreas:=False, OpenAfterPublish:=False

    MsgBox "Leadership report exported: " & reportPath, vbInformation, "Export complete"
End Sub

Public Sub FilterByRegion()
    Dim regionFilter As String
    Dim sheetsToFilter As Variant
    Dim i As Long
    Dim ws As Worksheet
    Dim regionCol As Long
    Dim lastRow As Long
    Dim lastCol As Long

    regionFilter = InputBox("Enter region to filter: North America, Europe, or Asia Pacific", "Filter by region")
    If Len(Trim$(regionFilter)) = 0 Then Exit Sub

    sheetsToFilter = Array("Backlog", "PO Tracker", "PO Status", "Exceptions", "Requests", "Partner SLA")

    For i = LBound(sheetsToFilter) To UBound(sheetsToFilter)
        On Error Resume Next
        Set ws = ThisWorkbook.Worksheets(CStr(sheetsToFilter(i)))
        On Error GoTo 0
        If Not ws Is Nothing Then
            regionCol = HeaderColumn(ws, "region")
            If regionCol > 0 Then
                lastRow = LastUsedRow(ws)
                lastCol = LastUsedCol(ws)
                ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, lastCol)).AutoFilter Field:=regionCol, Criteria1:=regionFilter
            End If
        End If
        Set ws = Nothing
    Next i
End Sub

Public Sub CreatePOTrackerView()
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim lastCol As Long

    Set ws = EnsureSheet("PO Tracker")
    lastRow = LastUsedRow(ws)
    lastCol = LastUsedCol(ws)

    If lastRow < 2 Or lastCol < 2 Then Exit Sub

    If ws.AutoFilterMode Then ws.AutoFilterMode = False
    ws.Range(ws.Cells(1, 1), ws.Cells(lastRow, lastCol)).AutoFilter
    ws.Columns.AutoFit
    ws.Activate
    ActiveWindow.SplitRow = 1
    ActiveWindow.FreezePanes = True
End Sub

