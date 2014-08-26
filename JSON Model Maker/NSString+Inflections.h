//
//  NSString+Inflections.h
//  JSON Model Maker
//
//  Created by Tim Lenton on 22/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Inflections)

- (NSString *)underscore;
- (NSString *)camelcase;
- (NSString *)classify;

@end
