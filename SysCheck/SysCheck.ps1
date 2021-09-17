# ---------------------------------
#  SysCheck v1.1
#  by Matteo Stählin & Sandro Lenz
# ---------------------------------

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

Set-ExecutionPolicy Unrestricted

$MainGUI = New-Object System.Windows.Forms.Form

Clear-host

Write-Host "Program Path: C:\SysCheck" -ForegroundColor DarkCyan

#  Main GUI
# ----------

# Cosmetics

$MainGUI.Text = "SysCheck"
$MainGUI.Icon = "C:\SysCheck\SysCheck-Icon.ico"
$MainGUI.Width = 1200
$MainGUI.Height = 600

# ---------------------------------------------------

function CreateReport {
    try {
        $reportHeader = '
<!DOCTYPE html>
<html lang="de">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SysCheck Report</title>
    <link rel="icon" type="image/icon" href="https://icons.iconarchive.com/icons/graphicloads/flat-finance/256/system-settings-icon.png">
    <style>
        * {
            font-family: Arial, Helvetica, sans-serif;
        }
        h1 {
            text-decoration: underline;
        }
    </style>
</head>

<h1>SysCheck Report</h1>
'
    $reportHeader | Out-File -FilePath "$reportPath"
    } catch {
        Write-Host "Log: Error 107 - Fehler beim Erstellen des Reports" -ForegroundColor Red
    }
}

# Checks

function doCheck {
    try {
    if($true -eq $ckbx_AuswahlSysteminfo.CheckState){func_Systeminfo} else{Write-Host "Log: Systeminfo nicht ausgewaehlt."}
    if($true -eq $ckbx_AuswahlIPConf.CheckState){func_IPKonfiguration} else{Write-Host "Log: IP-Konfiguration nicht ausgewaehlt."}
    if($true -eq $ckbx_AuswahlDisk.CheckState){func_Disks} else{Write-Host "Log: Disks nicht ausgewaehlt."}
    if($true -eq $ckbx_AuswahlPartition.CheckState){func_Partitionen} else{Write-Host "Log: Partitionen nicht ausgewaehlt."}
    if($true -eq $ckbx_AuswahlProzesse.CheckState){func_Services} else{Write-Host "Log: Services nicht ausgewaehlt."}
    if($true -eq $ckbx_AuswahlServices.CheckState){func_Prozesse} else{Write-Host "Log: Prozesse nicht ausgewaehlt."}
    
    $MainGUI.Controls.Add($lbl_FinishedReport)
    Write-Host "Log: Info 119 - Report gespeichert" -ForegroundColor Yellow
    Write-Host "Log: Info 120 - Check erfolgreich beendet" -ForegroundColor Green
    } catch {
        Write-Host "Log: Error 120 - Check nicht beendet" -ForegroundColor Red
    }
}

