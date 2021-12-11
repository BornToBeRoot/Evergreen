Function Get-Zoom {
    <#
        .SYNOPSIS
            Get the current version and download URL for Zoom.

        .NOTES
            Author: Trond Eirik Haavarstein
            Twitter: @xenappblog
    #>
    [OutputType([System.Management.Automation.PSObject])]
    [CmdletBinding(SupportsShouldProcess = $False)]
    param (
        [Parameter(Mandatory = $False, Position = 0)]
        [ValidateNotNull()]
        [System.Management.Automation.PSObject]
        $res = (Get-FunctionResource -AppName ("$($MyInvocation.MyCommand)".Split("-"))[1]),

        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateNotNull()]
        [System.String] $Filter
    )

    ForEach ($platform in $res.Get.Download.Keys) {
        ForEach ($installer in $res.Get.Download[$platform].Keys) {

            # Follow the download link which will return a 301/302
            $redirectUrl = Resolve-SystemNetWebRequest -Uri $res.Get.Download[$platform][$installer]

            # Match the URL without the text after the ?
            If ($Null -eq $redirectUrl) {
                Write-Verbose -Message "$($MyInvocation.MyCommand): Setting fallback URL to: $($script:resourceStrings.Uri.Issues)."
                $Url = $script:resourceStrings.Uri.Issues
            }
            Else {
                try {
                    $Url = [RegEx]::Match($redirectUrl.ResponseUri.AbsoluteUri, $res.Get.MatchUrl).Captures.Groups[1].Value
                }
                catch {
                    $Url = $redirectUrl.ResponseUri.AbsoluteUri
                }
            }

            # Match version number from the download URL
            try {
                $Version = [RegEx]::Match($Url, $res.Get.MatchVersion).Captures.Groups[0].Value
            }
            catch {
                $Version = "Latest"
            }

            # Construct the output; Return the custom object to the pipeline
            $PSObject = [PSCustomObject] @{
                Version  = $Version
                Platform = $platform
                Type     = $installer
                URI      = $Url
            }
            Write-Output -InputObject $PSObject
        }
    }
}
