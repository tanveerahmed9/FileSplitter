# this will be the wrapper for 1st release 
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

)
#Requires -RunAsAdministrator

#region Libraries, dependancies
#Import-Module powershell-yaml -ErrorAction SilentlyContinue
#required Powershell-yaml
#endregion

#region Class
Class FileSplitter{
   
    #region class property
    [string]$filename;
    [string]$stringtoValidate;
    static [string]$failedFolderpath;
    static $validateCount = 9;
    static [string]$commonLogs;
    static $collectiontoMatchgainst;
    [string] $validationResult;
    [System.Management.Automation.PSCustomObject] $fileCustomObject; # to store the current file separated data

    #endregion

    #region class method
     _movetofailedValidationFolder(){
            try{
            Move-Item -Path $this.fileName -Destination [FileSplitter]::failedFolderpath -ErrorAction SilentlyContinue| Out-Null     
           }
            catch{
                Write-Verbose "file $($this.filename) could not be moved to failed folder" -BackgroundColor Yellow
                Write-Verbose "Failed"
            }
        }
     _writeFilelog(){
        
     }
     #this function validates the number of 
    hidden _ValidateUnderscore(){
                try
                  {
                $charCount = ($this.stringtoValidate.ToCharArray() | Where-Object {$_ -eq '_'} | Measure-Object).Count
                #Write-Host "number of underscores are $charcount"
                if ([int]$charCount -ne [FileSplitter]::validateCount)
                {$this.validationResult = "FAILED"}
                else{
                    $this.validationResult = "SUCCESS"
                }
            }
            catch{

            }
            
        }
    
    hidden  _dateFormatValidation(){ # second release
           
        }

    hidden _GroupValidation(){
            
                 if ($this.collectiontoMatchgainst -ccontains $this.stringToMatch)
                 {
                     
                 }
            
                 else{
                    $this.validationResult = "SUCCESS"
                 }
                }
            
    
    hidden _assignIndividualIdentifier(){
    
                    $splittedarray = $this.filename -split "_" 
                    #create custom object here for the fields which require validation
                    $this.FileCustomObject = [PSCustomObject]@{
                        countyCode = $splittedarray[0]
                        employeeID = $splittedarray[1]
                        documentType = $splittedarray[2]
                        subDocumentType = $splittedarray[3]
                        documentDate = $splittedarray[5]
                        ingestionDate = $splittedarray[6]
                    }
                    
                }
    }
   #endregion
    

    main{ 
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
        $global:yamlContent = Get-Content -Path ./validationconfig.yml -Raw
        $global:yamlContent = $yamlContent | ConvertFrom-Yaml # converting from YAML to hast table use $yamlContent.gettype() and check out memebers to understand more
        $global:progressInitial = 0 # progress tracker
        [float]$global:progressPercentage = 0 # progress tracker
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
        $totalFiles = $filesfromSource.count
        write-host "total files are $totalfiles"
        $progressInitial = $totalFiles + 1
        foreach ($currentfile in $filesfromSource) {
            $progressInitial -= 1
            $progressPercentage = (($totalFiles-$progressInitial)/$totalFiles)*100
            $progressPercentage = [math]::Round($progressPercentage,2)
            Write-Progress -Activity "Scanning in Progress" -PercentComplete $progressPercentage -Status "$progressPercentage% completed";
            $filename = $currentfile.Name
            write-verbose "Current File selected is $filename" 
            #region Underscore validation
        # Write-Host "validating Underscore count..." -ForegroundColor Blue
            $ValidateUnderscores_return = _ValidateUnderscores -stringtoValidate $filename 
            if ($ValidateUnderscores_return -eq "SUCCESS"){
            # Write-Host "Underscore test passed"
            Write-Verbose "UnderScore test passed"
            }
            else{
                write-verbose "Underscore test failed moving file to the failed directory" 
                _movetofailedValidationFolder -fileName $currentfile.FullName
                Write-Verbose "File moved . no further validation check done moving to next iten"
                continue
            }

            #endregion
            
            #region assign file variables for validation
            [pscustomobject]$validationCustomObject = _assignIndividualIdentifier -stringforIdentifier $filename
            
            #endregion

            #region Country Code Validation
            $currentCountryCode  = $validationCustomObject.countyCode
            $allcountryCodes = $yamlContent.Country
            # match the country code against the config config codes
            if($currentCountryCode){
            $countryCodeValidation = _GroupValidation -stringToMatch $currentCountryCode -collectiontoMatchgainst $allcountryCodes
            if ($countryCodeValidation -eq "SUCCESS"){
                Write-Verbose "Passed the country validation test for file $currentfile"
            }
            else{
                Write-Verbose "failed the country validation test for file $currentfile  moving to failed folder"
                _movetofailedValidationFolder -filename $currentfile.FullName
                continue
            }
            }
            else{
                #country code empty , failed country code validation , since 
            }
            #endregion

            #region docuement type test
            if ($validationCustomObject.documentType){
            $groupameValidationReturn = _GroupValidation -stringToMatch $validationCustomObject.documentType -collectiontoMatchgainst $yamlContent.DocumentType
            if ($groupameValidationReturn -eq "FAILED"){
                _movetofailedValidationFolder -filename $currentfile.FullName
                Write-verbose "valied the 1st group test moving to failed folder"
                continue
            }
        }
            else{ # when the search string is empty
                _movetofailedValidationFolder -filename $currentfile.FullName
                Write-verbose "valied the 1st group test moving to failed folder"
                continue
            }
            
            #endregion

            #region sub dcument type test
            #fetching sub-document based on docuemnt type asuming $validationCustomObject.documentType is right group as it passd the document test.
            $documentType = $validationCustomObject.documentType
            $subdocumentArray = $yamlContent.$documentType # fetching sub-document based on document value
            $subDocStringToMatch = $validationCustomObject.subDocumentType
            # do a validation against sub groups
            if ($subDocStringToMatch){
            $subGroupValidationreturn = _GroupValidation -stringToMatch $subDocStringToMatch -collectiontoMatchgainst $subdocumentArray
            if ($subGroupValidationreturn -eq "FAILED"){
                Write-Verbose "File $filename fails the sub-group test , moving to failed folder"
                _movetofailedValidationFolder -fileName $currentfile.FullName
                continue
            }
            else{
                write-verbose "File $filename passes sub group test"
            }
        }


            else{
                write-verbose "Sub Group string is empty , validation failed moving to failed folder"
                _movetofailedValidationFolder -fileName $currentfile.FullName
            }
            #endregion
            
            # #region employee ID validation
            # Write-Host "ID validation code to be written here"
            $employeeID = $validationCustomObject.employeeID
            if (!($employeeID -match "^[0-9]*$")) # employee ID needs to be only numbers
            {
                Write-Verbose "employee ID contains non-Integer entry , moving to failed validation folder"
                _movetofailedValidationFolder -fileName $currentfile.FullName
            }
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



#endregion
Write-Host "starting"
ValidationMain -sourcePath $sourcePath -destinationpath $destinationPath




