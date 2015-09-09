#!/usr/bin/env fme

set workspacename {C:/Users/mssqlgisadmin/Documents/GitHub/fme-jobs/processing/workbench/UpdateMSDPIPESfromZDump.fmw}

set destDirList {}
set recreateSourceTree "no"

set superBatchFileName [FME_TempFilename]

set superBatchFile [open $superBatchFileName "w"]

lappend sourceDatasets {//coa-backup/gisdata/Engineering/ZDump/MSDUpdate/msdpipesnad83.shp}

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
set spot 0
set numDatasets [llength $sourceDatasets]
set extraDatasets {}
while {$spot < $numDatasets} {
    set nextSpot $spot
    incr nextSpot;
    set curDataset [lindex $sourceDatasets $spot]
    set curSourceDirectory [file dirname [file rootname $curDataset] ]


    # If we are replicating the directory structure, remove the common
    # portion of the source dataset, and use it in the formation of the
    # destination dataset.

    if { ($commonSource != {}) &&
         ([string first $commonSource $curSourceDirectory] == 0) } {
       set baseName [string range $curSourceDirectory [string length $commonSource] end]
       set destIndex 0
       set numDest [llength $destDirList]
       while {$destIndex < $numDest} {
          set destDir [lindex $destDirList $destIndex]
          set destDSetType [lindex $destDSetTypeList $destIndex]
          incr destIndex
          if { $destDSetType == 1} {
             catch { file mkdir [file dirname $destDir] }
          } else {
             catch { file mkdir [file dirname $destDir$baseName] }
          }
       }
    } else {
       set baseName [file tail [file rootname $curSourceDirectory]]
    }
    if { ($commonSource != {}) &&
         ([string first $baseName $commonSource] != -1) } {
         set baseName {}
    }


    set break 0
    if { ($nextSpot < $numDatasets) }  {
        set nextDataset [lindex $sourceDatasets $nextSpot]
        set nextSourceDirectory [file dirname [file rootname $nextDataset] ]
        if { ($nextSourceDirectory != $curSourceDirectory) ||
             ([lsearch $destDSetTypeList 0] == -1) } {
            set break 1
        } else {
            # Add to the list of like datasets
            set extraDatasets "$extraDatasets +SHAPE_1_DATASET \"$curDataset\"" 
        } 
    } else {
        set break 1
    }
    if { $break == 1 } {
        set destDatasetLine {}
        set destIndex 0
        set numDest [llength $destDirList]
        while {$destIndex < $numDest} {
           set destDir [lindex $destDirList $destIndex]
           set suffix [lindex $suffixList $destIndex]
           set destDSetType [lindex $destDSetTypeList $destIndex]
           if { $destDSetType == 1} {
               set destDataset "$destDir$suffix"
           } else {
               set destDataset "$destDir$baseName$suffix"
           }
           set destDatasetLine "$destDatasetLine --[lindex $destMacroList \"$destIndex\"] \"$destDataset\"" 
           incr destIndex
        }
        puts $superBatchFile "\"$workspacename\" --SourceDataset_SHAPE \"$curDataset\" $destDatasetLine $extraDatasets $logStandardOut $logTimings"
        set extraDatasets {}
    }
    incr spot
}

close $superBatchFile

set fmeHome {}
catch { set fmeHome $::env(FME_HOME)/ }


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

