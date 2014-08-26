//
//  NSString+Inflections.m
//  JSON Model Maker
//
//  Created by Tim Lenton on 22/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import "NSString+Inflections.h"

@implementation NSString (Inflections)

- (NSString *)underscore
{
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;
	
    NSCharacterSet *uppercase = [NSCharacterSet uppercaseLetterCharacterSet];
    NSCharacterSet *lowercase = [NSCharacterSet lowercaseLetterCharacterSet];
	
    NSString *buffer = nil;
    NSMutableString *output = [NSMutableString string];
	
    while (scanner.isAtEnd == NO) {
		
        if ([scanner scanCharactersFromSet:uppercase intoString:&buffer]) {
            [output appendString:[buffer lowercaseString]];
        }
		
        if ([scanner scanCharactersFromSet:lowercase intoString:&buffer]) {
            [output appendString:buffer];
            if (!scanner.isAtEnd)
                [output appendString:@"_"];
        }
    }
    
    return [NSString stringWithString:output];
}

- (NSString *)camelcase
{
    NSString *input = [self stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    NSArray *components = [input componentsSeparatedByString:@"_"];
    NSMutableString *output = [NSMutableString string];
	
    for (NSUInteger i = 0; i < components.count; i++) {
        if (i == 0) {
            [output appendString:components[i]];
        } else {
            [output appendString:[components[i] capitalizedString]];
        }
    }
	
    return [NSString stringWithString:output];
}

- (NSString *)classify
{
	if (self.length < 1 || [self isEqualToString:@""]) {
		return @"";
	}
    NSString *camelcase = [self camelcase];
    return [camelcase stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[camelcase substringWithRange:NSMakeRange(0, 1)] uppercaseString]];
}

@end