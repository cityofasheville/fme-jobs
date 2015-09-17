#!/usr/bin/env fme

set workspacename {C:/Users/mssqlgisadmin/Documents/GitHub/fme-jobs/edit_to_warehouse_fc/workbench/coa_fire_response_time.fmw}

set destDirList {}
set recreateSourceTree "no"

set superBatchFileName [FME_TempFilename]

set superBatchFile [open $superBatchFileName "w"]

lappend sourceDatasets {coa-gis-edit1}

set logStandardOut {}
set logTimings {}

set sourceDatasets [lsort [eval FME_RecursiveGlob $sourceDatasets]]
# When the "Recreate source directory tree" option has been selected,
# find the deepest directory that all of the source datasets have in common.
# This will be removed from each to form the destination dataset name.

set commonSource {}
if { [string first {yes} $recreateSourceTree] != -1 } {

   # And now the interesting part.  We start out assuming that everything up
   # to the last "/" in the first dataset is the common part, and then
   # start shortening it until we've looked at all datasets.

   foreach dataset $sourceDatasets {
      regsub {/[^/]*/*$} $dataset / datasetDir

      if { $commonSource == {} } {
         # The first time through, we will take the whole dataset directory
         # to seed our notion of what's in common

         set commonSource "${datasetDir}"
      } else {
         # Compare this dataset's directory with our current notion of
         # the commonPart.  We will iteratively remove path portions from
         # the end one or the other (or both) until they match.

         while { $datasetDir != $commonSource } {
            if { [string length $datasetDir] >= [string length $commonSource] } {
               regsub {[^/]*/*$} $datasetDir {} datasetDir
            } else {
               if { [string length $commonSource] >= [string length $datasetDir] } {
                  regsub {[^/]*/*$} $commonSource {} commonSource
               }
            }
         }
      }
   }
}
foreach sourceDataset $sourceDatasets {
    # If we are replicating the directory structure, remove the common
    # portion of the source dataset, and use it in the formation of the
    # destination dataset.

    if { ($commonSource != {}) &&
         ([string first $commonSource $sourceDataset] == 0) } {
       set baseName [file rootname [string range $sourceDataset [string length $commonSource] end]]
       catch { file mkdir [file dirname $destDir$baseName] }
    } else {
       set baseName {}
    }

    set destDatasetLine {}
    set destIndex 0
    set numDest [llength $destDirList]
    while {$destIndex < $numDest} {
       set destDir [lindex $destDirList $destIndex]
       set suffix [lindex $suffixList $destIndex]
       set destDataset "$destDir$baseName$suffix"
       set destDatasetLine "$destDatasetLine --[lindex $destMacroList \"$destIndex\"] \"$destDataset\"" 
       incr destIndex
    }
    puts $superBatchFile "\"$workspacename\" $destDatasetLine $logStandardOut $logTimings"
}

close $superBatchFile

set fmeHome {}
catch { set fmeHome $::env(FME_HOME)/ }

if [ catch { ${fmeHome}fme COMMAND_FILE $superBatchFileName } err ] {
  puts $err
  puts "\nFME encountered an error. Please contact support@safe.com"
} else {
  puts "\nTranslation SUCCESSFUL"
}
if [ catch { file delete $superBatchFileName } ] {
  puts "Warning: unable to delete $superBatchFileName"
}

if [ catch { ${fmeHome}fme COMMAND_FILE $superBatchFileName } err ] {
  puts $err
  puts "\nFME encountered an error. Please contact support@safe.com"
  return -code error -errorinfo "FME encountered an error. Please contact support@safe.com" -errorcode "-999"
} else {
  puts "\nTranslation SUCCESSFUL"
}
if [ catch { file delete $superBatchFileName } ] {
  puts "Warning: unable to delete $superBatchFileName"
}