function func_Systeminfo {
    try {
        "<br><br><h3>Systeminformationen:</h3><br>" | Add-Content -Path "$reportPath"
        $conf_Systeminfo = Get-Content -Path "C:\SysCheck\config_Systeminfo.txt"
        Get-ComputerInfo | ConvertTo-Html -property $conf_Systeminfo -as List | Add-Content -Path "$reportPath"
        Write-Host "Log: Info 113 - Systeminformationen erfolgreich ausgelesen" -ForegroundColor Yellow
    } catch { 
        Write-Host "Log: Error 100 - Fehler beim Auslesen der Systeminformationen" -ForegroundColor Red
    }
}
function func_IPKonfiguration {
    try {
        "<br><br><h3>IP-Konfiguration:</h3><br>" | Add-Content -Path "$reportPath"
        Get-NetIPConfiguration | Get-NetIPAddress | Select-Object ifIndex, InterfaceAlias, IPAddress, AddressState | Sort-Object ifIndex | ConvertTo-Html -as Table | Add-Content -Path "$reportPath"
        Write-Host "Log: Info 114 - IP-Konfiguration erfolgreich ausgelesen" -ForegroundColor Yellow
    } catch {
        Write-Host "Log: Error 101 - Fehler beim Auslesen der IP-Konfiguration" -ForegroundColor Red
    }
}
function func_Disks {
    try {
        "<br><br><h3>Disks:</h3><br>" | Add-Content -Path "$reportPath"
        Get-disk | ConvertTo-Html -Property Number, FriendlyName, SerialNumber, HealthStatus, OperationalStatus, Model, BootFromDisk, IsReadOnly -as Table | Add-Content -Path "$reportPath"
        Write-Host "Log: Info 115 - Disks erfolgreich ausgelesen" -ForegroundColor Yellow
    } catch {
        Write-Host "Log: Error 102 - Fehler beim Auslesen der Disks" -ForegroundColor Red
    }
}
function func_Partitionen {
    try {
        "<br><br><h3>Partitionen:</h3><br>" | Add-Content -Path "$reportPath"
        Get-PSDrive | Where {$_.Free} | Select-Object Name, @{Name="Used";Expression={"{0:n}" -f ($_.used/1GB)}}, @{Name="Free";Expression={"{0:n}" -f ($_.free/1GB)}} | Add-Content -Path "$reportPath"
        Write-Host "Log: Info 116 - Partitionen erfolgreich ausgelesen" -ForegroundColor Yellow
    } catch {
        Write-Host "Log: Error 103 - Fehler beim Auslesen der Partitionen" -ForegroundColor Red
    }
}
function func_Services {
    try {
        "<br><br><h3>Services:</h3><br>" | Add-Content -Path "$reportPath"
        Get-Service | Sort-Object -Property Status -Descending | ConvertTo-Html -Property Status, Name, DisplayName | Add-Content -Path "$reportPath"
        Write-Host "Log: Info 117 - Services erfolgreich ausgelesen" -ForegroundColor Yellow
    } catch {
        Write-Host "Log: Error 104 - Fehler beim Auslesen der Services" -ForegroundColor Red
    }
}
function func_Prozesse {
    try {
        "<br><br><h3>Prozesse:</h3><br>" | Add-Content -Path "$reportPath"
        Get-Process | Sort-Object ProcessName -Descending | ConvertTo-Html -Property Name, SI, ID, CPU, WS, PM, NPM, Handles, PriorityClass, Path, Description -As Table | Add-Content -Path "$reportPath"
        Write-Host "Log: Info 118 - Prozesse erfolgreich ausgelesen" -ForegroundColor Yellow
    } catch {
        Write-Host "Log: Error 105 - Fehler beim Auslesen der Prozesse" -ForegroundColor Red
    }
}

# ---------------------------------------------------

# Button Functions

$func_BrowsePath = {
    $BrowsePathGUI = New-Object System.Windows.Forms.FolderBrowserDialog
    $BrowsePathGUI.ShowDialog()

    try {
        Write-Host Report-Path: $BrowsePathGUI.SelectedPath
        $txt_SavePath.text = $BrowsePathGUI.SelectedPath
        $txt_SavePath.Update()
        } catch {
            Write-Host "Log: Error 110 - Fehler beim Setzten des Speicherpfads" -ForegroundColor Red
        }
    }

$func_StartCheck = {
    $MainGUI.Controls.Remove($lbl_FinishedReport)
    $date = Get-Date -Format yyyy-M-d
    $reportPath = $txt_SavePath.text + "\Report_SysCheck_$date.html"
    try {
        if(Test-Path $txt_SavePath.text) {
            CreateReport
            Write-Host "Log: Info 111 - Check wurde gestartet" -ForegroundColor yellow
            doCheck
        } else {
            Write-Host "Log: Error 110 - Fehler beim Setzten des Speicherpfads" -ForegroundColor Red
        }
    } catch {
        Write-Host "Log: Error 109 - Fehler beim Starten des Checks" -ForegroundColor Red
    }
}

# GUI Elements

