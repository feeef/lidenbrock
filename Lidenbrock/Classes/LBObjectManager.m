//
//  LBObjectManager.m
//  Lidenbrock
//
//  Created by feeef on 02/02/11.
//  Copyright 2011 Six Degrees. All rights reserved.
//

#import "LBObjectManager.h"

@implementation LBObjectManager

static NSMutableDictionary* syncIDs             = nil;
static NSMutableDictionary* dateFormats         = nil;
static NSMutableDictionary* timeZones           = nil;
static NSMutableDictionary* mappings            = nil;
static NSMutableDictionary* inverseMappings     = nil;

const char *kInitSelectorName       = "entityWithId:";
const char *kSerializeSelectorName	= "toDictionary:";
const char *kLoadSelectorName		= "loadFromDictionary:";

/*
 -----------------------------------------------------------------------------------------------------------------------------
 Utils
 -----------------------------------------------------------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark Utils

/***********************************************************************************************************
 */
+ (NSString *) evalPattern : (NSString *) pattern 
				withObject : (id) object 
					 error : (NSError **) error
{	
	
	__block NSString *processed	= [NSString stringWithString: pattern];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"#\\{([^\\{]+)\\}"
                                                                           options: NSRegularExpressionCaseInsensitive
                                                                             error: error];
    
    [regex enumerateMatchesInString: pattern 
                            options: 0 
                              range: NSMakeRange(0, [pattern length]) 
                         usingBlock: ^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                             
                             NSRange matchRange = [match range];
                             NSRange captureRange = [match rangeAtIndex:1];                             
                             
                             NSString *valueString      = @"";
                             NSString *matchString      = [pattern substringWithRange: matchRange];
                             NSString *capturedString   = [pattern substringWithRange: captureRange];
                             
                             NSError *sysError = nil;
                             
                             // Get value from property
                             //
                             id propertyValue = [LBObjectManager getValueFromProperty: capturedString
                                                                             inObject: object 
                                                                                error: &sysError];
                             
                             // Handle error
                             //
                             if (sysError != nil) {
                                 NSString *errorDescription = [NSString stringWithFormat: 
                                                               @"Pattern eval failure processing key #{%@}\n    - pattern : \"%@\"\n\n%@", 
                                                               capturedString, 
                                                               pattern, 
                                                               [sysError localizedDescription]];
                                 
                                 *error = [NSError errorWithDomain: @"OHSystemError" 
                                                              code: 2 
                                                          userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                     errorDescription, NSLocalizedDescriptionKey, nil]];
                             }
                             
                             // Process value
                             //
                             if ([LBObjectManager isString: propertyValue]) {
                                 valueString = (NSString *)propertyValue;
                             }
                             else if ([LBObjectManager isNumber: propertyValue]) {
                                 valueString = [(NSNumber *)propertyValue stringValue];
                             }
                             else {
                                 valueString = [LBObjectManager getClassNameFromClass: propertyValue];
                             }
                             
                             processed = [processed stringByReplacingOccurrencesOfString: matchString 
                                                                              withString: valueString];                             
                         }];
	
	
	return processed;
}

/***********************************************************************************************************
 */
+ (NSString *) getClassNameFromClass : (id) object
{	
	return [NSString stringWithCString:object_getClassName(object) encoding: NSUTF8StringEncoding];
}


/*
 -----------------------------------------------------------------------------------------------------------------------------
 Handle Properties
 -----------------------------------------------------------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark  Handle Properties

/***********************************************************************************************************
 */
+ (void) setSyncIdAs : (NSString *) syncId 
      forClassName : (NSString *) className
{
    if (nil == syncIDs) {
        syncIDs = [NSMutableDictionary dictionary];
    }
    
    [syncIDs setObject: syncId
                forKey: className];
}

/***********************************************************************************************************
 */
+ (NSString *) syncIdForClassName : (NSString *) className
{
    if (nil == syncIDs) {
        return nil;
    }
    else {
        return [syncIDs objectForKey: className];
    }
    
}

/***********************************************************************************************************
 */
