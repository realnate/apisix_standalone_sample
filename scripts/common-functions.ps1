function SubstituteVariables() {
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline, Mandatory = $true)]
    [string]
    $content,

    [Parameter(Mandatory = $false)]
    [hashtable]
    $substitutions
  )

  # First replace any placeholders with explicit substitutions

  if ($substitutions.Count) {
    foreach ($key in $substitutions.Keys) {
      $replaceWhat = [regex]::Escape("`$($key)")
      $replaceWith = $substitutions[$key].replace('$', '$$')
      $content = $content -replace $replaceWhat, $replaceWith
    }
  }

  # Now finish any remaining values using environment variables where possible

  Get-ChildItem env: | ForEach-Object {
    $replaceWhat = [regex]::Escape("`$($($_.Name))")
    $replaceWith = "$($_.Value)".replace('$', '$$')
    $content = $content -replace $replaceWhat, $replaceWith
  }

  return $content
}

function StopIfLastExitCodeNot0() {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]
    $message
  )

  if ($LASTEXITCODE -ne 0) {
    Write-Host $message -ForegroundColor Red
    exit 1
  }
}