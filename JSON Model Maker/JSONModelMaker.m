//
//  JSONModelMaker.m
//  JSON Model Maker
//
//  Created by Tim Lenton on 20/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import "JSONModelMaker.h"
#import "NSString+Inflections.h"

#define CLASS_NAME_KEY @"className"
#define CLASS_PROPERTIES_KEY @"classProperties"
#define DEFAULT_TYPE @"NSObject"
#define DEFAULT_TYPE_IS_PRIMITIVE NO

@interface JSONModelMaker ()
{
	NSMutableArray *_classArray;
	NSMutableArray *_protocolArray;
}
@end

@implementation JSONModelMaker

- (instancetype)initWithJSONData:(NSData *)jsonData
				   rootClassName:(NSString *)rootClass
                  rootSuperClass:(NSString *)rootSuperClass
					  superClass:(NSString *)superClass
        prefixClassNamesWithRoot:(BOOL)prefixClassNames
          hierarchicalClassNames:(BOOL)hierarchicalClassNames
{
	self = [super init];
	if (self) {
		self.jsonData = jsonData;
		self.rootClass = rootClass;
        self.rootSuperClass = rootSuperClass;
		self.superClass = superClass;
		if (!self.superClass || [self.superClass isEqualToString:@""]) {
			self.superClass = @"NSObject";
		}
		self.prefixClassNames = prefixClassNames;
        self.hierarchicalClassNames = hierarchicalClassNames;
		[self generate];
	}
	return self;
}

- (void)generate
{
	// Attempt to deserialise JSON data
	NSError *error = nil;
	NSObject *foundationObject = [NSJSONSerialization JSONObjectWithData:self.jsonData options:NSJSONReadingMutableContainers error:&error];
	if (error) {
		NSLog(@"%s Error %@: %@", __FUNCTION__, @(error.code), error.localizedDescription);
		self.error = error;
	}
	
	// Success
	else {
		_classArray = [NSMutableArray array];
		_protocolArray = [NSMutableArray array];
		
		[self processProperties:foundationObject forClass:self.rootClass withParentClass:@""];
	}
}

- (NSMutableDictionary *)classDictionaryForClassName:(NSString *)className
{
	NSMutableDictionary *classDictionary = nil;
	for (NSMutableDictionary *dictionary in _classArray) {
		if ([[dictionary objectForKey:CLASS_NAME_KEY] isEqualToString:className]) {
			classDictionary = dictionary;
			break;
		}
	}
	return classDictionary;
}

