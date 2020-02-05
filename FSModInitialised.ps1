#will create this either in form of module or in form of an exe 

param (
  # add all parameters here when calling this module directly
)

#region libraries to be imported (dependancy management)

function SortedFilesInFolder
 {
    <#
    This function retunrs all the childitems in a sorted format in an array.
    task .
    #>

    param(
        [Parameter(Mandatory=$true)]
        [string]
        $folderPath,

        [Parameter(Mandatory=$true)]
        [string]
        $Extension
        )
    $sortedArray = Get-ChildItem -Path $folderPath | Where-Object Extension -EQ $Extension | Select-Object -ExpandProperty  Name | Sort-Object -Property Name -Descending   
    return $sortedArray
 }

function MoveFiles{

    # this function will move files based on sortedarray received
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $folderPath, 
        
        [Parameter(Mandatory=$true)]
        [System.Array]
        $fileArray,

        [Parameter(Mandatory=$true)]
        [System.Array]
        $outputPath,

        [Parameter(Mandatory=$true)]
        [System.Array]
        $folderIndex

    )
    foreach ($tempFiles in $fileArray)
    {
     $currentFile = "$folderPath/$tempFiles" #current file in the directory
     $destPath = "$outputPath/Premigration_$folderIndex/$tempFiles"
     [System.IO.File]::Copy($currentFile,$destPath) | Out-Null #file copied to the new location
    }


}
# this function will do initial migration test , like path check , folder creation and then pass the controller to other helper functions
function PreFileMigrationController{
    # Parameter help description
    param(

    [Parameter(Mandatory=$true)]
    [string]
    $folderPath,
    # Parameter help description
    [Parameter(Mandatory=$true)]
    [int]
    $groupCount,

    [Parameter(Mandatory=$true)]
    [string]
    $extension,

    [Parameter(Mandatory=$false)]
    [string]
    $namingConvention,

    [Parameter(Mandatory=$true)]
    [string]
    $outputPath
    )
    <# what it does
    fetch following parameters as input 

    1. Migration file path
    2. group Count
    3. Extension for separation
    4. Excel output
    5 .naming convention validtion (second release)

     task1 - sort files on the basis of name
     task2 - create folder 1.. n (n = (total files)/($groupSize) .. take ceiling value)
     task3 - take 1st 1.. $group size file and move to the folder 1 ... 
     task3 - create slave ex at each fol
     task4 - create log  at master
     task5 - create final db or ex at master
 
     Side note - refer importExcel module as well as PSCache for optimisation
    #>

    begin{
    #region test paramter value
     #endregion
    # check if folder is present in the machine
    if (!(test-path -path $folderPath)){
        #call Fatal error 
        fatalerror
    }
    
     $totalFileCount = (Get-ChildItem -Path $folderPath | Select-Object Extension | Where-Object Extension -EQ "$extension").Count
     # when the group count is less than or equal to the total files in the fodlers
     if ($groupCount -ge $totalFileCount){
         $totalFolders = 1 
     }
     else{
         
         $totalFolders = [int][math]::Ceiling(($totalFileCount/$groupCount)) # taking ceiling value since we need to have an extra folder for remaining files
     }
    }
    process{
          #create the child FD

          $sortedFileArray = sortedFilesInFolder  -folderPath $folderPath -Extension $extension # sortedarray of files
          $tempFolderCount = $totalFolders 
          #region temp folder creation in the output path
          while ($tempFolderCount -gt 0)
          {
            $tempFolderName = "Premigration_$tempFolderCount"
            New-Item -ItemType Directory -Path $outputPath -Name $tempFolderName | Out-Null
            $tempFolderCount -= 1 #reducing the count for subsequent folder creation
          }
          Write-Host "Folders Created" -ForegroundColor Green 
          #endregion
          #region extracting subarray and passing to moveFile
          $initialIndex = 0
          $destfolderIndex = 0
          while ($initialIndex -le $sortedFileArray.count)
          {
          $destfolderIndex += 1
          $finalIndex = $initialIndex + $groupCount - 1
          $subFileArray = @()
          $subFileArray = $sortedFileArray[$initialIndex..$finalIndex] # extracted subsection to move to nth folder
          MoveFiles -folderPath $folderPath -outputPath $outputPath -fileArray $subFileArray -folderIndex $destfolderIndex
          $initialIndex += $groupCount # moving the initial index to current index of the array
          }
          #endregion
    }
    end{

    }

}

preFileMigrationController -folderPath "C:\Users\t.b.ahmed\Desktop\Automation" -groupCount 3 -extension ".pdf" -outputPath "C:\Users\t.b.ahmed\Desktop\outputPath"

Write-Host "1st phase completed" -ForegroundColor Green

function appendexcel{
param(
    # Parameter help description
    [Parameter(Mandatory=$true)]
    [string]
    $fileName,

    [Parameter(Mandatory=$true)]
    [string]
    $inputData
)
process{
    if (Test-Path -Path $fileName){
        get-help  Set-Row -Detailed 
        $excelObject = New-object -TypeName OfficeOpenXml.ExcelPackage
        $excelObject.File = "C:\Users\t.b.ahmed\Desktop\outputPath\MasterData.xlsx"
        $excelObject.Workbook.Worksheets.Add("MasterData")
        Set-Row -Worksheetname "MasterData"  -ExcelPackage $excelObject

    }
    else{
        new-item -path $fileName | Out-Null
        #create excel object for referencing 
        $excelObject = New-Object OfficeOpenXml.ExcelPackage
        $excelObject.File = "C:\Users\t.b.ahmed\Desktop\outputPath\MasterData.xlsx"
        $excelObject.Workbook.Worksheets.Add("MasterData")
        Set-ExcelRow -Value {"1,23,4:1,3,3:2"}  -ExcelPackage $excelObject -Worksheetname "MasterData"
    }
}

}

function appendsql{

}
function AppendExorDB{
    <#
    This function will append the DB log or excel log (Master setup) based on the switch
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $folderPath,

        [Parameter(Mandatory=$False, ParameterSetName ="SQL")]
        [switch]
        $SQL,

        [Parameter(Mandatory=$False, ParameterSetName ="Excel")]
        [switch]
        $Excel,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $inputData


    )

    begin{
        #split the data stream (since begin block is only invoked once and we will be fetching data from pipeline)
        $inputData = "filename1,foldername1,size1;filename2,foldername1,size2"
        $splittedData = $inputData -split ";"
        $intialIndex = 0
        $dataLength = $inputData.Length()
        $parameterSetName = $PSCmdlet.ParameterSetName
    }
    process
    {
        while($intialIndex -lt $dataLength){
           $insertedData = $splittedData[$initialIndex] # get the data to be inserted
           switch ($parametersetname)
           {
               "SQL" {} #call sql insertion
               "Excel" {} #call Excel insertion
           }
           $intialIndex +=1 # incrementing index to point to the next data in the array
        }
    }
    end{
        #dispose all open sessions
    }
}


function VerifyFileName{
    <#
    This function will verify the file naming convetion before moving to a folder location
    #>
}

function Createlog{
<#
Create a global log path

#>
param(
    
)

}

function fatalerror{
    <#
    in Case of fatal error objects will be disposed here and the execution will stop
    #>
}

<#
other helper functions to be mentioned below
#>

