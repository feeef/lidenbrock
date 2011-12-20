//
//  NSManagedObject+Lidenbrock.m
//  Lidenbrock
//
//  Created by feeef on 08/04/11.
//  Copyright 2011 Six Degrees. All rights reserved.
//

#import "NSManagedObject+Lidenbrock.h"


@implementation NSManagedObject (Lidenbrock)


/***********************************************************************************************************
 */
+ (void) setSyncIdAs : (NSString *) syncId
{
    NSString *className = [LBObjectManager getClassNameFromClass: self];
    
    [LBObjectManager setSyncIdAs : syncId 
                  forClassName : className];
}

/***********************************************************************************************************
 */
+ (void) setDateFormat : (NSString *) format
{
    NSString *className = [LBObjectManager getClassNameFromClass: self];
    
    [LBObjectManager setDateFormat : format
                      forClassName : className];
}

/***********************************************************************************************************
 */
+ (void) setTimeZone : (NSTimeZone *) timeZone
{
    NSString *className = [LBObjectManager getClassNameFromClass: self];
    
    [LBObjectManager setTimeZone : timeZone
                    forClassName : className];
}

/***********************************************************************************************************
 */
+ (void) setMapping : (NSDictionary *) mapping
{
    NSString *className = [LBObjectManager getClassNameFromClass: self];
    
    [LBObjectManager setMapping : mapping
                   forClassName : className];
}

/***********************************************************************************************************
 */
+ (id) newEntity
{
    // Get context
    //
    NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
    
	return [NSEntityDescription insertNewObjectForEntityForName: [LBObjectManager getClassNameFromClass: self] 
                                         inManagedObjectContext: context];
}

/***********************************************************************************************************
 */
+ (id) entityWithId : (NSString *) newId
{    
    id entity = nil;
    
    // Make sure the model has the syncId property.
    // Otherwise, instanciate a new entity.
    //
    BOOL isSyncable = (class_getProperty(self, [@"syncID" UTF8String]) != NULL);
    
    if ([LBObjectManager isString: newId] && isSyncable) {
        NSArray *result = [self fetch: @"syncID == %@", newId];
        if (result != nil && result.count > 0) {
            entity = [result objectAtIndex: 0];
        }
        else {
            entity = [self newEntity];
            [entity setValue: newId 
                      forKey: @"syncID"];
            NSLog(@"OHData : Insert new %@ with syncID = \"%@\"", [LBObjectManager getClassNameFromClass: self], newId);
        }
        
        return entity;
    }
    else {
        
        return [self newEntity];
    }
}

/***********************************************************************************************************
 */
+ (id) entityFromJson : (NSString *) json
{
    NSString *entityName = [LBObjectManager getClassNameFromClass: self];
    
    return [LBObjectManager objectWithClassName: entityName 
                                 fromDictionary: [json mutableObjectFromJSONString]];
}

/***********************************************************************************************************
 */
