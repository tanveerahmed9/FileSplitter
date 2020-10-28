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

# this will be updated when 
enum ListofValdations{
    _ValidateUnderscore = 1
    _assignIndividualIdentifier = 2
}

#region Class
Class FileValidator{
   
    #region class property
    static [string]$yamlPath;
    static [System.Collections.Hashtable]$yamlContent;
    static [string]$sourcePath;
    static [string]$destinationPath
    [string]$filename;
    static [string]$failedFolderpath;
    static $validateCount = 9;
    static [string]$commonLogs;
    static $collectiontoMatchgainst;
    [string] $validationResult;
    [System.Management.Automation.PSCustomObject] $fileCustomObject; # to store the current file separated data
    
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

    hidden _writeFilelog($method){
        $message = "Failed the Validaton - $method for File $($this.FileName)"
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
                    $this._writeFilelog("ValidateUnderScore")
                    $this._movetofailedValidationFolder()
                }
                else{
                    $this.validationResult = "SUCCESS"
                }
                }
            catch{

            }
            
        }

    hidden _loadconfig(){
        write-host $PSScriptRoot
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

        }
    }

    hidden  _dateFormatValidation(){ # second release
           
    }

    hidden _GroupValidation([string]$toMatch){
            
                 if ($this.collectiontoMatchgainst -ccontains $toMatch)
                 {
                     $this.validationResult = "SUCCESS"
                 }
            
                 else{
                    $this.validationResult = "FAILED"
                    _writeFilelog
                    _movetofailedValidationFolder 
                    continue
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
            
    FileValidator($sourcePath,$destinationPath){ # Constructor to initialize and validate
       # initialise static variable source and destination path
        # assignment 
        [FileValidator]::sourcePath = $sourcePath
        [FileValidator]::destinationPath = $destinationPath
        #tasks
        $this._ValidatePath() # validates the internal member source and destination path
        $this._loadconfig() # loads the config data to be available to all the instances of the class
        $this._createFailedFolder() # creates the Failed folder 
    }

    validate($filename)
    { # main function to validate all the steps
      $this.filename = $filename
      foreach ($currentValidation in [ListofValdations].GetEnumNames()) {
        while ($this.validationResult -ne "FAILED") {
            $this.$currentValidation()
            } 
      }
      
    }    }

    

   #endregion
    

 function main{
    begin{
        # initialised once 
        $FileObject = [FileValidator]::new("C:\FStst", "C:\FStst") 
        
    }
    process{
        $FileObject.validationResult = "SUCCESS" # initial result assuming as success
        $FileObject.validate($_) # validate the File
    }
}

function Controller {
    process{
        $sourcePath = "C:\FStst" 
        $files = Get-ChildItem -Path $sourcePath -File
        $files.Name | main
    }
}


Controller
#endregion

<#
Running Notes



#>



