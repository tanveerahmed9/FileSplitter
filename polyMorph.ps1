
# class Foo
# {
#     [string] $SomePram

#     Foo([string]$somePram)
#     {
#         $this.SomePram = $somePram
#     }

#     [string] GetMessage()
#     {
#         return $null
#     }

#     [void] WriteMessage()
#     {
#         Write-Host($this.GetMessage())
#     }
# }

# class Bar : Foo
# {
#     Bar([string]$somePram): base($somePram)
#     {

#     }

#     [string] GetMessage()
#     {
#         return ("{0} Success" -f $this.SomePram)
#     }
# }

# class Bar2 : Foo
# {
#     Bar2([string]$somePram): base($somePram)
#     {

#     }

#     [string] GetMessage()
#     {
#         return ("{0} Success" -f $this.SomePram)
#     }
# }

# [Foo[]] $foos = @([Bar]::new("Bar"), [Bar2]::new("Bar2"))

# foreach($foo in $foos)
# {
#     $foo.WriteMessage()
# }

<# in the abobe example we see that the base class writemessage function implementation is redundant 
and therefore only the structure could have been enough for the base class to inherit and make its own 
defination
This is the concept of Abstract Classes
#>

#region Forced abstraction
class Foo
{
    Foo ()
    {
        $type = $this.GetType()

        if ($type -eq [Foo])
        {
            throw("Class $type must be inherited")
        }
    }

    [string] SayHello()
    {
        throw("Must Override Method")
    }
}

class Bar : Foo
{
    Bar ()
    {

    }

    [string] SayHello()
    {
        return "Hello"
    }
}

#$foo = [Foo]::new() # this should throw

$bar = [bar]::new()
$bar.SayHello()

#endregion


#region Demonstration of singleton design pattern
<#
Singleton design pattern has the main purpose of having a a single class instance in the memory , 
even if we create multiple instantiation of the class see example below

generally to restrict direct access for creating new Object we declare the constrcutor as private.
in PS we do not have that (till version 7.1 at the time of writing this 11-1-2020) , we use little trick to 
emulate the above behaviour
see the attached code to understand more
#>

Class SingleTonExample{
   static [string] $someParam
    static [SingleTonExample] $instance 
    static [singletonExample] getInstance(){  # the static method to access the new instance creation which makes all the instance equal to each other
        if ($null -eq [SingleTonExample]::instance){ # for first time initialisation
            [SingleTonExample]::instance = [SingleTonExample]::new() # instantiate the class
        }
        return [SingleTonExample]::instance # otherwise just return the existing object
    }
}

$s1 = [SingleTonExample]::new()
$s1.someParam = "Global Data"

$s2 = [SingleTonExample]::new()
$s2.someParam
#endregion

#region Fatcory Pattern demonstration
<#
fatcory pattern is the one of the most widely used design pattern in all of the developments
It is a creational design pattern that provdes interface for creating objects in the super class, 
but allows the sub-class to akter the type of the objects that will be created

Example-- Road Logistic --> LOGISTICS <--- Sea logistics

Lets say we have a road logistics application , We code everything into road logistics say for function truck movemement
However when we want to add a new type of logistics ,lets say ship logistics, in that scenario the case base again needs to be rede-
-loped and changes in acoordance with the functionality of the Ship logistics , this could be avoided if we folow
factory design pattern 

Factory method helps in separating product construction code from the code that actually uses the product
see example below for various types of drnks 
#>
# produdct construction class here we will explicitly design to make it an abstract class
Class Drink {
    [string] $Name
    [int32] $caffeine

    Drink([string]$Name, [int32]$caffeine) # default Constructor
    {
        $type = $this.GetType() # fetch the instantiated object to check whether it is called through its owne instance
        if ($type -eq [Drink])
        {
            throw "Abstract class cannot be instantiated"
        }
        else{ 
            $this.Name = $Name
            $this.caffeine = $caffeine
        }
    }

    [string] Open()
    {
            Throw "must overrride this"
    }

}

# SODA implements Drink
Class SODA : Drink{
    SODA ([string] $Name, [int32] $caffeine ) : base ($Name, $caffeine){ # initialise data through base class consttructor

    }

    [string] Open()
    {
        return "Opned a SODA box {0}" -f $this.Name
    }

}

# Energt drink Implements Drink
Class EnergyDrink : Drink {
    EnergyDrink ([string] $Name, [int32] $caffeine ) : base ($Name, $caffeine){ 
    }
    [String] Open()
    {
        return "Opened and energy drink {0}" -f $this.Name
    }
}


# factory method to control the instantaitaion
Class Drinkfactory{
    # store and fetch the Object
    static [Drink[]] $drinks

    static [Object] getByType([Object] $o) # getts the Object with the Type
    {
        return [Drinkfactory]::drinks.Where({$_ -is $o})
    } 

    static [Object] getByName([Object] $o) # getts the Object with the Type
    {
        return [Drinkfactory]::drinks.Where({$_.Name -is $o})
    } 

    # create the instance

    [Drink] CreateNewInstance([String] $Name, [String] $caffeine , [String] $type)
    {
        return (new-object -TypeName "$type" -ArgumentList $name,$caffeine)
    }
}


  function Main(){
  [Drinkfactory] $drinkfactory = [Drinkfactory]::new() # instantiation the factory class
  [Drink] $beverage1 = $drinkfactory.CreateNewInstance("RedBull", "100", "EnergyDrink")  
  [Drink] $beverage2 = $drinkfactory.CreateNewInstance("Monster", "200", "EnergyDrink")  
  [Drink] $beverage3 = $drinkfactory.CreateNewInstance("LemonSODA", "150", "SODA") 
  $beverage1.Open()
  $beverage2.Open()
  $beverage3.open()
  # using static members to set/fetch Object
  


}
Main








#endregion