//
//  LBObjectManager.h
//  Lidenbrock
//
//  Created by feeef on 02/02/11.
//  Copyright 2011 Six Degrees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "JSONKit.h"

@interface LBObjectManager : NSObject 
{

}

#pragma mark -
#pragma mark Utils

+ (NSString *) evalPattern : (NSString *) pattern 
				withObject : (id) object 
					 error : (NSError **) error;

+ (NSString *) getClassNameFromClass : (id) object;


#pragma mark -
#pragma mark  Handle Properties

+ (void) setSyncIdAs : (NSString *) syncId 
      forClassName : (NSString *) className;

+ (NSString *) syncIdForClassName : (NSString *) className;

+ (void) setDateFormat : (NSString *) format 
          forClassName : (NSString *) className;

+ (NSString *) dateFormatForClassName : (NSString *) className;


+ (void) setTimeZone : (NSTimeZone *) timeZone 
        forClassName : (NSString *) className;

+ (NSTimeZone *) timeZoneForClassName : (NSString *) className;


+ (void) setMapping : (NSDictionary *) mapping 
       forClassName : (NSString *) className;

+ (NSDictionary *) mappingForClassName : (NSString *) className;

+ (NSDictionary *) inverseMappingForClassName : (NSString *) className;



+ (NSString *) getValueFromProperty : (NSString *) propertyName 
						   inObject : (id) object 
							  error : (NSError **) error;

+ (NSString *) getClassNameFromProperty : (NSString *) propertyName 
							   inObject : (id) object;

+ (BOOL) object : (id) object 
	hasProperty : (NSString *) propertyName;

+ (NSDictionary *) propertiesFromObject : (id) object;



#pragma mark -
#pragma mark  Data Type

+ (BOOL) isDictionary : (id) object;

+ (BOOL) isArray : (id) object;

+ (BOOL) isSet : (id) object;

+ (BOOL) isString : (id) object;

+ (BOOL) isDate : (id) object;

+ (BOOL) isNumber : (id) object;

+ (BOOL) isModel : (id) object;



#pragma mark -
#pragma mark Handle Serialization

+ (NSData *) dataFromObject : (id) object;

+ (NSString *) jsonFromObject : (id) object;

+ (NSString *) plistFromString : (NSString *) string;

+ (NSNumber *) plistFromNumber : (NSNumber *) number;

+ (NSDate *) plistFromDate : (NSDate *) date;

+ (NSString *) stringFromDate : (NSDate *) date 
                   withFormat : (NSString *) format 
                  andTimeZone : (NSTimeZone *) timeZone;

+ (NSDictionary *) plistFromDictionary : (NSDictionary *) dictionary 
                        withEntityName : (NSString *) entityName;

+ (NSArray *) plistFromArray : (NSArray *) array 
              withParentName : (NSString *) parentName;

+ (NSDictionary *) plistFromModel : (id) model;

+ (NSDictionary *) plistFromModel : (id) model 
                   withParentName : (NSString *) parentName;



#pragma mark -
#pragma mark Handle Deserialization

+ (NSArray *) objectsWithClassName : (NSString *) className 
						  fromJson : (NSString *) json;

+ (NSArray *) objectsWithClassName : (NSString *) className 
						 fromArray : (NSArray *) array;

+ (id) objectWithClassName : (NSString *) className 
			fromDictionary : (NSDictionary *) dictionary;




@end