+ (NSArray *) fetch : (NSString *) format, ...
{
    // TODO : make an easy way to pass the folloing information to the fetch method :
    //
    //          includes subentities
    //
    //          limit
    //          offset
    //          batch size
    //          affetced stores
    //          relashionship key path
    
    //          result type
    //          includes pending changes
    //          properties to fetch
    //          distinct results
    //          includes property values
    //          returnsObjectsAsFaults
    
    
    ///////////////////////////////////////////////////////////
    // Get context and init Request
    //
    NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
    
    NSString *entityName = [LBObjectManager getClassNameFromClass: self];
     
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: context];
    [fetchRequest setEntity: entity];
    [fetchRequest setIncludesSubentities: YES];
    [fetchRequest setIncludesPropertyValues: YES];
    [fetchRequest setReturnsDistinctResults: YES];
    

    
    ///////////////////////////////////////////////////////////
    // Extract Sorting order from the format
    //
    __block NSRange sortMatchRange;
    __block NSString *sortKey   = nil;
    __block BOOL sortAscending  = YES;
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"ORDER BY ([\\w\\.]*)(\\sDESC|\\sASC)?"
                                                                           options: NSRegularExpressionCaseInsensitive
                                                                             error: &error];
    
    [regex enumerateMatchesInString: format 
                            options: 0 
                              range: NSMakeRange(0, [format length]) 
                         usingBlock: ^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                             
                             sortMatchRange = [match range];
                             NSRange capture1Range  = [match rangeAtIndex: 1];
                             NSRange capture2Range  = [match rangeAtIndex: 2];
                             
                             if (capture1Range.length > 0) {
                                 sortKey = [format substringWithRange: capture1Range];
                             }
                             
                             if (capture2Range.length > 0) {
                                 NSString *direction    = [format substringWithRange: capture2Range];
                                 if ([direction isEqualToString: @"DESC"]) {
                                     sortAscending = NO;
                                 }
                             }
                         }];
    
    if (sortMatchRange.location != NSNotFound) {
        format = [format stringByReplacingCharactersInRange: sortMatchRange 
                                                 withString: @""];
    }

    
    
    ///////////////////////////////////////////////////////////
    // Set Predicate
    //
    format = [format stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // If the format is represented by '*' it means we want to list all elements.
    // We don't set the predicate for that purpose
    //
    if ([format isEqualToString: @"*"]) {
        NSLog(@"OHData : Fetch from %@ : All", entity.name);
    }
    else {
        va_list args;
        va_start(args, format);
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat: format 
                                                        arguments: args];
        va_end(args);
        
        [fetchRequest setPredicate: predicate];

        NSLog(@"OHData : Fetch from %@ : %@", entity.name, [predicate predicateFormat]);
    }
    
    
    
    ///////////////////////////////////////////////////////////
    // Set Sort Descriptor
    //
    if (sortKey != nil) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: sortKey 
                                                                         ascending: sortAscending];
        
        [fetchRequest setSortDescriptors: [NSArray arrayWithObject: sortDescriptor]];
        
        NSString *sortDirection = @"ASC";
        if (!sortAscending) {
            sortDirection = @"DESC";
        }
        NSLog(@"OHData :            ORDER BY %@ %@", sortKey, sortDirection);
    }

    
    ///////////////////////////////////////////////////////////
    // Run fetch request
    //
    NSArray *array = [context executeFetchRequest: fetchRequest 
                                            error: &error];
    
    [fetchRequest release];
    
    return array;
}


/***********************************************************************************************************
 */
+ (NSArray *) entitiesFromJson : (NSString *) json
{
    // If the JSON data represents an NSArray, the list is processed
    // otherwise, an empty array is returned.
    //
    id plist = [json mutableObjectFromJSONString];
    
    if ([LBObjectManager isArray: plist]) {
        return [self entitiesFromPlist: [json mutableObjectFromJSONString]];
    }
    else {
        return [NSArray array];
    }
	
}

/***********************************************************************************************************
 */
+ (NSArray *) entitiesFromPlist : (NSArray *) array {
	
    // If the Array is valid, the list is processed
    // otherwise, an empty array is returned.
    //
    if ([LBObjectManager isArray: array]) {
        return [LBObjectManager objectsWithClassName: [LBObjectManager getClassNameFromClass: self] 
                                           fromArray: array];
    }
    else {
        return [NSArray array];
    }
	
}

/***********************************************************************************************************
 */
- (void) loadFromJson : (NSString *) json
{
    // TODO : Make sure it is a dictionary
    //
	[self loadFromDictionary: [json mutableObjectFromJSONString]];
}

/***********************************************************************************************************
 */
