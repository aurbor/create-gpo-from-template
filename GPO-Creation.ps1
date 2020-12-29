<#
    .NOTES
      Author: Evan Wilson
      Contact: evan@aurbor.com
      Date: December 2020
    
    .SYNOPSIS

      Finds/Replaces/Creates a new GPO with settings from a backed up and packaged GPO shipped alongside the script.

    .DESCRIPTION

      This script will take an existing group policy object called with the same name as the $gpoName variable
      (eg. 'Software Restrictions') and will import it into Active Directory by creating a new GPO with the same
      name, and then importing the settings from the GPO backup included along-side the script. This script will
      not do anything meaningful without a GPO backup folder alongside it (eg. folder named in GUID format). This
      folder must be created and packaged with another script or manually from an existing domain controller. There
      are no parameters to name.

      The script will log its processes to a logfile in the same folder where the script is located.

    .PARAMETER gpoName

      This parameter may be unlocked in a future release, but for now the script should be modified if the GPO Name should be changed from the default 'Software Restrictions'.

    .EXAMPLE

      .\GPO-Creation.ps1

    #>

## Start Transcript/Log File

    Start-Transcript -Path "$PSScriptRoot\GPO-Creation-$(Get-Date -Format `"MM.dd.yyyy`").log"

## Import Group Policy Module for GPO cmdlets and AD Module for Domain Query

    Write-Output "Importing Modules..."
    Import-Module GroupPolicy
    Import-Module ActiveDirectory

## Set Configuration Variables

    Write-Output "Initializing Variables..."

# Change if you want to use a different GPO name, but must match the exported GPO that is packaged with the script
    $gpoName = "Software Restrictions"

# This will link to the root of the domain by default.
    $linkTarget = $(Get-ADDomain).DistinguishedName

## Check, Clean & Create New GPO

    If (Get-GPO -Name $gpoName -ErrorAction SilentlyContinue) {
        Write-Output "GPO Already exists, removing..."
        Remove-GPO -Name $gpoName
    } Else {
        Write-Output "No existing GPO, continuing..."
    }

    Write-Output "Creating new GPO with new settings..."
    New-GPO -Name $gpoName | New-GPLink -Target $linkTarget -LinkEnabled Yes | Out-Null
    $GPO = Get-GPO -Name $gpoName

## Import Packaged GPO Into New Object Created Above

    Write-Output "Copying Settings from Backup GPO located at $PSScriptRoot..."
    Import-GPO -BackupGpoName $gpoName -Path "$PSScriptRoot" -TargetGuid $GPO.Id | Out-Null

    Write-Output "GPO Configuration complete!"

## End Logging

    Stop-Transcript