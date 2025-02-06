<#
.SYNOPSIS
    Formats a collection of objects into a neatly rendered table with automatic column wrapping.

.DESCRIPTION
    Format-Table2 takes objects from the pipeline and examines all their properties to determine column widths,
    alignments, and the appropriate table layout. It then constructs and outputs a table with borders. If the table
    is wider than the host buffer, the columns are split into multiple blocks with specified repeat columns appearing
    on each block.

.PARAMETER InputObject
    The objects to be formatted as a table. This parameter accepts pipeline input.

.PARAMETER RepeatColumns
    An array of column names that should be repeated in each wrapped block.
    If not specified, the first discovered column is repeated by default.

.EXAMPLE
    Get-Process | Select-Object -First 3 | Format-Table2

    Retrieves the first 3 processes and displays them in a formatted table. If the total table width exceeds the host's
    buffer width, columns are wrapped and the first discovered column is repeated for each block.

.EXAMPLE
    Get-Process | Select-Object -First 3 | Format-Table2 -RepeatColumns "Name", "Id"

    In this example, both "Name" and "Id" columns are repeated on every wrapped block of the table output.

.NOTES
    The function dynamically calculates optimal column widths based on both header labels and cell content,
    ensuring that numeric values are right-aligned while textual values are left-aligned. It leverages
    efficient collection types and .NET string builders to boost performance. However, despite these
    optimizations, the function may not scale well for very large datasets, so please use it with caution
    in high-volume scenarios.

    AUTHOR: Terry Yang
    https://github.com/0x7FFFFFFFFFFFFFFF/Format-Table2
