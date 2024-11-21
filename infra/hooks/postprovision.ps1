#!/usr/bin/env pwsh

# Function to display error messages and exit
function Error-Exit {
    param (
        [string]$Message
    )
    Write-Error "❌ | $Message"
    exit 1
}

Write-Output "🔶 | Post-provisioning - starting script"

# Function to check azd authentication status
function Check-AzdAuth {
    $status = azd auth login --check-status 2>&1
    if ($status -match "Not logged in") {
        return $false
    } else {
        return $true
    }
}

# Function to check Azure CLI (az) authentication status
function Check-AzAuth {
    try {
        az account show > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

# Function to check if azd environment is refreshed
function Check-AzdEnv {
    try {
        azd env get-values > $null 2>&1
        return $true
    } catch {
        return $false
    }
}

# Check Python version
Write-Output "🐍 | Checking Python version..."
$pythonVersion = & python -V 2>&1 | Select-String -Pattern "\d+\.\d+"
if ($pythonVersion -notmatch "3.8|3.9|3.10|3.11") {
    Error-Exit "Python 3.8, 3.9, 3.10 or 3.11 is required. Current version: $pythonVersion"
} else {
    Write-Output "✅ | Python version $pythonVersion detected."
}

# Check if logged in to Azure CLI (az)
Write-Output "🔍 | Checking Azure CLI authentication status..."
if (-not (Check-AzAuth)) {
    Write-Output "🔑 | You are not logged in to Azure CLI."
    Write-Output "ℹ️  | Please run 'az login --use-device-code' to authenticate with Azure CLI."
    Error-Exit "Azure CLI authentication required. Exiting script."
} else {
    Write-Output "✅ | Azure CLI is authenticated."
}

# Check if logged in to azd
Write-Output "🔍 | Checking azd authentication status..."
if (-not (Check-AzdAuth)) {
    Write-Output "🔑 | You are not logged in to azd."
    Write-Output "ℹ️  | Please run 'azd auth login --use-device-code' to authenticate with azd."
    Error-Exit "azd authentication required. Exiting script."
} else {
    Write-Output "✅ | azd is authenticated."
}

# Check if azd environment is refreshed
Write-Output "🔄 | Checking if azd environment is refreshed..."
if (-not (Check-AzdEnv)) {
    Write-Output "⚠️  | Environment is not refreshed."
    Write-Output "ℹ️  | Run 'azd env refresh' to get environment variables from your azure deployment."
    Write-Output "ℹ️  | Choose the same environment name, subscription and location used when you deployed the environment."
    Error-Exit "Failed to retrieve environment values using 'azd env get-values'"
} else {
    Write-Output "✅ | azd environment is refreshed."
    azd env get-values > .env
    Write-Output "📄 | Environment values saved to .env."
}

# Install dependencies
# Write-Output '📦 | Installing dependencies from "requirements.txt"...'
# if (-not (& pip install --upgrade pip setuptools)) {
#     Error-Exit "Failed to upgrade pip and setuptools."
# }

# if (-not (& python -m pip install -r requirements.txt -qq)) {
#     Error-Exit "Failed to install dependencies from requirements.txt."
# }
# Write-Output "📦 | Dependencies installed successfully."

# Populate sample data
Write-Output "📊 | Populating sample data..."
$env:PYTHONPATH = "./src;$env:PYTHONPATH"
if (-not (& python data/sample-documents-indexing.py)) {
    Error-Exit "Failed to populate sample data."
}
Write-Output "🔶 | Post-provisioning - populated data successfully."