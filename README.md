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

    #import <Lidenbrock/Lidenbrock.h>


Using Lidenbrock
========

Lidenbrock only uses one Managed Object Context defined (by default when you create a Core Data project) as <b>[YourAppDelegate managedObjectContext]</b>, so make sure this is your Context.


### Load from JSON

Let's assume the following DB Model (as your .xcdatamodel). All Models are generated as NSManagedObject classes in your source code :

    Recipe
    ----------------
        name (NSString)
        details (NSString)
        ------------
        ingredients (NSSet)


    Igredient
    ----------------
        name (NSString)
        ------------
        recipes (NSSet)


In order to load a model from a JSON string, you can use the class method <b>entityFromJson</b> on any of your NSManagedObject class.

    Recipe *recipe = [Recipe entityFromJson: jsonString];

You may also use the instance method :
    
    Recipe *recipe = [Recipe newEntity];
    [recipe loadFromJson: jsonString];


jsonString representing the folowing :

    {
        "name"        : "my recipe",
        "details"     : "the details of the recipe",
        "ingredients" : [
            {"name" : "my first ingredient"},
            {"name" : "my second ingredient"}
        ]
    }

You may now access your ingredients through the <b>ingredients</b> attribute :

    NSArray *ingredients = [recipe.ingredients allObjects];


### Sync from JSON

The previous exemple creates a new entity, so if you save your context at this point, a new recipe will be added to your store.
If you want to retrieve and synchronise existing data, you need to add an attribute called <b>syncID</b> (NSString) to your model.
Lidenbrock will then look at any <b>id</b>, <b>_id</b> or <b>syncID</b> attribute in your JSON data and try to fetch any existing entity based on its value.
If no match can be made, a new entity is created.

    Recipe
    ----------------
        syncID (NSString)
        name (NSString)
        details (NSString)
        ------------
        ingredients (NSSet)


    Igredient
    ----------------
        syncID (NSString)
        name (NSString)
        ------------
        recipes (NSSet)

Just call <b>entityFromJson</b>. 

    Recipe *recipe = [Recipe entityFromJson: jsonString];

With the following JSON string :

    {
        "id"          : "REC1",
        "name"        : "my recipe",
        "details"     : "the details of the recipe",
        "ingredients" : [
            {
                "id"   : "INGR1",
                "name" : "my first ingredient"
            },
            {
                "id"   : "INGR2",
                "name" : "my second ingredient"
            }
        ]
    }

