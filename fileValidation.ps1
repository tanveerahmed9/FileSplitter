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

#region Enums 
enum ValidationFunctions
{
    _ValidateUnderscore
    _assignIndividualIdentifier
    _GroupValidation
    _employeeIDValidation
}

enum ListofGroupValdations{
 country
 documentType
 subDocumentType
}
#endregion
#region Class FileValidator
Class FileValidator{
   
    #region class property
    [string] $_documentTyperun
    [powershell] $ps;
    static [System.Management.Automation.Runspaces.RunspacePool] $rs ;
    static [string]$yamlPath;
    static [System.Collections.Hashtable]$yamlContent;
    static [string]$sourcePath;
    static [string]$destinationPath
    [string]$filename;
    static [string]$failedFolderpath;
    static $validateCount = 9;
    static [string]$commonLogs;
    $_collectiontoMatchgainst;
    [string] $validationResult;
    $_fileCustomObject; # to store the current file separated data
    
    
    #endregion

    #region class method
    hidden _movetofailedValidationFolder(){
            try{
            $internalSource = [FileValidator]::sourcePath
            $currentFiletoMove = $internalSource + "\$($this.filename)"
            $destinationMovement = [FileValidator]::failedFolderpath
            Move-Item -Path "$currentFiletoMove" -Destination $destinationMovement -ErrorAction SilentlyContinue| Out-Null     
           }
            catch{
                Write-Verbose "file $($this.filename) could not be moved to failed folder" -BackgroundColor Yellow
                Write-Verbose "Failed"
            }
        }

    hidden _writeFilelog($methodName){
        $message = "Failed the Validaton - $methodName for File $($this.FileName)"
        $logPath = [FileValidator]::failedFolderPath
        $logPath = $logPath + "\logs.log"
        $message | Out-File $logpath -Append
     }
     
     #this function validates the number of 
    hidden _ValidatePath(){
        if (!(!(test-path [FileValidator]::sourcepath) -or !(test-path [FileValidator]::destinationPath)))
        {
            throw "Source or Destination path Incorrect"
        }
    }

    hidden _ValidateUnderscore(){
                try
                {
                $charCount = ($this.filename.ToCharArray() | Where-Object {$_ -eq '_'} | Measure-Object).Count
                #Write-Host "number of underscores are $charcount"
                if ([int]$charCount -ne [FileValidator]::validateCount)
                {
                    $this.validationResult = "FAILED"
                    $this._writeFilelog("ValidateUnderScore") # Writing failed log for method Validate Underscores
                    $this._movetofailedValidationFolder()
                }
                else{
                    $this.validationResult = "SUCCESS"
                    
                }
                }
            catch{
                $this.validationResult = "FAILED"
                $this._writeFilelog("ValidateUnderScore") # Writing failed log for method Validate Underscores
                $this._movetofailedValidationFolder()
            }
            
        }

    hidden _loadconfig(){
        
        [FileValidator]::yamlPath = $PSScriptRoot + "\validationconfig.yml"
        $yamlPath_ = [FileValidator]::yamlPath
        if (!(test-path "$yamlPath_")) # when YAM does not exists
        {
            throw "Config File not found , please add the config file (in the same path) and then re-initiate"
        }
        else{
            $yamlContentRaw = Get-Content -Path "$yamlPath_" -Raw -ErrorAction Stop
            [FileValidator]::yamlContent = $yamlContentRaw | ConvertFrom-Yaml
        }
    }
    
    hidden _createFailedFolder()
    {
        [FileValidator]::failedFolderPath = [FileValidator]::sourcePath + "\FailedValidation"
        $localPath = [FileValidator]::failedFolderpath
        if (!(Test-Path $localPath)){
            Write-Verbose "Creating failed Folder"
            $null = New-Item -ItemType Directory -Path $localPath 
        }
        else{
            Write-Verbose "Failed Folder path already present"
        }
    }

    hidden  _dateFormatValidation(){ # second release
           
    }

    hidden _GroupValidation_Helper($currentKey)
    {
        if ($currentKey -eq "DocumentType") # captuting document type run to compare when sub-cocument is selected
        {
            $currentString = $this._fileCustomObject.$currentKey
            $currentListToMatchAgainst  = $currentListToMatchAgainst = [FileValidator]::yamlContent.$currentKey
            $this._documentTyperun = $currentString
            
        }
        elseif ($currentKey -eq "subDocumentType") # second layer filtering in cased of sub-documentype
        {
            $currentString = $this._fileCustomObject.$currentKey
            $currentListToMatchAgainst = [FileValidator]::yamlContent.$($this._documentTyperun)
        }
        else { # for other comparisons
            $currentString = $this._fileCustomObject.$currentKey
            $currentListToMatchAgainst = [FileValidator]::yamlContent.$currentKey 
        }
     
        if (!($currentListToMatchAgainst -contains $currentString)){
            $this.validationResult = "FAILED"
            $this._writeFilelog($currentKey)
            $this._movetofailedValidationFolder()
        }
    }

    hidden _GroupValidation(){
                  
                # hash table to ietarte over all the greoup validations to be done

                 $GroupValidationList = [ordered]@{
                    Country = $this._FileCustomObject.Country
                    documentType = $this._FileCustomObject.documentType
                    subDocumentType = $this._FileCustomObject.subDocumentType
                    }

                 foreach ($currentKey in $GroupValidationList.Keys) {
                     if ($this.validationResult -eq "SUCCESS"){  # keep validating until we get a failure
                     $this._GroupValidation_Helper($currentkey)
                     }
                 }
    }
               
    hidden _assignIndividualIdentifier(){
    
                    $splittedarray = $this.filename -split "_" 
                    #create custom object here for the fields which require validation
                    $this._FileCustomObject = [PSCustomObject]@{
                        country = $splittedarray[0]
                        employeeID = $splittedarray[1]
                        documentType = $splittedarray[2]
                        subDocumentType = $splittedarray[3]
                        documentDate = $splittedarray[5]
                        ingestionDate = $splittedarray[6]
                    }

    }

    hidden _employeeIDValidation(){
        $currentEmployeeID = $this._fileCustomObject.employeeID
        if (!($currentEmployeeID -match "^[0-9]*$")) # regex for digits
        {
            $this.validationResult = "FAILED"
            $this.validationResult = "FAILED"
            $this._writeFilelog("EmployeeID")
            $this._movetofailedValidationFolder()
        }
    }

    hidden _initializeRunspace(){
        # this function can be either used separately or clubbed , we will think on it as soon as we scale the code
        # create a runspace object
        [FileValidator]::rs = [runspacefactory]::CreateRunspacePool(1,4)
        [FileValidator]::rs.open() # opem the runspace so that it can be used in the PowerShell Object
        $this.ps = [PowerShell]::Create() 
    }

    hidden _ExecuteRunspace(){
        $powerShell = [PowerShell]::Create()
        $powerShell.RunspacePool = [FileValidator]::rs
        $powerShell.AddScript($this.sbforConcurrency) # the validate is invoked in this scenario
        $powerShell.AddArgument($this.filename)
        $powerShell.BeginInvoke() | Out-Null 
    }
                
            
    FileValidator($sourcePath,$destinationPath){ # Constructor to initialize and validate
       # initialise static variable source and destination path
        # assignment 
        [FileValidator]::sourcePath = $sourcePath
        [FileValidator]::destinationPath = $destinationPath
        #tasks
        $this._initializeRunspace() # initialise the runspace for concurrency
        $this._ValidatePath() # validates the internal member source and destination path
        $this._loadconfig() # loads the config data to be available to all the instances of the class
        $this._createFailedFolder() # creates the Failed folder 
    }
 $sbforConcurrency = {
    validate($filename)
    { # main function to validate all the steps
      $this.validationResult = "SUCCESS" # initially marking the result as sucess for first validation to go through
      $this.filename = $filename
      foreach ($currentValidation in [System.Enum]::GetNames([ValidationFunctions]) ) { # Iterate through all validation methods until we get a failure or all SUCCESS
        if ($this.validationResult -ne "FAILED" ) {
            $this.$currentValidation()
            } 
      }
      
    }   
} 
#endregion
}    
#endregion

