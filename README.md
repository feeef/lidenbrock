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

Lidenbrock only uses one Managed Object Context defined (by default when you create a Core Data project) as <code>YourAppDelegate.managedObjectContext</code>, so make sure this is your Context.

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


### Load from JSON

In order to load a model from a JSON string, you can use the class method <b>entityFromJson</b> on any of your NSManagedObject class.

    Recipe *recipe = [Recipe entityFromJson: jsonString];

You may also use the instance method :
    
    Recipe *recipe = [Recipe newEntity];
    [recipe loadFromJson: jsonString];


jsonString representing the folowing :

    {
        "name"        : "pancake",
        "details"     : "In a large bowl, sift together the flour, egg, milk...",
        "ingredients" : [
            {"name" : "flour"},
            {"name" : "egg"},
            {"name" : "milk"}
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

Just call <b>entityFromJson</b>

    Recipe *recipe = [Recipe entityFromJson: jsonString];

With the following JSON string :

    {
        "id"          : "REC1",
        "name"        : "pancake",
        "details"     : "In a large bowl, sift together the flour, egg, milk...",
        "ingredients" : [
            {
                "id"   : "INGR1",
                "name" : "flour"
            },
            {
                "id"   : "INGR2",
                "name" : "egg"
            },
            {
                "id"   : "INGR3",
                "name" : "milk"
            }
        ]
    }


### Save

You may save your data by calling the <b>save</b> method on your NSManagedObject instance. This is in fact a shortcut that performs a save on the all context.

    [recipe save];

You can also perform a save directly on the context.

    [[NSManagedObjectContext defaultContext] saveDefaultContext];



### Fetch

You can fetch an entity directly from it id (matching syncID). In that case, if no match can be found, a new entity is created and returned with @"REC1" set as syncID.

    Recipe *recipe = [Recipe entityWithId: @"REC1"];


You can also easily fetch entities from a predicate format.    
    
    NSString *ingredientName = @"egg";
    NSArray *recipes = [Recipe fetch: @"ANY ingredients.name == %@", ingredientName];



### Fetch & sort

You can sort your fetched data by adding a "SORT BY" satement at the end of your predicate format.

<b>IMPORTANT NOTE : </b> You should not use any "%@" variables in your "SORT BY" satement as the fetch method extracts this statment out of the rest of the format and only apply variables to the real predicate format, as defined by Apple.

    NSArray *recipes = [Recipe fetch: @"ANY ingredients.name == %@ ORDER BY name DESC", ingredientName];




