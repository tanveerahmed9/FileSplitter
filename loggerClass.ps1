# factory pattern to be followed for Logger , as we will have multiple logger (Excel,mysql,sql etc)
#abstract class for logger module
Class Logger { 

    [string] $logPath

    [void] WriteLog(){
      throw "Overwrite the parent block"
    }

Logger($logPath){
    $type = $this.GetType()
    if ($type -eq [Logger])
    {
        throw "Abstract class should not be instantiated"
    }
    else
    {
        Switch ($type.Name)
        {
            ExcelLogger{
                $this.logPath = $logPath
            }

            DB {
                $this.logPath = $logPath
            }

            Text {
                $this.logPath = $logPath
            }

        }

        $this.logPath = $logPath
    }
   }

}

Class ExcelLogger : Logger
{
    ExcelLogger($logPath) : base($logPath){

    }

    [Void] WriteLog(){
      
    }


}

Class DBLogger : Logger
{
    DBLogger($logPath): base($logPath){

    }

    [Void] WriteLog(){

    }

    [Void] DBConnection(){

    }
    
    

}

Class TextLogging : Logger 
{
   TextLogging($logPath) : base($logPath){ # always call the Parent Class for initialisation

   }
 

}

function LoggerMain {
    
    [ExcelLogger] $excelLogger = [ExcelLogger]::new("C:/Test")
}
LoggerMain