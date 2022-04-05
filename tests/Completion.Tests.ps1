Describe 'PSUnixUtilCompleters completion tests' {
    BeforeDiscovery {
        Import-Module "$PSScriptRoot/../out/PSUnixUtilCompleters"
        $zsh = Get-Command -ErrorAction Ignore zsh
        $bsh = Get-Command -ErrorAction Ignore /bin/bash
        $skipZsh = $null -eq $zsh ? $true : $false
        $skipBsh = $null -eq $bsh ? $true : $false
        if ( $skipZsh ) { $zsh = Get-Command Write-OutPut }
        if ( $skipBsh ) { $bsh = Get-Command Write-Output }
    }

    Context "Script Analyzer" {
        It "There should be no script analyzer violations" {
            $result = Invoke-ScriptAnalyzer -Recurse -Path "$PSScriptRoot/.."
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Bash completions" {
        BeforeDiscovery {
            if ( $skipZsh ) {
                return
            }
            if (Test-Path /etc/bash_completion) {
                $bashCompletionScript = "/etc/bash_completion"
            }
            else {
                $bashCompletionScript = "/usr/local/etc/bash_completion"
            }
            $bcomp = "$PSScriptRoot/bash-completer"
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
            $completionTestCases = @(
                @{ InStr = 'gzip --'; CursorPos = 7; Suggestions = (& $bsh -c "$bcomp $bashCompletionScript 'gzip --'") }
                @{ InStr = 'dd i'; CursorPos = 4; Suggestions = (& $bsh -c "$bcomp  $bashCompletionScript 'dd i'") }
            )
            Set-PSUnixUtilCompleter -ShellType Bash -CompletionScript $bashCompletionScript
        }

        It "Completes <InStr> correctly" -foreach $completionTestCases -skip:$skipBsh {
            # param($InStr, $CursorPos, $Suggestions)

            $result = TabExpansion2 -inputScript $InStr -cursorColumn $CursorPos

            foreach ($s in $Suggestions)
            {
                $result.CompletionMatches.CompletionText | Should -Contain $s
            }
        }
    }

    Context "Zsh completions" {
        BeforeDiscovery {
            if ( $skipZsh ) {
                return
            }
            $moduleVersion = (Get-Module PSUnixUtilCompleters).Version.ToString()
            $zcomp = "$PSScriptRoot/../out/PSUnixUtilCompleters/${moduleVersion}/zcomplete.sh"
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
            $completionTestCases = @(
                @{ InStr = 'ls -a'; CursorPos = 5; Suggestions = (& $zsh $zcomp 'ls -a').where({"$_" -match ' -- '}).foreach({"$_".Split(' ')[0]}) }
                @{ InStr = 'grep --'; CursorPos = 7; Suggestions = (& $zsh $zcomp 'grep --').where({"$_" -match ' -- '}).foreach({"$_".Split(' ')[0]}) }
                @{ InStr = 'dd i'; CursorPos = 4; Suggestions = (& $zsh $zcomp 'dd i').where({"$_" -match ' -- '}).foreach({"$_".Split(' ')[0]}) }
                @{ InStr = 'cat -'; CursorPos = 5; Suggestions = (& $zsh $zcomp 'cat -').where({"$_" -match ' -- '}).foreach({"$_".Split(' ')[0]}) }
                @{ InStr = 'ps au'; CursorPos = 5; Suggestions = (& $zsh $zcomp 'ps au').where({"$_" -match ' -- '}).foreach({"$_".Split(' ')[0]}) }
            )
            Set-PSUnixUtilCompleter -ShellType Zsh
        }

        It "Completes '<inStr>' correctly" -foreach $completionTestCases -skip:$skipZsh {
            # param($InStr, $CursorPos, $Suggestions)

            $result = TabExpansion2 -inputScript $InStr -cursorColumn $CursorPos

            foreach ($s in $Suggestions)
            {
                $result.CompletionMatches.CompletionText | Should -Contain $s
            }
        }
    }
}
