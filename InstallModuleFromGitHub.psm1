function Install-ModuleFromGitHub {
    [CmdletBinding()]
    param(
        $GitHubRepo,
        $Branch = "master",
        [Parameter(ValueFromPipelineByPropertyName)]
        $ProjectUri,
        $DestinationPath
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
                Write-Debug "PSModulePath: $PSModulePath"

                $url = "https://github.com/{0}/archive/{1}.zip" -f $GitHubRepo, $Branch
                $targetModuleName=$GitHubRepo.split('/')[-1]

                $OutPath = Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "$targetModuleName"
                Write-Debug "OutPath: $OutPath"
                if(!(Test-Path $OutPath)) {
                    $null = md $OutPath
                }

                $OutFile = Join-Path -Path $OutPath -ChildPath "$($Branch).zip"
                Write-Debug "OutFile: $OutFile"

                Invoke-RestMethod $url -OutFile $OutFile
                if ($IsWindows) {
                  Unblock-File $OutFile
                }
                Expand-Archive -Path $OutFile -DestinationPath $OutPath -Force

                $targetModule = Join-Path -Path $targetModuleName -ChildPath $Branch

                if ($IsWindows) {
                  $dest = "C:\Program Files\WindowsPowerShell\Modules"
                }

                else {
                  $dest = Join-Path -Path $HOME -ChildPath ".local/share/powershell/Modules"
                }

                if($DestinationPath) {
                    $dest = $DestinationPath
                }
                $dest = Join-Path -Path $dest -ChildPath $targetModuleName

                $psd1 = Get-ChildItem $OutPath -Include *.psd1 -Recurse

                if($psd1) {
                    $ModuleVersion=(Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                    $dest = Join-Path -Path $dest -ChildPath $ModuleVersion
                }

                $null = Copy-Item "$(Join-Path -Path $OutPath -ChildPath $targetModule)/*" $dest -Force
        }
    }
}

# Install-PSModuleFromGitHub dfinke/nameit
# Install-PSModuleFromGitHub dfinke/nameit TestBranch