- (void)processProperties:(NSObject *)properties forClass:(NSString *)className withParentClass:(NSString *)parentClassName
{
	// Class name
	NSString *fullClassName = [className classify];
	if (self.prefixClassNames && ![fullClassName isEqualToString:self.rootClass]) {
		fullClassName = [NSString stringWithFormat:@"%@%@", self.rootClass, [className classify]];
	}
    else if (self.hierarchicalClassNames) {
        fullClassName = [NSString stringWithFormat:@"%@%@", parentClassName, [className classify]];
    }
	
	// Try to find in classArray, if it's not there yet add it
	NSMutableDictionary *classDictionary = [self classDictionaryForClassName:fullClassName];
	if (!classDictionary) {
		classDictionary = [NSMutableDictionary dictionary];
		[classDictionary setObject:fullClassName forKey:CLASS_NAME_KEY];
		[classDictionary setObject:[NSMutableDictionary dictionary] forKey:CLASS_PROPERTIES_KEY];
		[_classArray addObject:classDictionary];
	}
	NSMutableDictionary *propertiesDictionary = [classDictionary objectForKey:CLASS_PROPERTIES_KEY];
	
	// Process input properties - dictionary
	if ([properties isKindOfClass:[NSDictionary class]]) {
		
		NSDictionary *inputPropertiesDictionary = (NSDictionary *)properties;
		
		for (NSString *propertyName in inputPropertiesDictionary) {
			
			// Try to find existing first - don't process if it already has a strong type
			NSDictionary *propertyDefinition = [propertiesDictionary objectForKey:propertyName];
			BOOL isGeneric = [[propertyDefinition objectForKey:@"type"] isEqualToString:DEFAULT_TYPE] || [[propertyDefinition objectForKey:@"type"] isEqualToString:@"NSArray"] || [[propertyDefinition objectForKey:@"type"] isEqualToString:@"NSDictionary"];
			if (propertyDefinition && !isGeneric) {
				continue;
			}
			
			// Get the input property
			NSObject *property = [inputPropertiesDictionary objectForKey:propertyName];
			
			// String
			if ([property isKindOfClass:[NSString class]]) {
				
				propertyDefinition = @{@"name": [propertyName camelcase], @"type": @"NSString", @"isPrimitive": [NSNumber numberWithBool:NO]};
				[propertiesDictionary setObject:propertyDefinition forKey:propertyName];
			}
		
			// Number
			else if ([property isKindOfClass:[NSNumber class]]) {
				
				NSString *dataType = [self numberType:(NSNumber *)property];
				BOOL isPrimitive = [self typeIsPrimitive:dataType];
				propertyDefinition = @{@"name": [propertyName camelcase], @"type": dataType, @"isPrimitive": [NSNumber numberWithBool:isPrimitive]};
				[propertiesDictionary setObject:propertyDefinition forKey:propertyName];
			}
			
			// Array
			else if ([property isKindOfClass:[NSArray class]]) {
				
				// Protocol name
				NSString *protocolName = [propertyName classify];
				if (self.prefixClassNames) {
					protocolName = [NSString stringWithFormat:@"%@%@", self.rootClass, [propertyName classify]];
				}
                else if (self.hierarchicalClassNames) {
                    protocolName = [NSString stringWithFormat:@"%@%@", fullClassName, [propertyName classify]];
                }
				
				// Add property
				propertyDefinition = @{@"name": [propertyName camelcase], @"type": @"NSArray", @"isPrimitive": [NSNumber numberWithBool:NO], @"protocol": protocolName};
				[propertiesDictionary setObject:propertyDefinition forKey:propertyName];
				
				// Add protocol definition
				if ([_protocolArray indexOfObject:protocolName] == NSNotFound) {
					[_protocolArray addObject:protocolName];
				}
				
                // Creates a stub entry in the class array (incase there's no values in this array at all)
                [self processProperties:nil forClass:propertyName withParentClass:fullClassName];
                
				// Process each object in the array to learn about the new class
				for (NSObject *object in (NSArray *)property) {
					[self processProperties:object forClass:propertyName withParentClass:fullClassName];
				}
			}
			
			// Dictionary
			else if ([property isKindOfClass:[NSDictionary class]]) {
				
				// Class name
				NSString *fullChildClassName = [propertyName classify];
				if (self.prefixClassNames) {
					fullChildClassName = [NSString stringWithFormat:@"%@%@", self.rootClass, [propertyName classify]];
				}
                else if (self.hierarchicalClassNames) {
                    fullChildClassName = [NSString stringWithFormat:@"%@%@", fullClassName, [propertyName classify]];
                }
				
				// Add a property for this class
				propertyDefinition = @{@"name": [propertyName camelcase], @"type": fullChildClassName, @"isPrimitive": [NSNumber numberWithBool:NO]};
				[propertiesDictionary setObject:propertyDefinition forKey:propertyName];

				// Recursively call this method to add a new class for the dictionary
				[self processProperties:property forClass:propertyName withParentClass:fullClassName];
			}
			
			// All other types
			else {
				propertyDefinition = @{@"name": [propertyName camelcase], @"type": DEFAULT_TYPE, @"isPrimitive": [NSNumber numberWithBool:DEFAULT_TYPE_IS_PRIMITIVE]};
				[propertiesDictionary setObject:propertyDefinition forKey:propertyName];
			}
		}
	}
	
	// Array
	if ([properties isKindOfClass:[NSArray class]]) {
		
		for (NSObject *object in (NSArray *)properties) {
			[self processProperties:object forClass:fullClassName withParentClass:@""];
		}
	}
	
}

