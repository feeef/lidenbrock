//
//  NSManagedObject+Lidenbrock.h
//  Lidenbrock
//
//  Created by feeef on 08/04/11.
//  Copyright 2011 Six Degrees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "NSManagedObjectContext+Lidenbrock.h"
#import "LBObjectManager.h"
#import "JSONKit.h"


@interface NSManagedObject (Lidenbrock)

+ (void) setSyncIdAs : (NSString *) syncId;

+ (void) setDateFormat : (NSString *) format;

+ (void) setTimeZone : (NSTimeZone *) timeZone;



+ (id) newEntity;

+ (id) entityWithId : (NSString *) newId;

+ (id) entityFromJson : (NSString *) json;



+ (NSArray *) fetch : (NSString *) format, ...;



+ (NSArray *) entitiesFromJson : (NSString *) json;

+ (NSArray *) entitiesFromPlist : (NSArray *) array;

- (void) loadFromJson : (NSString *) json;

- (void) loadFromDictionary : (NSDictionary *) dictionary;



- (NSDictionary *) toDictionary;



- (BOOL) save;



- (NSString *) getClassNameForKey : (NSString *) key;

@end
