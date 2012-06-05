#enumerates over a folder's trx files to list in order what's passed/failed.
add-type -assemblyName mscorlib;

function get-FailuresOverTime([string]$folder = (pwd).Path){
if (-not(test-path($folder))){
  Write-host -fore red ('"' + $folder + '" does not exist.  Specify a valid folder');
  return;
}
  write-host -fore green 'Test over time'
  $totalFailed
  $files = ls $folder *.trx;

  $fileInfos = @{};
  $FileXmls = @{};
  $failedLists = @{}

  $files | % { 
    $date = $_.LastWriteTime;
    $xml = [Xml](cat $_.FullName);
    $fileXmls[$date] = $xml;
    $fileInfos.Add($date, $_);
    $failed = $xml.TestRun.Results.UnitTestResult | where  { $_.outcome -match 'Failed' };
    $failedLists[$date] = @{};
    $failed | % { $failedLists[$date].Add($_.TestName, $_);}
  }

  $allFailed = @{};
  $failedLists.Keys | % { #foreach failed list 
                          $failedLists[$_].Keys | % { #foreach failed test
                            if (-not($allFailed.ContainsKey($_))){ $allFailed.Add($_, $_); }
                          }
                    }
  
  write-host -nonewline ''.PadLeft(48);
  $sortedDates = $fileXmls.Keys | sort;
  $sortedDates | % { write-host -nonewline -fore white $_.ToString('MM/dd/yy hh:mm').padright(20); }
  write-host;
  $allFailed.GetEnumerator() | Sort-Object Name | % {
      $testName = $_.Name;
      write-host $testName.PadRight(48) -nonewline; 
      $sortedDates | % { 
        if ($failedLists[$_].ContainsKey($testName)) { write-host -fore black -nonewline 'failed'.padRight(20) -back red; }
        else { write-host -nonewline ''.PadRight(20); }
      }
      write-host;
  }

}