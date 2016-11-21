$ModuleName   = "InstallModuleFromGitHub"
$ModulePath   = "C:\Program Files\WindowsPowerShell\Modules"
$TargetPath = "$($ModulePath)\$($ModuleName)"

if(!(Test-Path $TargetPath)) { md $TargetPath | out-null}

$targetFiles = echo `
    *.psm1 `
    *.psd1 `
    License.txt `



ls $targetFiles |
    ForEach {
        Copy-Item -Verbose -Path $_.FullName -Destination "$($TargetPath)\$($_.name)"
    }