+ (void) setDateFormat : (NSString *) format 
          forClassName : (NSString *) className
{
    if (nil == dateFormats) {
        dateFormats = [NSMutableDictionary dictionary];
    }
    
    [dateFormats setObject: format
                    forKey: className];
}

/***********************************************************************************************************
 */
+ (NSString *) dateFormatForClassName : (NSString *) className
{
    if (nil == dateFormats) {
        return nil;
    }
    else {
        return [dateFormats objectForKey: className];
    }
    
}

/***********************************************************************************************************
 */
+ (void) setTimeZone : (NSTimeZone *) timeZone 
        forClassName : (NSString *) className
{
    if (nil == timeZones) {
        timeZones = [NSMutableDictionary dictionary];
    }
    
    [timeZones setObject: timeZone
                  forKey: className];
}


/***********************************************************************************************************
 */
+ (NSTimeZone *) timeZoneForClassName : (NSString *) className
{
    if (nil == timeZones) {
        return nil;
    }
    else {
        return [timeZones objectForKey: className];
    }
}


/***********************************************************************************************************
 */
+ (void) setMapping : (NSDictionary *) mapping 
       forClassName : (NSString *) className
{
    if (nil == mappings) {
        mappings = [NSMutableDictionary dictionary];
    }
    
    [mappings setObject: mapping
                 forKey: className];
    
    // Generate inverse mapping for deserialization
    //
    NSMutableDictionary *inverseMapping = [NSMutableDictionary dictionary];
    NSArray *keys = [mapping allKeys];
    id key; 
    id value;
    int i;
    for (i = 0; i < [keys count]; i++)
    {
        key = [keys objectAtIndex: i];
        value = [mapping objectForKey: key];
        
        [inverseMapping setObject: key 
                           forKey: value];
    }
    
    if (nil == inverseMappings) {
        inverseMappings = [NSMutableDictionary dictionary];
    }
    
    [inverseMappings setObject: inverseMapping
                        forKey: className];
}


/***********************************************************************************************************
 */
+ (NSDictionary *) mappingForClassName : (NSString *) className
{
    if (nil == mappings) {
        return nil;
    }
    else {
        return [mappings objectForKey: className];
    }
}

/***********************************************************************************************************
 */
+ (NSDictionary *) inverseMappingForClassName : (NSString *) className
{
    if (nil == inverseMappings) {
        return nil;
    }
    else {
        return [inverseMappings objectForKey: className];
    }
}

/***********************************************************************************************************
 This method can accept properties with the following format :
	property
	property.subProperty
	property[index]
 
 They can also be combined : property.subProperty[index].anotherProperty
 */
+ (NSString *) getValueFromProperty : (NSString *) propertyName 
						   inObject : (id) object 
							  error : (NSError **) error
{
	NSString *errorDescription = nil;
	
	id value = nil;
	if (object != nil) {
		
		// if there is a call to a sub property, we get to it
		//
		id parent = object;
		NSArray *elems = [propertyName componentsSeparatedByString: @"."];
		for(NSString *elem in elems)
		{
			@try {
                
                NSString *varName = nil;
                NSString *varKey = nil;
               
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^\\[]+)\\[\"?'?([^\\]\\\"\\']+)\"?'?\\]"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:error];
                
                NSUInteger numberOfMatches = [regex numberOfMatchesInString: elem
                                                                    options: 0
                                                                      range: NSMakeRange(0, [elem length])];
                if (numberOfMatches > 0) {
                    NSArray *matches = [regex matchesInString: elem
                                                      options: 0
                                                        range: NSMakeRange(0, [elem length])];
                    
                    NSTextCheckingResult *match = [matches objectAtIndex: 0];
                    
                    varName = [elem substringWithRange: [match rangeAtIndex:1]];
                    varKey = [elem substringWithRange: [match rangeAtIndex:2]];
                }
				
				if (varName == nil) {
					varName = elem;
				}
				
				value = [parent valueForKey: varName];
				
				if ([LBObjectManager isArray: value] && [LBObjectManager isString: varKey]) {
					NSNumberFormatter * format = [[NSNumberFormatter alloc] init];
					[format setNumberStyle:NSNumberFormatterDecimalStyle];					
					
					value = [(NSArray *)value objectAtIndex: [[format numberFromString: varKey] integerValue]];
					[format release];
				}
				
				if ([LBObjectManager isDictionary: value] && [LBObjectManager isString: varKey]) {
					
					value = [(NSDictionary *)value objectForKey: varKey];
				}
				
			}
			@catch (NSException * e) {
				value = nil;
			}
			
			if (value == nil) {
				if (elem != nil && parent != nil) {
					errorDescription = [NSString stringWithFormat:@"Cannot find property '%@' in '%@' object", elem, [LBObjectManager getClassNameFromClass: parent]];
				}
				else {
					errorDescription = [NSString stringWithFormat:@"Cannot find property '%@' in '%@' object", propertyName, [LBObjectManager getClassNameFromClass: object]];
				}
				break;
			}
			
			parent = value;
		}
	}
	else {
		errorDescription = @"Cannot get value from nil object";
	}
	
	
	if (errorDescription != nil) {
		*error = [NSError errorWithDomain: @"OHSystemError" 
									 code: 1 
								 userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
											errorDescription, NSLocalizedDescriptionKey, nil]];
	}
	
	return value;
}

