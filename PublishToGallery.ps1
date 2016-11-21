$p = @{
    Name = "InstallModuleFromGitHub"
    NuGetApiKey = $NuGetApiKey
    ReleaseNote = "First Release"
}

Publish-Module @p