- (NSString *)headerFileContent
{
	NSMutableString *output = [NSMutableString string];
	
    // @class
    for (NSDictionary *dictionary in _classArray) {
        [output appendFormat:@"@class %@;\n", [dictionary objectForKey:CLASS_NAME_KEY]];
    }
    [output appendString:@"\n"];
    
    // Protocols
	for (NSString *protocol in _protocolArray) {
		[output appendFormat:@"@protocol %@\n@end\n", protocol];
	}
    [output appendString:@"\n"];
    
	// Class definitions
    NSInteger count = 1;
	for (NSDictionary *dictionary in _classArray) {

        // Super class
        NSString *superClass = self.superClass;
        if (count == 1) {
            superClass = self.rootSuperClass;
        }
        count += 1;
        
		[output appendFormat:@"@interface %@ : %@\n", [dictionary objectForKey:CLASS_NAME_KEY], superClass];
		
		// Properties
		NSDictionary *propertiesDictionary = [dictionary objectForKey:CLASS_PROPERTIES_KEY];
		
		// Sort properties
		NSArray *keys = [propertiesDictionary allKeys];
		NSArray *sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
			
			NSDictionary *property1 = [propertiesDictionary objectForKey:key1];
			NSString *sortKey1 = [NSString stringWithFormat:@"%@.%@", [self sortingValueForType:[property1 objectForKey:@"type"] isPrimitive:[[property1 objectForKey:@"isPrimitive"] boolValue]], [property1 objectForKey:@"name"]];
			NSDictionary *property2 = [propertiesDictionary objectForKey:key2];
			NSString *sortKey2 = [NSString stringWithFormat:@"%@.%@", [self sortingValueForType:[property2 objectForKey:@"type"] isPrimitive:[[property2 objectForKey:@"isPrimitive"] boolValue]], [property2 objectForKey:@"name"]];
			
			return [sortKey1 compare:sortKey2 options:NSCaseInsensitiveSearch];
		}];
			
		// Output
		for (NSString *key in sortedKeys) {
			
			NSDictionary *propertyDefinition = [propertiesDictionary objectForKey:key];
            NSString *referenceType = @"strong, ";
			NSString *star = @"*";
			if ([[propertyDefinition objectForKey:@"isPrimitive"] boolValue]) {
				star = @"";
                referenceType = @"";
			}
			NSString *protocol = @"";
			if ([propertyDefinition objectForKey:@"protocol"]) {
				protocol = [NSString stringWithFormat:@"<%@>", [propertyDefinition objectForKey:@"protocol"]];
			}

			[output appendFormat:@"@property (%@nonatomic) %@%@ %@%@;\n", referenceType, [propertyDefinition objectForKey:@"type"], protocol, star, [propertyDefinition objectForKey:@"name"]];
		}
		
		[output appendFormat:@"@end\n\n"];
	}
	
	self.headerFileContent = output;
	return _headerFileContent;
}

- (NSString *)implementationFileContent
{
	NSMutableString *output = [NSMutableString string];
	
	for (NSDictionary *dictionary in _classArray) {
		
		[output appendFormat:@"@implementation %@\n@end\n\n", [dictionary objectForKey:CLASS_NAME_KEY]];
	}
	
	self.implementationFileContent = output;
	return _implementationFileContent;
}

- (NSString *)numberType:(NSNumber *)number
{
	NSString *output = @"";
	
	const char* type = [number objCType];
	if (strcmp (type, @encode (NSInteger)) == 0) {
		output = @"NSInteger";
	}
	else if (strcmp (type, @encode (NSUInteger)) == 0) {
		output = @"NSInteger";
	}
	else if (strcmp (type, @encode (int)) == 0) {
		output = @"NSInteger";
	}
	else if (strcmp (type, @encode (float)) == 0) {
		output = @"double";
	}
	else if (strcmp (type, @encode (double)) == 0) {
		output = @"double";
	}
	else if (strcmp (type, @encode (long)) == 0) {
		output = @"NSInteger";
	}
	else if (strcmp (type, @encode (long long)) == 0) {
		output = @"NSInteger";
	}
	else if (strcmp (type, @encode (BOOL)) == 0) {
		output = @"BOOL";
	}
	else {
		output = @"NSNumber";
	}
	
	return output;
}

- (BOOL)typeIsPrimitive:(NSString *)type
{
	if ([type isEqualToString:@"NSString"] || [type isEqualToString:@"NSArray"] || [type isEqualToString:@"NSDictionary"] || [type isEqualToString:@"NSNumber"]) {
		return NO;
	}
	
	return YES;
}

- (NSString *)sortingValueForType:(NSString *)type isPrimitive:(BOOL)isPrimitive
{
	NSString *sortingValue = @"";
	
	if (isPrimitive) {
		sortingValue = [NSString stringWithFormat:@"1.%@", type];
	}
	
	else {
		if ([type isEqualToString:@"NSString"]) {
			sortingValue = @"2";
		}
		else if ([type isEqualToString:@"NSArray"]) {
			sortingValue = @"5";
		}
		else {
			sortingValue = [NSString stringWithFormat:@"4.%@", type];
		}
	}
	return sortingValue;
}

@end
