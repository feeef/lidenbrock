Description
===========

Lidenbrock is an add-on to Core Data. It is a solution to easily synchronize your Core Data models with some external JSON resources.


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


The following <b>jsonObject</b> variable :

{
"id"          : "REC1",
"name"        : "pancake",
"details"     : "In a large bowl, sift together the flour, egg, milk...",
"createdOn"   : "2011-08-26"
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

And the following <b>jsonArray</b> variable :

[
{"name" : "flour"},
{"name" : "egg"},
{"name" : "milk"}
]



### Load from JSON

In order to load a model from a JSON string, you can use the class method <b>entityFromJson</b> on any of your NSManagedObject class.

Recipe *recipe = [Recipe entityFromJson: jsonObject];

You may also use the instance method :

Recipe *recipe = [Recipe newEntity];
[recipe loadFromJson: jsonObject];

Loading is recursive so you can now access your ingredients through the <b>ingredients</b> attribute :

NSArray *ingredients = [recipe.ingredients allObjects];


You can also load an array of objects :

NSArray *ingredients = [Ingredient entitiesFromJson: jsonArray];


### Sync from JSON

The previous exemple creates a new entity for every single load.

If you want to retrieve and synchronise existing data, you need to add an attribute called <b>syncID</b> (NSString) to your model.
Lidenbrock will then look at any <b>id</b>, <b>_id</b> or <b>syncID</b> attribute in your JSON data and try to retreive an existing entity based on its value.
You can also specify a custom attribute, in your json data, to be your syncID :

[Recipe setSyncIdAs: @"myCustomAttribute"];

If no match can be made, a new entity is created.

The new model is as follow :

Recipe
----------------
syncID (NSString)
name (NSString)
details (NSString)
createdOn (NSDate)
------------
ingredients (NSSet)


Igredient
----------------
syncID (NSString)
name (NSString)
------------
recipes (NSSet)


<b>entityFromJson</b> will now sync existing data

Recipe *recipe = [Recipe entityFromJson: jsonObject];


### Mapping

If some of your JSON fields names don't match your models names, you can apply a specific mapping to you CoreData entity.

NSDictionary *mapping = [NSDictionary dictionaryWithObjectsAndKeys:
@"model_name", @"json_name", 
@"model_details", @"json_details", nil];

[Recipe setMapping: mapping];

The keys of your mapping dictionnary represent the JSON fields and the values represent the CoreData model fields.



### Working with dates

If a Core Data entity defines one or more attributes as NSDate, you will have to specify the format used to load the NSDate object from the JSON string. If none is specified, the following is used by default : 'yyyy-MM-dd HH:mm:ss'

[Recipe setDateFormat: @"yyyy-MM-dd"];


You can also specify a time zone to be used on each date on your object. If none is specified, no time zone is set to the date formatter.

NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation: @"UTC"];
[Recipe setTimeZone: timeZone];



### Serialize to JSON

You can serialize your Core Data models into JSON by calling the method <b>toJson</b> on your instance.

NSString *jsonString = [recipe toJson];



### Save

You may save your data by calling the <b>save</b> method on your NSManagedObject instance. This is in fact a shortcut that performs a save on the context, saving any other unsaved data.

[recipe save];

You can also perform a save directly on the context.

[[NSManagedObjectContext defaultContext] saveDefaultContext];



### Fetch

You can fetch an entity directly from its id (matching syncID). 
If no match can be found, a new entity is created and returned with the new id set as syncID.

Recipe *recipe = [Recipe entityWithId: @"REC1"];



You can also easily fetch entities from a predicate format.    

NSString *ingredientName = @"egg";
NSArray *recipes = [Recipe fetch: @"ANY ingredients.name == %@", ingredientName];



### Fetch & sort

You can sort your fetched data by adding a "ORDER BY" statement at the end of your predicate format.

NSArray *recipes = [Recipe fetch: @"ANY ingredients.name == %@ ORDER BY name DESC", ingredientName];

<b>IMPORTANT NOTE : </b> You should not use any "%@" variables in your "ORDER BY" statement as the fetch method extracts this statment out of the rest of the format and only apply variables to the real predicate format, as defined by Apple.


What's coming next ?
==============

Lidenbrock is at an early stage of development so a lot of important features are still missing. They should be available in future releases.

* Ability to use more than one Context
* Add a "Limit" statmament to the fetch method
* Delete data
* Load from URL
* Send to URL

Stay tuned!