/***********************************************************************************************************
 */
+ (NSString *) getClassNameFromProperty : (NSString *) propertyName 
							   inObject : (id) object
{	
	NSString *className = nil;
	
	objc_property_t property = class_getProperty([object class], [propertyName UTF8String]);
	
	if(property != NULL) 
	{
		NSString *propAttr	= [NSString stringWithCString: property_getAttributes(property) encoding: NSUTF8StringEncoding];
        
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"@\"([^\"]+)\""
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
        NSArray *matches = [regex matchesInString: propAttr
                                          options: 0
                                            range: NSMakeRange(0, [propAttr length])];
        
        NSTextCheckingResult *match = [matches objectAtIndex: 0];
        
        className = [propAttr substringWithRange: [match rangeAtIndex: 1]];
        
	};
	
	return className;
}

/***********************************************************************************************************
 */
+ (BOOL) object : (id) object 
	hasProperty : (NSString *) propertyName
{
	BOOL foundProperty = NO;
	if (object != nil) {
		foundProperty = class_getProperty([object class], [propertyName UTF8String]) != NULL;
	}
	return foundProperty;
}

/***********************************************************************************************************
 */
+ (NSDictionary *) propertiesFromObject : (id) object
{
	NSMutableDictionary *propDict = [NSMutableDictionary dictionary];
	
	if (object != nil) {
		unsigned int outCount, i;
		objc_property_t *properties = class_copyPropertyList([object class], &outCount);
		for(i = 0; i < outCount; i++) 
		{
			objc_property_t property = properties[i];
			const char *propName = property_getName(property);
			if(propName) 
			{			
				NSString *propertyName	= [NSString stringWithCString: propName encoding: NSUTF8StringEncoding];
				id propertyValue		= [object valueForKey: propertyName];
				
				if (propertyValue != nil) 
				{
					if ([LBObjectManager isModel: propertyValue])
					{
						propertyValue = objc_msgSend(propertyValue, sel_registerName(kSerializeSelectorName), nil);
					}
					
					[propDict setObject: propertyValue
								 forKey: propertyName];
				}
			}
		}
		free(properties);
	}
	
	return propDict;
}


/*
 -----------------------------------------------------------------------------------------------------------------------------
 Data Type
 -----------------------------------------------------------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark  Data Type


/***********************************************************************************************************
 */
+ (BOOL) isDictionary : (id) object
{
	return (object != nil && [object isKindOfClass: [NSDictionary class]]) ? YES : NO;
}

/***********************************************************************************************************
 */
+ (BOOL) isArray : (id) object
{
	return (object != nil && [object isKindOfClass: [NSArray class]]) ? YES : NO;
}

/***********************************************************************************************************
 */
+ (BOOL) isSet : (id) object
{
	return (object != nil && [object isKindOfClass: [NSSet class]]) ? YES : NO;
}

