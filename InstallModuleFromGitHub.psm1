function Install-ModuleFromGitHub {
    [CmdletBinding()]
    param(
        $GitHubRepo,
        $Branch="master",
        [Parameter(ValueFromPipelineByPropertyName)]
        $ProjectUri,
        $DestinationPath
    )

    Process {
        if($PSBoundParameters.ContainsKey("ProjectUri")) {
            $GitHubRepo=$null
            if($ProjectUri.OriginalString.StartsWith("https://github.com")) {
                $GitHubRepo=$ProjectUri.AbsolutePath
            } else {
                $name=$ProjectUri.LocalPath.split('/')[-1]
                Write-Host -ForegroundColor Red ("Module [{0}]: not installed, it is not hosted on GitHub " -f $name)
            }
        }

        if($GitHubRepo) {
                Write-Verbose ("[$(Get-Date)] Retrieving {0} {1}" -f $GitHubRepo, $Branch)

                $url="https://github.com/{0}/archive/{1}.zip" -f $GitHubRepo, $Branch
                $targetModuleName=$GitHubRepo.split('/')[-1]

                $OutPath="$([System.IO.Path]::GetTempPath())\$targetModuleName"

                if(!(Test-Path $OutPath)) {
                    $null=md $OutPath
                }

                $OutFile="$($OutPath)\$($Branch).zip"
                
                Invoke-RestMethod $url -OutFile $OutFile
                Unblock-File $OutFile
                Expand-Archive -Path $OutFile -DestinationPath $OutPath -Force

                $targetModule="\$($targetModuleName)-$($Branch)"
                
                $dest="C:\Program Files\WindowsPowerShell\Modules"
                if($DestinationPath) {
                    $dest=$DestinationPath
                }
                $dest+="\$targetModuleName"

                $psd1=ls $OutPath *.psd1 -Recurse
                
                if($psd1) {
                    $ModuleVersion=(Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                    $dest+="\$($ModuleVersion)"
                }        
                
                $null=Robocopy.exe "$($OutPath)\$($targetModule)" $dest /mir
        }
    }
}

# Install-PSModuleFromGitHub dfinke/nameit
# Install-PSModuleFromGitHub dfinke/nameit TestBranch