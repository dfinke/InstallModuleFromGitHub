function Install-ModuleFromGitHub {
    [CmdletBinding()]
    param(
        $GitHubRepo,
        $Branch = "master",
        [Parameter(ValueFromPipelineByPropertyName)]
        $ProjectUri,
        $DestinationPath,
        [ValidateSet('CurrentUser', 'AllUsers')]
        [string] $Scope = "AllUsers",
        $SSOToken,
        $moduleName
    )

    Process {
        if($PSBoundParameters.ContainsKey("ProjectUri")) {
            $GitHubRepo = $null
            if($ProjectUri.OriginalString.StartsWith("https://github.com")) {
                $GitHubRepo = $ProjectUri.AbsolutePath
            } else {
                $name=$ProjectUri.LocalPath.split('/')[-1]
                Write-Host -ForegroundColor Red ("Module [{0}]: not installed, it is not hosted on GitHub " -f $name)
            }
        }

        if($GitHubRepo) {
                Write-Verbose ("[$(Get-Date)] Retrieving {0} {1}" -f $GitHubRepo, $Branch)

                $url = "https://api.github.com/repos/{0}/zipball/{1}" -f $GitHubRepo, $Branch

                if ($moduleName) {
                    $targetModuleName = $moduleName
                } else {
                    $targetModuleName=$GitHubRepo.split('/')[-1]
                }
                Write-Debug "targetModuleName: $targetModuleName"
                
                $tmpDir = [System.IO.Path]::GetTempPath()

                $OutFile = Join-Path -Path $tmpDir -ChildPath "$($targetModuleName).zip"
                Write-Debug "OutFile: $OutFile"

                if ($SSOToken) {$headers = @{"Authorization" = "token $SSOToken" }}

                #enable TLS1.2 encryption
                if (-not ($IsLinux -or $IsOSX)) {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                }
                Invoke-RestMethod $url -OutFile $OutFile -Headers $headers
                if (-not ($IsLinux -or $IsOSX)) {
                  Unblock-File $OutFile
                }
                
                $fileHash = $(Get-FileHash -Path $OutFile).hash
                $tmpDir = "$tmpDir/$fileHash"

                Expand-Archive -Path $OutFile -DestinationPath $tmpDir -Force

                $unzippedArchive = get-childItem "$tmpDir"
                Write-Debug "targetModule: $targetModule"

                if ($IsLinux -or $IsOSX) {
                  $dest = Join-Path -Path $HOME -ChildPath ".local/share/powershell/Modules"
                } else {
                  switch ($Scope) {
                    'CurrentUser' { 
                      $dest = ($env:PSModulePath -split ';' -match 'Documents')[0]
                    }
                    'AllUsers' {
                      $dest = "C:\Program Files\WindowsPowerShell\Modules"
                    }
                  }
                }

                if($DestinationPath) {
                    $dest = $DestinationPath
                }
                $dest = Join-Path -Path $dest -ChildPath $targetModuleName
                
                $psd1 = Get-ChildItem (Join-Path -Path $tmpDir -ChildPath $unzippedArchive) -Include *.psd1 -Recurse

                if($psd1) {
                    $ModuleVersion=(Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                    $dest = Join-Path -Path $dest -ChildPath $ModuleVersion
                    $null = New-Item -ItemType directory -Path $dest -Force
                }
                $null = Copy-Item "$(Join-Path -Path $tmpDir -ChildPath $unzippedArchive)/*" $dest -Force
        }
    }
}

# Install-ModuleFromGitHub dfinke/nameit
# Install-ModuleFromGitHub dfinke/nameit TestBranch
