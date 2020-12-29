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

      Used in conjunction with GPO-Creation.ps1 for deploying a baseline GPO that has been created somewhere else.

    .PARAMETER gpoName

      This parameter may be unlocked in a future release, but for now the script should be modified if the GPO Name should be changed from the default 'Software Restrictions'.

    .EXAMPLE

      .\GPO-Backup.ps1

    #>

## Initialize Variables
    # Change if you want to use a different GPO name, but must match the GPO name used in the GPO-Creation.ps1 script when being distributed.
    $gpoName = "Software Restrictions"

## Check/Setup Folder Structure

    # Check and Create Logs folder
    If (Test-Path "$PSScriptRoot\Logs") {
        Write-Output "Logging Folder Exists..."
    } Else {
        Write-Output "Logging Folder Doesn't Exist..."
        New-Item -ItemType Directory -Path "$PSScriptRoot\Logs" | Out-Null
    }

    # Check and Create Packages folder
    If (Test-Path "$PSScriptRoot\Packages") {
        Write-Output "Packages Folder Exists..."
    } Else {
        Write-Output "Packages Folder Doesn't Exist..."
        New-Item -ItemType Directory -Path "$PSScriptRoot\Packages" | Out-Null
    }

## Start Transcript/Log File
    
    Start-Transcript -Path "$PSScriptRoot\Logs\GPO-Backup-$(Get-Date -Format `"dd.MM.yyyy.HHmm`").log"

## Import Group Policy Module for GPO cmdlets and AD Module for Domain Query

    Write-Output "Importing Modules..."
    Import-Module GroupPolicy
    Import-Module ActiveDirectory

## Set Configuration Variables

    Write-Output "Initializing Variables..."

## Clean Up Working Directory
    
    Write-Output "Cleaning Working Folder..."
    Get-ChildItem $PSScriptRoot -Exclude "Packages", "Logs", GPO-Backup.ps1 | Remove-Item -Recurse -Force | Out-Null
    Write-Output "Working Folder Cleaned..."

## Get latest GPO Creation Script (GPO-Creation.ps1) from GitHub for Deployment Package
    $scriptUrl = "https://raw.githubusercontent.com/aurbor/create-gpo-from-template/main/GPO-Creation.ps1"
    $scriptOutputFile = "$PSScriptRoot\GPO-Creation.ps1"
    Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptOutputFile

## Find GPO and Back it up in preparation of packaging.

    $gpoExport = Get-GPO -name $gpoName
    Backup-GPO -Guid $gpoExport.Id -Path $PSScriptRoot | Out-Null

## Package Exported GPO and Creation script - ready for distribution.

    Write-Output "Creating Deployment Package..."
    Get-ChildItem | Where {($_.Name -notlike "Logs") -and ($_.name -notlike "Packages") -and ($_.Name -notlike "GPO-Backup.ps1")} | Compress-Archive -DestinationPath $PSScriptRoot\Packages\GPO-Deployment-$(Get-Date -Format `"dd.MM.yyyy.HHmm`").zip -Force
    Write-Output "Post Deployment Cleanup..."
    Get-ChildItem $PSScriptRoot -Exclude "Packages", "Logs", GPO-Backup.ps1 | Remove-Item -Recurse -Force | Out-Null
    Write-Output "Folder Cleaned, Deployment ZIP created..."

## End Logging

    Stop-Transcript