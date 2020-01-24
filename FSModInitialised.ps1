#will create this either in form of module or in form of an exe 

param (
  # add all parameters here when calling this module directly
)


function preFileMigrationController{
    # Parameter help description
    param(

    [Parameter(Mandatory=$true)]
    [string]
    $folderPath,
    # Parameter help description
    [Parameter(Mandatory=$true)]
    [ParameterType]
    $groupCount,

    [Parameter(Mandatory=$true)]
    [string]
    $extension,

    [Parameter(Mandatory=$false)]
    [string]
    $namingConvention
    )
    <#what it does
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
}


