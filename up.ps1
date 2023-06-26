[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]
  $namespace,

  [Parameter(Mandatory = $false)]
  [string]
  $reloaderHelmReleaseName,

  [Parameter(Mandatory = $false)]
  [hashtable]
  $substitutions
)

$ErrorActionPreference = "Stop"

. .\scripts\common-functions.ps1

$reloaderHelmReleaseName = if ($reloaderHelmReleaseName) { $reloaderHelmReleaseName } else { 'reloader' }

$substitutions = if ($substitutions) { $substitutions } else { @{} }
$substitutions['namespace'] = $namespace

#
# Add stakater helm repo
#

Write-Host "Adding stakater Helm Repo..."
helm repo add stakater https://stakater.github.io/stakater-charts
StopIfLastExitCodeNot0 -message "helm returned exit code $LASTEXITCODE"
Write-Host "Added stakater Helm Repo"

#
# Update helm repos
#

Write-Host "Updating helm repos..."
helm repo update
StopIfLastExitCodeNot0 -message "helm returned exit code $LASTEXITCODE"
Write-Host "Updated Helm repos"

#
# Create namespace if it doesn't exist
#

Write-Host "Creating Namespace '$namespace' if it doesn't already exist..."

kubectl create namespace $namespace -o yaml --dry-run=client | `
  Out-String | `
  SubstituteVariables -substitutions $substitutions | `
  kubectl apply -f -

StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"

Write-Host "Namespace created or already existed"

#
# Create the config.yaml config map
#

Write-Host "Creating config map $namespace/apisix-config-yaml..."

kubectl create configmap apisix-config-yaml -n $namespace --from-file=.\kubernetes\config.yaml -o yaml --dry-run=client | `
  Out-String | `
  SubstituteVariables -substitutions $substitutions | `
  kubectl apply -f -

StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"

Write-Host "Created or updated config map"

#
# Create the apisix.yaml config map
#

Write-Host "Creating config map $namespace/apisix..."

kubectl create configmap apisix-apisix-yaml -n $namespace --from-file=.\kubernetes\apisix.yaml -o yaml --dry-run=client | `
  Out-String | `
  SubstituteVariables -substitutions $substitutions | `
  kubectl apply -f -

StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"

Write-Host "Created or updated config map"


#
# Install APISIX
#

Write-Host "Installing APISIX standalone"

kubectl apply -f .\kubernetes\apisix-deploy.yaml -n $namespace -o yaml --dry-run=client | `
  Out-String | `
  SubstituteVariables -substitutions $substitutions | `
  kubectl apply -f -

StopIfLastExitCodeNot0 -message "kubectl returned exit code $LASTEXITCODE"

Write-Host "Installed APISIX standalone"

#
# Install Reloader Helm Chart
#

Write-Host "Installing helm chart stakater/reloader as release named $reloaderHelmReleaseName. If this takes a long time then it probably failed."
helm upgrade --install -n $namespace $reloaderHelmReleaseName stakater/reloader --set reloader.watchGlobally=false --wait --timeout 15m0s
StopIfLastExitCodeNot0 -message "helm returned exit code $LASTEXITCODE"
Write-Host "Installed helm chart"