/***********************************************************************************************************
 */
+ (BOOL) isString : (id) object
{
	return (object != nil && [object isKindOfClass: [NSString class]]) ? YES : NO;
}

/***********************************************************************************************************
 */
+ (BOOL) isDate : (id) object
{
	return (object != nil && [object isKindOfClass: [NSDate class]]) ? YES : NO;
}

/***********************************************************************************************************
 */
+ (BOOL) isNumber : (id) object
{
	return (object != nil && [object isKindOfClass: [NSNumber class]]) ? YES : NO;
}

/***********************************************************************************************************
 */
+ (BOOL) isModel : (id) object
{
	if (object != nil) {
		BOOL isSerializable = class_getInstanceMethod([object class], sel_registerName(kSerializeSelectorName)) != NULL;
		BOOL isLoadable		= class_getInstanceMethod([object class], sel_registerName(kLoadSelectorName)) != NULL;
		
		return (isSerializable && isLoadable) ? YES : NO;
	}
	else {
		return NO;
	}
}



/*
 -----------------------------------------------------------------------------------------------------------------------------
 Handle Serialization
 -----------------------------------------------------------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark Handle Serialization

/***********************************************************************************************************
 */
+ (NSData *) dataFromObject : (id) object
{
	NSData *xmlData = nil;
	
	id plist = nil;
	
	if ([LBObjectManager isModel: object]) {
		plist = objc_msgSend(object, sel_registerName(kSerializeSelectorName), nil);
	}
	else {
		plist = object;
	}

	if (plist != nil) {
		NSString *errorString;
		
		xmlData = [NSPropertyListSerialization dataFromPropertyList: plist
															 format: NSPropertyListBinaryFormat_v1_0
												   errorDescription: &errorString];
		if (errorString != nil) {
			NSLog(errorString, nil);
			[errorString release];
		}
	}

	
	return xmlData;
}

/***********************************************************************************************************
 */
+ (NSString *) jsonFromObject : (id) object
{
	NSString *json              = nil;
	NSMutableDictionary *dict	= nil;
	
	if ([LBObjectManager isModel: object]) {
		dict = objc_msgSend(object, sel_registerName(kSerializeSelectorName), nil);
	}
	else if ([LBObjectManager isDictionary: object]) {
		dict = object;
	}
	
	if (dict != nil) {
		json = [dict JSONString];
	}
	
	return json;
}

/***********************************************************************************************************
 */
+ (NSString *) plistFromString : (NSString *) string
{
	if (string == nil) {
		return @"";
	}
	else {
		return string;
	}
}

/***********************************************************************************************************
 */
+ (NSNumber *) plistFromNumber : (NSNumber *) number
{
	if (number == nil) {
		return [NSNumber numberWithInt: 0];
	}
	else {
		return number;
	}
}

/***********************************************************************************************************
 */
+ (NSDate *) plistFromDate : (NSDate *) date
{
	if (date == nil) {
		return [NSDate date];
	}
	else {
		return date;
	}
}

/***********************************************************************************************************
 */
+ (NSString *) stringFromDate : (NSDate *) date 
                   withFormat : (NSString *) format 
                  andTimeZone : (NSTimeZone *) timeZone
{
	if (date == nil) {
		date = [NSDate date];
	}
    
    if (format == nil) {
        format = @"yyyy-MM-dd HH:mm:ss";
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat: format];
    
    if (timeZone != nil) {
        [formatter setTimeZone: timeZone];
    }
    
    NSString *dateString = [formatter stringFromDate: date];
    
    [formatter release];
    
    return dateString;
}


/***********************************************************************************************************
 */
+ (NSDictionary *) plistFromModel : (id) model
{
    return [LBObjectManager plistFromModel: model 
                            withParentName: nil];
}

/***********************************************************************************************************
 */
+ (NSDictionary *) plistFromModel : (id) model 
                   withParentName : (NSString *) parentName
{
	if ([LBObjectManager isModel: model]) {
		return objc_msgSend(model, sel_registerName(kSerializeSelectorName), parentName);
	}
	else {
		return nil;
	}
}

