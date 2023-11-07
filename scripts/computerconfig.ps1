$configTypes = $($xmlConfig.wizard.Page | Where-Object {$_.id -eq "ComputerConfig"}).ConfigType


function Import-ConfigType {

    foreach($configType in $configTypes) {
        $UIControls.configType.Items.Add("$($configType.Name)") | Out-Null
    }

    $UIControls.configType.SelectedIndex = 0
}


$UIControls.configType.Add_SelectionChanged({
    $_sender = $args[0]

    $description = ($configTypes | Where-Object {$_.Name -eq $_sender.SelectedItem}).Description
    if ($description) {
        $UIControls.lb_configTypeDescription.Text = "$description"
    } else {
        $UIControls.lb_configTypeDescription.Text = "No description"
    }
})

Import-ConfigType