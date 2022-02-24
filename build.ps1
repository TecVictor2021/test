param(
    [string] $nugetApiKey,
    [bool]   $nugetPublish = $false
)

Install-package BuildUtils -Confirm:$false -Scope CurrentUser -Force
Import-Module BuildUtils

$runningDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$nugetTempDir = "$runningDirectory/artifacts/NuGet"

if (Test-Path $nugetTempDir) 
{
    Write-host "Cleaning temporary nuget path $nugetTempDir"
    Remove-Item $nugetTempDir -Recurse -Force
}

$version = Invoke-Gitversion
$assemblyVer = $version.assemblyVersion 
$assemblyFileVersion = $version.assemblyFileVersion
$nugetPackageVersion = $version.nugetVersion
$assemblyInformationalVersion = $version.assemblyInformationalVersion

Write-host "assemblyInformationalVersion   = $assemblyInformationalVersion"
Write-host "assemblyVer                    = $assemblyVer"
Write-host "assemblyFileVersion            = $assemblyFileVersion"
Write-host "nugetPackageVersion            = $nugetPackageVersion"

# Now restore packages and build everything.
dotnet restore "$runningDirectory/MarketTecBotApiNet5.sln"
dotnet test "$runningDirectory/MarketTecBotApiNet5.Tests/MarketTecBotApiNet5.Tests.csproj" /p:CollectCoverage=true /p:CoverletOutput=TestResults/ /p:CoverletOutputFormat=lcov
dotnet build "$runningDirectory/MarketTecBotApiNet5.sln" --configuration release
dotnet pack "$runningDirectory/MarketTecBotApiNet5/MarketTecBotApiNet5.csproj" --configuration release -o "$runningDirectory/artifacts/NuGet" /p:PackageVersion=$nugetPackageVersion /p:AssemblyVersion=$assemblyVer /p:FileVersion=$assemblyFileVer /p:InformationalVersion=$assemblyInformationalVersion

if ($true -eq $nugetPublish) 
{
    dotnet nuget push .\artifacts\NuGet\** --source https://api.nuget.org/v3/index.json --api-key $nugetApiKey
}