#region caller and controller
 function main($totalFileCount){
    begin{
        # initialised once 
        $FileObject = [FileValidator]::new("C:\FStst", "C:\FStst") 
        $progressTracker = -1
        $displayProgresstracker = 50 # show progress after every 20 files
    }
    process{
         # initial result assuming as success
        $progressTracker += 1
        $displayProgresstracker += 1
        $percentageProgress = (($progressTracker/$totalFileCount)*100) 
        $percentageProgress = [Math]::Round($percentageProgress,2)
        if ($displayProgresstracker%50 -eq 0){
        Write-Progress -PercentComplete "$percentageProgress" -Activity "Scanning Files in the Source" -Status "$percentageProgress% Completed"
     }
        $FileObject.validate($_) # validate the File
    }

    end{
        Write-host "Scanning Completed Total File Scanned $totalFileCount" -ForegroundColor Green
    }
}

function Controller {
    process{
        $sourcePath = "C:\FStst" 
        $files = Get-ChildItem -Path $sourcePath -File
        $totalFileCount = $files.count
        $files.Name | main($totalFileCount)
    }
}
#endregion

Controller #@PSBoundParameters


<#
Running Notes
1. Will Create a RunTime ScriptMethod to cover all the group validations
2. $sb - for all template of the scriptMethod
3. Scriptmethod do not have access to non-static member of the class Need to explore more on this

4. 2 Enums created 
   a) ValidationFunctions- for addition of new valdiations please add an entry to this enum after adding the 
       class method 
   b) ListofGroupValdations - List of Group Validation to be done , add entry here and also make an entry in the 
      Yaml file which will be loaded when we  first create the object

5. The current Code is not thread safe , need to implement RS.

#>



