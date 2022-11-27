Install a PowerShell Module from GitHub
-

Not all PowerShell Modules are published to the PowerShellGallery but are hosted on GitHub.

[Read the blog post](https://dfinke.github.io/powershell/2016/11/21/Quickly-Install-PowerShell-Modules-from-GitHub.html)

##  Changes 

## 1.6.0

via https://github.com/dfinke/InstallModuleFromGitHub/pull/25

- on non-unix platforms, fixed the psd1 file search
join-path on line 87 was joining two full paths, which is not a
valid result.
## 1.5.0

Thank you to [Max Renner](https://github.com/rennerom) for the pull request.

- Use  [System.Environment]::OSVersion.Platform -eq "Unix" as a catch all for non-windows systems
- Replaced the hard coded Module paths assigned to $dest with environment variables instead.
- Added if logic for Windows vs Non-Windows machines in assigning $psd1 and in the final Copy-Item statement.

## 1.4.0

- Fix module installation path (Thanks [JonathanPitre](https://github.com/JonathanPitre))

## v 0.5.0

- Allow for copying folders recursively. Thank you to:
    - https://github.com/montereyharris
    - https://github.com/jayvdb
    - https://github.com/JonathanPitre

## In Action
![image](https://github.com/dfinke/InstallModuleFromGitHub/blob/master/media/InstallFromGitHub.gif?raw=true)