$lbl_AuswahlTitle = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlTitle)
$lbl_AuswahlTitle.top = 25
$lbl_AuswahlTitle.left = 25
$lbl_AuswahlTitle.Width = 400
$lbl_AuswahlTitle.Height = 50
$lbl_AuswahlTitle.Text = "Auswahl"
$lbl_AuswahlTitle.Font = New-Object System.Drawing.Font("Arial", 18)


$lbl_AuswahlSysteminfo = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlSysteminfo)
$lbl_AuswahlSysteminfo.top = 100
$lbl_AuswahlSysteminfo.left = 100
$lbl_AuswahlSysteminfo.Width = 400
$lbl_AuswahlSysteminfo.Height = 50
$lbl_AuswahlSysteminfo.Text = "Systeminformationen"
$lbl_AuswahlSysteminfo.Font = New-Object System.Drawing.Font("Arial", 11)

$ckbx_AuswahlSysteminfo = New-Object System.Windows.Forms.CheckBox
$MainGUI.Controls.Add($ckbx_AuswahlSysteminfo)
$ckbx_AuswahlSysteminfo.top = 90
$ckbx_AuswahlSysteminfo.left = 500
$ckbx_AuswahlSysteminfo.Width = 30
$ckbx_AuswahlSysteminfo.Height = 50


$lbl_AuswahlIPConf = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlIPConf)
$lbl_AuswahlIPConf.top = 150
$lbl_AuswahlIPConf.left = 100
$lbl_AuswahlIPConf.Width = 400
$lbl_AuswahlIPConf.Height = 50
$lbl_AuswahlIPConf.Text = "IP-Konfiguration"
$lbl_AuswahlIPConf.Font = New-Object System.Drawing.Font("Arial", 11)

$ckbx_AuswahlIPConf = New-Object System.Windows.Forms.CheckBox
$MainGUI.Controls.Add($ckbx_AuswahlIPConf)
$ckbx_AuswahlIPConf.top = 140
$ckbx_AuswahlIPConf.left = 500
$ckbx_AuswahlIPConf.Width = 30
$ckbx_AuswahlIPConf.Height = 50


$lbl_AuswahlDisk = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlDisk)
$lbl_AuswahlDisk.top = 200
$lbl_AuswahlDisk.left = 100
$lbl_AuswahlDisk.Width = 400
$lbl_AuswahlDisk.Height = 50
$lbl_AuswahlDisk.Text = "Disks"
$lbl_AuswahlDisk.Font = New-Object System.Drawing.Font("Arial", 11)

$ckbx_AuswahlDisk = New-Object System.Windows.Forms.CheckBox
$MainGUI.Controls.Add($ckbx_AuswahlDisk)
$ckbx_AuswahlDisk.top = 190
$ckbx_AuswahlDisk.left = 500
$ckbx_AuswahlDisk.Width = 30
$ckbx_AuswahlDisk.Height = 50


$lbl_AuswahlPartition = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlPartition)
$lbl_AuswahlPartition.top = 250
$lbl_AuswahlPartition.left = 100
$lbl_AuswahlPartition.Width = 400
$lbl_AuswahlPartition.Height = 50
$lbl_AuswahlPartition.Text = "Partitionen"
$lbl_AuswahlPartition.Font = New-Object System.Drawing.Font("Arial", 11)

$ckbx_AuswahlPartition = New-Object System.Windows.Forms.CheckBox
$MainGUI.Controls.Add($ckbx_AuswahlPartition)
$ckbx_AuswahlPartition.top = 240
$ckbx_AuswahlPartition.left = 500
$ckbx_AuswahlPartition.Width = 30
$ckbx_AuswahlPartition.Height = 50


$lbl_AuswahlProzesse = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlProzesse)
$lbl_AuswahlProzesse.top = 300
$lbl_AuswahlProzesse.left = 100
$lbl_AuswahlProzesse.Width = 400
$lbl_AuswahlProzesse.Height = 50
$lbl_AuswahlProzesse.Text = "Prozesse"
$lbl_AuswahlProzesse.Font = New-Object System.Drawing.Font("Arial", 11)

