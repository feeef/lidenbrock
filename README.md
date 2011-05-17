Description
===========

Lidenbrock is an add-on to Core Data. It is a solution to easily synchronize your Core Data application with some external JSON resources.


Features
==============

* Load new models and synchronize existing ones from a JSON string
* Fetch your data with a single line of code
* Sort your result directly from the predicate format (the SQL way)


Installation
=======

1. git clone git@github.com:sixdegrees/lidenbrock.git
2. Import Lidenbrock.framework to your XCode project
3. Add -ObjC and -all_load to Other Link Flags in your project
4. You can now import the framework within your code :

#### Code
    #import <Lidenbrock/Lidenbrock.h>


Using Lidenbrock
========

Lidenbrock only uses one Managed Object Context defined (by default when you create a Core Data project) as [YourAppDelegate managedObjectContext], so make sure this is your Context.


Let's assume the following DB Model (as your .xcdatamodel). All Models are generated as NSManagedObject classes in your source code :

    Recipe
    ----------------
        name
        details
        ------------
        ingredients


    Igredient
    ----------------
        name
        ------------
        recipe


### Loading from JSON

In order to load a model from a JSON string, you can use the class method 'entityFromJson' on any NSManagedObject.

    Recipe *recipe = [Recipe entityFromJson: jsonString];

jsonString represents the folowing :

    {
        "name"        : "my recipe",
        "details"     : "the details of the recipe",
        "ingredients" : [
            {"name" : "my first ingredient"},
            {"name" : "my second ingredient"}
        ]
    }


