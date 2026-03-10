$state = terraform state pull | Out-String

if ($state -eq "") {
    "lol"
}