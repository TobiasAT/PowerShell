
function Build-TALanguageTable 
{
    <#
        .SYNOPSIS
        The Build-TALanguageTable command creates a table with language information.

        .DESCRIPTION
        This command builds a table that contains information about different languages. 
        Each entry in the table is a hashtable that includes the following properties:
        - Language: The two-letter language code.
        - Language_DisplayName: The full name of the language.
        - LanguageId_SP: The language ID used by SharePoint.
        - LanguageCode_SP: The language code used by SharePoint.
        - LanguageCode_DeepL_Source: The language code used by the DeepL API for source text.
        - LanguageCode_DeepL_Target: The language code used by the DeepL API for target text.

        .EXAMPLE
        Build-TALanguageTable        

        .NOTES
        The language codes and IDs are based on the following references:
        - SharePoint: https://pkbullock.com/resources/reference-sharepoint-online-languages-ids/
        - DeepL: https://developers.deepl.com/docs/resources/supported-languages
        
        Author: Tobias Asboeck - https://github.com/TobiasAT/PowerShell 
        Last updated: 31.03.2024 
    #>    

    $LanguageData = @(
        @{
            Language = 'EN' 
            Language_DisplayName = 'English' 
            LanguageId_SP = 1033 
            LanguageCode_SP = 'en-US'
            LanguageCode_DeepL_Source = 'EN'
            LanguageCode_DeepL_Target = 'EN-US'
        },
        @{
            Language = 'DE' 
            Language_DisplayName = 'German'
            LanguageId_SP = 1031 
            LanguageCode_SP = 'de-DE'
            LanguageCode_DeepL_Source = 'DE'
            LanguageCode_DeepL_Target = 'DE'
        },
        @{
            Language = 'FR' 
            Language_DisplayName = 'French'
            LanguageId_SP = 1036 
            LanguageCode_SP = 'fr-FR'
            LanguageCode_DeepL_Source = 'FR'
            LanguageCode_DeepL_Target = 'FR'
        },
        @{
            Language = 'IT' 
            Language_DisplayName = 'Italian'
            LanguageId_SP = 1040 
            LanguageCode_SP = 'it-IT'
            LanguageCode_DeepL_Source = 'IT'
            LanguageCode_DeepL_Target = 'IT'
        },
        @{
            Language = 'ES' 
            Language_DisplayName = 'Spanish'
            LanguageId_SP = 3082 
            LanguageCode_SP = 'es-ES'
            LanguageCode_DeepL_Source = 'ES'
            LanguageCode_DeepL_Target = 'ES'
        }
    )

    # Build the table
    $LanguageTable = $LanguageData | ForEach-Object { [PSCustomObject]$_ }
    $LanguageTable 
}

