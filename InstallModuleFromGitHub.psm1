function Install-ModuleFromGitHub
{
    [CmdletBinding()]
    param(
        $GitHubRepo,
        $Branch = 'master',
        [Parameter(ValueFromPipelineByPropertyName)]
        $ProjectUri,
        $DestinationPath,
        $SSOToken,
        $ModuleName,
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string] $Scope = 'AllUsers'
    )

    Process
    {
        if($PSBoundParameters.ContainsKey('ProjectUri'))
        {
            $GitHubRepo = $null
            if($ProjectUri.OriginalString.StartsWith('https://github.com'))
            {
                $GitHubRepo = $ProjectUri.AbsolutePath
            }
            else
            {
                $Name = $ProjectUri.LocalPath.split('/')[-1]
                Write-Host -ForegroundColor Red ('Module [{0}]: not installed, it is not hosted on GitHub ' -f $Name)
            }
        }

        if($GitHubRepo)
        {
            Write-Verbose ("[$(Get-Date)] Retrieving {0} {1}" -f $GitHubRepo, $Branch)

            $url = 'https://api.github.com/repos/{0}/zipball/{1}' -f $GitHubRepo, $Branch

            if ($ModuleName)
            {
                $targetModuleName = $ModuleName
            }
            else
            {
                $targetModuleName = $GitHubRepo.split('/')[-1]
            }
            Write-Debug "targetModuleName: $targetModuleName"

            $tmpDir = [System.IO.Path]::GetTempPath()

            $OutFile = Join-Path -Path $tmpDir -ChildPath "$($targetModuleName).zip"
            Write-Debug "OutFile: $OutFile"

            if ($SSOToken)
            {
                $headers = @{'Authorization' = "token $SSOToken" }
            }

            #enable TLS1.2 encryption
            if (-not ($IsLinux -or $IsMacOS))
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            }
            Invoke-RestMethod $url -OutFile $OutFile -Headers $headers
            if (-not ([System.Environment]::OSVersion.Platform -eq 'Unix'))
            {
                Unblock-File $OutFile
            }

            $fileHash = $(Get-FileHash -Path $OutFile).hash
            $tmpDir = "$tmpDir/$fileHash"
            Expand-Archive -Path $OutFile -DestinationPath $tmpDir -Force

            $unzippedArchive = Get-ChildItem "$tmpDir"
            Write-Debug "targetModule: $targetModule"
            if($IsLinux -or $IsMacOS)
            {
                if ($Scope -eq 'CurrentUser')
                {
                    $DestinationPath = Join-Path -Path $HOME -ChildPath '.local/share/powershell/Modules'
                }
                else
                {
                    $DestinationPath = '/usr/local/share/powershell/Modules'
                }
            }
            else
            {
                switch ($Scope)
                {
                    'CurrentUser'
                    {
                        $DestinationPath = "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowerShell\Modules"
                    }
                    'AllUsers'
                    {
                        $DestinationPath = "$($env:ProgramFiles)\WindowsPowerShell\Modules"
                    }
                }
            }
            $DestinationPath = Join-Path -Path $DestinationPath -ChildPath $targetModuleName
            Write-Verbose "The module will be saved to '$DestinationPath'."
            if($IsLinux -or $IsMacOS)
            {
                $psd1 = Get-ChildItem (Join-Path -Path $unzippedArchive -ChildPath *) -Include *.psd1 -Recurse
            }
            else
            {
                $psd1 = Get-ChildItem (Join-Path -Path $tmpDir -ChildPath $unzippedArchive) -Include *.psd1 -Recurse
            }

            if($psd1)
            {
                $ModuleVersion = (Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                $DestinationPath = Join-Path -Path $DestinationPath -ChildPath $ModuleVersion
                try
                {
                    $null = New-Item -ItemType directory -Path $DestinationPath -Force -ErrorAction Stop
                }
                catch
                {
                    Write-Error "Unable to create the folder '$DestinationPath'. Try again running as Administrator."
                    break
                }
            }

            if($IsLinux -or $IsMacOS)
            {
                $null = Copy-Item "$(Join-Path -Path $unzippedArchive -ChildPath *)" $DestinationPath -Force -Recurse
            }
            else
            {
                try
                {
                    $null = Copy-Item "$(Join-Path -Path $tmpDir -ChildPath $unzippedArchive\*)" $DestinationPath -Force -Recurse -ErrorAction Stop
                }
                catch
                {
                    Write-Output 'Unable to copy files.'
                    break
                }
            }
        }
    }
}