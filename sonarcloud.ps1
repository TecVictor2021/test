param(
    [string] $sonarSecret
)


Install-package BuildUtils -Confirm:$false -Scope CurrentUser -Force
Import-Module BuildUtils

$runningDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$testOutputDir = "$runningDirectory/TestResults"
Write-host "sonarcloud.ps1 before if"
if (Test-Path $testOutputDir) 
{
    Write-host "Cleaning temporary Test Output path $testOutputDir"
    Remove-Item $testOutputDir -Recurse -Force
}

Write-host "sonarcloud.ps1 after if"
#$version = Invoke-Gitversion
#$assemblyVer = $version.assemblyVersion 
$assemblyVer = 5.2.4


$branch = git branch --show-current
Write-Host "branch is $branch"

Write-host "sonarcloud.ps1 before restore"
dotnet tool restore
Write-host "sonarcloud.ps1 before sonarscanner"
dotnet tool run dotnet-sonarscanner begin /k:"TecVictor2021_test" /o:"tecvictor2021" /v:"$assemblyVer" /d:sonar.login="$sonarSecret" /d:sonar.host.url="https://sonarcloud.io" /d:sonar.cs.vstest.reportsPaths=TestResults/*.trx /d:sonar.cs.opencover.reportsPaths=TestResults/*/coverage.opencover.xml /d:sonar.coverage.exclusions="**Test*.cs" /d:sonar.branch.name="$branch"
Write-host "sonarcloud.ps1 before restore 2"
dotnet restore # add folder if is necesary "src"
Write-host "sonarcloud.ps1 before build"
dotnet build --configuration release # src --configuration release
Write-host "sonarcloud.ps1 before test"
dotnet test "./MarketTecBotApiNet5.Test/MarketTecBotApiNet5.Test.csproj" --collect:"XPlat Code Coverage" --results-directory TestResults/ --logger "trx;LogFileName=unittests.trx" --no-build --no-restore --configuration release -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover
tree /f    
Write-host "sonarcloud.ps1 before end"
dotnet tool run dotnet-sonarscanner end /d:sonar.login="$sonarSecret"
