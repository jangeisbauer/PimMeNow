# *****************************************************************************************************************************************
#     ____  ______  ___   __  _________   _   ______ _       __
#    / __ \/  _/  |/  /  /  |/  / ____/  / | / / __ \ |     / /
#   / /_/ // // /|_/ /  / /|_/ / __/    /  |/ / / / / | /| / / 
#  / ____// // /  / /  / /  / / /___   / /|  / /_/ /| |/ |/ /  
# /_/   /___/_/  /_/  /_/  /_/_____/  /_/ |_/\____/ |__/|__/   April 15, 2020
$version = "0.1.1"
# *****************************************************************************************************************************************
# P i m M e N o w - PS Script to PIM you with comfort ;-)
# 
# Written by: Jan Geisbauer | Twitter: @janvonkirchheim | Blog: https://emptydc.com | Podcast: https://hairlessinthecloud.com 
#
# Blog Post on usage of PimMeNow: https://emptydc.com/2020/03/11/pim-me-now/
# Get latest version on GitHub: https://github.com/jangeisbauer/PimMeNow
#
# Help By:
# Counter comes from: http://blog.dbsnet.fr/countdown-in-a-powershell-gui
# Thanks to Stephen Owen @foxdeploy for this post: https://foxdeploy.com/2014/09/18/adding-autocomplete-to-your-textbox-forms-in-powershell/
#
# *****************************************************************************************************************************************
# Changelog
# ----------------------------------------------------------------------------------------------------------------------------------------
# 15. April 2020: add date & sessiondata to error log
# ----------------------------------------------------------------------------------------------------------------------------------------


# Your PIM Profiles
$accounts = @(
    # add pim account: name of profile, accountname, tenantID, profile-number edge, pim role, duration in hours
    ("Jule Sec admin","jule@100pcloud.com","bf830bb0-fb9g-4081-9a9c-53859bc1dc97","Profile 5","security administrator",2), #default
    ("Jule MSX admin","jule@100pcloud.com","bf8xxxxxxxxxxxxxxxxxxxxxxxxdc97","Profile 5","Exchange administrator",2), 
    ("AdmLab GA","administrator@100pcloud.com","bf8xxxxxxxxxxxxxxxxxxxxxxxxc97","Profile 4","security administrator",2)
)

# Check if justification txt exits
if (!(Test-Path "justificationreasons.txt"))
{
    New-Item -path justificationreasons.txt -type "file" 
}

$justification = Get-content 'justificationreasons.txt'
$systemCheck = 0
$Error.Clear()

# Check if PIM PS Module exists - if not install it
if (Get-Module -ListAvailable -Name AzureADPreview) 
{
    $systemCheck = 1
} 
else 
{
    Write-Host "Module does not exist"
    Start-Process -Verb RunAs -FilePath powershell.exe -ArgumentList "install-module AzureADPreview -force"
    $systemCheck = 1
}

