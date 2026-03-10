$root = (Get-Location).ToString()

# Could (maybe should) move to some kind of project config file
# Locations to <terraform destroy> in
$stadia = "stage", "prod"
$components = @{
    "services" = ,"webserver-cluster";
    "data-stores" = ,"mysql";
}

# Visit each project directory and destroy infrastructure if present
foreach ($stadium in $stadia) {
    foreach ($c_key in $components.Keys) {
        foreach ($component in $components[$c_key]) {
            # Relative path to component for display purposes
            $path = $stadium + "\" + $c_key  + "\" + $component

            # Full path to component on disk
            $fullpath = $root + "\" + $path

            # Check if directory at $fullpath exists
            if (Test-Path($fullpath)) {
                # Move to Terraform module
                Set-Location $fullpath

                # Check if directory has a Terraform state file,
                # i.e. it is a Terraform root module.
                # This check is important because <terraform destroy> is a shorthand 
                # for <terraform apply -destroy>, and <terraform apply> should not be 
                # be called in reusable modules.
                $state = terraform state pull | Out-String
                $has_state = $state -ne ""
                if ($has_state) { 
                    # Report actions
                    Write-Host "Destroying " -ForegroundColor red -NoNewline
                    Write-Host $path -NoNewline
                    Write-Host " ..."

                    # Destroy infrastructure
                    terraform destroy -auto-approve -compact-warnings -input=false 
                }
            }
            else {
                Write-Host "Path not found, continuing.." -ForegroundColor yellow
            }
        }
    }
}

# Set location to starting directory
Set-Location $root