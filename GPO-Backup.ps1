<#
    .NOTES
      Author: Evan Wilson
      Contact: evan@aurbor.com
      Date: December 2020
    
    .SYNOPSIS

      Creates a backup of a GPO named 'Software Restrictions' on a domain controller for use in GPO deployment via GPO-Create.ps1 script usage.
      This script will also download the latest version of the GPO-Create.ps1 script to be packaged with the GPO for
      distribution.

    .DESCRIPTION

      Used in conjunction with GPO-Creation.ps1 for deploying a baseline GPO that has been created somewhere else. This script relies upon the 7Zip4Powershell Module
      (https://www.powershellgallery.com/packages/7Zip4Powershell/1.9.0) which will be installed automatically if it's not already on the machine.

    .PARAMETER gpoName

      This parameter may be unlocked in a future release, but for now the script should be modified if the GPO Name should be changed from the default 'Software Restrictions'.

    .EXAMPLE

      .\GPO-Backup.ps1

    #>

## Initialize Variables
    # Change if you want to use a different GPO name, but must match the GPO name used in the GPO-Creation.ps1 script when being distributed.
    $gpoName = "Software Restrictions"

## Check for 7Zip4Powershell Module, Install If Not Found

If (Get-Module -ListAvailable -Name 7Zip4Powershell) {
    Write-Output "7Zip4Powershell Module Found. Continuing..."
} 
else {
    Write-Output "7Zip4Powershell Module Not Found. Installing..."
    Install-Module -Name 7Zip4Powershell -RequiredVersion 1.9.0 -Force -AllowClobber
    Write-Output "7Zip4Powershell Module Now Installed. Continuing..."
}



function New-Folder ($name) {
    If (Test-Path "$PSScriptRoot\$name") {
        Write-Output "$name Folder Exists..."
    } Else {
        Write-Output "$name Folder Doesn't Exist..."
        New-Item -ItemType Directory -Path "$PSScriptRoot\$name" | Out-Null
    }
}

## Check/Setup Folder Structure

    # Check and Create Logs folder
    New-Folder "Logs"

    # Check and Create Packages folder
    New-Folder "Packages"
    
    # Check and Create Working folder
    New-Folder "Working"

## Start Transcript/Log File
    
    Start-Transcript -Path "$PSScriptRoot\Logs\GPO-Backup-$(Get-Date -Format `"dd.MM.yyyy.HHmm`").log"

## Import Group Policy Module for GPO cmdlets and AD Module for Domain Query

    Write-Output "Importing Modules..."
    Import-Module GroupPolicy
    Import-Module ActiveDirectory
    Import-Module 7Zip4Powershell

## Clean Up Working Directory
    
    Write-Output "Cleaning Working Folder..."
    Get-ChildItem "$PSScriptRoot\Working" | Remove-Item -Recurse -Force | Out-Null
    Write-Output "Working Folder Cleaned..."

## Get latest GPO Creation Script (GPO-Creation.ps1) from GitHub for Deployment Package
    $scriptUrl = "https://raw.githubusercontent.com/aurbor/create-gpo-from-template/main/GPO-Creation.ps1"
    $scriptOutputFile = "$PSScriptRoot\Working\GPO-Creation.ps1"
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptOutputFile

## Find GPO and back it up in preparation of packaging.

    $gpoExport = Get-GPO -name $gpoName
    Backup-GPO -Guid $gpoExport.Id -Path "$PSScriptRoot\Working" | Out-Null

## Package Exported GPO and Creation script - ready for distribution.

    Write-Output "Creating Deployment Package..."
    Compress-7Zip -ArchiveFileName ".\Packages\GPO-Deployment-$(Get-Date -Format `"dd.MM.yyyy.HHmm`").zip" -Path "$($PSScriptRoot)\Working\." -Format Zip
    Write-Output "Post Deployment Cleanup..."
    Get-ChildItem "$PSScriptRoot\Working" | Remove-Item -Recurse -Force | Out-Null
    Write-Output "Folder Cleaned, Deployment ZIP created in 'Packages' Folder..."

## End Logging

    Stop-Transcript