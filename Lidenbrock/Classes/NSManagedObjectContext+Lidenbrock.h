//
//  NSManagedObjectContext+Lidenbrock.h
//  Lidenbrock
//
//  Created by feeef on 11/04/11.
//  Copyright 2011 Six Degrees. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LBObjectManager.h"

@interface NSManagedObjectContext (Lidenbrock)

+ (NSManagedObjectContext *) defaultContext;

+ (BOOL) saveDefaultContext;

@end
