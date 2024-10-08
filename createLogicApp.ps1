param (
    [string]$environment
)

# Determine the configuration file based on the environment
$configFilePath = "logicapp-config-$environment.json"

if (-Not (Test-Path $configFilePath)) {
    Write-Host "Configuration file not found: $configFilePath"
    exit 1
}

# Read the configuration file
$config = Get-Content -Path $configFilePath | ConvertFrom-Json

# Fetch the authorization token from pipeline variables
$authorizationToken = "$(DevAuthorizationToken)"  # Default for dev

if ($environment -eq "qa") {
    $authorizationToken = "$(QaAuthorizationToken)"
} elseif ($environment -eq "sandbox") {
    $authorizationToken = "$(SandboxAuthorizationToken)"
}

# Generate the Logic App definition
$logicAppDefinition = @{
    "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
    actions = @{
        HTTP = @{
            inputs = @{
                headers = @{
                    Authorization = $authorizationToken
                }
                method = $config.method
                uri = $config.uri
            }
            runAfter = @{}
            type = "Http"
        }
    }
    contentVersion = "1.0.0.0"
    outputs = @{}
    parameters = @{
        "$connections" = @{
            defaultValue = @{}
            type = "Object"
        }
    }
    triggers = @{
        Recurrence = @{
            evaluatedRecurrence = @{
                frequency = $config.frequency
                interval = $config.interval
                schedule = @{
                    hours = $config.hours
                    minutes = $config.minutes
                    weekDays = $config.weekDays
                }
                timeZone = $config.timeZone
            }
            recurrence = @{
                frequency = $config.frequency
                interval = $config.interval
                schedule = @{
                    hours = $config.hours
                    minutes = $config.minutes
                    weekDays = $config.weekDays
                }
                timeZone = $config.timeZone
            }
            type = "Recurrence"
        }
    }
}

# Convert Logic App definition to JSON
$logicAppDefinitionJson = $logicAppDefinition | ConvertTo-Json -Depth 10

# Save to a temporary file for ARM deployment
$logicAppDefinitionJson | Out-File -FilePath "LogicAppDefinition.json"

# Prepare parameters for ARM deployment
$logicAppParams = @{
    logicAppName = $config.logicAppName  # Use the name from the config
    location = "Central India"           
    sku = $config.sku.name
    definition = $logicAppDefinitionJson
}

# Convert to JSON and save ARM parameters
$logicAppParamsJson = $logicAppParams | ConvertTo-Json -Depth 10
$logicAppParamsJson | Out-File -FilePath "LogicAppParameters.json"

Write-Host "Logic App definition and parameters saved."
