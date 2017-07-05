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
            if($ProjectUri.OriginalString.StartsWith("https://github.com") -or $ProjectUri.OriginalString.StartsWith("https://bitbucket.org")) {
                $GitHubRepo = $ProjectUri.AbsolutePath
            } else {
                $name=$ProjectUri.LocalPath.split('/')[-1]
                Write-Host -ForegroundColor Red ("Module [{0}]: not installed, it is not hosted on GitHub or BitBucket " -f $name)
            }
        }

        if($GitHubRepo) {
                Write-Verbose ("[$(Get-Date)] Retrieving {0} {1}" -f $GitHubRepo, $Branch)

                if ($ProjectUri.OriginalString.StartsWith("https://github.com")){
                  $url = "https://github.com/{0}/archive/{1}.zip" -f $GitHubRepo, $Branch
                }
                elseif($ProjectUri.OriginalString.StartsWith("https://bitbucket.org")){
                  $url = "https://bitbucket.org/{0}/get/{1}.zip" -f $GitHubRepo, $Branch
                }

                $targetModuleName=$GitHubRepo.split('/')[-1]
                Write-Debug "targetModuleName: $targetModuleName"

                $tmpDir = [System.IO.Path]::GetTempPath()

                $OutFile = Join-Path -Path $tmpDir -ChildPath "$($targetModuleName).zip"
                Write-Debug "OutFile: $OutFile"


                if ($IsLinux -or $IsOSX) {
                  Invoke-RestMethod $url -OutFile $OutFile
                }

                else {
                  Invoke-RestMethod $url -OutFile $OutFile
                  Unblock-File $OutFile
                }

                Expand-Archive -Path $OutFile -DestinationPath $tmpDir -Force
                $unzippedArchive = (Get-ChildItem $tmpDir| Where-Object {$_.LastWriteTime -gt $(get-date).AddMinutes(-2) -and  $_.Name -like "*$targetModuleName*"}).Name
                Write-Debug "targetModule: $targetModule"

                if ($IsLinux -or $IsOSX) {
                  $dest = Join-Path -Path $HOME -ChildPath ".local/share/powershell/Modules"
                }

                else {
                  $dest = [Environment]::GetFolderPath("MyDocuments")+"\WindowsPowerShell\"
                }

                if($DestinationPath) {
                    $dest = $DestinationPath
                }
                $dest = Join-Path -Path $dest -ChildPath $targetModuleName
                Write-Debug "dest: $dest"

                $psd1 = Get-ChildItem (Join-Path -Path $tmpDir -ChildPath $unzippedArchive) -Include *.psd1 -Recurse

                if($psd1) {
                    $ModuleVersion=(Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                    $dest = Join-Path -Path $dest -ChildPath $ModuleVersion
                }

                $null = Copy-Item "$(Join-Path -Path $tmpDir -ChildPath $unzippedArchive)/*" $dest -Force -Recurse
        }
    }
}

# Install-PSModuleFromGitHub dfinke/nameit
# Install-PSModuleFromGitHub dfinke/nameit TestBranch
