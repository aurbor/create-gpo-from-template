<#
    .NOTES
      Author: Evan Wilson
      Contact: evan@aurbor.com
      Date: January 2021
    
    .SYNOPSIS

      Downloads required GPO Package from public host, and then unpacks it, and runs the deployment script included (GPO-Creation.ps1)

    .DESCRIPTION

      This script downloads a deployment zip file by the name specified in the 'Configuration Variables' section to the host calling the script.
      It then unpacks the deployment ZIP, and runs the GPO-Creation.ps1 script to deploy the contained GPO. This script is designed to be used
      via an RMM tool to make deployment across multiple hosts easier.

    .PARAMETER packageURL

      This parameter may be unlocked in a future release, but for now the script should be modified if the URL should be changed.

    .EXAMPLE

      .\GPO-Download.ps1

    #>

## Start Transcript/Log File

Start-Transcript -Path "$PSScriptRoot\GPO-Download-$(Get-Date -Format `"MM.dd.yyyy`").log"

## Initialize New-Folder Function
function New-Folder ($name) {
    If (Test-Path "$PSScriptRoot\$name") {
        Write-Output "$name Folder Exists..."
    } Else {
        Write-Output "$name Folder Doesn't Exist..."
        New-Item -ItemType Directory -Path "$PSScriptRoot\$name" | Out-Null
    }
}

## Set Configuration Variables

    Write-Output "Initializing Variables..."

    # Update with the URL where the deployment zip file is held. This must be a publicly available URL.
    $packageURL = "https://icespomig.blob.core.windows.net/public/Scripts/GPO-Deployment.zip"

## Download the Deployment Package

    New-Folder "Working"
    Write-Output "Creating And Cleaning Working Folder..."
    Get-ChildItem "$PSScriptRoot\Working" | Remove-Item -Recurse -Force | Out-Null
    Write-Output "Working Folder Cleaned..."
    Write-Output "Downloading Deployment Package..."
    $packageOutputFile = "$PSScriptRoot\Working\SoftwareRestrictions.zip"
    Invoke-WebRequest -Uri $packageURL -OutFile $packageOutputFile

## Unpack Deployment Package
    
Write-Output "Unpacking GPO Deployment ZIP..."
    Expand-Archive -Path $packageOutputFile -DestinationPath "$PSScriptRoot\Working"
    Remove-Item $packageOutputFile -Force | Out-Null

## Run the Deployment Script

Write-Output "Running Deployment Script..."
    ."$PSScriptRoot\Working\GPO-Creation.ps1"

## End Logging

    Stop-Transcript