- (void) loadFromDictionary : (NSDictionary *) dictionary
{		
	if (dictionary != nil)
	{	
        NSString *className     = [LBObjectManager getClassNameFromClass: [self class]];
        NSString *customSyncId  = [LBObjectManager syncIdForClassName: className];
        NSDictionary *mapping   = [LBObjectManager mappingForClassName: className];

		NSArray *keys = [dictionary allKeys];
		
		NSString *key; 
		id value;
		int i;
        
		// Read each key/value pairs from the dictionary and set
		// the properties of the current object with them
		//
		for (i = 0; i < [keys count]; i++)
		{
            BOOL shouldUpdate = YES;
            
			// Load property
			//
			key		= (NSString *)[keys objectAtIndex: i];
			value	= [dictionary objectForKey: key];
            
            if (mapping != nil) {
                id mapKey = [mapping objectForKey: key];
                if (mapKey != nil) {
                    key = mapKey;
                }
            }
            
            
            
            
            if (customSyncId != nil && [key isEqualToString: customSyncId]) 
            {
                key = @"syncID";
            }
            else if ([key isEqualToString: @"id"] || [key isEqualToString: @"_id"]) 
            {
                key = @"syncID";
            }
            
			if ([LBObjectManager isDictionary: value]) {
				// Parse dictionary
				//
                NSString *className = [self getClassNameForKey: key];
                if (className != nil) {
                    value = [LBObjectManager objectWithClassName: [self getClassNameForKey: key] 
                                                  fromDictionary: value];
                }
			}
			else if ([LBObjectManager isArray: value])  {

                NSDictionary *relations = [[self entity] relationshipsByName];
                NSRelationshipDescription *rel = [relations objectForKey: key];
                
                if (rel) {
                    NSString *subClassName  = [[rel destinationEntity] managedObjectClassName];
                    
                    NSArray *array = [LBObjectManager objectsWithClassName: subClassName 
                                                                 fromArray: value];
                    
                    
                    NSEnumerator* enumerator = [array objectEnumerator];
                    id model;
                    while ((model = [enumerator nextObject])) 
                    {
                        NSSet *changedObjects = [[NSSet alloc] initWithObjects:&model count:1];
                        [self willChangeValueForKey: key 
                                    withSetMutation: NSKeyValueUnionSetMutation 
                                       usingObjects: changedObjects];
                        
                        [[self primitiveValueForKey: key] addObject: model];
                        
                        [self didChangeValueForKey: key 
                                   withSetMutation: NSKeyValueUnionSetMutation 
                                      usingObjects: changedObjects];
                        [changedObjects release];
                    }                    
                }
                
                shouldUpdate = NO;
			}
			
			// Set property
			//
            if (shouldUpdate && [LBObjectManager object: self 
                                            hasProperty: key]) {
                
                NSAttributeDescription *prop = (NSAttributeDescription *)[[[self entity] propertiesByName] objectForKey: key];
                
                if ([prop attributeType] == NSDateAttributeType) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    
                    // Set Format
                    //
                    NSString *dateFormat    = [LBObjectManager dateFormatForClassName: className];
                    if (dateFormat == nil) {
                        dateFormat = @"yyyy-MM-dd HH:mm:ss";
                    }
                    NSLog(@"OHData : Using date format on %@ : %@", className, dateFormat);
                    [formatter setDateFormat: dateFormat];
                    
                    // Set timezone
                    //
                    NSTimeZone *timeZone = [LBObjectManager timeZoneForClassName: className];
                    if (timeZone != nil) {
                        [formatter setTimeZone: timeZone];
                        NSLog(@"OHData : Using time zone on %@ : %@", className, [timeZone name]);
                    }
                    
                    NSDate *dateFromString = [formatter dateFromString: value];
                    
                    [formatter release];
                    
                    [self setValue: dateFromString 
                            forKey: key];
                }
                else {
                    [self setValue: value 
                            forKey: key];
                }
            }
		}
	}
}


/***********************************************************************************************************
 */
- (NSDictionary *) toDictionary : (NSString *) parentName
{	
    NSString *className = [LBObjectManager getClassNameFromClass: [self class]];
    
	// Load real object properties
	//
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary: [LBObjectManager propertiesFromObject: self]];
    
    
    // remove any backward relationship
    //
    if (parentName != nil) {
        
        NSArray *props = [[self entity] properties];

        
		NSEnumerator* enumerator = [props objectEnumerator];
		id value;
		while ((value = [enumerator nextObject])) 
		{            
            if ([value isKindOfClass: [NSRelationshipDescription class]]) {
                
                if ([[[value destinationEntity] name] isEqualToString: parentName]) {
                    [attributes removeObjectForKey: [value name]];
                }
            }
        }
    }


    
	return [LBObjectManager plistFromDictionary: attributes 
                                 withEntityName: className];
}


/***********************************************************************************************************
 */
- (NSString *) toJson
{	    
	return [LBObjectManager jsonFromObject: self];
}


/***********************************************************************************************************
 */
- (BOOL) save 
{
    // Save the objects in the data store
    //
    return [NSManagedObjectContext saveDefaultContext];
}

/***********************************************************************************************************
 */
- (NSString *) getClassNameForKey : (NSString *) key
{
	// If the dictionary represents a property in this object, 
	// we make sure to load its class name and get the object
	// from the dictionary.
	//
	NSString *className = [LBObjectManager getClassNameFromProperty: key 
														   inObject: self];
	
	return className;
}

@end
