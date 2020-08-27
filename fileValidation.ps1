# this will be the wrapper for 1st release 
# param (
#     [Parameter(Mandatory=$true)]
#     [string]
#     $sourcePath,

#     [Parameter(Mandatory=$true)]
#     [string]
#     $destinationPath,

#     [Parameter(Mandatory=$false)]
#     [string]
#     $country = "NL" # default it to netherland as the first release is focussed on netherland

# )

Measure-Command{
function _movetofailedValidationFolder{
param (
    [Parameter(Mandatory=$true)]
    [string]
    $fileName
)
process{
    try{
    Move-Item -Path $fileName -Destination $Global:failedFolderpath | Out-Null
    return "SUCCESS"
}
    catch{
        Write-Host "file $filename could not be moved to failed folder" -BackgroundColor Yellow
        return "Failed"
    }
}
}
function _ValidateUnderscores{
    
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $stringtoValidate
    )
    process{
        $charCount = ($stringtoValidate.ToCharArray() | Where-Object {$_ -eq '_'} | Measure-Object).Count
        #Write-Host "number of underscores are $charcount"
        if ([int]$charCount -ne 9)
        {return "FAILED"}
        else{
            return "SUCCESS"
        }
    }
}

function ValidationMain{ 
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $sourcePath,
    
        [Parameter(Mandatory=$true)]
        [string]
        $destinationPath,
    
        [Parameter(Mandatory=$false)]
        [string]
        $country = "NL" # default it to netherland as the first release is focussed on netherland
    
    )# main function which will inetarct with all other 
begin{
    
    #region Source and destination validation
    Write-Host "Validating source and destinaion" -ForegroundColor Blue
    if (!(test-path $sourcePath)){
        throw "Source path not in the host , please provide the correct source path"
    }
    Write-Host "Source path found" -ForegroundColor Green
    if (!(Test-Path $destinationPath)){
        throw "Destination path not in the host , please provide the correct Destination path" 
    }
    Write-Host "destination path found" -ForegroundColor Green
    #endregion

    #region failed validation folder creation
    try{
        Write-Host "Creating a failed validation folder"
        New-Item -ItemType Directory -Path $sourcePath -Name "FailedValidation" -ErrorAction SilentlyContinue
        Write-Host "Created the failed validation folder" -ForegroundColor Green
        $Global:failedFolderpath = "$sourcePath\FailedValidation"
    }
    catch{
        throw "issue while creaing a failed validation folder"
    }
    #endregion

    #region load global config variables
       # the value of the config will be used in the validation 
    #endregion

}
process{
    #region fetch the child items of the Souce folder
    Write-Host "fetching files from the source folder" -ForegroundColor Blue
    try{
     $filesfromSource = Get-ChildItem $sourcePath -ErrorAction Stop  -File
    }
    catch{
       throw "error while fetching child item of the source path $($_.exception.message)"
    }
    Write-Host "file fetch completed" -ForegroundColor Green
    #endregion

    #region validation mainK
    write-host "starting the validation" -ForegroundColor Blue
    foreach ($currentfile in $filesfromSource) {
        $filename = $currentfile.Name
      #  write-host "Current File selected is $filename" -ForegroundColor Blue
        #region Underscore validation
       # Write-Host "validating Underscore count..." -ForegroundColor Blue
        $ValidateUnderscores_return = _ValidateUnderscores -stringtoValidate $filename
        if ($ValidateUnderscores_return -eq "SUCCESS"){
           # Write-Host "Underscore test passed"
        }
        else{
           # write-host "Underscore test failed moving file to the failed directory" -ForegroundColor red
            _movetofailedValidationFolder -fileName $currentfile.FullName
            #Write-Host "File moved . no further validation check done moving to next iten"
            continue
        }

        #endregion

        # #region docuement type test
        # write-host "write logic for group test here"
        # #endregion

        # #region sub dcument type test
        # Write-Host "write logic for sub-group test here"
        # #endregion
        
        # #region employee ID validation
        # Write-Host "ID validation code to be written here"
        # #endregion

        # #region date format validation
        # Write-Host "date validation to be written here"
        # #endregion
        #
    }
    

    #endregion

}
end{  
    Write-Host "finished" -ForegroundColor Green
    # call the file mover code once all validation is done

 }
}
Write-Host "starting"
ValidationMain -sourcePath "C:\Terraform" -destinationpath "C:\new_terraform" }