# check if we are ready
if($systemCheck -eq 1)
{
    # build form
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'PimMeNow!'
    $form.Size = New-Object System.Drawing.Size(580,500)
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object System.Drawing.Font("opensans",9,[System.Drawing.FontStyle]::bold)

    # OK Button
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(150,360)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Height = 50
    $OKButton.Width = 120
    $OKButton.Text = 'Cancel'
    $OKButton.Text = 'OK'
    $OKButton.Font = New-Object System.Drawing.Font("opensans",10,[System.Drawing.FontStyle]::bold)
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)

    # Version Label
    $versionLabel = New-Object System.Windows.Forms.LinkLabel 
    $versionLabel.Size = New-Object System.Drawing.Size(280,30)
    $versionLabel.LinkColor = "Black" 
    $versionLabel.ActiveLinkColor = "Black" 
    # check version
    try 
    {
        $checkversion =Invoke-WebRequest "http://100pcloud.com/version.txt"  
    }
    catch 
    {
        $cantReachURL = $true
    } 
    if(!$cantReachURL)
    {
        if($version -eq $checkversion.content)
        {
            $versionLabel.Location = New-Object System.Drawing.Point(470,30)
            $versionLabel.Text = "Version: " + $version
            $LinkLabel.add_Click({[system.Diagnostics.Process]::start("https://github.com/jangeisbauer/PimMeNow")}) 
        }
        else
        {
            $versionLabel.Location = New-Object System.Drawing.Point(380,30)
            $versionLabel.Text = "New Version: Update Now!"
            $LinkLabel.add_Click({[system.Diagnostics.Process]::start("https://github.com/jangeisbauer/PimMeNow")}) 
        }
    }
    else 
    {
        $versionLabel.Location = New-Object System.Drawing.Point(470,30)
        $versionLabel.Text = "Version: " + $version
        $LinkLabel.add_Click({[system.Diagnostics.Process]::start("https://github.com/jangeisbauer/PimMeNow")}) 
    }
    $form.Controls.Add($versionLabel) 

    # Blog link
    $LinkLabel = New-Object System.Windows.Forms.LinkLabel 
    $LinkLabel.Location = New-Object System.Drawing.Size(10,440) 
    $LinkLabel.Size = New-Object System.Drawing.Size(150,20) 
    $LinkLabel.LinkColor = "Black" 
    $LinkLabel.ActiveLinkColor = "Black" 
    $LinkLabel.Text = "EmptyDC.com" 
    $LinkLabel.add_Click({[system.Diagnostics.Process]::start("https://emptydc.com")}) 
    $form.Controls.Add($LinkLabel) 

    #Add Button event 
    $OKButton.Add_Click(
        {    
            # connect to PIM
            $admin =  $accounts[$listBox.SelectedIndex][1].ToString()
            $TenantID =  $accounts[$listBox.SelectedIndex][2].ToString()
            $edgeProfile = $accounts[$listBox.SelectedIndex][3].ToString()
            $role =  $accounts[$listBox.SelectedIndex][4].ToString()
            $duration =  $accounts[$listBox.SelectedIndex][5].ToString()    

            if($admin.Length -ne 0 -and $textBox.Text.Length -ne 0)
            {
                # connect to azuread
                Import-Module azureadpreview

                Connect-AzureAD -AccountId $admin
                $oid=Get-AzureADUser -ObjectId $admin
                
                # find roleassignment
                $roleToAssign=Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $TenantID | ?{$_.displayname -like $role}

                # prepare activation
                $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
                $schedule.Type = "Once"
                $durationString = "PT" + $duration + "H" 
                $schedule.Duration = $durationString
                $schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

                # activate your role
                Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId 'aadRoles' -ResourceId $TenantID -RoleDefinitionId $roleToAssign.id -SubjectId $oid.objectID -Type 'UserAdd' -AssignmentState 'Active' -reason $textBox.Text -Schedule $schedule 

                # open edge with configured profile (no, other browsers are not possible here ;-)
                Start-Process -FilePath "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList "--profile-directory=`"$edgeProfile`""

                # disconnect azuread
                disconnect-azuread
            }
        }
    )

    # Cancel Button
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Point(300,360)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Height = 50
    $CancelButton.Width = 120
    $CancelButton.Text = 'Cancel'
    $CancelButton.Font = New-Object System.Drawing.Font("opensans",10,[System.Drawing.FontStyle]::bold)
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)

    # Select Account Label
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,30)
    $label.Size = New-Object System.Drawing.Size(280,30)
    $label.Text = 'Select an Account:'
    $form.Controls.Add($label)

    # Listbox with account / tenant pairs
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,60)
    $listBox.Size = New-Object System.Drawing.Size(420,10)
    $listBox.Height = 200
    $listBox.Width = 545
    $listBox.Font = New-Object System.Drawing.Font("opensans",10,[System.Drawing.FontStyle]::Regular)
    $form.Controls.Add($listBox)

    # justification text box
    $label2 = New-Object System.Windows.Forms.Label
    $label2.Location = New-Object System.Drawing.Point(10,270)
    $label2.Size = New-Object System.Drawing.Size(280,30)
    $label2.Text = 'Justification:'

    # add items to listbox
    foreach ($key in $accounts) 
    {    
        [void] $listBox.Items.Add($key[0].Tostring())
    }

    # preselect listbox
    $listBox.SetSelected(0,$true)
    $listBox.add_SelectedIndexChanged({$textBox.Focus()})
    $form.Controls.Add($label2)

    # Justification Textbox
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,300)
    $textBox.Size = New-Object System.Drawing.Size(545,50)
    $textBox.Height = 50
    $textBox.Font = New-Object System.Drawing.Font("opensans",10,[System.Drawing.FontStyle]::Regular)
    $textBox.AutoCompleteSource = 'CustomSource'
    $textBox.AutoCompleteMode='SuggestAppend'
    $textBox.AutoCompleteCustomSource=$autocomplete

    # Importing justification keywords from a file for autocompletion
    if($justification.Length -ne 0)
    {
        $justification | % {$textBox.AutoCompleteCustomSource.AddRange($_) }
    }
    # bring up form
    $form.Add_Shown({$form.Activate(); $textBox.focus()})
    $form.Controls.Add($textBox)
    $form.ShowDialog()

    # write to autocomplete file 
    if($textBox.TextLength -ne 0)
    {
        if($justification.Length -ne 0)
        {
            if(!$justification.ToLower().Contains($textBox.Text.ToLower()))
            {
                Add-Content -path justificationreasons.txt -value $textBox.Text
            }
        }
        else 
        {
            Add-Content -path justificationreasons.txt -value $textBox.Text
        }
    }
}

 # listbox items
 $admin =  $accounts[$listBox.SelectedIndex][1].ToString()
 $duration =  $accounts[$listBox.SelectedIndex][5].ToString()   

 # counter label
 $counterlabel = New-Object 'System.Windows.Forms.Label'
 $counterlabel.AutoSize = $True
 $counterlabel.Font = 'Open Sans, 24pt, style=Bold'
 $counterlabel.Location = '5, 55'
 $counterlabel.Name = 'label000000'
 $counterlabel.Size = '208, 46'
 $counterlabel.TabIndex = 0
 $duration = $duration -as [int]
 $counterlabel.Text = $duration * 60
 $form.controls.Add($counterlabel)

 # rebuild form for counter
 $form.controls.Remove($LinkLabel)
 $form.controls.Remove($listBox)
 $form.controls.Remove($OKButton)
 $form.controls.Remove($CancelButton)
 $form.Controls.Remove($label2)
 $form.Controls.Remove($textBox)
 $form.Size = New-Object System.Drawing.Size(235,150)
 $form.Font = New-Object System.Drawing.Font("opensans",9,[System.Drawing.FontStyle]::Regular)


 # reset label for counter
 $label.Size =  New-Object System.Drawing.Size(195,40) 
 $label.Location = New-Object System.Drawing.Point(10,20)
 $label.text = "Minutes until " + $admin + " gets deactivated:"
 $CancelButton.Location = New-Object System.Drawing.Point(0,30)

 # Pim Duration Counter
 function CountDown 
 {
     $isNumeric = $counterlabel.Text -match '^\d+$'
     if($isNumeric -eq $true)
     {
        $counterlabel.Text -= 1
        If ($counterlabel.Text -eq 0) 
        {
            $timer.Stop()
            $counterlabel.Text = "Deactivated!"
        } 
    }
 }

# Countdown is decremented every seconde using a timer
$timer=New-Object System.Windows.Forms.Timer
$timer.Interval=60000
$timer.add_Tick({CountDown})
$timer.Start()    

[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($form)

# error log
if (!(Test-Path "errors.txt"))
{
    New-Item -path errors.txt -type "file" 
}
if($Error.count -ne 0)
{
    $date = get-date
    # add session data
    $sessionData = "Admin: " + $admin + " | TenantID: " + $TenantID + " | Profile: " + $edgeProfile + " | Pim-Role: " + $role + " | Duration: " +$duration 
    Add-Content -path errors.txt -value $date
    Add-Content -path errors.txt -value $sessionData
    Add-Content -path errors.txt -value $Error
}