$ckbx_AuswahlProzesse = New-Object System.Windows.Forms.CheckBox
$MainGUI.Controls.Add($ckbx_AuswahlProzesse)
$ckbx_AuswahlProzesse.top = 290
$ckbx_AuswahlProzesse.left = 500
$ckbx_AuswahlProzesse.Width = 30
$ckbx_AuswahlProzesse.Height = 50


$lbl_AuswahlServices = New-Object System.Windows.Forms.Label
$MainGUI.Controls.Add($lbl_AuswahlServices)
$lbl_AuswahlServices.top = 350
$lbl_AuswahlServices.left = 100
$lbl_AuswahlServices.Width = 400
$lbl_AuswahlServices.Height = 50
$lbl_AuswahlServices.Text = "Services"
$lbl_AuswahlServices.Font = New-Object System.Drawing.Font("Arial", 11)

$ckbx_AuswahlServices = New-Object System.Windows.Forms.CheckBox
$MainGUI.Controls.Add($ckbx_AuswahlServices)
$ckbx_AuswahlServices.top = 340
$ckbx_AuswahlServices.left = 500
$ckbx_AuswahlServices.Width = 30
$ckbx_AuswahlServices.Height = 50


$txt_SavePath = New-Object System.Windows.Forms.TextBox
$MainGUI.Controls.Add($txt_SavePath)
$txt_SavePath.Left = 600
$txt_SavePath.top = 100
$txt_SavePath.Width = 350
$txt_SavePath.Height = 50
$txt_SavePath.text = "Speicherpfad"
$txt_SavePath.Font = New-Object System.Drawing.Font("Arial", 13)

$btn_BrowsePath = New-Object System.Windows.Forms.Button
$MainGUI.Controls.Add($btn_BrowsePath)
$btn_BrowsePath.Left = 1000
$btn_BrowsePath.top = 100
$btn_BrowsePath.Width = 80
$btn_BrowsePath.Height = 30
$btn_BrowsePath.text = "Browse"
$btn_BrowsePath.Font = New-Object System.Drawing.Font("Arial", 8)
$btn_BrowsePath.Add_Click($func_BrowsePath)


$btn_StartCheck = New-Object System.Windows.Forms.Button
$MainGUI.Controls.Add($btn_StartCheck)
$btn_StartCheck.Left = 640
$btn_StartCheck.top = 160
$btn_StartCheck.Width = 400
$btn_StartCheck.Height = 100
$btn_StartCheck.text = "Check starten"
$btn_StartCheck.Font = New-Object System.Drawing.Font("Arial", 13)
$btn_StartCheck.BackColor = "LightGreen"
$btn_StartCheck.Add_Click($func_StartCheck)


$drpdn_ColorScheme = New-Object System.Windows.Forms.ComboBox
# $MainGUI.Controls.Add($drpdn_ColorScheme)
$drpdn_ColorScheme.Left = 665
$drpdn_ColorScheme.top = 300
$drpdn_ColorScheme.Width = 350
$drpdn_ColorScheme.Height = 60
$drpdn_ColorScheme.Font = New-Object System.Drawing.Font("Arial", 13)
[void] $drpdn_ColorScheme.Items.Add("Default Color")
[void] $drpdn_ColorScheme.Items.Add("Dark")
[void] $drpdn_ColorScheme.Items.Add("High contrast")
$drpdn_ColorScheme.SelectedIndex = 0
$drpdn_ColorScheme.Enabled = 0


$lbl_FinishedReport = New-Object System.Windows.Forms.Label
$lbl_FinishedReport.top = 380
$lbl_FinishedReport.left = 690
$lbl_FinishedReport.Width = 350
$lbl_FinishedReport.Height = 60
$lbl_FinishedReport.Text = "Check abgeschlossen"
$lbl_FinishedReport.Font = New-Object System.Drawing.Font("Arial", 15)
$lbl_FinishedReport.ForeColor = "Blue"

# ---------------------------------------------------

# Show Window

$MainGUI.ShowDialog()