#>
function Format-Table2 {
    [CmdletBinding()]
    [Alias("ft2")]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][PSObject]$InputObject,
        # Which column(s) should be repeated on every wrapped block.
        # If not provided, by default the first discovered column is used.
        [string[]]$RepeatColumns = @()
    )

    begin {
        # Number of spaces on each side of cell content.
        $Padding = 1

        # Use a generic list for efficient accumulation of input objects.
        $data = [System.Collections.Generic.List[PSObject]]::new()

        # Cache the newline value.
        $nl = [Environment]::NewLine

        # Helper: Returns $true if a string can be parsed as a number.
        function is_numeric {
            param([string]$s)
            $dummy = 0.0
            return [double]::TryParse($s, [System.Globalization.NumberStyles]::Number,
                                      [System.Globalization.CultureInfo]::InvariantCulture, [ref]$dummy)
        }

        # An ordered dictionary mapping column names to column details.
        # Each detail is stored as a hashtable so its values can be updated.
        # Keys include: Header, MaxLen, and AllNumeric.
        $colInfo = [ordered]@{}
    }
    process {
        $data.Add($InputObject)
        foreach ($prop in $InputObject.PSObject.Properties) {
            $name = $prop.Name
            if (-not $colInfo.Contains($name)) {  # Using Contains (not ContainsKey) for an ordered dictionary.
                $colInfo[$name] = @{
                    Header     = $name
                    MaxLen     = $name.Length
                    AllNumeric = $true
                }
            }
            if ($prop.Value -ne $null) {
                $s = $prop.Value.ToString() -replace "\t", "    "
            }
            else {
                $s = ""
            }
            if ($s.Length -gt $colInfo[$name]['MaxLen']) {
                $colInfo[$name]['MaxLen'] = $s.Length
            }
            if ($s -ne "" -and -not (is_numeric $s)) {
                $colInfo[$name]['AllNumeric'] = $false
            }
        }
    }
    end {
        if ($data.Count -eq 0) { return }

        # Finalize each column's width and alignment.
        foreach ($key in $colInfo.Keys) {
            $info = $colInfo[$key]
            $info['Width'] = $info['MaxLen'] + (2 * $Padding)
            $info['Alignment'] = if ($info['AllNumeric']) { "Right" } else { "Left" }
        }

        # Preserve natural (first encountered) order.
        $orderedColumns = @($colInfo.Keys)

        # Process repeat columns: if none specified, default to the first discovered column.
        if ($RepeatColumns.Count -eq 0) {
            $RepeatColumns = @($orderedColumns[0])
        }
        else {
            $RepeatColumns = $RepeatColumns | Where-Object { $orderedColumns -contains $_ }
            if ($RepeatColumns.Count -eq 0) {
                $RepeatColumns = @($orderedColumns[0])
            }
        }

        # Cache available width from the host.
        $bufferWidth = $Host.UI.RawUI.BufferSize.Width

        # Helper: Compute total block width for specified columns.
        function get_block_width {
            param([string[]]$Cols)
            $sum = 0
            foreach ($c in $Cols) {
                $sum += $colInfo[$c]['Width']
            }
            # Each column adds a vertical border; add one more than the number of columns.
            return $sum + ($Cols.Count + 1)
        }

        # Define border characters.
        $bc = @{
            TopLeft     = "+"
            TopMid      = "+"
            TopRight    = "+"
            Fill        = "-"
            MidLeft     = "+"
            MidMid      = "+"
            MidRight    = "+"
            BottomLeft  = "+"
            BottomMid   = "+"
            BottomRight = "+"
            Vertical    = "|"
        }

        # Function: Generate a table block given a list of columns.
        function generate_table_block {
            param([string[]]$Cols)
            $sb = [System.Text.StringBuilder]::new()

            # Top border.
            $lineTopSB = [System.Text.StringBuilder]::new()
            $lineTopSB.Append($bc.TopLeft) | Out-Null
            foreach ($col in $Cols) {
                $width = $colInfo[$col]['Width']
                $lineTopSB.Append([string]::new($bc.Fill, $width)) | Out-Null
                $lineTopSB.Append($bc.TopMid) | Out-Null
            }
            if ($lineTopSB.Length -gt 1) {
                $lineTopStr = $lineTopSB.ToString()
                $lineTop = $lineTopStr.Substring(0, $lineTopStr.Length - 1) + $bc.TopRight
            }
            else {
                $lineTop = $lineTopSB.ToString() + $bc.TopRight
            }
            $sb.AppendLine($lineTop) | Out-Null

            # Header row (center the header).
            $headerSB = [System.Text.StringBuilder]::new()
            $headerSB.Append($bc.Vertical) | Out-Null
            foreach ($col in $Cols) {
                $info = $colInfo[$col]
                $content = $info['Header']
                $totalPad = $info['Width'] - $content.Length
                $leftPad = [int]([math]::Floor($totalPad / 2))
                $rightPad = $totalPad - $leftPad
                $cell = (" " * $leftPad) + $content + (" " * $rightPad)
                $headerSB.Append($cell) | Out-Null
                $headerSB.Append($bc.Vertical) | Out-Null
            }
            $sb.AppendLine($headerSB.ToString()) | Out-Null

            # Middle border.
            $lineMidSB = [System.Text.StringBuilder]::new()
            $lineMidSB.Append($bc.MidLeft) | Out-Null
            foreach ($col in $Cols) {
                $width = $colInfo[$col]['Width']
                $lineMidSB.Append([string]::new($bc.Fill, $width)) | Out-Null
                $lineMidSB.Append($bc.MidMid) | Out-Null
            }
            if ($lineMidSB.Length -gt 1) {
                $lineMidStr = $lineMidSB.ToString()
                $lineMid = $lineMidStr.Substring(0, $lineMidStr.Length - 1) + $bc.MidRight
            }
            else {
                $lineMid = $lineMidSB.ToString() + $bc.MidRight
            }
            $sb.AppendLine($lineMid) | Out-Null

            # Data rows.
            foreach ($obj in $data) {
                $rowSB = [System.Text.StringBuilder]::new()
                $rowSB.Append($bc.Vertical) | Out-Null
                foreach ($col in $Cols) {
                    $info = $colInfo[$col]
                    $val = ""
                    if ($obj.PSObject.Properties[$col]) {
                        $temp = $obj.$col
                        if ($temp -ne $null) {
                            $val = $temp.ToString() -replace "\t", "    "
                        }
                    }
                    $contentWidth = [Math]::Max(0, $info['Width'] - (2 * $Padding))
                    if ($info['Alignment'] -eq "Right") {
                        $cellContent = $val.PadLeft($contentWidth)
                    }
                    else {
                        $cellContent = $val.PadRight($contentWidth)
                    }
                    $cell = (" " * $Padding) + $cellContent + (" " * $Padding)
                    $rowSB.Append($cell) | Out-Null
                    $rowSB.Append($bc.Vertical) | Out-Null
                }
                $sb.AppendLine($rowSB.ToString()) | Out-Null
            }

            # Bottom border.
            $lineBottomSB = [System.Text.StringBuilder]::new()
            $lineBottomSB.Append($bc.BottomLeft) | Out-Null
            foreach ($col in $Cols) {
                $width = $colInfo[$col]['Width']
                $lineBottomSB.Append([string]::new($bc.Fill, $width)) | Out-Null
                $lineBottomSB.Append($bc.BottomMid) | Out-Null
            }
            if ($lineBottomSB.Length -gt 1) {
                $lineBottomStr = $lineBottomSB.ToString()
                $lineBottom = $lineBottomStr.Substring(0, $lineBottomStr.Length - 1) + $bc.BottomRight
            }
            else {
                $lineBottom = $lineBottomSB.ToString() + $bc.BottomRight
            }
            $sb.AppendLine($lineBottom) | Out-Null

            return $sb.ToString().TrimEnd()
        }

        # -------------------------------
        # Determine column blocks that fit within the available width.
        # Block 1 is built from the natural column order.
        # -------------------------------
        $blocks = @()
        $block1 = @()
        $i = 0
        while ($i -lt $orderedColumns.Count) {
            $trial = $block1 + $orderedColumns[$i]
            if ((get_block_width -Cols $trial) -le $bufferWidth) {
                $block1 = $trial
                $i++
            }
            else {
                break
            }
        }
        $blocks += ,$block1

        # Remaining columns (if any) for subsequent blocks.
        if ($i -lt $orderedColumns.Count) {
            $remaining = $orderedColumns[$i..($orderedColumns.Count - 1)]
        }
        else {
            $remaining = @()
        }

        # For subsequent blocks, prepend the repeat columns and add as many remaining columns as fit.
        while ($remaining.Count -gt 0) {
            $block = @()
            foreach ($p in $RepeatColumns) {
                if ($block -notcontains $p) {
                    $block += $p
                }
            }
            $j = 0
            while ($j -lt $remaining.Count) {
                $trial = $block + $remaining[$j]
                if ((get_block_width -Cols $trial) -le $bufferWidth) {
                    $block += $remaining[$j]
                    $j++
                }
                else {
                    break
                }
            }
            $blocks += ,$block
            if ($j -lt $remaining.Count) {
                $remaining = $remaining[$j..($remaining.Count - 1)]
            }
            else {
                $remaining = @()
            }
        }

        # -------------------------------
        # Generate full output (each block as one table).
        # -------------------------------
        $outputSB = [System.Text.StringBuilder]::new()
        foreach ($blk in $blocks) {
            $outputSB.AppendLine((generate_table_block -Cols $blk)) | Out-Null
            $outputSB.AppendLine() | Out-Null
        }
        Write-Output $outputSB.ToString().TrimEnd()
    }
}
