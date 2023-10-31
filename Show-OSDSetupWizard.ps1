[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')| out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null

# Track currentPage
$script:CurrentPage = 0

$script:HasError = $false

# Try loading TSEnv Object
try {
    $TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue
} 
catch {
    Write-Warning "Error while loading Microsoft.SMS.TSEnvironment, maybe running outside a TS. Error message : $($_)"
    [System.Windows.MessageBox]::Show("Error while loading Microsoft.SMS.TSEnvironment, maybe running outside a TS. `t`n`nError message :`n$($_)", 'Error', 'Ok','Error')
}


function LoadXml($filename) {
    $xmlLoader = New-Object System.Xml.XmlDocument
    $xmlLoader.Load($filename)
    return $xmlLoader
}

# Load XAML files
$xmlMainWindow = LoadXml("$PSScriptRoot\Xaml\MainWindow.xaml")
$xmlConfig = LoadXml("$PSScriptRoot\Config.xml")

# Collection storing references to all named WPF controls in the UI
$UIControls=[hashtable]::Synchronized(@{})

# Convert Windows and Pages to a XAML object graph
$UIControls.MainWindow = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xmlMainWindow))


# Load page enabled in the config file
$EnabledPages = @()
foreach ($page in $xmlConfig.wizard.Page) {

    if ($page.Enabled -eq $True) {
        "Loading page $($page.id)"
        if (Test-Path "$PSScriptRoot\Xaml\$($page.filename)") {
            $pageXml = LoadXml("$PSScriptRoot\Xaml\$($page.filename)")
            $UIControls.$($page.id) = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $pageXml))
            $pageXml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object -Process {
                $UIControls.$($_.Name) = $UIControls.$($page.id).FindName($_.Name)
            }
        } else {
            [System.Windows.MessageBox]::Show("An error occured while loading the config file. `t`n`nFile not found : $PSScriptRoot\Xaml\$($page.filename)", 'Error', 'Ok','Error')
        }

        if ($page.script)
        {
            if (Test-Path "$PSScriptRoot\scripts\$($page.script)") {
                . "$PSScriptRoot\scripts\$($page.script)"
            } else {
                [System.Windows.MessageBox]::Show("An error occured while loading the config file. `t`n`nFile not found : $PSScriptRoot\scripts\$($page.script)", 'Error', 'Ok','Error')
            }
        }

        $EnabledPages += [PSCustomObject]@{
            id = $page.id
            name = $page.name
        }
    }
}

# Load the main window
$XmlMainWindow.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object -Process {
    $UIControls.$($_.Name) = $UIControls.MainWindow.FindName($_.Name)
}


$UIControls.btn_Next.Add_Click({
    
    if ($script:HasError -eq $false) {
        $script:CurrentPage++
        $UIControls.frame_Pages.Content = $UIControls.$($EnabledPages[$script:CurrentPage].id)
        $UIControls.Btn_Previous.IsEnabled = $true
    
        if (-Not ($EnabledPages[$script:CurrentPage + 1])) {
            $UIControls.btn_Next.IsEnabled = $false
            $UIControls.Btn_Finish.IsEnabled = $true
        }
    }

    $UIControls.SideMenu.SelectedIndex = $script:CurrentPage
    
    
})

$UIControls.Btn_Previous.Add_Click({
    
    $script:CurrentPage--
    $UIControls.frame_Pages.Content = $UIControls.$($EnabledPages[$script:CurrentPage].id)
    $UIControls.btn_Next.IsEnabled = $true
    $UIControls.Btn_Finish.IsEnabled = $false
    
    if ($script:CurrentPage -eq 0) {
        $UIControls.Btn_Previous.IsEnabled = $false
    }

    $UIControls.SideMenu.SelectedIndex = $script:CurrentPage

})


$UIControls.btn_Cancel.Add_Click({
    
    $Result = [System.Windows.MessageBox]::Show('Are you sure you want to cancel ?', 'Cancel Wizard', 'YesNo','Question')

    If ($Result -eq 'Yes') {
        $UIControls.MainWindow.Close()
    }

})

# Show first enabled page
if ($EnabledPages[0]) {
    $UIControls.frame_Pages.Content = $UIControls.$($EnabledPages[0].id)
    $UIControls.Btn_Previous.IsEnabled = $false
    $UIControls.SideMenu.ItemsSource = $EnabledPages

    $UIControls.SideMenu.SelectedIndex = $script:CurrentPage
}

# If no second page enabled
if (-Not ($EnabledPages[1])) {
    $UIControls.Btn_Previous.IsEnabled = $false
    $UIControls.Btn_Next.IsEnabled = $false
    $UIControls.Btn_Finish.IsEnabled = $true
}

# Show the user interface
$UIControls.MainWindow.ShowDialog() | Out-Null
