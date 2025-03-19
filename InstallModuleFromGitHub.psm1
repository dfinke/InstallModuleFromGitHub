function Install-ModuleFromGitHub
{
    [CmdletBinding()]
    param(
        $GitHubRepo,
        $Branch = "master",
        [Parameter(ValueFromPipelineByPropertyName)]
        $ProjectUri,
        $DestinationPath,
        $SSOToken,
        $moduleName,
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]
        $Scope = "CurrentUser"
    )

    Process
    {
        Write-Verbose ("[$(Get-Date)] Powershell       : {0}.{1}" -f $PSVersionTable.psVersion.Major, $PSVersionTable.psVersion.Minor)

        if ($PSBoundParameters.ContainsKey("ProjectUri"))
        {
            $GitHubRepo = $null
            if ($ProjectUri.OriginalString.StartsWith("https://github.com"))
            {
                $GitHubRepo = $ProjectUri.AbsolutePath
            }
            else
            {
                $name = $ProjectUri.LocalPath.split('/')[-1]
                Write-Host -ForegroundColor Red ("Module [{0}]: not installed, it is not hosted on GitHub " -f $name)
            }
        }

        if ($GitHubRepo)
        {
            $url = "https://api.github.com/repos/{0}/zipball/{1}" -f $GitHubRepo, $Branch
            Write-Verbose ("[$(Get-Date)] Repository       : {0}" -f "https://api.github.com/repos/$GitHubRepo")
            Write-Verbose ("[$(Get-Date)] Branch           : {0}" -f "$Branch")
            Write-Verbose ("[$(Get-Date)] Retrieving       : {0} {1}" -f $GitHubRepo, $Branch)
            Write-Verbose ("[$(Get-Date)] Download from    : {0}" -f $url)

            if ($moduleName)
            {
                $targetModuleName = $moduleName
            }
            else
            {
                $targetModuleName = $GitHubRepo.split('/')[-1]
            }
            Write-Verbose ("[$(Get-Date)] targetModuleName : {0}" -f $targetModuleName)
            Write-Debug "targetModuleName: $targetModuleName"

            $tmpDir = [System.IO.Path]::GetTempPath()

            $OutFile = Join-Path -Path $tmpDir -ChildPath "$($targetModuleName).zip"
            Write-Verbose ("[$(Get-Date)] Output File      : {0}" -f $OutFile)
            Write-Debug "OutFile: $OutFile"

            if ($SSOToken) 
            {
                $headers = @{"Authorization" = "token $SSOToken" } 
                Write-Verbose ("[$(Get-Date)] SSO Token        : {0}" -f $SSOToken)
            }
            else
            {
                Write-Verbose ("[$(Get-Date)] SSO Token        : N/A")
            }

            #enable TLS1.2 encryption
            if (-not ($IsLinux -or $IsMacOS))
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            }
            Invoke-RestMethod $url -OutFile $OutFile -Headers $headers

            if (-not ([System.Environment]::OSVersion.Platform -eq "Unix"))
            {
                Unblock-File $OutFile
            }

            $fileHash = $(Get-FileHash -Path $OutFile).hash
            $tmpDir = "$tmpDir/$fileHash"

            if (Test-Path $tmpDir)
            {
                Write-Warning ("[$(Get-Date)] Checking Folder  : {0} already exists, re-using content" -f $tmpDir) 
            }
            else
            {
                New-Item $tmpDir -ItemType Directory
                Write-Verbose ("[$(Get-Date)] Checking Folder  : {0} created" -f $tmpDir) 
            }
            
            Expand-Archive -Path $OutFile -DestinationPath $tmpDir -Force

            $unzippedArchive = Get-ChildItem "$tmpDir"
            Write-Debug "targetModule: $targetModule"
            Write-Verbose ("[$(Get-Date)] targetModuleName : {0}" -f $targetModuleName)

            if ([System.Environment]::OSVersion.Platform -eq "Unix")
            {
                if ($Scope -eq "CurrentUser")
                {
                    $dest = Join-Path -Path $HOME -ChildPath ".local/share/powershell/Modules"
                }
                else
                {
                    $dest = "/usr/local/share/powershell/Modules"
                }
            }
            else
            {
                Write-Verbose ("[$(Get-Date)] Using Scope      : {0}" -f $Scope)
                if ($Scope -eq "CurrentUser")
                {
                    # Current User
                    if ($psVersionTable.PSVersion.Major -eq "5")
                    {
                        $scopedPath = [Environment]::GetFolderPath('MyDocuments')
                        $scopedChildPath = "\WindowsPowerShell\Modules"
                    }
                    elseif ($psVersionTable.PSVersion.Major -eq "7") 
                    {
                        $scopedPath = [Environment]::GetFolderPath('MyDocuments')
                        $scopedChildPath = "\PowerShell\Modules"
                    }
                }
                else
                {
                    # All Users
                    if ($psVersionTable.PSVersion.Major -eq "5")
                    {
                        $scopedPath = $env:ProgramFiles
                        $scopedChildPath = "\WindowsPowerShell\Modules"
                    }
                    elseif ($psVersionTable.PSVersion.Major -eq "7") 
                    {
                        $scopedPath = $env:ProgramFiles
                        $scopedChildPath = "\PowerShell\Modules"
                    }
                }

                $dest = Join-Path -Path $scopedPath -ChildPath $scopedChildPath
            }

            if ($DestinationPath)
            {
                $dest = $DestinationPath
            }
            $dest = Join-Path -Path $dest -ChildPath $targetModuleName

            if ([System.Environment]::OSVersion.Platform -eq "Unix")
            {
                $psd1 = Get-ChildItem (Join-Path -Path $unzippedArchive -ChildPath *) -Include *.psd1 -Recurse
            }
            else
            {
                $psd1 = Get-ChildItem (Join-Path -Path $tmpDir -ChildPath $unzippedArchive.Name) -Include *.psd1 -Recurse
            } 

            $sourcePath = $unzippedArchive.FullName

            if ($psd1)
            {
                $ModuleVersion = (Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                Write-Verbose ("[$(Get-Date)] Module version   : {0}" -f $ModuleVersion)

                $dest = Join-Path -Path $dest -ChildPath $ModuleVersion
                Write-Verbose ("[$(Get-Date)] Destination      : {0}" -f $dest)

                $null = New-Item -ItemType directory -Path $dest -Force
                $sourcePath = $psd1.DirectoryName
            }

            if ([System.Environment]::OSVersion.Platform -eq "Unix")
            {
                $null = Copy-Item "$(Join-Path -Path $unzippedArchive -ChildPath *)" $dest -Force -Recurse
            }
            else
            {
                $null = Copy-Item "$sourcePath\*" $dest -Force -Recurse
            }
        }
        Write-Verbose "[$(Get-Date)] Status           : Installer finished"
    }
}

# Install-ModuleFromGitHub dfinke/nameit
# Install-ModuleFromGitHub dfinke/nameit TestBranch
