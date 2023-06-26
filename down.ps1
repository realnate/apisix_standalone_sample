[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]
  $namespace,
  
  [Parameter(Mandatory = $false)]
  [string]
  $reloaderHelmReleaseName,
  
  [Parameter(Mandatory = $false)]
  [bool]
  $removeEntireNamespace,
  
  [Parameter(Mandatory = $false)]
  [hashtable]
  $substitutions
)

$ErrorActionPreference = "Stop"

. .\scripts\common-functions.ps1

$reloaderHelmReleaseName = if ($reloaderHelmReleaseName) { $reloaderHelmReleaseName } else { 'reloader' }

$substitutions = if ($substitutions) { $substitutions } else { @{} }
$substitutions['namespace'] = $namespace

$configMaps = , 'apisix-apisix-yaml', 'apisix-config-yaml'
$secrets = $null

#
# Delete APISIX
#

try {

  Write-Host "Removing APISIX standalone"

  Get-Content .\kubernetes\apisix-deploy.yaml | `
    Out-String | `
    SubstituteVariables -substitutions $substitutions | `
    kubectl delete -n $namespace -f -

  StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"

  Write-Host "Removed APISIX standalone"
}
catch {
  Write-Error "Failed to delete apisix. Aborting removal process. Investigate!`n$_"
  return
}

#
# Delete Reloader helm chart
#

try {
  $installed = helm list -n $namespace -f $reloaderHelmReleaseName --no-headers
  if ($installed) {
    Write-Host "Uninstalling Reloader Helm Release Named '$reloaderHelmReleaseName' in Namespace '$namespace'..."
    helm uninstall -n $namespace $reloaderHelmReleaseName --wait --timeout 15m0s
    StopIfLastExitCodeNot0 -message "helm returned exit code $LASTEXITCODE"
  }
  else {
    Write-Host "APISIX Helm Release Named '$reloaderHelmReleaseName' in Namespace '$namespace' does not appear to exist... skipping uninstall."
  }
}
catch {
  Write-Error "Failed to uninstall reloader. Aborting removal process. Investigate!`n$_"
  return
}

#
# Delete the config maps
#

foreach ($configMap in $configMaps) {
  try {
    $installed = kubectl get configmap $configMap -n $namespace --ignore-not-found=true
    if ($installed) {
      Write-Host "Removing Config Map Named '$configMap' in Namespace '$namespace'..."
      kubectl delete configmap -n $namespace $configMap
      StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"
    }
    else {
      Write-Host "Config Map '$configMap' in Namespace '$namespace' does not appear to exist... skipping removal."
    }
  }
  catch {
    Write-Error "Failed to delete config map. Aborting removal process. Investigate!`n$_"
    return
  }
}

 
#
# Delete secrets
#

foreach ($secret in $secrets) {
  try {
    $installed = kubectl get secret $secret -n $namespace --ignore-not-found=true
    if ($installed) {
      Write-Host "Removing Secret Named '$secret' in Namespace '$namespace'..."
      kubectl delete secret -n $namespace $secret
      StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"
    }
    else {
      Write-Host "Secret '$secret' in Namespace '$namespace' does not appear to exist... skipping removal."
    }
  }
  catch {
    Write-Error "Failed to delete secret. Aborting removal process. Investigate!`n$_"
    return
  }
}

#
# Delete the namespace
#

if ($removeEntireNamespace) {
  try {
    $installed = kubectl get ns $namespace --ignore-not-found=true
    if ($installed) {
      Write-Host "Removing namespace '$namespace'..."
      kubectl delete namespace $namespace
      StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"
    }
    else {
      Write-Host "Namespace '$namespace' does not appear to exist... skipping removal."
    }
  }
  catch {
    Write-Error "Failed to delete namespace. Aborting removal process. Investigate!`n$_"
    return
  }
}
