//
//  JSONModelMaker.h
//  JSON Model Maker
//
//  Created by Tim Lenton on 20/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONModelMaker : NSObject

@property (strong, nonatomic) NSData *jsonData;
@property (copy, nonatomic) NSString *rootClass;
@property (copy, nonatomic) NSString *rootSuperClass;
@property (copy, nonatomic) NSString *superClass;
@property (nonatomic) BOOL prefixClassNames;
@property (nonatomic) BOOL hierarchicalClassNames;
@property (copy, nonatomic) NSString *headerFileContent;
@property (copy, nonatomic) NSString *implementationFileContent;
@property (strong, nonatomic) NSError *error;

- (instancetype)initWithJSONData:(NSData *)jsonData
				   rootClassName:(NSString *)rootClass
                  rootSuperClass:(NSString *)rootSuperClass
					  superClass:(NSString *)superClass
      prefixClassNamesWithRoot:(BOOL)prefixClassNames
      hierarchicalClassNames:(BOOL)hierarchicalClassNames;

- (void)generate;

@end
