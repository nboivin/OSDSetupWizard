Write-host "Computer Details Script loaded..."

$domainList = $($xmlConfig.wizard.Page | Where-Object {$_.id -eq "ComputerDetails"}).Domain

function Import-DomainList {
    
    foreach($domain in $domainList) {
        $UIControls.domainName.Items.Add("$($domain.Name)") | Out-Null
    }

    $UIControls.domainName.SelectedIndex = 0
}

function Import-DomainOUList($domainName) {

    $UIControls.domainOU.Items.Clear()

    $domainOUList = $($domainList | Where-Object {$_.Name -eq $domainName}).DomainOU

    foreach ($domainOU in $domainOUList) {
        $UIControls.domainOU.Items.Add($($domainOU.Name))
    }

    $UIControls.domainOU.SelectedIndex = 0

}


$UIControls.computerName.Add_Textchanged({ 
    $_sender = $args[0]

    if ($_sender.Text -match "^[-_]|[^a-zA-Z0-9-_]")
    {
        $script:HasError = $true
        $UIControls.lb_ComputerDetailError.Visibility = "Visible"
        $UIControls.lb_ComputerDetailError.Content = "The computer name is not valid."
    }
    elseif ($_sender.Text.Length -gt 15) {
        $script:HasError = $true
        $UIControls.lb_ComputerDetailError.Visibility = "Visible"
        $UIControls.lb_ComputerDetailError.Content = "The computer name is longer than 15 characters."
    }
    elseif ($_sender.Text.Length -eq 0) {
        $script:HasError = $true
        $UIControls.lb_ComputerDetailError.Visibility = "Visible"
        $UIControls.lb_ComputerDetailError.Content = "The computer name is required. Please enter a computer name."
    }
    else {
        $script:HasError = $false
        $UIControls.lb_ComputerDetailError.Visibility = "Collapsed"
    }

})

$UIControls.domainName.Add_SelectionChanged({
    $_sender = $args[0]

    Import-DomainOUList -domainName $($_sender.SelectedItem)

})

$UIControls.domainOU.Add_SelectionChanged({
    $_sender = $args[0]

    $script:OSDDomainOUName = (($domainList | Where-Object {$_.Name -eq $UIControls.domainName.SelectedItem}).DomainOU | Where-Object {$_.Name -eq $_sender.SelectedItem}).Value
})

# Retrieve current computer name value
if ($script:TSEnv) {
    if ($script:TSEnv.Value("OSDComputerName")) {
        $script:OSDComputerName = $script:TSEnv.Value("OSDComputerName")
    } else {
        $script:OSDComputerName = $env:COMPUTERNAME
    }
} else {
    $script:OSDComputerName = $env:COMPUTERNAME
}

$UIControls.computerName.Text = $script:OSDComputerName

Import-DomainList