/***********************************************************************************************************
 */
+ (NSDictionary *) plistFromDictionary : (NSDictionary *) dictionary 
                        withEntityName : (NSString *) entityName
{
	if (dictionary == nil)
	{
		return [NSDictionary dictionary];
	}
	else
	{
        NSDictionary *mapping   = [LBObjectManager inverseMappingForClassName: entityName];
        
		NSMutableDictionary *plistObject = [NSMutableDictionary dictionary];
		
		NSArray *keys = [dictionary allKeys];
		
		id key; 
		id value;
		int i;
		for (i = 0; i < [keys count]; i++)
		{
			key = [keys objectAtIndex: i];
			value = [dictionary objectForKey: key];
            
            if (mapping != nil) {
                id mapKey = [mapping objectForKey: key];
                if (mapKey != nil) {
                    key = mapKey;
                }
            }
			
			
			if ([LBObjectManager isString: value]) {
				[plistObject setObject: [LBObjectManager plistFromString: value] 
								forKey: key];
				
			}
			else if ([LBObjectManager isNumber: value]) {
				[plistObject setObject: [LBObjectManager plistFromNumber: value] 
								forKey: key];
				
			}			
			else if ([LBObjectManager isDate: value]) {
                NSString *format = nil;
                NSTimeZone *timeZone = nil;
                if (entityName != nil) {
                    format = [LBObjectManager dateFormatForClassName: entityName];
                    timeZone = [LBObjectManager timeZoneForClassName: entityName];
                }
				[plistObject setObject: [LBObjectManager stringFromDate: value 
                                                             withFormat: format 
                                                            andTimeZone: timeZone]
								forKey: key];
				
			}
			else if ([LBObjectManager isDictionary: value]) {
				[plistObject setObject: [LBObjectManager plistFromDictionary: value 
                                                              withEntityName: nil] 
								forKey: key];
				
			}
			else if ([LBObjectManager isArray: value]) {
				[plistObject setObject: [LBObjectManager plistFromArray: value 
                                                         withParentName: entityName]
								forKey: key];
				
			}
            else if ([LBObjectManager isSet: value]) {
				[plistObject setObject: [LBObjectManager plistFromArray: [value allObjects] 
                                                         withParentName: entityName] 
								forKey: key];
				
			}
			else if ([LBObjectManager isModel: value]) {
				[plistObject setObject: [LBObjectManager plistFromModel: value] 
								forKey: key];
			}
			
		}
		
		return plistObject;
	}
}


/***********************************************************************************************************
 */
+ (NSArray *) plistFromArray : (NSArray *) array 
              withParentName : (NSString *) parentName
{
	if (array == nil)
	{
		return [NSArray array];
	}
	else
	{
		NSMutableArray *plistObject = [NSMutableArray array];
		
		NSEnumerator* enumerator = [array objectEnumerator];
		id value;
		while ((value = [enumerator nextObject])) 
		{
			if ([LBObjectManager isString: value]) {
				[plistObject addObject: [LBObjectManager plistFromString: value]];
				
			}
			else if ([LBObjectManager isNumber: value]) {
				[plistObject addObject: [LBObjectManager plistFromNumber: value]];
				
			}
			else if ([LBObjectManager isDate: value]) {
				[plistObject addObject: [LBObjectManager plistFromDate: value]];
				
			}			
			else if ([LBObjectManager isDictionary: value]) {
				[plistObject addObject: [LBObjectManager plistFromDictionary: value 
                                                              withEntityName: nil]];
				
			}
			else if ([LBObjectManager isArray: value]) {
				[plistObject addObject: [LBObjectManager plistFromArray: value 
                                                         withParentName: nil]];
				
			}
            else if ([LBObjectManager isSet: value]) {
				[plistObject addObject: [LBObjectManager plistFromArray: [value allObjects] 
                                                         withParentName: nil]];
				
			}
			else if ([LBObjectManager isModel: value]) {
				[plistObject addObject: [LBObjectManager plistFromModel: value 
                                                         withParentName: parentName]];
			}
		}
		
		return plistObject;
	}
}


