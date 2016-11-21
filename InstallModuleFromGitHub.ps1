function Install-ModuleFromGitHub {
    [CmdletBinding()]
    param(
        $GitHubRepo,
        $Branch="master",
        [Parameter(ValueFromPipelineByPropertyName)]
        $ProjectUri
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
            
                $OutFile="$($pwd)\$($Branch).zip"
                
                Invoke-RestMethod $url -OutFile $OutFile
                Unblock-File $OutFile
                Expand-Archive -Path $OutFile -DestinationPath $pwd -Force

                $targetModuleName=$GitHubRepo.split('/')[-1]
                $targetModule=".\$($targetModuleName)-$($Branch)"    
                
                $dest="C:\Program Files\WindowsPowerShell\Modules\$targetModuleName"
                $psd1=ls $targetModule *.psd1
                
                if($psd1) {
                    $ModuleVersion=(Get-Content -Raw $psd1.FullName | Invoke-Expression).ModuleVersion
                    $dest+="\$($ModuleVersion)"
                }        
                
                $null=Robocopy.exe $targetModule $dest /mir
        }
    }
}

# Install-PSModuleFromGitHub dfinke/nameit
# Install-PSModuleFromGitHub dfinke/nameit TestBranch