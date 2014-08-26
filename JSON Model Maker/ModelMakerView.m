//
//  ModelMakerView.m
//  JSON Model Maker
//
//  Created by Tim Lenton on 20/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import "ModelMakerView.h"
#import "JSONModelMaker.h"

@implementation ModelMakerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)awakeFromNib
{
	// Defaults
	self.rootTextField.stringValue = @"ProductModel";
    self.rootSuperTextField.stringValue = @"JSONModel";
	self.superTextField.stringValue = @"JSONModel";
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"json"];
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	self.jsonTextView.string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	// Disable smart quotes
	self.jsonTextView.automaticQuoteSubstitutionEnabled = NO;
}

- (IBAction)generateButtonClicked:(id)sender
{
	self.headerTextView.string = @"";
	self.implementationTextView.string = @"";
	
	NSString *json = self.jsonTextView.string;
	NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
	
	NSLog(@"%s Debug: %@", __FUNCTION__, json);
    
    BOOL prefixClassNamesWithRoot = NO;
    if (self.radioButton.selectedRow == 0) {
        prefixClassNamesWithRoot = YES;
    }
    
    BOOL hierarchicalClassNames = NO;
    if (self.radioButton.selectedRow == 1) {
        hierarchicalClassNames = YES;
    }
	
	JSONModelMaker *jsonModelMaker = [[JSONModelMaker alloc] initWithJSONData:data
																rootClassName:self.rootTextField.stringValue
                                                               rootSuperClass:self.rootSuperTextField.stringValue
																   superClass:self.superTextField.stringValue
                                                     prefixClassNamesWithRoot:prefixClassNamesWithRoot
                                                       hierarchicalClassNames:hierarchicalClassNames
                                      ];
    	
	if (jsonModelMaker.error) {
		self.headerTextView.string = jsonModelMaker.error.localizedDescription;
	}
	
	else {
		self.headerTextView.string = jsonModelMaker.headerFileContent;
		self.implementationTextView.string = jsonModelMaker.implementationFileContent;
	}
}


@end