/*
 -----------------------------------------------------------------------------------------------------------------------------
 Handle Deserialization
 -----------------------------------------------------------------------------------------------------------------------------
 */

#pragma mark -
#pragma mark Handle Deserialization

/***********************************************************************************************************
 */
+ (NSArray *) objectsWithClassName : (NSString *) className 
						  fromJson : (NSString *) json
{
	NSArray *objects = [NSArray array];
	
	// Convert json string into NSDictionary
	//
	id data = [json JSONString];
	
	
	if ([LBObjectManager isArray: data]) 
	{
		objects = [LBObjectManager objectsWithClassName: className 
											fromArray: (NSArray *)data];
	}
	
	return objects;
}

/***********************************************************************************************************
 */
+ (NSArray *) objectsWithClassName : (NSString *) className 
						 fromArray : (NSArray *) array
{
	NSMutableArray *objectInstance = nil;
	
	if (array != nil)
	{
		objectInstance = [NSMutableArray array];
		
		NSEnumerator* enumerator = [array objectEnumerator];
		id value;
		while ((value = [enumerator nextObject])) 
		{
			if ([LBObjectManager isDictionary: value])
			{
				[objectInstance addObject: [LBObjectManager objectWithClassName: className 
                                                                 fromDictionary: value]];
			}
			else if ([LBObjectManager isArray: value])
			{
				[objectInstance addObject: [LBObjectManager objectsWithClassName: nil 
                                                                       fromArray: value]];
			}
			else
			{
				[objectInstance addObject: value];
			}
		}
	}
	return objectInstance;
}

/***********************************************************************************************************
 */
+ (id) objectWithClassName : (NSString *) className 
			fromDictionary : (NSDictionary *) dictionary
{	
	id objectInstance = nil;
	
	if (dictionary != nil)
	{	
		// try to instanciate the model
		//
		Class objectClass = nil;
		
		if ([LBObjectManager isString: className]) {
			objectClass = NSClassFromString(className);
		}
		
		if (objectClass != nil) {
            
            // If the Class has a specific object selector, we use it
            // Otherwise, we use the default object instantiating process
            //
            if (class_getClassMethod(objectClass, sel_registerName(kInitSelectorName)) != NULL) {
                
                NSString *newId = nil;
                
                NSString *customSyncId = [LBObjectManager syncIdForClassName: className];
                
                if (customSyncId != nil) {
                    newId = [dictionary objectForKey: customSyncId];
                }
                if (newId == nil) {
                    newId = [dictionary objectForKey: @"_id"];
                }
                if (newId == nil) {
                    newId = [dictionary objectForKey: @"id"];
                }
                if (newId == nil) {
                    newId = [dictionary objectForKey: @"syncID"];
                }
                objectInstance = objc_msgSend(objectClass, sel_registerName(kInitSelectorName), newId);
            }
            else {
                objectInstance = [[[objectClass alloc] init] autorelease];
            }
        }
		
		if ([LBObjectManager isModel: objectInstance]) {
			objc_msgSend(objectInstance, sel_registerName(kLoadSelectorName), dictionary);
		}
		
		// Otherwise, parse the dictionnary data
		//
		else {
			objectInstance = [NSMutableDictionary dictionaryWithDictionary: dictionary];
			
			NSArray *keys = [dictionary allKeys];
			
			id key; 
			id value;
			int i;
			for (i = 0; i < [keys count]; i++)
			{
				key = [keys objectAtIndex: i];
				value = [dictionary objectForKey: key];
				
				if ([LBObjectManager isDictionary: value])
				{
					[objectInstance setObject: [LBObjectManager objectWithClassName: nil 
																   fromDictionary: value] 
									   forKey: key];
				}
				else if ([LBObjectManager isArray: value])
				{
					[objectInstance setObject: [LBObjectManager objectsWithClassName: nil 
																		 fromArray: value] 
									   forKey: key];
				}
			}
		}
	}
	
	return objectInstance;
}





@end
